# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Dotfiles repo for an Arch Linux + Hyprland (Omarchy) desktop. Manages shared and host-specific configs for Hyprland, Waybar, and zsh via symlinks into `~/.config/`.

## Install

```bash
./install.sh
```

This symlinks configs into `~/.config/`, backing up originals to `~/.config-backup/`. Requires a matching `hosts/<hostname>/` directory for the current machine.

After changing Hyprland configs: `SUPER+SHIFT+C` reloads the config, or `hyprctl reload`.

## Architecture

### Shared vs Host-Specific Split

- **Shared configs** (top-level `hypr/`, `waybar/style.css`): Symlinked to `~/.config/` on all machines. Things like keybindings, look-and-feel, autostart, env vars.
- **Host-specific configs** (`hosts/<hostname>/`): Per-machine overrides for monitors, input devices, and waybar layout. Currently two hosts: `max` and `archie`.

The split is defined by two arrays in `install.sh`: `SYMLINKS` (shared) and `HOST_SYMLINKS` (host-specific).

### Hyprland Config Layering

`hyprland.conf` sources configs in this order:
1. Omarchy defaults from `~/.local/share/omarchy/default/hypr/` (not in this repo)
2. Omarchy theme from `~/.config/omarchy/current/theme/`
3. User overrides from `~/.config/hypr/` (this repo's shared configs)

User configs override Omarchy defaults via Hyprland's `source` directive.

### Key Files

- `hypr/bindings.conf` — Custom keybindings, Chrome profile submaps, webapp submaps
- `hypr/looknfeel.conf` — Gaps, borders, animations, dwindle layout settings
- `hypr/hyprland.conf` — Top-level config with source order + window rules
- `config.jsonc` — Waybar config (modules, workspace icons, persistent workspaces)
- `zshrc` — Oh My Zsh config with Android SDK paths, nvm, brew

### Adding a New Host

```bash
mkdir -p hosts/<hostname>/hypr hosts/<hostname>/waybar
# Add monitors.conf, input.conf, and waybar/config.jsonc for the new host
./install.sh
```

## Important Notes

- Use the `/omarchy` skill for any changes to Hyprland, Waybar, or other desktop configs managed by Omarchy.
- `config.jsonc` at the repo root is the Waybar config (not a project settings file).
- The `zshrc` (no dot) is the repo copy; `.zshrc` is a local copy — edits should go in `zshrc`.
