#!/bin/bash
# theme - Ubuntu Yaru Theme for Debian 13
# Summary: Installs and applies the Yaru Dark theme and icons.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Yaru theme packages.
# @return 0 on success.
install_yaru() {
    log_info "Installing Yaru theme packages..."
    apt_install "yaru-theme-gtk"
    apt_install "yaru-theme-icon"
    apt_install "yaru-theme-sound"
    apt_install "papirus-icon-theme"
}

# Apply Yaru-dark theme to MATE.
# @return 0 on success.
apply_mate_theme() {
    local primary_user
    primary_user=$(id -un 1000)
    
    log_info "Applying Yaru-dark theme for $primary_user..."
    
    sudo -u "$primary_user" dbus-launch gsettings set org.mate.interface gtk-theme 'Yaru-dark'
    sudo -u "$primary_user" dbus-launch gsettings set org.mate.interface icon-theme 'Yaru-dark'
    sudo -u "$primary_user" dbus-launch gsettings set org.mate.Marco.general theme 'Yaru-dark'
}

# Run the theme provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Theme Provisioning..."
    install_yaru
    apply_mate_theme
    log_success "Yaru-dark theme applied."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
