<p align="center">
  <img src="docs/banner.svg" alt="cc-picker – Projekt wählen, Claude Code startet genau dort" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Lizenz-MIT-4f8cff" alt="Lizenz: MIT">
  <img src="https://img.shields.io/badge/Bash-%E2%89%A5%204-5fe0a0?logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Plattform-Linux-8b93a6?logo=linux&logoColor=white" alt="Linux">
</p>

**cc-picker** ist ein kleiner Projekt-Launcher für
[Claude Code](https://claude.com/product/claude-code): Du wählst einen
Projektordner aus einer Liste (oder legst einen neuen an), und Claude Code
startet **genau dort** – statt im Home-Verzeichnis oder vermischt mit
anderen KI-Coding-Tools.

> **Hinweis:** cc-picker ist ein unabhängiges Community-Projekt und **nicht mit
> Anthropic verbunden oder von Anthropic autorisiert**. "Claude" ist eine
> Marke von Anthropic, PBC. Dieses Tool startet lediglich die offizielle
> `claude`-Kommandozeile in einem von dir gewählten Ordner.

## So funktioniert's

<p align="center">
  <img src="docs/flow.svg" alt="Ablauf: 1. cc-picker starten, 2. Modus GUI oder Shell wählen, 3. Projekt wählen oder neu anlegen, 4. Terminal öffnet sich im Projektordner und startet claude" width="100%">
</p>

## Zwei Modi

<table>
  <tr>
    <th width="50%">🖱️ GUI-Modus</th>
    <th width="50%">⌨️ Shell-Modus</th>
  </tr>
  <tr>
    <td><img src="docs/gui-mode.svg" alt="GUI-Modus: zenity-Fenster mit Projektliste"></td>
    <td><img src="docs/shell-mode.svg" alt="Shell-Modus: nummeriertes Projektmenü im Terminal"></td>
  </tr>
  <tr>
    <td>Auswahlfenster per <code>zenity</code>. Claude Code startet in einem
    neuen Terminalfenster im gewählten Ordner.</td>
    <td>Nummeriertes Menü direkt im Terminal – ideal per SSH oder ohne
    Desktop. Wird automatisch genutzt, wenn <code>zenity</code> fehlt.</td>
  </tr>
</table>

## Warum?

Wer mehrere KI-Coding-Tools parallel nutzt (z. B. Claude Code und ein
anderes Tool auf demselben Rechner), will in der Regel:

- 📂 **getrennte Arbeitskopien pro Tool** statt gemeinsam genutzter Ordner
- ⚡ **schnellen Projektwechsel**, ohne sich Pfade merken zu müssen
- 🔒 **Claude Code nicht versehentlich im ganzen Home-Verzeichnis** starten
  (unnötig weitreichende Datei- und Ausführungsrechte)

cc-picker löst das mit einer einfachen Auswahlliste: Ordner wählen (oder neu
anlegen, optional mit `git clone`) → Claude Code startet direkt dort.

## Features

| | |
|---|---|
| 🪟 **GUI oder Shell** | beim Start wählbar; ohne `zenity` automatischer Fallback aufs Terminal-Menü |
| ➕ **Neues Projekt** | direkt aus der Auswahl anlegen, optional per `git clone` einer Remote-URL |
| 🔍 **Auto-Erkennung** | `claude`-Binary (PATH, dann gängige Installationsorte), Terminal-Emulator (gnome-terminal, konsole, xfce4-terminal, alacritty, kitty, xterm) und deine Login-Shell (bash, zsh, fish, …) |
| ⚙️ **Keine hartcodierten Pfade** | alles über Umgebungsvariablen konfigurierbar |
| 🧩 **Desktop-Integration** | eigenes Icon im Anwendungsmenü |

## Installation

```bash
git clone https://github.com/bruneler/cc-picker.git
cd cc-picker
./install.sh
```

<img src="cc-picker.svg" alt="cc-picker App-Icon" width="72" align="right">

Das Skript installiert:

| Datei | Zweck |
|---|---|
| `~/.local/bin/cc-picker` | ausführbares Skript |
| `~/.local/share/applications/cc-picker.desktop` | Eintrag im Anwendungsmenü |
| `~/.local/share/icons/cc-picker.svg` | App-Icon |

**PATH wird automatisch eingerichtet:** Ist `~/.local/bin` noch nicht im
`PATH`, erkennt `install.sh` deine Login-Shell und ergänzt die passende
Zeile – nur einmal, auch bei mehrfacher Installation:

| Shell | Datei | Eintrag |
|---|---|---|
| bash | `~/.bashrc` | `export PATH="$HOME/.local/bin:$PATH"` |
| zsh | `~/.zshrc` | `export PATH="$HOME/.local/bin:$PATH"` |
| fish | `~/.config/fish/config.fish` | `fish_add_path "$HOME/.local/bin"` |
| andere | `~/.profile` | `export PATH="$HOME/.local/bin:$PATH"` |

Wer das lieber selbst macht: `CC_PICKER_NO_PATH=1 ./install.sh` – dann
wird die Zeile nur angezeigt, nicht eingetragen.

## Nutzung

```bash
cc-picker                # Modus-Auswahl (GUI oder Shell)
cc-picker --shell-mode   # direkt das Terminal-Menü
```

Oder im Anwendungsmenü nach **cc-picker** suchen.

1. Modus wählen: **GUI** oder **Shell**
2. Projekt aus der Liste wählen – oder **„+ Neues Projekt erstellen"**
   (Name eingeben, optional Git-Remote-URL zum Klonen)
3. Ein Terminal öffnet sich im gewählten Ordner, `claude` startet dort.
   Beendest du Claude Code, bleibt die Shell im Projektordner offen.

## Konfiguration

Alles über Umgebungsvariablen, kein Editieren des Skripts nötig:

| Variable             | Standard                            | Bedeutung                                       |
|----------------------|-------------------------------------|-------------------------------------------------|
| `CC_PICKER_BASE`     | `~/Entwicklung/claude-code`         | Ordner, in dem Projekte gesucht/angelegt werden |
| `CC_PICKER_BIN`      | automatisch erkannt                 | Pfad zur `claude`-Binary                        |
| `CC_PICKER_TERMINAL` | automatisch erkannt                 | zu verwendender Terminal-Emulator               |
| `CC_PICKER_SHELL`    | automatisch erkannt (`/etc/passwd`) | Shell, die nach Claude Code weiterläuft         |

Beispiel:

```bash
CC_PICKER_BASE=~/projekte CC_PICKER_BIN=/opt/claude/bin/claude cc-picker
```

## Voraussetzungen

- `bash`
- [`claude`](https://claude.com/product/claude-code) (Claude Code CLI), installiert und erreichbar
- optional: `zenity` für den GUI-Modus
- optional: `git` für „Neues Projekt erstellen" mit Klonen

## Deinstallation

```bash
rm ~/.local/bin/cc-picker \
   ~/.local/share/applications/cc-picker.desktop \
   ~/.local/share/icons/cc-picker.svg
```

Deine Projektordner bleiben dabei unberührt. Einen von `install.sh`
ergänzten PATH-Eintrag (markiert mit `# added by cc-picker install.sh`)
kannst du bei Bedarf aus deiner Shell-Config löschen.

## Mitwirken

Issues und Pull Requests willkommen – siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Lizenz

[MIT](LICENSE)
