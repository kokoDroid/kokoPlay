#!/usr/bin/env bash
set -euo pipefail

SERVICE="rclone-proton-mount.service"
MOUNT_POINT="$HOME/ProtonDrive"
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
DB_PATH="$HOME/Passwords.kdbx"

echo "⚠️  This will:"
echo " - Stop and disable Proton mount service"
echo " - Unmount Proton Drive"
echo " - Delete rclone config"
echo " - Delete credential database"
echo " - Remove Proton entry from keyring"
echo
read -rp "Are you sure you want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo "[+] Stopping service if running..."
systemctl --user stop "$SERVICE" 2>/dev/null || true

echo "[+] Disabling service..."
systemctl --user disable "$SERVICE" 2>/dev/null || true

echo "[+] Unmounting Proton Drive..."
if mountpoint -q "$MOUNT_POINT"; then
    fusermount -u "$MOUNT_POINT" || true
fi

echo "[+] Removing rclone config..."
if [[ -f "$RCLONE_CONFIG" ]]; then
    rm -f "$RCLONE_CONFIG"
    echo "    Removed $RCLONE_CONFIG"
fi

echo "[+] Removing credential database..."
if [[ -f "$DB_PATH" ]]; then
    rm -f "$DB_PATH"
    echo "    Removed $DB_PATH"
fi

echo "[+] Removing keyring entry..."
# Adjust attributes to match how you stored it
secret-tool clear app keepass db kokoplay 2>/dev/null || true

echo "[+] Reloading systemd..."
systemctl --user daemon-reload

echo "✅ Proton Drive cleanup complete."
