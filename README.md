<h1 align="center">dotfiles</h1>

<p align="center">
  CachyOS (niri + DMS) on Linux · Windows 11 on the side.<br>
  One repo, two platforms, no clutter.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OS-CachyOS-111111?style=flat-square" />
  <img src="https://img.shields.io/badge/WM-niri-111111?style=flat-square" />
  <img src="https://img.shields.io/badge/Windows-11-111111?style=flat-square" />
  <img src="https://img.shields.io/badge/Shell-Zsh%20%2B%20P10k-111111?style=flat-square" />
  <img src="https://img.shields.io/badge/Terminal-kitty-111111?style=flat-square" />
</p>

![Desktop](.github/images/image-7.png)

## Layout

```text
linux/     CachyOS configs (installed by install.sh via symlinks)
windows/   Windows 11 configs (copied manually)
shared/    VS Code, Zed, Discord themes
SYSTEM.md  what was done, how it works, troubleshooting
```

Full details — tool list, keybinds, aliases, install notes, Windows target
paths — live in **[SYSTEM.md](SYSTEM.md)**.

## Linux quick start

```bash
git clone https://github.com/SpreadSheets600/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./install.sh --dry-run
./install.sh              # backs up conflicts, then symlinks
chsh -s /usr/bin/zsh      # if zsh is not already your login shell
exec zsh -l
```

`install.sh` links `linux/` into `~/.config` and `$HOME`; it never deletes
anything. Previous files go to `~/.local/state/dotfiles-backups/<timestamp>/`.

### Packages

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

`pokeget` (random Pokémon logo) is installed from its signed GitHub release to
`~/.local/bin/pokeget`. See [SYSTEM.md §5](SYSTEM.md#5-terminal-fonts--icons-kitty--desktop).

## Components

| Area | Linux | Windows |
|---|---|---|
| Shell | zsh + Powerlevel10k | — |
| Terminal | kitty | Windows Terminal |
| WM | niri + DMS | Komorebi + WHKD |
| Bar | DMS | YASB |
| Taskbar | — | Windhawk |
| Editor | Neovim (LazyVim), Zed, VS Code | Zed, VS Code |
| Apps | Spotify, Discord + Equicord, any site as a Brave web app | — |
| Monitor | btop / Conky | — |
| Font | ZedMono Nerd Font (system + kitty) | — |
| Icons | Numix-Square | — |
| Theme | DMS matugen (base46 in Neovim) | Custom / Rainmeter |

### Shell

- Fast startup: Arch packages only, no plugin manager, no network calls.
- Powerlevel10k with a two-line prompt and the DMS purple palette.
- `eza`, `bat`, `fd`, `ripgrep`, `fzf` + `fzf-tab`, `zoxide`, `yazi`,
  `lazygit`, `direnv`, `vivid`, `git-delta`.
- Shared 100k history, substring search, fzf history (`Ctrl+R`).
- `fastfetch` greets each new kitty window with a random Pokémon sprite
  (`NOFETCH=1` to skip).

### Neovim

- **LazyVim** with Python, TypeScript, JSON, YAML, TOML, Markdown, Docker, and
  Git extras (`:LazyExtras` to add more).
- Colors follow **DankMaterialShell** through the
  [base46](https://github.com/AvengeMedia/base46) plugin. DMS writes
  `colors/dms.lua` and the lualine theme, and Neovim hot-reloads them when the
  wallpaper or theme changes. Catppuccin Mocha is only an offline fallback.
- LSPs, formatters, and linters install on demand through Mason (`:Mason`).
  Treesitter parsers use the system `tree-sitter` CLI.
- `<leader>w` saves, `<leader>W` saves all, `<leader>qq` quits everything.
- Config only is tracked; plugins and Mason packages live in
  `~/.local/share/nvim`. After pulling, run
  `nvim --headless "+Lazy! sync" +qa` if plugins are missing.

### Apps & web apps

- **Spotify** through `spotify-launcher` (official client, updates itself).
- **Discord** with **Equicord** patched in by Equilotl. The original
  `app.asar` is kept as `_app.asar`; re-run the installer after Discord
  updates. DMS also generates a Discord CSS theme, linked into Equicord as
  `dank-discord.css` (enable it under Equicord → Themes).
- **Any website** can run in a Brave app window with no tabs or address bar:
  `webapp.sh <url> [name]`. It creates a menu entry and a dedicated profile at
  `~/.local/share/webapps/<slug>`, then launches the app.
  ```bash
  webapp.sh https://web.whatsapp.com WhatsApp
  webapp.sh --install https://web.telegram.org Telegram
  webapp.sh --list
  webapp.sh --remove Telegram --purge
  ```
  WhatsApp is already installed this way. Set `WEBAPP_BROWSER` to use another
  Chromium browser. The script writes a matching `StartupWMClass` (Chromium's
  Wayland app ID) so niri associates the window with its launcher.
- **Theme sync:** DMS generates matugen colours from the current wallpaper for
  every detected template (Neovim, kitty, GTK, Discord CSS, niri). Run
  `dms-theme-refresh.sh` to force a full regeneration after installing a new
  themed app.

### Terminal

- ZedMono Nerd Font, 12.5, 105% line height, 96% opacity + blur.
- Colour and tab files are generated by DMS and included automatically.
- Powerline tabs, 20k scrollback, `Ctrl+Shift+C/V`, `Ctrl+Shift+T/N`,
  `Ctrl+Shift+F` for scrollback search.

### Desktop font & icons

- **ZedMono Nerd Font** is the UI + monospace font (`gsettings` + fontconfig).
- **Numix-Square** is the GTK icon theme, applied through `gsettings` and
  `gtk-3.0/gtk-4.0 settings.ini`.
- `install.sh` re-applies both on every install.

### Git

- Identity: `SpreadSheets600 <dev.spreadsheets600@gmail.com>`.
- `gh` credential helper, delta diffs, rebase pulls, useful aliases.
- See [SYSTEM.md §8](SYSTEM.md#8-git-github-cli-and-identity).

## Windows

Copy the files from `windows/` to their target paths (table in
[SYSTEM.md §10](SYSTEM.md#10-windows--shared-files)):

- `terminal/settings.json` → Windows Terminal
- `komorebi/` → `%USERPROFILE%\.config\komorebi`
- `yasb/` → `%USERPROFILE%\.config\yasb`
- `windhawk/` → paste mod settings in the Windhawk UI
- `rainmeter/squareplayer.rmskin` → import into Rainmeter
- `wsl/wsl.conf` → `/etc/wsl.conf`; `wsl/wsl.config` → `%USERPROFILE%\.wslconfig`
- `scripts/system-cleanup.ps1` → run as Administrator

## Shared

| App | File |
|---|---|
| VS Code | `shared/vscode/settings.json` |
| Zed | `shared/zed/settings.json` + `shared/zed/themes/` |
| Discord | `shared/discord/*.css` (BetterDiscord) |

## Updating

```bash
cd ~/Dotfiles
git add -A
git commit -m "feat: describe the change"
git push
```

Because the Linux configs are symlinked, edits made through the app or through
`~/.config` show up in the repo immediately.

## Fonts & icons

- [ZedMono Nerd Font](https://github.com/zed-industries/zed-fonts)
- [Iosevka Nerd Font](https://github.com/be5invis/Iosevka)
- [JetBrains Mono Nerd Font](https://www.jetbrains.com/lp/mono/)
- `ttf-nerd-fonts-symbols-mono` for fallback glyphs
- [Numix-Square](https://github.com/numixproject/numix-icon-theme-square) icon theme
