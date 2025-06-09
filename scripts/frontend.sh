#!/bin/bash
set -e

sudo apt update -y
sudo apt install apache2 -y

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

sudo npm install -g corepack
corepack enable
corepack prepare yarn@stable --activate

cd /tmp/app
npm install
npm run build
sudo cp -r build/* /var/www/html
