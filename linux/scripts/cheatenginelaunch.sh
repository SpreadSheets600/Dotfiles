#!/bin/bash

# Steam Location
STEAM_ROOT="$HOME/.steam/steam"

# Proton And WinePrefix Location
COMPAT_DIR="/home/spreadsheets600/Games/SteamPrefixes/CachyOS-Proton"
PROTON_ROOT="/usr/share/steam/compatibilitytools.d/proton-cachyos-slr"

# Cheat Engine Executable Location
CHEAT_EXE="C:\\Program Files\\Cheat Engine\\cheatengine-x86_64.exe"

# Launch Commands
WLR_NO_HARDWARE_CURSORS=1 \
GDK_BACKEND=x11 \
STEAM_COMPAT_DATA_PATH="$COMPAT_DIR" \
STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT" \
"$PROTON_ROOT/proton" run "$CHEAT_EXE"
