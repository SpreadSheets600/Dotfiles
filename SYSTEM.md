# SYSTEM.md

Living notes for this machine and the dotfiles repo. Updated whenever the
setup changes.

- **Last updated:** 2026-10-21
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
   `glow`, `pkgfile`, `fzf-tab`, plus Nerd Fonts (`Iosevka`, `JetBrains Mono`,
   `Symbols`).
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

---

## 2. Repository layout

```text
Dotfiles/
├── install.sh              # link linux/ configs into $HOME (backs up first)
├── SYSTEM.md               # this file
├── README.md
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
│   │   ├── fastfetch/
│   │   ├── lazygit/
│   │   ├── cava/
│   │   ├── conky/
│   │   ├── goverlay/
│   │   ├── MangoHud/
│   │   └── autostart/
│   └── scripts/            # Linux helper scripts (linked into ~/.local/bin)
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
| `~/.config/{kitty,niri,paru,fastfetch,lazygit,cava,conky,goverlay,MangoHud,autostart}` | `linux/.config/...` |
| `~/.local/bin/{game.sh,VirtualPhoneCam.sh,cheatenginelaunch.sh}` | `linux/scripts/...` |

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

There is no automatic backup script any more. The repo **is** the source of
truth; `install.sh` never deletes user data.

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

`fastfetch` runs only in the first interactive shell of a terminal (not inside
tmux/zellij). Disable with:

```bash
NOFETCH=1 zsh
# or permanently, add this above the greeting in .zshrc:
#   return
```

---

## 5. Terminal (kitty)

Config: `linux/.config/kitty/kitty.conf`

- Font: **Iosevka Nerd Font** 12.5, line height 105%, ligatures on.
- Padding 16 px, no server-side decorations, 96% opacity, 24 px blur.
- DMS/ii-generated colours are included from `dank-theme.conf` and
  `dank-tabs.conf`. DMS rewrites these files; because the directory is a
  symlink, they land in this repo.
- Tabs: powerline, slanted, top edge, hidden when only one tab.
- Shell: `/usr/bin/zsh`.
- `Ctrl+Shift+C/V` copy/paste, `Ctrl+C` copy-or-interrupt, `Ctrl+Shift+T/N`
  new tab/window in cwd, `Ctrl+Shift+F` scrollback search, `Ctrl +/-/0` zoom.

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
| `direnv` | per-directory env |
| `git-delta` | better git diffs |
| `duf` / `dust` / `procs` / `glow` | disk / tree-size / process / markdown |
| `tealdeer` | fast `tldr` (`tldr`) |
| `pkgfile` | command-not-found package hints |
| `zellij` | terminal multiplexer |
| `neovim` | editor (`EDITOR`/`VISUAL`/`MANPAGER`) |
| `paru` | AUR helper |

Fonts: `ttf-iosevka-nerd`, `ttf-jetbrains-mono-nerd`,
`ttf-nerd-fonts-symbols-mono`.

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
- DMS owns the generated `dms/` files and the kitty theme files. Editing them
  manually is fine, but DMS may overwrite them on a theme change.
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

# config links
ls -l ~/.zshrc ~/.p10k.zsh ~/.config/kitty ~/.config/niri

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
| Icons show as boxes | `fc-cache -f`, confirm `Iosevka Nerd Font` in `fc-list`, restart kitty. |
| Prompt looks wrong | `p10k configure`, or check `~/.p10k.zsh` is linked. |
| “Instant prompt” warning | Some program prints before `.zshrc`; move it later or set `POWERLEVEL9K_INSTANT_PROMPT=off`. |
| `zsh: command not found` after install | Open a new terminal; login shell changes need a re-login. |
| Old config still appears | `exec zsh -l`; check `readlink -f ~/.zshrc`. |
| paru cannot build an AUR package | Read the PKGBUILD (`paru --review`), then `paru -S --rebuild <pkg>`. |
| DMS theme changed kitty | Reload kitty or `kitty @ set-colors --all --configured ~/.config/kitty/dank-theme.conf`. |
| Broken symlink in `~/.config` | Re-run `./install.sh`; restore from `~/.local/state/dotfiles-backups/`. |

---

## 13. Next steps / ideas

- Add `zellij` layouts and a `tmux`-style workflow if needed.
- Set up `atuin` if you want searchable, syncable shell history.
- Add `starship` config only if you decide to switch away from p10k.
- Add a `chezmoi`/`stow` workflow if the repo grows beyond one machine.
- Capture a fresh screenshot set for the README (`fastfetch` + kitty + niri).
