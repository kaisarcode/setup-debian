#!/bin/bash
# base - Debian 13 Base Machine Profile
# Summary: Provisions a bare-metal Debian 13 with all drivers and core tools.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Run the base provisioning profile.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    require_root

    log_info "Initializing Debian 13 BASE profile..."
    
    # Run Layer 1 modules
    source "$PROJECT_ROOT/modules/core.sh"
    source "$PROJECT_ROOT/modules/drivers.sh"
    source "$PROJECT_ROOT/modules/tailscale.sh"
    source "$PROJECT_ROOT/modules/locales.sh"

    log_success "BASE profile installation complete."
}

main "$@"
