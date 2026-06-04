#!/bin/sh
niri msg -j workspaces 2>/dev/null \
  | jq -r '[.[] | select(.output != null)] | sort_by(.idx) | map(if .is_focused then "[" + (.idx | tostring) + "]" else (.idx | tostring) end) | join("  ")' \
  || echo "?"
