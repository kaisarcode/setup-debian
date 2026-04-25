#!/bin/bash
# tailscale - Tailscale VPN for Debian 13
# Summary: Installs Tailscale using the official repository.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install Tailscale.
install_tailscale() {
    if command_exists tailscale; then
        log_skip "Tailscale is already installed."
        return 0
    fi

    log_info "Installing Tailscale via official script..."
    curl -fsSL https://tailscale.com/install.sh | sh
}

# Run the tailscale provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Tailscale Provisioning..."
    install_tailscale
    sudo tailscale set --operator=$USER
    log_success "Tailscale installation complete. Run 'sudo tailscale up' to authenticate."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
