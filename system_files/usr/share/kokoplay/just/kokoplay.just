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

# Install local NAS support parameters <IP> <USERNAME> <PASSWORD> <DIR>
kokoplay-install-nas:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ $# -ne 4 ]]; then
      echo "Usage: ujust kokoplay-install-nas <IP> <USERNAME> <PASSWORD> <DIR>"
      exit 1
    fi

    IP="$1"
    USER="$2"
    PASS="$3"
    DIR="$4"


# Store secrets securely
    printf '%s' "$USER" | secret-tool store --label="SMB Username" service smb key user
    printf '%s' "$PASS" | secret-tool store --label="SMB Password" service smb key pass
    printf '%s' "$IP"   | secret-tool store --label="SMB IP" service smb key ip
    printf '%s' "$DIR"  | secret-tool store --label="SMB DIR" service smb key dir


# Reload and enable user service
    systemctl --user daemon-reload
    systemctl --user enable mount-qnap.service
    systemctl --user start mount-qnap.service

echo "NAS should be mounted in home directory"
