#!/usr/bin/bash

set -euo pipefail
set -x

# --- Variables ---
NEW_ID=com.kokoplay.desktop
SRC=/usr/share/plasma/look-and-feel/com.valve.vapor.desktop
DST=/usr/share/plasma/look-and-feel/$NEW_ID
LOGO_URL=https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz
LOGO_FILE=bazzite_logo.svgz

# --- Step 1: Copy base Look-and-Feel ---
rm -rf "$DST"
cp -a "$SRC" "$DST"

# --- Step 2: Add splash logo ---
mkdir -p "$DST/contents/splash/images"
curl -L -o "$DST/contents/splash/images/$LOGO_FILE" "$LOGO_URL"

# --- Step 3: Update Splash.qml to point to new logo ---
SPLASH_QML="$DST/contents/splash/Splash.qml"
if [ -f "$SPLASH_QML" ]; then
    sed -i 's|images/[^"]*\.svgz|images/bazzite_logo.svgz|g' "$SPLASH_QML"
fi

# --- Step 4: Ensure defaults folder exists ---
mkdir -p "$DST/contents/defaults"

# --- Step 5: Create or copy new profile ---
PROFILE="$DST/contents/defaults/KokoPlay.profile"
if [ -f "$DST/contents/defaults/Vapor.profile" ]; then
    cp "$DST/contents/defaults/Vapor.profile" "$PROFILE"
else
    touch "$PROFILE"
fi

# --- Step 6: Patch SplashScreen section ---
if grep -q "^\[SplashScreen\]" "$PROFILE"; then
    sed -i '/^\[SplashScreen\]/,/^\[/{s|Theme=.*|Theme=com.kokoplay.desktop|}' "$PROFILE"
else
    echo -e "[SplashScreen]\nTheme=com.kokoplay.desktop" >> "$PROFILE"
fi

# --- Step 7: Update metadata.desktop ---
META="$DST/metadata.desktop"
sed -i \
    -e "s|^X-KDE-PluginInfo-Name=.*|X-KDE-PluginInfo-Name=$NEW_ID|" \
    -e 's|^Name=.*|Name=KokoPlay|' \
    -e 's|^Comment=.*|Comment=KokoPlay Plasma Look-and-Feel|' \
    -e "s|^DefaultProfile=.*|DefaultProfile=KokoPlay.profile|" \
    "$META"

# --- Step 8: Update metadata.json ---
JSON="$DST/metadata.json"
if [ -f "$JSON" ]; then
    sed -i \
        -e 's|"Id"[[:space:]]*:[[:space:]]*"com.valve.vapor.desktop"|"Id": "com.kokoplay.desktop"|' \
        -e 's|"Name"[[:space:]]*:[[:space:]]*"Vapor"|"Name": "KokoPlay"|' \
        -e 's|"Description"[[:space:]]*:[[:space:]]*"The stock SteamOS theme"|"Description": "KokoPlay Plasma Look-and-Feel"|' \
        "$JSON"
fi

# --- Step 9: Set LookAndFeelPackage for first login ---
mkdir -p /etc/xdg || true
sed -i '/^LookAndFeelPackage=/d' /etc/xdg/kdeglobals || true
echo "LookAndFeelPackage=$NEW_ID" >> /etc/xdg/kdeglobals

# ---------------------------
# 8️⃣ Optional debug: verify files
# ---------------------------
ls -l "$DST"
ls -l "$DST/contents/splash/images"
ls -l "$DST/contents/splash"
cat "$DST/metadata.desktop"
