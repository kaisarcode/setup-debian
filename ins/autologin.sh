#!/bin/bash
# autologin - Autologin management for Debian 13
# Summary: Enables or disables automatic login for LightDM.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Enable autologin in LightDM for the primary user.
enable_autologin() {
    local primary_user
    primary_user=$(id -un 1000)
    
    if [ -f /etc/lightdm/lightdm.conf ]; then
        log_info "Enabling autologin for $primary_user..."
        sudo sed -i "s/^#autologin-user=.*/autologin-user=$primary_user/" /etc/lightdm/lightdm.conf
        sudo sed -i "s/^#autologin-user-timeout=.*/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf
        log_success "Autologin enabled for $primary_user."
    else
        log_error "LightDM configuration not found at /etc/lightdm/lightdm.conf"
        return 1
    fi
}

# Run the autologin provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Autologin Provisioning..."
    enable_autologin
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
