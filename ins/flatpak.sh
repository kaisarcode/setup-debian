#!/bin/bash
# flatpak - Isolated applications for Debian 13
# Summary: Installs Flatpak support and sandboxed applications like VS Code.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Flatpak support and Flathub repository.
install_flatpak_base() {
    log_info "Installing Flatpak support..."
    apt_install "flatpak"
    log_info "Adding Flathub repository..."
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# Run the flatpak provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"
    log_info "Running Flatpak Isolation Provisioning..."
    install_flatpak_base
    log_success "Flatpak apps are ready."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
