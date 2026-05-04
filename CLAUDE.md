# jamesdroplet

Infrastructure repo for James's DigitalOcean droplet. Manages Caddy config and deploy scripts for all hosted sites.

## Sites

| Site | Repo | Port | Type |
|---|---|---|---|
| hamesjan.com | `/root/hamesjan` | 3000 | SvelteKit (adapter-node) |
| clawedmachine.com | `/root/clawedmachine` | (see its service) | SvelteKit |

## Caddy

- Main config: `/root/jamesdroplet/Caddyfile` — imports each site's `Caddyfile.site`
- Caddy runs as a systemd service overridden in `/etc/systemd/system/caddy.service.d/override.conf`
- Reload config: `make caddy-reload` (no downtime)

## Makefile targets

```
make caddy-reload              # hot-reload Caddy config
make install-site-hamesjan     # register hamesjan systemd service (first time only)
make deploy-hamesjan           # pull + build + restart service + caddy reload
make deploy-clawedmachine      # pull + build + restart service + caddy reload
```

## Adding a new site

1. Create `/root/<site>/Caddyfile.site` and `<site>.service`
2. Add `import /root/<site>/Caddyfile.site` to `Caddyfile`
3. Add `install-site-<site>` and `deploy-<site>` targets to Makefile
4. Add a deploy script to `scripts/`
5. `make install-site-<site> && make caddy-reload`

## Scripts

- `scripts/deploy-hamesjan.sh` — pull, npm install, build, systemctl restart hamesjan, caddy reload
- `scripts/deploy-clawedmachine.sh` — site-specific deploy logic
- `scripts/status.sh` — check status of running services
