# dotfiles

<div align="center">
  <img src=".github/images/linux/image-1.png" alt="niri desktop with DankMaterialShell bar, cava and clock widgets" width="100%"/>
</div>

<div align="center">
  <img src=".github/images/windows/image-1.png" alt="Windows desktop with YASB bar, cava and Rainmeter clock" width="100%"/>
</div>

<div align="center">
  <img src=".github/images/windows/image-3.png" alt="fastfetch in Windows Terminal" width="49%"/>
  <img src=".github/images/linux/image-3.png" alt="fastfetch in kitty" width="49%"/>
</div>

> [!NOTE]
> I dual-boot CachyOS and Windows 11 on the same machine. Everything for both
> sides lives in this repo: `linux/` is symlinked into `$HOME` by `install.sh`,
> `windows/` is copied by hand on the Windows partition.

## Stack

| Linux | Windows |
| :-- | :-- |
| [niri](https://github.com/YaLTeR/niri) | [Komorebi](https://github.com/LGUG2Z/komorebi) + [WHKD](https://github.com/LGUG2Z/whkd) |
| DankMaterialShell | [YASB](https://github.com/amnweb/yasb) + [Windhawk](https://windhawk.net/) |
| [kitty](https://github.com/kovidgoyal/kitty), zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | [Windows Terminal](https://github.com/microsoft/terminal), zsh in [WSL](https://learn.microsoft.com/windows/wsl/) |
| [Neovim](https://github.com/neovim/neovim) + [LazyVim](https://www.lazyvim.org/), Zed, VS Code | Zed, VS Code |
| [Conky](https://github.com/brndnmtthws/conky), btop, [cava](https://github.com/karlstav/cava), [fastfetch](https://github.com/fastfetch-cli/fastfetch) | [Rainmeter](https://www.rainmeter.net/), cava, fastfetch |

## Palette

- **Theme**: matugen, generated from the current wallpaper
- **Font**: ZedMono Nerd Font
- **Icons**: Numix-Square
- **Cursors**: [WCurso](https://github.com/SpreadSheets600/WCursor)r packs (Camellya, Chisa)
- **Wallpapers**: [SpreadSheets600/Wallpapers](https://github.com/SpreadSheets600/Wallpapers)

---

## Install

```bash
git clone --recurse-submodules https://github.com/SpreadSheets600/Dotfiles.git ~/Dotfiles

cd ~/Dotfiles

./install.sh --dry-run   # show the links
./install.sh             # back up conflicts, then symlink

chsh -s /usr/bin/zsh     # if zsh is not your login shell yet
```

> [!NOTE]
> These are my personal settings, published as a backup and for reference. Read
> `install.sh` before running it and expect to change keybinds, paths and
> hardware bits. Existing files are moved to
> `~/.local/state/dotfiles-backups/<timestamp>/` first, nothing is deleted.

---

## Linux

niri tiles the windows, DankMaterialShell draws the bar, dock, widgets and lock
screen, and matugen recolours Neovim, kitty, GTK, Discord and niri from the
current wallpaper. The editor hot-reloads the generated palette, so a wallpaper
change re-themes the whole desktop without a restart.

Helpers live in `linux/scripts/` and land in `~/.local/bin`:

| Script | What it does |
| :-- | :-- |
| `webapp.sh` | any site in a browser app window, plus a menu entry |
| `dotfiles-sync.sh` | commit and push this repo to GitHub |
| `game-launch.sh` | gamescope + gamemode + MangoHud wrapper |
| `phone-cam.sh` | Android phone as a virtual camera |
| `pokemon-logo.sh` | random Pokémon sprite for fastfetch |

Keybinds: `linux/.config/niri/dms/binds.kdl` and `linux/.config/niri/custom/`.
Validate the config with `niri validate -c ~/.config/niri/config.kdl`.

---

## Windows

Komorebi tiles, YASB replaces the taskbar, Windhawk restyles it, and Rainmeter
draws the clock and cava. WSL runs Debian with the same zsh setup as the Linux
side.

| Repo path | Target |
| :-- | :-- |
| `windows/terminal/settings.json` | Windows Terminal `settings.json` |
| `windows/komorebi/` | `%USERPROFILE%\.config\komorebi` |
| `windows/yasb/` | `%USERPROFILE%\.config\yasb` |
| `windows/windhawk/` | paste into the Windhawk UI |
| `windows/rainmeter/` | import the `.rmskin` |
| `windows/wsl/` | `wsl.conf` inside WSL, `wsl.config` as `%USERPROFILE%\.wslconfig` |

> [!NOTE]
> Windhawk mods are stored per mod in `windows/windhawk/*.json`. Paste them into
> the mod's advanced settings and hit save. Full target paths are in
> [`SYSTEM.md` §10](SYSTEM.md#10-windows--shared-files).

---

## Wallpapers

[**SpreadSheets600/Wallpapers**](https://github.com/SpreadSheets600/Wallpapers)
is mounted at `wallpapers/` and `~/Pictures/Wallpapers` points straight at
`wallpapers/Wallpapers/`, one flat folder of images, so any picker can use the
collection. Every push rebuilds a gallery at
[spreadsheets600.github.io/Wallpapers](https://spreadsheets600.github.io/Wallpapers/).

```bash
cd ~/Dotfiles/wallpapers
python3 scripts/organize.py       # HEIC -> JPEG, renumber loose files
python3 scripts/build_site.py     # thumbnails + site -> _site/
```

---

## Sync

`dotfiles-sync.sh` commits and pushes the paths in `linux/scripts/dotfiles-sync.paths`.
It stages only what rebuilds the Linux setup, refuses secrets and files over
95 MB, rebases if the remote moved, and pushes the wallpaper submodule before
recording its new commit here.

```bash
dotfiles-sync.sh list       # what gets committed
dotfiles-sync.sh status     # pending changes + ahead/behind
dotfiles-sync.sh run        # commit + push now
dotfiles-sync.sh --dry-run  # preview
```
