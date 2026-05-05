#!/bin/bash
# containers - Container tooling for Debian 13
# Summary: Installs Podman, Distrobox, and Incus with rootless support.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Podman, Distrobox, and rootless dependencies.
# @return 0 on success.
install_podman() {
    log_info "Installing Podman and rootless dependencies..."
    apt_install "podman"
    apt_install "distrobox"
    apt_install "uidmap"
    apt_install "slirp4netns"
    apt_install "fuse-overlayfs"
}

# Configure subuids/subgids for the primary user.
# @return 0 on success.
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

# Install Incus and supporting packages.
# @return 0 on success.
install_incus() {
    log_info "Installing Incus..."
    apt_install "incus"
    apt_install "incus-base"
    apt_install "qemu-system"
    apt_install "virtiofsd"
    apt_install "ebtables"
    apt_install "iptables"

    if ! getent group incus-admin >/dev/null 2>&1; then
        sudo groupadd --system incus-admin
    fi

    local primary_user
    primary_user=$(id -un 1000 2>/dev/null || awk -F: '$3 == 1000 {print $1}' /etc/passwd)
    if [ -n "$primary_user" ]; then
        log_info "Adding user '$primary_user' to incus-admin group..."
        sudo usermod -aG incus-admin "$primary_user"
    fi

    sudo systemctl enable --now incus
}

# Initialize Incus if not already done.
# @return 0 on success.
init_incus() {
    if ! sudo incus storage show default >/dev/null 2>&1; then
        log_info "Initializing Incus with default settings..."
        sudo incus admin init --auto
    fi
}

# Run the containers provisioning.
# @return 0 on success.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Containers Provisioning..."
    install_podman
    configure_rootless
    install_incus
    init_incus
    log_success "Containers Provisioning complete."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
