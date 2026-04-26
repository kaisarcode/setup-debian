#!/bin/bash
# desktop - MATE Desktop environment for Debian 13
# Summary: Installs MATE Desktop, LightDM, and standard GUI tools.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install MATE Desktop environment.
# @return 0 on success.
install_mate_desktop() {
    log_info "Installing MATE Desktop environment..."
    apt_install "mate-desktop-environment"
    apt_install "mate-tweak"
    apt_install "mate-menu"
    apt_install "lightdm"
    apt_install "lightdm-gtk-greeter"

    apt_install "network-manager-gnome"
    apt_install "firefox-esr"
    apt_install "mate-terminal"
    apt_install "pluma"
    apt_install "engrampa"
    apt_install "caja"

    log_info "Installing Caja extensions..."
    apt_install "caja-open-terminal"
    apt_install "caja-wallpaper"
    apt_install "caja-image-converter"
    apt_install "caja-admin"
}

# Apply some basic configurations.
# @return 0 on success.
configure_desktop() {
    log_info "Configuring LightDM..."
    sudo systemctl enable lightdm 2>/dev/null || true
}

# Configure NetworkManager as the desktop network owner.
# @return 0 on success.
configure_network_manager() {
    log_info "Configuring NetworkManager for desktop Wi-Fi management..."
    sudo install -d -m 0755 /etc/NetworkManager

    if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
        sudo sed -i 's/^managed=false$/managed=true/' /etc/NetworkManager/NetworkManager.conf
        if ! grep -q '^managed=true$' /etc/NetworkManager/NetworkManager.conf; then
            printf '\n[ifupdown]\nmanaged=true\n' | sudo tee -a /etc/NetworkManager/NetworkManager.conf >/dev/null
        fi
    else
        printf '[main]\nplugins=ifupdown,keyfile\n\n[ifupdown]\nmanaged=true\n' | sudo tee /etc/NetworkManager/NetworkManager.conf >/dev/null
    fi

    remove_ifupdown_wifi_config
    sudo systemctl enable --now NetworkManager 2>/dev/null || true
    sudo systemctl try-reload-or-restart NetworkManager 2>/dev/null || true
}

# Remove legacy ifupdown Wi-Fi declarations that hide Wi-Fi from nm-applet.
# @return 0 on success.
remove_ifupdown_wifi_config() {
    local interfaces_file="/etc/network/interfaces"

    if [ ! -f "$interfaces_file" ]; then
        return 0
    fi

    if ! sudo grep -Eq '^[[:space:]]*(allow-hotplug|auto|iface)[[:space:]]+(wl|wlan)|^[[:space:]]*wpa-' "$interfaces_file"; then
        return 0
    fi

    sudo cp -n "$interfaces_file" "$interfaces_file.kcs.bak"
    printf '%s\n\n%s\n%s\n' \
        "source /etc/network/interfaces.d/*" \
        "auto lo" \
        "iface lo inet loopback" | sudo tee "$interfaces_file" >/dev/null
}

# Run the desktop provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Desktop Provisioning..."
    install_mate_desktop
    configure_desktop
    configure_network_manager
    log_success "Desktop Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
