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

# if the openai_key is set, then we need to pass it to the container
%{ if openai_key != "" }
OPENAI_KEY="-e OPENAI_API_KEY=${openai_key}"
OPENAI_BASE="-e OPENAI_API_BASE_URLS=${openai_base}"
%{ endif }

# if the gpu_enabled is set, then we need to enable the GPU in Docker
%{ if gpu_enabled }
## Set the GPU flag used in Docker
GPU_FLAG="--gpus=all"
%{ endif }

## Create the systemd unit
cat << EOF > /etc/systemd/system/openwebui.service
[Unit]
Description=Open Web UI
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull ghcr.io/open-webui/open-webui:ollama
ExecStart=/usr/bin/docker run -p 80:8080 $${OPENAI_KEY} $${OPENAI_BASE} $${GPU_FLAG} -e RAG_EMBEDDING_MODEL_AUTO_UPDATE=true -v /etc/open_web_ui.d:/root/.open_web_ui -v /etc/open-webui.d:/app/backend/data --name %n ghcr.io/open-webui/open-webui:ollama

[Install]
WantedBy=multi-user.target
EOF

## Reload systemd and enable the service
systemctl daemon-reload
systemctl enable openwebui.service

# If the GPU is enabled, then we need to install the Nvidia drivers and the
# Nvidia Container Toolkit
%{ if gpu_enabled }

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

# Reboot the system, this is required to load the Nvidia drivers
reboot
%{ endif }

# Start the service if not installing the GPU drivers
# if the GPU drivers are being installed, then the system will reboot and the 
# service will be started automatically
systemctl start openwebui.service