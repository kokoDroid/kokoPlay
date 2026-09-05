#!/usr/bin/bash
#set -euo pipefail

# Create /var/nix for the bind mount source
#mkdir -p /var/nix && chmod 0755 /var/nix

# Install core Nix packages (daemon excluded for single-user mode)
#dnf5 -y install nix-core nix-legacy busybox

# Set up bind mount so /nix is accessible
#printf '[Unit]\nDescription=Bind mount /var/nix to /nix\n[Mount]\nWhat=/var/nix\nWhere=/nix\nType=none\nOptions=bind\n[Install]\nWantedBy=local-fs.target\n' \
 #   > /etc/systemd/system/nix.mount && \
 #   systemctl enable nix.mount

# Create /nix as mount point
#mkdir -p /nix
set -euo pipefail

# ------------------------------------------------------------
# Nix for KokoPlay
#
# Persistent writable store:
#
#   /var/nix  ->  /nix
#
# /var is writable/persistent on the installed immutable system.
# The actual login user is discovered at first boot, not during
# image construction.
# ------------------------------------------------------------

# ------------------------------------------------------------
# Install Nix
# ------------------------------------------------------------

dnf5 -y install \
    nix-core \
    nix-legacy \
    busybox

# ------------------------------------------------------------
# Validate the Nix configuration supplied by the package/image.
# Do not replace it blindly.
# ------------------------------------------------------------

if [[ -f /etc/nix/nix.conf ]]; then
    nix-instantiate --eval \
        --expr 'builtins.readFile "/etc/nix/nix.conf"' || true
fi

# Make sure the directory exists if the package did not create it.
mkdir -p /etc/nix

# Enable nix-command and flakes while preserving existing settings.
if [[ ! -f /etc/nix/nix.conf ]]; then
    cat > /etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
EOF
elif ! grep -Eq \
    '^[[:space:]]*experimental-features[[:space:]]*=.*nix-command.*flakes|^[[:space:]]*experimental-features[[:space:]]*=.*flakes.*nix-command' \
    /etc/nix/nix.conf
then
    cat >> /etc/nix/nix.conf <<'EOF'

# KokoPlay: modern Nix command and flakes support
experimental-features = nix-command flakes
EOF
fi

# ------------------------------------------------------------
# Persistent Nix store
# ------------------------------------------------------------

mkdir -p /var/nix
chmod 0755 /var/nix

# Mount point only. The actual directory is supplied by /var/nix.
mkdir -p /nix

# ------------------------------------------------------------
# /var/nix -> /nix bind mount
# ------------------------------------------------------------

cat > /etc/systemd/system/nix.mount <<'EOF'
[Unit]
Description=Bind mount persistent Nix store
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
# First-boot Nix initialization
#
# The image build cannot know the final user's UID.
# Therefore this runs on the installed system.
# ------------------------------------------------------------

cat > /usr/local/sbin/kokoplay-nix-init <<'EOF'
#!/usr/bin/bash
set -euo pipefail

# Wait briefly for the installed system's normal user to exist.
for _ in {1..60}; do

    USER_INFO="$(
        getent passwd |
        awk -F: '
            $3 >= 1000 &&
            $3 < 60000 &&
            $6 ~ "^/var/home/" &&
            $7 !~ /(nologin|false)$/ {
                print $1 ":" $3 ":" $4 ":" $6
                exit
            }
        '
    )"

    [[ -n "$USER_INFO" ]] && break
    sleep 2
done

if [[ -z "${USER_INFO:-}" ]]; then
    echo "No normal /var/home user found; Nix initialization deferred."
    exit 0
fi

IFS=: read -r NIX_USER NIX_UID NIX_GID NIX_HOME <<< "$USER_INFO"

echo "Initializing Nix for user: $NIX_USER (UID $NIX_UID)"

# The mount must be present.
if ! mountpoint -q /nix; then
    echo "/nix is not mounted."
    exit 1
fi

# /var/nix is initially empty on a new installation.
# Make the persistent single-user Nix store writable by the
# actual installed user.
# ------------------------------------------------------------
# If Nix is already initialized, leave the existing store alone.
# This is important during OS updates.
# ------------------------------------------------------------

if [[ -d /nix/store ]] && [[ -d /nix/var/nix/db ]]; then
    echo "Existing Nix installation detected; leaving it unchanged."
    exit 0
fi

# ------------------------------------------------------------
# First-time initialization only.
# ------------------------------------------------------------

echo "No existing Nix store detected; initializing Nix for $NIX_USER."

chown "$NIX_UID:$NIX_GID" /var/nix
chmod 0755 /var/nix

# Create the store directory.
if [[ ! -d /nix/store ]]; then
    mkdir /nix/store
fi

chown "$NIX_UID:$NIX_GID" /nix/store
chmod 0755 /nix/store

# Initialize the user's Nix profile/database.
#
# This is intentionally executed as the real user rather than
# root.
runuser -u "$NIX_USER" -- env \
    HOME="$NIX_HOME" \
    USER="$NIX_USER" \
    LOGNAME="$NIX_USER" \
    nix profile list >/dev/null

echo "Nix initialization completed for $NIX_USER."
EOF

chmod 0755 /usr/local/sbin/kokoplay-nix-init

# ------------------------------------------------------------
# Service that performs the user-dependent part at first boot.
# ------------------------------------------------------------

cat > /etc/systemd/system/kokoplay-nix-init.service <<'EOF'
[Unit]
Description=Initialize KokoPlay Nix store
Requires=nix.mount
After=nix.mount
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/kokoplay-nix-init
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kokoplay-nix-init.service