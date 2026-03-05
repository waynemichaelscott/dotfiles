#!/bin/bash

# =============================================================================
# Dotfiles Install Script
# =============================================================================
# Edit the arrays below to control which files get symlinked.
# After editing, run: ./install.sh
#
# Originals are backed up to ~/.config-backup/ before symlinking.
#
# Host-specific files live under hosts/<hostname>/ and are symlinked
# automatically based on $(hostname).
# =============================================================================

# Shared files/directories to symlink (relative to this dotfiles directory)
# Format: "source:destination" where destination is relative to ~/.config/
SYMLINKS=(
    "waybar/style.css:waybar/style.css"
    "hypr/bindings.conf:hypr/bindings.conf"
    "hypr/looknfeel.conf:hypr/looknfeel.conf"
    "hypr/autostart.conf:hypr/autostart.conf"
    "hypr/hyprland.conf:hypr/hyprland.conf"
    "hypr/envs.conf:hypr/envs.conf"
    "hypr/hypridle.conf:hypr/hypridle.conf"
    "hypr/hyprlock.conf:hypr/hyprlock.conf"
    "hypr/hyprsunset.conf:hypr/hyprsunset.conf"
    "hypr/scripts:hypr/scripts"
    "hypr/input.conf:hypr/input.conf"
)

# Shared files to symlink into $HOME (format: "source:destination" relative to ~/)
HOME_SYMLINKS=(
    "zshrc:.zshrc"
    "p10k.zsh:.p10k.zsh"
)

# Host-specific files (relative to hosts/<hostname>/)
HOST_SYMLINKS=(
    "hypr/monitors.conf:hypr/monitors.conf"
    "waybar/config.jsonc:waybar/config.jsonc"
)

# =============================================================================
# Script logic below - no need to edit
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"
HOSTNAME="$(hostname)"
HOST_DIR="$DOTFILES_DIR/hosts/$HOSTNAME"

echo "Dotfiles directory: $DOTFILES_DIR"
echo "Config directory:   $CONFIG_DIR"
echo "Host:               $HOSTNAME"
echo ""

# Check that a host directory exists for this machine
if [[ ! -d "$HOST_DIR" ]]; then
    echo "ERROR: No host directory found at $HOST_DIR"
    echo "Create it with: mkdir -p hosts/$HOSTNAME/hypr hosts/$HOSTNAME/waybar"
    echo "Then add your machine-specific configs there."
    exit 1
fi

echo "Host directory:     $HOST_DIR"
echo ""

backup_created=false

link_entry() {
    local src_path="$1"
    local dest_path="$2"
    local label="$3"

    # Check source exists
    if [[ ! -e "$src_path" ]]; then
        echo "SKIP: $label (source not found)"
        return
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
        local backup_path="$BACKUP_DIR/${dest_path#$HOME/}"
        mkdir -p "$(dirname "$backup_path")"
        cp -r "$dest_path" "$backup_path"
        echo "BACKUP: $dest_path -> $backup_path"
        rm -rf "$dest_path"
    fi

    # Create symlink
    ln -s "$src_path" "$dest_path"
    echo "LINKED: ${dest_path#$HOME/} -> $src_path"
}

# If waybar is currently a directory symlink, remove it so we can symlink
# individual files inside it instead
waybar_dest="$CONFIG_DIR/waybar"
if [[ -L "$waybar_dest" && -d "$waybar_dest" ]]; then
    echo "Replacing waybar directory symlink with individual file symlinks..."
    rm "$waybar_dest"
    mkdir -p "$waybar_dest"
fi

# Symlink shared files
echo "--- Shared configs ---"
for entry in "${SYMLINKS[@]}"; do
    src="${entry%%:*}"
    dest="${entry#*:}"
    link_entry "$DOTFILES_DIR/$src" "$CONFIG_DIR/$dest" "$src"
done

echo ""

# Symlink host-specific files
echo "--- Host-specific configs ($HOSTNAME) ---"
for entry in "${HOST_SYMLINKS[@]}"; do
    src="${entry%%:*}"
    dest="${entry#*:}"
    link_entry "$HOST_DIR/$src" "$CONFIG_DIR/$dest" "hosts/$HOSTNAME/$src"
done

# Symlink home-directory files
echo "--- Home configs ---"
for entry in "${HOME_SYMLINKS[@]}"; do
    src="${entry%%:*}"
    dest="${entry#*:}"
    link_entry "$DOTFILES_DIR/$src" "$HOME/$dest" "$src"
done

echo ""
if [[ "$backup_created" == true ]]; then
    echo "Originals backed up to: $BACKUP_DIR"
fi
echo "Done! Symlinks created."
