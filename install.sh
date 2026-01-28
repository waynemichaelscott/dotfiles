#!/bin/bash

# =============================================================================
# Dotfiles Install Script
# =============================================================================
# Edit the arrays below to control which files get symlinked.
# After editing, run: ./install.sh
#
# Originals are backed up to ~/.config-backup/ before symlinking.
# =============================================================================

# Files/directories to symlink (relative to this dotfiles directory)
# Format: "source:destination" where destination is relative to ~/.config/
SYMLINKS=(
    "waybar:waybar"
    "hypr/bindings.conf:hypr/bindings.conf"
    "hypr/looknfeel.conf:hypr/looknfeel.conf"
    "hypr/autostart.conf:hypr/autostart.conf"
    "hypr/hyprland.conf:hypr/hyprland.conf"
    "hypr/envs.conf:hypr/envs.conf"
    "hypr/hypridle.conf:hypr/hypridle.conf"
    "hypr/hyprlock.conf:hypr/hyprlock.conf"
    "hypr/hyprsunset.conf:hypr/hyprsunset.conf"
    "hypr/scripts:hypr/scripts"
    # "hypr/monitors.conf:hypr/monitors.conf"    # Machine-specific, skip
    # "hypr/input.conf:hypr/input.conf"          # Machine-specific, skip
)

# =============================================================================
# Script logic below - no need to edit
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"

echo "Dotfiles directory: $DOTFILES_DIR"
echo "Config directory:   $CONFIG_DIR"
echo "Backup directory:   $BACKUP_DIR"
echo ""

backup_created=false

for entry in "${SYMLINKS[@]}"; do
    src="${entry%%:*}"
    dest="${entry#*:}"

    src_path="$DOTFILES_DIR/$src"
    dest_path="$CONFIG_DIR/$dest"

    # Check source exists
    if [[ ! -e "$src_path" ]]; then
        echo "SKIP: $src (source not found)"
        continue
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest_path")"

    # Handle existing destination
    if [[ -L "$dest_path" ]]; then
        # Already a symlink - remove and recreate
        rm "$dest_path"
    elif [[ -e "$dest_path" ]]; then
        # Exists but not a symlink - backup the original
        if [[ "$backup_created" == false ]]; then
            mkdir -p "$BACKUP_DIR"
            backup_created=true
        fi
        backup_path="$BACKUP_DIR/$dest"
        mkdir -p "$(dirname "$backup_path")"
        cp -r "$dest_path" "$backup_path"
        echo "BACKUP: $dest_path -> $backup_path"
        rm -rf "$dest_path"
    fi

    # Create symlink
    ln -s "$src_path" "$dest_path"
    echo "LINKED: $dest -> $src_path"
done

echo ""
if [[ "$backup_created" == true ]]; then
    echo "Originals backed up to: $BACKUP_DIR"
fi
echo "Done! Symlinks created."
