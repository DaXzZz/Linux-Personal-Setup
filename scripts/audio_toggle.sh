#!/usr/bin/env bash
set -euo pipefail

HEADSET_KEY="PRO X Wireless Gaming Headset Analog Stereo"
BUILTIN_KEY="Built-in Audio Analog Stereo"

error_exit() {
    local message="$1"
    echo "❌ Error: $message" >&2
    notify-send "Audio Toggle Error" "$message" 2>/dev/null || true
    exit 1
}

log_success() {
    local message="$1"
    echo "$message"
    notify-send "Audio Output" "$message" 2>/dev/null || true
}

command -v wpctl >/dev/null 2>&1 || error_exit "wpctl not found"
command -v awk >/dev/null 2>&1 || error_exit "awk not found"

SINKS="$(
    wpctl status | awk '
    /Sinks:/ { capture = 1; next }
    /^[[:space:]]*├─|^[[:space:]]*└─/ { capture = 0 }
    capture {
        gsub(/[│*]/, "")
        if ($1 ~ /^[0-9]+\.$/) print
    }'
)"

[[ -n "$SINKS" ]] || error_exit "No audio sinks found"

HEADSET_ID="$(
    echo "$SINKS" | awk -v key="$HEADSET_KEY" '
    BEGIN { IGNORECASE = 1 }
    index($0, key) { gsub(/\./, "", $1); print $1; exit }
    '
)"

BUILTIN_ID="$(
    echo "$SINKS" | awk -v key="$BUILTIN_KEY" '
    BEGIN { IGNORECASE = 1 }
    index($0, key) { gsub(/\./, "", $1); print $1; exit }
    '
)"

[[ -n "$HEADSET_ID" ]] || error_exit "Could not find headset sink: $HEADSET_KEY"
[[ -n "$BUILTIN_ID" ]] || error_exit "Could not find built-in sink: $BUILTIN_KEY"

CURRENT_SINK="$(
    echo "$SINKS" | awk '
    /^\s*[0-9]+\./ && index($0, "*") {
        gsub(/[.*]/, "", $1)
        print $1
        exit
    }'
)"

# Fallback: wpctl inspect @DEFAULT_AUDIO_SINK@
if [[ -z "$CURRENT_SINK" ]]; then
    CURRENT_SINK="$(
        wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null |
        awk -F' = ' '/object.id/ {print $2; exit}' |
        tr -d '"'
    )"
fi

[[ -n "$CURRENT_SINK" ]] || error_exit "Could not determine current default sink"

if [[ "$CURRENT_SINK" == "$HEADSET_ID" ]]; then
    wpctl set-default "$BUILTIN_ID" || error_exit "Failed to switch to Built-in Audio"
    log_success "🔊 Switched to Built-in Audio"
else
    wpctl set-default "$HEADSET_ID" || error_exit "Failed to switch to PRO X Headset"
    log_success "🎧 Switched to PRO X Headset"
fi