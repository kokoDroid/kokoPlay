#!/usr/bin/bash
set -euo pipefail

# Copy theme
mkdir -p /usr/local/share/plasma/look-and-feel
cp -r /usr/share/plasma/look-and-feel/com.valve.vapor.desktop \
      /usr/local/share/plasma/look-and-feel/

mkdir -p /usr/local/share/plasma/look-and-feel/com.valve.vapor.desktop/contents/splash/images


curl -L -o \
/usr/local/share/plasma/look-and-feel/com.valve.vapor.desktop/contents/splash/images/kokoplay-logo.svgz \
https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz

SPLASH=/usr/local/share/plasma/look-and-feel/com.valve.vapor.desktop/contents/splash

sed -i '/source:.*logo/ s|source:.*|source: "images/kokoplay-logo.svgz"|' \
"$SPLASH/Splash.qml"


