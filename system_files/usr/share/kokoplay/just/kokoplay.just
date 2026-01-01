# Install only Flatpaks
kokoplay-install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokodroid/kokoplay/main/repo_files/flatpaks) flatpak --system -y install
    echo "Flatpaks installation complete."

# Install only Homebrews
kokoplay-install-brews:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Homebrews..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/kokodroid/kokoplay/main/repo_files/brews) brew install
    echo "Homebrews installation complete."

# Install local NAS support directory mapping
kokoplay-install-nas:
set -euo pipefail

    echo "Installing NAS... not yet implemented"