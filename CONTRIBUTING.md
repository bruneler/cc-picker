# Contributing to cc-picker

Thanks for your interest! A few quick notes:

## Reporting bugs / suggesting features

Please open an [issue](../../issues) and include:
- your distro, shell and terminal emulator
- the output of `bash --version` and `zenity --version` (if installed)
- steps to reproduce

Issues in English or German are both fine.

## Pull requests

1. Fork the repo and branch off `main`
2. Keep changes as small and focused as possible
3. Check the scripts for syntax errors with `bash -n cc-picker.sh install.sh`
   and test manually
4. Don't introduce hard-coded paths or user names – anything system- or
   user-specific belongs in a `CC_PICKER_*` environment variable with a
   sensible automatic fallback

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
