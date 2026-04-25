#!/bin/bash
# workstation - Workstation Provisioning Profile for Debian 13
# Summary: Full desktop environment plus Sunshine streaming for NVIDIA hosts.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Run the workstation provisioning profile.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    require_root

    log_info "Initializing Debian 13 WORKSTATION profile (RTX Host)..."
    
    # 1. Base Layer (Core + Drivers + Tailscale)
    source "$PROJECT_ROOT/profiles/base.sh"

    # 2. Desktop Layer (MATE + Podman)
    source "$PROJECT_ROOT/profiles/desktop.sh"

    # 3. Workstation Specific (Sunshine)
    source "$PROJECT_ROOT/modules/sunshine.sh"

    log_success "WORKSTATION profile installation complete."
}

main "$@"
