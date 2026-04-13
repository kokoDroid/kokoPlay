#!/usr/bin/env bash
set -euo pipefail

DB="$HOME/Passwords.kdbx"
ENTRY="Proton Drive"
MOUNT_POINT="$HOME/ProtonDrive"

# secret-tool attributes
SECRET_APP="keepass"
SECRET_DB="kokoplay"

echo "=== Proton Drive secure setup ==="

########################################
# 1. Get or initialize DB password
# to clear it from kee ring secret-tool clear app keepass db kokoplay
########################################
DBPASS=$(secret-tool lookup app "$SECRET_APP" db "$SECRET_DB" || true)

if [[ -z "${DBPASS:-}" ]]; then
    echo "[+] No DB password in keyring. First-time setup."
    echo "Following DB password will be stored in keyring."
    echo "The same password will be used to encrypt keepassxc database."
    echo "Database location: $DB"
    echo
    read -s -p "Enter NEW DB password: " DBPASS
    echo
    read -s -p "Confirm DB password: " DBPASS2
    echo

    [[ "$DBPASS" == "$DBPASS2" ]] || { echo "Passwords mismatch"; exit 1; }

    echo "[+] Storing DB password in keyring..."
    printf "%s" "$DBPASS" | secret-tool store \
        --label="KeePassXC DB (kokoplay)" \
        app "$SECRET_APP" db "$SECRET_DB"

    ########################################
    # Create KeePassXC DB
    ########################################
    echo "[+] Creating KeePassXC DB..."
    printf '%s\n%s\n' "$DBPASS" "$DBPASS" | keepassxc-cli db-create -p "$DB" >/dev/null

   # printf "%s" "$DBPASS" | keepassxc-cli db-create -q --set-password "$DB"
    #keepassxc-cli db-create -q --set-password "$DB"

    ########################################
    # Create Proton entry
    ########################################
    echo "[+] Creating entry: $ENTRY"

    read -p "Proton username: " PUSER
    read -s -p "Proton password: " PPASS
    echo



printf "%s\n%s\n" "$DBPASS" "$PPASS" | keepassxc-cli add "$DB" -u "$PUSER" -p "$ENTRY" >/dev/null

echo "Entry $ENTRY added."
echo "If your proton account has 2FA, as automatic adding of TOTP into keepassxc database is not possible,"
echo "please open keypassxc database in GUI and enter TOTP manually."
echo "For entry $ENTRY click on left tab ADVANCED and ADD additional attribute OTP with value for example"
echo "otpauth://totp/Proton%3Ajohn.doe%40proton.me?period=30&digits=6&algorithm=SHA1&secret=XXXXYYYYZZZZ&issuer=Proton"
echo "for username john.doe@proton.me and TOTP secret XXXXYYYYZZZZ"


else
    echo "[=] DB password retrieved from keyring- database exists"
    echo " If you want to recreate DB first delete DB: rm $DB"
    echo " Also delete entry in keyring: secret-tool clear app keepass db kokoplay"
fi

# Cleanup sensitive variables in shell memory

unset DBPASS DBPASS2 PPASS
