#!/bin/bash

NGINX_CONF="/home/ubuntu/websites/projects.nginx.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/projects.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/projects.conf"
SUDO_PASS="zi#982851"

start() {
    echo "=== Starting Projects Server on port 2005 ==="

    # Stop any existing Node/PM2 processes on port 2005
    pm2 delete all 2>/dev/null

    # Ensure nginx can read project files
    echo "$SUDO_PASS" | sudo -S chmod 755 /home/ubuntu /home/ubuntu/websites 2>/dev/null
    echo "$SUDO_PASS" | sudo -S chmod -R 755 /home/ubuntu/websites/landing /home/ubuntu/websites/mla/dist /home/ubuntu/websites/web-weaver/dist 2>/dev/null

    # Install nginx config
    echo "$SUDO_PASS" | sudo -S cp "$NGINX_CONF" "$NGINX_AVAILABLE" 2>/dev/null
    echo "$SUDO_PASS" | sudo -S ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED" 2>/dev/null

    # Test nginx config
    echo "$SUDO_PASS" | sudo -S nginx -t 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Nginx config test failed!"
        exit 1
    fi

    # Start or reload nginx
    if echo "$SUDO_PASS" | sudo -S systemctl is-active --quiet nginx; then
        echo "$SUDO_PASS" | sudo -S systemctl reload nginx
        echo "Nginx reloaded."
    else
        echo "$SUDO_PASS" | sudo -S systemctl start nginx
        echo "Nginx started."
    fi

    echo ""
    echo "=== Server running ==="
    echo "  Landing:     https://project.zeye.app/"
    echo "  MLA:         https://project.zeye.app/mla/"
    echo "  Web-Weaver:  https://project.zeye.app/web-weaver/"
    echo ""
}

stop() {
    echo "=== Stopping Projects Server ==="
    echo "$SUDO_PASS" | sudo -S rm -f "$NGINX_ENABLED" 2>/dev/null
    echo "$SUDO_PASS" | sudo -S nginx -t 2>/dev/null && echo "$SUDO_PASS" | sudo -S systemctl reload nginx
    echo "Projects server stopped."
}

rebuild() {
    echo "=== Rebuilding projects ==="
    cd /home/ubuntu/websites/mla && npx vite build --base=/mla/
    cd /home/ubuntu/websites/web-weaver && npx vite build --base=/web-weaver/
    echo "Build complete. Run '$0 start' to apply."
}

status() {
    echo "=== Port 2005 ==="
    echo "$SUDO_PASS" | sudo -S ss -tlnp | grep 2005 2>/dev/null
    echo ""
    echo "=== Nginx status ==="
    echo "$SUDO_PASS" | sudo -S systemctl status nginx --no-pager 2>/dev/null
}

case "$1" in
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
