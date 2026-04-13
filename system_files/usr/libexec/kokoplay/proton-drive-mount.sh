#!/usr/bin/env bash
set -euo pipefail

MOUNT_POINT="$HOME/ProtonDrive"
DBPASS=$(secret-tool lookup app keepass db kokoplay)

if [ -z "$DBPASS" ]; then
    echo "Error: Rclone config password not found in keyring. Configure proton DB and rclone first" >&2
    exit 1
fi
export RCLONE_CONFIG_PASS=$DBPASS

mkdir -p "$MOUNT_POINT"

echo "[+] Mounting Proton Drive..."

fusermount -u "$MOUNT_POINT" 2>/dev/null || true


rclone mount proton: --protondrive-app-version macos-drive@1.0.0-alpha.1 "$MOUNT_POINT" \
    --vfs-cache-mode writes \
    --log-level ERROR \
    --daemon
