.PHONY: caddy-install caddy-override caddy-reload install-go firewall-setup \
        install-site-clawedmachine deploy-clawedmachine help

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

# ── clawedmachine ──────────────────────────────────────────────────────────

install-site-clawedmachine:
	cp /root/clawedmachine/platform/clawedmachine.service /etc/systemd/system/clawedmachine.service
	systemctl daemon-reload
	systemctl enable clawedmachine
	systemctl start clawedmachine

deploy-clawedmachine:
	cd /root/clawedmachine/platform && go build -o clawedmachine-server .
	systemctl restart clawedmachine
	$(MAKE) caddy-reload

# ── Bootstrap (first-time, run targets in order) ───────────────────────────
#
#   make caddy-install
#   make caddy-override
#   make install-go
#   git clone <repo> /root/clawedmachine
#   make install-site-clawedmachine
#   make deploy-clawedmachine
#   make firewall-setup   # if ufw is active
#
# ── Adding a new site ──────────────────────────────────────────────────────
#
# 1. Create /root/<site>/platform/ with Caddyfile.site, main.go, go.mod, <site>.service
# 2. Add install-site-<site> and deploy-<site> targets below (copy the pattern above)
# 3. make install-site-<site> && make deploy-<site>
# No changes to Caddyfile needed — the import glob picks it up automatically.
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
	@echo "  install-site-clawedmachine  Register clawedmachine systemd service"
	@echo "  deploy-clawedmachine        Build binary, restart service, reload Caddy"
