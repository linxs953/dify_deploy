# Dify 自动化部署指南

本指南将介绍如何使用本仓库提供的脚本在 Linux 环境（推荐 Ubuntu）下快速部署 Dify。

![Dify 部署架构图](YOUR_IMAGE_URL_HERE)

## 前置要求

*   Linux 操作系统 (推荐 Ubuntu 20.04+)
*   Root 权限或 Sudo 权限

## 自动部署脚本

`deploy/dify/dify.sh` 脚本负责 Docker 环境的安装和 Dify 服务的部署。

### 使用方法

1.  进入脚本目录：
    ```bash
    cd deploy/dify
    ```

2.  赋予脚本执行权限：
    ```bash
    chmod +x dify.sh
    ```

3.  执行脚本（建议使用 sudo）：
    ```bash
    sudo ./dify.sh
    ```

### 脚本功能

*   **环境检查与配置**：自动检查并配置系统环境。
*   **Docker 安装**：自动安装 Docker 和 Docker Compose。
*   **服务部署**：拉取并启动 Dify 相关服务容器。

![Dify 部署成功截图](YOUR_IMAGE_URL_HERE)

## 验证部署

部署完成后，您可以通过浏览器访问服务器 IP 地址来验证 Dify 是否启动成功。
