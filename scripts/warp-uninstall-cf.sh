#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
warp-cli --accept-tos disconnect 2>/dev/null || true
systemctl stop warp-svc 2>/dev/null || true
systemctl disable warp-svc 2>/dev/null || true
if dpkg -l cloudflare-warp >/dev/null 2>&1; then
  apt-get remove -y -qq cloudflare-warp || apt-get purge -y -qq cloudflare-warp
fi
echo "WARP package removed (config may remain under /var/lib/cloudflare-warp)."
