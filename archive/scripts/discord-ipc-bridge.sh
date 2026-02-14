#!/bin/bash
SOCKET_PATH="${XDG_RUNTIME_DIR}/discord-ipc-0"

rm -f "$SOCKET_PATH"

socat UNIX-LISTEN:"$SOCKET_PATH",fork \
  EXEC:"/mnt/c/npiperelay/npiperelay.exe -ep -s //./pipe/discord-ipc-0",nofork
