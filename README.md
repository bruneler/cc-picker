<p align="center">
  <b>English</b> | <a href="README.de.md">Deutsch</a>
</p>

<p align="center">
  <img src="docs/banner.svg" alt="cc-picker – pick a project, Claude Code starts right there" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-4f8cff" alt="License: MIT">
  <img src="https://img.shields.io/badge/Bash-%E2%89%A5%204-5fe0a0?logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/platform-Linux-8b93a6?logo=linux&logoColor=white" alt="Linux">
</p>

**cc-picker** is a small project launcher for
[Claude Code](https://claude.com/product/claude-code): pick a project folder
from a list (or create a new one), and Claude Code starts **right there** –
instead of in your home directory or mixed up with other AI coding tools.

> **Note:** cc-picker is an independent community project and is **not
> affiliated with or endorsed by Anthropic**. "Claude" is a trademark of
> Anthropic, PBC. This tool simply launches the official `claude`
> command-line tool in a folder of your choice.

## How it works

<p align="center">
  <img src="docs/flow.svg" alt="Flow: 1. launch cc-picker, 2. choose GUI or shell mode, 3. pick or create a project, 4. a terminal opens in the project folder and starts claude" width="100%">
</p>

## Two modes

<table>
  <tr>
    <th width="50%">🖱️ GUI mode</th>
    <th width="50%">⌨️ Shell mode</th>
  </tr>
  <tr>
    <td><img src="docs/gui-mode.svg" alt="GUI mode: zenity window with project list"></td>
    <td><img src="docs/shell-mode.svg" alt="Shell mode: numbered project menu in the terminal"></td>
  </tr>
  <tr>
    <td>A picker window via <code>zenity</code>, <code>kdialog</code> or <code>yad</code> –
    whichever your desktop has. Claude Code starts in a new
    terminal window inside the chosen folder.</td>
    <td>A numbered menu right in your terminal – great over SSH or without a
    desktop. Used automatically when no dialog tool is installed.</td>
  </tr>
</table>

## Why?

If you use several AI coding tools side by side (e.g. Claude Code and
another tool on the same machine), you usually want:

- 📂 **separate working copies per tool** instead of shared folders
- ⚡ **quick switching between projects** without memorizing paths
- 🔒 **no accidental Claude Code sessions in your entire home directory**
  (needlessly broad file and execution access)

cc-picker solves this with a simple picker: choose a folder (or create one,
optionally via `git clone`) → Claude Code starts right there.

## Features

| | |
|---|---|
| 🪟 **GUI or shell** | choose at startup; GUI works with `zenity` (GNOME & most desktops), `kdialog` (KDE) or `yad` |
| ➕ **New project** | create one straight from the picker, optionally by cloning a Git remote |
| 🔍 **Auto-detection** | `claude` binary (PATH, then common install locations), terminal emulator (gnome-terminal, konsole, xfce4-terminal, alacritty, kitty, xterm) and your login shell (bash, zsh, fish, …) |
| 🌐 **English & German** | UI language follows your system locale (`$LANG`) |
| ⚙️ **No hard-coded paths** | everything configurable via a config file or environment variables |
| 🧩 **Desktop integration** | its own icon in your application menu |

## Installation

```bash
git clone https://github.com/bruneler/cc-picker.git
cd cc-picker
./install.sh
```

<img src="cc-picker.svg" alt="cc-picker app icon" width="72" align="right">

The installer sets up:

| File | Purpose |
|---|---|
| `~/.local/bin/cc-picker` | the executable script |
| `~/.local/share/applications/cc-picker.desktop` | application menu entry |
| `~/.local/share/icons/cc-picker.svg` | app icon |

**PATH is set up automatically:** if `~/.local/bin` isn't in your `PATH`
yet, `install.sh` detects your login shell and adds the matching line –
only once, even if you install repeatedly:

| Shell | File | Entry |
|---|---|---|
| bash | `~/.bashrc` | `export PATH="$HOME/.local/bin:$PATH"` |
| zsh | `~/.zshrc` | `export PATH="$HOME/.local/bin:$PATH"` |
| fish | `~/.config/fish/config.fish` | `fish_add_path "$HOME/.local/bin"` |
| other | `~/.profile` | `export PATH="$HOME/.local/bin:$PATH"` |

Prefer to do it yourself? Run `CC_PICKER_NO_PATH=1 ./install.sh` – the line
is then only printed, not written.

**Dependencies are checked too** – see [Dependencies](#dependencies).

## Usage

```bash
cc-picker                # choose a mode (GUI or shell)
cc-picker --shell-mode   # go straight to the terminal menu
cc-picker --help         # usage, projects folder and config file
cc-picker --version      # show the version
```

Or search for **cc-picker** in your application menu.

1. Choose a mode: **GUI** or **Shell**
2. Pick a project from the list – or **"+ Create new project"**
   (enter a name, optionally a Git remote URL to clone)
3. A terminal opens in the chosen folder and starts `claude`.
   When you quit Claude Code, the shell stays open in the project folder.

## Configuration

By default, projects live in `~/claude-projects`. To change this or any
other setting, create `~/.config/cc-picker/config`:

```ini
# ~/.config/cc-picker/config
CC_PICKER_BASE=~/code/ai-projects
CC_PICKER_LANG=en
```

The config file also applies when you launch cc-picker from the app menu.
Environment variables with the same names take precedence over it.
The file is only read, never executed, and only the keys below are used:

| Variable             | Default                        | Meaning                                          |
|----------------------|--------------------------------|--------------------------------------------------|
| `CC_PICKER_BASE`     | `~/claude-projects`            | folder where projects are listed and created     |
| `CC_PICKER_BIN`      | auto-detected                  | path to the `claude` binary                      |
| `CC_PICKER_TERMINAL` | auto-detected                  | terminal emulator to use                         |
| `CC_PICKER_SHELL`    | auto-detected (`/etc/passwd`)  | shell that keeps running after Claude Code exits |
| `CC_PICKER_LANG`     | from `$LANG`                   | UI language: `de…` = German, otherwise English   |
| `CC_PICKER_DIALOG`   | auto-detected                  | dialog tool: `zenity`, `kdialog` or `yad`        |

One-off example via environment variables:

```bash
CC_PICKER_BASE=~/projects CC_PICKER_BIN=/opt/claude/bin/claude cc-picker
```

## Dependencies

| What | Needed for | Notes |
|---|---|---|
| `bash` | everything | preinstalled on virtually every Linux system |
| [`claude`](https://claude.com/product/claude-code) | everything | the Claude Code CLI |
| a dialog tool | GUI mode & app-menu launch | any one of `zenity`, `kdialog`, `yad` – most desktops ship one |
| a terminal emulator | GUI mode | gnome-terminal, konsole, xfce4-terminal, alacritty, kitty or xterm |
| `git` | optional | only for cloning when creating a new project |

**`install.sh` checks all of this for you.** If no dialog tool is found, it
offers to install one (`kdialog` on KDE, `zenity` elsewhere) and shows the
exact command before running anything:

```text
Install zenity now? This will run:
  sudo pacman -S --needed zenity
Install? [Y/n]
```

Nothing is installed without your confirmation, and `sudo` asks for your
password itself – the installer never runs as root. To skip the check, use
`CC_PICKER_NO_DEPS=1 ./install.sh`.

Installing a dialog tool manually:

| Distribution | Command |
|---|---|
| Arch / Manjaro | `sudo pacman -S zenity` |
| Debian / Ubuntu / Mint | `sudo apt install zenity` |
| Fedora | `sudo dnf install zenity` |
| openSUSE | `sudo zypper install zenity` |

On KDE, replace `zenity` with `kdialog`.

> Without a dialog tool, cc-picker still works from a terminal
> (`cc-picker --shell-mode`), but launching it from the app menu won't show
> anything.

## Uninstall

```bash
rm ~/.local/bin/cc-picker \
   ~/.local/share/applications/cc-picker.desktop \
   ~/.local/share/icons/cc-picker.svg
```

Your project folders are left untouched. If `install.sh` added a PATH entry
(marked `# added by cc-picker install.sh`), you can remove it from your shell
config if you like.

## Contributing

Issues and pull requests are welcome – see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
