#!/bin/bash
# locales - Locale and XDG directory management for Debian 13
# Summary: Forces English system language and English XDG directory names.
# Author:  KaisarCode
# Website: https://kaisarcode.com
# License: https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Configure system locales.
setup_locales() {
    log_info "Configuring system locales (English system, Spanish AR support)..."
    
    # Ensure locales are generated
    sudo sed -i 's/^# \(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo sed -i 's/^# \(es_AR.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    sudo locale-gen
    
    # Set system-wide language to English
    sudo localectl set-locale LANG=en_US.UTF-8
    
    # Force Latam keyboard layout (X11 and Console)
    sudo localectl set-x11-keymap latam
    sudo localectl set-keymap latam
    
    # Set Time and Currency to Argentina (Optional, but keeps Buenos Aires logic)
    sudo localectl set-locale LC_TIME=es_AR.UTF-8 LC_MONETARY=es_AR.UTF-8 LC_PAPER=es_AR.UTF-8
}

# Rename XDG user directories to English.
rename_xdg_dirs() {
    local primary_user
    local user_home
    primary_user=$(id -un 1000)
    user_home=$(getent passwd "$primary_user" | cut -d: -f6)

    log_info "Standardizing XDG directories to English for $primary_user..."

    # Ensure xdg-user-dirs is installed
    sudo apt install -y xdg-user-dirs

    # Define mapping (Spanish -> English)
    declare -A mapping=(
        ["Escritorio"]="Desktop"
        ["Descargas"]="Downloads"
        ["Documentos"]="Documents"
        ["Música"]="Music"
        ["Imágenes"]="Pictures"
        ["Vídeos"]="Videos"
        ["Plantillas"]="Templates"
        ["Público"]="Public"
    )

    # Physical rename and config update
    for old_name in "${!mapping[@]}"; do
        new_name="${mapping[$old_name]}"
        if [ -d "$user_home/$old_name" ] && [ ! -d "$user_home/$new_name" ]; then
            mv "$user_home/$old_name" "$user_home/$new_name"
            log_info "Renamed $old_name to $new_name"
        fi
    done

    # Force update the config file
    sudo -u "$primary_user" bash -c "cat <<EOF > $user_home/.config/user-dirs.dirs
XDG_DESKTOP_DIR=\"\$HOME/Desktop\"
XDG_DOWNLOAD_DIR=\"\$HOME/Downloads\"
XDG_TEMPLATES_DIR=\"\$HOME/Templates\"
XDG_PUBLICSHARE_DIR=\"\$HOME/Public\"
XDG_DOCUMENTS_DIR=\"\$HOME/Documents\"
XDG_MUSIC_DIR=\"\$HOME/Music\"
XDG_PICTURES_DIR=\"\$HOME/Pictures\"
XDG_VIDEOS_DIR=\"\$HOME/Videos\"
EOF"

    log_success "XDG directories are now in English."
}

# Run the locales provisioning.
main() {
    local PROJECT_ROOT
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$PROJECT_ROOT/lib/utils.sh"

    log_info "Running Locale and XDG Provisioning..."
    setup_locales
    rename_xdg_dirs
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
