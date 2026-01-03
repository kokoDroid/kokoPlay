# Install selected Flatpaks apps
kokoplay-install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/flatpaks) flatpak --system -y install

    echo "Flatpaks installation complete."

# Install selected Homebrews
kokoplay-install-brews:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Homebrews..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokoDroid/kokoPlay/main/repo_files/brews) brew install

    echo "Homebrews installation complete."

# Install local NAS support parameters
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
