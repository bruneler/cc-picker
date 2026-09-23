# Changelog

All notable changes to cc-picker are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [0.2.0] – 2026-09-23

First public release.

### Added
- GUI mode (dialog window) and shell mode (numbered terminal menu)
- Create new projects from the picker, optionally via `git clone`
- Auto-detection of the `claude` binary, terminal emulator, login shell and
  dialog tool
- GUI support for `zenity`, `kdialog` and `yad` (override: `CC_PICKER_DIALOG`)
- English and German UI, chosen from `$LANG` (override: `CC_PICKER_LANG`)
- Config file `~/.config/cc-picker/config`, which also applies when
  launching from the app menu; environment variables take precedence
- Recently used projects are listed first, with a "last used" column
  (stored locally in `~/.local/state/cc-picker/recent`)
- Progress indicator while cloning in GUI mode; errors show git's reason
- Clear button labels ("Start"/"Cancel") and the app icon on yad/kdialog
  windows
- `CC_PICKER_MODE`: `gui` (default), `shell` or `ask`
- `--help` and `--version`
- `install.sh`: installs script, app menu entry and icon; adds `~/.local/bin`
  to `PATH` for bash, zsh, fish or `~/.profile` if needed
  (skip: `CC_PICKER_NO_PATH=1`)
- `install.sh`: dependency check; offers to install a dialog tool with the
  exact package manager command, only after confirmation
  (skip: `CC_PICKER_NO_DEPS=1`)
- App icon, README in English and German with illustrations
- CI: syntax check, ShellCheck and smoke test on every push

### Changed
- Default projects folder is now `~/claude-projects`
- `cc-picker` opens the project list directly instead of asking
  "GUI or Shell?" first
- Without a dialog tool, launching from the app menu opens the terminal
  menu instead of doing nothing
- Hidden folders are no longer listed as projects
- Docs: state clearly that the start folder is not a security boundary

### Fixed
- `CC_PICKER_BIN` is honored even when `claude` isn't found on `PATH`
- Project names are validated: no `/`, no leading `.` or `-`, so new
  projects can't end up outside the projects folder
- Paths containing quotes or spaces work with all supported terminals
  (xfce4-terminal previously broke on `'`)
- A failed `git clone` shows an error and leaves no empty folder behind
- Quitting the shell menu with Ctrl+D exits cleanly (exit code 0)
- Cancelling the Git question no longer creates a project; an empty field
  still means "empty folder"
- Project names with tabs, line breaks or other control characters, or with
  leading/trailing spaces, are rejected; existing folders with control
  characters are left out of the list instead of breaking it

## 0.1 – internal

Initial version, not released.

[0.2.0]: https://github.com/bruneler/cc-picker/releases/tag/v0.2.0
