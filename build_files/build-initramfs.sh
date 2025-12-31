#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Building initramfs"

# Get kernel version and build initramfs

KERNEL_VERSION="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"

# Build directory (Bazzite staging root)
BUILD_ROOT="/tmp/image-root"

# Ensure module directory exists in staging tree
mkdir -p "$BUILD_ROOT/usr/lib/modules/$KERNEL_VERSION"

# Generate initramfs inside the staging tree
chroot "$BUILD_ROOT" /usr/bin/dracut \
  --no-hostonly \
  --kver "$KERNEL_VERSION" \
  --reproducible \
  --zstd \
  -v \
  --add ostree \
  -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

# Secure the file
chmod 0600 "$BUILD_ROOT/usr/lib/modules/$KERNEL_VERSION/initramfs.img"


log "Build completed"