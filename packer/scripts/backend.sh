#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# Update apt cache and install curl
apt-get update -y
apt-get install -y curl

# Setup Node.js 18 repo and install nodejs
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get update -y
apt-get install -y nodejs

# Install corepack and pm2 globally
npm install -g corepack pm2

# Enable corepack and activate yarn
corepack enable
corepack prepare yarn@stable --activate

# Validate /tmp/app exists
if [ ! -d /tmp/app ]; then
  echo "/tmp/app directory not found!"
  exit 1
fi

cd /tmp/app

# Install dependencies
npm install
npm install dotenv

# Start backend with pm2
pm2 start index.js --name backend
pm2 save

# Commented this out to prevent image build failure
# These steps are better run as part of user-data or after instance launch
# pm2 startup systemd -u $(whoami) --hp $(eval echo "~$(whoami)")
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $(whoami) --hp $(eval echo "~$(whoami)")

