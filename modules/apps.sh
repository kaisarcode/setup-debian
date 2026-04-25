#!/bin/bash
# apps - Desktop Applications for Debian 13
# Summary: Installs standard desktop applications.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Install internet applications.
install_internet_apps() {
    log_info "Installing Internet applications..."
    # We install the standard Firefox (non-ESR) available in Trixie
    apt_install "firefox"
}

# Install productivity tools.
install_tools() {
    log_info "Installing desktop tools..."
    apt_install "vlc"
    apt_install "gnome-calculator"
}

# Run the apps provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Applications Provisioning..."
    install_internet_apps
    install_tools
    log_success "Applications installed."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
