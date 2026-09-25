# Launch preparation

Status: preparation only. The real recording, visual review and public launch
are still pending. Do not describe the existing SVG illustrations or the
website's interactive folder demo as a recording of the application.

## Baseline checked on 2026-09-25

- `main`: `cf72cab31f2a2674466f63c87952517211ba6974`.
- The [live website](https://cc-picker.brue.nu/) matched `website/index.html`;
  its `release-info.json` reported the same commit.
- Both READMEs introduce the tool before “How it works” / “So funktioniert's”.
  This is the best place for a short recording, before the flow illustrations.
- The website hero contains an interactive illustration explicitly labelled
  “demo – nothing is launched”. Real picker screenshots appear further down.
  Put the recording immediately after the hero, before `#why`, so visitors
  see the actual picker-to-terminal transition early.
- PR #20 (`refactor/ui-dispatch`) was open. This preparation changes no runtime
  code and does not depend on that refactor.

Core message: **Pick a project → Claude Code starts right there.**
Keep the launcher focused; this launch needs no extra languages, provider or
model management, telemetry, or paid advertising.

## Record the real application

Use an English UI and a neutral desktop. Record a single continuous take of
about 12–15 seconds. Keep a local original recording; export GIF and MP4 from
that same take. Do not recreate Claude's interface or substitute a fake binary.

1. Prepare neutral projects and isolate the picker's configuration/history
   using the command below. Run from the repository root. It does not install
   the launcher or change existing picker settings. Save the printed temporary
   directory until the recording is finished.

   ```bash
   demo_root=$(mktemp -d /tmp/cc-picker-demo.XXXXXX)
   mkdir -p "$demo_root/projects/"{my-app,website,notes-app}
   mkdir -p "$demo_root/config" "$demo_root/state"
   printf 'Demo directory: %s\n' "$demo_root"
   XDG_CONFIG_HOME="$demo_root/config" \
   XDG_STATE_HOME="$demo_root/state" \
   CC_PICKER_BASE="$demo_root/projects" \
   CC_PICKER_LANG=en CC_PICKER_MODE=gui CC_PICKER_SESSION=new \
   bash ./cc-picker.sh
   ```

   This isolates **cc-picker**, not Claude Code. Claude still uses its existing
   account, settings and startup hooks. Check these locally before recording;
   do not copy credentials into the repository or publish diagnostic output.
   Do not override `HOME`, disable trust checks or bypass permissions.

2. Rehearse once: choose `my-app`, complete normal Claude login/trust setup
   outside the recording if needed, and confirm the actual working directory
   is the temporary `projects/my-app` directory. Exit the rehearsal session.
   Reuse the same directory and launch command for the take.
3. Frame a neutral capture region containing both the picker and destination
   terminal. Hide notifications, unrelated windows, terminal tabs, account
   details and personal paths. Check terminal title bars as well as content.
   Prefer 1280×720 if both windows remain readable; do not crop away evidence
   of the chosen folder.
4. Record with the desktop's actual screen recorder:

   | Time | Action |
   |---|---|
   | 0–2 s | Launch cc-picker; the real GUI appears. |
   | 2–5 s | Select `my-app`, briefly pause, then activate Start. |
   | 5–10 s | The terminal opens and the real Claude Code UI loads. |
   | 10–15 s | Hold the result with `my-app` visible as the working folder. |

   Do not submit a prompt; startup is sufficient. If startup takes longer,
   retake or keep a longer honest clip rather than speeding up the result.
5. Watch the complete original before export. Reject any take containing
   private project names, personal paths, account identifiers, tokens or
   unrelated notifications. Retaking is preferable to covering the result.

## Export and review

These commands expect an already framed, reviewed recording named `demo-source.mkv`
in the current directory. Adapt the input filename if the recorder produces
another format. `-n` avoids overwriting an existing export. Choose a different
output name when iterating. Keep raw recordings outside Git.

```bash
# GIF for GitHub; preserve aspect ratio and use a palette for readable text.
ffmpeg -n -i demo-source.mkv -an -map_metadata -1 \
  -filter_complex '[0:v]fps=12,scale=960:-2:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a' \
  -loop 0 cc-picker-demo.gif

# MP4 for the website and community uploads; no audio or source metadata.
ffmpeg -n -i demo-source.mkv -an -map_metadata -1 \
  -vf 'scale=1280:-2:flags=lanczos' -c:v libx264 -crf 23 \
  -pix_fmt yuv420p -movflags +faststart cc-picker-demo.mp4

# Select a useful frame showing the picker; adjust the timestamp to the take.
ffmpeg -n -ss 2 -i cc-picker-demo.mp4 -frames:v 1 cc-picker-demo-poster.png

ffprobe -v error -show_entries format=duration,size \
  -of default=noprint_wrappers=1 cc-picker-demo.mp4
```

Target a GIF below roughly 5 MB without sacrificing legibility. If larger,
try 10 fps or a slightly narrower export and review again. The MP4 is the
preferred website asset because it supports pause and is usually smaller.

Before adding assets, watch both exports from start to finish and check the
poster separately. Verify readable project names, no sensitive content,
the real terminal transition, correct working folder, useful final hold,
duration, and file sizes. Record capture date, source commit, cc-picker and
Claude versions, desktop/dialog/terminal and reviewer in this document.

Capture record: **pending**. No GIF, MP4 or poster has been produced or reviewed.

## Integration once the recording passes review

Store the reviewed assets together in `website/assets/demo/`:
`cc-picker-demo.gif`, `cc-picker-demo.mp4`, `cc-picker-demo-poster.png`.
Use one GIF for both README languages; the website deploy already includes
tracked files under `website/`. Do not add broken links before the files exist.

Insert before “How it works” in `README.md`:

```markdown
## See it in action

![Real recording: select my-app in cc-picker; a terminal opens and Claude Code starts in that project.](website/assets/demo/cc-picker-demo.gif)

Pick a project → Claude Code starts right there.
[Watch the video with playback controls](https://cc-picker.brue.nu/#demo).
```

Insert before “So funktioniert's” in `README.de.md`:

```markdown
## In Aktion

![Echte Aufnahme: my-app in cc-picker wählen; ein Terminal öffnet sich und Claude Code startet in diesem Projekt.](website/assets/demo/cc-picker-demo.gif)

Projekt wählen → Claude Code startet genau dort.
[Video mit Wiedergabesteuerung ansehen](https://cc-picker.brue.nu/#demo).
```

Website markup immediately after `.hero`:

```html
<section class="band" id="demo" aria-labelledby="demo-title">
  <h2 id="demo-title" data-t="demoTitle">See it in action</h2>
  <video controls playsinline preload="none"
         poster="assets/demo/cc-picker-demo-poster.png"
         aria-labelledby="demo-title" aria-describedby="demo-description"
         style="display:block;width:100%;height:auto">
    <source src="assets/demo/cc-picker-demo.mp4" type="video/mp4">
    <a href="assets/demo/cc-picker-demo.mp4" data-t="demoDownload">Download the demo video</a>
  </video>
  <p id="demo-description" data-t="demoDescription">Real recording: select my-app in cc-picker; a terminal opens and Claude Code starts in that project.</p>
</section>
```

Add `demoTitle`, `demoDownload` and `demoDescription` to the existing `data-t`
translation dictionary, including German equivalents. Set the video's actual
`width` and `height` attributes after export to reserve layout space. No autoplay,
looping video, external embed, extra consent requirement or tracking event is
needed. Keep the text description available without playing the silent clip.
Check English/German, both detail modes, mobile width, keyboard playback and
the no-JavaScript fallback before merging the asset integration PR.

## Launch sequence

1. Finish recording, review, integrate and verify the deployed assets.
2. Re-read current r/ClaudeCode rules, including self-promotion, upload and
   flair requirements. Publish the draft in [launch-copy.md](launch-copy.md)
   only when the real demo is ready and posting is explicitly authorized.
3. Collect useful feedback: desktop/dialog/terminal, whether users understood
   the workflow, installation problems and missing essentials. Avoid adding
   features solely for promotion.
4. Consider r/ClaudeAI afterwards, with its own rules check and adapted copy;
   avoid simultaneous duplicate posts.
5. Find maintained Awesome Claude Code/tool lists; check scope, duplicates,
   contribution format and activity before preparing a focused listing PR.
6. Consider Show HN after initial feedback. Confirm its current submission
   rules and keep the tool freely inspectable and usable.

Community rules and directory eligibility have **not** been checked in this
preparation. No community posts or listing PRs have been submitted.
