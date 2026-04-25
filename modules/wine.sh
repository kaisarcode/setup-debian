#!/bin/bash
# wine - Wine compatibility layer for Debian 13
# Summary: Installs Wine with i386 support and winetricks.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Enable 32-bit architecture and install Wine.
install_wine() {
    log_info "Enabling i386 architecture..."
    sudo dpkg --add-architecture i386
    sudo apt update

    log_info "Installing Wine and compatibility libraries..."
    apt_install "wine"
    apt_install "wine32"
    apt_install "wine64"
    apt_install "libwine"
    apt_install "libwine:i386"
    apt_install "fonts-wine"
}

# Install winetricks and common helpers.
install_winetricks() {
    log_info "Installing winetricks and dependencies..."
    apt_install "winetricks"
    apt_install "cabextract"
    apt_install "unzip"
    apt_install "p7zip"
    apt_install "wget"
    apt_install "zenity"
}

# Run the wine provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Wine Provisioning..."
    install_wine
    install_winetricks
    log_success "Wine environment is complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
