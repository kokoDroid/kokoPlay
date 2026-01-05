#!/usr/bin/bash
set -euo pipefail
set -x

# ---------------------------
# Variables
# ---------------------------
NEW_ID=com.kokoplay.desktop
SRC=/usr/share/plasma/look-and-feel/com.valve.vapor.desktop
DST=/usr/share/plasma/look-and-feel/$NEW_ID

# Copy base LNF
rm -rf "$DST"
cp -a "$SRC" "$DST"

# Replace busywidget/logo
mkdir -p "$DST/contents/splash/images" || true
curl -L -o "$DST/contents/splash/images/bazzite_logo.svgz" \
  https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz

# Update Splash.qml to point to new logo (optional if you want a separate file)
SPLASH_QML="$DST/contents/splash/Splash.qml"
sed -i 's|images/[^"]*\.svgz|images/bazzite_logo.svgz|g' "$SPLASH_QML"

# Fix metadata
sed -i \
  -e 's|"Id"[[:space:]]*:[[:space:]]*"com.valve.vapor.desktop"|"Id": "com.kokoplay.desktop"|' \
  -e 's|"Name"[[:space:]]*:[[:space:]]*"Vapor"|"Name": "KokoPlay"|' \
  -e 's|"Description"[[:space:]]*:[[:space:]]*"The stock SteamOS theme"|"Description": "KokoPlay Plasma Look-and-Feel"|' \
  "$DST/metadata.json"

# Update default profile for splash
mkdir -p "$DST/contents/defaults" || true

PROFILE="$DST/contents/defaults/Vapor.profile"
if grep -q "^\[SplashScreen\]" "$PROFILE"; then
    sed -i '/^\[SplashScreen\]/,/^\[/{s|Theme=.*|Theme=com.kokoplay.desktop|}' "$PROFILE"
else
    echo -e "\n[SplashScreen]\nTheme=com.kokoplay.desktop" >> "$PROFILE"
fi


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
