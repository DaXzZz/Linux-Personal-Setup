#!/bin/bash

# Add stricter error handling
set -euo pipefail

# Partial name match (more flexible)
HEADSET_KEY="PRO X Wireless"
BUILTIN_KEY="Built-in Audio"

# Fallback IDs (used when one sink disappears)
FALLBACK_HEADSET_ID=73
FALLBACK_BUILTIN_ID=45

# Function to log errors and exit
error_exit() {
    local message="$1"
    echo "❌ Error: $message" >&2
    notify-send "Audio Toggle Error" "$message"
    exit 1
}

# Function to log success
log_success() {
    local message="$1"
    echo "$message"
    notify-send "Audio Output" "$message"
}

# Extract sink list
SINKS=$(wpctl status | awk '
  /Sinks:/ { capture = 1; next }
  /^[[:space:]]*├─|^[[:space:]]*└─/ { capture = 0 }
  capture {
    gsub(/[│*]/, "")
    if ($1 ~ /^[0-9]+\.$/) print
  }
') || error_exit "Failed to get audio sinks"

# Try to get sink IDs by name
HEADSET_ID=$(echo "$SINKS" | grep -i "$HEADSET_KEY" | awk '{print $1}' | tr -d '.')
BUILTIN_ID=$(echo "$SINKS" | grep -i "$BUILTIN_KEY" | awk '{print $1}' | tr -d '.')

# Fallback to known static IDs
[[ -z "$HEADSET_ID" ]] && HEADSET_ID=$FALLBACK_HEADSET_ID
[[ -z "$BUILTIN_ID" ]] && BUILTIN_ID=$FALLBACK_BUILTIN_ID

# Validate that we have usable IDs
[[ -z "$HEADSET_ID" ]] && error_exit "Could not find headset audio device"
[[ -z "$BUILTIN_ID" ]] && error_exit "Could not find built-in audio device"

# Get current default sink (robust)
CURRENT_SINK=$(wpctl status | grep -A5 "Sinks:" | grep '\*' | grep -oP '\*\s+\K[0-9]+') || error_exit "Could not determine current sink"

if [[ -z "$CURRENT_SINK" ]]; then
    error_exit "Could not determine current sink."
fi

# Toggle
if [[ "$CURRENT_SINK" == "$HEADSET_ID" ]]; then
    if ! wpctl set-default "$BUILTIN_ID"; then
        error_exit "Failed to switch to Built-in Audio"
    fi
    log_success "🔊 Switched to Built-in Audio"
else
    if ! wpctl set-default "$HEADSET_ID"; then
        error_exit "Failed to switch to PRO X Headset"
    fi
    log_success "🎧 Switched to PRO X Headset"
fi

exit 0