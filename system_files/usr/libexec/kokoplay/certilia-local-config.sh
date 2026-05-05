#!/usr/bin/env bash
set -euo pipefail


NSS_DIR="/home/$USER/.pki/nssdb"
mkdir -p "$NSS_DIR"

echo " NSSDIR: $NSS_DIR"

if [[ ! -f "$NSS_DIR/cert9.db" ]]; then
    echo "📁 Creating NSS DB..."
    certutil -N -d sql:"$NSS_DIR" --empty-password
fi

PKCS11_PATH="/usr/lib/akd/certiliamiddleware/pkcs11/libEidPkcs11.so"

if [[ ! -f "$PKCS11_PATH" ]]; then
    echo "❌ Certilia PKCS11 not found!"
    exit 1
fi


sleep 5

pkill -x brave 2>/dev/null || true
echo "📌 Registering PKCS#11 into USER profile..."
printf '\n' | modutil -dbdir "sql:$NSS_DIR" \
    -add "Certilia" \
    -libfile "$PKCS11_PATH" || true



echo "✅ Environment ready!"
