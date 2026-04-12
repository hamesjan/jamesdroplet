#!/usr/bin/env bash
set -euo pipefail

SITE=/root/clawedmachine/platform

echo "==> pulling latest"
git -C /root/clawedmachine pull

echo "==> building"
cd "$SITE"
go build -o clawedmachine-server .

echo "==> restarting service"
systemctl restart clawedmachine

echo "==> reloading caddy"
caddy reload --config /root/jamesdroplet/Caddyfile --force

echo "==> done — $(systemctl is-active clawedmachine)"
