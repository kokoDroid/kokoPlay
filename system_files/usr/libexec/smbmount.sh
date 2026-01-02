#!/bin/bash
#sleep 10


MOUNTPOINT="$HOME/NAS"

# Retrieve credentials via Python keyring

#USERNAME=$(python3 -c "import keyring; print(keyring.get_password('smb', 'user'))")
#PASSWORD=$(python3 -c "import keyring; print(keyring.get_password('smb', 'pass'))")
# Wait up to 30 seconds for keyring credentials
for i in {1..15}; do
USERNAME=$(secret-tool lookup service smb key user)
PASSWORD=$(secret-tool lookup service smb key pass)
IP=$(secret-tool lookup service smb key ip)
DIR=$(secret-tool lookup service smb key dir)

    if [[ -n "$USERNAME" && -n "$PASSWORD" && "$USERNAME" != "None" && "$PASSWORD" != "None" ]]; then
        break
    fi
    sleep 2
done

if [[ -z "$USERNAME" || -z "$PASSWORD" || "$USERNAME" == "None" || "$PASSWORD" == "None" ]]; then
    echo "ERROR: Keyring credentials not available"
    exit 1
fi
# Ensure mount point exists
#mkdir -p "$MOUNTPOINT"

# Mount with cifs
NAS="//${IP}/${DIR}"

sudo -n /usr/bin/mount.cifs "$NAS" "$MOUNTPOINT" \
  -o user="$USERNAME",pass="$PASSWORD",uid=$(id -u),gid=$(id -g),iocharset=utf8

