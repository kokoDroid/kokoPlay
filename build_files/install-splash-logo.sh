#!/usr/bin/bash
set -euo pipefail
set -x

# ---------------------------
# Variables
# ---------------------------
NEW_ID=com.kokoplay.desktop
SRC=/usr/share/plasma/look-and-feel/com.valve.vapor.desktop
DST=/usr/share/plasma/look-and-feel/$NEW_ID

LOGO_URL="https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz"
LOGO_FILE="bazzite_logo.svgz"

# ---------------------------
# 1️⃣ Clean destination
# ---------------------------
rm -rf "$DST"
mkdir -p "$DST"

# ---------------------------
# 2️⃣ Copy source theme
# ---------------------------
cp -a "$SRC/"* "$DST/"

META_JSON=/usr/share/plasma/look-and-feel/com.kokoplay.desktop/metadata.json

sed -i \
  -e 's|"Id"[[:space:]]*:[[:space:]]*"com.valve.vapor.desktop"|"Id": "com.kokoplay.desktop"|' \
  -e 's|"Name"[[:space:]]*:[[:space:]]*"Vapor"|"Name": "KokoPlay"|' \
  -e 's|"Description"[[:space:]]*:[[:space:]]*"The stock SteamOS theme"|"Description": "KokoPlay Plasma Look-and-Feel"|' \
  "$META_JSON"

# ---------------------------
# 3️⃣ Ensure splash images directory exists
# ---------------------------
mkdir -p "$DST/contents/splash/images"

# ---------------------------
# 4️⃣ Download custom logo
# ---------------------------
curl -L -o "$DST/contents/splash/images/$LOGO_FILE" "$LOGO_URL"

# ---------------------------
# 5️⃣ Ensure Splash.qml exists
#    If missing, create minimal one
# ---------------------------
SPLASH_QML="$DST/contents/splash/Splash.qml"

if [ ! -f "$SPLASH_QML" ]; then
cat > "$SPLASH_QML" <<'EOF'
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 640
    height: 480
    color: "black"

    Image {
        anchors.centerIn: parent
        source: "images/bazzite_logo.svgz"
    }
}
EOF
fi

# ---------------------------
# 6️⃣ Update metadata
# ---------------------------
META="$DST/metadata.desktop"

sed -i \
  -e 's|^X-KDE-PluginInfo-Name=.*|X-KDE-PluginInfo-Name=com.kokoplay.desktop|' \
  -e 's|^Name=.*|Name=KokoPlay|' \
  -e 's|^Comment=.*|Comment=KokoPlay Plasma Look-and-Feel|' \
  "$META"

# ---------------------------
# 7️⃣ Set system default Look-and-Feel
# ---------------------------
mkdir -p /etc/xdg
sed -i '/^LookAndFeelPackage=/d' /etc/xdg/kdeglobals
echo "LookAndFeelPackage=com.kokoplay.desktop" >> /etc/xdg/kdeglobals

# ---------------------------
# 8️⃣ Optional debug: verify files
# ---------------------------
ls -l "$DST"
ls -l "$DST/contents/splash/images"
ls -l "$DST/contents/splash"
cat "$DST/metadata.desktop"
