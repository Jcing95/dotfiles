#!/usr/bin/env bash

BATT_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT_INFO" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
CHARGING=$(echo "$BATT_INFO" | grep -q "AC Power" && echo "true" || echo "false")

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set battery icon="󰂑" label="N/A"
  exit 0
fi

if [ "$CHARGING" = "true" ]; then
  ICON="󰂄"
elif [ "$PERCENTAGE" -ge 80 ]; then
  ICON="󰁹"
elif [ "$PERCENTAGE" -ge 60 ]; then
  ICON="󰂀"
elif [ "$PERCENTAGE" -ge 40 ]; then
  ICON="󰁾"
elif [ "$PERCENTAGE" -ge 20 ]; then
  ICON="󰁻"
else
  ICON="󰁺"
fi

sketchybar --set battery icon="$ICON" label="${PERCENTAGE}%"
