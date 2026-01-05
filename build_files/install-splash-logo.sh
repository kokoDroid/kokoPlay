#!/usr/bin/bash

set -euo pipefail
set -x


NEW_ID=com.kokoplay.desktop
SRC=/usr/share/plasma/look-and-feel/com.valve.vapor.desktop
DST=/var/usrlocal/share/plasma/look-and-feel/$NEW_ID

rm -rf "$DST"
mkdir -p "$DST"
cp -a "$SRC/"* "$DST/"
# Ensure splash images directory exists
mkdir -p "$DST/contents/splash/images"

# Replace splash logo
curl -L -o \
"$DST/contents/splash/images/bazzite_logo.svgz" \
https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz

curl -L -o \
"$DST/contents/splash/images/bazzite_logo.svgz" \
https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz


META=/var/usrlocal/share/plasma/look-and-feel/com.kokoplay.desktop/metadata.desktop

sed -i \
  -e 's|^X-KDE-PluginInfo-Name=.*|X-KDE-PluginInfo-Name=com.kokoplay.desktop|' \
  -e 's|^Name=.*|Name=KokoPlay|' \
  -e 's|^Comment=.*|Comment=KokoPlay Plasma Look-and-Feel|' \
  "$META"


mkdir -p /etc/xdg
sed -i '/^LookAndFeelPackage=/d' /etc/xdg/kdeglobals
echo "LookAndFeelPackage=com.kokoplay.desktop" >> /etc/xdg/kdeglobals

