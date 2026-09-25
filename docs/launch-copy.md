# Launch copy — drafts, not published

Use only after the real demo is reviewed and available. Check each community's
current rules before posting. Never claim unrecorded platform tests or user
feedback. Attach the reviewed MP4 where supported; use the website for playback
elsewhere. The author should confirm the first-person wording reflects their
experience.

## Reusable description

cc-picker is a small open-source Linux launcher for Claude Code. Pick a project
folder from a list, and Claude Code starts right there. It supports a graphical
picker and a terminal menu. Written in Bash, licensed under MIT.

Repository: https://github.com/bruneler/cc-picker

Website: https://cc-picker.brue.nu/

## r/ClaudeCode

Title: I got tired of starting Claude Code in the wrong directory, so I built cc-picker

I wanted a simple way to choose a project before starting Claude Code, so I
built cc-picker: a small Linux launcher that shows a project list and opens
Claude Code in the folder you choose.

The clip shows the real workflow: open the picker → choose my-app → Claude
Code starts in that project's terminal.

There's also a terminal menu for SSH or a desktop without a dialog tool, plus
recent projects and options to continue an earlier session. It uses your
existing Claude Code installation. The launcher has no telemetry and doesn't
change Claude Code's permissions or sandbox it.

It's MIT-licensed: https://github.com/bruneler/cc-picker

How do you switch between Claude Code projects today? I'd especially appreciate
feedback on whether the picker fits your workflow and how it works on your
Linux desktop.

## r/ClaudeAI — later, adapted for a broader audience

Title: A small Linux project picker for people using Claude Code across several projects

If you use Claude Code in several project folders, I made a small open-source
launcher that lets you choose the folder first. It then opens a terminal and
starts Claude Code there.

The short recording shows the whole workflow. It's a Linux tool for the
Claude Code command line, using an existing Claude Code installation.

Code and installation: https://github.com/bruneler/cc-picker

For people who work this way: is choosing the starting folder a recurring
friction point, or does your editor or terminal setup already handle it well?

## Directory entry — adapt to the target contribution format

[cc-picker](https://github.com/bruneler/cc-picker) — A lightweight Linux project
launcher for Claude Code, with a graphical picker or terminal menu, recent
projects and session continuation. Bash; MIT.

## Show HN — after initial feedback

Title: Show HN: cc-picker – Pick a Linux project folder and start Claude Code there

Suggested submission URL: https://github.com/bruneler/cc-picker

Introductory comment draft:

I built cc-picker to make the starting directory an explicit choice before
launching Claude Code. It's a Bash script for Linux: choose a project in a
graphical picker or terminal menu, and Claude Code starts in that folder.

It works with an existing Claude Code installation and has no background
service or launcher telemetry. It doesn't change Claude Code's permissions;
the working directory isn't a sandbox.

The repository has installation instructions and a short real recording.
I'd be interested in feedback on the workflow and Linux desktop compatibility.
