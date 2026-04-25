#!/bin/bash
# podman - Podman container engine for Debian 13
# Summary: Installs Podman and configures rootless container support.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Podman and its dependencies.
install_podman() {
    log_info "Installing Podman and rootless dependencies..."
    apt_install "podman"
    apt_install "distrobox"
    apt_install "uidmap"
    apt_install "slirp4netns"
    apt_install "fuse-overlayfs"
}

# Configure subuids/subgids for the primary user.
configure_rootless() {
    local primary_user
    primary_user=$(id -un 1000 2>/dev/null || awk -F: '$3 == 1000 {print $1}' /etc/passwd)
    
    if [ -n "$primary_user" ]; then
        log_info "Ensuring subuid/subgid configuration for '$primary_user'..."
        if ! grep -q "^$primary_user:" /etc/subuid; then
            echo "$primary_user:100000:65536" | sudo tee -a /etc/subuid > /dev/null
        fi
        if ! grep -q "^$primary_user:" /etc/subgid; then
            echo "$primary_user:100000:65536" | sudo tee -a /etc/subgid > /dev/null
        fi
    fi
}

# Run the podman provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Podman Provisioning..."
    install_podman
    configure_rootless
    log_success "Podman Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
