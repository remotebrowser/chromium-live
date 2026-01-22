#!/bin/bash
set -e

export DISPLAY=:99
export NO_AT_BRIDGE=1
export SESSION_MANAGER=""
export DBUS_SESSION_BUS_ADDRESS=""
export USER=user

echo "Starting Tailscale daemon..."
sudo nohup tailscaled > /dev/null 2>&1 &
echo

echo "Starting TigerVNC server on DISPLAY=$DISPLAY..."
Xvnc -alwaysshared ${DISPLAY} -geometry 1920x1080 -depth 24 -rfbport 5900 -SecurityTypes None &
sleep 2
echo "TigerVNC server running on DISPLAY=$DISPLAY"

echo "Starting DBus session"
eval $(dbus-launch --sh-syntax)
export SESSION_MANAGER=""

echo "Configuring hosts file for ad blocking..."
wc -l /app/hosts
sudo tee -a /etc/hosts < /app/hosts > /dev/null

echo "Starting tinyproxy on port 8119..."
tinyproxy -d -c /app/tinyproxy.conf &

echo "Starting XFCE4..."
startxfce4 >/dev/null 2>&1 & sleep 3

xeyes &

echo "Starting Chromium..."
chromium --start-maximized --no-sandbox --remote-debugging-port=9221 --disable-dev-shm-usage --user-data-dir=$HOME/chrome-profile --proxy-server="http://127.0.0.1:8119" duck.com &
socat TCP-LISTEN:9222,fork,reuseaddr TCP:127.0.0.1:9221 &

echo "VNC server started on port 5900"
sudo websockify --web /usr/share/novnc/ 80 localhost:5900 &
echo "noVNC viewable at http://localhost:80"

# Keep the container running
while true; do sleep 1; done
