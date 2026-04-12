#!/usr/bin/env bash
set -euo pipefail

# Usage: ./status.sh [site]
# If no site given, shows all sites found under /root/*/platform/Caddyfile.site

SITES=()

if [[ $# -gt 0 ]]; then
    SITES=("$@")
else
    for f in /root/*/platform/Caddyfile.site; do
        [[ -e "$f" ]] || continue
        site=$(echo "$f" | cut -d/ -f3)
        SITES+=("$site")
    done
fi

if [[ ${#SITES[@]} -eq 0 ]]; then
    echo "no sites found"
    exit 1
fi

for site in "${SITES[@]}"; do
    platform="/root/$site/platform"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $site"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # ── git hash ──────────────────────────────
    if [[ -d "/root/$site/.git" ]]; then
        hash=$(git -C "/root/$site" rev-parse HEAD 2>/dev/null || echo "unknown")
        short=${hash:0:8}
        dirty=$(git -C "/root/$site" status --porcelain 2>/dev/null)
        if [[ -n "$dirty" ]]; then
            echo "  commit   $short (dirty — uncommitted changes)"
        else
            echo "  commit   $short"
        fi
    else
        echo "  commit   (no git repo at /root/$site)"
    fi

    # ── systemd service ───────────────────────
    if systemctl list-unit-files "${site}.service" &>/dev/null && \
       systemctl list-unit-files "${site}.service" | grep -q "${site}.service"; then
        active=$(systemctl is-active "$site" 2>/dev/null || true)
        since=$(systemctl show "$site" --property=ActiveEnterTimestamp \
                --value 2>/dev/null | sed 's/ [A-Z]*$//')
        case "$active" in
            active)   echo "  service  running (since $since)" ;;
            inactive) echo "  service  stopped" ;;
            failed)   echo "  service  FAILED" ;;
            *)        echo "  service  $active" ;;
        esac
    else
        echo "  service  (no systemd unit found for $site)"
    fi

    # ── HTTP health check ─────────────────────
    caddysite="$platform/Caddyfile.site"
    if [[ -f "$caddysite" ]]; then
        port=$(grep -oP 'localhost:\K[0-9]+' "$caddysite" | head -1)
        if [[ -n "$port" ]]; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" \
                        --max-time 3 "http://localhost:$port/" 2>/dev/null || echo "000")
            if [[ "$http_code" =~ ^[23] ]]; then
                echo "  http     OK $http_code on :$port"
            else
                echo "  http     FAIL $http_code on :$port"
            fi
        else
            echo "  http     (could not parse port from Caddyfile.site)"
        fi
    else
        echo "  http     (no Caddyfile.site found)"
    fi

    echo ""
done
