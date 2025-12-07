# Ollama 部署指南

Ollama 是一个开源的大模型本地运行工具。本指南介绍如何使用脚本快速部署 Ollama。

![Ollama 架构图](YOUR_IMAGE_URL_HERE)

## 部署脚本

位于 `deploy/ollama/deploy.sh` 的脚本可以帮助您快速安装和启动 Ollama 服务。

### 使用方法

1.  进入脚本目录：
    ```bash
    cd deploy/ollama
    ```

2.  赋予脚本执行权限：
    ```bash
    chmod +x deploy.sh
    ```

3.  执行脚本：
    ```bash
    ./deploy.sh
    ```

![Ollama 运行截图](YOUR_IMAGE_URL_HERE)

## 验证安装

安装完成后，您可以通过以下命令检查 Ollama 版本或运行模型：

```bash
ollama --version
ollama run llama3
```

## 与 Dify 集成

部署完成后，您可以在 Dify 的模型供应商设置中添加 Ollama，填入 Ollama 的服务地址（通常为 `http://host.docker.internal:11434` 或服务器真实 IP:11434）。
