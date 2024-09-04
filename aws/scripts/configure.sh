#!/bin/bash

# Fail if one command fails
set -e

# Run the script in non-interactive mode so that the installation does not 
# prompt for input
export DEBIAN_FRONTEND=noninteractive

## Create the default db with an intial user
## Open WebUI uses SQLite as the default database, when first run it allows anyone to create an admin account
## since we are runnning this in a cloud environment, we need to create an admin account before starting the server.
## At present the only way to do this is to create the database with an admin account already created.

PASSWD=$(htpasswd -bnBC 10 "" "${open_webui_password}" | tr -d ':\n')
USER=${open_webui_user}

# Update the database with the admin user
cat << EOF > /etc/open-webui.d/webui.sql
PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
INSERT INTO auth VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','$${USER}','$${PASSWD}',1);
INSERT INTO user VALUES('488af2d3-dd38-4310-a549-6d8ad11ae69e','Admin User','$${USER}','admin','data:image/png;base64,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',NULL,1719901984,1719901984,1719901984,'null','null',NULL);
COMMIT;
EOF

sqlite3 /etc/open-webui.d/webui.db < /etc/open-webui.d/webui.sql

# Cleanup
rm -f /etc/open-webui.d/webui.sql

# if the openai_key is set, then we need to pass it to the container
# write these to the environment file that will be loaded by systemd
%{ if openai_key != "" }
echo "OPENAI_KEY='-e OPENAI_API_KEY=${openai_key}'" >> /etc/open-webui.d/openwebui.env
echo "OPENAI_BASE='-e OPENAI_API_BASE_URLS=${openai_base}'" >> /etc/open-webui.d/openwebui.env
%{ endif }

# if the gpu_enabled is set, then we need to enable the GPU in Docker
# write these to the environment file that will be loaded by systemd
%{ if gpu_enabled }
echo "GPU_FLAG='--gpus=all'" >> /etc/open-webui.d/openwebui.env
%{ endif }

# start the openwebui service
systemctl enable openwebui.service
systemctl start openwebui.service