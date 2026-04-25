#!/bin/bash
# incus - Incus instance manager for Debian 13
# Summary: Installs Incus and configures basic networking.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Incus.
install_incus() {
    log_info "Installing Incus..."
    apt_install "incus"
    apt_install "incus-base"
    apt_install "qemu-system"
    apt_install "virtiofsd"
    apt_install "ebtables"
    apt_install "iptables"

    # Ensure groups exist
    if ! getent group incus-admin >/dev/null 2>&1; then
        sudo groupadd --system incus-admin
    fi

    # Add primary user to the group
    local primary_user
    primary_user=$(id -un 1000 2>/dev/null || awk -F: '$3 == 1000 {print $1}' /etc/passwd)
    if [ -n "$primary_user" ]; then
        log_info "Adding user '$primary_user' to incus-admin group..."
        sudo usermod -aG incus-admin "$primary_user"
    fi

    sudo systemctl enable --now incus
}

# Initialize Incus if not already done.
init_incus() {
    if ! sudo incus storage show default >/dev/null 2>&1; then
        log_info "Initializing Incus with default settings..."
        sudo incus admin init --auto
    fi
}

# Run the incus provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Incus Provisioning..."
    install_incus
    init_incus
    log_success "Incus Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
