#!/usr/bin/bash
set -euo pipefail

# ------------------------------------------------------------
# Nix multi-user setup for KokoPlay
#
# Persistent Nix state:
#
#     /var/nix -> /nix
#
# Nix itself is managed by Fedora's nix-daemon/nix-system
# packages. We do not manually initialize the Nix store.
# ------------------------------------------------------------

# Fedora multi-user Nix
dnf5 -y install \
    nix-daemon \
    nix-legacy \
    busybox

# ------------------------------------------------------------
# Preserve and inspect the existing Nix configuration
# ------------------------------------------------------------

if [[ -f /etc/nix/nix.conf ]]; then
    nix-instantiate --eval \
        --expr 'builtins.readFile "/etc/nix/nix.conf"' || true
fi

mkdir -p /etc/nix

if [[ ! -f /etc/nix/nix.conf ]]; then
    cat > /etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF
elif ! grep -Eq \
    '^[[:space:]]*experimental-features[[:space:]]*=.*nix-command.*flakes|^[[:space:]]*experimental-features[[:space:]]*=.*flakes.*nix-command' \
    /etc/nix/nix.conf
then
    cat >> /etc/nix/nix.conf <<'EOF'

# KokoPlay: enable nix-command and flakes
experimental-features = nix-command flakes
EOF
fi

# ------------------------------------------------------------
# Persistent writable backing directory.
#
# IMPORTANT:
# Do not chown it to a normal user.
# Do not create /nix/store manually.
# Do not modify an existing Nix store.
# ------------------------------------------------------------

mkdir -p /var/nix
chmod 0755 /var/nix

mkdir -p /nix

# ------------------------------------------------------------
# Bind persistent /var/nix to /nix
# ------------------------------------------------------------

cat > /etc/systemd/system/nix.mount <<'EOF'
[Unit]
Description=Persistent Nix store
Before=local-fs.target
After=local-fs-pre.target

[Mount]
What=/var/nix
Where=/nix
Type=none
Options=bind

[Install]
WantedBy=local-fs.target
EOF

systemctl enable nix.mount

# ------------------------------------------------------------
# Fedora's multi-user Nix daemon.
#
# nix-daemon depends on nix-core and nix-system.
# nix-system provides the Nix system users/directories.
# ------------------------------------------------------------

systemctl enable nix-daemon.socket