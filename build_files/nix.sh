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
# packages. This is a MULTI-USER installation.
# ------------------------------------------------------------

# Fedora multi-user Nix
dnf5 -y install \
    nix-daemon \
    nix-legacy \
    busybox \
    policycoreutils-python-utils

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
# Nix uses root ownership in multi-user mode.
# ------------------------------------------------------------

mkdir -p /var/nix
chmod 0755 /var/nix

mkdir -p /nix

# ------------------------------------------------------------
# Create the persistent Nix directory structure.
#
# /nix is a bind mount of /var/nix at runtime, so initialize
# the actual persistent directories under /var/nix.
# ------------------------------------------------------------

mkdir -p \
    /var/nix/store \
    /var/nix/var/nix \
    /var/nix/var/nix/daemon-socket \
    /var/nix/var/nix/builds \
    /var/nix/var/log/nix

chmod 0755 \
    /var/nix/store \
    /var/nix/var/nix \
    /var/nix/var/nix/daemon-socket \
    /var/nix/var/nix/builds \
    /var/nix/var/log/nix

# ------------------------------------------------------------
# Initialize the Nix store/database in the persistent location.
#
# Do not initialize /nix separately because /nix is the runtime
# bind mount of /var/nix.
# ------------------------------------------------------------

if [[ ! -f /var/nix/var/nix/db/db.sqlite ]]; then
    NIX_STORE_DIR=/var/nix/store \
    NIX_STATE_DIR=/var/nix/var/nix \
    nix-store --init
fi

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
# SELinux labeling for the Nix daemon socket.
#
# systemd needs to create:
#
#     /nix/var/nix/daemon-socket/socket
#
# Fedora labels /nix as default_t, which prevents systemd from
# creating the socket there. Use var_run_t for the socket path.
#
# The /var/nix rule is needed because /var/nix is the persistent
# backing directory of the /nix bind mount.
# ------------------------------------------------------------

semanage fcontext -a -t var_run_t \
    '/nix/var/nix/daemon-socket(/.*)?' 2>/dev/null || \
semanage fcontext -m -t var_run_t \
    '/nix/var/nix/daemon-socket(/.*)?'

semanage fcontext -a -t var_run_t \
    '/var/nix/var/nix/daemon-socket(/.*)?' 2>/dev/null || \
semanage fcontext -m -t var_run_t \
    '/var/nix/var/nix/daemon-socket(/.*)?'

restorecon -RF /var/nix/var/nix/daemon-socket

# ------------------------------------------------------------
# Make unprivileged Nix clients use the system daemon.
# ------------------------------------------------------------

cat > /etc/profile.d/nix-remote.sh <<'EOF'
# KokoPlay: use the system Nix daemon for multi-user operation.
export NIX_REMOTE=daemon
EOF

chmod 0644 /etc/profile.d/nix-remote.sh

# ------------------------------------------------------------
# Fedora's multi-user Nix daemon.
#
# nix-daemon is socket activated, so enable the socket rather
# than the service itself.
# ------------------------------------------------------------

systemctl enable nix-daemon.socket

# ------------------------------------------------------------
# Apply SELinux labels to the persistent Nix tree.
# ------------------------------------------------------------

restorecon -RF /var/nix

# The daemon socket must use var_run_t.
restorecon -RF /var/nix/var/nix/daemon-socket

# ------------------------------------------------------------
# End
# ------------------------------------------------------------