#!/usr/bin/env bash
set -euo pipefail

VERSION="0.9.0"
URL="https://proton.me/download/drive/cli/${VERSION}/linux-x64/proton-drive"
SHA512="3533025ba69ae112b64e3e01fbcc1ad0688136a4043f6cf6a72886967d85fdcd9ec235479c2e113171614be5225bfba93427509a05ca5aa6071d924fa7e91ca8"

curl -fL "$URL" -o /tmp/proton-drive
echo "${SHA512}  /tmp/proton-drive" | sha512sum -c -

install -D -m 0755 /tmp/proton-drive /usr/localbin/proton-drive
echo "=== PROTON DRIVE POST-INSTALL ==="
ls -l /usr/local/bin/proton-drive
file /usr/local/bin/proton-drive
/usr/local/bin/proton-drive version
rm -f /tmp/proton-drive