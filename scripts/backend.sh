#!/bin/bash
set -e

sudo apt update -y

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

sudo npm install -g corepack pm2
corepack enable
corepack prepare yarn@stable --activate

cd /tmp/app
npm install
npm install dotenv
pm2 start index.js --name backend
pm2 save
