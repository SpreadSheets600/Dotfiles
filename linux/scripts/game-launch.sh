#!/usr/bin/env bash

set -euo pipefail

LAUNCH_DELAY="${LAUNCH_DELAY:-2}"
RES_WIDTH="${RES_WIDTH:-1920}"
RES_HEIGHT="${RES_HEIGHT:-1080}"
REFRESH_RATE="${REFRESH_RATE:-60}"

ENABLE_GAMEMODE="${ENABLE_GAMEMODE:-1}"
ENABLE_FULLSCREEN="${ENABLE_FULLSCREEN:-1}"
ENABLE_CURSOR_GRAB="${ENABLE_CURSOR_GRAB:-1}"
ENABLE_MANGOHUD="${ENABLE_MANGOHUD:-1}"
ENABLE_PRIME="${ENABLE_PRIME:-1}"

sleep "$LAUNCH_DELAY"

CMD=()

if [[ "$ENABLE_GAMEMODE" == "1" ]] && command -v gamemoderun >/dev/null 2>&1; then
  CMD+=(gamemoderun)
fi

CMD+=(
  gamescope
  -W "$RES_WIDTH"
  -H "$RES_HEIGHT"
  -r "$REFRESH_RATE"
)

if [[ "$ENABLE_FULLSCREEN" == "1" ]]; then
  CMD+=(-f)
fi

if [[ "$ENABLE_CURSOR_GRAB" == "1" ]]; then
  CMD+=(--force-grab-cursor)
fi

CMD+=(--)

if [[ "$ENABLE_PRIME" == "1" ]] && command -v prime-run >/dev/null 2>&1; then
  CMD+=(prime-run)
fi

if [[ "$ENABLE_MANGOHUD" == "1" ]]; then
  CMD+=(mangohud)
fi

exec "${CMD[@]}" "$@"
