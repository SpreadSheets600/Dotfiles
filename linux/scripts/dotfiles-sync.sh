#!/usr/bin/env bash
# =============================================================================
#  dotfiles-sync.sh — commit and push the setup configs to GitHub
#
#  GitHub is the backup. Only the paths listed in
#  linux/scripts/dotfiles-sync.paths are staged (Linux setup, installer, docs,
#  shared editor configs, wallpapers) — not screenshots or Windows files.
#  Before staging, every entry in linux/scripts/dotfiles-backup.paths is copied
#  into linux/snapshots/ (configs that cannot be symlinked into the repo).
#
#  Usage:
#    dotfiles-sync.sh [run]      sync the manifest now (default; timer uses this)
#    dotfiles-sync.sh run --all  sync the whole repo (includes assets)
#    dotfiles-sync.sh list       show the manifest
#    dotfiles-sync.sh status     pending manifest changes + ahead/behind
#    dotfiles-sync.sh --dry-run  show what would be committed
#    dotfiles-sync.sh --help
#
#  Environment:
#    DOTFILES_DIR         repository path (default: ~/Dotfiles)
#    DOTFILES_REMOTE      remote name    (default: origin)
#    DOTFILES_SYNC_PATHS  manifest path  (default: <repo>/linux/scripts/dotfiles-sync.paths)
# =============================================================================

set -euo pipefail

export GIT_TERMINAL_PROMPT=0

REPO="${DOTFILES_DIR:-$HOME/Dotfiles}"
REMOTE="${DOTFILES_REMOTE:-origin}"
MANIFEST="${DOTFILES_SYNC_PATHS:-$REPO/linux/scripts/dotfiles-sync.paths}"
BACKUP_MANIFEST="${DOTFILES_BACKUP_PATHS:-$REPO/linux/scripts/dotfiles-backup.paths}"
PATHS=()

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
die()  { printf 'dotfiles-sync: %s\n' "$*" >&2; exit 1; }
notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -u critical "Dotfiles sync blocked" "$*" 2>/dev/null || true
}

usage() {
  sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
}

[[ -d $REPO/.git ]] || die "not a git repository: $REPO"
cd -- "$REPO"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ $BRANCH != HEAD ]] || die "detached HEAD; check out a branch first"

load_paths() {
  [[ -f $MANIFEST ]] || die "manifest not found: $MANIFEST"
  mapfile -t PATHS < <(
    sed -e 's/[[:space:]]*#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$MANIFEST"
  )
  ((${#PATHS[@]} > 0)) || die "manifest is empty: $MANIFEST"
}
load_paths

# One run at a time (timer + manual sync can overlap).
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/dotfiles-sync.lock"
flock -n 9 || { log "another sync is already running"; exit 0; }

scan_staged() {
  local diff bad_paths big
  diff=$(git diff --cached --unified=0 -- . || true)

  if grep -qE \
    -e 'gh[pousr]_[A-Za-z0-9]{30,}' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'sk-[A-Za-z0-9]{20,}' \
    -e 'AKIA[0-9A-Z]{16}' \
    -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' <<<"$diff"; then
    git reset -q
    notify "possible secret in staged changes; commit aborted"
    die "refusing to commit: possible secret in staged changes"
  fi

  bad_paths=$(git diff --cached --name-only \
    | grep -Ei '(^|/)(id_(rsa|dsa|ecdsa|ed25519)|\.env(\..*)?|credentials(\.json)?|hosts\.yml|[^/]+\.(pem|key|p12|pfx))$' || true)
  if [[ -n $bad_paths ]]; then
    git reset -q
    printf '%s\n' "$bad_paths" >&2
    notify "sensitive filename staged; commit aborted"
    die "refusing to commit the files above"
  fi

  big=$(git diff --cached --name-only -z | while IFS= read -r -d '' f; do
    [[ -f $f ]] || continue
    size=$(stat -c %s -- "$f")
    if ((size > 95 * 1024 * 1024)); then
      printf '%s (%d MB)\n' "$f" "$((size / 1024 / 1024))"
    fi
  done)
  if [[ -n $big ]]; then
    git reset -q
    printf '%s\n' "$big" >&2
    notify "file over 95 MB staged; commit aborted"
    die "refusing to commit files over GitHub's 100 MB limit"
  fi
}

snapshot_configs() {
  [[ -f $BACKUP_MANIFEST ]] || return 0

  local line src dest count=0
  while IFS= read -r line; do
    line=${line%%#*}
    line=${line#"${line%%[![:space:]]*}"}
    line=${line%"${line##*[![:space:]]}"}
    [[ -z $line ]] && continue
    if [[ $line != *'|'* ]]; then
      log "ignoring malformed snapshot line: $line"
      continue
    fi
    src=${line%%|*}
    dest=${line#*|}
    src=${src/#\~/$HOME}
    dest=${dest/#\~/$REPO}
    [[ -f $src ]] || continue
    mkdir -p -- "$(dirname -- "$dest")"
    cp -f -- "$src" "$dest"
    count=$((count + 1))
  done <"$BACKUP_MANIFEST"

  log "refreshed $count config snapshot(s)"
}

submodule_sync() {
  local sub="$REPO/wallpapers" branch
  [[ -d $sub ]] || return 0
  git -C "$sub" rev-parse --git-dir >/dev/null 2>&1 || return 0   # not initialised

  branch=$(git config -f "$REPO/.gitmodules" --get submodule.wallpapers.branch 2>/dev/null || true)
  branch=${branch:-master}

  # A freshly cloned submodule is on a detached HEAD; commits made there would
  # never reach a branch, so move onto the tracking branch first.
  if ! git -C "$sub" symbolic-ref -q HEAD >/dev/null; then
    git -C "$sub" checkout -q "$branch" \
      || { log "wallpapers: detached HEAD, checkout $branch failed; skipping"; return 0; }
  fi

  if [[ -n $(git -C "$sub" status --porcelain) ]]; then
    log "staging wallpapers submodule"
    git -C "$sub" add -A
    git -C "$sub" commit -q -m "auto: wallpapers sync $(date '+%Y-%m-%d %H:%M')" || true
  fi

  if git -C "$sub" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git -C "$sub" push --quiet || log "wallpapers: push failed, will retry next tick"
  else
    git -C "$sub" push --quiet -u origin "$branch" || log "wallpapers: push failed, will retry next tick"
  fi
}

cmd_run() {
  local mode=${1:-}

  if [[ -d .git/rebase-merge || -d .git/rebase-apply || -f .git/MERGE_HEAD ]]; then
    notify "merge/rebase already in progress in $REPO"
    die "merge/rebase in progress; finish or abort it first"
  fi

  # Refresh the copies of configs that cannot be symlinked, then stage.
  snapshot_configs

  # wallpapers/ is a submodule: commit and push it first, otherwise the parent
  # would pin a commit that does not exist on GitHub yet.
  submodule_sync

  # Start from a clean index so unrelated staged files never sneak in.
  git reset -q
  if [[ $mode == --all ]]; then
    git add -A
    log "staging whole repo (--all)"
  else
    git add -A -- "${PATHS[@]}"
    log "staging ${#PATHS[@]} manifest paths"
  fi

  if git diff --cached --quiet; then
    log "no changes to commit"
  else
    scan_staged
    git commit -q -m "auto: dotfiles sync $(date '+%Y-%m-%d %H:%M')"
    log "committed $(git rev-parse --short HEAD): $(git show --stat --oneline HEAD | tail -n 1)"
  fi

  local has_upstream=0
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    has_upstream=1
    if ! git fetch --quiet "$REMOTE"; then
      log "offline: changes are committed locally and will push next tick"
      return 0
    fi
    if ! git merge-base --is-ancestor '@{u}' HEAD; then
      log "remote moved; rebasing"
      if ! git pull --rebase --autostash --quiet; then
        git rebase --abort 2>/dev/null || true
        notify "rebase conflict in $REPO; resolve manually"
        die "rebase conflict; resolve it manually"
      fi
    fi
  else
    log "no upstream for $BRANCH; pushing with -u"
  fi

  if ((has_upstream)); then
    if ! git push --quiet "$REMOTE" "$BRANCH"; then
      log "push failed: commit is safe locally and will retry"
      return 0
    fi
  else
    if ! git push --quiet -u "$REMOTE" "$BRANCH"; then
      log "push failed: commit is safe locally and will retry"
      return 0
    fi
  fi

  log "pushed to $REMOTE/$BRANCH"
}

cmd_status() {
  printf 'repo:     %s\n' "$REPO"
  printf 'branch:   %s\n' "$BRANCH"
  printf 'manifest: %s (%d paths)\n\n' "$MANIFEST" "${#PATHS[@]}"
  git status --short --branch -- "${PATHS[@]}"
  printf 'last:     %s\n' "$(git log -1 --format='%h %s (%cr)')"
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    local counts
    counts=$(git rev-list --left-right --count '@{u}...HEAD')
    printf 'remote:   %s behind, %s ahead\n' "${counts%%$'\t'*}" "${counts##*$'\t'}"
  else
    printf 'remote:   no upstream configured\n'
  fi
}

cmd_dry() {
  printf 'repo:     %s (%s)\n' "$REPO" "$BRANCH"
  printf 'manifest: %s (%d paths)\n\n' "$MANIFEST" "${#PATHS[@]}"
  git status --short -- "${PATHS[@]}"
  printf '\n'
  git diff --stat -- "${PATHS[@]}"
}

cmd_list() {
  printf 'manifest: %s\n\n' "$MANIFEST"
  grep -vE '^[[:space:]]*(#|$)' "$MANIFEST"
}

case ${1:-run} in
  run)          shift; cmd_run "${1:-}" ;;
  list|paths)   cmd_list ;;
  status)       cmd_status ;;
  --dry-run|-n) cmd_dry ;;
  -h|--help)    usage ;;
  *)            usage; exit 1 ;;
esac
