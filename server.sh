#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="2005"
NGINX_CONF="$SCRIPT_DIR/projects.nginx.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/projects.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/projects.conf"

need_sudo() {
    if [[ "${EUID}" -eq 0 ]]; then
        return 0
    fi
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    echo "ERROR: sudo access is required. Run with sudo or configure passwordless sudo for nginx commands."
    exit 1
}

run_sudo() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

ensure_static_dirs() {
    local required=(
        "$SCRIPT_DIR/landing/index.html"
        "$SCRIPT_DIR/mla/dist/index.html"
        "$SCRIPT_DIR/web-weaver/dist/index.html"
        "$SCRIPT_DIR/BVR_SUPERMARKET/dist/index.html"
    )
    local missing=0
    for file in "${required[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Missing required build file: $file"
            missing=1
        fi
    done
    if [[ "$missing" -ne 0 ]]; then
        echo "ERROR: One or more static build outputs are missing. Run '$0 rebuild' first."
        exit 1
    fi
}

start() {
    echo "=== Starting websites static server on port $PORT ==="
    need_sudo
    ensure_static_dirs

    # Ensure nginx can traverse project directories.
    run_sudo chmod 755 /home/ubuntu /home/ubuntu/websites
    run_sudo chmod -R 755 "$SCRIPT_DIR/landing" "$SCRIPT_DIR/mla/dist" "$SCRIPT_DIR/web-weaver/dist" "$SCRIPT_DIR/BVR_SUPERMARKET/dist"

    # Install/enable nginx site.
    run_sudo cp "$NGINX_CONF" "$NGINX_AVAILABLE"
    run_sudo ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED"

    run_sudo nginx -t
    if run_sudo systemctl is-active --quiet nginx; then
        run_sudo systemctl reload nginx
        echo "Nginx reloaded."
    else
        run_sudo systemctl start nginx
        echo "Nginx started."
    fi

    echo
    echo "=== Server running ==="
    echo "  Landing:     https://project.zeye.app/"
    echo "  MLA:         https://project.zeye.app/mla/"
    echo "  Web-Weaver:  https://project.zeye.app/web-weaver/"
    echo "  BVR:         https://project.zeye.app/bvr-supermarket/"
    echo
}

stop() {
    echo "=== Stopping websites static server ==="
    need_sudo
    run_sudo rm -f "$NGINX_ENABLED"
    run_sudo nginx -t
    run_sudo systemctl reload nginx
    echo "Projects server stopped."
}

rebuild() {
    echo "=== Rebuilding websites projects ==="
    (cd "$SCRIPT_DIR/mla" && npx vite build --base=/mla/)
    (cd "$SCRIPT_DIR/web-weaver" && npx vite build --base=/web-weaver/)
    (cd "$SCRIPT_DIR/BVR_SUPERMARKET" && npm run build)
    echo "Build complete. Run '$0 start' to apply."
}

status() {
    echo "=== Port $PORT listener ==="
    ss -tln | grep ":$PORT" || echo "No listener on port $PORT"
    echo
    echo "=== Nginx site links ==="
    ls -l "$NGINX_ENABLED" 2>/dev/null || echo "$NGINX_ENABLED not present"
    echo
    echo "=== Public checks ==="
    curl -k -sS -o /dev/null -w "project.zeye.app -> %{http_code}\n" --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/ || true
    curl -k -sS -o /dev/null -w "project.zeye.app/mla/ -> %{http_code}\n" --resolve project.zeye.app:443:127.0.0.1 https://project.zeye.app/mla/ || true
}

case "${1:-}" in
    start)   start ;;
    stop)    stop ;;
    restart) stop; sleep 1; start ;;
    rebuild) rebuild ;;
    status)  status ;;
    *)
        echo "Usage: $0 {start|stop|restart|rebuild|status}"
        exit 1
        ;;
esac
