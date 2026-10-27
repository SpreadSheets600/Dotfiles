# dotfiles

CachyOS with **niri** + **DankMaterialShell** on Linux, Windows 11 on the side.
The Linux configs are symlinked into `$HOME` by one script, the rest is copied
by hand. Everything that can be versioned is versioned.

![niri + DankMaterialShell on CachyOS](linux/screenshots/desktop-2026-10-22.png)

## layout

```text
linux/                CachyOS configs, linked into $HOME by install.sh
  .config/            kitty, niri, nvim, fastfetch, cava, conky, ...
  snapshots/          live configs that cannot be symlinked (copied by the sync)
  scripts/            helpers installed to ~/.local/bin
  systemd/user/       sync timer + cursor path units
windows/              Windows 11 configs, copied manually
shared/               VS Code, Zed and Discord configs (both platforms)
wallpapers/           submodule -> SpreadSheets600/Wallpapers
install.sh            link everything, back up whatever is in the way
SYSTEM.md             long-form notes: setup, keybinds, packages, fixes
```

`SYSTEM.md` is the manual: it explains how each piece was set up, what every
keybind does, and how to fix the things that tend to break.

## install

```bash
git clone --recurse-submodules https://github.com/SpreadSheets600/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles

./install.sh --dry-run    # show what would be linked
./install.sh              # back up conflicts, then symlink
chsh -s /usr/bin/zsh      # if zsh is not your login shell
exec zsh -l
```

Nothing is deleted: every file that is in the way is moved to
`~/.local/state/dotfiles-backups/<timestamp>/` first. The installer also
creates the `~/Pictures/Wallpapers` link, initialises the wallpaper submodule
and enables the sync timer.

Already cloned without submodules?

```bash
git submodule update --init --recursive
```

### packages

```bash
sudo pacman -S --needed zsh zsh-completions zsh-autosuggestions \
  zsh-syntax-highlighting zsh-history-substring-search zsh-theme-powerlevel10k \
  kitty bat eza fzf fd ripgrep zoxide vivid yazi direnv stow lazygit btop \
  fastfetch cava neovim nodejs npm tree-sitter-cli stylua shfmt jq \
  discord spotify-launcher zellij git-delta duf dust procs glow pkgfile \
  ttf-zed-mono-nerd ttf-iosevka-nerd ttf-jetbrains-mono-nerd \
  ttf-nerd-fonts-symbols-mono

sudo pacman -S --needed paru
paru -S fzf-tab numix-square-icon-theme-git   # AUR
```

## the stack

| area | linux | windows |
|---|---|---|
| compositor | niri | Komorebi + WHKD |
| bar | DankMaterialShell | YASB |
| terminal | kitty | Windows Terminal |
| shell | zsh + Powerlevel10k | — |
| editor | Neovim (LazyVim), Zed, VS Code | Zed, VS Code |
| taskbar | — | Windhawk |
| monitor | btop, Conky | — |
| fonts | ZedMono Nerd Font | — |
| icons | Numix-Square | — |
| cursors | WCursor (Camellya / Chisa) | Windows cursor |
| theme | DMS matugen | custom / Rainmeter |

**Theming** — DankMaterialShell generates a matugen palette from the current
wallpaper and writes it into Neovim (`colors/dms.lua` + lualine), kitty, GTK,
Discord CSS and niri. Neovim hot-reloads those files, so the editor follows the
wallpaper without a restart. `dms-theme-refresh.sh` forces a full regeneration
after installing a themed app.

**Shell** — no plugin manager and no network calls at startup. Powerlevel10k
with a two-line prompt, `eza`, `bat`, `fd`, `ripgrep`, `fzf-tab`, `zoxide`,
`yazi`, `lazygit`, `direnv`, `vivid`, `git-delta`, a shared 100k history and
`fastfetch` with a random Pokémon sprite (`NOFETCH=1` to skip).

**Editor** — LazyVim with Python, TypeScript, JSON, YAML, TOML, Markdown,
Docker and Git extras. Mason installs LSPs, formatters and linters on demand;
Treesitter uses the system CLI. Only the config is tracked — plugins live in
`~/.local/share/nvim`.

**Web apps** — `webapp.sh <url> [name]` opens any site in a Brave window with no
tabs or address bar and adds a menu entry. `--isolated` gives it a separate
profile, `--list` and `--remove` manage existing ones.

## sync

`dotfiles-sync.sh` commits and pushes the setup to GitHub on a 15-minute timer.
It stages only what is listed in `linux/scripts/dotfiles-sync.paths`, refuses
staged secrets and files over 95 MB, and rebases if the remote moved.

```bash
dotfiles-sync.sh list       # what gets committed
dotfiles-sync.sh status     # pending changes + ahead/behind
dotfiles-sync.sh run        # commit + push now
dotfiles-sync.sh --dry-run  # preview
```

Wallpapers are a submodule, so the sync commits and pushes inside
`wallpapers/` first and then records the new commit here. Adding an image is
just dropping it into a category folder.

## windows & shared

Copy from the repo to the target path — the full table is in
[`SYSTEM.md` §10](SYSTEM.md#10-windows--shared-files):

```text
windows/terminal/settings.json      Windows Terminal
windows/komorebi/                   %USERPROFILE%\.config\komorebi
windows/yasb/                       %USERPROFILE%\.config\yasb
windows/windhawk/                   paste into the Windhawk UI
windows/rainmeter/                  import the .rmskin
windows/wsl/wsl.conf                /etc/wsl.conf
windows/scripts/system-cleanup.ps1  run as Administrator
```

`shared/` holds VS Code and Zed settings plus the Discord CSS themes and Zed
themes, used on both platforms.

## wallpapers

[**SpreadSheets600/Wallpapers**](https://github.com/SpreadSheets600/Wallpapers)
is mounted at `wallpapers/`. The images are sorted by subject and then colour,
and `~/Pictures/Wallpapers` is a link straight to the image folders, so the
collection is usable from any picker without touching the repo.

```bash
cd ~/Dotfiles/wallpapers
python3 scripts/organize.py       # HEIC -> JPEG, renumber loose files
python3 scripts/build_readme.py   # refresh READMEs
python3 scripts/build_site.py     # refresh the GitHub Pages gallery
```

## notes

- Cursors: `wcursor current` shows the active theme; DMS owns the choice and a
  systemd path unit mirrors it to GTK, X11, GSettings and niri.
- Fonts and icons are re-applied by `install.sh` through `gsettings`.
- Identity, aliases and `gh` setup: [`SYSTEM.md` §8](SYSTEM.md#8-git-github-cli-and-identity).
- Fonts: [ZedMono](https://github.com/zed-industries/zed-fonts),
  [Iosevka](https://github.com/be5invis/Iosevka),
  [JetBrains Mono](https://www.jetbrains.com/lp/mono/),
  [Numix-Square](https://github.com/numixproject/numix-icon-theme-square).
