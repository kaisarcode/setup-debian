#!/bin/bash
# desktop - Debian 13 Workstation Profile
# Summary: Incremental profile: Base + MATE Desktop + Podman.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Run the desktop provisioning profile.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    require_root

    log_info "Initializing Debian 13 DESKTOP profile..."
    
    # 1. Ensure Base is provisioned
    source "$PROJECT_ROOT/profiles/base.sh"

    # 2. Provision Desktop layer
    source "$PROJECT_ROOT/modules/desktop.sh"
    source "$PROJECT_ROOT/modules/podman.sh"
    source "$PROJECT_ROOT/modules/apps.sh"
    source "$PROJECT_ROOT/modules/theme.sh"
    source "$PROJECT_ROOT/modules/wine.sh"

    log_success "DESKTOP profile installation complete."
}

main "$@"
