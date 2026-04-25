#!/bin/bash
# desktop - MATE Desktop environment for Debian 13
# Summary: Installs MATE Desktop, LightDM, and standard GUI tools.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install MATE Desktop environment.
install_mate_desktop() {
    log_info "Installing MATE Desktop environment..."
    apt_install "mate-desktop-environment"
    apt_install "mate-tweak"
    apt_install "mate-menu"
    apt_install "lightdm"
    apt_install "lightdm-gtk-greeter"

    # Standard GUI tools
    apt_install "network-manager-gnome"
    apt_install "mate-terminal"
    apt_install "pluma"
    apt_install "engrampa"
    apt_install "caja"

    # Caja Extensions
    log_info "Installing Caja extensions..."
    apt_install "caja-open-terminal"
    apt_install "caja-wallpaper"
    apt_install "caja-image-converter"
    apt_install "caja-admin"
}

# Apply some basic configurations.
configure_desktop() {
    log_info "Configuring LightDM..."
    sudo systemctl enable lightdm 2>/dev/null || true
}

# Run the desktop provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Desktop Provisioning..."
    install_mate_desktop
    configure_desktop
    log_success "Desktop Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
