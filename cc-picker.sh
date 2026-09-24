#!/bin/bash
# cc-picker — project picker & launcher for Claude Code
# https://github.com/bruneler/cc-picker
#
# Not affiliated with or endorsed by Anthropic. "Claude" is a trademark
# of Anthropic, PBC. This tool simply launches the `claude` CLI in a
# chosen project directory.
#
# Flow: load config → pick UI language → parse options → detect claude,
# dialog tool, terminal and shell → show the project list (window or
# terminal menu), or resolve a project given on the command line → ask
# whether to continue an earlier Claude session → open a terminal in the
# chosen folder and start claude. main() at the bottom runs these steps.
#
# Convention: functions return values on stdout, which callers capture with
# $(...). All messages, prompts and git output must therefore go to stderr,
# or they would end up in the returned value. Functions that fill the P_*
# arrays must run in the current shell, never inside $(...). Questions go
# through the ui_* functions, which ask with a dialog or in the terminal
# depending on GUI.
#
# The translated T_* messages are our own constants; some are used as printf
# format strings on purpose (they contain %s/%d placeholders).
# shellcheck disable=SC2059

set -euo pipefail

VERSION="0.3.2"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cc-picker"
CONFIG_FILE="$CONFIG_DIR/config"
TEMPLATE_DIR="$CONFIG_DIR/templates"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/cc-picker"
RECENT_FILE="$STATE_DIR/recent"
PINNED_FILE="$STATE_DIR/pinned"
RECENT_MAX=50
ARCHIVE_NAME=".archive"
# The window list offers a search entry from this many projects on
SEARCH_MIN=8

# expand_home <path> — expands a leading ~/ or $HOME/ by hand (matched
# literally on purpose, the config file is never evaluated)
# shellcheck disable=SC2088
expand_home() {
    case "$1" in
        "~")        printf '%s' "$HOME" ;;
        "~/"*)      printf '%s' "$HOME/${1#\~/}" ;;
        "\$HOME/"*) printf '%s' "$HOME/${1#\$HOME/}" ;;
        *)          printf '%s' "$1" ;;
    esac
}

# --- Config file: KEY=VALUE lines, environment variables take precedence ---
# Parsed, not sourced, and limited to known CC_PICKER_* keys.
load_config() {
    local key value
    [ -f "$CONFIG_FILE" ] || return 0
    while IFS='=' read -r key value || [ -n "$key" ]; do
        key="${key//[[:space:]]/}"
        case "$key" in
            CC_PICKER_BASE|CC_PICKER_BIN|CC_PICKER_TERMINAL|CC_PICKER_SHELL|CC_PICKER_LANG|CC_PICKER_DIALOG|CC_PICKER_MODE) ;;
            CC_PICKER_SESSION|CC_PICKER_GIT_STATUS|CC_PICKER_EDITOR|CC_PICKER_FZF|CC_PICKER_UPDATE_REPO) ;;
            *) continue ;;
        esac
        [ -n "${!key:-}" ] && continue
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value#[\"\']}"
        value="${value%[\"\']}"
        value="$(expand_home "$value")"
        printf -v "$key" '%s' "$value"
    done < "$CONFIG_FILE"
}

# init_settings — sets BASES/BASE and the other settings from the config
# file and environment. Projects folders: CC_PICKER_BASE may list several,
# separated by ":". New projects are created in the first one.
init_settings() {
    local b bases
    BASES=()
    IFS=':' read -ra bases <<< "${CC_PICKER_BASE:-$HOME/claude-projects}"
    for b in "${bases[@]}"; do
        b="$(expand_home "$b")"
        [ "$b" = "/" ] || b="${b%/}"
        [ -n "$b" ] && BASES+=("$b")
    done
    [ "${#BASES[@]}" -gt 0 ] || BASES=("$HOME/claude-projects")
    BASE="${BASES[0]}"

    START_MODE="${CC_PICKER_MODE:-gui}"
    SESSION_MODE="${CC_PICKER_SESSION:-ask}"
    GIT_STATUS="${CC_PICKER_GIT_STATUS:-1}"
    USE_FZF="${CC_PICKER_FZF:-1}"
    UPDATE_REPO="${CC_PICKER_UPDATE_REPO:-https://github.com/bruneler/cc-picker.git}"
}

# --- UI language: German for de_* locales, English otherwise ---
# load_messages — sets UI_LANG and the translated T_* messages
load_messages() {
    UI_LANG="${CC_PICKER_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
    case "$UI_LANG" in
        de*)
            T_NEW_ENTRY="+ Neues Projekt erstellen"
            T_MANAGE_ENTRY="⚙ Projekte verwalten …"
            T_SEARCH_ENTRY="⌕ Suchen …"
            T_SHOW_ALL="× Alle Projekte zeigen"
            T_NO_CLAUDE="claude wurde nicht gefunden. Bitte CC_PICKER_BIN setzen oder claude installieren."
            T_NO_TERMINAL="Kein unterstütztes Terminal gefunden. Bitte CC_PICKER_TERMINAL setzen."
            T_NEW_TITLE="Neues Projekt"
            T_NEW_NAME="Name des neuen Projektordners:"
            T_BAD_NAME="Ungültiger Name. Erlaubt ist ein einfacher Ordnername: kein '/', keine Tabulatoren oder Zeilenumbrüche, nicht mit '.' oder '-' beginnend, keine Leerzeichen am Anfang oder Ende."
            T_EXISTS="Es gibt schon einen Ordner namens %s."
            T_CLONE_TITLE="Git-Repo (optional)"
            T_CLONE_GUI="Git-Remote-URL oder GitHub-Kurzform (benutzer/repo) zum Klonen, oder leer lassen für ein neues Projekt:"
            T_CLONE_SHELL="Git-URL oder benutzer/repo zum Klonen (leer lassen für ein neues Projekt):"
            T_CLONING="Klone %s …"
            T_CLONE_FAIL="git clone ist fehlgeschlagen:"
            T_TEMPLATE_TEXT="Womit soll das neue Projekt starten?"
            T_COL_TEMPLATE="Vorlage"
            T_TEMPLATE_EMPTY="Leerer Ordner"
            T_TEMPLATE_ITEM="Vorlage: %s"
            T_PICK_PROJECT="In welchem Projekt starten?"
            T_COL_PROJECT="Projekt"
            T_COL_LAST="Zuletzt"
            T_COL_GIT="Git"
            T_GIT_CHANGED="%d geändert"
            T_GIT_DETACHED="abgekoppelt"
            T_SHELL_HEADER="cc-picker — Projekt wählen (Nummer, oder Text zum Filtern):"
            T_INVALID="Ungültige Auswahl, nochmal."
            T_NO_MATCH='Nichts passt zu „%s“.'
            T_SEARCH_TITLE="Suchen"
            T_SEARCH_TEXT="Teil des Projektnamens:"
            T_PICK_MODE="Wie möchtest du das Projekt auswählen?"
            T_COL_MODE="Modus"
            T_MODE_GUI="Projektliste (Fenster)"
            T_MODE_SHELL="Terminal-Menü"
            T_SESSION_TEXT="Wie soll Claude Code in %s starten?"
            T_COL_START="Start"
            T_SESSION_NEW="Neue Sitzung"
            T_SESSION_CONTINUE="Letzte Sitzung fortsetzen"
            T_SESSION_RESUME="Frühere Sitzung auswählen"
            T_MANAGE_PICK="Welches Projekt möchtest du verwalten?"
            T_MANAGE_TEXT="Was soll mit %s passieren?"
            T_COL_ACTION="Aktion"
            T_ACT_FILES="Im Dateimanager öffnen"
            T_ACT_EDITOR="Im Editor öffnen (%s)"
            T_ACT_PIN="Anheften (steht dann immer oben)"
            T_ACT_UNPIN="Nicht mehr anheften"
            T_ACT_RENAME="Umbenennen"
            T_ACT_ARCHIVE="Archivieren"
            T_ACT_RESTORE="Archiviertes Projekt wiederherstellen …"
            T_RENAME_TEXT="Neuer Name für %s:"
            T_ARCHIVE_ASK='%s archivieren?

Der Ordner wird nach %s verschoben, nicht gelöscht. Zurückholen kannst du ihn unter „Projekte verwalten“.'
            T_CONFIRM="[j/N] "
            T_RESTORE_PICK="Welches Projekt wiederherstellen?"
            T_BTN_START="Starten"
            T_BTN_NEXT="Weiter"
            T_BTN_OK="OK"
            T_BTN_CANCEL="Abbrechen"
            T_BAD_OPTION="Unbekannte Option:"
            T_TOO_MANY="Zu viele Argumente:"
            T_NOT_FOUND="Kein Projekt namens %s gefunden."
            T_AMBIGUOUS="%s passt zu mehreren Projekten:"
            T_NO_RECENT="Es wurde noch kein Projekt benutzt."
            T_UPD_NO_GIT="Für --update wird git benötigt."
            T_UPD_CHECK="Suche nach Updates in %s …"
            T_UPD_CURRENT="cc-picker %s ist aktuell."
            T_UPD_INSTALL="Aktualisiere cc-picker %s → %s …"
            T_UPD_FAIL="Update fehlgeschlagen:"
            T_AGO_NOW="gerade eben"
            T_AGO_MIN="vor %d Min."
            T_AGO_HOUR="vor %d Std."
            T_AGO_YESTERDAY="gestern"
            T_AGO_DAYS="vor %d Tagen"
            ;;
        *)
            T_NEW_ENTRY="+ Create new project"
            T_MANAGE_ENTRY="⚙ Manage projects …"
            T_SEARCH_ENTRY="⌕ Search …"
            T_SHOW_ALL="× Show all projects"
            T_NO_CLAUDE="claude not found. Please set CC_PICKER_BIN or install claude."
            T_NO_TERMINAL="No supported terminal emulator found. Please set CC_PICKER_TERMINAL."
            T_NEW_TITLE="New project"
            T_NEW_NAME="Name of the new project folder:"
            T_BAD_NAME="Invalid name. Use a plain folder name: no '/', no tabs or line breaks, not starting with '.' or '-', no spaces at the start or end."
            T_EXISTS="A folder named %s already exists."
            T_CLONE_TITLE="Git repo (optional)"
            T_CLONE_GUI="Git remote URL or GitHub shorthand (user/repo) to clone, or leave empty for a new project:"
            T_CLONE_SHELL="Git URL or user/repo to clone (leave empty for a new project):"
            T_CLONING="Cloning %s …"
            T_CLONE_FAIL="git clone failed:"
            T_TEMPLATE_TEXT="What should the new project start with?"
            T_COL_TEMPLATE="Template"
            T_TEMPLATE_EMPTY="Empty folder"
            T_TEMPLATE_ITEM="Template: %s"
            T_PICK_PROJECT="Which project do you want to start in?"
            T_COL_PROJECT="Project"
            T_COL_LAST="Last used"
            T_COL_GIT="Git"
            T_GIT_CHANGED="%d changed"
            T_GIT_DETACHED="detached"
            T_SHELL_HEADER="cc-picker — choose a project (number, or text to filter):"
            T_INVALID="Invalid choice, try again."
            T_NO_MATCH='Nothing matches “%s”.'
            T_SEARCH_TITLE="Search"
            T_SEARCH_TEXT="Part of the project name:"
            T_PICK_MODE="How do you want to choose the project?"
            T_COL_MODE="Mode"
            T_MODE_GUI="Project list (window)"
            T_MODE_SHELL="Terminal menu"
            T_SESSION_TEXT="How should Claude Code start in %s?"
            T_COL_START="Start"
            T_SESSION_NEW="New session"
            T_SESSION_CONTINUE="Continue last session"
            T_SESSION_RESUME="Choose an earlier session"
            T_MANAGE_PICK="Which project do you want to manage?"
            T_MANAGE_TEXT="What do you want to do with %s?"
            T_COL_ACTION="Action"
            T_ACT_FILES="Open in file manager"
            T_ACT_EDITOR="Open in editor (%s)"
            T_ACT_PIN="Pin (always listed first)"
            T_ACT_UNPIN="Unpin"
            T_ACT_RENAME="Rename"
            T_ACT_ARCHIVE="Archive"
            T_ACT_RESTORE="Restore an archived project …"
            T_RENAME_TEXT="New name for %s:"
            T_ARCHIVE_ASK='Archive %s?

The folder is moved to %s, not deleted. You can bring it back under “Manage projects”.'
            T_CONFIRM="[y/N] "
            T_RESTORE_PICK="Which project do you want to restore?"
            T_BTN_START="Start"
            T_BTN_NEXT="Next"
            T_BTN_OK="OK"
            T_BTN_CANCEL="Cancel"
            T_BAD_OPTION="Unknown option:"
            T_TOO_MANY="Too many arguments:"
            T_NOT_FOUND="No project named %s found."
            T_AMBIGUOUS="%s matches several projects:"
            T_NO_RECENT="No project has been used yet."
            T_UPD_NO_GIT="--update needs git."
            T_UPD_CHECK="Checking for updates in %s …"
            T_UPD_CURRENT="cc-picker %s is up to date."
            T_UPD_INSTALL="Updating cc-picker %s → %s …"
            T_UPD_FAIL="Update failed:"
            T_AGO_NOW="just now"
            T_AGO_MIN="%d min ago"
            T_AGO_HOUR="%d h ago"
            T_AGO_YESTERDAY="yesterday"
            T_AGO_DAYS="%d days ago"
            ;;
    esac
}

print_usage() {
    local bases
    bases="$(IFS=':'; printf '%s' "${BASES[*]}")"
    case "$UI_LANG" in
        de*) cat <<EOF
cc-picker $VERSION — Projekt wählen und Claude Code darin starten

Aufruf:
  cc-picker                Projektliste (Fenster)
  cc-picker --shell-mode   Terminal-Menü
  cc-picker NAME           direkt im Projekt NAME starten
                           (ein eindeutiger Anfang des Namens genügt)
  cc-picker -              im zuletzt benutzten Projekt starten
  cc-picker --update       auf die neueste Version aktualisieren
  cc-picker --help         diese Hilfe
  cc-picker --version      Version anzeigen

Sitzung (sonst wird gefragt, falls es schon eine gibt):
  -n, --new                neue Sitzung
  -c, --continue           letzte Sitzung fortsetzen
  -r, --resume             frühere Sitzung auswählen

Projektordner: $bases
Konfiguration: $CONFIG_FILE
               (oder Umgebungsvariablen CC_PICKER_*, siehe README)
EOF
        ;;
        *) cat <<EOF
cc-picker $VERSION — pick a project and launch Claude Code in it

Usage:
  cc-picker                project list (window)
  cc-picker --shell-mode   terminal menu
  cc-picker NAME           start right in project NAME
                           (a unique beginning of the name is enough)
  cc-picker -              start in the most recently used project
  cc-picker --update       update to the latest version
  cc-picker --help         show this help
  cc-picker --version      show the version

Session (otherwise you're asked if there already is one):
  -n, --new                new session
  -c, --continue           continue the last session
  -r, --resume             choose an earlier session

Projects folder: $bases
Config file:     $CONFIG_FILE
                 (or CC_PICKER_* environment variables, see README)
EOF
        ;;
    esac
}

usage_error() {
    echo "cc-picker: $1" >&2
    print_usage >&2
    exit 2
}

set_project_arg() {
    [ "$HAVE_PROJECT" = "0" ] || usage_error "$T_TOO_MANY $1"
    PROJECT_ARG="$1"
    HAVE_PROJECT=1
}

# parse_args <arg>... — sets SHELL_MODE, DO_UPDATE, SESSION_MODE and the
# project given on the command line (PROJECT_ARG, HAVE_PROJECT)
parse_args() {
    SHELL_MODE=0
    DO_UPDATE=0
    PROJECT_ARG=""
    HAVE_PROJECT=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --shell-mode)  SHELL_MODE=1 ;;
            -n|--new)      SESSION_MODE="new" ;;
            -c|--continue) SESSION_MODE="continue" ;;
            -r|--resume)   SESSION_MODE="resume" ;;
            --update)      DO_UPDATE=1 ;;
            -h|--help)     print_usage; exit 0 ;;
            -V|--version)  echo "cc-picker $VERSION"; exit 0 ;;
            --)            shift; break ;;
            -)             set_project_arg - ;;
            -*)            usage_error "$T_BAD_OPTION $1" ;;
            *)             set_project_arg "$1" ;;
        esac
        shift
    done
    if [ $# -gt 0 ]; then set_project_arg "$1"; fi
    if [ $# -gt 1 ]; then usage_error "$T_TOO_MANY $2"; fi
}

# --- Dialog tool: zenity (GNOME), kdialog (KDE) or yad, whichever exists ---
find_dialog() {
    local d
    for d in zenity kdialog yad; do
        command -v "$d" >/dev/null 2>&1 && { echo "$d"; return 0; }
    done
    return 1
}

# find_icon — the app icon for dialog windows (installed copy, or the one
# next to the script)
find_icon() {
    local i
    for i in "${XDG_DATA_HOME:-$HOME/.local/share}/icons/cc-picker.svg" "$(dirname "$SELF")/cc-picker.svg"; do
        [ -f "$i" ] && { echo "$i"; return 0; }
    done
    return 1
}

# Extra options for yad/kdialog windows: app icon if available
# (zenity 4 takes the window icon from the desktop, not from an option)
icon_args() {
    [ -n "$ICON" ] || return 0
    case "$DIALOG" in
        yad)     printf '%s\0' "--window-icon=$ICON" ;;
        kdialog) printf '%s\0' "--icon" "$ICON" ;;
    esac
}

# All list dialogs have a hidden first column with a key (e.g. "p3" for the
# fourth project, "new", "manage"), so labels never have to be parsed back.

# dlg_menu <text> <ok-label> <column> <key> <label>... — prints the chosen key
dlg_menu() {
    local text="$1" ok="$2" column="$3"; shift 3
    case "$DIALOG" in
        zenity) zenity --list --title="cc-picker" --text="$text" \
                    --column="key" --column="$column" --hide-column=1 --print-column=1 \
                    --ok-label="$ok" --cancel-label="$T_BTN_CANCEL" \
                    "$@" --height=320 --width=420 ;;
        yad)    yad --list --title="cc-picker" "${ICON_ARGS[@]}" --text="$text" \
                    --column="key" --column="$column" --hide-column=1 --print-column=1 \
                    --button="$T_BTN_CANCEL:1" --button="$ok:0" \
                    "$@" --height=320 --width=420 --separator="" ;;
        kdialog) kdialog --title "cc-picker" "${ICON_ARGS[@]}" \
                    --ok-label "$ok" --cancel-label "$T_BTN_CANCEL" \
                    --menu "$text" "$@" ;;
        *) return 1 ;;
    esac
}

# dlg_projects <key> <name> <last-used> [<git>]... — the project list; rows
# have the git column only when SHOW_GIT is 1; prints the chosen key
dlg_projects() {
    local cols=(--column="key" --column="$T_COL_PROJECT" --column="$T_COL_LAST")
    local args=() n=3 detail
    [ "$SHOW_GIT" = "1" ] && { cols+=(--column="$T_COL_GIT"); n=4; }
    case "$DIALOG" in
        zenity) zenity --list --title="cc-picker" --text="$T_PICK_PROJECT" "${cols[@]}" \
                    --hide-column=1 --print-column=1 \
                    --ok-label="$T_BTN_START" --cancel-label="$T_BTN_CANCEL" \
                    "$@" --height=460 --width=560 ;;
        yad)    yad --list --title="cc-picker" "${ICON_ARGS[@]}" --text="$T_PICK_PROJECT" "${cols[@]}" \
                    --hide-column=1 --print-column=1 --separator="" \
                    --button="$T_BTN_CANCEL:1" --button="$T_BTN_START:0" \
                    "$@" --height=460 --width=560 ;;
        kdialog)
            while [ $# -ge "$n" ]; do
                if [ "$n" = "4" ]; then detail="$(join_details "$3" "$4")"; else detail="$3"; fi
                if [ -n "$detail" ]; then args+=("$1" "$2   ($detail)"); else args+=("$1" "$2"); fi
                shift "$n"
            done
            kdialog --title "cc-picker" "${ICON_ARGS[@]}" \
                --ok-label "$T_BTN_START" --cancel-label "$T_BTN_CANCEL" \
                --menu "$T_PICK_PROJECT" "${args[@]}" ;;
        *) return 1 ;;
    esac
}

# dlg_entry <title> <text> [<prefill>] — prints the entered text
dlg_entry() {
    local prefill="${3:-}"
    case "$DIALOG" in
        zenity)  zenity --entry --title="$1" --text="$2" --entry-text="$prefill" \
                     --ok-label="$T_BTN_NEXT" --cancel-label="$T_BTN_CANCEL" ;;
        yad)     yad --entry --title="$1" "${ICON_ARGS[@]}" --text="$2" --entry-text="$prefill" \
                     --button="$T_BTN_CANCEL:1" --button="$T_BTN_NEXT:0" ;;
        kdialog) kdialog --title "$1" "${ICON_ARGS[@]}" \
                     --ok-label "$T_BTN_NEXT" --cancel-label "$T_BTN_CANCEL" \
                     --inputbox "$2" "$prefill" ;;
        *) return 1 ;;
    esac
}

# dlg_question <text> <ok-label> — succeeds if the user confirms
dlg_question() {
    case "$DIALOG" in
        zenity)  zenity --question --title="cc-picker" --text="$1" \
                     --ok-label="$2" --cancel-label="$T_BTN_CANCEL" ;;
        yad)     yad --title="cc-picker" "${ICON_ARGS[@]}" --image=dialog-question --text="$1" \
                     --button="$T_BTN_CANCEL:1" --button="$2:0" ;;
        kdialog) kdialog --title "cc-picker" "${ICON_ARGS[@]}" \
                     --yes-label "$2" --no-label "$T_BTN_CANCEL" --yesno "$1" ;;
        *) return 1 ;;
    esac
}

# dlg_error <text>
dlg_error() {
    case "$DIALOG" in
        zenity)  zenity --error --title="cc-picker" --text="$1" ;;
        yad)     yad --title="cc-picker" "${ICON_ARGS[@]}" --image=dialog-error --text="$1" --button=OK ;;
        kdialog) kdialog --title "cc-picker" "${ICON_ARGS[@]}" --error "$1" ;;
        *) return 1 ;;
    esac
}

# dlg_info <text>
dlg_info() {
    case "$DIALOG" in
        zenity)  zenity --info --title="cc-picker" --text="$1" ;;
        yad)     yad --title="cc-picker" "${ICON_ARGS[@]}" --image=dialog-information --text="$1" --button=OK ;;
        kdialog) kdialog --title "cc-picker" "${ICON_ARGS[@]}" --msgbox "$1" ;;
        *) return 1 ;;
    esac
}

# dlg_busy <text> <pid> — shows a busy indicator until process <pid> exits
dlg_busy() {
    local text="$1" pid="$2"
    case "$DIALOG" in
        zenity)
            while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done \
                | zenity --progress --pulsate --auto-close --no-cancel \
                    --title="cc-picker" --text="$text" 2>/dev/null || true ;;
        yad)
            while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done \
                | yad --progress --pulsate --auto-close --no-buttons \
                    --title="cc-picker" "${ICON_ARGS[@]}" --text="$text" 2>/dev/null || true ;;
        kdialog)
            kdialog --title "cc-picker" --passivepopup "$text" 5 2>/dev/null &
            while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done ;;
        *)  while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done ;;
    esac
}

# --- Terminal menu ---
# fzf is used when it's installed and we're on a real terminal; otherwise a
# numbered menu that also accepts text to filter the list.
fzf_ok() {
    [ "$USE_FZF" = "1" ] && command -v fzf >/dev/null 2>&1 && [ -t 0 ] && [ -t 2 ]
}

# shell_menu <header> <item> <filter>... — prints the index of the chosen
# item; fails on EOF (Ctrl+D) or Esc. Typed text is matched against each
# item's <filter> (e.g. only the project name, not the "2 h ago" details).
shell_menu() {
    local header="$1"; shift
    local items=() filter=() shown=() matches=() i n reply needle redraw=1
    while [ $# -ge 2 ]; do
        items+=("$1")
        filter+=("$2")
        shift 2
    done
    if fzf_ok; then
        for i in "${!items[@]}"; do printf '%s\t%s\n' "$i" "${items[$i]}"; done \
            | fzf --delimiter=$'\t' --with-nth=2.. --header="$header" \
                  --height=50% --reverse --no-multi \
            | cut -f1
        return
    fi
    shown=("${!items[@]}")
    while true; do
        if [ "$redraw" = "1" ]; then
            echo "$header" >&2
            echo >&2
            n=1
            for i in "${shown[@]}"; do
                printf '%3d) %s\n' "$n" "${items[$i]}" >&2
                n=$((n + 1))
            done
            redraw=0
        fi
        read -rp "#? " reply || return 1
        reply="${reply#"${reply%%[![:space:]]*}"}"
        reply="${reply%"${reply##*[![:space:]]}"}"
        if [ -z "$reply" ]; then
            shown=("${!items[@]}")
            redraw=1
            continue
        fi
        if [[ "$reply" =~ ^[0-9]+$ ]]; then
            if [ "$reply" -ge 1 ] && [ "$reply" -le "${#shown[@]}" ]; then
                echo "${shown[$((reply - 1))]}"
                return 0
            fi
            echo "$T_INVALID" >&2
            continue
        fi
        needle="${reply,,}"
        matches=()
        for i in "${!items[@]}"; do
            [[ "${filter[$i],,}" == *"$needle"* ]] && matches+=("$i")
        done
        case "${#matches[@]}" in
            0) printf "$T_NO_MATCH\n" "$reply" >&2 ;;
            1) echo "${matches[0]}"; return 0 ;;
            *) shown=("${matches[@]}"); redraw=1 ;;
        esac
    done
}

# --- Asking the user: dialogs (GUI=1) or terminal prompts (GUI=0) ---
# GUI is 1 while the project list window is used, and when a project given
# on the command line is started without a terminal.
GUI=0

# ui_menu <text> <ok-label> <column> <key> <label>... — prints the key of
# the chosen entry; fails on cancel
ui_menu() {
    local text="$1" ok="$2" column="$3" keys=() items=() key="" idx
    shift 3
    if [ "$GUI" = "1" ]; then
        key=$(dlg_menu "$text" "$ok" "$column" "$@") || return 1
    else
        while [ $# -ge 2 ]; do
            keys+=("$1")
            items+=("$2" "$2")
            shift 2
        done
        idx=$(shell_menu "$text" "${items[@]}") || return 1
        [ -z "$idx" ] || key="${keys[$idx]}"
    fi
    [ -n "$key" ] || return 1
    echo "$key"
}

# ui_entry <title> <text> [<prefill>] — prints the entered text; fails on
# cancel or EOF. The terminal prompt shows only <text>.
ui_entry() {
    local answer
    if [ "$GUI" = "1" ]; then
        dlg_entry "$@"
        return
    fi
    read -rp "$2 " answer || return 1
    echo "$answer"
}

# ui_confirm <text> <ok-label> — asks a yes/no question; succeeds on yes
ui_confirm() {
    local answer
    if [ "$GUI" = "1" ]; then
        dlg_question "$1" "$2"
        return
    fi
    echo "$1" >&2
    read -rp "$T_CONFIRM" answer || return 1
    [[ "$answer" =~ ^[jJyY] ]]
}

# say <text> — an error or notice as a dialog or on stderr
say() {
    if [ "$GUI" = "1" ]; then
        dlg_error "$1" || true
    else
        echo "$1" >&2
    fi
}

# --- Locate the claude binary ---
find_claude_bin() {
    if [ -n "${CC_PICKER_BIN:-}" ]; then
        echo "$CC_PICKER_BIN"
        return 0
    fi
    if command -v claude >/dev/null 2>&1; then
        command -v claude
        return 0
    fi
    local candidates=(
        "$HOME/.local/bin/claude"
        "$HOME/.npm-global/bin/claude"
        "/usr/local/bin/claude"
        "/usr/bin/claude"
    )
    local c
    for c in "${candidates[@]}"; do
        [ -x "$c" ] && { echo "$c"; return 0; }
    done
    return 1
}

# --- Locate a terminal emulator ---
find_terminal() {
    local t terms=("gnome-terminal" "konsole" "xfce4-terminal" "alacritty" "kitty" "xterm")
    for t in "${terms[@]}"; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return 0; }
    done
    return 1
}
# --- Detect the user's login shell (bash, zsh, fish, ...) ---
find_user_shell() {
    if [ -n "${CC_PICKER_SHELL:-}" ]; then
        echo "$CC_PICKER_SHELL"
        return 0
    fi
    local passwd_shell
    passwd_shell=$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f7)
    if [ -n "$passwd_shell" ] && [ -x "$passwd_shell" ]; then
        echo "$passwd_shell"
        return 0
    fi
    if [ -n "${SHELL:-}" ] && [ -x "$SHELL" ]; then
        echo "$SHELL"
        return 0
    fi
    echo "/bin/bash"
}
# --- Graphical editor for "Open in editor": CC_PICKER_EDITOR (a command,
# optionally with options, e.g. "code -n"), else the first one found ---
find_editor() {
    if [ -n "${CC_PICKER_EDITOR:-}" ]; then
        echo "$CC_PICKER_EDITOR"
        return 0
    fi
    local e
    for e in code codium zed subl; do
        command -v "$e" >/dev/null 2>&1 && { echo "$e"; return 0; }
    done
    return 1
}
# detect_tools — finds the dialog tool, icon, terminal, shell, editor and
# timeout command; settings take precedence
detect_tools() {
    DIALOG="${CC_PICKER_DIALOG:-$(find_dialog || echo "")}"
    ICON="$(find_icon || echo "")"
    # NUL-separated, so option values may contain spaces
    mapfile -d '' ICON_ARGS < <(icon_args)
    TERMINAL_BIN="${CC_PICKER_TERMINAL:-$(find_terminal || echo "")}"
    USER_SHELL="$(find_user_shell)"
    EDITOR_CMD="$(find_editor || echo "")"
    TIMEOUT=()
    if command -v timeout >/dev/null 2>&1; then TIMEOUT=(timeout 2); fi
}

# open_terminal <dir> <command> [args...] — runs the command in a new
# terminal window, then keeps the user's shell open in <dir>
open_terminal() {
    local dir="$1"; shift
    local full_cmd
    # %q-quote everything so paths with spaces or quotes survive `bash -c`;
    # exec the user's shell afterwards so the terminal stays open in <dir>
    # once claude exits
    full_cmd="$(printf '%q ' "$@"); exec $(printf '%q' "$USER_SHELL")"
    case "$TERMINAL_BIN" in
        gnome-terminal)   gnome-terminal --working-directory="$dir" -- bash -c "$full_cmd" ;;
        konsole)          konsole --workdir "$dir" -e bash -c "$full_cmd" ;;
        xfce4-terminal)   xfce4-terminal --working-directory="$dir" -x bash -c "$full_cmd" ;;
        alacritty)        alacritty --working-directory "$dir" -e bash -c "$full_cmd" ;;
        kitty)            kitty --directory "$dir" bash -c "$full_cmd" ;;
        xterm)            (cd "$dir" && xterm -e bash -c "$full_cmd") ;;
        *)                echo "$T_NO_TERMINAL" >&2; return 1 ;;
    esac
}

# --- Recently used projects: "<epoch> <path>" lines, newest first ---
# Stored locally only. Lines from cc-picker 0.2 hold a bare name, which is
# resolved against the first projects folder.

# read_recent — prints "<epoch>\t<path>" lines
read_recent() {
    local ts rest
    [ -f "$RECENT_FILE" ] || return 0
    while read -r ts rest; do
        [ -n "$rest" ] || continue
        case "$rest" in /*) ;; *) rest="$BASE/$rest" ;; esac
        printf '%s\t%s\n' "$ts" "$rest"
    done < "$RECENT_FILE"
}

mark_used() {
    local tmp
    mkdir -p "$STATE_DIR"
    tmp="$(mktemp "$RECENT_FILE.XXXXXX")"
    {
        printf '%s %s\n' "$(date +%s)" "$1"
        read_recent | P="$1" awk -F'\t' '$2 != ENVIRON["P"] { print $1 " " $2 }'
    } | awk -v max="$RECENT_MAX" 'NR <= max' > "$tmp"
    mv "$tmp" "$RECENT_FILE"
}

# --- Pinned projects: one path per line, listed before all others ---
declare -A PINNED=()
load_pins() {
    local line
    PINNED=()
    [ -f "$PINNED_FILE" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] && PINNED[$line]=1
    done < "$PINNED_FILE"
    return 0
}

is_pinned() { [ -n "${PINNED[$1]:-}" ]; }

toggle_pin() {
    load_pins
    mkdir -p "$STATE_DIR"
    if is_pinned "$1"; then
        rewrite_state "$1" "" pinned
    else
        printf '%s\n' "$1" >> "$PINNED_FILE"
    fi
}

# rewrite_state <old-path> <new-path> [pinned] — updates the recent and
# pinned lists after a rename; an empty <new-path> removes the entry. With
# "pinned", only the pinned list is changed.
rewrite_state() {
    local tmp
    if [ "${3:-}" != "pinned" ] && [ -f "$RECENT_FILE" ]; then
        tmp="$(mktemp "$RECENT_FILE.XXXXXX")"
        read_recent | O="$1" N="$2" awk -F'\t' '
            $2 == ENVIRON["O"] { if (ENVIRON["N"] == "") next; print $1 " " ENVIRON["N"]; next }
            { print $1 " " $2 }' > "$tmp"
        mv "$tmp" "$RECENT_FILE"
    fi
    if [ -f "$PINNED_FILE" ]; then
        tmp="$(mktemp "$PINNED_FILE.XXXXXX")"
        O="$1" N="$2" awk '
            $0 == ENVIRON["O"] { if (ENVIRON["N"] == "") next; print ENVIRON["N"]; next }
            { print }' "$PINNED_FILE" > "$tmp"
        mv "$tmp" "$PINNED_FILE"
    fi
}

# ago <epoch> — prints a short relative time
ago() {
    local d=$(( $(date +%s) - $1 ))
    if   [ "$d" -lt 60 ];     then printf '%s' "$T_AGO_NOW"
    elif [ "$d" -lt 3600 ];   then printf "$T_AGO_MIN" $(( d / 60 ))
    elif [ "$d" -lt 86400 ];  then printf "$T_AGO_HOUR" $(( d / 3600 ))
    elif [ "$d" -lt 172800 ]; then printf '%s' "$T_AGO_YESTERDAY"
    else                           printf "$T_AGO_DAYS" $(( d / 86400 ))
    fi
}

# join_details <text>... — joins the non-empty arguments with " · "
join_details() {
    local out="" part
    for part in "$@"; do
        [ -n "$part" ] || continue
        if [ -n "$out" ]; then out="$out · $part"; else out="$part"; fi
    done
    printf '%s' "$out"
}

# git_info <dir> — prints "<branch>" or "<branch> · <n> changed" for Git
# repositories; nothing for other folders, on errors or after 2 seconds
# (TIMEOUT is set by detect_tools)
git_info() {
    local out branch n
    [ "$GIT_STATUS" = "1" ] && [ -e "$1/.git" ] || return 0
    command -v git >/dev/null 2>&1 || return 0
    out="$(GIT_OPTIONAL_LOCKS=0 "${TIMEOUT[@]}" git -C "$1" status --porcelain=v1 -b 2>/dev/null)" || return 0
    branch="${out%%$'\n'*}"
    branch="${branch#\#\# }"
    case "$branch" in
        "No commits yet on "*) branch="${branch#No commits yet on }" ;;
        "Initial commit on "*) branch="${branch#Initial commit on }" ;;
        "HEAD (no branch)"*)   branch="$T_GIT_DETACHED" ;;
    esac
    branch="${branch%%...*}"
    branch="${branch%% \[*}"
    n=$(( $(printf '%s\n' "$out" | wc -l) - 1 ))
    if [ "$n" -gt 0 ]; then
        join_details "$branch" "$(printf "$T_GIT_CHANGED" "$n")"
    else
        printf '%s' "$branch"
    fi
}

# in_bases <path> — succeeds if <path> lies directly inside one of the
# projects folders
in_bases() {
    local b dir="${1%/*}"
    for b in "${BASES[@]}"; do
        [ "$dir" = "$b" ] && return 0
    done
    return 1
}

# label_for <path> — the project's name; projects from further projects
# folders get that folder's name as prefix, e.g. "code/my-app"
label_for() {
    local dir="${1%/*}"
    if [ "$dir" = "$BASE" ]; then
        printf '%s' "${1##*/}"
    else
        printf '%s/%s' "${dir##*/}" "${1##*/}"
    fi
}

# A project name must be a single, plain folder name inside a projects
# folder: no "/", no control characters (tabs and newlines would break the
# list formats), no leading "." or "-", no leading or trailing whitespace
valid_name() {
    case "$1" in
        ""|.*|-*|*/*|*[[:cntrl:]]*|[[:space:]]*|*[[:space:]]) return 1 ;;
    esac
}

# collect_projects — fills the P_* arrays: pinned projects first, then the
# recently used ones, then the rest alphabetically per projects folder.
# Must run in the current shell (not in $(...)).
P_PATH=() P_LABEL=() P_TS=() P_GIT=()
SHOW_GIT=0
collect_projects() {
    local ts path name base pass
    local ordered=()
    declare -A seen=() ts_of=()
    P_PATH=() P_LABEL=() P_TS=() P_GIT=()
    SHOW_GIT=0
    load_pins
    while IFS=$'\t' read -r ts path; do
        [ -z "${seen[$path]:-}" ] || continue
        if [ ! -d "$path" ] || ! in_bases "$path" || ! valid_name "${path##*/}"; then
            continue
        fi
        seen[$path]=1
        ts_of[$path]="$ts"
        ordered+=("$path")
    done < <(read_recent)
    for base in "${BASES[@]}"; do
        [ -d "$base" ] || continue
        # NUL-separated, so no folder name can split into two entries; names
        # with control characters (created outside cc-picker) are skipped
        while IFS= read -r -d '' name; do
            case "$name" in *[[:cntrl:]]*) continue ;; esac
            path="$base/$name"
            [ -z "${seen[$path]:-}" ] || continue
            seen[$path]=1
            ts_of[$path]=0
            ordered+=("$path")
        done < <(find "$base" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\0' | sort -z)
    done
    for pass in pinned rest; do
        for path in "${ordered[@]}"; do
            if is_pinned "$path"; then
                [ "$pass" = "pinned" ] || continue
            else
                [ "$pass" = "rest" ] || continue
            fi
            P_PATH+=("$path")
            P_LABEL+=("$(label_for "$path")")
            P_TS+=("${ts_of[$path]}")
            P_GIT+=("$(git_info "$path")")
            [ -z "${P_GIT[-1]}" ] || SHOW_GIT=1
        done
    done
    return 0
}

# display_label <index> — the label, with a star for pinned projects
display_label() {
    if is_pinned "${P_PATH[$1]}"; then
        printf '★ %s' "${P_LABEL[$1]}"
    else
        printf '%s' "${P_LABEL[$1]}"
    fi
}

last_used() {
    [ "${P_TS[$1]}" = "0" ] || ago "${P_TS[$1]}"
}

# shell_row <index> — one line of the terminal menu
shell_row() {
    local detail
    detail="$(join_details "$(last_used "$1")" "${P_GIT[$1]}")"
    if [ -n "$detail" ]; then
        printf '%s   (%s)' "$(display_label "$1")" "$detail"
    else
        display_label "$1"
    fi
}

# resolve_project <query> — prints the path of the project named <query>:
# "-" is the most recently used one; otherwise the exact name, then a
# unique beginning of a name (case-insensitive)
resolve_project() {
    local query="$1" i matches=() lower best="" best_ts=0
    collect_projects
    if [ "$query" = "-" ]; then
        for i in "${!P_PATH[@]}"; do
            if [ "${P_TS[$i]}" -gt "$best_ts" ]; then
                best="${P_PATH[$i]}"
                best_ts="${P_TS[$i]}"
            fi
        done
        [ -n "$best" ] || { echo "cc-picker: $T_NO_RECENT" >&2; return 1; }
        echo "$best"
        return 0
    fi
    for i in "${!P_PATH[@]}"; do
        [ "${P_LABEL[$i]}" = "$query" ] && { echo "${P_PATH[$i]}"; return 0; }
    done
    for i in "${!P_PATH[@]}"; do
        [ "${P_PATH[$i]##*/}" = "$query" ] && matches+=("$i")
    done
    if [ "${#matches[@]}" -eq 0 ]; then
        lower="${query,,}"
        for i in "${!P_PATH[@]}"; do
            if [[ "${P_LABEL[$i],,}" == "$lower"* || "${P_PATH[$i]##*/}" == "$query"* ]]; then
                matches+=("$i")
            fi
        done
    fi
    case "${#matches[@]}" in
        0) printf "cc-picker: $T_NOT_FOUND\n" "$query" >&2; return 1 ;;
        1) echo "${P_PATH[${matches[0]}]}" ;;
        *) printf "cc-picker: $T_AMBIGUOUS\n" "$query" >&2
           for i in "${matches[@]}"; do echo "  ${P_LABEL[$i]}" >&2; done
           return 1 ;;
    esac
}

# --- Claude sessions ---
# Claude Code keeps a project's sessions in <config>/projects/<path>, with
# every character other than A-Z, a-z and 0-9 replaced by "-".
has_sessions() {
    local dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/${1//[^a-zA-Z0-9]/-}"
    [ -d "$dir" ] && [ -n "$(find "$dir" -maxdepth 1 -name '*.jsonl' -print -quit 2>/dev/null)" ]
}

# choose_session <path> — prints new, continue or resume. Asks only if
# CC_PICKER_SESSION is "ask" and the project already has a session.
choose_session() {
    local path="$1" text
    case "$SESSION_MODE" in
        new) echo new; return 0 ;;
        continue|resume|ask) ;;
        *) SESSION_MODE=ask ;;
    esac
    has_sessions "$path" || { echo new; return 0; }
    [ "$SESSION_MODE" = "ask" ] || { echo "$SESSION_MODE"; return 0; }
    text="$(printf "$T_SESSION_TEXT" "$(label_for "$path")")"
    ui_menu "$text" "$T_BTN_START" "$T_COL_START" \
        new "$T_SESSION_NEW" continue "$T_SESSION_CONTINUE" resume "$T_SESSION_RESUME"
}

# launch <path> <new|continue|resume> <here|terminal> — starts claude in
# <path>: "here" replaces this process, "terminal" opens a new window
launch() {
    local path="$1" mode="$2" where="$3" args=()
    case "$mode" in
        continue) args=(--continue) ;;
        resume)   args=(--resume) ;;
    esac
    mark_used "$path"
    if [ "$where" = "here" ]; then
        cd "$path" || exit 1
        exec "$CLAUDE_BIN" "${args[@]}"
    fi
    open_terminal "$path" "$CLAUDE_BIN" "${args[@]}"
}

# --- New projects ---

# expand_clone_url <text> — the GitHub shorthand "user/repo" becomes
# https://github.com/user/repo.git; anything else is returned unchanged
expand_clone_url() {
    if [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]+$ ]] && [ ! -e "$1" ]; then
        printf 'https://github.com/%s.git' "${1%.git}"
    else
        printf '%s' "$1"
    fi
}

# clone <url> <target> — shows progress in a dialog in GUI mode; reports
# a failure itself
clone() {
    local url="$1" target="$2" err pid rc=0
    if [ "$GUI" = "0" ]; then
        git clone -- "$url" "$target" >&2 && return 0
        say "$T_CLONE_FAIL $url"
        return 1
    fi
    err="$(mktemp)"
    git clone -- "$url" "$target" >/dev/null 2>"$err" &
    pid=$!
    dlg_busy "$(printf "$T_CLONING" "$url")" "$pid"
    wait "$pid" || rc=$?
    [ "$rc" = "0" ] || say "$T_CLONE_FAIL $url
$(grep -m1 '^fatal:' "$err" || tail -n1 "$err")"
    rm -f "$err"
    return "$rc"
}

# list_templates — prints the template names, NUL-separated
list_templates() {
    [ -d "$TEMPLATE_DIR" ] || return 0
    find "$TEMPLATE_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\0' | sort -z
}

# choose_template — prints the chosen template name, or nothing for an
# empty folder; asks only if there are templates
choose_template() {
    local templates=() items=() idx key
    mapfile -d '' templates < <(list_templates)
    [ "${#templates[@]}" -gt 0 ] || return 0
    items=(empty "$T_TEMPLATE_EMPTY")
    for idx in "${!templates[@]}"; do
        items+=("t$idx" "$(printf "$T_TEMPLATE_ITEM" "${templates[$idx]}")")
    done
    key=$(ui_menu "$T_TEMPLATE_TEXT" "$T_BTN_NEXT" "$T_COL_TEMPLATE" "${items[@]}") || return 1
    [ "$key" = "empty" ] || echo "${templates[${key#t}]}"
    return 0
}

# apply_template <template> <target> <name> — copies the template, fills in
# {{PROJECT_NAME}} in its text files and runs git init
apply_template() {
    local src="$TEMPLATE_DIR/$1" target="$2" name="$3" f content
    cp -a "$src/." "$target/"
    while IFS= read -r -d '' f; do
        grep -qIF '{{PROJECT_NAME}}' "$f" || continue
        content="$(cat "$f"; printf x)"
        content="${content%x}"
        printf '%s' "${content//"{{PROJECT_NAME}}"/"$name"}" > "$f"
    done < <(find "$target" -type f ! -path "$target/.git/*" -print0)
    if command -v git >/dev/null 2>&1 && [ ! -e "$target/.git" ]; then
        git -C "$target" init -q >&2 || true
    fi
}

# create_project <name> <clone-url> <template> — prints the path
create_project() {
    local target="$BASE/$1" clone_url="$2" template="$3"
    if [ -n "$clone_url" ]; then
        clone "$clone_url" "$target" || return 1
    else
        mkdir -p "$target"
        [ -z "$template" ] || apply_template "$template" "$target" "$1"
    fi
    echo "$target"
}

# ask_new_name <title> <text> <dir> [<prefill>] — asks until the name is
# valid and not taken in <dir>; prints it
ask_new_name() {
    local title="$1" text="$2" dir="$3" prefill="${4:-}" name
    while true; do
        name=$(ui_entry "$title" "$text" "$prefill") || return 1
        [ -z "$name" ] && return 1
        if ! valid_name "$name"; then
            say "$T_BAD_NAME"
        elif [ -e "$dir/$name" ]; then
            say "$(printf "$T_EXISTS" "$name")"
        else
            echo "$name"
            return 0
        fi
    done
}

# new_project — asks for name, Git URL and template; prints the path of
# the new project
new_project() {
    local new_name clone_url template="" prompt="$T_CLONE_SHELL"
    new_name=$(ask_new_name "$T_NEW_TITLE" "$T_NEW_NAME" "$BASE") || return 1
    # Cancel/Ctrl+D aborts; an empty answer means "new project, no clone"
    [ "$GUI" = "0" ] || prompt="$T_CLONE_GUI"
    clone_url=$(ui_entry "$T_CLONE_TITLE" "$prompt") || return 1
    clone_url="$(expand_clone_url "$clone_url")"
    if [ -z "$clone_url" ]; then
        template=$(choose_template) || return 1
    fi
    create_project "$new_name" "$clone_url" "$template"
}

# --- Managing projects ---

# run_detached <command>... — starts a GUI program without waiting for it
run_detached() {
    if command -v setsid >/dev/null 2>&1; then
        setsid -f "$@" >/dev/null 2>&1 < /dev/null || true
    else
        ("$@" >/dev/null 2>&1 < /dev/null &)
    fi
}

# list_archived — prints the paths of archived projects, NUL-separated.
# Each projects folder has its own archive folder.
list_archived() {
    local b
    for b in "${BASES[@]}"; do
        [ -d "$b/$ARCHIVE_NAME" ] || continue
        find "$b/$ARCHIVE_NAME" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -print0 | sort -z
    done
}


# project_action <key> <path> — runs one of the manage actions
project_action() {
    local key="$1" path="$2" name new_name target editor=()
    name="${path##*/}"
    case "$key" in
        files)
            run_detached xdg-open "$path" ;;
        editor)
            read -ra editor <<< "$EDITOR_CMD"
            run_detached "${editor[@]}" "$path" ;;
        pin)
            toggle_pin "$path" ;;
        rename)
            new_name=$(ask_new_name "$T_ACT_RENAME" "$(printf "$T_RENAME_TEXT" "$name")" \
                           "${path%/*}" "$name") || return 0
            mv -- "$path" "${path%/*}/$new_name"
            rewrite_state "$path" "${path%/*}/$new_name" ;;
        archive)
            target="${path%/*}/$ARCHIVE_NAME/$name"
            [ ! -e "$target" ] || target="$target-$(date +%Y%m%d-%H%M%S)"
            ui_confirm "$(printf "$T_ARCHIVE_ASK" "$name" "$target")" "$T_ACT_ARCHIVE" || return 0
            mkdir -p "${target%/*}"
            mv -- "$path" "$target"
            rewrite_state "$path" "" ;;
    esac
}

# manage_project <path> — shows the actions for one project
manage_project() {
    local path="$1" items=() key text
    load_pins
    if command -v xdg-open >/dev/null 2>&1; then
        items+=(files "$T_ACT_FILES")
    fi
    if [ -n "$EDITOR_CMD" ]; then
        items+=(editor "$(printf "$T_ACT_EDITOR" "${EDITOR_CMD%% *}")")
    fi
    if is_pinned "$path"; then items+=(pin "$T_ACT_UNPIN"); else items+=(pin "$T_ACT_PIN"); fi
    items+=(rename "$T_ACT_RENAME" archive "$T_ACT_ARCHIVE")
    text="$(printf "$T_MANAGE_TEXT" "$(label_for "$path")")"
    key=$(ui_menu "$text" "$T_BTN_OK" "$T_COL_ACTION" "${items[@]}") || return 0
    project_action "$key" "$path"
}

# restore_project — moves an archived project back
restore_project() {
    local archived=() items=() i key path target
    mapfile -d '' archived < <(list_archived)
    [ "${#archived[@]}" -gt 0 ] || return 0
    for i in "${!archived[@]}"; do
        path="${archived[$i]}"
        items+=("a$i" "$(label_for "${path%/*/*}/${path##*/}")")
    done
    key=$(ui_menu "$T_RESTORE_PICK" "$T_BTN_OK" "$T_COL_PROJECT" "${items[@]}") || return 0
    path="${archived[${key#a}]}"
    target="${path%/*/*}/${path##*/}"
    if [ -e "$target" ]; then
        say "$(printf "$T_EXISTS" "${path##*/}")"
        return 0
    fi
    mv -- "$path" "$target"
}

# manage — pick a project (or the archive), then an action. Uses the P_*
# arrays filled by the caller.
manage() {
    local items=() i key
    for i in "${!P_PATH[@]}"; do
        items+=("p$i" "$(display_label "$i")")
    done
    if [ -n "$(list_archived | head -c1)" ]; then
        items+=(restore "$T_ACT_RESTORE")
    fi
    [ "${#items[@]}" -gt 0 ] || return 0
    key=$(ui_menu "$T_MANAGE_PICK" "$T_BTN_NEXT" "$T_COL_PROJECT" "${items[@]}") || return 0
    case "$key" in
        restore) restore_project ;;
        p*)      manage_project "${P_PATH[${key#p}]}" ;;
    esac
    return 0
}

# --- Self-update ---
# Installs the newest tagged release (or main, if there are no tags yet) of
# UPDATE_REPO with its install.sh, if its version is newer than this one.
UPDATE_TMP=""
self_update() {
    local tag new_version newest ref=()
    command -v git >/dev/null 2>&1 || { echo "cc-picker: $T_UPD_NO_GIT" >&2; exit 1; }
    printf "$T_UPD_CHECK\n" "$UPDATE_REPO" >&2
    tag="$(git ls-remote --tags --refs -- "$UPDATE_REPO" 2>/dev/null \
            | awk -F/ '{ print $NF }' | grep -E '^v?[0-9]+(\.[0-9]+)*$' | sort -V | tail -n1)" || true
    [ -z "$tag" ] || ref=(--branch "$tag")
    UPDATE_TMP="$(mktemp -d)"
    trap 'rm -rf "$UPDATE_TMP"' EXIT
    if ! git -c advice.detachedHead=false clone -q --depth 1 "${ref[@]}" -- "$UPDATE_REPO" "$UPDATE_TMP/cc-picker" >&2; then
        echo "cc-picker: $T_UPD_FAIL git clone $UPDATE_REPO" >&2
        exit 1
    fi
    new_version="$(sed -n 's/^VERSION="\(.*\)"$/\1/p' "$UPDATE_TMP/cc-picker/cc-picker.sh" | head -n1)"
    if [ -z "$new_version" ] || [ ! -f "$UPDATE_TMP/cc-picker/install.sh" ]; then
        echo "cc-picker: $T_UPD_FAIL $UPDATE_REPO" >&2
        exit 1
    fi
    newest="$(printf '%s\n%s\n' "$VERSION" "$new_version" | sort -V | tail -n1)"
    if [ "$newest" = "$VERSION" ]; then
        printf "$T_UPD_CURRENT\n" "$VERSION"
        exit 0
    fi
    printf "$T_UPD_INSTALL\n\n" "$VERSION" "$new_version"
    bash "$UPDATE_TMP/cc-picker/install.sh"
}

# --- Project list: window ---
# Opens a new terminal with claude in the chosen (or newly created) project.
run_gui() {
    local rows=() pad=() key path mode i n query="" matched
    GUI=1
    while true; do
        collect_projects
        n="${#P_PATH[@]}"
        # every row needs a value per column: key, name, last used [, git]
        pad=("")
        [ "$SHOW_GIT" = "0" ] || pad+=("")
        rows=(new "$T_NEW_ENTRY" "${pad[@]}")
        [ "$n" -eq 0 ] || rows+=(manage "$T_MANAGE_ENTRY" "${pad[@]}")
        if [ -n "$query" ]; then
            rows+=(all "$T_SHOW_ALL" "${pad[@]}")
        elif [ "$n" -ge "$SEARCH_MIN" ]; then
            rows+=(search "$T_SEARCH_ENTRY" "${pad[@]}")
        fi
        matched=0
        for i in "${!P_PATH[@]}"; do
            [ -z "$query" ] || [[ "${P_LABEL[$i],,}" == *"${query,,}"* ]] || continue
            rows+=("p$i" "$(display_label "$i")" "$(last_used "$i")")
            [ "$SHOW_GIT" = "0" ] || rows+=("${P_GIT[$i]}")
            matched=$((matched + 1))
        done
        if [ -n "$query" ] && [ "$matched" -eq 0 ]; then
            dlg_info "$(printf "$T_NO_MATCH" "$query")" || true
            query=""
            continue
        fi

        key=$(dlg_projects "${rows[@]}") || exit 0
        case "$key" in
            new)    path=$(new_project) || continue
                    mode=new ;;
            manage) manage; continue ;;
            all)    query=""; continue ;;
            search) query=$(dlg_entry "$T_SEARCH_TITLE" "$T_SEARCH_TEXT") || query=""
                    continue ;;
            p*)     path="${P_PATH[${key#p}]}"
                    mode=$(choose_session "$path") || continue ;;
            *)      exit 0 ;;
        esac
        launch "$path" "$mode" terminal
        exit 0
    done
}

# --- Project list: terminal menu ---
# Replaces this process with claude in the chosen (or newly created) project.
run_shell() {
    local items=() idx n path mode i
    GUI=0
    while true; do
        collect_projects
        n="${#P_PATH[@]}"
        # typed text filters on the project name only, not on the details
        items=()
        for i in "${!P_PATH[@]}"; do items+=("$(shell_row "$i")" "${P_LABEL[$i]}"); done
        items+=("$T_NEW_ENTRY" "$T_NEW_ENTRY")
        [ "$n" -eq 0 ] || items+=("$T_MANAGE_ENTRY" "$T_MANAGE_ENTRY")

        # EOF (Ctrl+D) or Esc in fzf is a normal way to quit
        idx=$(shell_menu "$T_SHELL_HEADER" "${items[@]}") || idx=""
        if [ -z "$idx" ]; then
            echo >&2
            exit 0
        fi
        if [ "$idx" -lt "$n" ]; then
            path="${P_PATH[$idx]}"
            mode=$(choose_session "$path") || continue
        elif [ "$idx" -eq "$n" ]; then
            path=$(new_project) || continue
            mode=new
        else
            manage
            continue
        fi
        launch "$path" "$mode" here
    done
}

# Shell mode: in place when we have a terminal, else in a new terminal window
start_shell_mode() {
    if [ -t 0 ] || [ -z "$TERMINAL_BIN" ]; then
        run_shell
    else
        open_terminal "$BASE" "$SELF" --shell-mode
    fi
}

# start_project <query> — starts claude right in the project named <query>:
# in place when we have a terminal, else in a new terminal window
start_project() {
    local path mode
    if ! path="$(resolve_project "$1")"; then
        [ -t 0 ] || dlg_error "$(printf "$T_NOT_FOUND" "$1")" 2>/dev/null || true
        exit 1
    fi
    [ -t 0 ] || [ -z "$DIALOG" ] || GUI=1
    mode=$(choose_session "$path") || exit 0
    if [ -t 0 ] || [ -z "$TERMINAL_BIN" ]; then
        launch "$path" "$mode" here
    else
        launch "$path" "$mode" terminal
    fi
}

# --- Main ---
main() {
    local mode
    load_config
    load_messages
    init_settings
    parse_args "$@"

    if [ "$DO_UPDATE" = "1" ]; then
        self_update
        exit 0
    fi

    detect_tools
    CLAUDE_BIN="$(find_claude_bin)" || {
        dlg_error "$T_NO_CLAUDE" 2>/dev/null \
            || echo "cc-picker: $T_NO_CLAUDE" >&2
        exit 1
    }
    mkdir -p "$BASE"

    # A project on the command line → start right there; --shell-mode →
    # terminal menu in place; no dialog tool or terminal → terminal menu;
    # otherwise as set in CC_PICKER_MODE (default: project list window)
    if [ "$HAVE_PROJECT" = "1" ]; then
        start_project "$PROJECT_ARG"
        exit 0
    fi
    if [ "$SHELL_MODE" = "1" ]; then
        run_shell
        exit 0
    fi
    if [ -z "$DIALOG" ] || [ -z "$TERMINAL_BIN" ]; then
        start_shell_mode
        exit 0
    fi

    case "$START_MODE" in
        shell) start_shell_mode ;;
        ask)
            mode=$(dlg_menu "$T_PICK_MODE" "$T_BTN_NEXT" "$T_COL_MODE" \
                       gui "$T_MODE_GUI" shell "$T_MODE_SHELL") || exit 0
            case "$mode" in
                gui)   run_gui ;;
                shell) start_shell_mode ;;
                *)     exit 0 ;;
            esac ;;
        *) run_gui ;;
    esac
}

main "$@"
