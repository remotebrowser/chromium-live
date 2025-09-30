#!/bin/bash
set -e

export DISPLAY=:99
export NO_AT_BRIDGE=1
export SESSION_MANAGER=""
export DBUS_SESSION_BUS_ADDRESS=""
export USER=root

echo "Starting TigerVNC server on DISPLAY=$DISPLAY..."
Xvnc -alwaysshared ${DISPLAY} -geometry 1920x1080 -depth 24 -rfbport 5900 -SecurityTypes None &
sleep 2
echo "TigerVNC server running on DISPLAY=$DISPLAY"

echo "Starting DBus session"
eval $(dbus-launch --sh-syntax)
export SESSION_MANAGER=""

echo "Starting XFCE4..."
startxfce4 >/dev/null 2>&1 & sleep 1

export GTK_THEME="Windows-10"
echo "Installing desktop theme..."
if [ ! -d ~/.themes/Windows-10 ] && [ ! -f ~/.themes/*/index.theme ]; then
    echo "Theme not found, extracting from Theme.tar.gz..."

    mkdir -p /tmp/win10-theme
    tar xz -C /tmp/win10-theme --strip-components=1 < /app/Theme.tar.gz

    mkdir -p ~/.themes/Windows-10
    cp -r /tmp/win10-theme/* ~/.themes/Windows-10/
    echo "Copied theme files to ~/.themes/Windows-10/"    
    rm -rf /tmp/win10-theme

    echo "Applying theme settings..."
    xfconf-query -c xsettings -p /Net/ThemeName -s "$GTK_THEME" --create --type string
    xfconf-query -c xfwm4 -p /general/theme -s "$GTK_THEME" --create --type string
    xfconf-query -c xsettings -p /Gtk/ThemeName -s "$GTK_THEME" --create --type string
    gtk-update-icon-cache -f ~/.themes/$GTK_THEME/gtk-*/icons 2>/dev/null || true

    echo "Restarting XFCE to apply new theme..."
    pkill -f xfsettingsd 2>/dev/null || true; sleep 1; xfsettingsd &
    pkill -f xfwm4 2>/dev/null || true; sleep 1; xfwm4 --replace &
    sleep 1

    echo "Desktop theme installed!"
else
    echo "Theme already exists, skipping installation"
fi

echo "VNC server started on port 5900"
websockify --web /usr/share/novnc/ 3001 localhost:5900 &
echo "noVNC viewable at http://localhost:3001"

xeyes &
firefox-esr duck.com &

# Keep the container running
while true; do sleep 1; done
