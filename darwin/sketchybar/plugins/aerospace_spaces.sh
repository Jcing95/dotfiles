#!/usr/bin/env bash

# Get non-empty workspaces and focused workspace from aerospace
NON_EMPTY=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)
FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null | tr -d '[:space:]')

# Fall back to env var if available (from aerospace trigger)
[ -z "$FOCUSED" ] && FOCUSED="$FOCUSED_WORKSPACE"

# Build a single batched sketchybar command for all spaces
ARGS=()
for sid in $(seq 1 9); do
  if echo "$NON_EMPTY" | grep -qw "$sid" || [ "$FOCUSED" = "$sid" ]; then
    drawing="on"
  else
    drawing="off"
  fi

  if [ "$FOCUSED" = "$sid" ]; then
    icon_color="0xFFFFFFFF"
    bg_color="0x26ffffff"
  else
    icon_color="0xFF888888"
    bg_color="0x00000000"
  fi

  ARGS+=(--set space.$sid drawing="$drawing" icon.color="$icon_color" background.color="$bg_color")
done

sketchybar "${ARGS[@]}"
