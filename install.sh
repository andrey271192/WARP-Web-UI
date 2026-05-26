#!/usr/bin/env bash
# WARP Web UI — one-command installer (run as root on Debian/Ubuntu)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${WARP_WEBUI_INSTALL_DIR:-/opt/warp-webui}"
ENV_FILE="/etc/default/warp-webui"
SERVICE_NAME="warp-webui"
UNIT_DST="/etc/systemd/system/${SERVICE_NAME}.service"
ALIASES_DIR="/etc/warp-webui"
LOG_DIR="/var/log/warp-webui"

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Run as root: sudo bash install.sh"
  exit 1
fi

echo "=== WARP Web UI installer ==="
echo

prompt() {
  local var_name="$1" prompt_text="$2" default_val="$3"
  local input
  read -rp "${prompt_text} [${default_val}]: " input
  if [[ -z "${input}" ]]; then
    printf -v "${var_name}" '%s' "${default_val}"
  else
    printf -v "${var_name}" '%s' "${input}"
  fi
}

echo "SOCKS port: local port for warp-cli proxy mode (used by x-ui / Amnezia presets)."
echo "Common choices: 40000 (warp-offline style) or 1024 (cloudflare-warp default)."
prompt WARP_PROXY_PORT "SOCKS proxy port" "40000"
if ! [[ "${WARP_PROXY_PORT}" =~ ^[0-9]+$ ]] || (( WARP_PROXY_PORT < 1 || WARP_PROXY_PORT > 65535 )); then
  echo "Invalid SOCKS port: ${WARP_PROXY_PORT}"
  exit 1
fi

prompt WARP_WEBUI_PORT "Web UI HTTP port" "3030"
if ! [[ "${WARP_WEBUI_PORT}" =~ ^[0-9]+$ ]] || (( WARP_WEBUI_PORT < 1 || WARP_WEBUI_PORT > 65535 )); then
  echo "Invalid Web UI port: ${WARP_WEBUI_PORT}"
  exit 1
fi

prompt WARP_WEBUI_USER "Web UI admin username" "warpadmin"

while true; do
  read -rsp "Web UI admin password (min 8 chars): " WARP_WEBUI_PASS
  echo
  if [[ "${#WARP_WEBUI_PASS}" -ge 8 ]]; then
    break
  fi
  echo "Password too short. Use at least 8 characters."
done

# Detect public host for client preset hints (optional)
WARP_PUBLIC_HOST="${WARP_PUBLIC_HOST:-}"
if [[ -z "${WARP_PUBLIC_HOST}" ]]; then
  WARP_PUBLIC_HOST="$(curl -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)"
fi
if [[ -z "${WARP_PUBLIC_HOST}" ]]; then
  WARP_PUBLIC_HOST="$(hostname -f 2>/dev/null || hostname)"
fi

echo
echo "Installing to ${INSTALL_DIR} ..."
mkdir -p "${INSTALL_DIR}/scripts" "${ALIASES_DIR}" "${LOG_DIR}"
install -m 0755 "${REPO_DIR}/app.py" "${INSTALL_DIR}/app.py"
install -m 0755 "${REPO_DIR}/scripts/warp-install-cf.sh" "${INSTALL_DIR}/scripts/warp-install-cf.sh"
install -m 0755 "${REPO_DIR}/scripts/warp-uninstall-cf.sh" "${INSTALL_DIR}/scripts/warp-uninstall-cf.sh"

umask 077
cat > "${ENV_FILE}" <<EOF
WARP_WEBUI_USER=${WARP_WEBUI_USER}
WARP_WEBUI_PASS=${WARP_WEBUI_PASS}
WARP_WEBUI_HOST=0.0.0.0
WARP_WEBUI_PORT=${WARP_WEBUI_PORT}
WARP_PROXY_PORT=${WARP_PROXY_PORT}
WARP_PUBLIC_HOST=${WARP_PUBLIC_HOST}
WARP_INSTALL_SCRIPT=${INSTALL_DIR}/scripts/warp-install-cf.sh
WARP_UNINSTALL_SCRIPT=${INSTALL_DIR}/scripts/warp-uninstall-cf.sh
WARP_CLIENT_ALIASES=${ALIASES_DIR}/client-aliases.json
EOF
chmod 600 "${ENV_FILE}"

if [[ ! -f "${ALIASES_DIR}/client-aliases.json" ]]; then
  echo '{}' > "${ALIASES_DIR}/client-aliases.json"
  chmod 600 "${ALIASES_DIR}/client-aliases.json"
fi

sed \
  -e "s|@INSTALL_DIR@|${INSTALL_DIR}|g" \
  -e "s|@ENV_FILE@|${ENV_FILE}|g" \
  "${REPO_DIR}/systemd/warp-webui.service" > "${UNIT_DST}"

if command -v warp-cli >/dev/null 2>&1; then
  warp-cli --accept-tos mode proxy 2>/dev/null || true
  warp-cli --accept-tos proxy port "${WARP_PROXY_PORT}" 2>/dev/null || true
fi

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}.service"
systemctl restart "${SERVICE_NAME}.service"

# Optional: open firewall for Web UI port
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then
  ufw allow "${WARP_WEBUI_PORT}/tcp" comment 'warp-webui' || true
fi

echo
echo "=== Installed ==="
echo "Web UI:  http://${WARP_PUBLIC_HOST}:${WARP_WEBUI_PORT}/"
echo "Login:   ${WARP_WEBUI_USER} / (password you entered)"
echo "SOCKS:   127.0.0.1:${WARP_PROXY_PORT} (after WARP is installed and proxy mode enabled)"
echo "Env:     ${ENV_FILE}"
echo
echo "Next: open the Web UI and use 'Install WARP' if cloudflare-warp is not installed yet."
echo "Set proxy port in the UI or re-run install with a different WARP_PROXY_PORT in ${ENV_FILE}."
