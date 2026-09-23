<p align="center">
  <a href="README.md">English</a> | <b>Deutsch</b>
</p>

<p align="center">
  <img src="docs/banner.de.svg" alt="cc-picker – Projekt wählen, Claude Code startet genau dort" width="100%">
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
  <img src="docs/flow.de.svg" alt="Ablauf: 1. cc-picker starten, 2. Modus GUI oder Shell wählen, 3. Projekt wählen oder neu anlegen, 4. Terminal öffnet sich im Projektordner und startet claude" width="100%">
</p>

## Zwei Modi

<table>
  <tr>
    <th width="50%">🖱️ GUI-Modus</th>
    <th width="50%">⌨️ Shell-Modus</th>
  </tr>
  <tr>
    <td><img src="docs/gui-mode.de.svg" alt="GUI-Modus: zenity-Fenster mit Projektliste"></td>
    <td><img src="docs/shell-mode.de.svg" alt="Shell-Modus: nummeriertes Projektmenü im Terminal"></td>
  </tr>
  <tr>
    <td>Auswahlfenster per <code>zenity</code>, <code>kdialog</code> oder <code>yad</code> –
    je nachdem, was dein Desktop mitbringt. Claude Code startet in einem
    neuen Terminalfenster im gewählten Ordner.</td>
    <td>Nummeriertes Menü direkt im Terminal – ideal per SSH oder ohne
    Desktop. Start mit <code>cc-picker --shell-mode</code>; wird auch
    automatisch genutzt, wenn kein Dialog-Programm installiert ist.</td>
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
| 🪟 **GUI oder Shell** | standardmäßig das Fenster, Terminal-Menü per `--shell-mode`; GUI klappt mit `zenity` (GNOME & die meisten Desktops), `kdialog` (KDE) oder `yad` |
| 🕘 **Zuletzt benutzte oben** | zuletzt geöffnete Projekte stehen ganz oben, mit Zeitangabe |
| ➕ **Neues Projekt** | direkt aus der Auswahl anlegen, optional per `git clone` einer Remote-URL |
| 🔍 **Auto-Erkennung** | `claude`-Binary (PATH, dann gängige Installationsorte), Terminal-Emulator (gnome-terminal, konsole, xfce4-terminal, alacritty, kitty, xterm) und deine Login-Shell (bash, zsh, fish, …) |
| 🌐 **Deutsch & Englisch** | Sprache folgt automatisch der Systemsprache (`$LANG`) |
| ⚙️ **Keine hartcodierten Pfade** | alles per Konfigurationsdatei oder Umgebungsvariablen einstellbar |
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

**Auch die Abhängigkeiten werden geprüft** – siehe [Abhängigkeiten](#abhängigkeiten).

## Nutzung

```bash
cc-picker                # Projektliste (Fenster)
cc-picker --shell-mode   # Terminal-Menü
cc-picker --help         # Hilfe, Projektordner und Konfigurationsdatei
cc-picker --version      # Version anzeigen
```

Oder im Anwendungsmenü nach **cc-picker** suchen.

1. Projekt wählen – zuletzt benutzte stehen oben – oder
   **„+ Neues Projekt erstellen"** (Name eingeben, optional Git-Remote-URL
   zum Klonen; beim Klonen zeigt ein Fortschrittsfenster den Stand)
2. Ein Terminal öffnet sich im gewählten Ordner, `claude` startet dort.
   Beendest du Claude Code, bleibt die Shell im Projektordner offen.

## Konfiguration

Standardmäßig liegen die Projekte in `~/claude-projects`. Um das oder
andere Einstellungen zu ändern, lege `~/.config/cc-picker/config` an:

```ini
# ~/.config/cc-picker/config
CC_PICKER_BASE=~/Projekte/ki
CC_PICKER_LANG=de
```

Die Konfigurationsdatei gilt auch beim Start über das Anwendungsmenü.
Gleichnamige Umgebungsvariablen haben Vorrang. Die Datei wird nur gelesen,
nie ausgeführt, und nur diese Schlüssel werden beachtet:

| Variable             | Standard                            | Bedeutung                                       |
|----------------------|-------------------------------------|-------------------------------------------------|
| `CC_PICKER_BASE`     | `~/claude-projects`                 | Ordner, in dem Projekte gesucht/angelegt werden |
| `CC_PICKER_BIN`      | automatisch erkannt                 | Pfad zur `claude`-Binary                        |
| `CC_PICKER_TERMINAL` | automatisch erkannt                 | zu verwendender Terminal-Emulator               |
| `CC_PICKER_SHELL`    | automatisch erkannt (`/etc/passwd`) | Shell, die nach Claude Code weiterläuft         |
| `CC_PICKER_LANG`     | aus `$LANG`                         | Sprache der Oberfläche: `de…` = Deutsch, sonst Englisch |
| `CC_PICKER_DIALOG`   | automatisch erkannt                 | Dialog-Programm: `zenity`, `kdialog` oder `yad` |
| `CC_PICKER_MODE`     | `gui`                               | was `cc-picker` öffnet: `gui` (Projektliste), `shell` (Terminal-Menü) oder `ask` (fragen) |

Einmaliges Beispiel per Umgebungsvariablen:

```bash
CC_PICKER_BASE=~/projekte CC_PICKER_BIN=/opt/claude/bin/claude cc-picker
```

## Abhängigkeiten

| Was | Wofür | Hinweis |
|---|---|---|
| `bash` | alles | auf praktisch jedem Linux vorinstalliert |
| [`claude`](https://claude.com/product/claude-code) | alles | die Claude-Code-Kommandozeile |
| ein Dialog-Programm | GUI-Modus & Start per Icon | eines von `zenity`, `kdialog`, `yad` – die meisten Desktops haben eines dabei |
| ein Terminal-Emulator | GUI-Modus | gnome-terminal, konsole, xfce4-terminal, alacritty, kitty oder xterm |
| `git` | optional | nur zum Klonen beim Anlegen neuer Projekte |

**`install.sh` prüft das alles für dich.** Fehlt ein Dialog-Programm, bietet
es an, eines zu installieren (`kdialog` unter KDE, sonst `zenity`), und zeigt
vorher den genauen Befehl:

```text
zenity jetzt installieren? Ausgeführt wird:
  sudo pacman -S --needed zenity
Installieren? [J/n]
```

Ohne deine Bestätigung wird nichts installiert, und das Passwort fragt `sudo`
selbst ab – der Installer läuft nie als root. Prüfung überspringen:
`CC_PICKER_NO_DEPS=1 ./install.sh`.

Dialog-Programm von Hand installieren:

| Distribution | Befehl |
|---|---|
| Arch / Manjaro | `sudo pacman -S zenity` |
| Debian / Ubuntu / Mint | `sudo apt install zenity` |
| Fedora | `sudo dnf install zenity` |
| openSUSE | `sudo zypper install zenity` |

Unter KDE statt `zenity` einfach `kdialog` nehmen.

> Ohne Dialog-Programm weicht cc-picker aufs Terminal-Menü aus – auch beim
> Start über das Anwendungsmenü, sofern ein Terminal-Emulator installiert ist.

## Deinstallation

```bash
rm ~/.local/bin/cc-picker \
   ~/.local/share/applications/cc-picker.desktop \
   ~/.local/share/icons/cc-picker.svg
```

Deine Projektordner bleiben dabei unberührt. Einen von `install.sh`
ergänzten PATH-Eintrag (markiert mit `# added by cc-picker install.sh`)
kannst du bei Bedarf aus deiner Shell-Config löschen.

Einstellungen und die Liste der zuletzt benutzten Projekte liegen in zwei
kleinen lokalen Dateien – es wird nichts irgendwohin gesendet. Auch diese
entfernen:

```bash
rm -r ~/.config/cc-picker ~/.local/state/cc-picker
```

## Mitwirken

Issues und Pull Requests willkommen – siehe [CONTRIBUTING.md](CONTRIBUTING.md) (Englisch).

## Lizenz

[MIT](LICENSE)
