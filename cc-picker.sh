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
# terminal menu) → open a terminal in the chosen folder and start claude.
#
# Convention: functions return values on stdout, which callers capture with
# $(...). All messages, prompts and git output must therefore go to stderr,
# or they would end up in the returned value.
#
# The translated T_* messages are our own constants; some are used as printf
# format strings on purpose (they contain %s/%d placeholders).
# shellcheck disable=SC2059

set -euo pipefail

VERSION="0.2.0"
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/cc-picker/config"
RECENT_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/cc-picker/recent"
RECENT_MAX=50

# --- Config file: KEY=VALUE lines, environment variables take precedence ---
# Parsed, not sourced, and limited to known CC_PICKER_* keys.
load_config() {
    local key value
    [ -f "$CONFIG_FILE" ] || return 0
    while IFS='=' read -r key value || [ -n "$key" ]; do
        key="${key//[[:space:]]/}"
        case "$key" in
            CC_PICKER_BASE|CC_PICKER_BIN|CC_PICKER_TERMINAL|CC_PICKER_SHELL|CC_PICKER_LANG|CC_PICKER_DIALOG|CC_PICKER_MODE) ;;
            *) continue ;;
        esac
        [ -n "${!key:-}" ] && continue
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        value="${value#[\"\']}"
        value="${value%[\"\']}"
        # Expand a leading ~/ or $HOME/ by hand (matched literally on purpose)
        # shellcheck disable=SC2088
        case "$value" in
            "~/"*)      value="$HOME/${value#\~/}" ;;
            "\$HOME/"*) value="$HOME/${value#\$HOME/}" ;;
        esac
        printf -v "$key" '%s' "$value"
    done < "$CONFIG_FILE"
}
load_config

BASE="${CC_PICKER_BASE:-$HOME/claude-projects}"
START_MODE="${CC_PICKER_MODE:-gui}"

# --- UI language: German for de_* locales, English otherwise ---
UI_LANG="${CC_PICKER_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
case "$UI_LANG" in
    de*)
        T_NEW_ENTRY="+ Neues Projekt erstellen"
        T_NO_CLAUDE="claude wurde nicht gefunden. Bitte CC_PICKER_BIN setzen oder claude installieren."
        T_NO_TERMINAL="Kein unterstütztes Terminal gefunden. Bitte CC_PICKER_TERMINAL setzen."
        T_NEW_TITLE="Neues Projekt"
        T_NEW_NAME="Name des neuen Projektordners:"
        T_BAD_NAME="Ungültiger Name. Erlaubt ist ein einfacher Ordnername: kein '/', keine Tabulatoren oder Zeilenumbrüche, nicht mit '.' oder '-' beginnend, keine Leerzeichen am Anfang oder Ende."
        T_CLONE_TITLE="Git-Repo (optional)"
        T_CLONE_GUI="Git-Remote-URL zum Klonen, oder leer lassen für leeren Ordner:"
        T_CLONE_SHELL="Git-Remote-URL zum Klonen (leer lassen für leeren Ordner):"
        T_CLONING="Klone %s …"
        T_CLONE_FAIL="git clone ist fehlgeschlagen:"
        T_PICK_PROJECT="In welchem Projekt starten?"
        T_COL_PROJECT="Projekt"
        T_COL_LAST="Zuletzt"
        T_SHELL_HEADER="cc-picker — Projekt wählen:"
        T_INVALID="Ungültige Auswahl, nochmal."
        T_PICK_MODE="Wie möchtest du das Projekt auswählen?"
        T_COL_MODE="Modus"
        T_MODE_GUI="Projektliste (Fenster)"
        T_MODE_SHELL="Terminal-Menü"
        T_BTN_START="Starten"
        T_BTN_NEXT="Weiter"
        T_BTN_CANCEL="Abbrechen"
        T_BAD_OPTION="Unbekannte Option:"
        T_AGO_NOW="gerade eben"
        T_AGO_MIN="vor %d Min."
        T_AGO_HOUR="vor %d Std."
        T_AGO_YESTERDAY="gestern"
        T_AGO_DAYS="vor %d Tagen"
        ;;
    *)
        T_NEW_ENTRY="+ Create new project"
        T_NO_CLAUDE="claude not found. Please set CC_PICKER_BIN or install claude."
        T_NO_TERMINAL="No supported terminal emulator found. Please set CC_PICKER_TERMINAL."
        T_NEW_TITLE="New project"
        T_NEW_NAME="Name of the new project folder:"
        T_BAD_NAME="Invalid name. Use a plain folder name: no '/', no tabs or line breaks, not starting with '.' or '-', no spaces at the start or end."
        T_CLONE_TITLE="Git repo (optional)"
        T_CLONE_GUI="Git remote URL to clone, or leave empty for an empty folder:"
        T_CLONE_SHELL="Git remote URL to clone (leave empty for an empty folder):"
        T_CLONING="Cloning %s …"
        T_CLONE_FAIL="git clone failed:"
        T_PICK_PROJECT="Which project do you want to start in?"
        T_COL_PROJECT="Project"
        T_COL_LAST="Last used"
        T_SHELL_HEADER="cc-picker — choose a project:"
        T_INVALID="Invalid choice, try again."
        T_PICK_MODE="How do you want to choose the project?"
        T_COL_MODE="Mode"
        T_MODE_GUI="Project list (window)"
        T_MODE_SHELL="Terminal menu"
        T_BTN_START="Start"
        T_BTN_NEXT="Next"
        T_BTN_CANCEL="Cancel"
        T_BAD_OPTION="Unknown option:"
        T_AGO_NOW="just now"
        T_AGO_MIN="%d min ago"
        T_AGO_HOUR="%d h ago"
        T_AGO_YESTERDAY="yesterday"
        T_AGO_DAYS="%d days ago"
        ;;
esac

print_usage() {
    case "$UI_LANG" in
        de*) cat <<EOF
cc-picker $VERSION — Projekt wählen und Claude Code darin starten

Aufruf:
  cc-picker                Projektliste (Fenster)
  cc-picker --shell-mode   Terminal-Menü
  cc-picker --help         diese Hilfe
  cc-picker --version      Version anzeigen

Projektordner: $BASE
Konfiguration: $CONFIG_FILE
               (oder Umgebungsvariablen CC_PICKER_*, siehe README)
EOF
        ;;
        *) cat <<EOF
cc-picker $VERSION — pick a project and launch Claude Code in it

Usage:
  cc-picker                project list (window)
  cc-picker --shell-mode   terminal menu
  cc-picker --help         show this help
  cc-picker --version      show the version

Projects folder: $BASE
Config file:     $CONFIG_FILE
                 (or CC_PICKER_* environment variables, see README)
EOF
        ;;
    esac
}

SHELL_MODE=0
case "${1:-}" in
    "")           ;;
    --shell-mode) SHELL_MODE=1 ;;
    -h|--help)    print_usage; exit 0 ;;
    -V|--version) echo "cc-picker $VERSION"; exit 0 ;;
    *)            echo "cc-picker: $T_BAD_OPTION $1" >&2; print_usage >&2; exit 2 ;;
esac

# --- Dialog tool: zenity (GNOME), kdialog (KDE) or yad, whichever exists ---
find_dialog() {
    local tools=("zenity" "kdialog" "yad")
    for d in "${tools[@]}"; do
        command -v "$d" >/dev/null 2>&1 && { echo "$d"; return 0; }
    done
    return 1
}
DIALOG="${CC_PICKER_DIALOG:-$(find_dialog || echo "")}"

# App icon for dialog windows (installed copy, or the one next to the script)
ICON=""
for i in "${XDG_DATA_HOME:-$HOME/.local/share}/icons/cc-picker.svg" "$(dirname "$SELF")/cc-picker.svg"; do
    [ -f "$i" ] && { ICON="$i"; break; }
done

# Extra options for yad/kdialog windows: app icon if available
# (zenity 4 takes the window icon from the desktop, not from an option)
icon_args() {
    [ -n "$ICON" ] || return 0
    case "$DIALOG" in
        yad)     printf '%s\0' "--window-icon=$ICON" ;;
        kdialog) printf '%s\0' "--icon" "$ICON" ;;
    esac
}
# NUL-separated, so option values may contain spaces
mapfile -d '' ICON_ARGS < <(icon_args)

# dlg_list <text> <ok-label> <column> <item>... — prints the chosen item
dlg_list() {
    local text="$1" ok="$2" column="$3"; shift 3
    local args=() item
    case "$DIALOG" in
        zenity) zenity --list --title="cc-picker" --text="$text" --column="$column" \
                    --ok-label="$ok" --cancel-label="$T_BTN_CANCEL" \
                    "$@" --height=260 --width=360 ;;
        yad)    yad --list --title="cc-picker" "${ICON_ARGS[@]}" --text="$text" --column="$column" \
                    --button="$T_BTN_CANCEL:1" --button="$ok:0" \
                    "$@" --height=260 --width=360 --print-column=1 --separator="" ;;
        kdialog)
            for item in "$@"; do args+=("$item" "$item"); done
            kdialog --title "cc-picker" "${ICON_ARGS[@]}" \
                --ok-label "$ok" --cancel-label "$T_BTN_CANCEL" \
                --menu "$text" "${args[@]}" ;;
        *) return 1 ;;
    esac
}

# dlg_projects <name> <last-used>... — project list with a "last used"
# column; prints the chosen name
dlg_projects() {
    local args=()
    case "$DIALOG" in
        zenity) zenity --list --title="cc-picker" --text="$T_PICK_PROJECT" \
                    --column="$T_COL_PROJECT" --column="$T_COL_LAST" \
                    --ok-label="$T_BTN_START" --cancel-label="$T_BTN_CANCEL" \
                    "$@" --print-column=1 --height=420 --width=460 ;;
        yad)    yad --list --title="cc-picker" "${ICON_ARGS[@]}" --text="$T_PICK_PROJECT" \
                    --column="$T_COL_PROJECT" --column="$T_COL_LAST" \
                    --button="$T_BTN_CANCEL:1" --button="$T_BTN_START:0" \
                    "$@" --print-column=1 --separator="" --height=420 --width=460 ;;
        kdialog)
            while [ $# -gt 0 ]; do
                if [ -n "$2" ]; then args+=("$1" "$1   ($2)"); else args+=("$1" "$1"); fi
                shift 2
            done
            kdialog --title "cc-picker" "${ICON_ARGS[@]}" \
                --ok-label "$T_BTN_START" --cancel-label "$T_BTN_CANCEL" \
                --menu "$T_PICK_PROJECT" "${args[@]}" ;;
        *) return 1 ;;
    esac
}

# dlg_entry <title> <text> — prints the entered text
dlg_entry() {
    case "$DIALOG" in
        zenity)  zenity --entry --title="$1" --text="$2" \
                     --ok-label="$T_BTN_NEXT" --cancel-label="$T_BTN_CANCEL" ;;
        yad)     yad --entry --title="$1" "${ICON_ARGS[@]}" --text="$2" \
                     --button="$T_BTN_CANCEL:1" --button="$T_BTN_NEXT:0" ;;
        kdialog) kdialog --title "$1" "${ICON_ARGS[@]}" \
                     --ok-label "$T_BTN_NEXT" --cancel-label "$T_BTN_CANCEL" \
                     --inputbox "$2" ;;
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
    for c in "${candidates[@]}"; do
        [ -x "$c" ] && { echo "$c"; return 0; }
    done
    return 1
}

CLAUDE_BIN="$(find_claude_bin)" || {
    dlg_error "$T_NO_CLAUDE" 2>/dev/null \
        || echo "cc-picker: $T_NO_CLAUDE" >&2
    exit 1
}

# --- Locate a terminal emulator ---
find_terminal() {
    local terms=("gnome-terminal" "konsole" "xfce4-terminal" "alacritty" "kitty" "xterm")
    for t in "${terms[@]}"; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return 0; }
    done
    return 1
}
TERMINAL_BIN="${CC_PICKER_TERMINAL:-$(find_terminal || echo "")}"

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
USER_SHELL="$(find_user_shell)"

mkdir -p "$BASE"

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
        *)                echo "$T_NO_TERMINAL"; return 1 ;;
    esac
}

# --- Recently used projects: "<epoch> <name>" lines, newest first ---
# Stored locally only; lines for projects that no longer exist are ignored.
mark_used() {
    local name="$1" tmp
    mkdir -p "$(dirname "$RECENT_FILE")"
    tmp="$(mktemp "$RECENT_FILE.XXXXXX")"
    {
        printf '%s %s\n' "$(date +%s)" "$name"
        if [ -f "$RECENT_FILE" ]; then
            awk -v n="$name" '{ t=$1; sub(/^[0-9]+ /, ""); if ($0 != n) print t " " $0 }' "$RECENT_FILE"
        fi
    } | head -n "$RECENT_MAX" > "$tmp"
    mv "$tmp" "$RECENT_FILE"
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

# list_projects — prints "<epoch>\t<name>" for every project folder:
# recently used first, then the rest alphabetically. Epoch 0 means "never
# used" – an empty first field would be swallowed by `read`, because a tab
# counts as whitespace in IFS.
list_projects() {
    local ts name
    declare -A seen=()
    if [ -f "$RECENT_FILE" ]; then
        while read -r ts name; do
            if [ -n "$name" ] && [ -d "$BASE/$name" ] && [ -z "${seen[$name]:-}" ]; then
                seen[$name]=1
                printf '%s\t%s\n' "$ts" "$name"
            fi
        done < "$RECENT_FILE"
    fi
    # NUL-separated, so no folder name can split into two entries; names with
    # control characters (created outside cc-picker) are skipped
    while IFS= read -r -d '' name; do
        case "$name" in *[[:cntrl:]]*) continue ;; esac
        [ -z "${seen[$name]:-}" ] && printf '0\t%s\n' "$name"
    done < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\0' | sort -z)
    return 0
}

# A project name must be a single, plain folder name inside $BASE: no "/",
# no control characters (tabs and newlines would break the list formats),
# no leading "." or "-", no leading or trailing whitespace
valid_name() {
    case "$1" in
        ""|.*|-*|*/*|*[[:cntrl:]]*|[[:space:]]*|*[[:space:]]) return 1 ;;
    esac
}

# clone <url> <target> <gui:0|1> — shows progress in GUI mode
clone() {
    local url="$1" target="$2" gui="$3" err pid rc=0
    if [ "$gui" = "0" ]; then
        git clone "$url" "$target" >&2
        return
    fi
    err="$(mktemp)"
    git clone "$url" "$target" >/dev/null 2>"$err" &
    pid=$!
    dlg_busy "$(printf "$T_CLONING" "$url")" "$pid"
    wait "$pid" || rc=$?
    [ "$rc" = "0" ] || CLONE_ERROR="$(grep -m1 '^fatal:' "$err" || tail -n1 "$err")"
    rm -f "$err"
    return "$rc"
}

# create_project <name> <clone_url> <gui:0|1> — prints the project path
create_project() {
    local target="$BASE/$1" clone_url="$2" gui="$3"
    if [ -n "$clone_url" ]; then
        clone "$clone_url" "$target" "$gui" || return 1
    else
        mkdir -p "$target"
    fi
    echo "$target"
}

new_project_gui() {
    local new_name clone_url
    CLONE_ERROR=""
    while true; do
        new_name=$(dlg_entry "$T_NEW_TITLE" "$T_NEW_NAME") || return 1
        [ -z "$new_name" ] && return 1
        valid_name "$new_name" && break
        dlg_error "$T_BAD_NAME" || true
    done
    # Cancel aborts; an empty field with "Next" means "empty folder"
    clone_url=$(dlg_entry "$T_CLONE_TITLE" "$T_CLONE_GUI") || return 1
    create_project "$new_name" "$clone_url" 1 || {
        dlg_error "$T_CLONE_FAIL $clone_url
$CLONE_ERROR" || true
        return 1
    }
}

new_project_shell() {
    local new_name clone_url
    while true; do
        read -rp "$T_NEW_NAME " new_name || return 1
        [ -z "$new_name" ] && return 1
        valid_name "$new_name" && break
        echo "$T_BAD_NAME" >&2
    done
    # Ctrl+D aborts; an empty line means "empty folder"
    read -rp "$T_CLONE_SHELL " clone_url || return 1
    create_project "$new_name" "$clone_url" 0 || {
        echo "$T_CLONE_FAIL $clone_url" >&2
        return 1
    }
}

# run_gui — project list in a dialog window; opens a new terminal with
# claude in the chosen (or newly created) project
run_gui() {
    local items=("$T_NEW_ENTRY" "") choice target ts name last
    while IFS=$'\t' read -r ts name; do
        last=""
        [ "$ts" != "0" ] && last="$(ago "$ts")"
        items+=("$name" "$last")
    done < <(list_projects)

    choice=$(dlg_projects "${items[@]}") || exit 0
    [ -z "$choice" ] && exit 0

    if [ "$choice" == "$T_NEW_ENTRY" ]; then
        target=$(new_project_gui) || exit 0
    else
        target="$BASE/$choice"
    fi

    mark_used "$(basename "$target")"
    open_terminal "$target" "$CLAUDE_BIN"
}

# run_shell — numbered menu in the current terminal; replaces this process
# with claude in the chosen (or newly created) project
run_shell() {
    local options=() choice target ts name
    while IFS=$'\t' read -r ts name; do
        options+=("$name")
    done < <(list_projects)
    options+=("$T_NEW_ENTRY")

    echo "$T_SHELL_HEADER"
    echo

    # select returns non-zero on EOF (Ctrl+D); that's a normal way to quit
    select choice in "${options[@]}"; do
        [ -z "$choice" ] && { echo "$T_INVALID"; continue; }
        if [ "$choice" == "$T_NEW_ENTRY" ]; then
            target=$(new_project_shell) || exit 0
        else
            target="$BASE/$choice"
        fi
        mark_used "$(basename "$target")"
        cd "$target" || exit 1
        exec "$CLAUDE_BIN"
    done || true
    echo
}

# Shell mode: in place when we have a terminal, else in a new terminal window
start_shell_mode() {
    if [ -t 0 ] || [ -z "$TERMINAL_BIN" ]; then
        run_shell
    else
        open_terminal "$BASE" "$SELF" --shell-mode
    fi
}

# --- Main ---
# --shell-mode → terminal menu in place; no dialog tool or terminal → terminal
# menu; otherwise as set in CC_PICKER_MODE (default: project list window)
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
        mode=$(dlg_list "$T_PICK_MODE" "$T_BTN_NEXT" "$T_COL_MODE" "$T_MODE_GUI" "$T_MODE_SHELL") || exit 0
        case "$mode" in
            "$T_MODE_GUI")   run_gui ;;
            "$T_MODE_SHELL") start_shell_mode ;;
            *)               exit 0 ;;
        esac ;;
    *) run_gui ;;
esac
