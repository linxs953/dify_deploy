#!/bin/bash

# ollama部署脚本

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Configure OLLAMA_HOST to listen on all interfaces
# This configuration is specific to Linux systems using systemd
if command -v systemctl >/dev/null 2>&1; then
    SERVICE_FILE="/etc/systemd/system/ollama.service"
    
    if [ -f "$SERVICE_FILE" ]; then
        echo "Configuring OLLAMA_HOST in $SERVICE_FILE..."
        
        # Check if OLLAMA_HOST is already set to avoid duplication
        if ! grep -q "OLLAMA_HOST=0.0.0.0:11434" "$SERVICE_FILE"; then
            # Add the Environment variable to the [Service] section
            # We insert it after [Service] block start to ensure it's in the correct section
            sed -i '/^\[Service\]/a Environment="OLLAMA_HOST=0.0.0.0:11434"' "$SERVICE_FILE"
            
            # Reload systemd and restart Ollama
            echo "Reloading systemd daemon..."
            systemctl daemon-reload
            
            echo "Restarting Ollama service..."
            systemctl restart ollama
            
            echo "Ollama configuration updated successfully."
        else
            echo "OLLAMA_HOST is already configured."
        fi
    else
        echo "Warning: Service file $SERVICE_FILE not found. Please ensure Ollama is installed correctly."
    fi
else
    echo "systemctl not found. Skipping systemd configuration (not a Linux systemd environment)."
fi


systemctl status ollama 
systemctl start ollama 
systemctl enable ollama
systemctl daemon-reload 
systemctl restart ollama