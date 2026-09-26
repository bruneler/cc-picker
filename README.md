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

Step-by-step instructions are available in the [user guide](https://cc-picker.brue.nu/manual.en.html).

## See it in action

![Real recording: select my-app in cc-picker; a terminal opens and Claude Code starts in that project.](website/assets/demo/cc-picker-demo.gif)

Pick a project → Claude Code starts right there.
[Watch the video with playback controls](https://cc-picker.brue.nu/#demo).

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
    desktop. Start it with <code>cc-picker --shell-mode</code>; also used
    automatically when no dialog tool is installed.</td>
  </tr>
</table>

## Why?

If you use several AI coding tools side by side (e.g. Claude Code and
another tool on the same machine), you usually want:

- 📂 **separate working copies per tool** instead of shared folders
- ⚡ **quick switching between projects** without memorizing paths
- 🏠 **no accidental Claude Code sessions with your whole home directory**
  as the working folder

cc-picker solves this with a simple picker: choose a folder (or create one,
optionally via `git clone`) → Claude Code starts right there.

> **Not a sandbox:** the start folder is Claude Code's working folder, not a
> security boundary. Depending on its permissions, Claude Code can still read,
> change or run things outside of it. What it may do is controlled by Claude
> Code's own permission settings – cc-picker doesn't change them.

## Features

| | |
|---|---|
| 🪟 **GUI or shell** | window by default, terminal menu via `--shell-mode`; GUI works with `zenity` (GNOME & most desktops), `kdialog` (KDE) or `yad` |
| 🕘 **Recent first** | recently used projects are listed at the top, with "last used" times; pinned favourites stay above them |
| ↩️ **Continue where you left off** | start a new Claude Code session, continue the last one or pick an earlier one |
| 🔎 **Search** | type part of a name to filter the list; uses `fzf` in the terminal menu if it's installed |
| ⚡ **Straight from the command line** | `cc-picker my-app` or `cc-picker -` (last project) – no list at all |
| 🌿 **Git status at a glance** | branch and number of changed files next to each project |
| ➕ **New project** | create one straight from the picker: from a template (with `git init` and a prepared `CLAUDE.md`), or by cloning a Git remote – `user/repo` is enough for GitHub |
| 🗂️ **Manage projects** | open in file manager or editor, pin, rename, archive and restore |
| 📁 **Several projects folders** | e.g. `~/claude-projects` and `~/code` in one list |
| ⬆️ **Self-update** | `cc-picker --update` installs the newest version |
| 🔍 **Auto-detection** | `claude` binary (PATH, then common install locations), terminal emulator (gnome-terminal, konsole, xfce4-terminal, alacritty, kitty, xterm) and your login shell (bash, zsh, fish, …) |
| 🌐 **English & German** | UI language follows your system locale (`$LANG`) |
| ⚙️ **No hard-coded paths** | everything configurable via a config file or environment variables |
| 🧩 **Desktop integration** | its own icon in your application menu |

## Linux distributions

- **Arch Linux:** fully tested by the maintainer on their own system.
- **Debian:** confirmed working by the maintainer.
- **Ubuntu:** automated checks and functional tests run on GitHub Actions
  (`ubuntu-latest`), using isolated test environments without real Claude sessions.
  This is not a full desktop end-to-end test.
- **Linux Mint, Manjaro, Fedora and openSUSE:** expected to work with the
  dependencies below, but not yet verified by dedicated distribution tests.
  The installer recognises `apt-get`, `pacman`, `dnf` and `zypper`.

Requires Bash 4 or newer, GNU/Linux tools and a working Claude Code installation.
The graphical picker additionally needs `zenity`, `kdialog` or `yad` and a
supported terminal emulator. No particular desktop environment is required for
terminal mode. Distribution versions have not yet been recorded in a test matrix.

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
| `~/.local/share/cc-picker/LICENSE` | MIT license and copyright notice |
| `~/.config/cc-picker/templates/` | project templates – installed once, your changes are kept |

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

**Missing window support?** During installation, cc-picker checks for a
dialog tool. If none is available, the installer offers to install `kdialog`
on KDE or `zenity` elsewhere. It shows the exact command first and runs it
only with your approval. If you decline, the terminal menu remains available.
Normal launches do not ask again.

See [Dependencies](#dependencies) for details.

## Usage

```bash
cc-picker                # project list (window)
cc-picker --shell-mode   # terminal menu
cc-picker my-app         # start right in project "my-app" (a unique beginning is enough)
cc-picker -              # start in the most recently used project
cc-picker -c my-app      # … and continue the last session there
cc-picker --update       # update to the newest version
cc-picker --help         # usage, projects folder and config file
cc-picker --version      # show the version
```

Or search for **cc-picker** in your application menu.

1. Pick a project – pinned (★) and recently used ones are at the top – or
   **"+ Create new project"** (see below)
2. If Claude Code has been used in that project before, you choose:
   **new session**, **continue last session** (`claude --continue`) or
   **choose an earlier session** (`claude --resume`). Set
   `CC_PICKER_SESSION` to skip the question, or pass `-n`, `-c` or `-r`.
3. A terminal opens in the chosen folder and starts `claude`.
   When you quit Claude Code, the shell stays open in the project folder.

**Searching:** in the terminal menu, type part of a name instead of a number
to filter the list (an empty line shows everything again). If
[`fzf`](https://github.com/junegunn/fzf) is installed, the menu uses it
instead (`CC_PICKER_FZF=0` turns that off). In the window, a **Search …**
entry appears once you have 8 or more projects.

**Git status:** for Git repositories, the list shows the branch and the
number of changed files, e.g. `main · 3 changed`. `CC_PICKER_GIT_STATUS=0`
turns this off (for very large repositories).

### New projects

Enter a name, then either

- a Git URL to clone – for GitHub, `user/repo` is enough – or
- nothing, and pick a **template** or an **empty folder**.

Templates are folders in `~/.config/cc-picker/templates/`. Their contents are
copied into the new project, `{{PROJECT_NAME}}` in text files is replaced
with the project's name, and `git init` is run. `install.sh` sets up a
`standard` template with a `CLAUDE.md` and a `.gitignore`; edit it or add
your own. Without any templates, the question is skipped.

### Managing projects

**⚙ Manage projects …** in the list lets you, for one project:

- open it in the file manager or in your editor (`CC_PICKER_EDITOR`, or
  the first of `code`, `codium`, `zed`, `subl` that's installed)
- pin it, so it's always listed first (★)
- rename it
- archive it: the folder is moved to `.archive/` inside the projects folder
  – nothing is deleted – and can be restored from the same menu

Claude Code keeps its session history per folder path, so after renaming, the
old sessions can't be continued from the new name.

### Updating

`cc-picker --update` fetches the newest release from GitHub and runs its
`install.sh`, if it's newer than the installed version. Your settings,
templates and project list are kept.

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
| `CC_PICKER_BASE`     | `~/claude-projects`            | projects folder; several separated by `:` (e.g. `~/claude-projects:~/code`) – new projects go into the first |
| `CC_PICKER_BIN`      | auto-detected                  | path to the `claude` binary                      |
| `CC_PICKER_TERMINAL` | auto-detected                  | terminal emulator to use                         |
| `CC_PICKER_SHELL`    | auto-detected (`/etc/passwd`)  | shell that keeps running after Claude Code exits |
| `CC_PICKER_LANG`     | from `$LANG`                   | UI language: `de…` = German, otherwise English   |
| `CC_PICKER_DIALOG`   | auto-detected                  | dialog tool: `zenity`, `kdialog` or `yad`        |
| `CC_PICKER_MODE`     | `gui`                          | what `cc-picker` opens: `gui` (project list), `shell` (terminal menu) or `ask` |
| `CC_PICKER_SESSION`  | `ask`                          | for projects with earlier sessions: `ask`, `new`, `continue` or `resume` |
| `CC_PICKER_GIT_STATUS` | `1`                          | `0` hides branch and changes in the list         |
| `CC_PICKER_EDITOR`   | auto-detected                  | graphical editor for "Open in editor", e.g. `code -n` |
| `CC_PICKER_FZF`      | `1`                            | `0` uses the numbered terminal menu even if `fzf` is installed |
| `CC_PICKER_UPDATE_REPO` | this repository             | Git repository used by `--update` (for forks)    |

One-off example via environment variables:

```bash
CC_PICKER_BASE=~/projects CC_PICKER_BIN=/opt/claude/bin/claude cc-picker
```

## Dependencies

One Bash script. No framework, runtime service or background daemon. Uses standard Linux tools and your existing Claude Code installation.

Standard tools include GNU coreutils, `find`, `sort`, `sed`, `grep` and `awk`.

| What | Needed for | Notes |
|---|---|---|
| `bash` | everything | preinstalled on virtually every Linux system |
| [`claude`](https://claude.com/product/claude-code) | everything | the Claude Code CLI |
| a dialog tool | GUI mode & app-menu launch | any one of `zenity`, `kdialog`, `yad` – most desktops ship one |
| a terminal emulator | GUI mode | gnome-terminal, konsole, xfce4-terminal, alacritty, kitty or xterm |
| `git` | optional | cloning, `git init` for templates, Git status in the list, `--update` |
| `fzf` | optional | searchable terminal menu |
| `xdg-open` | optional | "Open in file manager" (part of `xdg-utils`, usually preinstalled) |

**`install.sh` checks the main dependencies.** If no dialog tool is found, it
offers to install one (`kdialog` on KDE, `zenity` elsewhere) and shows the
exact command before running anything:

```text
Install zenity now? This will run:
  sudo pacman -S --needed zenity
Install? [Y/n]
```

Nothing is installed without your confirmation, and `sudo` asks for your
password itself – the installer never runs as root. To skip automatic dependency installation, use
`CC_PICKER_NO_DEPS=1 ./install.sh`. Without an interactive terminal, the installer
also skips the prompt and prints the installation command instead. If no
supported package manager is found, it provides manual installation guidance.

Installing a dialog tool manually:

| Distribution | Command |
|---|---|
| Arch / Manjaro | `sudo pacman -S zenity` |
| Debian / Ubuntu / Mint | `sudo apt install zenity` |
| Fedora | `sudo dnf install zenity` |
| openSUSE | `sudo zypper install zenity` |

On KDE, replace `zenity` with `kdialog`.

> Without a dialog tool, cc-picker falls back to the terminal menu – also
> when launched from the app menu, as long as a terminal emulator is
> installed.

## Uninstall

```bash
rm ~/.local/bin/cc-picker \
   ~/.local/share/applications/cc-picker.desktop \
   ~/.local/share/icons/cc-picker.svg \
   ~/.local/share/cc-picker/LICENSE
```

Your project folders are left untouched. If `install.sh` added a PATH entry
(marked `# added by cc-picker install.sh`), you can remove it from your shell
config if you like.

Settings, templates, the list of recently used projects and the pinned
projects live in small local files; the launcher does not send these files
to the project maintainer or Matomo. To remove
them as well:

```bash
rm -r ~/.config/cc-picker ~/.local/state/cc-picker
```

## Privacy

The **installed cc-picker launcher has no telemetry**. Settings, project
history and templates stay on your computer. Optional Git cloning connects
to the chosen remote; `cc-picker --update` connects to GitHub (or your configured
update repository), and installing missing packages contacts your package
sources. Claude Code and programs you open have their own network behaviour
and privacy policies.

The **project website** at [cc-picker.brue.nu](https://cc-picker.brue.nu/)
uses self-hosted Matomo **only after your consent**, separately from the launcher.
The current notice discloses full IP addresses, analytics cookies and no
enforced automatic deletion period. You can decline or withdraw consent in
[Privacy settings](https://cc-picker.brue.nu/#privacy-settings); DNT and GPC
are respected. See the [privacy notice](https://cc-picker.brue.nu/privacy.html)
for data categories, storage, hosting and contact details.

## Contributing

This is my first public open-source project, and I am still learning along
the way. If you spot a mistake or have a suggestion, I welcome a friendly
message or an issue. Thank you for your patience and for helping out!

Please report security vulnerabilities privately using the reporting channel
described in [SECURITY.md](SECURITY.md).

Issues and pull requests are welcome – see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

The MIT license covers cc-picker’s original code and documentation. Bundled
fonts and other third-party components retain their own licenses; see
[Third-party notices](THIRD_PARTY_NOTICES.md). The installer also saves the
MIT license to `~/.local/share/cc-picker/LICENSE`.

[MIT](LICENSE)

cc-picker is provided without warranty. The warranty and liability provisions
of the MIT License apply to the extent permitted by law. Back up important
data regularly and review the permissions you grant to Claude Code.

---

ChatGPT and Claude Code assisted in the development of cc-picker. I maintain
the project and make the decisions about changes and releases.
