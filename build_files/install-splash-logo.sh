#!/usr/bin/bash

# Copy theme

mkdir -p /etc/plasma/look-and-feel
cp -r /usr/share/plasma/look-and-feel/com.valve.vapor.desktop /etc/plasma/look-and-feel/

# Paths
LOOKANDFEEL=/etc/plasma/look-and-feel/com.valve.vapor.desktop
SPLASH=$LOOKANDFEEL/contents/splash


# Download custom logo from GitHub
curl -L -o $SPLASH/images/kokoplay-logo.svgz \
    https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz

# Update Splash.qml to point to new logo
sed -i '/source:.*logo/ s|source:.*|source: "images/kokoplay-logo.svgz"|' "$SPLASH/Splash.qml"
