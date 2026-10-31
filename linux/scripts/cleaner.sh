#!/usr/bin/env bash
#
# cleaner.sh — safe, fast disk cleaner and disk-usage analyzer for Linux desktops.
#
# Cleans user-space caches by default (browser, thumbnails, trash, dev tooling,
# Electron/Flatpak app caches) and can optionally include system caches
# (pacman, journal) plus Docker pruning.
#
# Run `cleaner.sh help` for usage, `cleaner.sh scan` to see what is reclaimable.

set -uo pipefail

VERSION="2.0.0"
PROG=${0##*/}

HOME_DIR=${HOME:-}
STATE_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/cleaner"
HISTORY_FILE="$STATE_DIR/history.log"

TMP_AGE=3
EXCLUDES=""
DRY_RUN=0
ASSUME_YES=0
JSON=0
SYSTEM=0
AGGRESSIVE=0
QUIET=0
USE_COLOR="auto"
DOCKER_FILTER=""
DOCKER_ALL=0
DOCKER_VOLUMES=0
ANALYZE_LIMIT=20

CATALOG_ORDER=(
  cache thumbnails browser trash tmp appcache
  npm yarn pnpm pip uv cargo go gradle electron
  pkgcache journal orphans
)

DEV_IDS=(npm yarn pnpm pip uv cargo go gradle electron)
USER_IDS=(cache thumbnails browser trash tmp appcache)
SYSTEM_IDS=(pkgcache journal orphans)
DOCKER_IDS=(docker_images docker_containers docker_volumes docker_build)
DEFAULT_IDS=(cache thumbnails browser trash tmp)

BROWSER_NAMES=(mozilla google-chrome chromium BraveSoftware microsoft-edge vivaldi opera opera-gx)
BROWSER_PATHS=(
  "$HOME_DIR/.cache/mozilla"
  "$HOME_DIR/.cache/google-chrome"
  "$HOME_DIR/.cache/chromium"
  "$HOME_DIR/.cache/BraveSoftware"
  "$HOME_DIR/.cache/microsoft-edge"
  "$HOME_DIR/.cache/vivaldi"
  "$HOME_DIR/.cache/opera"
  "$HOME_DIR/.cache/opera-gx"
)

# ---------------------------------------------------------------- output ----

setup_color() {
  local want=$USE_COLOR
  [[ ${NO_COLOR:-} != "" ]] && want=never
  if [[ $want == always ]]; then
    USE_COLOR=1
  elif [[ $want == never ]] || [[ ! -t 1 ]]; then
    USE_COLOR=0
  else
    USE_COLOR=1
  fi
}

c_reset='' c_bold='' c_dim='' c_red='' c_green='' c_yellow='' c_blue='' c_cyan=''
init_colors() {
  setup_color
  ((USE_COLOR)) || return 0
  c_reset=$'\033[0m' c_bold=$'\033[1m' c_dim=$'\033[2m'
  c_red=$'\033[31m' c_green=$'\033[32m' c_yellow=$'\033[33m'
  c_blue=$'\033[34m' c_cyan=$'\033[36m'
}

say() { ((QUIET)) || printf '%s\n' "$*"; }
info() { ((QUIET)) || printf '%s\n' "$*"; }
warn() { ((QUIET)) || printf '%swarn:%s %s\n' "$c_yellow" "$c_reset" "$*" >&2; }
die() {
  printf '%serror:%s %s\n' "$c_red" "$c_reset" "$*" >&2
  exit 1
}

human() {
  local bytes=${1:-0}
  awk -v b="$bytes" 'BEGIN{
    split("B KB MB GB TB PB", u, " ");
    i = 1;
    while (b >= 1024 && i < 6) { b /= 1024; i++ }
    if (i == 1) printf "%d %s", b, u[i];
    else printf "%.1f %s", b, u[i];
  }'
}

json_escape() {
  local s=${1-}
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

json_bool() { if (($1)); then printf 'true'; else printf 'false'; fi; }

# --------------------------------------------------------------- helpers ----

expand_tilde() {
  local p=${1-}
  case $p in
    "~") printf '%s' "$HOME_DIR" ;;
    "~/"*) printf '%s/%s' "$HOME_DIR" "${p#\~/}" ;;
    *) printf '%s' "$p" ;;
  esac
}

is_safe_path() {
  local p=${1-}
  [[ -n $p && $p == /* ]] || return 1
  case $p in
    /|/home|/root|/tmp|/var|/usr|"$HOME_DIR"|"${HOME_DIR:-/nonexistent}") return 1 ;;
  esac
  [[ $p == "$HOME_DIR"/* || $p == /tmp/* ]] || return 1
  [[ $p != *"/../"* && $p != */.. ]] || return 1
  return 0
}

measure() {
  local path=$1 size
  [[ -e $path || -L $path ]] || { printf '0'; return; }
  size=$(du -sb -- "$path" 2>/dev/null | awk 'NR==1{print $1}')
  printf '%s' "${size:-0}"
}

measure_many() {
  local total=0 path size
  for path in "$@"; do
    size=$(measure "$path")
    total=$((total + size))
  done
  printf '%s' "$total"
}

remove_path() {
  local path=$1
  [[ -e $path || -L $path ]] || return 0
  if ! is_safe_path "$path"; then
    warn "refusing to remove unsafe path: $path"
    return 1
  fi
  if ((DRY_RUN)); then
    info "  ${c_dim}would remove${c_reset} $path"
    return 0
  fi
  rm -rf -- "$path" 2>/dev/null || return 1
  return 0
}

remove_contents() {
  local dir=$1 entry failed=0
  [[ -d $dir ]] || return 0
  while IFS= read -r -d '' entry; do
    remove_path "$entry" || failed=1
  done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  return $failed
}

have() { command -v "$1" >/dev/null 2>&1; }

confirm() {
  local prompt=$1
  ((ASSUME_YES)) && return 0
  [[ -t 0 ]] || die "refusing to delete without --yes in a non-interactive shell"
  local answer
  read -r -p "$prompt [y/N] " answer
  [[ ${answer,,} == y || ${answer,,} == yes ]]
}

# ------------------------------------------------------------- categories ----

category_exists() {
  case $1 in
    cache|thumbnails|browser|trash|tmp|appcache|npm|yarn|pnpm|pip|uv|cargo|go|gradle|electron|pkgcache|journal|orphans|docker_images|docker_containers|docker_volumes|docker_build) return 0 ;;
    *) return 1 ;;
  esac
}

category_group() {
  case $1 in
    pkgcache|journal|orphans) printf 'system' ;;
    npm|yarn|pnpm|pip|uv|cargo|go|gradle|electron) printf 'dev' ;;
    docker_*) printf 'docker' ;;
    *) printf 'user' ;;
  esac
}

category_label() {
  case $1 in
    cache) printf 'User cache' ;;
    thumbnails) printf 'Thumbnails' ;;
    browser) printf 'Browser caches' ;;
    trash) printf 'Trash' ;;
    tmp) printf 'Old files in /tmp' ;;
    appcache) printf 'App caches (Electron/Flatpak)' ;;
    npm) printf 'npm cache' ;;
    yarn) printf 'Yarn cache' ;;
    pnpm) printf 'pnpm store' ;;
    pip) printf 'pip cache' ;;
    uv) printf 'uv cache' ;;
    cargo) printf 'Cargo registry' ;;
    go) printf 'Go build cache' ;;
    gradle) printf 'Gradle caches' ;;
    electron) printf 'Electron/node-gyp downloads' ;;
    pkgcache) printf 'pacman package cache' ;;
    journal) printf 'systemd journal' ;;
    orphans) printf 'Orphaned packages (list only)' ;;
    docker_images) printf 'Docker images' ;;
    docker_containers) printf 'Docker containers' ;;
    docker_volumes) printf 'Docker volumes' ;;
    docker_build) printf 'Docker build cache' ;;
    *) printf '%s' "$1" ;;
  esac
}

category_icon() {
  case $1 in
    cache) printf 'cached' ;;
    thumbnails) printf 'image' ;;
    browser) printf 'public' ;;
    trash) printf 'delete' ;;
    tmp) printf 'schedule' ;;
    appcache) printf 'apps' ;;
    npm|yarn|pnpm) printf 'javascript' ;;
    pip|uv) printf 'terminal' ;;
    cargo) printf 'settings_ethernet' ;;
    go) printf 'code' ;;
    gradle) printf 'build' ;;
    electron) printf 'memory' ;;
    pkgcache) printf 'inventory_2' ;;
    journal) printf 'article' ;;
    orphans) printf 'help' ;;
    docker_*) printf 'deployed_code' ;;
    *) printf 'folder' ;;
  esac
}

resolve_ids() {
  local out=() id
  for id in "$@"; do
    case $id in
      all) out+=("${USER_IDS[@]}" "${DEV_IDS[@]}") ;;
      user) out+=("${USER_IDS[@]}") ;;
      dev|developer) out+=("${DEV_IDS[@]}") ;;
      system) out+=("${SYSTEM_IDS[@]}") ;;
      docker) out+=("${DOCKER_IDS[@]}") ;;
      *) out+=("$id") ;;
    esac
  done
  printf '%s\n' "${out[@]}" | awk 'NF && !seen[$0]++'
}

parse_excludes() {
  local raw=${EXCLUDES//,/ }
  local -a user=()
  read -r -a user <<<"$raw" 2>/dev/null || true
  CACHE_EXCLUDES=("${PROTECTED_CACHE[@]}" "${BROWSER_NAMES[@]}" "${DEV_CACHE_NAMES[@]}" thumbnails "${user[@]}")
}

PROTECTED_CACHE=(yay paru pikaur)
DEV_CACHE_NAMES=(yarn pip uv go-build electron electron-builder node-gyp)
CACHE_EXCLUDES=()

cache_excluded() {
  local name=$1 skip
  for skip in "${CACHE_EXCLUDES[@]}"; do
    [[ -n $skip && $name == "$skip" ]] && return 0
  done
  return 1
}

# --------------------------------------------------------------- measures ----

cache_size() {
  local root="$HOME_DIR/.cache" entry name total=0 size
  [[ -d $root ]] || { printf '0'; return; }
  while IFS= read -r -d '' entry; do
    name=${entry##*/}
    cache_excluded "$name" && continue
    size=$(measure "$entry")
    total=$((total + size))
  done < <(find "$root" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  printf '%s' "$total"
}

appcache_entries() {
  local base sub
  for base in "$HOME_DIR"/.config/* "$HOME_DIR"/.var/app/*; do
    [[ -d $base ]] || continue
    for sub in Cache GPUCache "Code Cache" CachedData DawnGraphiteCache DawnWebGPUCache "Service Worker/CacheStorage"; do
      [[ -e $base/$sub ]] && printf '%s\0' "$base/$sub"
    done
  done
  for base in "$HOME_DIR"/.var/app/*/cache; do
    [[ -d $base ]] && printf '%s\0' "$base"
  done
}

appcache_size() {
  local entry total=0 size
  while IFS= read -r -d '' entry; do
    size=$(measure "$entry")
    total=$((total + size))
  done < <(appcache_entries)
  printf '%s' "$total"
}

appcache_available() {
  local first
  first=$(appcache_entries | head -c 1)
  [[ -n $first ]]
}

docker_available() {
  have docker && docker info >/dev/null 2>&1
}

docker_size_for() {
  docker_available || { printf '0'; return; }
  local type=$1
  docker system df --format '{{.Type}}|{{.Size}}|{{.Reclaimable}}' 2>/dev/null |
    awk -F'|' -v want="$type" '
      function tobytes(s,   n,u,m) {
        s = s; gsub(/^[ \t]+|[ \t]+$/, "", s);
        sub(/ *\(.*$/, "", s);
        if (match(s, /^[0-9.]+/)) { n = substr(s, 1, RLENGTH) + 0; u = substr(s, RLENGTH + 1) }
        else return 0;
        if (u ~ /[kK]?B$/) return n;
        if (u ~ /[mM]B$/) return n * 1024 * 1024;
        if (u ~ /[gG]B$/) return n * 1024 * 1024 * 1024;
        if (u ~ /[tT]B$/) return n * 1024 * 1024 * 1024 * 1024;
        return n;
      }
      tolower($1) ~ tolower(want) { print tobytes($3); found = 1; exit }
      END { if (!found) print 0 }
    '
}

category_available() {
  local id=$1
  case $id in
    cache) [[ -d $HOME_DIR/.cache ]] ;;
    thumbnails) [[ -d $HOME_DIR/.cache/thumbnails ]] ;;
    trash) [[ -d $HOME_DIR/.local/share/Trash ]] ;;
    browser) local p; for p in "${BROWSER_PATHS[@]}"; do [[ -d $p ]] && return 0; done; return 1 ;;
    tmp) [[ -d /tmp ]] ;;
    appcache) appcache_available ;;
    npm) [[ -d $HOME_DIR/.npm ]] ;;
    yarn) [[ -d $HOME_DIR/.cache/yarn ]] ;;
    pnpm) have pnpm || [[ -d $HOME_DIR/.local/share/pnpm ]] ;;
    pip) [[ -d $HOME_DIR/.cache/pip ]] ;;
    uv) [[ -d $HOME_DIR/.cache/uv ]] ;;
    cargo) [[ -d $HOME_DIR/.cargo ]] ;;
    go) [[ -d $HOME_DIR/.cache/go-build ]] ;;
    gradle) [[ -d $HOME_DIR/.gradle ]] ;;
    electron) [[ -d $HOME_DIR/.cache/electron || -d $HOME_DIR/.cache/node-gyp ]] ;;
    pkgcache) [[ -d /var/cache/pacman/pkg ]] ;;
    journal) have journalctl ;;
    orphans) have pacman ;;
    docker_*) docker_available ;;
    *) return 1 ;;
  esac
}

category_detail() {
  local id=$1
  case $id in
    cache) printf '%s' "$HOME_DIR/.cache" ;;
    thumbnails) printf '%s' "$HOME_DIR/.cache/thumbnails" ;;
    browser) printf '%s' "$HOME_DIR/.cache/{mozilla,chromium,...}" ;;
    trash) printf '%s' "$HOME_DIR/.local/share/Trash" ;;
    tmp) printf '/tmp (older than %s days, owner only)' "$TMP_AGE" ;;
    appcache) printf '%s' "$HOME_DIR/.config/*/{Cache,GPUCache} + ~/.var/app/*/cache" ;;
    npm) printf '%s' "$HOME_DIR/.npm/_cacache" ;;
    yarn) printf '%s' "$HOME_DIR/.cache/yarn" ;;
    pnpm) printf 'pnpm store' ;;
    pip) printf '%s' "$HOME_DIR/.cache/pip" ;;
    uv) printf '%s' "$HOME_DIR/.cache/uv" ;;
    cargo) printf '%s' "$HOME_DIR/.cargo/registry" ;;
    go) printf '%s' "$HOME_DIR/.cache/go-build" ;;
    gradle) printf '%s' "$HOME_DIR/.gradle/caches" ;;
    electron) printf '%s' "$HOME_DIR/.cache/{electron,node-gyp,electron-builder}" ;;
    pkgcache) printf '/var/cache/pacman/pkg (keeps 1 version)' ;;
    journal) printf 'journalctl --vacuum-size=200M' ;;
    orphans) printf 'pacman -Qtdq' ;;
    docker_images) printf 'docker image prune -a' ;;
    docker_containers) printf 'docker container prune' ;;
    docker_volumes) printf 'docker volume prune' ;;
    docker_build) printf 'docker builder prune -a' ;;
    *) printf '' ;;
  esac
}

category_size() {
  case $1 in
    cache) cache_size ;;
    thumbnails) measure "$HOME_DIR/.cache/thumbnails" ;;
    browser) measure_many "${BROWSER_PATHS[@]}" ;;
    trash) measure_many "$HOME_DIR/.local/share/Trash/files" "$HOME_DIR/.local/share/Trash/info" ;;
    tmp) tmp_size ;;
    appcache) appcache_size ;;
    npm) measure "$HOME_DIR/.npm/_cacache" ;;
    yarn) measure "$HOME_DIR/.cache/yarn" ;;
    pnpm) pnpm_size ;;
    pip) measure "$HOME_DIR/.cache/pip" ;;
    uv) measure "$HOME_DIR/.cache/uv" ;;
    cargo) measure_many "$HOME_DIR/.cargo/registry/cache" "$HOME_DIR/.cargo/registry/src" "$HOME_DIR/.cargo/git/checkouts" "$HOME_DIR/.cargo/git/db" ;;
    go) measure "$HOME_DIR/.cache/go-build" ;;
    gradle) measure "$HOME_DIR/.gradle/caches" ;;
    electron) measure_many "$HOME_DIR/.cache/electron" "$HOME_DIR/.cache/electron-builder" "$HOME_DIR/.cache/node-gyp" ;;
    pkgcache) measure "/var/cache/pacman/pkg" ;;
    journal) journal_size ;;
    orphans) printf '0' ;;
    docker_images) docker_size_for Images ;;
    docker_containers) docker_size_for Containers ;;
    docker_volumes) docker_size_for Volumes ;;
    docker_build) docker_size_for "Build Cache" ;;
    *) printf '0' ;;
  esac
}

tmp_size() {
  local total=0 size
  while IFS= read -r -d '' entry; do
    size=$(measure "$entry")
    total=$((total + size))
  done < <(find /tmp -mindepth 1 -maxdepth 1 -user "$(id -un)" -mtime +"$TMP_AGE" -print0 2>/dev/null)
  printf '%s' "$total"
}

journal_size() {
  have journalctl || { printf '0'; return; }
  journalctl --disk-usage 2>/dev/null | awk '
    { for (i = 1; i <= NF; i++) if ($i ~ /^[0-9.]+[KMGTP]?B?$/) { v = $i; break } }
    END {
      if (v == "") { print 0; exit }
      n = v + 0;
      if (v ~ /K/) n *= 1024;
      else if (v ~ /M/) n *= 1024 * 1024;
      else if (v ~ /G/) n *= 1024 * 1024 * 1024;
      else if (v ~ /T/) n *= 1024 * 1024 * 1024 * 1024;
      printf "%d", n;
    }'
}

pnpm_size() {
  if have pnpm; then
    local store
    store=$(pnpm store path 2>/dev/null | head -n1)
    [[ -n $store ]] && { measure "$store"; return; }
  fi
  measure_many "$HOME_DIR/.local/share/pnpm/store"
}

# ---------------------------------------------------------------- cleanup ----

clean_category() {
  case $1 in
    cache) clean_cache ;;
    thumbnails) remove_path "$HOME_DIR/.cache/thumbnails" ;;
    browser) clean_browser ;;
    trash) clean_trash ;;
    tmp) clean_tmp ;;
    appcache) clean_appcache ;;
    npm) remove_path "$HOME_DIR/.npm/_cacache" ;;
    yarn) remove_path "$HOME_DIR/.cache/yarn" ;;
    pnpm) clean_pnpm ;;
    pip) remove_path "$HOME_DIR/.cache/pip" ;;
    uv) remove_path "$HOME_DIR/.cache/uv" ;;
    cargo) remove_path "$HOME_DIR/.cargo/registry/cache"; remove_path "$HOME_DIR/.cargo/registry/src"; remove_path "$HOME_DIR/.cargo/git/checkouts"; remove_path "$HOME_DIR/.cargo/git/db" ;;
    go) remove_path "$HOME_DIR/.cache/go-build" ;;
    gradle) remove_path "$HOME_DIR/.gradle/caches" ;;
    electron) remove_path "$HOME_DIR/.cache/electron"; remove_path "$HOME_DIR/.cache/electron-builder"; remove_path "$HOME_DIR/.cache/node-gyp" ;;
    pkgcache) clean_pkgcache ;;
    journal) clean_journal ;;
    orphans) clean_orphans ;;
    docker_images) docker_prune image ;;
    docker_containers) docker_prune container ;;
    docker_volumes) docker_prune volume ;;
    docker_build) docker_prune builder ;;
    *) warn "unknown category: $1"; return 1 ;;
  esac
}

clean_cache() {
  local root="$HOME_DIR/.cache" entry name failed=0
  [[ -d $root ]] || return 0
  while IFS= read -r -d '' entry; do
    name=${entry##*/}
    cache_excluded "$name" && continue
    remove_path "$entry" || failed=1
  done < <(find "$root" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  return $failed
}

clean_browser() {
  local p failed=0
  if have pgrep && pgrep -u "$(id -u)" -x 'firefox|chromium|chrome|brave|vivaldi|opera|msedge' >/dev/null 2>&1; then
    warn "a browser is running; its cache may be recreated while you clean it"
  fi
  for p in "${BROWSER_PATHS[@]}"; do
    remove_path "$p" || failed=1
  done
  return $failed
}

clean_trash() {
  local failed=0
  remove_contents "$HOME_DIR/.local/share/Trash/files" || failed=1
  remove_contents "$HOME_DIR/.local/share/Trash/info" || failed=1
  return $failed
}

clean_tmp() {
  local entry failed=0
  while IFS= read -r -d '' entry; do
    remove_path "$entry" || failed=1
  done < <(find /tmp -mindepth 1 -maxdepth 1 -user "$(id -un)" -mtime +"$TMP_AGE" -print0 2>/dev/null)
  return $failed
}

clean_appcache() {
  local entry failed=0
  while IFS= read -r -d '' entry; do
    remove_path "$entry" || failed=1
  done < <(appcache_entries)
  return $failed
}

clean_pnpm() {
  if have pnpm && ((!DRY_RUN)); then
    pnpm store prune >/dev/null 2>&1 && return 0
  fi
  remove_path "$HOME_DIR/.local/share/pnpm/store"
}

clean_pkgcache() {
  if ((DRY_RUN)); then
    info "  ${c_dim}would run${c_reset} sudo paccache -rk1"
    return 0
  fi
  if have paccache; then
    sudo paccache -rk1 -q
  else
    sudo pacman -Sc --noconfirm
  fi
}

clean_journal() {
  if ((DRY_RUN)); then
    info "  ${c_dim}would run${c_reset} sudo journalctl --vacuum-size=200M"
    return 0
  fi
  sudo journalctl --vacuum-size=200M >/dev/null
}

clean_orphans() {
  local count
  count=$(pacman -Qtdq 2>/dev/null | wc -l)
  if ((count == 0)); then
    info "  no orphaned packages"
    return 0
  fi
  info "  ${count} orphaned package(s). Remove them with:"
  info "    sudo pacman -Rns \$(pacman -Qtdq)"
  return 0
}

docker_prune() {
  docker_available || { warn "docker is not available"; return 1; }
  local action=$1 filter=()
  [[ -n $DOCKER_FILTER ]] && filter=(--filter "until=$DOCKER_FILTER")
  if ((DRY_RUN)); then
    info "  ${c_dim}would run${c_reset} docker $action prune ${filter[*]:-}"
    return 0
  fi
  case $action in
    image) docker image prune -af "${filter[@]}" ;;
    container) docker container prune -f "${filter[@]}" ;;
    volume) docker volume prune -f "${filter[@]}" ;;
    builder) docker builder prune -af "${filter[@]}" ;;
    system)
      local args=(-f)
      ((DOCKER_ALL || AGGRESSIVE)) && args+=(-a)
      ((DOCKER_VOLUMES || AGGRESSIVE)) && args+=(--volumes)
      docker system prune "${args[@]}" "${filter[@]}" ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------- commands ----

cmd_list() {
  local id group last_group=""
  for id in "${CATALOG_ORDER[@]}" "${DOCKER_IDS[@]}"; do
    group=$(category_group "$id")
    if [[ $group != "$last_group" ]]; then
      [[ -n $last_group ]] && printf '\n'
      printf '%s%s%s\n' "$c_bold" "$group" "$c_reset"
      last_group=$group
    fi
    printf '  %-16s %s\n' "$id" "$(category_label "$id")"
  done
}

cmd_scan() {
  local -A SIZE=() AVAIL=() GROUP=() LABEL=()
  local ids=() id total=0 count=0

  parse_excludes
  for id in "${CATALOG_ORDER[@]}"; do
    if [[ $(category_group "$id") == system ]] && ((!SYSTEM)); then
      continue
    fi
    SIZE[$id]=$(category_size "$id")
    LABEL[$id]=$(category_label "$id")
    GROUP[$id]=$(category_group "$id")
    if category_available "$id"; then AVAIL[$id]=1; else AVAIL[$id]=0; fi
    total=$((total + SIZE[$id]))
    ids+=("$id")
  done

  if docker_available; then
    for id in "${DOCKER_IDS[@]}"; do
      SIZE[$id]=$(category_size "$id")
      LABEL[$id]=$(category_label "$id")
      GROUP[$id]=docker
      AVAIL[$id]=1
      total=$((total + SIZE[$id]))
      ids+=("$id")
    done
  fi

  if ((JSON)); then
    printf '{"version":1,"generated":%s,"total_bytes":%s,"system":%s,"categories":[' \
      "$(date +%s)" "$total" "$(json_bool "$SYSTEM")"
    for id in "${ids[@]}"; do
      ((count++)) && printf ','
      printf '{"id":"%s","label":"%s","group":"%s","bytes":%s,"available":%s,"cleanable":%s,"detail":"%s"}' \
        "$(json_escape "$id")" \
        "$(json_escape "${LABEL[$id]}")" \
        "${GROUP[$id]}" \
        "${SIZE[$id]:-0}" \
        "$(json_bool "${AVAIL[$id]:-0}")" \
        "$(if [[ $id == orphans ]]; then json_bool 0; else json_bool 1; fi)" \
        "$(json_escape "$(category_detail "$id")")"
    done
    printf ']}\n'
    return 0
  fi

  local group last_group=""
  for group in user dev docker system; do
    local printed=0
    for id in "${ids[@]}"; do
      [[ ${GROUP[$id]} == "$group" ]] || continue
      if ((!printed)); then
        printf '\n%s%s%s\n' "$c_bold" "${group^}" "$c_reset"
        printed=1
      fi
      printf '  %-16s %10s  %s%s%s\n' \
        "$id" "$(human "${SIZE[$id]:-0}")" "$c_dim" "${LABEL[$id]}" "$c_reset"
    done
  done

  printf '\n%sTotal reclaimable: %s%s%s\n' "$c_bold" "$c_green" "$(human "$total")" "$c_reset"
  local default_total=0 id2
  for id2 in "${DEFAULT_IDS[@]}"; do
    default_total=$((default_total + ${SIZE[$id2]:-0}))
  done
  printf '%sDefault clean (cache thumbnails browser trash tmp): %s%s\n' \
    "$c_dim" "$(human "$default_total")" "$c_reset"
  if ((!SYSTEM)); then
    printf '%sAdd --system to include pacman, journal and orphaned packages.%s\n' "$c_dim" "$c_reset"
  fi
}

collect_ids() {
  local -n out=$1
  shift
  local -a raw=("$@")
  local id
  ((${#raw[@]})) || raw=("${DEFAULT_IDS[@]}")
  out=()
  while IFS= read -r id; do
    [[ -n $id ]] && out+=("$id")
  done < <(resolve_ids "${raw[@]}")
  ((${#out[@]})) || die "no categories selected"
  for id in "${out[@]}"; do
    category_exists "$id" || die "unknown category: $id (see: $PROG list)"
    if ((!SYSTEM)) && [[ $(category_group "$id") == system ]]; then
      die "category '$id' needs --system (it runs sudo)"
    fi
  done
}

cmd_clean() {
  local -a ids=()
  collect_ids ids "$@"
  ((${#ids[@]})) || exit 0

  parse_excludes

  local -a before=() freed=()
  local id total_before=0 total_freed=0 errors=0
  local group

  if ((!JSON)); then
    say "${c_bold}Dank Cleaner $VERSION${c_reset}"
    for id in "${ids[@]}"; do
      printf '  %-16s %10s  %s\n' "$id" "$(human "$(category_size "$id")")" "$(category_label "$id")"
    done
    say ""
  fi

  if ((!DRY_RUN)); then
    local prompt="Remove the selected categories? This cannot be undone."
    confirm "$prompt" || { say "aborted"; exit 0; }
  fi

  local i=0
  for id in "${ids[@]}"; do
    before[i]=$(category_size "$id")
    if ((DRY_RUN)); then
      say "${c_cyan}dry-run${c_reset} $id ($(human "${before[i]}")) ${c_dim}$(category_detail "$id")${c_reset}"
      clean_category "$id"
      local rc=$?
      freed[i]=${before[i]}
    else
      say "cleaning $id ($(human "${before[i]}"))..."
      clean_category "$id"
      local rc=$?
      local after
      after=$(category_size "$id")
      freed[i]=$(( before[i] - after ))
      ((freed[i] < 0)) && freed[i]=0
    fi
    ((rc != 0)) && errors=$((errors + 1))
    total_before=$((total_before + before[i]))
    total_freed=$((total_freed + freed[i]))
    i=$((i + 1))
  done

  if ((JSON)); then
    printf '{"ok":%s,"dry_run":%s,"freed_bytes":%s,"before_bytes":%s,"errors":%s,"categories":[' \
      "$(json_bool $((errors == 0)))" "$(json_bool "$DRY_RUN")" "$total_freed" "$total_before" "$errors"
    local n=0
    for id in "${ids[@]}"; do
      ((n++)) && printf ','
      printf '{"id":"%s","bytes_before":%s,"bytes_after":%s,"freed":%s}' \
        "$(json_escape "$id")" \
        "${before[n-1]:-0}" \
        "$(( ${before[n-1]:-0} - ${freed[n-1]:-0} ))" \
        "${freed[n-1]:-0}"
    done
    printf ']}\n'
  else
    printf '\n%s%s %s%s\n' "$c_bold" "$( ((DRY_RUN)) && printf 'Would free:' || printf 'Freed:')" \
      "$(human "$total_freed")" "$c_reset"
    if ((errors)); then
      printf '%s%d category/categories reported errors (permissions or running apps).%s\n' \
        "$c_yellow" "$errors" "$c_reset"
    fi
  fi

  if ((!DRY_RUN)); then
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$total_freed" "${ids[*]}" \
      >>"$HISTORY_FILE" 2>/dev/null || true
  fi
}

# ---------------------------------------------------------------- docker ----

cmd_docker() {
  local action=${1:-system}
  (($#)) && shift
  docker_available || die "docker is not installed or the daemon is not running"

  case $action in
    containers|container|images|image|volumes|volume|build|builder|system)
      if ((!DRY_RUN)); then
        confirm "Run docker $action prune?" || { say "aborted"; exit 0; }
      fi
      local before after freed
      before=$(docker_reclaimable_total)
      case $action in
        containers|container) docker_prune container ;;
        images|image) docker_prune image ;;
        volumes|volume) docker_prune volume ;;
        build|builder) docker_prune builder ;;
        system) docker_prune system ;;
      esac
      after=$(docker_reclaimable_total)
      freed=$((before - after))
      ((freed < 0)) && freed=0
      if ((JSON)); then
        printf '{"ok":true,"action":"%s","dry_run":%s,"freed_bytes":%s}\n' \
          "$(json_escape "$action")" "$(json_bool "$DRY_RUN")" "$freed"
      else
        say "docker $action: freed $(human "$freed")"
      fi
      ;;
    *)
      die "unknown docker action: $action (containers|images|volumes|build|system)"
      ;;
  esac
}

docker_reclaimable_total() {
  local total=0 id
  for id in "${DOCKER_IDS[@]}"; do
    total=$((total + $(category_size "$id")))
  done
  printf '%s' "$total"
}

# --------------------------------------------------------------- analyze ----

analyze_entries() {
  local path=$1 limit=$2 entry name size
  local -a rows=()
  [[ -d $path ]] || return 1
  while IFS= read -r -d '' entry; do
    size=$(measure "$entry")
    name=${entry##*/}
    rows+=("$size"$'\t'"$name"$'\t'"$entry")
  done < <(find "$path" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1nr | head -n "$limit"
}

cmd_analyze() {
  local path=${1:-$HOME_DIR}
  local limit=$ANALYZE_LIMIT
  path=$(expand_tilde "$path")
  [[ -d $path ]] || die "not a directory: $path"
  path=$(realpath -m -- "$path" 2>/dev/null || printf '%s' "$path")

  local total
  total=$(measure "$path")
  local rows
  rows=$(analyze_entries "$path" "$limit")

  if ((JSON)); then
    printf '{"ok":true,"path":"%s","total_bytes":%s,"entries":[' \
      "$(json_escape "$path")" "$total"
    local first=1 size name full
    while IFS=$'\t' read -r size name full; do
      [[ -n ${size:-} ]] || continue
      ((first)) || printf ','
      first=0
      printf '{"name":"%s","path":"%s","bytes":%s}' \
        "$(json_escape "$name")" "$(json_escape "$full")" "$size"
    done <<<"$rows"
    printf ']}\n'
    return 0
  fi

  printf '%s%s%s  %s\n\n' "$c_bold" "$path" "$c_reset" "$(human "$total")"
  local max=1 size name full pct bar_width=28
  while IFS=$'\t' read -r size name full; do
    [[ -n ${size:-} ]] || continue
    ((size > max)) && max=$size
  done <<<"$rows"

  while IFS=$'\t' read -r size name full; do
    [[ -n ${size:-} ]] || continue
    local width=$(( size * bar_width / max ))
    ((width < 1)) && width=1
    printf '  %-32s %10s  %s' "${name:0:32}" "$(human "$size")" "$c_blue"
    printf '█%.0s' $(seq 1 "$width")
    printf '%s\n' "$c_reset"
  done <<<"$rows"
}

cmd_largest() {
  local path=${1:-$HOME_DIR} limit=${2:-$ANALYZE_LIMIT}
  path=$(expand_tilde "$path")
  [[ -d $path ]] || die "not a directory: $path"
  local rows
  rows=$(find "$path" -xdev -type f -size +1M -printf '%s\t%p\n' 2>/dev/null | sort -nr | head -n "$limit")
  if ((JSON)); then
    printf '{"ok":true,"path":"%s","files":[' "$(json_escape "$path")"
    local first=1 size full
    while IFS=$'\t' read -r size full; do
      [[ -n ${size:-} ]] || continue
      ((first)) || printf ','
      first=0
      printf '{"path":"%s","bytes":%s}' "$(json_escape "$full")" "$size"
    done <<<"$rows"
    printf ']}\n'
    return 0
  fi
  while IFS=$'\t' read -r size full; do
    [[ -n ${size:-} ]] || continue
    printf '  %10s  %s\n' "$(human "$size")" "$full"
  done <<<"$rows"
}

cmd_history() {
  [[ -f $HISTORY_FILE ]] || { say "no cleanup history yet"; return 0; }
  tail -n "${1:-10}" "$HISTORY_FILE" | while IFS=$'\t' read -r when bytes ids; do
    printf '  %s  %10s  %s\n' "$when" "$(human "$bytes")" "$ids"
  done
}

cmd_doctor() {
  say "${c_bold}cleaner.sh $VERSION${c_reset}"
  say "home:    $HOME_DIR"
  say "state:   $STATE_DIR"
  say "tmp age: $TMP_AGE day(s)"
  say ""
  local tool
  for tool in bash du find sort awk rm sudo pacman paccache journalctl docker pnpm; do
    if have "$tool"; then printf '  %-12s %s\n' "$tool" "$(command -v "$tool")"
    else printf '  %-12s %s\n' "$tool" "${c_dim}not found${c_reset}"; fi
  done
}

usage() {
  cat <<EOF
${c_bold}cleaner.sh $VERSION${c_reset} — reclaim disk space without guessing

${c_bold}Usage${c_reset}
  $PROG scan [--json] [--system]       show reclaimable space per category
  $PROG clean [ids...] [options]       remove selected categories
  $PROG docker [action] [options]      prune Docker data
  $PROG analyze [path] [--json]        disk usage of a directory
  $PROG largest [path] [n]             largest files under a path
  $PROG list                           list category ids
  $PROG history [n]                    last cleanup runs
  $PROG doctor                         environment and tool check
  $PROG version

${c_bold}Options${c_reset}
  -n, --dry-run          measure only, delete nothing
  -y, --yes              skip the confirmation prompt
      --json             machine-readable output
      --system           include system categories (runs sudo)
      --aggressive       deeper pruning (pnpm store, docker all volumes)
      --exclude LIST     extra ~/.cache names to keep (comma separated)
      --tmp-age DAYS     /tmp age threshold (default: 3)
      --docker-filter F  docker prune --filter until=F
      --docker-all       docker system prune -a (all unused images)
      --docker-volumes   docker system prune --volumes
      --limit N          entries for analyze/largest (default: 20)
  -q, --quiet            less chatter
      --no-color         disable ANSI colour
  -h, --help             this help

${c_bold}Categories${c_reset}
  user:   cache thumbnails browser trash tmp appcache
  dev:    npm yarn pnpm pip uv cargo go gradle electron
  system: pkgcache journal orphans        (needs --system)
  docker: docker_images docker_containers docker_volumes docker_build

${c_bold}Examples${c_reset}
  $PROG scan
  $PROG clean cache trash --dry-run
  $PROG clean browser thumbnails --yes
  $PROG clean dev --yes
  $PROG scan --system --json
  $PROG docker images --yes
  $PROG analyze ~/Downloads --json
EOF
}

# ------------------------------------------------------------------ main ----

main() {
  local -a positional=()
  while (($#)); do
    case $1 in
      -n|--dry-run) DRY_RUN=1 ;;
      -y|--yes) ASSUME_YES=1 ;;
      --json) JSON=1 ;;
      --system) SYSTEM=1 ;;
      --aggressive) AGGRESSIVE=1 ;;
      --exclude) shift; EXCLUDES=${1:-} ;;
      --exclude=*) EXCLUDES=${1#*=} ;;
      --tmp-age) shift; TMP_AGE=${1:-3} ;;
      --tmp-age=*) TMP_AGE=${1#*=} ;;
      --docker-filter) shift; DOCKER_FILTER=${1:-} ;;
      --docker-filter=*) DOCKER_FILTER=${1#*=} ;;
      --docker-all) DOCKER_ALL=1 ;;
      --docker-volumes) DOCKER_VOLUMES=1 ;;
      --limit) shift; ANALYZE_LIMIT=${1:-20} ;;
      --limit=*) ANALYZE_LIMIT=${1#*=} ;;
      -q|--quiet) QUIET=1 ;;
      --no-color) USE_COLOR=never ;;
      -h|--help|help) init_colors; usage; exit 0 ;;
      -v|--version|version) printf 'cleaner.sh %s\n' "$VERSION"; exit 0 ;;
      --) shift; positional+=("$@"); break ;;
      -*) die "unknown option: $1" ;;
      *) positional+=("$1") ;;
    esac
    shift
  done

  init_colors
  ((JSON)) && QUIET=1
  [[ -n $HOME_DIR ]] || die "HOME is not set"
  [[ $TMP_AGE =~ ^[0-9]+$ ]] || die "--tmp-age must be a number"
  [[ $ANALYZE_LIMIT =~ ^[0-9]+$ ]] || die "--limit must be a number"

  local cmd=${positional[0]:-scan}
  ((${#positional[@]})) && positional=("${positional[@]:1}")

  case $cmd in
    scan) cmd_scan ;;
    clean) cmd_clean "${positional[@]}" ;;
    docker) cmd_docker "${positional[@]}" ;;
    analyze) cmd_analyze "${positional[@]}" ;;
    largest) cmd_largest "${positional[@]}" ;;
    list) cmd_list ;;
    history) cmd_history "${positional[@]}" ;;
    doctor) cmd_doctor ;;
    *) die "unknown command: $cmd (try: $PROG help)" ;;
  esac
}

main "$@"
