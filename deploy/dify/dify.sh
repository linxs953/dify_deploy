#!/bin/bash

# ==========================================
# 脚本设置
# ==========================================

# 遇到任何命令返回非零状态码时立即退出
set -e
# 管道中的任何命令失败都导致整个管道失败
set -o pipefail

# 定义颜色变量
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==========================================
# 辅助函数
# ==========================================

# 错误捕获处理函数
handle_error() {
    local line_no=$1
    echo -e "\n${RED}=====================================================${NC}"
    echo -e "${RED} [ERROR] 脚本执行失败！${NC}"
    echo -e "${RED} 错误发生在第 $line_no 行。${NC}"
    echo -e "${RED} 请检查上方日志以获取详细信息。${NC}"
    echo -e "${RED}=====================================================${NC}"
}

# 注册错误捕获 (ERR 信号在命令返回非零且未被 if/while 等处理时触发)
trap 'handle_error $LINENO' ERR

log_info() {
    echo -e "$(date '+%H:%M:%S') ${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "$(date '+%H:%M:%S') ${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "$(date '+%H:%M:%S') ${RED}[ERROR]${NC} $1"
}

ensure_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        log_warn "建议使用 sudo 运行此脚本，以确保有足够权限。"
    fi
}

# ==========================================
# 主逻辑
# ==========================================

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}       Dify 自动化部署脚本 (Docker + 环境配置)       ${NC}"
echo -e "${BLUE}=====================================================${NC}"

ensure_sudo

# 1. 安装 Docker
echo -e "\n${YELLOW}>>> [1/6] 开始安装 Docker 环境...${NC}"

log_info "更新 apt 软件包索引..."
sudo apt update -y

log_info "安装基础依赖 (ca-certificates, curl)..."
sudo apt install -y ca-certificates curl

log_info "添加 Docker 官方 GPG 密钥..."
sudo install -m 0755 -d /etc/apt/keyrings
# 修复原脚本中的反引号错误，并添加 -fsSL 参数确保静默失败时报错
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

log_info "添加 Docker 软件源..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log_info "再次更新 apt 索引..."
sudo apt update -y

log_info "正在安装 Docker Engine (这可能需要几分钟)..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log_info "Docker 安装/更新完成。"


# 2. 检查与启动 Docker
echo -e "\n${YELLOW}>>> [2/6] 检查 Docker 服务状态...${NC}"
# systemctl is-active 如果不活跃会返回非零，导致 set -e 退出。
# 因此需要临时允许失败，或者使用 if 结构 (if 结构内的命令失败不会触发 set -e)
if sudo systemctl is-active --quiet docker; then
    log_info "Docker 服务正在运行。"
else
    log_warn "Docker 未运行，正在启动..."
    sudo systemctl start docker
    
    # 再次检查，如果失败则由 set -e 或手动 exit 触发
    if ! sudo systemctl is-active --quiet docker; then
        log_error "Docker 启动失败。"
        exit 1
    fi
    log_info "Docker 启动成功。"
fi


# 3. 配置镜像加速
echo -e "\n${YELLOW}>>> [3/6] 配置 Docker 镜像加速源...${NC}"
sudo mkdir -p /etc/docker
log_info "写入 daemon.json (使用 mirror.iscas.ac.cn)..."
# 使用 tee 写入文件
sudo tee /etc/docker/daemon.json > /dev/null <<-'EOF'
{
  "registry-mirrors": ["https://mirror.iscas.ac.cn"]
}
EOF

log_info "重启 Docker 以应用配置..."
sudo systemctl daemon-reload
sudo systemctl restart docker
log_info "镜像加速配置完成。"


# 4. 下载 Dify 代码
echo -e "\n${YELLOW}>>> [4/6] 下载 Dify 源码...${NC}"
if [ -d "dify" ]; then
    log_warn "检测到 'dify' 目录已存在，跳过 git clone。"
else
    log_info "正在克隆 Dify 仓库..."
    # 修复原脚本中的反引号错误
    git clone https://github.com/langgenius/dify.git
fi

# 尝试进入目录，如果失败则触发 set -e (或者显式检查)
cd dify/docker || { log_error "无法进入 dify/docker 目录"; exit 1; }


# 5. 配置 .env 文件
echo -e "\n${YELLOW}>>> [5/6] 初始化环境配置...${NC}"
if [ ! -f .env ]; then
    log_info "创建 .env 文件 (从 .env.example 复制)..."
    cp .env.example .env
else
    log_info ".env 文件已存在。"
fi

echo -e "${BLUE}--- 配置 Nginx 端口 ---${BLUE}"
while true; do
    # read 命令通常返回 0，除非遇到 EOF
    read -p "请输入 Nginx 监听端口 (默认为 80): " user_port
    user_port=${user_port:-80} 
    
    if [[ "$user_port" =~ ^[0-9]+$ ]]; then 
        break 
    else 
        log_warn "输入错误: 端口必须是纯数字，请重新输入。" 
    fi 
done

# 使用 sed 替换
sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${user_port}/" .env

current_port=$(grep "^EXPOSE_NGINX_PORT=" .env | cut -d'=' -f2)
log_info "✅ 配置已更新! EXPOSE_NGINX_PORT 目前设置为: ${current_port}"

# 配置插件签名验证
log_info "配置插件签名验证 (设置为 false)..."
if grep -q "^FORCE_VERIFYING_SIGNATURE=" .env; then
    sed -i 's/^FORCE_VERIFYING_SIGNATURE=.*/FORCE_VERIFYING_SIGNATURE=false/' .env
else
    echo "FORCE_VERIFYING_SIGNATURE=false" >> .env
fi

if grep -q "^ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES=" .env; then
    sed -i 's/^ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES=.*/ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES=false/' .env
else
    echo "ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES=false" >> .env
fi


# 6. 启动服务
echo -e "\n${YELLOW}>>> [6/6] 启动 Dify 服务 (Docker Compose)...${NC}"
# docker compose 命令如果失败，set -e 会自动捕获并退出
docker compose -f docker-compose.yaml up -d

# 7. 修复权限
echo -e "\n${YELLOW}>>> [7/7] 正在修复 API 容器权限...${NC}"
# 获取 api 服务的所有容器 ID
api_containers=$(docker compose -f docker-compose.yaml ps -q api)

if [ -n "$api_containers" ]; then
    for container_id in $api_containers; do
        log_info "正在处理容器: $container_id"
        # 在容器内以 root 身份执行 chown
        docker exec -u root "$container_id" chown -R dify:dify /app/api/storage
        log_info "容器 $container_id 权限修复完成。"
    done
else
    log_warn "未找到 API 容器，跳过权限修复。"
fi

echo -e "\n${GREEN}=====================================================${NC}"
echo -e "${GREEN}           🎉 Dify 部署成功! 恭喜!           ${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "  👉 访问地址: http://localhost:${current_port}"
echo -e "  👉 注意: 首次启动可能需要几分钟等待数据库初始化完成。"
echo -e "${GREEN}=====================================================${NC}"