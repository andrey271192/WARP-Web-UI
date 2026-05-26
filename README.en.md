# WARP Web UI

Browser control panel for **Cloudflare WARP** on Linux: connect/disconnect, WARP+, SOCKS port, optional **3x-ui** and **Amnezia** presets.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/install.sh | sudo bash
```

Interactive defaults: SOCKS `40000`, Web UI `3030`, user `warpadmin`, password (min 8 chars) → `/etc/default/warp-webui`.

```bash
curl -fsSL https://raw.githubusercontent.com/andrey271192/WARP-Web-UI/main/uninstall.sh | sudo bash
```

Open `http://SERVER:PORT/` after install. Use **Install WARP** in the UI if the package is missing.

## Security (short)

- HTTP Basic Auth only — use HTTPS (nginx/Caddy) in production.
- Firewall the Web UI port to trusted IPs.
- Runs as root; do not expose publicly without protection.

## Docs

Full documentation (Russian): [README.md](README.md).

## License

MIT — [LICENSE](LICENSE).
