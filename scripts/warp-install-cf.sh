#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
if command -v warp-cli >/dev/null 2>&1; then
  echo "cloudflare-warp already installed: $(warp-cli --version 2>/dev/null || true)"
  systemctl enable --now warp-svc 2>/dev/null || true
  warp-cli --accept-tos registration show 2>/dev/null || warp-cli --accept-tos registration new 2>/dev/null || true
  warp-cli --accept-tos mode proxy 2>/dev/null || true
  warp-cli --accept-tos proxy port "${WARP_PROXY_PORT:-1024}" 2>/dev/null || true
  exit 0
fi
apt-get update -qq
apt-get install -y -qq curl gnupg lsb-release ca-certificates
mkdir -p /usr/share/keyrings
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflare-client.list
apt-get update -qq
apt-get install -y -qq cloudflare-warp
systemctl enable --now warp-svc
sleep 2
warp-cli --accept-tos registration new || true
warp-cli --accept-tos mode proxy
warp-cli --accept-tos proxy port "${WARP_PROXY_PORT:-1024}"
echo "WARP installed."
