# cc-picker

Ein kleines Kommandozeilen-/GUI-Tool, das dir hilft, [Claude Code](https://claude.com/product/claude-code)
sauber getrennt in verschiedenen Projektordnern zu starten — statt immer im
Home-Verzeichnis oder vermischt mit anderen KI-Coding-Tools.

> **Hinweis:** cc-picker ist ein unabhängiges Community-Projekt und **nicht mit
> Anthropic verbunden oder von Anthropic autorisiert**. "Claude" ist eine
> Marke von Anthropic, PBC. Dieses Tool startet lediglich die offizielle
> `claude`-Kommandozeile in einem von dir gewählten Ordner.

## Warum?

Wenn du mehrere KI-Coding-Tools parallel nutzt (z. B. Claude Code und ein
anderes Tool auf demselben Rechner), will man in der Regel:

- getrennte, unabhängige Arbeitskopien pro Tool statt gemeinsam genutzter Ordner
- schnellen Wechsel zwischen mehreren Projekten, ohne sich Pfade zu merken
- Claude Code nicht versehentlich im gesamten Home-Verzeichnis starten
  (unnötig weitreichende Datei-/Ausführungsrechte)

cc-picker löst das mit einer einfachen Auswahlliste: Ordner wählen (oder neu
anlegen, optional mit `git clone`) → Claude Code startet direkt dort.

## Features

- **GUI- oder Shell-Modus** — beim Start wählbar (GUI via `zenity`, sonst
  automatischer Fallback auf Terminal-Menü)
- **Neues Projekt erstellen** direkt aus der Auswahl heraus, optional mit
  `git clone` einer Remote-URL
- **Automatische Erkennung:**
  - `claude`-Binary (PATH, dann gängige Installationsorte)
  - verfügbarer Terminal-Emulator (gnome-terminal, konsole, xfce4-terminal,
    alacritty, kitty, xterm)
  - eigene Login-Shell (bash, zsh, fish, ...) für die Session nach Claude Code
- **Keine hartcodierten Pfade** — alles über Umgebungsvariablen konfigurierbar

## Installation

```bash
git clone https://github.com/bruneler/cc-picker.git
cd cc-picker
./install.sh
```

Das Skript installiert:
- `~/.local/bin/cc-picker` (ausführbares Skript)
- `~/.local/share/applications/cc-picker.desktop` (App-Icon fürs Anwendungsmenü)

Falls `~/.local/bin` noch nicht in deinem `PATH` ist:
```bash
export PATH="$HOME/.local/bin:$PATH"
```
(in `~/.bashrc` bzw. `~/.zshrc` eintragen, damit es dauerhaft gilt.)

## Nutzung

Per Terminal:
```bash
cc-picker
```

Per Icon: im Anwendungsmenü nach **cc-picker** suchen.

Ablauf:
1. Modus wählen: **GUI** oder **Shell**
2. Projekt aus der Liste wählen — oder **„+ Neues Projekt erstellen"**
   (Name eingeben, optional Git-Remote-URL zum Klonen)
3. Ein neues Terminal öffnet sich im gewählten Ordner, `claude` startet dort

## Konfiguration

Alles über Umgebungsvariablen, kein Editieren des Skripts nötig:

| Variable            | Standard                          | Bedeutung                                  |
|---------------------|------------------------------------|---------------------------------------------|
| `CC_PICKER_BASE`    | `~/Entwicklung/claude-code`        | Ordner, in dem Projekte gesucht/angelegt werden |
| `CC_PICKER_BIN`     | automatisch erkannt                | Pfad zur `claude`-Binary                   |
| `CC_PICKER_TERMINAL`| automatisch erkannt                | Zu verwendender Terminal-Emulator          |
| `CC_PICKER_SHELL`   | automatisch erkannt (`/etc/passwd`)| Shell, die nach Claude Code weiterläuft    |

Beispiel:
```bash
CC_PICKER_BASE=~/projekte CC_PICKER_BIN=/opt/claude/bin/claude cc-picker
```

## Voraussetzungen

- `bash`
- [`claude`](https://claude.com/product/claude-code) (Claude Code CLI), installiert und erreichbar
- optional: `zenity` für den GUI-Modus
- optional: `git` für die „Neues Projekt erstellen"-Funktion mit Klonen

## Mitwirken

Issues und Pull Requests willkommen — siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz

[MIT](LICENSE)
