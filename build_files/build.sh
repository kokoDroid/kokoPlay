#!/bin/bash

set -ouex pipefail

# Import Brave signing key
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
rpm --import https://packages.microsoft.com/keys/microsoft.asc
rpm --import https://download.docker.com/linux/fedora/gpg

# Add Brave repo (CORRECT URL)
#cat > /etc/yum.repos.d/brave-browser.repo << 'EOF'
#[brave-browser]
#name=Brave Browser
#baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
#enabled=1
#gpgcheck=1
#gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
#EOF

# Install Brave
#dnf5 install -y brave-browser
dnf5 install -y adw-gtk3-theme abattis-cantarell-fonts

#dnf5 install -y gtk4


dnf5 install -y /rpms/*.rpm



# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 
#dnf5 clean all

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
