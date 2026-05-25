#!/usr/bin/env bash

set -euo pipefail

# Launch Delay
LAUNCH_DELAY="${LAUNCH_DELAY:-2}"

# Display Settings
RES_WIDTH="${RES_WIDTH:-1920}"
RES_HEIGHT="${RES_HEIGHT:-1080}"
REFRESH_RATE="${REFRESH_RATE:-144}"

# Flags
ENABLE_FULLSCREEN="${ENABLE_FULLSCREEN:-1}"
ENABLE_CURSOR_GRAB="${ENABLE_CURSOR_GRAB:-1}"
ENABLE_MANGOHUD="${ENABLE_MANGOHUD:-1}"
ENABLE_PRIME="${ENABLE_PRIME:-1}"

sleep "$LAUNCH_DELAY"

CMD=()

# Gamemode
if command -v gamemoderun >/dev/null 2>&1; then
    CMD+=(gamemoderun)
fi

CMD+=(
    gamescope
    -W "$RES_WIDTH"
    -H "$RES_HEIGHT"
    -r "$REFRESH_RATE"
)

# Fullscreen
if [[ "$ENABLE_FULLSCREEN" == "1" ]]; then
    CMD+=(-f)
fi

# Cursor Grab
if [[ "$ENABLE_CURSOR_GRAB" == "1" ]]; then
    CMD+=(--force-grab-cursor)
fi

CMD+=(--)

# PRIME Offload For Game Process
if [[ "$ENABLE_PRIME" == "1" ]] && command -v prime-run >/dev/null 2>&1; then
    CMD+=(prime-run)
fi

# MangoHud
if [[ "$ENABLE_MANGOHUD" == "1" ]]; then
    CMD+=(mangohud)
fi

exec "${CMD[@]}" "$@"
