# SYSTEM.md

Living notes for this machine and the dotfiles repo. Updated whenever the
setup changes.

- **Last updated:** 2026-10-22
- **Host OS:** CachyOS Linux (Arch-based, rolling)
- **Kernel:** 7.2.11-1-cachyos
- **Compositor:** niri (Wayland) + DankMaterialShell (DMS)
- **Primary shell:** zsh 5.9.2
- **Terminal:** kitty 0.49.2
- **Repo:** <https://github.com/SpreadSheets600/Dotfiles>
- **GitHub:** `SpreadSheets600` / `dev.spreadsheets600@gmail.com`

> **Security:** passwords are **not** stored in this repo. `sudo`, `gh`, and git
> credentials live in the system keyring / `~/.config/gh/` only.

---

## 1. What was done (2026-10-21)

1. Installed the terminal stack: `paru`, `zoxide`, `vivid`, `yazi`, `direnv`,
   `stow`, `lazygit`, `neovim`, `zellij`, `git-delta`, `duf`, `dust`, `procs`,
   `glow`, `pkgfile`, `fzf-tab`, plus Nerd Fonts (`ZedMono`, `Iosevka`,
   `JetBrains Mono`, `Symbols`).
2. Wrote a new zsh configuration from scratch using **Powerlevel10k** (no
   zinit / oh-my-zsh / network required at startup).
3. Rebuilt the kitty config and pointed it at the DMS-generated colour files so
   the terminal follows the wallpaper/accent colour.
4. Set the login shell to `/usr/bin/zsh` (was `/bin/fish`).
5. Configured `paru` for AUR use and git (identity, delta, aliases, gh helper).
6. Reorganised `~/Dotfiles` into `linux/`, `windows/`, and `shared/`, removed
   caches/backups/duplicates, and added `install.sh` (symlink installer).
7. Linked all Linux configs from the repo into `$HOME` (see §3).
8. Added this file and rewrote the README; pushed everything to GitHub.
9. Installed **ZedMono Nerd Font** and **Numix-Square** icons, set both
   system-wide, and made ZedMono the kitty font.
10. Replaced the CachyOS fastfetch logo with a random `pokeget` Pokémon sprite
    and removed the ASCII box around the info.
11. Installed Node.js/npm plus `tree-sitter-cli`, `stylua`, and `shfmt`, and set
    up **LazyVim** in `linux/.config/nvim` with Python/TypeScript/JSON/YAML/
    TOML/Markdown/Docker/Git extras.
12. Added **DMS → Neovim** color sync through the `base46` plugin, a generic
    **Brave web-app launcher** (`webapp.sh`), and installed **Spotify**,
    **Discord** (with **Equicord** patched on top).
13. Set up **WCursor** in `~/Projects/wcursor`, converted and installed the
    **Camellya** and **Chisa** Windows cursor packs (six themes), and linked them
    into `~/.icons` so niri can see them.
14. Added GitHub sync for the setup configs (`dotfiles-sync.sh`). The wallpaper
    collection moved into its own repo
    (`SpreadSheets600/Wallpapers`), mounted here as the `wallpapers/` submodule
    and symlinked from `~/Pictures/Wallpapers`.

---

## 2. Repository layout

```text
Dotfiles/
├── install.sh              # link linux/ configs into $HOME (backs up first)
├── SYSTEM.md               # this file
├── README.md
├── wallpapers/             # submodule: SpreadSheets600/Wallpapers (images)
├── linux/                  # machine-local Linux (CachyOS/niri) configs
│   ├── .zshrc              # interactive shell
│   ├── .zshenv             # environment for every zsh
│   ├── .zprofile           # login shell
│   ├── .p10k.zsh           # Powerlevel10k theme
│   ├── .gitconfig
│   ├── .config/
│   │   ├── kitty/          # terminal (kitty.conf + DMS colour files)
│   │   ├── niri/           # compositor config + DMS includes
│   │   ├── paru/
│   │   ├── fontconfig/     # ZedMono as default monospace
│   │   ├── gtk-3.0/        # GTK font + Numix-Square icon theme
│   │   ├── gtk-4.0/
│   │   ├── nvim/           # LazyVim (init.lua + lua/config + lua/plugins)
│   │   ├── fastfetch/      # random Pokémon logo + modules
│   │   ├── lazygit/
│   │   ├── cava/
│   │   ├── conky/
│   │   ├── goverlay/
│   │   ├── MangoHud/
│   │   └── autostart/
│   └── scripts/            # helpers (linked into ~/.local/bin)
├── windows/                # Windows 11 configs
│   ├── terminal/           # Windows Terminal settings.json
│   ├── komorebi/           # tiling WM + whkd keybinds
│   ├── yasb/               # status bar
│   ├── windhawk/           # taskbar/start/explorer mods
│   ├── rainmeter/          # skin package
│   ├── wsl/                # wsl.conf + .wslconfig
│   └── scripts/            # system-cleanup.ps1
└── shared/                 # used on both platforms
    ├── vscode/settings.json
    ├── zed/                # settings + themes
    └── discord/            # BetterDiscord CSS
```

### Why this layout

- Everything under `linux/.config/` mirrors `~/.config/` exactly, so the
  installer can link one directory per app.
- Dotfiles in `linux/` that live directly in `$HOME` (`.zshrc`, `.gitconfig`,
  …) are handled explicitly by `install.sh`.
- `windows/` and `shared/` are reference files that are copied to their target
  paths on Windows; they are not installed by `install.sh`.

---

## 3. How the Linux configs are installed

`~/.config/<app>` are **symlinks** into this repo, so editing either side edits
the same file.

```bash
cd ~/Dotfiles
./install.sh --dry-run   # preview
./install.sh             # link (existing files are moved to a backup)
```

Backups are written to:

```text
~/.local/state/dotfiles-backups/<YYYYmmdd-HHMMSS>/
```

Current links:

| In `$HOME` | Points to |
|---|---|
| `~/.zshrc` | `linux/.zshrc` |
| `~/.zshenv` | `linux/.zshenv` |
| `~/.zprofile` | `linux/.zprofile` |
| `~/.p10k.zsh` | `linux/.p10k.zsh` |
| `~/.gitconfig` | `linux/.gitconfig` |
| `~/.config/{kitty,niri,paru,fastfetch,lazygit,cava,conky,goverlay,MangoHud,autostart,nvim}` | `linux/.config/...` |
| `~/.local/bin/{cheat-engine.sh,game-launch.sh,phone-cam.sh,pokemon-logo.sh,webapp.sh,dotfiles-sync.sh}` | `linux/scripts/...` |
| `~/Pictures/Wallpapers` | `wallpapers/Wallpapers/` |

Website app-menu entries are generated (not tracked) by `webapp.sh` at
`~/.local/share/applications/webapp-<slug>.desktop`.

To check for broken links:

```bash
find ~/.config -maxdepth 1 -type l ! -exec test -e {} \; -print
```

### Updating the repo

```bash
cd ~/Dotfiles
git add -A
git commit -m "feat: describe the change"
git push
```

`install.sh` never deletes user data: conflicts are moved to the timestamped
backup dir above. Automatic GitHub sync of the setup configs is covered in §16.

---

## 4. Shell stack (zsh)

Startup order: `.zshenv` → `.zprofile` (login) → `.zshrc` (interactive).

### Files

- **`.zshenv`** — XDG dirs, `PATH` (deduplicated, user-first), locale, editor,
  pager, `BAT_THEME`, `LESS` options. Silent and safe for scripts.
- **`.zshrc`** — history, options, completion, plugins, keybinds, fzf, zoxide,
  direnv, aliases, functions, Powerlevel10k, fastfetch greeting.
- **`.p10k.zsh`** — two-line prompt, DMS purple palette, `❯` prompt, git
  status, command duration, node/python/venv/kube context, clock.

### Powerlevel10k

- Theme: `/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme`
- Instant prompt: `quiet` (no noticeable shell startup delay).
- Left: `context → dir → git → newline → ❯`
- Right: `status → command time → background jobs → node → python → venv →
  kubecontext → time`
- Colours match kitty/DMS: accent `#d0bcff`, text `#e6e0e9`, green `#7fff9a`,
  yellow `#ffda72`, red `#ff728f`.

Re-run the wizard only if you want a different prompt (it overwrites
`~/.p10k.zsh`):

```bash
p10k configure
```

### Plugins (Arch packages, loaded locally)

| Plugin | Package |
|---|---|
| autosuggestions | `zsh-autosuggestions` |
| syntax highlighting | `zsh-syntax-highlighting` |
| history substring search | `zsh-history-substring-search` |
| extra completions | `zsh-completions` |
| fzf tab completion | `fzf-tab` (AUR) |
| fzf shell bindings | `fzf` (`source <(fzf --zsh)`) |

Syntax highlighting is loaded last. No plugin manager is used, so startup does
not depend on the network.

### History

- File: `~/.local/state/zsh/history`
- 100,000 entries, shared/instant across terminals, duplicates suppressed.
- `Ctrl+R` — fzf history; `↑`/`↓` — substring search; `fh` — pick a command.

### Key bindings

| Keys | Action |
|---|---|
| `Ctrl+R` | fuzzy history search |
| `Ctrl+T` | fuzzy file picker |
| `Alt+C` | fuzzy directory jump |
| `Ctrl+F` / `Ctrl+B` | forward / backward char |
| `Alt+F` / `Alt+B` | forward / backward word |
| `Ctrl+←/→` | word movement |
| `Ctrl+W` | delete previous word |
| `Shift+Tab` | reverse menu completion |
| `↑` / `↓` | history substring search |

### Aliases (highlights)

```text
ls  l  la  ll  lt  tree     eza (icons, git, tree)
cat catp                    bat
grep                        ripgrep
du / df / ps / top          dust / duf / procs / btop
g gs gd ga gc gp gl …       git shortcuts
lg                          lazygit
vim vi n                    neovim
p / up / clean              paru / full upgrade / clean cache
reload sz                   restart zsh / re-source config
```

`fd` is installed but `find` is intentionally **not** aliased, so scripts and
muscle memory keep working.

Icon spacing is standardized at **two spaces**: `.zshenv` exports
`EZA_ICON_SPACING=2` for every `eza` call (including fzf previews), and the
fastfetch keys use `icon + two spaces + label`. Keep both values in sync when
adjusting the gap.

### Functions

| Function | Purpose |
|---|---|
| `mkcd` / `take` | create a directory and `cd` into it |
| `y` | yazi that returns to the last visited directory |
| `extract` | extract tar/zip/7z/rar/gz/xz/zst |
| `fh` | pick a command from history and put it on the prompt |
| `fcd` | fuzzy `cd` with an `eza` preview |
| `pkg <file>` | which package owns/provides a file |
| `command_not_found_handler` | suggests packages via `pkgfile` |

### Greeting

`fastfetch` runs once per kitty window/tab (tracked by `$KITTY_WINDOW_ID`) and
is skipped inside tmux/zellij. Disable with:

```bash
NOFETCH=1 zsh
# or permanently, add this above the greeting in .zshrc:
#   return
```

---

## 5. Terminal, fonts & icons (kitty + desktop)

### kitty

Config: `linux/.config/kitty/kitty.conf`

- Font: **ZedMono Nerd Font** 12.5, line height 105%, ligatures on.
- Padding 16 px, no server-side decorations, 96% opacity, 24 px blur.
- DMS/ii-generated colours are included from `dank-theme.conf` and
  `dank-tabs.conf`. DMS rewrites these files; because the directory is a
  symlink, they land in this repo.
- Tabs: powerline, slanted, top edge, hidden when only one tab.
- Shell: `/usr/bin/zsh`.
- `Ctrl+Shift+C/V` copy/paste, `Ctrl+C` copy-or-interrupt, `Ctrl+Shift+T/N`
  new tab/window in cwd, `Ctrl+Shift+F` scrollback search, `Ctrl +/-/0` zoom.

### Desktop font

**ZedMono Nerd Font** is installed from `ttf-zed-mono-nerd` and applied at three
levels:

1. `gsettings` — UI and monospace font:
   ```bash
   gsettings set org.gnome.desktop.interface font-name 'ZedMono Nerd Font 11'
   gsettings set org.gnome.desktop.interface monospace-font-name 'ZedMono Nerd Font 11'
   ```
2. `fontconfig` — `~/.config/fontconfig/conf.d/60-zed-mono.conf` makes
   `monospace` (and the `sans-serif` fallback) resolve to ZedMono.
3. `kitty` — `font_family ZedMono Nerd Font`.

`install.sh` applies the gsettings values automatically. Verify:

```bash
gsettings get org.gnome.desktop.interface font-name
fc-match monospace
```

### Icon theme

**Numix-Square** (AUR `numix-square-icon-theme-git`, depends on
`numix-icon-theme-git`) is installed to `/usr/share/icons/Numix-Square` and set
with:

```bash
gsettings set org.gnome.desktop.interface icon-theme 'Numix-Square'
```

GTK 3/4 settings also point at it (`gtk-icon-theme-name=Numix-Square`), so apps
that read `settings.ini` instead of dconf pick it up too. Restart running apps
after changing the theme.

### Cursors (WCursor)

**WCursor** (private repo `SpreadSheets600/WCursor`) converts Windows `.ani` /
`.cur` packs to Linux Xcursor themes, adds the 24/32/48/64 px sizes, keeps the
converted theme in `~/Documents/Cursors/<Theme>`, installs a copy under
`~/.local/share/icons`, and applies the theme + size consistently to DMS, niri,
X11, GTK 3/4, and GSettings.

Setup (requires an authenticated `gh` account):

```bash
gh auth status
gh repo clone SpreadSheets600/WCursor ~/Projects/wcursor
cd ~/Projects/wcursor
python3 -m venv .venv
.venv/bin/pip install -e .
ln -sfn ~/Projects/wcursor/.venv/bin/wcursor ~/.local/bin/wcursor
wcursor doctor
```

The source packs are the two VSTHEMES downloads in `~/Downloads`:

- `camellya_fbd4ebf39e_VSTHEMES-ORG.zip`
  - `Cursors/Red`, `Cursors/White` — animated
  - `Static/Red`, `Static/White` — static
- `chibi-chisa-wuwa_dd9b80d3fb_VSTHEMES-ORG.zip`
  - `Windows` — animated
  - `Static` — static

Extract and install every variant:

```bash
mkdir -p ~/Projects/cursor-packs/{camellya,chisa}
unzip -q -o ~/Downloads/camellya_fbd4ebf39e_VSTHEMES-ORG.zip \
  -d ~/Projects/cursor-packs/camellya
unzip -q -o ~/Downloads/chibi-chisa-wuwa_dd9b80d3fb_VSTHEMES-ORG.zip \
  -d ~/Projects/cursor-packs/chisa

mkdir -p ~/Documents/Cursors
conv() { wcursor convert "$1" -o "$HOME/Documents/Cursors/$2" --name "$2" -q; }
conv ~/Projects/cursor-packs/camellya/Cursors/Red   Camellya-Red-Animated
conv ~/Projects/cursor-packs/camellya/Cursors/White Camellya-White-Animated
conv ~/Projects/cursor-packs/camellya/Static/Red    Camellya-Red-Static
conv ~/Projects/cursor-packs/camellya/Static/White  Camellya-White-Static
conv ~/Projects/cursor-packs/chisa/Windows          Chisa-Animated
conv ~/Projects/cursor-packs/chisa/Static           Chisa-Static

# install (copy) into the icon dir and expose to niri via ~/.icons
for n in Camellya-Red-Animated Camellya-White-Animated \
         Camellya-Red-Static Camellya-White-Static \
         Chisa-Animated Chisa-Static; do
  rm -rf ~/.local/share/icons/"$n"
  cp -a ~/Documents/Cursors/"$n" ~/.local/share/icons/"$n"
  ln -sfn ~/.local/share/icons/"$n" ~/.icons/"$n"
done
```

**niri does not search `~/.local/share/icons` here.** niri loads cursors with
the Rust `xcursor` crate, which — when `XDG_DATA_HOME` is set — looks in
`~/.local/share` instead of `~/.local/share/icons`. Themes that exist only in
`~/.local/share/icons` are invisible to niri and it silently draws its built-in
black arrow (`WARN niri::cursor: error loading xcursor ...: no default icon` in
the journal). The `ln -sfn` loop above is therefore required, not cosmetic;
`~/.icons` is searched by niri, libwayland-cursor and Xcursor alike.

**Move cursor / open hand.** The Move slot (`fleur`) prefers an open-palm image
when a pack ships one (`OpenHand.*`, `Palm.*`, `Hand1.*`, or an INF key such as
`openhand = ...`). Windows packs almost never include one, so it falls back to
the pack's own 4-corner move arrow (`Move.ani`/`Move.cur`). The open-hand/grab
names (`grab`, `grabbing`, `closedhand`, `hand1`, `openhand`) are aliases of
`fleur`, so they show the same image instead of falling back to Adwaita's open
hand. The link slot (`hand2`, plus `pointer`/`pointing_hand`, i.e.
hover/buttons/link-click) is deliberately left alone and keeps the pack's own
pointing hand. Implemented in `wcursor/pack.py` (`find_palm_source`) and the
`ALIASES` table in `wcursor/roles.py`; covered by `tests/test_pack.py` and
`tests/test_roles.py`.

**DMS is the source of truth for the active theme and size.** It writes
`cursorSettings`, `niri/dms/cursor.kdl`, and `.Xresources`, and sets
`XCURSOR_THEME`/`XCURSOR_SIZE` for apps it launches. It does **not** update
GTK, GSettings, `~/.icons/default`, or reload niri, so changing the cursor only
in DMS leaves some apps on the old cursor.

After picking a cursor in DMS, push the same theme through WCursor so GTK,
GSettings, `~/.icons/default` and niri catch up:

```bash
wcursor set "<theme>" --size <size> --no-dms
```

DMS rewrites `cursor.kdl` several times while the cursor picker is open, so run
the command once after choosing. The active cursor is whatever DMS has
selected. Check the full state with:

```bash
wcursor list
wcursor current
```

Switch variants from the DMS cursor settings or with `wcursor set`, for
example:

```bash
wcursor set Camellya-Red-Animated   --size 64
wcursor set Camellya-White-Animated --size 64
wcursor set Camellya-Red-Static     --size 64
wcursor set Camellya-White-Static   --size 64
wcursor set Chisa-Animated          --size 64
wcursor set Chisa-Static            --size 64
```

Apps started before a cursor change keep the old `XCURSOR_THEME` in their
environment; restart them (or log out/in) to pick up the new theme.

All six themes include 24/32/48/64 px; use `--size 24` for a smaller cursor.
`wcursor set` may restart DMS when it has to rewrite DMS's files; the sync
service always passes `--no-dms`. Other targets are backed up once as
`<file>.wcursor-bak`. The source ZIPs (~11 MB) stay in `~/Downloads` and are
not committed. The sync helper skips **System Default** and system-only themes
such as **Adwaita**, because WCursor only manages themes installed under
`~/.local/share/icons`.

### fastfetch greeting

- Random sprite: `pokeget random --hide-name` (installed from the signed
  `pokeget-rs` v1.6.7 GitHub release to `~/.local/bin/pokeget`).
- `linux/scripts/pokemon-logo.sh` remaps pokeget's pure-black pixels to the DMS
  background (`#141218`) so the sprite blends into the terminal.
- `linux/.config/fastfetch/config.jsonc` uses logo type `command-raw`, so a new
  random Pokémon is drawn every time a new kitty window/tab opens.
- The ASCII box was removed; modules are plain key/value lines.
- Disable the greeting with `NOFETCH=1`, or call `fastfetch` manually with
  `fetch`.

If kitty does not pick up a new theme, reload it:

```bash
kitty @ --to unix:/tmp/kitty-$USER set-colors --all --configured ~/.config/kitty/dank-theme.conf
```

---

## 6. Installed CLI toolkit

| Tool | Why |
|---|---|
| `zsh` + `zsh-*` plugins | shell |
| `powerlevel10k` | prompt |
| `kitty` | GPU terminal |
| `eza` | modern `ls` (icons, git, tree) |
| `bat` | syntax-highlighted `cat`/pager |
| `fd` | fast `find` |
| `ripgrep` | fast `grep` |
| `fzf` + `fzf-tab` | fuzzy finder everywhere |
| `zoxide` | smarter `cd` (`z`, `zi`) |
| `vivid` | `LS_COLORS` from Catppuccin Mocha |
| `yazi` | TUI file manager |
| `lazygit` | TUI git client |
| `btop` | system monitor |
| `fastfetch` | system info |
| `pokeget` | random Pokémon sprite for fastfetch |
| `direnv` | per-directory env |
| `git-delta` | better git diffs |
| `duf` / `dust` / `procs` / `glow` | disk / tree-size / process / markdown |
| `tealdeer` | fast `tldr` (`tldr`) |
| `pkgfile` | command-not-found package hints |
| `zellij` | terminal multiplexer |
| `neovim` | editor (`EDITOR`/`VISUAL`/`MANPAGER`) |
| `nodejs` / `npm` | LSP servers and Mason packages |
| `tree-sitter-cli` | Treesitter parsers |
| `stylua` / `shfmt` | Lua / shell formatting |
| `jq` | reads DMS session and wallpaper state from `~/.local/state/DankMaterialShell/session.json` |
| `discord` | Discord desktop client (Equicord patched in) |
| `spotify-launcher` | official Spotify client with self-updates |
| `wcursor` | Windows cursor pack conversion/install + system-wide switching |
| `paru` | AUR helper |

Fonts: `ttf-zed-mono-nerd`, `ttf-iosevka-nerd`, `ttf-jetbrains-mono-nerd`,
`ttf-nerd-fonts-symbols-mono`. Icons: `numix-square-icon-theme-git` +
`numix-icon-theme-git` (AUR).

---

## 7. paru (AUR)

- Installed from the CachyOS repo (`paru 2.1.0`).
- Config: `linux/.config/paru/paru.conf` (symlinked).
- Enabled: `PgpFetch`, `Devel`, `Provides`, `CombinedUpgrade`, `UpgradeMenu`,
  `NewsOnUpgrade`, `SudoLoop`, `BatchInstall`, `UseAsk`, `CleanAfter`.
- Common commands:

```bash
paru                 # full upgrade (repo + AUR)
paru -S <pkg>        # install (repo or AUR)
paru -Ss <query>     # search repo + AUR
paru -Sc             # clean package cache / build dirs
paru -Qdtq | paru -R -  # remove orphaned packages
```

> AUR packages are user-submitted. Review PKGBUILDs (`paru --review`) before
> installing unfamiliar packages.

---

## 8. Git, GitHub CLI, and identity

- `git` identity is set in `linux/.gitconfig`:
  `SpreadSheets600 <dev.spreadsheets600@gmail.com>`.
- `gh` is authenticated for `SpreadSheets600` with `repo`, `workflow`, `gist`,
  and `read:org` scopes.
- Git uses the gh credential helper for HTTPS. Verify with:

```bash
gh auth status
git config --global --list
```

- `git lg`, `git st`, `git last`, `git undo`, `git amend` are configured.
- Diffs use delta with line numbers and side-by-side view.

---

## 9. niri + DMS notes

The live niri config was imported as-is into `linux/.config/niri/`:

- `config.kdl` plus `dms/*.kdl` includes (`colors`, `layout`, `alttab`, `binds`,
  `outputs`, `cursor`, `input`).
- User window rules live in `custom/windowrules.kdl`, included after the DMS
  files. This currently floats browser picture-in-picture windows, Google Meet
  browser tabs, and the Meet web app. Keep overrides out of `dms/` so a DMS
  regeneration cannot remove them.
- DMS owns the generated `dms/` files and the kitty theme files. Editing them
  manually is fine, but DMS may overwrite them on a theme change.
- DMS is set to `currentThemeName: "dynamic"`; matugen derives every palette
  from the current wallpaper (`~/.local/state/DankMaterialShell/session.json`)
  and re-runs the enabled templates when it changes.
- Old `config.d/` modules and timestamped `config.kdl.backup*` files were
  removed; git history still contains them.
- niri output config is currently for the laptop panel (`1920x1080@120`,
  scale 2). Adjust in `dms/outputs.kdl` or via `niri msg outputs`.

Check the config without logging out:

```bash
niri validate -c ~/.config/niri/config.kdl
```

---

## 10. Windows / shared files

Copy these manually on the Windows side:

| Repo path | Target |
|---|---|
| `windows/terminal/settings.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `windows/komorebi/komorebi.json` | `%USERPROFILE%\.config\komorebi\komorebi.json` |
| `windows/komorebi/whkdrc` | `%USERPROFILE%\.config\komorebi\whkdrc` |
| `windows/yasb/config.yaml`, `styles.css` | `%USERPROFILE%\.config\yasb\` |
| `windows/wsl/wsl.conf` | inside WSL: `/etc/wsl.conf` |
| `windows/wsl/wsl.config` | `%USERPROFILE%\.wslconfig` |
| `windows/rainmeter/squareplayer.rmskin` | import via Rainmeter |
| `windows/scripts/system-cleanup.ps1` | run as Administrator |
| `shared/vscode/settings.json` | `%APPDATA%\Code\User\settings.json` (or Linux `~/.config/Code/User/`) |
| `shared/zed/settings.json` + `themes/` | Zed settings dir (`~/.config/zed`, `%APPDATA%\Zed`) |
| `shared/discord/*.css` | BetterDiscord themes folder |

After changing WSL config: `wsl --shutdown` in PowerShell.

Windhawk mods are stored per-mod in `windows/windhawk/*.json`; paste them into
the Windhawk UI (or import if supported).

---

## 11. Verification checklist

```bash
# shell
echo $SHELL                     # /usr/bin/zsh (after re-login)
zsh -i -c 'echo ok'
p10k configure                  # only if you want to change the prompt

# tools
eza --version && bat --version && zoxide --version && yazi --version
fzf --version && vivid --version && paru --version
tldr tar

# fonts / icons / cursors
gsettings get org.gnome.desktop.interface font-name
gsettings get org.gnome.desktop.interface icon-theme
gsettings get org.gnome.desktop.interface cursor-theme
gsettings get org.gnome.desktop.interface cursor-size
fc-match monospace
ls /usr/share/icons/Numix-Square
wcursor list
wcursor current
wcursor doctor

# fastfetch logo
pokemon-logo.sh | head -3
fastfetch --config ~/.config/fastfetch/config.jsonc

# neovim / lazyvim
nvim --headless "+lua print(vim.g.colors_name)" +qa   # dms (base46)
nvim --headless "+checkhealth lazyvim" +qa

# apps
spotify-launcher --version
discord --version
test -f ~/.config/Equicord/equicord.asar && echo "Equicord patched"
command -v webapp.sh
webapp.sh --list
desktop-file-validate ~/.local/share/applications/webapp-whatsapp.desktop

# config links
ls -l ~/.zshrc ~/.p10k.zsh ~/.config/kitty ~/.config/niri ~/.config/nvim

# git / gh
gh auth status
git config --global user.email

# niri
niri validate -c ~/.config/niri/config.kdl

# kitty config parse (opens a short test window)
kitty --config ~/.config/kitty/kitty.conf sh -c 'sleep 0.2'
```

---

## 12. Troubleshooting

| Symptom | Fix |
|---|---|
| Icons show as boxes | `fc-cache -f`, confirm `ZedMono Nerd Font` in `fc-list`, restart kitty. |
| System font did not change | `gsettings set …` again, restart the app; GTK apps may need a re-login. |
| Icon theme did not change | `gsettings get … icon-theme`, then restart the app; some Qt/Flatpak apps need their own override. |
| Cursor theme did not change | `wcursor set '<theme>' --size 32`, then restart the app; check `wcursor current` for mismatched targets. |
| DMS cursor changed but GTK/X11 apps still use the old one | Run `wcursor set '<theme>' --size <size> --no-dms`, then check `wcursor current`. |
| Cursor is too small or too large | Switch size with `wcursor set '<theme>' --size 24` (or 32/48/64); the theme includes all four sizes. |
| WCursor cannot map a pack | Point it at the folder containing the `.ani`/`.cur` files and `install.inf`, e.g. `camellya/Cursors/White` — not the ZIP root. |
| Prompt looks wrong | `p10k configure`, or check `~/.p10k.zsh` is linked. |
| “Instant prompt” warning | Some program prints before `.zshrc`; move it later or set `POWERLEVEL9K_INSTANT_PROMPT=off`. |
| `zsh: command not found` after install | Open a new terminal; login shell changes need a re-login. |
| Old config still appears | `exec zsh -l`; check `readlink -f ~/.zshrc`. |
| paru cannot build an AUR package | Read the PKGBUILD (`paru --review`), then `paru -S --rebuild <pkg>`. |
| DMS theme changed kitty | Reload kitty or `kitty @ set-colors --all --configured ~/.config/kitty/dank-theme.conf`. |
| Broken symlink in `~/.config` | Re-run `./install.sh`; restore from `~/.local/state/dotfiles-backups/`. |
| Neovim plugins missing after pull | `nvim --headless "+Lazy! sync" +qa`, then restart `nvim`. |
| LSP/tool not found in Neovim | Open `:Mason`, install it, or `pacman -S` the binary (for example `tree-sitter-cli`). |
| Treesitter parser fails to build | Confirm `gcc`, `make`, and `tree-sitter` are installed; rerun `:TSUpdate`. |
| Neovim stays Catppuccin | Check `~/.config/nvim/colors/dms.lua` exists; change the DMS wallpaper/theme once so matugen regenerates it, then restart `nvim`. |
| A web app has no icon | `update-desktop-database ~/.local/share/applications`; the script uses the first matching `web-<slug>` icon, otherwise `web-browser`. |
| Discord lost Equicord after an update | Re-run the Equilotl command in §14. |
| DMS Discord theme not visible | Enable it under Equicord → Themes; the file is `~/.config/Equicord/themes/dank-discord.css`. |

---

## 13. Neovim + LazyVim

The config lives in `linux/.config/nvim` and is symlinked to `~/.config/nvim` by
`install.sh`.

- **Base:** LazyVim starter (`init.lua`, `lua/config/`, `lua/plugins/`).
- **Extras:** Python, TypeScript, JSON, YAML, TOML, Markdown, Docker, and Git.
  Browse or add more with `:LazyExtras`.
- **Theme:** `base46` + the colorscheme generated by DMS. DankMaterialShell
  writes `~/.config/nvim/colors/dms.lua` and
  `~/.config/nvim/lua/lualine/themes/dms.lua` on wallpaper/theme changes; the
  generated colorscheme hot-reloads inside Neovim. Catppuccin Mocha is kept only
  as a fallback for sessions where DMS has not generated the files yet.
  `<leader>w` saves, `<leader>W` saves all buffers, and `<leader>qq` quits
  everything.
- **Editing:** system clipboard, `scrolloff=8`, no wrap, cursorline, and a
  100-column guide. Undo history persists between sessions.
- **Tooling:** LSP servers, formatters, and linters are managed by Mason and
  install on demand. Required host tools: `nodejs`/`npm`, `tree-sitter-cli`,
  `stylua`, `shfmt`, `gcc`, `make`, `rg`, and `fd`.
- **Data:** plugins, Mason packages, and parser builds live in
  `~/.local/share/nvim` and are intentionally **not** tracked. The repo holds
  only the configuration; the DMS-generated `colors/dms.lua` and lualine theme
  are gitignored too.

Useful commands: `:Lazy` (plugins), `:LazyExtras` (language packs),
`:Mason` (LSP/formatters), `:checkhealth` (diagnostics).

After changing the config in the repo, run `./install.sh` (only needed for new
symlinks) and `nvim` — LazyVim picks up changes on the next start.

---

## 14. Apps & web apps

### Spotify

Installed with `spotify-launcher` (official client, self-updating). The client
was pre-downloaded with `spotify-launcher --no-exec`, so the first launch is
instant.

```bash
spotify-launcher
```

### Discord + Equicord

`discord` is the normal Arch package, patched with **Equicord** using the
official Equilotl CLI. Equicord lives in `~/.config/Equicord/equicord.asar`;
Discord's original `app.asar` is preserved as `_app.asar`.

After a Discord update, re-apply Equicord:

```bash
curl -fsSL -o /tmp/EquilotlCli-linux \
  https://github.com/Equicord/Equilotl/releases/latest/download/EquilotlCli-linux
chmod +x /tmp/EquilotlCli-linux
sudo env "XDG_CONFIG_HOME=$HOME/.config" /tmp/EquilotlCli-linux -install -branch stable
```

DMS also writes a Discord CSS theme to
`~/.config/Vencord/themes/dank-discord.css`; it is linked into Equicord as
`~/.config/Equicord/themes/dank-discord.css`. Enable **DMS** under
**Equicord → Themes** to use it.

### Web apps (Brave app mode)

`webapp.sh` turns any URL into an app window: no tabs, no address bar, and it
writes a desktop entry so the site appears in the app menu. By default it uses
your **normal browser profile**, so links open in the browser/profile you
already use. Pass `--isolated` (or set `WEBAPP_ISOLATED=1`) only when a site
needs its own cookies/session/profile.

```bash
webapp.sh <url> [name]              # launch + create/update the menu entry
webapp.sh --isolated <url> [name]   # same, with a separate profile
webapp.sh --install <url> [name]    # create/update the entry only
webapp.sh --list                    # show installed web apps
webapp.sh --remove <name> [--purge] # remove entry; --purge also deletes its isolated profile
```

WhatsApp is installed as:

```bash
webapp.sh https://web.whatsapp.com WhatsApp
```

Close any app window that was launched before switching profile modes, then
reopen it from the app menu.

Each app gets:

- launcher: `~/.local/share/applications/webapp-<slug>.desktop`
- default profile: the browser's normal profile (links stay in your session)
- isolated profile, with `--isolated`: `~/.local/share/webapps/<slug>`
- Wayland app ID: `brave-<host>__-Default` (or the Chromium equivalent), written
  to `StartupWMClass` so niri associates the window with the launcher
- X11 class: `webapp-<slug>` (passed as `--class`)

The default browser is `brave-origin`; override it with
`WEBAPP_BROWSER=brave` (or another Chromium binary). The shell and apps re-theme
themselves when DMS changes the wallpaper.

---

## 15. Next steps / ideas

- Add `zellij` layouts and a `tmux`-style workflow if needed.
- Set up `atuin` if you want searchable, syncable shell history.
- Add `starship` config only if you decide to switch away from p10k.
- Add a `chezmoi`/`stow` workflow if the repo grows beyond one machine.
- Capture a fresh screenshot set for the README (`fastfetch` + kitty + niri).

---

## 16. GitHub sync & wallpapers

### Setup configs (`dotfiles-sync.sh`)

GitHub is the backup. `dotfiles-sync.sh` commits and pushes only the paths in
the manifest `linux/scripts/dotfiles-sync.paths` — the files needed to rebuild
the Linux setup — instead of the whole repo:

```text
linux/          shell files, every app config install.sh links, helper scripts
install.sh      installer
README.md
SYSTEM.md
.gitignore      repo ignore rules
shared/         VS Code / Zed / Discord configs (cross-platform)
wallpapers/     submodule pin for the wallpaper collection
```

Deliberately **not** synced: `.github/images` (README screenshots) and
`windows/`. Add a line to the manifest to include either of them, or run
`dotfiles-sync.sh run --all` for a one-off full sync.

Run it by hand, or point your own timer at it:

| Thing | Where |
|---|---|
| script | `linux/scripts/dotfiles-sync.sh` -> `~/.local/bin/dotfiles-sync.sh` |
| manifest | `linux/scripts/dotfiles-sync.paths` |
| safety | refuses token formats, private keys, `.env`/`credentials` files, >95 MB |

```bash
dotfiles-sync.sh list          # paths included in the backup
dotfiles-sync.sh status        # pending changes + ahead/behind
dotfiles-sync.sh --dry-run     # preview
dotfiles-sync.sh run           # commit + push now
dotfiles-sync.sh run --all     # include wallpapers/windows/screenshots too
```

It rebases on `origin/main` before pushing and keeps offline commits for the
next run.

Only files inside `~/Dotfiles` can be synced. If a config is not in the repo
yet, add it under `linux/.config/` and run `install.sh` so it gets symlinked.

### Wallpapers

Wallpapers live in their own repository,
[SpreadSheets600/Wallpapers](https://github.com/SpreadSheets600/Wallpapers),
mounted here as the `wallpapers/` submodule. The images live flat in
`wallpapers/Wallpapers/`, numbered in a stable order, and `~/Pictures/Wallpapers`
is a symlink to that image root.

```text
~/Dotfiles/wallpapers/             <-- submodule -> SpreadSheets600/Wallpapers
~/Dotfiles/wallpapers/Wallpapers/  <-- the images, no subfolders
~/Pictures/Wallpapers -> ~/Dotfiles/wallpapers/Wallpapers
~/Pictures/Wallapaper -> ~/Dotfiles/wallpapers/Wallpapers   # old spelling, kept
```

Drop an image into `Wallpapers/` and run `dotfiles-sync.sh`: it commits and
pushes the submodule first, then records the new commit in Dotfiles. By hand:

```bash
cd ~/Dotfiles/wallpapers
python3 scripts/organize.py       # HEIC -> JPEG, renumber loose files
python3 scripts/build_readme.py   # refresh README
python3 scripts/build_site.py     # refresh the gallery
git add -A && git commit -m "feat: add wallpapers" && git push
cd .. && git add wallpapers && git commit -m "chore: bump wallpapers"
```

A fresh clone needs the submodule too:

```bash
git clone --recurse-submodules https://github.com/SpreadSheets600/Dotfiles.git ~/Dotfiles
git submodule update --init --recursive   # for an existing clone
```

`install.sh` recreates the `~/Pictures/Wallpapers` link and initialises the
submodule when it is empty. The submodule keeps the wallpaper repo's full
history, so its `.git` is far bigger than the images it holds.

The wallpaper repo also builds its own site: a push runs
`.github/workflows/site.yml`, which renders 480 px WebP thumbnails, rebuilds the
README and force-pushes the result to the `gh-pages` branch
(<https://spreadsheets600.github.io/Wallpapers/>). Thumbnails live only on that
branch — the source images never leave `master`.
