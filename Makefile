.PHONY: caddy-install caddy-override caddy-reload install-go firewall-setup \
        install-site-clawedmachine deploy-clawedmachine help \
        install-node

# ── Caddy ──────────────────────────────────────────────────────────────────

caddy-install:
	apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
	    | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
	    | tee /etc/apt/sources.list.d/caddy-stable.list
	apt update && apt install -y caddy

# Override the default caddy.service to point at our Caddyfile
caddy-override:
	mkdir -p /etc/systemd/system/caddy.service.d
	printf '[Service]\nUser=root\nGroup=root\nExecStart=\nExecStart=/usr/bin/caddy run --environ --config /root/jamesdroplet/Caddyfile\nExecReload=\nExecReload=/usr/bin/caddy reload --config /root/jamesdroplet/Caddyfile --force\n' \
	    > /etc/systemd/system/caddy.service.d/override.conf
	systemctl daemon-reload
	systemctl enable caddy
	systemctl restart caddy

caddy-reload:
	caddy reload --config /root/jamesdroplet/Caddyfile --force

# ── Go ─────────────────────────────────────────────────────────────────────

install-go:
	apt install -y golang-go

# ── Firewall ───────────────────────────────────────────────────────────────

firewall-setup:
	ufw allow 22/tcp
	ufw allow 80/tcp
	ufw allow 443/tcp
	ufw --force enable

# ── Node.js ────────────────────────────────────────────────────────────────

install-node:
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
	bash -c 'source /root/.nvm/nvm.sh && nvm install 22 && npm install -g pnpm@10.18.2'
	ln -sf /root/.nvm/versions/node/v22.22.2/bin/node /usr/local/bin/node
	bash -c 'source /root/.nvm/nvm.sh && pnpm setup && source /root/.bashrc && pnpm add -g turbo'

# ── clawedmachine ──────────────────────────────────────────────────────────

install-site-clawedmachine:
	cp /root/clawedmachine/apps/platform/clawedmachine.service /etc/systemd/system/clawedmachine.service
	systemctl daemon-reload
	systemctl enable clawedmachine
	systemctl start clawedmachine

deploy-clawedmachine:
	cd /root/clawedmachine && bash useful_scripts/setup_repo.sh
	systemctl restart clawedmachine
	$(MAKE) caddy-reload

# ── Bootstrap (first-time, run targets in order) ───────────────────────────
#
#   make caddy-install
#   make caddy-override
#   make install-node
#   git clone <repo> /root/clawedmachine
#   cp /root/clawedmachine/apps/platform/.env.example /root/clawedmachine/apps/platform/.env
#   # fill in real secrets in .env
#   make install-site-clawedmachine
#   make deploy-clawedmachine
#   make firewall-setup   # if ufw is active
#
# ── Adding a new site ──────────────────────────────────────────────────────
#
# 1. Create /root/<site>/apps/platform/ with Caddyfile.site, *.service
# 2. Add install-site-<site> and deploy-<site> targets below (copy the pattern above)
# 3. Add an explicit `import /root/<site>/apps/platform/Caddyfile.site` line to Caddyfile
#    (Caddy only allows one wildcard per glob, so each site needs its own import line)
# 4. make install-site-<site> && make deploy-<site> && make caddy-reload
#
# ── Help ───────────────────────────────────────────────────────────────────

help:
	@echo "Infrastructure targets:"
	@echo "  caddy-install             Install Caddy from official repo"
	@echo "  caddy-override            Point Caddy at /root/jamesdroplet/Caddyfile"
	@echo "  caddy-reload              Hot-reload Caddy config"
	@echo "  install-go                Install Go via apt"
	@echo "  firewall-setup            Open ports 22/80/443 via ufw"
	@echo ""
	@echo "Site targets:"
	@echo "  install-node                Install Node.js 22 via NVM + pnpm + turbo"
	@echo "  install-site-clawedmachine  Register clawedmachine systemd service"
	@echo "  deploy-clawedmachine        Build SvelteKit app, restart service, reload Caddy"
