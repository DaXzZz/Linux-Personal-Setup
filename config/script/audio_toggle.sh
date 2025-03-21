#!/bin/bash

# Partial name match (more flexible)
HEADSET_KEY="PRO X Wireless"
BUILTIN_KEY="Built-in Audio"

# Fallback IDs (used when one sink disappears)
FALLBACK_HEADSET_ID=73
FALLBACK_BUILTIN_ID=45

# Extract sink list
SINKS=$(wpctl status | awk '
  /Sinks:/ { capture = 1; next }
  /^[[:space:]]*├─|^[[:space:]]*└─/ { capture = 0 }
  capture {
    gsub(/[│*]/, "")
    if ($1 ~ /^[0-9]+\.$/) print
  }
')

# Try to get sink IDs by name
HEADSET_ID=$(echo "$SINKS" | grep -i "$HEADSET_KEY" | awk '{print $1}' | tr -d '.')
BUILTIN_ID=$(echo "$SINKS" | grep -i "$BUILTIN_KEY" | awk '{print $1}' | tr -d '.')

# Fallback to known static IDs
[[ -z "$HEADSET_ID" ]] && HEADSET_ID=$FALLBACK_HEADSET_ID
[[ -z "$BUILTIN_ID" ]] && BUILTIN_ID=$FALLBACK_BUILTIN_ID

# Get current default sink (robust)
CURRENT_SINK=$(wpctl status | grep -A5 "Sinks:" | grep '\*' | grep -oP '\*\s+\K[0-9]+')

if [[ -z "$CURRENT_SINK" ]]; then
    echo "❌ Error: Could not determine current sink."
    exit 1
fi

# Toggle
if [[ "$CURRENT_SINK" == "$HEADSET_ID" ]]; then
    echo "🔊 Switching to Built-in Audio..."
    wpctl set-default "$BUILTIN_ID"
    notify-send "Audio Output" "🔊 Switched to Built-in Audio"
else
    echo "🎧 Switching to PRO X Headset..."
    wpctl set-default "$HEADSET_ID"
    notify-send "Audio Output" "🎧 Switched to PRO X Headset"
fi
