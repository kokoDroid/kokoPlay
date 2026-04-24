# Install selected Flatpaks apps
[group('kokoPlay')]
kokoplay-install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/flatpaks) flatpak --system -y install

    echo "Flatpaks installation complete."

# Install selected Homebrews
[group('kokoPlay')]
kokoplay-install-brews:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Homebrews..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/brews) brew install

    echo "Homebrews installation complete."

# Install local NAS support parameters
[group('kokoPlay')]
kokoplay-install-nas:
    #!/usr/bin/env bash
    set -euo pipefail


    # Store secrets securely
    echo "Enter SMB username:"
    secret-tool store --label="SMB Username" service smb key user
    # secret-tool store service smb key user

    echo "Enter SMB password:"
    secret-tool store --label="SMB Password" service smb key pass
    # secret-tool store service smb key pass
    echo "Enter SMB server IP:"
    secret-tool store --label="SMB IP" service smb key ip
    # secret-tool store service smb key ip

    echo "Enter SMB share directory:"
    secret-tool store --label="SMB Directory" service smb key dir
    # secret-tool store service smb key dir


    # Reload and enable user service
    systemctl --user daemon-reload
    systemctl --user enable mount-qnap.service
    systemctl --user start mount-qnap.service

    echo "NAS should be mounted in home directory"

# Make NAS mountable without root password during boot
[group('kokoPlay')]
kokoplay-mount-cifs-sudo:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/mount.cifs" | sudo tee /etc/sudoers.d/$USER-mount-cifs
    sudo chmod 440 /etc/sudoers.d/$USER-mount-cifs
    sudo visudo -c

alias kpmd := kokoplay-mount-dir

# Mount additional directory to installed local NAS
[group('kokoPlay')]
kokoplay-mount-dir:
    #!/usr/bin/env bash
    set -euo pipefail   

    # Retrieve credentials via Python keyring

    USERNAME=$(secret-tool lookup service smb key user)
    PASSWORD=$(secret-tool lookup service smb key pass)
    IP=$(secret-tool lookup service smb key ip)

    if [[ -z "$USERNAME" || -z "$PASSWORD" || "$USERNAME" == "None" || "$PASSWORD" == "None" ]]; then
        echo "ERROR: Keyring credentials not available"
        exit 1
    fi

    read -p "Enter directory name to mount: " DIR

    # Ensure mount point exists
    MOUNTPOINT="$HOME/NAS/$DIR"
    mkdir -p "$MOUNTPOINT"

    # Mount with cifs
    NAS="//${IP}/${DIR}"

    sudo -n /usr/bin/mount.cifs "$NAS" "$MOUNTPOINT" \
      -o user="$USERNAME",pass="$PASSWORD",uid=$(id -u),gid=$(id -g),iocharset=utf8

alias pcs := kokoplay-proton-create-secret

# Install local NAS support parameters
[group('kokoPlay')]
kokoplay-certilia-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    bash /usr/libexec/kokoplay/certilia-setup.sh

# Proton drive encrypted DB creation for credentials
[group('kokoPlay-proton')]
kokoplay-proton-create-secret:
    #!/usr/bin/env bash
    set -euo pipefail  
    bash /usr/libexec/kokoplay/create-proton-db.sh

# Proton drive remote configuration
[group('kokoPlay-proton')]
kokoplay-proton-rclone-config:
    #!/usr/bin/env bash
    set -euo pipefail  
    python3 /usr/libexec/kokoplay/rclone-proton-config.py

# Proton drive mount
[group('kokoPlay-proton')]
kokoplay-proton-mount:
    #!/usr/bin/env bash
    set -euo pipefail  
    bash /usr/libexec/kokoplay/proton-drive-mount.sh

# Proton drive unmount
[group('kokoPlay-proton')]
kokoplay-proton-unmount:
    #!/usr/bin/env bash
    set -euo pipefail  
    bash /usr/libexec/kokoplay/proton-drive-unmount.sh

# Proton drive set mount on boot
[group('kokoPlay-proton')]
kokoplay-proton-mount-on-boot:
    #!/usr/bin/env bash
    set -euo pipefail  
    systemctl --user daemon-reload
    systemctl --user enable rclone-proton-mount.service
    systemctl --user start rclone-proton-mount.service          

# Proton drive set mount on boot disable
[group('kokoPlay-proton')]
kokoplay-proton-mount-on-boot-disable:
    #!/usr/bin/env bash
    set -euo pipefail  
    systemctl --user stop rclone-proton-mount.service  
    systemctl --user disable rclone-proton-mount.service
    systemctl --user daemon-reload

# Proton drive help
[group('kokoPlay-proton')]
kokoplay-proton-help:
    #!/usr/bin/env bash
    set -euo pipefail  

    echo "Arguments:"
    echo "create-secret : Create enrypted keepapssxc database to store proton passwords.This should be step 1"
    echo
    echo "rclone-config : This will configure proton remote, obtain access token and store it."
    echo "                It will use data from encrypted database for this.It will mount proton drive once"
    echo "                This step should be repeated only when seesion is removed or token timeouts, usually in weeks or months"
    echo
    echo "rclone-config-delete :"
    echo "                Delete rclone config only This keeps secret keepass DB."
    echo "                Use it if drive stop mounting (session removed) and configure again."
    echo
    echo "mount         : It will mount proton drive. For manual mounting after OS startup"
    echo
    echo "unmount       : It will unmount proton drive"
    echo
    echo "mount-on-boot : This will start service to mount proton drive an every boot"
    echo "                You may consider also kokoplay-mount-cifs-sudo ujust command"
    echo
    echo "mount-on-boot-disable :"
    echo "                Disable auto mount"
    echo
    echo "cleanup        : Warning: Purges all proton related configuration data including credentials"
    echo

# Proton drive clean up and reset
[group('kokoPlay-proton')]
kokoplay-proton-cleanup:
    #!/usr/bin/env bash
    set -euo pipefail  
    bash /usr/libexec/kokoplay/proton-drive-cleanup.sh

# Proton drive rclone config delete
[group('kokoPlay-proton')]
kokoplay-proton-rclone-config-delete:
    #!/usr/bin/env bash
    set -euo pipefail  

    RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"

    echo "[+] Removing rclone config..."
    if [[ -f "$RCLONE_CONFIG" ]]; then
        rm -f "$RCLONE_CONFIG"
        echo "    Removed $RCLONE_CONFIG"
    fi
