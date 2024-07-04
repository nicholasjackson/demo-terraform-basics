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

## Only if GPU is enabled install the NVIDA drivers
%{ if gpu_enabled }

## Install Nvidia Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt-get update
apt-get install -y nvidia-container-toolkit

## Configure Docker
nvidia-ctk runtime configure --runtime=docker

# Setup Nvidia Driver
/opt/deeplearning/install-driver.sh

## Set the GPU flag used in Docker
GPU_FLAG="--gpus=all"

%{ endif }

# Install the Ollama UI Server
mkdir -p /etc/open-webui.d/

## Create the default db with an intial user
## Open WebUI uses SQLite as the default database, when first run it allows anyone to create an admin account
## since we are runnning this in a cloud environment, we need to create an admin account before starting the server.
## At present the only way to do this is to create the database with an admin account already created.

apt-get install -y sqlite3 apache2-utils

PASSWD=$(htpasswd -bnBC 10 "" "${open-webui-password}" | tr -d ':\n')

cat << EOF > /etc/open-webui.d/webui.sql
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "migratehistory" ("id" INTEGER NOT NULL PRIMARY KEY, "name" VARCHAR(255) NOT NULL, "migrated_at" DATETIME NOT NULL);
INSERT INTO migratehistory VALUES(1,'001_initial_schema','2024-07-02 06:27:32.706712');
INSERT INTO migratehistory VALUES(2,'002_add_local_sharing','2024-07-02 06:27:32.713058');
INSERT INTO migratehistory VALUES(3,'003_add_auth_api_key','2024-07-02 06:27:32.719099');
INSERT INTO migratehistory VALUES(4,'004_add_archived','2024-07-02 06:27:32.726653');
INSERT INTO migratehistory VALUES(5,'005_add_updated_at','2024-07-02 06:27:32.740363');
INSERT INTO migratehistory VALUES(6,'006_migrate_timestamps_and_charfields','2024-07-02 06:27:32.777610');
INSERT INTO migratehistory VALUES(7,'007_add_user_last_active_at','2024-07-02 06:27:32.793487');
INSERT INTO migratehistory VALUES(8,'008_add_memory','2024-07-02 06:27:32.798820');
INSERT INTO migratehistory VALUES(9,'009_add_models','2024-07-02 06:27:32.805408');
INSERT INTO migratehistory VALUES(10,'010_migrate_modelfiles_to_models','2024-07-02 06:27:32.811752');
INSERT INTO migratehistory VALUES(11,'011_add_user_settings','2024-07-02 06:27:32.816307');
INSERT INTO migratehistory VALUES(12,'012_add_tools','2024-07-02 06:27:32.821421');
INSERT INTO migratehistory VALUES(13,'013_add_user_info','2024-07-02 06:27:32.826242');
INSERT INTO migratehistory VALUES(14,'014_add_files','2024-07-02 06:27:32.831765');
INSERT INTO migratehistory VALUES(15,'015_add_functions','2024-07-02 06:27:32.839411');
INSERT INTO migratehistory VALUES(16,'016_add_valves_and_is_active','2024-07-02 06:27:32.847968');
INSERT INTO migratehistory VALUES(17,'017_add_user_oauth_sub','2024-07-02 06:27:32.854237');
INSERT INTO migratehistory VALUES(18,'018_add_function_is_global','2024-07-02 06:27:32.861247');
CREATE TABLE IF NOT EXISTS "tag" ("id" VARCHAR(255) NOT NULL, "name" VARCHAR(255) NOT NULL, "user_id" VARCHAR(255) NOT NULL, "data" TEXT);
CREATE TABLE IF NOT EXISTS "chatidtag" ("id" VARCHAR(255) NOT NULL, "tag_name" VARCHAR(255) NOT NULL, "chat_id" VARCHAR(255) NOT NULL, "user_id" VARCHAR(255) NOT NULL, "timestamp" INTEGER NOT NULL NOT NULL);
CREATE TABLE IF NOT EXISTS "auth" ("id" VARCHAR(255) NOT NULL, "email" VARCHAR(255) NOT NULL, "password" TEXT NOT NULL NOT NULL, "active" INTEGER NOT NULL);
INSERT INTO auth VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','admin@demo.gs','$${PASSWD}',1);
CREATE TABLE IF NOT EXISTS "chat" ("id" VARCHAR(255) NOT NULL, "user_id" VARCHAR(255) NOT NULL, "title" TEXT NOT NULL NOT NULL, "chat" TEXT NOT NULL, "share_id" VARCHAR(255), "archived" INTEGER NOT NULL, "created_at" DATETIME NOT NULL NOT NULL, "updated_at" DATETIME NOT NULL NOT NULL);
CREATE TABLE IF NOT EXISTS "document" ("id" INTEGER NOT NULL PRIMARY KEY, "collection_name" VARCHAR(255) NOT NULL, "name" VARCHAR(255) NOT NULL, "title" TEXT NOT NULL NOT NULL, "filename" TEXT NOT NULL NOT NULL, "content" TEXT, "user_id" VARCHAR(255) NOT NULL, "timestamp" INTEGER NOT NULL NOT NULL);
CREATE TABLE IF NOT EXISTS "prompt" ("id" INTEGER NOT NULL PRIMARY KEY, "command" VARCHAR(255) NOT NULL, "user_id" VARCHAR(255) NOT NULL, "title" TEXT NOT NULL NOT NULL, "content" TEXT NOT NULL, "timestamp" INTEGER NOT NULL NOT NULL);
CREATE TABLE IF NOT EXISTS "user" ("id" VARCHAR(255) NOT NULL, "name" VARCHAR(255) NOT NULL, "email" VARCHAR(255) NOT NULL, "role" VARCHAR(255) NOT NULL, "profile_image_url" TEXT NOT NULL NOT NULL, "api_key" VARCHAR(255), "created_at" INTEGER NOT NULL NOT NULL, "updated_at" INTEGER NOT NULL NOT NULL, "last_active_at" INTEGER NOT NULL NOT NULL, "settings" TEXT, "info" TEXT, "oauth_sub" TEXT);
INSERT INTO user VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','Admin User','admin@demo.gs','admin','data:image/png;base64,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',NULL,1719901984,1719901984,1719901984,'null','null',NULL);
CREATE TABLE IF NOT EXISTS "memory" ("id" VARCHAR(255) NOT NULL, "user_id" VARCHAR(255) NOT NULL, "content" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "created_at" INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS "model" ("id" TEXT NOT NULL, "user_id" TEXT NOT NULL, "base_model_id" TEXT, "name" TEXT NOT NULL, "meta" TEXT NOT NULL, "params" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS "tool" ("id" TEXT NOT NULL, "user_id" TEXT NOT NULL, "name" TEXT NOT NULL, "content" TEXT NOT NULL, "specs" TEXT NOT NULL, "meta" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "valves" TEXT);
CREATE TABLE IF NOT EXISTS "file" ("id" TEXT NOT NULL, "user_id" TEXT NOT NULL, "filename" TEXT NOT NULL, "meta" TEXT NOT NULL, "created_at" INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS "function" ("id" TEXT NOT NULL, "user_id" TEXT NOT NULL, "name" TEXT NOT NULL, "type" TEXT NOT NULL, "content" TEXT NOT NULL, "meta" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "valves" TEXT, "is_active" INTEGER NOT NULL, "is_global" INTEGER NOT NULL);
CREATE UNIQUE INDEX "tag_id" ON "tag" ("id");
CREATE UNIQUE INDEX "chatidtag_id" ON "chatidtag" ("id");
CREATE UNIQUE INDEX "auth_id" ON "auth" ("id");
CREATE UNIQUE INDEX "chat_id" ON "chat" ("id");
CREATE UNIQUE INDEX "chat_share_id" ON "chat" ("share_id");
CREATE UNIQUE INDEX "document_collection_name" ON "document" ("collection_name");
CREATE UNIQUE INDEX "document_name" ON "document" ("name");
CREATE UNIQUE INDEX "prompt_command" ON "prompt" ("command");
CREATE UNIQUE INDEX "user_api_key" ON "user" ("api_key");
CREATE UNIQUE INDEX "user_id" ON "user" ("id");
CREATE UNIQUE INDEX "memory_id" ON "memory" ("id");
CREATE UNIQUE INDEX "model_id" ON "model" ("id");
CREATE UNIQUE INDEX "tool_id" ON "tool" ("id");
CREATE UNIQUE INDEX "file_id" ON "file" ("id");
CREATE UNIQUE INDEX "user_oauth_sub" ON "user" ("oauth_sub");
CREATE UNIQUE INDEX "function_id" ON "function" ("id");
COMMIT;
EOF

sqlite3 /etc/open-webui.d/webui.db < /etc/open-webui.d/webui.sql

## Create the systemd unit
cat << EOF > /etc/systemd/system/ollama.service
[Unit]
Description=Ollama UI Server
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=0
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker stop %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStartPre=/usr/bin/docker pull ghcr.io/open-webui/open-webui:ollama
ExecStart=/usr/bin/docker run -p 80:8080 $${GPU_FLAG} -e RAG_EMBEDDING_MODEL_AUTO_UPDATE=true -v /etc/ollama.d:/root/.ollama -v /etc/open-webui.d:/app/backend/data --name %n ghcr.io/open-webui/open-webui:ollama

[Install]
WantedBy=multi-user.target
EOF

## Reload systemd and enable the service
systemctl daemon-reload
systemctl enable ollama.service
systemctl start ollama.service