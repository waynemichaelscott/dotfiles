#!/bin/bash

# Chrome profile chooser for externally-opened links.
#
# Registered as the x-scheme-handler/http(s) + text/html handler via
# chrome-profile-chooser.desktop. When you click a link in another app,
# this pops a Walker dropdown so you can pick which Chrome profile opens it,
# instead of Chrome silently reusing the last-focused profile window.
#
# HOST-SPECIFIC: Chrome's internal "Profile N" directory numbers are assigned
# next-free-integer and differ per machine. Keep this table in sync with
# hosts/max/hypr/chrome.conf (same profiles, labels, and --class values so the
# SUPER+B submap and this chooser stay consistent, incl. per-profile Waybar
# icons via hyprland-autoname-workspaces).
#
# Re-derive the Profile N -> account mapping if it ever breaks:
#   for p in ~/.config/google-chrome/Default ~/.config/google-chrome/Profile\ *; do
#     python3 -c "import json,sys; d=json.load(open(sys.argv[1]+'/Preferences')); \
#       ai=d.get('account_info') or [{}]; \
#       print(sys.argv[1].split('/')[-1], '::', ai[0].get('email','?'))" "$p"
#   done

urls=("$@")

# Menu order = display order. First letter of each line is the selection key.
options="W  Wayne (personal)
A  Acumi / ADHD
G  GymStack
D  Domus Vesta
I  Incognito"

choice=$(printf '%s' "$options" | omarchy-launch-walker --dmenu \
  --width 320 --minheight 1 --maxheight 400 -p "Open link in…" 2>/dev/null)

# Esc / no selection -> do nothing (the link simply doesn't open).
[[ -z "$choice" ]] && exit 0

case "${choice:0:1}" in
  W) profile="Default";    class="chrome-personal" ;;
  A) profile="Profile 3";  class="chrome-adhd" ;;
  G) profile="Profile 4";  class="chrome-gymstack" ;;
  D) profile="Profile 10"; class="chrome-dv" ;;
  I) exec setsid uwsm-app -- google-chrome-stable --incognito --new-window "${urls[@]}" ;;
  *) exit 0 ;;
esac

# --new-window: always open the link in a fresh window for the chosen profile,
# even if that profile is already running, rather than adding a tab to an
# existing window. --class gives the new window the right WM class for Waybar
# icons (per-profile mapping via hyprland-autoname-workspaces).
exec setsid uwsm-app -- google-chrome-stable \
  --profile-directory="$profile" --class="$class" --new-window "${urls[@]}"
