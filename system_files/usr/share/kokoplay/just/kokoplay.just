# Install selected Flatpaks apps
kokoplay-install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokodroid/kokoPlay/main/repo_files/flatpaks) flatpak --system -y install
    echo "Flatpaks installation complete."

# Install selected Homebrews
kokoplay-install-brews:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Homebrews..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokodroid/kokoPlay/main/repo_files/brews) brew install
    echo "Homebrews installation complete."

# Install local NAS support and directory mapping
kokoplay-install-nas:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing NAS... not yet implemented"