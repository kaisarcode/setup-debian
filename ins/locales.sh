#!/bin/bash
# locales - Locale and XDG directory management for Debian 13
# Summary: Forces English system language and English XDG directory names.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Configure system locales.
setup_locales() {
    log_info "Configuring system locales (English system, Spanish AR support)..."

    sudo sed -i 's/^# \(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo sed -i 's/^# \(es_AR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen

    sudo update-locale LANG=en_US.UTF-8
    sudo update-locale LC_TIME=es_AR.UTF-8 LC_MONETARY=es_AR.UTF-8 LC_PAPER=es_AR.UTF-8

    sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="latam"/' /etc/default/keyboard
}

# Force XDG user directories to English.
setup_xdg_dirs() {
    local primary_user
    local user_home

    primary_user="$(id -un 1000)"
    user_home="$(getent passwd "$primary_user" | cut -d: -f6)"

    log_info "Configuring English XDG directories for $primary_user..."

    sudo apt install -y xdg-user-dirs
    sudo -u "$primary_user" mkdir -p "$user_home/.config"

    sudo -u "$primary_user" env LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 xdg-user-dirs-update --force

    log_success "XDG directories are now configured in English."
}

# Run the locales provisioning.
main() {
    local PROJECT_ROOT

    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Locale and XDG Provisioning..."

    setup_locales
    setup_xdg_dirs
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
