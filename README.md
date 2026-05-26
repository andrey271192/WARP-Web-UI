# WARP Web UI

Browser-based control panel for **Cloudflare WARP** on Linux: connect/disconnect, WARP+ license, SOCKS proxy port, and optional presets for **3x-ui** and **Amnezia Xray**.

## Features

- **WARP control**: Connect, disconnect, restart `warp-svc`, view status and logs
- **Account**: Registration info, apply WARP+ license key
- **Install / uninstall** `cloudflare-warp` from the UI (Debian/Ubuntu apt repo)
- **SOCKS proxy**: Set `warp-cli` proxy port (e.g. `40000` or `1024`)
- **3x-ui preset**: Add `warp-socks` outbound → `127.0.0.1:PORT` and `geosite:google` routing rule
- **Amnezia preset**: Docker bridge `172.17.0.1:11025` → host SOCKS, per-client WARP routing with friendly names

## Requirements

- Linux (Debian/Ubuntu recommended)
- `python3` (stdlib only — no pip packages)
- `systemd`
- Optional: `cloudflare-warp` package (can be installed via UI or `scripts/warp-install-cf.sh`)
- Optional: `docker`, `socat`, `x-ui` / Amnezia for integration presets

## Quick start

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/install.sh | sudo bash
```

The installer **asks interactively**:

| Prompt | Default | Notes |
|--------|---------|--------|
| SOCKS proxy port | `40000` | Also `1024` is common for official `cloudflare-warp` |
| Web UI port | `3030` | Open in firewall if needed |
| Admin username | `warpadmin` | HTTP Basic Auth |
| Admin password | *(required, min 8 chars)* | Stored in `/etc/default/warp-webui` (`chmod 600`) |

### Clone and install

```bash
git clone https://github.com/andrey271192/WARP-Web-UI.git
cd WARP-Web-UI
sudo bash install.sh
```

Open `http://YOUR_SERVER:3030/` (use the port you chose). Log in with the credentials you set.

If WARP is not installed yet, click **Install WARP** in the UI (or run `scripts/warp-install-cf.sh` with `WARP_PROXY_PORT` set).

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/uninstall.sh | sudo bash
```

Or from a clone: `sudo bash uninstall.sh` — stops the service, optionally removes files, config, and the `cloudflare-warp` package.

## Repository layout

```
app.py                          # Web UI + API (Python http.server)
scripts/warp-install-cf.sh      # Install cloudflare-warp from Cloudflare apt repo
scripts/warp-uninstall-cf.sh    # Remove cloudflare-warp package
systemd/warp-webui.service      # systemd unit template
install.sh / uninstall.sh       # One-command setup / teardown
.env.example                    # Environment variable reference
```

After install, files live under `/opt/warp-webui/`, config in `/etc/default/warp-webui`.

## Configuration

See [`.env.example`](.env.example). Main variables:

- `WARP_WEBUI_USER`, `WARP_WEBUI_PASS` — Basic Auth
- `WARP_WEBUI_PORT` — HTTP port (default `3030`)
- `WARP_PROXY_PORT` — SOCKS port used at install and for `warp-install` from UI
- `WARP_PUBLIC_HOST` — Public IP/hostname for client preset hints

Client display names for Amnezia: `/etc/warp-webui/client-aliases.json`

## Security notes

- **HTTP Basic Auth only** — credentials are sent on every request. Prefer **HTTPS** (reverse proxy: nginx/Caddy + TLS) for production.
- **Firewall**: Expose only the Web UI port to trusted IPs (`ufw allow from TRUSTED to any port 3030`).
- **Root service**: The panel runs as root to manage `warp-cli`, systemd, and Docker. Do not expose it to the public internet without protection.
- **Secrets**: Never commit `/etc/default/warp-webui`. Rotate the admin password after install.
- WARP+ license keys are entered in the UI and passed to `warp-cli` — they are not stored in this repo.

## API (authenticated)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | HTML UI |
| GET | `/status`, `/registration`, `/proxy`, `/logs` | Status |
| POST | `/connect`, `/disconnect`, `/restart` | WARP control |
| POST | `/warp-install`, `/warp-uninstall` | Package install/remove |
| POST | `/proxy-port`, `/license` | SOCKS port, WARP+ key |
| POST | `/xui-preset`, `/amnezia-preset`, `/amnezia-routing` | Integration presets |

## License

MIT — see [LICENSE](LICENSE).

## Russian documentation

See [README.ru.md](README.ru.md).
