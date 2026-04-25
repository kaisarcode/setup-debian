#!/bin/bash
# setup - Bootstrap script for KCS Debian 13
# Summary: Installs git, clones the setup-debian repo, and runs a profile.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -e

# Colors for bootstrap logging
BLUE='\033[0;34m'
NC='\033[0m'

log_bootstrap() {
    echo -e "${BLUE}[BOOTSTRAP]${NC} $1"
}

# 1. Basic environment preparation
log_bootstrap "Updating apt and installing basic tools (git, sudo, curl)..."
apt update -qq
apt install -y -qq git curl sudo

# 2. Clone or update the setup-debian repository
REPO_DIR="${SETUP_DEBIAN_DIR:-$HOME/setup-debian}"
REPO_URL="https://github.com/kaisarcode/setup-debian"

if [ ! -d "$REPO_DIR" ]; then
    log_bootstrap "Cloning repository into $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    log_bootstrap "Updating existing repository in $REPO_DIR..."
    git -C "$REPO_DIR" pull -q
fi

# 3. Make everything executable
chmod +x "$REPO_DIR"/profiles/*.sh "$REPO_DIR"/modules/*.sh 2>/dev/null || true

# 4. Execute the requested profile (default to base)
PROFILE=${1:-"base"}
log_bootstrap "Launching profile: $PROFILE..."

if [ -f "$REPO_DIR/profiles/$PROFILE.sh" ]; then
    cd "$REPO_DIR"
    exec ./profiles/"$PROFILE".sh
else
    echo "Error: Profile '$PROFILE' not found in $REPO_DIR/profiles/"
    exit 1
fi
