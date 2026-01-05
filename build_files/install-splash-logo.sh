#!/usr/bin/bash

set -euo pipefail
set -x

LNF_ID=com.valve.vapor.desktop
BASE=/var/usrlocal/share/plasma/look-and-feel/$LNF_ID

# Create directories in the REAL writable location
mkdir -p "$BASE/contents/splash/images"

# Copy base look-and-feel
cp -r /usr/share/plasma/look-and-feel/$LNF_ID/* "$BASE/"

# Download your logo
curl -L -o \
"$BASE/contents/splash/images/kokoplay-logo.svgz" \
https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/kokoplay-logo.svgz

# Patch Splash.qml
sed -i '/source:.*logo/ s|source:.*|source: "images/kokoplay-logo.svgz"|' \
"$BASE/contents/splash/Splash.qml"
