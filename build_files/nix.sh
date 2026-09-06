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
#
# Nix store/database initialization is performed on first boot,
# not during the image build.
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
    cat > /etc/nix/nix.conf <<'NIXCONF'
experimental-features = nix-command flakes
NIXCONF
elif ! grep -Eq \
    '^[[:space:]]*experimental-features[[:space:]]*=.*nix-command.*flakes|^[[:space:]]*experimental-features[[:space:]]*=.*flakes.*nix-command' \
    /etc/nix/nix.conf
then
    cat >> /etc/nix/nix.conf <<'NIXCONF'

# KokoPlay: enable nix-command and flakes
experimental-features = nix-command flakes
NIXCONF
fi

# ------------------------------------------------------------
# Persistent writable backing directory.
#
# IMPORTANT:
# Do not chown it to a normal user.
# Nix uses root ownership in multi-user mode.
#
# The actual Nix store/database is initialized on first boot
# because /var is persistent only on the installed system.
# ------------------------------------------------------------

mkdir -p /var/nix
chmod 0755 /var/nix

mkdir -p /nix

# ------------------------------------------------------------
# Bind persistent /var/nix to /nix
# ------------------------------------------------------------

cat > /etc/systemd/system/nix.mount <<'NIXMOUNT'
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
NIXMOUNT

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

# ------------------------------------------------------------
# Make unprivileged Nix clients use the system daemon.
# ------------------------------------------------------------

cat > /etc/profile.d/nix-remote.sh <<'NIXREMOTE'
# KokoPlay: use the system Nix daemon for multi-user operation.
export NIX_REMOTE=daemon
NIXREMOTE

chmod 0644 /etc/profile.d/nix-remote.sh

# ------------------------------------------------------------
# First-boot Nix initialization.
#
# The image build cannot reliably initialize the persistent
# /var/nix because the installed system's persistent /var is
# available only after boot.
#
# This service:
#
#   1. waits for nix.mount
#   2. creates the Nix directory structure
#   3. initializes the Nix store/database
#   4. applies SELinux labels
#   5. enables the Nix daemon socket
#
# The service is skipped automatically after successful
# initialization.
# ------------------------------------------------------------

cat > /usr/local/sbin/kokoplay-nix-init <<'NIXINIT'
#!/usr/bin/bash
set -euo pipefail

# ------------------------------------------------------------
# KokoPlay Nix first-boot initialization
# ------------------------------------------------------------

# The mount must already be active.
if ! mountpoint -q /nix; then
    systemctl start nix.mount
fi

# ------------------------------------------------------------
# Create the persistent Nix directory structure.
# ------------------------------------------------------------

mkdir -p \
    /nix/store \
    /nix/var/nix \
    /nix/var/nix/daemon-socket \
    /nix/var/nix/builds \
    /nix/var/log/nix

chmod 0755 \
    /nix/store \
    /nix/var/nix \
    /nix/var/nix/daemon-socket \
    /nix/var/nix/builds \
    /nix/var/log/nix

# ------------------------------------------------------------
# Initialize the Nix store/database.
# ------------------------------------------------------------

if [[ ! -f /nix/var/nix/db/db.sqlite ]]; then
    nix-store --init
fi

# ------------------------------------------------------------
# Apply SELinux labels.
# ------------------------------------------------------------

restorecon -RF /nix

# The daemon socket must use var_run_t.
restorecon -RF /nix/var/nix/daemon-socket

# ------------------------------------------------------------
# Enable and start the multi-user Nix daemon socket.
# ------------------------------------------------------------

systemctl enable nix-daemon.socket
systemctl start nix-daemon.socket

# ------------------------------------------------------------
# Verify that the daemon socket exists.
# ------------------------------------------------------------

if [[ ! -S /nix/var/nix/daemon-socket/socket ]]; then
    echo "ERROR: Nix daemon socket was not created."
    exit 1
fi

# ------------------------------------------------------------
# Initialization complete.
# ------------------------------------------------------------

touch /var/nix/.kokoplay-nix-initialized

echo "KokoPlay multi-user Nix initialization completed."
NIXINIT

chmod 0755 /usr/local/sbin/kokoplay-nix-init

# ------------------------------------------------------------
# Verify helper script was actually created.
# ------------------------------------------------------------

test -x /usr/local/sbin/kokoplay-nix-init

# ------------------------------------------------------------
# First-boot systemd service.
# ------------------------------------------------------------

cat > /etc/systemd/system/kokoplay-nix-init.service <<'NIXSERVICE'
[Unit]
Description=KokoPlay Nix first-boot initialization
Requires=nix.mount
After=nix.mount
Before=nix-daemon.socket

ConditionPathExists=!/var/nix/.kokoplay-nix-initialized

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/kokoplay-nix-init
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
NIXSERVICE

# ------------------------------------------------------------
# Verify service was actually created.
# ------------------------------------------------------------

test -f /etc/systemd/system/kokoplay-nix-init.service

# ------------------------------------------------------------
# Enable first-boot initialization.
# ------------------------------------------------------------

systemctl enable kokoplay-nix-init.service

# ------------------------------------------------------------
# End
# ------------------------------------------------------------