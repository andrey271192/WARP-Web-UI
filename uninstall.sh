#!/usr/bin/env bash
# WARP Web UI — one-command uninstaller
set -euo pipefail

INSTALL_DIR="${WARP_WEBUI_INSTALL_DIR:-/opt/warp-webui}"
ENV_FILE="/etc/default/warp-webui"
SERVICE_NAME="warp-webui"
UNIT="/etc/systemd/system/${SERVICE_NAME}.service"
BRIDGE_UNIT="/etc/systemd/system/warp-socks-bridge.service"

if [[ "${EUID:-0}" -ne 0 ]]; then
  echo "Run as root: sudo bash uninstall.sh"
  exit 1
fi

echo "=== WARP Web UI uninstaller ==="

if systemctl is-active --quiet "${SERVICE_NAME}.service" 2>/dev/null; then
  systemctl stop "${SERVICE_NAME}.service"
fi
systemctl disable "${SERVICE_NAME}.service" 2>/dev/null || true

if [[ -f "${UNIT}" ]]; then
  rm -f "${UNIT}"
fi

if systemctl is-active --quiet warp-socks-bridge.service 2>/dev/null; then
  systemctl stop warp-socks-bridge.service 2>/dev/null || true
fi
systemctl disable warp-socks-bridge.service 2>/dev/null || true
[[ -f "${BRIDGE_UNIT}" ]] && rm -f "${BRIDGE_UNIT}"

systemctl daemon-reload

read -rp "Remove application files in ${INSTALL_DIR}? [y/N]: " REMOVE_APP
if [[ "${REMOVE_APP,,}" == "y" || "${REMOVE_APP,,}" == "yes" ]]; then
  rm -rf "${INSTALL_DIR}"
fi

read -rp "Remove config ${ENV_FILE} and /etc/warp-webui/? [y/N]: " REMOVE_CFG
if [[ "${REMOVE_CFG,,}" == "y" || "${REMOVE_CFG,,}" == "yes" ]]; then
  rm -f "${ENV_FILE}"
  rm -rf /etc/warp-webui
fi

read -rp "Remove cloudflare-warp package (apt remove)? [y/N]: " REMOVE_WARP
if [[ "${REMOVE_WARP,,}" == "y" || "${REMOVE_WARP,,}" == "yes" ]]; then
  if [[ -x "${INSTALL_DIR}/scripts/warp-uninstall-cf.sh" ]]; then
    WARP_PROXY_PORT=1024 bash "${INSTALL_DIR}/scripts/warp-uninstall-cf.sh"
  elif command -v warp-cli >/dev/null 2>&1; then
    warp-cli --accept-tos disconnect 2>/dev/null || true
    systemctl stop warp-svc 2>/dev/null || true
    apt-get remove -y -qq cloudflare-warp 2>/dev/null || apt-get purge -y -qq cloudflare-warp 2>/dev/null || true
  else
    echo "cloudflare-warp not found; skipped."
  fi
fi

echo "WARP Web UI uninstalled."
