#!/usr/bin/env bash
# Wait for awww-daemon to be ready, then set a random wallpaper from ~/wallpapers/.
set -euo pipefail

until awww query >/dev/null 2>&1; do sleep 0.1; done

pick=$(find "$HOME/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n1)
[ -n "$pick" ] || { echo "no wallpapers found in ~/wallpapers" >&2; exit 1; }

exec awww img "$pick" --transition-type random
