#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

# Clean apt cache
sudo rm -rf /var/lib/apt/lists/*

# Ensure universe repo is enabled (for completeness)
sudo apt-get update -y
sudo apt-get install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt-get update -y

# Upgrade system packages
sudo apt-get upgrade -y
sudo apt-get --fix-broken install -y

# Install Apache and common tools (removed ssl-cert)
sudo apt-get install -y apache2 apache2-bin curl

# Setup Node.js 18 and install it
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install and enable corepack for Yarn
sudo npm install -g corepack
corepack enable
corepack prepare yarn@stable --activate

# Ensure the source directory exists
if [ ! -d /tmp/app ]; then
  echo "ERROR: /tmp/app directory not found!"
  exit 1
fi

cd /tmp/app

# Install frontend dependencies and build
npm install
npm run build

# Deploy build output to Apache directory
sudo cp -r build/* /var/www/html/

# Restart Apache
sudo systemctl restart apache2

