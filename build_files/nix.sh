#!/usr/bin/bash
set -euo pipefail

# Create /var/nix for the bind mount source
mkdir -p /var/nix && chmod 0755 /var/nix

# Install core Nix packages (daemon excluded for single-user mode)
dnf5 -y install nix-core nix-legacy

# Set up bind mount so /nix is accessible
printf '[Unit]\nDescription=Bind mount /var/nix to /nix\n[Mount]\nWhat=/var/nix\nWhere=/nix\nType=none\nOptions=bind\n[Install]\nWantedBy=local-fs.target\n' \
    > /etc/systemd/system/nix.mount && \
    systemctl enable nix.mount

# Create /nix as mount point
mkdir -p /nix