#!/bin/bash

if [ ! -x /opt/bin/syncthing ]; then
    echo "Error: /opt/bin/syncthing not found or not executable."
    echo "Please install it by running:"
    echo "  opkg install syncthing"
    exit 1
fi

# Remount root filesystem as read-write
mount -o remount,rw /

# Define paths
SERVICE_FILE="/lib/systemd/system/syncthing.service"
SYMLINK="/lib/systemd/system/multi-user.target.wants/syncthing.service"

# Write the service configuration
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Syncthing
After=network.target wpa_supplicant.service
Requires=network.target wpa_supplicant.service

[Service]
Environment="HOME=/home/root"
ExecStartPre=/bin/sh -c 'until ip addr show wlan0 | grep -q "inet "; do sleep 1; done'
ExecStart=/opt/bin/syncthing serve --no-browser --no-restart
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Remove existing symlink if it exists
if [ -L "$SYMLINK" ] || [ -e "$SYMLINK" ]; then
    echo "Removing existing symlink: $SYMLINK"
    rm -f "$SYMLINK"
fi

# Create new symlink
ln -s "$SERVICE_FILE" "$SYMLINK"

# Remount root filesystem as read-only
mount -o remount,ro /

echo "Service file installed and symlink created successfully."

