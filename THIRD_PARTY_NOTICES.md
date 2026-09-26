# Third-party notices

The MIT license in [LICENSE](LICENSE) applies to cc-picker's original code and
original documentation. It does not relicense third-party software, fonts,
trademarks, or interfaces shown in screenshots and recordings.

## Bundled website fonts

The files in `website/assets/fonts/` include:

| Font | Copyright notice | License |
|---|---|---|
| Bricolage Grotesque | Copyright 2022 The Bricolage Grotesque Project Authors | SIL Open Font License 1.1 |
| Atkinson Hyperlegible | Copyright 2020 Braille Institute of America, Inc. | SIL Open Font License 1.1 |
| IBM Plex Mono | Copyright © 2017 IBM Corp.; Reserved Font Name: Plex | SIL Open Font License 1.1 |

The full notices and license texts are in
[website/assets/fonts/OFL.txt](website/assets/fonts/OFL.txt). Keep that file with
redistributed font files. These fonts retain their OFL license, including its
conditions for modifications and reserved names; they are not MIT-licensed.
The launcher installer does not install the website fonts.

## Matomo on the project website

`website/analytics.js` is cc-picker's consent integration. After consent, it
loads a separate Matomo JavaScript tracker from `analytics.brue.nu/matomo.js`.
That tracker is not bundled in this repository or installed by `install.sh`.
The deployed tracker inspected on 2026-09-26 identifies itself as BSD-3-Clause
in its license header and refers to Matomo's `js/LICENSE.txt`. Matomo components
retain their own licenses; cc-picker's MIT license does not cover them.
Preserve the applicable upstream notices when redistributing a tracker.

Upstream: https://github.com/matomo-org/matomo/blob/master/js/piwik.js

## External programs

cc-picker invokes separately installed programs such as Bash, Git, zenity,
kdialog, yad, terminal emulators, fzf and Claude Code. Those programs are not
bundled or relicensed by this project. Package installation uses the user's
configured distribution package sources. Their respective licenses and terms
continue to apply.

## Screenshots, recordings and trademarks

The demo and screenshots illustrate actual or documented program interfaces.
Third-party interface elements, names and marks shown in them remain subject
to their owners' rights; the project's MIT license grants no additional rights
to those elements or marks.

Claude and Claude Code are Anthropic product names. cc-picker is an independent
community project, not affiliated with or endorsed by Anthropic. Claude Code
is not included in cc-picker and is subject to its own terms.

## Installed license

The installer copies the complete MIT license to
`~/.local/share/cc-picker/LICENSE`. When redistributing cc-picker or substantial
portions of it, retain the copyright and permission notice as required by that
license. Repository distributions should also retain these third-party notices
and the font licenses when the corresponding assets are included.
