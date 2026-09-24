# Changelog

## Unreleased

### Changed
- Add a first-project welcome and an AI-assistance note to both READMEs
- Explain website consent storage and cookie durations in plain language in German and English

## [0.3.1] – 2026-09-24

### Added
- Security policy with a private reporting contact and supported versions
- Security regression tests for shell metacharacters and path handling
- Consent-based, self-hosted Matomo website statistics with a bilingual privacy
  notice, withdrawal controls and DNT/GPC support
- Automatic website deployment after successful main-branch checks

### Changed
- Clarify runtime dependencies on the website and in both READMEs
- Document Linux distribution compatibility and the limits of test coverage
- Distinguish the telemetry-free launcher from optional website analytics in
  both READMEs, the security policy and the website; document update connections

### Fixed
- `--update` no longer prints Git's "detached HEAD" advice
- Keep mobile language/detail controls on one row and clarify consent button feedback

## [0.3.0] – 2026-09-24

### Added
- Continue where you left off: for projects with earlier Claude Code
  sessions, choose a new session, `claude --continue` or `claude --resume`
  (`CC_PICKER_SESSION`, `-n`/`-c`/`-r`)
- Start from the command line without a list: `cc-picker NAME` (a unique
  beginning is enough) and `cc-picker -` for the most recent project
- Search: type text in the terminal menu to filter it, `fzf` is used when
  installed (`CC_PICKER_FZF`); the window gets a search entry from 8 projects
- Git branch and number of changed files next to each project
  (`CC_PICKER_GIT_STATUS`)
- Pin favourite projects so they're always listed first
- Several projects folders in `CC_PICKER_BASE`, separated by `:`
- Project templates in `~/.config/cc-picker/templates/` with
  `{{PROJECT_NAME}}` placeholders and `git init`; `install.sh` sets up a
  `standard` template with `CLAUDE.md` and `.gitignore`
- GitHub shorthand `user/repo` when cloning
- "Manage projects": open in file manager or editor (`CC_PICKER_EDITOR`),
  pin, rename, archive and restore
- `cc-picker --update` installs the newest release
- Functional tests for all of the above, including the window mode with a
  fake dialog tool

### Changed
- The recent list stores full paths; entries from 0.2 are still read
- Creating a project with an existing name is refused instead of reusing
  the folder
- The terminal menu lists one project per line and stays open after
  managing a project or cancelling a new one

### Fixed
- Quote desktop launcher paths correctly, including spaces and special characters.
- Separate Git options from clone URLs.
- Website: no horizontal scrolling on phones.

### Other
- Add isolated functional tests to CI.
- Version the website with local fonts and cc-picker.brue.nu metadata.

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

[0.3.1]: https://github.com/bruneler/cc-picker/releases/tag/v0.3.1
[0.3.0]: https://github.com/bruneler/cc-picker/releases/tag/v0.3.0
[0.2.0]: https://github.com/bruneler/cc-picker/releases/tag/v0.2.0
