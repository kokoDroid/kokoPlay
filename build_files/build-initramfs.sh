#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Building initramfs"

# Get kernel version and build initramfs

KERNEL_VERSION="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"


# Staging root for the image
BUILD_ROOT="/tmp/image-root"

# Ensure module directory exists inside the image root
mkdir -p "$BUILD_ROOT/usr/lib/modules/$KERNEL_VERSION"

# Build initramfs INTO the image root (not the host)
/usr/bin/dracut \
  --installroot "$BUILD_ROOT" \
  --no-hostonly \
  --kver "$KERNEL_VERSION" \
  --reproducible \
  --zstd \
  --add ostree \
  -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

# Secure permissions
chmod 0600 "$BUILD_ROOT/usr/lib/modules/$KERNEL_VERSION/initramfs.img"

log "Build completed"