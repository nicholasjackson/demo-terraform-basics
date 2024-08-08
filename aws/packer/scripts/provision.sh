#!/bin/bash

# Fail if one command fails
set -e

# Run the script in non-interactive mode so that the installation does not 
# prompt for input
export DEBIAN_FRONTEND=noninteractive

# Install required packages
apt-get update
apt-get install -y ca-certificates curl sqlite3 apache2-utils

# Setup Docker

## Add Docker's official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

## Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install the open_web_ui UI Server
mkdir -p /etc/open-webui.d/

# Start Open Web UI for the first time so that it creates the database
/usr/bin/docker pull ghcr.io/open-webui/open-webui:ollama
/usr/bin/docker run -d -v /etc/open-webui.d:/root/.open_web_ui -v /etc/open-webui.d:/app/backend/data --name openwebui ghcr.io/open-webui/open-webui:ollama
sleep 10 # Wait 10s for the server to start and the database to be created
/usr/bin/docker stop openwebui
/usr/bin/docker rm openwebui

## Create the systemd unit
## When starting systemd will load the environment file and pass the variables to the container
## The environment variables will be provisioned when the VM is created by Terraform
cat << 'EOF' > /etc/systemd/system/openwebui.service
[Unit]
Description=Open Web UI
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
EnvironmentFile=/etc/open-webui.d/openwebui.env
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run -p 80:8080 $OPENAI_KEY $OPENAI_BASE $GPU_FLAG -e RAG_EMBEDDING_MODEL_AUTO_UPDATE=true -v /etc/open-webui.d:/root/.open_web_ui -v /etc/open-webui.d:/app/backend/data --name %n ghcr.io/open-webui/open-webui:ollama

[Install]
WantedBy=multi-user.target
EOF

## Reload systemd and enable the service
systemctl daemon-reload

# Install the Nvidia drivers and the
# Nvidia Container Toolkit

# Install Nvidia Driver
echo 'deb http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware' >> /etc/apt/sources.list
apt-get update
apt-get install -y linux-headers-amd64
apt-get install -y nvidia-driver firmware-misc-nonfree

## Install Nvidia Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit

## Configure Docker
nvidia-ctk runtime configure --runtime=docker