#!/bin/bash
set -e

# Install Docker
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Install latest Docker Compose plugin
COMPOSE_URL=$(curl -s https://api.github.com/repos/docker/compose/releases/latest \
  | grep '"browser_download_url"' \
  | grep 'docker-compose-linux-x86_64"' \
  | cut -d'"' -f4)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -sSL "$COMPOSE_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
