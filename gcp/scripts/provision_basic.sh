#! /bin/bash

# Fail if one command fails
set -e
export DEBIAN_FRONTEND=noninteractive

# Setup Docker

## Add Docker's official GPG key:
apt-get update
apt-get install -y ca-certificates curl
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

# Install the Open Web UI Server
mkdir -p /etc/open-webui.d/

## Create the default db with an intial user
## Open WebUI uses SQLite as the default database, when first run it allows anyone to create an admin account
## since we are runnning this in a cloud environment, we need to create an admin account before starting the server.
## At present the only way to do this is to create the database with an admin account already created.

apt-get install -y sqlite3 apache2-utils

PASSWD=$(htpasswd -bnBC 10 "" "mypassword" | tr -d ':\n')
USER="admin@demo.gs"

# Start Open Web UI for the first time so that it creates the database
/usr/bin/docker pull ghcr.io/open-webui/open-webui:ollama
/usr/bin/docker run -d -p 80:8080 -v /etc/open-webui.d:/root/.open_web_ui -v /etc/open-webui.d:/app/backend/data --name openwebui ghcr.io/open-webui/open-webui:ollama

# Wait for the server to start
timeout 300 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost)" != "200" ]]; do sleep 5; done' || false

# Stop the server
/usr/bin/docker stop openwebui
/usr/bin/docker rm openwebui

# Update the database with the admin user
cat << EOF > /etc/open-webui.d/webui.sql
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
INSERT INTO auth VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','${USER}','${PASSWD}',1);
INSERT INTO user VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','Admin User','${USER}','admin','data:image/png;base64,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',NULL,1719901984,1719901984,1719901984,'null','null',NULL);
COMMIT;
EOF

sqlite3 /etc/open-webui.d/webui.db < /etc/open-webui.d/webui.sql

## Create the systemd unit
cat << 'EOF' > /etc/systemd/system/openwebui.service
[Unit]
Description=Open Web UI Server
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run -p 80:8080 -e RAG_EMBEDDING_MODEL_AUTO_UPDATE=true -v /etc/open-webui.d:/root/.open_web_ui -v /etc/open-webui.d:/app/backend/data --name %n ghcr.io/open-webui/open-webui:ollama

[Install]
WantedBy=multi-user.target
EOF

## Reload systemd and enable the service
systemctl daemon-reload
systemctl enable openwebui.service

# After installing Nvidia drivers we need to reboot
systemctl start openwebui.service