#!/usr/bin/env bash
# webapp.sh — run any website in a Chromium app window and add it to the menu.
#
# Usage:
#   webapp.sh <url> [name]              launch (and create/update the menu entry)
#   webapp.sh --install <url> [name]    only create/update the menu entry
#   webapp.sh --list                    list installed web apps
#   webapp.sh --remove <name> [--purge] remove the entry (and optionally its profile)
#
# Environment:
#   WEBAPP_BROWSER  Chromium browser command (default: brave-origin, brave, chromium)
#   WEBAPP_DATA_DIR profile directory (default: ${XDG_DATA_HOME:-~/.local/share}/webapps)
set -euo pipefail

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="${WEBAPP_DATA_DIR:-$DATA_HOME/webapps}"
DESKTOP_DIR="$DATA_HOME/applications"
SELF="$(readlink -f -- "${BASH_SOURCE[0]}")"

usage() {
  cat <<'EOF'
Usage:
  webapp.sh <url> [name]              launch (and create/update the menu entry)
  webapp.sh --install <url> [name]    only create/update the menu entry
  webapp.sh --list                    list installed web apps
  webapp.sh --remove <name> [--purge] remove the entry (and optionally its profile)

Environment:
  WEBAPP_BROWSER  Chromium browser command (default: brave-origin, brave, chromium)
  WEBAPP_DATA_DIR profile directory (default: ${XDG_DATA_HOME:-~/.local/share}/webapps)
EOF
}

die() {
  printf 'webapp: %s\n' "$*" >&2
  exit 1
}

slugify() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

normalize_url() {
  local url=$1
  case $url in
    http://*|https://*) printf '%s\n' "$url" ;;
    *) printf 'https://%s\n' "$url" ;;
  esac
}

url_host() {
  local host=${1#*://}
  host=${host%%/*}
  host=${host%%\?*}
  host=${host%%#*}
  printf '%s\n' "$host"
}

default_name() {
  local host
  host="$(url_host "$1")"
  host=${host#www.}
  host=${host%%:*}
  printf '%s\n' "${host:-Web App}"
}

browser_app_prefix() {
  local browser=${1##*/}
  case $browser in
    brave*) printf 'brave' ;;
    chromium*) printf 'chromium' ;;
    google-chrome*) printf 'google-chrome' ;;
    *) printf '%s' "$browser" ;;
  esac
}

pick_browser() {
  if [[ -n ${WEBAPP_BROWSER:-} ]]; then
    command -v "$WEBAPP_BROWSER" >/dev/null 2>&1 ||
      die "WEBAPP_BROWSER '$WEBAPP_BROWSER' not found"
    printf '%s\n' "$WEBAPP_BROWSER"
    return
  fi

  local browser
  for browser in brave-origin brave brave-browser chromium chromium-browser google-chrome-stable; do
    if command -v "$browser" >/dev/null 2>&1; then
      printf '%s\n' "$browser"
      return
    fi
  done
  die "no Chromium browser found (set WEBAPP_BROWSER)"
}

pick_icon() {
  local slug=$1 icon
  for icon in "web-$slug" "$slug" web-browser applications-internet; do
    if compgen -G "/usr/share/icons/*/*/apps/$icon.svg" >/dev/null ||
      compgen -G "/usr/share/icons/*/*/apps/$icon.png" >/dev/null ||
      compgen -G "$HOME/.local/share/icons/*/*/apps/$icon.svg" >/dev/null; then
      printf '%s\n' "$icon"
      return
    fi
  done
  printf 'web-browser\n'
}

# Quote one argument for a Desktop Entry Exec line.
desktop_quote() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//\$/\\\\\$}
  s=${s//\`/\\\\\`}
  s=${s//%/%%}
  printf '"%s"' "$s"
}

write_desktop() {
  local url=$1 name=$2 slug=$3
  local desktop="$DESKTOP_DIR/webapp-$slug.desktop"
  local browser icon exec_line host prefix wm_class

  browser="$(pick_browser)"
  icon="$(pick_icon "$slug")"
  exec_line="$(desktop_quote "$SELF") $(desktop_quote "$url") $(desktop_quote "$name")"

  # Chromium app windows on Wayland derive their app_id from the URL, not
  # from --class. Match it so niri associates the window with this launcher.
  host="$(url_host "$url")"
  prefix="$(browser_app_prefix "$browser")"
  case $prefix in
    brave|chromium|google-chrome) wm_class="$prefix-${host}__-Default" ;;
    *) wm_class="webapp-$slug" ;;
  esac

  mkdir -p "$DESKTOP_DIR"
  cat >"$desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$name
GenericName=Web App
Comment=$name web app ($url)
Exec=$exec_line
Icon=$icon
Terminal=false
Categories=Network;WebBrowser;
Keywords=webapp;website;browser;
StartupNotify=true
StartupWMClass=$wm_class
X-WebApp=true
X-WebApp-Browser=$browser
X-WebApp-URL=$url
X-WebApp-WMClass=$wm_class
EOF

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi
  printf '%s\n' "$desktop"
}

launch_webapp() {
  local url=$1 name=$2 slug=$3
  local browser profile desktop

  browser="$(pick_browser)"
  profile="$APP_DIR/$slug"
  desktop="$(write_desktop "$url" "$name" "$slug")"
  mkdir -p "$profile"

  printf 'webapp: %s -> %s\n' "$name" "$desktop" >&2
  exec "$browser" \
    --app="$url" \
    --user-data-dir="$profile" \
    --class="webapp-$slug" \
    --name="$name" \
    --window-size=1100,820 \
    --no-first-run \
    --no-default-browser-check
}

remove_webapp() {
  local target=$1 purge=${2:-0} slug desktop
  slug="$(slugify "$target")"
  desktop="$DESKTOP_DIR/webapp-$slug.desktop"

  if [[ -f $desktop ]]; then
    rm -f -- "$desktop"
    printf 'webapp: removed %s\n' "$desktop"
  else
    printf 'webapp: no entry for %s\n' "$target" >&2
  fi

  if [[ $purge == 1 ]]; then
    rm -rf -- "${APP_DIR:?}/$slug"
    printf 'webapp: removed profile %s\n' "$APP_DIR/$slug"
  fi

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
  fi
}

list_webapps() {
  local file name url
  shopt -s nullglob
  local files=("$DESKTOP_DIR"/webapp-*.desktop)
  if ((${#files[@]} == 0)); then
    printf 'No web apps installed.\n'
    return
  fi
  for file in "${files[@]}"; do
    name=$(sed -n 's/^Name=//p' "$file" | head -n1)
    url=$(sed -n 's/^X-WebApp-URL=//p' "$file" | head -n1)
    printf '%-22s %s\n' "$name" "$url"
  done
}

mode="launch"
purge=0
url=""
name=""

while (($# > 0)); do
  case $1 in
    -h|--help) usage; exit 0 ;;
    -i|--install) mode="install"; shift ;;
    -l|--list) mode="list"; shift ;;
    -r|--remove) mode="remove"; shift ;;
    -p|--purge) purge=1; shift ;;
    --) shift; break ;;
    -*) die "unknown option: $1" ;;
    *)
      if [[ -z $url ]]; then
        url=$1
      elif [[ -z $name ]]; then
        name=$1
      else
        die "too many arguments"
      fi
      shift
      ;;
  esac
done

case $mode in
  list)
    list_webapps
    ;;
  remove)
    [[ -n $url ]] || die "--remove needs a name"
    remove_webapp "$url" "$purge"
    ;;
  install|launch)
    [[ -n $url ]] || { usage; exit 1; }
    url="$(normalize_url "$url")"
    [[ -n $name ]] || name="$(default_name "$url")"
    name=${name//$'\n'/ }
    slug="$(slugify "$name")"
    [[ -n $slug ]] || die "could not derive a name; pass one explicitly"
    if [[ $mode == install ]]; then
      write_desktop "$url" "$name" "$slug"
    else
      launch_webapp "$url" "$name" "$slug"
    fi
    ;;
esac
