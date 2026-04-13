#!/bin/zsh

if ipconfig getifaddr en0 &>/dev/null; then
  sketchybar --set "$NAME" icon="󰖩"
else
  sketchybar --set "$NAME" icon="󰖪"
fi
