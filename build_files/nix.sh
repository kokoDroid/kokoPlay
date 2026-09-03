

# Create /var/nix for the bind mount source
mkdir -p /var/nix && chmod 0755 /var/nix

# Install full Nix stack including daemon
dnf -y install nix nix-daemon nix-filesystem

# Set up bind mount so /nix is accessible at boot
printf '[Unit]\nDescription=Bind mount /var/nix to /nix\n[Mount]\nWhat=/var/nix\nWhere=/nix\nType=none\nOptions=bind\n[Install]\nWantedBy=local-fs.target\n' \
    > /etc/systemd/system/nix.mount && \
    printf '[Unit]\nDescription=Nix Daemon\nAfter=nix.mount\n[Service]\nType=simple\nExecStart=/usr/libexec/nix-daemon\n[Install]\nWantedBy=multi-user.target\n' \
    > /etc/systemd/system/nix-daemon.service && \
    systemctl enable nix.mount nix-daemon.service

# Create /nix as mount point
mkdir -p /nix

# Add users to nixbld group for multi-user builds
groupadd -r nixbld 2>/dev/null || true