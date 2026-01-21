#!/bin/bash

set -ouex pipefail

mkdir -p /usr/lib/tmpfiles.d
cat > /usr/lib/tmpfiles.d/fontconfig.conf <<'EOF'
d /var/cache/fontconfig 0755 root root -
EOF

# Clean cache early
rm -rf /var/cache/*

# Ensure fontconfig cache dir exists
mkdir -p /var/cache/fontconfig
chmod 1777 /var/cache/fontconfig

# Fontconfig config
mkdir -p /etc/fonts/conf.d
cat > /etc/fonts/conf.d/99-local-fonts.conf <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>/usr/share/fonts</dir>
  <dir>/usr/share/fonts/google-noto</dir>
  <cachedir>/var/cache/fontconfig</cachedir>
</fontconfig>
EOF

# Build cache (non-fatal)
fc-cache -rv || true


# Import Brave signing key
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
rpm --import https://packages.microsoft.com/keys/microsoft.asc
rpm --import https://download.docker.com/linux/fedora/gpg



dnf5 install -y adw-gtk3-theme abattis-cantarell-fonts
#dnf5 reinstall -y pango
#dnf5 install -y pango-devel
dnf5 install -y icu

dnf5 install -y glibc-langpack-en




#dnf5 install -y /rpms/*.rpm
echo "Installing local RPMs..."

# 1️⃣ Install all RPMs except MegaSync
echo "Installing all RPMs except MegaSync..."
dnf5 install -y $(find /rpms -maxdepth 1 -type f -name '*.rpm' ! -name 'megasync-*.rpm')

# 2️⃣ Install MegaSync separately with --noscripts
MEGASYNC_RPM=$(find /rpms -maxdepth 1 -type f -name 'megasync-*.rpm')

if [[ -f "$MEGASYNC_RPM" ]]; then
    echo "Installing MegaSync RPM without running post-install scripts..."
    dnf5 install -y "$MEGASYNC_RPM" --setopt=tsflags=noscripts
else
    echo "No MegaSync RPM found in /rpms, skipping..."
fi

echo "All RPMs installed successfully."

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#dnf5 install -y tmux 
#dnf5 clean all

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File
systemctl --user mask app-megasync@autostart.service

systemctl enable podman.socket
