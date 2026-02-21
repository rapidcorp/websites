#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NGINX_AVAILABLE="/etc/nginx/sites-available/projects.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/projects.conf"

echo "== websites setup verification =="
echo

echo "[1/5] Required static files"
required=(
  "$ROOT_DIR/landing/index.html"
  "$ROOT_DIR/mla/dist/index.html"
  "$ROOT_DIR/web-weaver/dist/index.html"
  "$ROOT_DIR/BVR_SUPERMARKET/dist/index.html"
)
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then
    echo "OK  $f"
  else
    echo "MISSING  $f"
    exit 1
  fi
done
echo

echo "[2/5] Nginx site files"
[[ -f "$NGINX_AVAILABLE" ]] && echo "OK  $NGINX_AVAILABLE" || { echo "MISSING  $NGINX_AVAILABLE"; exit 1; }
[[ -L "$NGINX_ENABLED" ]] && echo "OK  $NGINX_ENABLED -> $(readlink -f "$NGINX_ENABLED")" || { echo "MISSING  symlink $NGINX_ENABLED"; exit 1; }
echo

echo "[3/5] Local listener on 2005"
ss -ltn | grep -q ':2005' && echo "OK  port 2005 is listening" || { echo "MISSING  no listener on 2005"; exit 1; }
echo

echo "[4/5] Domain probes"
curl -k -sS -o /dev/null -w 'project.zeye.app -> %{http_code}\n' --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/
curl -k -sS -o /dev/null -w 'project.zeye.app/mla/ -> %{http_code}\n' --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/mla/
curl -k -sS -o /dev/null -w 'project.zeye.app/web-weaver/ -> %{http_code}\n' --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/web-weaver/
curl -k -sS -o /dev/null -w 'project.zeye.app/bvr-supermarket/ -> %{http_code}\n' --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/bvr-supermarket/
echo

echo "[5/5] Nginx config syntax"
if sudo -n true 2>/dev/null; then
  sudo nginx -t
  echo "OK  nginx -t"
else
  echo "SKIP  sudo not available for nginx -t in this shell"
fi
