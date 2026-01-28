#!/bin/bash

# Get a list of all window addresses, sorted by workspace and then address
windows=$(hyprctl clients -j | jq -r '.[] | .address' | sort)
current_window=$(hyprctl activewindow -j | jq -r '.address')

# Find the index of the current window
current_index=-1
i=0
for window in $windows; do
  if [ "$window" == "$current_window" ]; then
    current_index=$i
    break
  fi
  ((i++))
done

# Determine the next or previous window
if [ "$1" == "next" ]; then
  next_index=$(( (current_index + 1) % ${#windows[@]} ))
else
  next_index=$(( (current_index - 1 + ${#windows[@]}) % ${#windows[@]} ))
fi

# Get the address of the target window
target_window=$(echo "$windows" | sed -n "$((next_index + 1))p")

# Focus the target window
hyprctl dispatch focuswindow address:$target_window