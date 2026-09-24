# Contributing to cc-picker

Thanks for your interest! A few quick notes:

## Reporting bugs / suggesting features

Please open an [issue](../../issues) and include:
- the output of `cc-picker --version`
- your distro, shell and terminal emulator
- the output of `bash --version` and of your dialog tool's version
  (`zenity --version`, `kdialog --version` or `yad --version`)
- steps to reproduce

Issues in English or German are both fine.

## Pull requests

1. Fork the repo and branch off `main`
2. Keep changes as small and focused as possible
3. Run `bash -n cc-picker.sh install.sh` and
   [ShellCheck](https://www.shellcheck.net/) (`shellcheck cc-picker.sh install.sh`),
   then test manually. CI runs the same checks on every push.
4. Don't introduce hard-coded paths or user names – anything system- or
   user-specific belongs in a `CC_PICKER_*` setting (config file and
   environment variable) with a sensible automatic fallback
5. Add a line to the topmost, unreleased section of [CHANGELOG.md](CHANGELOG.md)

## Translations

User-facing text lives in the `T_*` variables at the top of `cc-picker.sh`
and `install.sh`, in English and German. When you add or change a message,
update both languages.

The README exists in two versions (`README.md` in English, `README.de.md` in
German), each with its own illustrations in `docs/` (`*.svg` and `*.de.svg`).
Please keep both in sync; if you only speak one of the languages, say so in
the PR and someone can help with the other.

## Style

- Plain Bash; avoid Bashisms that aren't needed
- Code comments and commit messages in English

## Code of conduct

Be kind and respectful. That's it.

## Functional checks

Run `/usr/bin/python3 -m unittest discover -s tests -v` on Linux with
`python3-gi` and `desktop-file-utils` installed (Arch: `python-gobject`,
`desktop-file-utils`). Tests use temporary homes and fake Claude executables;
they do not change your installation or start real Claude sessions. CI runs
them on every push and pull request.

The published static website is in `website/`. It needs no build step. Keep
fonts and their license together, and exclude design drafts and source-only
preview generators. Production hosting is maintained in the infrastructure repo.

## Website deployment

Successful main CI runs publish `website/` to https://cc-picker.brue.nu/.
The dependent deployment job uses a dedicated restricted SSH key; no admin VPS
access. Pull requests and tags never deploy. The public `release-info.json`
identifies the live source commit. Use the `lint` workflow's manual main run to
retry; obsolete runs are skipped. Changes to deployment access and recovery are
maintained in bruneler/bruenus-infrastructure (ADR 0015).
