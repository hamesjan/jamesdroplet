#!/usr/bin/env bash
set -euo pipefail

echo "==> pulling latest"
git -C /root/hamesjan pull

echo "==> installing deps"
cd /root/hamesjan && npm install

echo "==> building"
npm run build

echo "==> restarting service"
systemctl restart hamesjan

echo "==> reloading caddy"
caddy reload --config /root/jamesdroplet/Caddyfile --force

echo "==> done"
