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

# Make NAS mountable without root password during boot

alias kpmd := kokoplay-mount-dir

[group('kokoPlay')]
kokoplay-mount-dir:
    #!/usr/bin/env bash
    set -euo pipefail   

    MOUNTPOINT="$HOME/NAS"

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
    mkdir -p "$MOUNTPOINT"

    # Mount with cifs
    NAS="//${IP}/${DIR}"

    sudo -n /usr/bin/mount.cifs "$NAS" "$MOUNTPOINT" \
      -o user="$USERNAME",pass="$PASSWORD",uid=$(id -u),gid=$(id -g),iocharset=utf8
