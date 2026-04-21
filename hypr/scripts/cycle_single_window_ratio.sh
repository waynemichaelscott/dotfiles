#!/bin/bash

# Cycle single-window aspect ratio
# Direction: "next" or "prev"
DIRECTION="${1:-next}"

RATIOS=("0 0" "1 1" "4 3" "16 9")
LABELS=("Off (fill)" "1:1 Square" "4:3" "16:9 Widescreen")

CURRENT=$(hyprctl getoption "layout:single_window_aspect_ratio" 2>/dev/null | head -1)

# Find current index
CURRENT_INDEX=0
for i in "${!RATIOS[@]}"; do
  X=$(echo "${RATIOS[$i]}" | cut -d' ' -f1)
  Y=$(echo "${RATIOS[$i]}" | cut -d' ' -f2)
  if [[ $CURRENT == *"[$X, $Y]"* ]]; then
    CURRENT_INDEX=$i
    break
  fi
done

# Calculate next index
COUNT=${#RATIOS[@]}
if [[ "$DIRECTION" == "prev" ]]; then
  NEXT_INDEX=$(( (CURRENT_INDEX - 1 + COUNT) % COUNT ))
else
  NEXT_INDEX=$(( (CURRENT_INDEX + 1) % COUNT ))
fi

hyprctl keyword layout:single_window_aspect_ratio "${RATIOS[$NEXT_INDEX]}"
notify-send "    1-Window Ratio: ${LABELS[$NEXT_INDEX]}"
