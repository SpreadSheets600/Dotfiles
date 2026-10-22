#!/usr/bin/env bash
# =============================================================================
#  backup.sh — hardlink-snapshot backups of $HOME
#
#  Usage:
#    backup.sh run [--verbose]        take a snapshot (default command)
#    backup.sh list                   list snapshots, newest first
#    backup.sh prune                  apply KEEP_SNAPSHOTS retention
#    backup.sh restore SNAP PATH [DEST]
#                                     copy PATH out of SNAP into DEST
#                                     (SNAP may be "latest"; DEST defaults to
#                                      ~/restore-<timestamp>)
#    backup.sh status                 show config and last snapshot
#
#  Config: ~/.config/backup/backup.conf
#  Layout: $BACKUP_ROOT/snapshots/<timestamp>/home/    copy of $HOME
#          $BACKUP_ROOT/snapshots/<timestamp>/_system/ package list, services
#
#  Unchanged files are hardlinked to the previous snapshot, so a daily run
#  costs little extra space. This is a data backup, not a disk image: keep
#  BACKUP_ROOT on a different disk for real protection.
# =============================================================================

set -euo pipefail

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/backup/backup.conf"

# Defaults (overridable by the config file).
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/Backups}"
KEEP_SNAPSHOTS="${KEEP_SNAPSHOTS:-7}"
REQUIRE_MOUNT="${REQUIRE_MOUNT:-0}"
EXTRA_EXCLUDES=()

# shellcheck source=/dev/null
if [[ -f $CONFIG_FILE ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

BACKUP_ROOT="${BACKUP_ROOT%/}"
SNAPSHOTS_DIR="$BACKUP_ROOT/snapshots"

# Directories that are rebuildable, duplicated elsewhere, or just noise.
DEFAULT_EXCLUDES=(
  ".cache/"
  ".local/share/Trash/"
  ".local/state/dotfiles-backups/"
  ".local/share/flatpak/"
  ".local/share/Steam/"
  ".local/share/spotify-launcher/"
  ".local/share/nvim/"
  ".local/share/webapps/"
  ".local/share/GitKrakenCLI/"
  ".local/share/opencode/"
  ".npm/_cacache/"
  ".opencode/"
  ".vscode/extensions/"
  ".var/app/*/cache/"
  "Cache/"
  "Code Cache/"
  "GPUCache/"
  "CacheStorage/"
  "ShaderCache/"
  "DawnCache/"
  "CachedData/"
  "CachedExtensionVSIXs/"
  "node_modules/"
  ".venv/"
  "venv/"
  "__pycache__/"
  "*.pyc"
  ".pytest_cache/"
  "target/"
  ".thumbnails/"
  "*.bak/"
)

RSYNC_EXCLUDES=()
for pattern in "${DEFAULT_EXCLUDES[@]}" "${EXTRA_EXCLUDES[@]}"; do
  RSYNC_EXCLUDES+=(--exclude="$pattern")
done

# Never let the destination get copied into itself.
case "$BACKUP_ROOT" in
  "$HOME"/*)
    RSYNC_EXCLUDES+=(--exclude="/${BACKUP_ROOT#"$HOME"/}/")
    ;;
esac

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die()  { printf 'backup: %s\n' "$*" >&2; exit 1; }
usage() { sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'; }

on_exit() {
  local rc=$?
  if ((rc != 0)); then
    printf 'backup: failed (exit %d) — see: journalctl --user -u backup.service\n' "$rc" >&2
    if command -v notify-send >/dev/null 2>&1; then
      notify-send -u critical "Backup failed" "backup.sh exited $rc" 2>/dev/null || true
    fi
  fi
}
trap on_exit EXIT

snapshot_list() {
  [[ -d $SNAPSHOTS_DIR ]] || return 0
  find "$SNAPSHOTS_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

latest_snapshot() {
  snapshot_list | tail -n 1
}

prune() {
  [[ -d $SNAPSHOTS_DIR ]] || return 0
  ((${KEEP_SNAPSHOTS:-7} > 0)) || { log "retention disabled (KEEP_SNAPSHOTS=0)"; return 0; }

  local -a snaps
  mapfile -t snaps < <(snapshot_list)
  local count=${#snaps[@]}
  ((count > KEEP_SNAPSHOTS)) || return 0

  local -a doomed=("${snaps[@]:0:count-KEEP_SNAPSHOTS}")
  for old in "${doomed[@]}"; do
    log "pruning $old"
    rm -rf -- "${SNAPSHOTS_DIR:?}/$old"
  done
}

run_backup() {
  local verbose=${1:-0}

  if ((REQUIRE_MOUNT)) && ! mountpoint -q -- "$BACKUP_ROOT"; then
    log "skipping: $BACKUP_ROOT is not mounted"
    return 0
  fi

  mkdir -p -- "$SNAPSHOTS_DIR"
  local avail_kb
  avail_kb=$(df -Pk -- "$BACKUP_ROOT" | awk 'NR==2 {print $4}')
  ((avail_kb > 1048576)) || die "less than 1 GiB free on $BACKUP_ROOT"

  local ts snap prev
  ts=$(date +%Y-%m-%d_%H-%M-%S)
  snap="$SNAPSHOTS_DIR/$ts"
  prev=$(latest_snapshot || true)

  mkdir -p -- "$snap/home" "$snap/_system"

  local -a opts=(-aHAXx --numeric-ids --info=stats1)
  if [[ -n $prev && -d $SNAPSHOTS_DIR/$prev/home ]]; then
    opts+=(--link-dest="$SNAPSHOTS_DIR/$prev/home")
    log "snapshot $ts (hardlinks from $prev)"
  else
    log "snapshot $ts (first run)"
  fi
  ((verbose)) && opts+=(-v)

  rsync "${opts[@]}" "${RSYNC_EXCLUDES[@]}" -- "$HOME/" "$snap/home/"
  log "home copied"

  {
    printf 'snapshot: %s\n' "$ts"
    date -Is
    uname -a
    printf '\n## os-release\n'
    grep -E '^(PRETTY_NAME|ID|VERSION_ID|BUILD_ID)=' /etc/os-release 2>/dev/null || true
    printf '\n## explicit packages\n'
    pacman -Qqe 2>/dev/null || true
    printf '\n## foreign/AUR packages\n'
    pacman -Qqm 2>/dev/null || true
    printf '\n## enabled user units\n'
    systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null || true
    printf '\n## enabled system units\n'
    systemctl list-unit-files --state=enabled --no-legend 2>/dev/null || true
    printf '\n## disks\n'
    df -h 2>/dev/null || true
  } >"$snap/_system/system-info.txt"

  local f
  for f in /etc/fstab /etc/pacman.conf; do
    [[ -r $f ]] && cp --parents -- "$f" "$snap/_system/" || true
  done

  ln -sfn "snapshots/$ts" "$BACKUP_ROOT/latest"
  log "metadata written"

  prune

  log "done: $snap ($(du -sh -- "$snap" | cut -f1) apparent)"
  log "total: $(du -sh -- "$BACKUP_ROOT" | cut -f1)"
}

cmd_list() {
  [[ -d $SNAPSHOTS_DIR ]] || { log "no snapshots yet in $SNAPSHOTS_DIR"; return 0; }
  local latest now
  latest=$(latest_snapshot || true)
  while IFS= read -r d; do
    [[ $d == "$latest" ]] && now="  (latest)" || now=""
    printf '%s  %8s%s\n' "$d" "$(du -sh -- "$SNAPSHOTS_DIR/$d" | cut -f1)" "$now"
  done < <(snapshot_list | tac)
}

cmd_restore() {
  local snap_arg=${1:-latest}
  local path=${2:-}
  [[ -n $path ]] || die "usage: backup.sh restore SNAP PATH [DEST]"

  local snap
  if [[ $snap_arg == latest ]]; then
    snap="$BACKUP_ROOT/latest"
  else
    snap="$SNAPSHOTS_DIR/$snap_arg"
  fi
  [[ -d $snap ]] || die "snapshot not found: $snap_arg"

  local rel=${path#/}
  local src="$snap/home/$rel"
  [[ -e $src || -L $src ]] || die "not in snapshot: $path"

  local dest=${3:-"$HOME/restore-$(date +%Y%m%d-%H%M%S)"}
  [[ $dest != / ]] || die "refusing to restore into /"
  local dest_dir
  dest_dir=$(dirname -- "$rel")
  mkdir -p -- "$dest/$dest_dir"
  rsync -aHAX -- "$src" "$dest/$dest_dir/"
  log "restored $path -> $dest/$rel"
  log "nothing outside $dest was touched"
}

cmd_status() {
  printf 'config:        %s\n' "$CONFIG_FILE"
  printf 'backup root:   %s\n' "$BACKUP_ROOT"
  printf 'keep:          %s snapshots\n' "$KEEP_SNAPSHOTS"
  printf 'require mount: %s\n' "$REQUIRE_MOUNT"
  if [[ -d $SNAPSHOTS_DIR ]]; then
    printf 'snapshots:     %d\n' "$(snapshot_list | wc -l)"
    printf 'latest:        %s\n' "$(latest_snapshot || echo none)"
    printf 'disk used:     %s\n' "$(du -sh -- "$BACKUP_ROOT" | cut -f1)"
  else
    printf 'snapshots:     0 (not created yet)\n'
  fi
}

case ${1:-run} in
  run)      run_backup "${2:+1}" ;;
  list)     cmd_list ;;
  prune)    prune ;;
  restore)  shift; cmd_restore "$@" ;;
  status)   cmd_status ;;
  -h|--help) usage ;;
  *)        usage; exit 1 ;;
esac
