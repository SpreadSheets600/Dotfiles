#!/usr/bin/env bash
set -euo pipefail

PROG=$(basename "$0")
DRY_RUN=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) DRY_RUN=0; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) echo "Usage: $PROG [--force|-f]"; exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

LOG="${LOG:-$HOME/.wsl_optimize.log}"

log(){ echo "$*" | tee -a "$LOG"; }

run(){
  if [[ $DRY_RUN -eq 1 ]]; then
    log "(dry-run) $*"
  else
    log "+ $*"
    "$@"
  fi
}

run_root(){
  if [[ $DRY_RUN -eq 1 ]]; then
    log "(dry-run) sudo $*"
  else
    log "+ sudo $*"
    sudo "$@"
  fi
}

log "Starting safe WSL optimization"

################################
# Safe cache cleanup
################################

command -v pip3 >/dev/null && run pip3 cache purge || true
command -v npm >/dev/null && run npm cache clean --force || true

run rm -rf "$HOME/.cache/pip/"* 2>/dev/null || true
run rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true
run rm -rf "$HOME/.local/share/Trash/"* 2>/dev/null || true

################################
# Journald limits (systemd)
################################

if command -v systemctl >/dev/null; then
  run_root mkdir -p /etc/systemd/journald.conf.d

  cat <<EOF | run_root tee /etc/systemd/journald.conf.d/99-wsl.conf
[Journal]
Storage=volatile
RuntimeMaxUse=50M
EOF

  run_root systemctl restart systemd-journald
fi

################################
# WSL config (interop safe)
################################

cat <<EOF | run_root tee /etc/wsl.conf
[automount]
enabled=true
root=/mnt/
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true
EOF

log "Done. Run 'wsl --shutdown' in Windows to apply wsl.conf"
