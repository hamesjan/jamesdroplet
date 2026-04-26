#!/usr/bin/env bash
set -euo pipefail

echo "==> pulling latest"
git -C /root/hamesjan pull

echo "==> building"
cd /root/hamesjan
npm run build

echo "==> reloading caddy"
caddy reload --config /root/jamesdroplet/Caddyfile --force

echo "==> done"
