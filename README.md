# Dify Deployment & Plugins Repository

Welcome to the **Dify Deployment & Plugins** repository! This project is a comprehensive collection of tools designed to streamline the deployment of Dify and extend its capabilities through custom plugins.

## 📂 Project Structure

The repository is organized into two main sections:

*   **`deploy/`**: Contains automated scripts for deploying Dify and related services (like Ollama).
*   **`dify-plugin/`**: Houses the source code for custom Dify plugins.

---

## 🚀 Deployment Guide

This repository provides shell scripts to facilitate the installation and setup of Dify on Linux environments (specifically optimized for Ubuntu).

### Dify Automatic Deployment

The `deploy/dify/dify.sh` script handles the installation of Docker environment and the deployment of Dify.

**Usage:**

```bash
cd deploy/dify
chmod +x dify.sh
sudo ./dify.sh
```

**Features:**
*   Installs Docker & Docker Compose.
*   Configures system environment.
*   Deploys Dify services.

### Ollama Deployment

For local LLM support, you can use the Ollama deployment script located at `deploy/ollama/deploy.sh`.

```bash
cd deploy/ollama
chmod +x deploy.sh
./deploy.sh
```

---

## 🧩 Plugins

### DBTool Plugin (`dify-plugin/dbtool`)

**DBTool** is a powerful utility plugin for Dify that allows agents to interact directly with databases.

#### Features
*   **Execute SQL**: Run SQL queries against a connected database.
*   **Get Table Definition**: Retrieve schema information and table definitions to help LLMs understand the database structure.

#### Installation
1.  Pack the plugin using Dify's plugin packaging tool.
2.  Upload the `.difypkg` file to your Dify instance's plugin management page.

---

## 🛠️ Development

### Prerequisites
*   Docker & Docker Compose
*   Python 3.10+ (for plugin development)

### Contribution
Feel free to submit Pull Requests or Issues to improve the deployment scripts or add new features to the plugins.
