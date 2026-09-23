#!/bin/bash
# cc-picker — project picker & launcher for Claude Code
# https://github.com/bruneler/cc-picker
#
# Not affiliated with or endorsed by Anthropic. "Claude" is a trademark
# of Anthropic, PBC. This tool simply launches the `claude` CLI in a
# chosen project directory.

set -euo pipefail

BASE="${CC_PICKER_BASE:-$HOME/Entwicklung/claude-code}"

# --- UI language: German for de_* locales, English otherwise ---
UI_LANG="${CC_PICKER_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
case "$UI_LANG" in
    de*)
        T_NEW_ENTRY="+ Neues Projekt erstellen"
        T_NO_CLAUDE="claude wurde nicht gefunden. Bitte CC_PICKER_BIN setzen oder claude installieren."
        T_NO_TERMINAL="Kein unterstütztes Terminal gefunden. Bitte CC_PICKER_TERMINAL setzen."
        T_NEW_TITLE="Neues Projekt"
        T_NEW_NAME="Name des neuen Projektordners:"
        T_CLONE_TITLE="Git-Repo (optional)"
        T_CLONE_GUI="Git-Remote-URL zum Klonen, oder leer lassen für leeren Ordner:"
        T_CLONE_SHELL="Git-Remote-URL zum Klonen (leer lassen für leeren Ordner):"
        T_PICK_PROJECT="In welchem Projekt starten?"
        T_COL_PROJECT="Projekt"
        T_SHELL_HEADER="cc-picker — Projekt wählen:"
        T_INVALID="Ungültige Auswahl, nochmal."
        T_PICK_MODE="Wie möchtest du das Projekt auswählen?"
        T_COL_MODE="Modus"
        ;;
    *)
        T_NEW_ENTRY="+ Create new project"
        T_NO_CLAUDE="claude not found. Please set CC_PICKER_BIN or install claude."
        T_NO_TERMINAL="No supported terminal emulator found. Please set CC_PICKER_TERMINAL."
        T_NEW_TITLE="New project"
        T_NEW_NAME="Name of the new project folder:"
        T_CLONE_TITLE="Git repo (optional)"
        T_CLONE_GUI="Git remote URL to clone, or leave empty for an empty folder:"
        T_CLONE_SHELL="Git remote URL to clone (leave empty for an empty folder):"
        T_PICK_PROJECT="Which project do you want to start in?"
        T_COL_PROJECT="Project"
        T_SHELL_HEADER="cc-picker — choose a project:"
        T_INVALID="Invalid choice, try again."
        T_PICK_MODE="How do you want to choose the project?"
        T_COL_MODE="Mode"
        ;;
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

# dlg_list <text> <column> <item>... — prints the chosen item
dlg_list() {
    local text="$1" column="$2"; shift 2
    local args=() item
    case "$DIALOG" in
        zenity) zenity --list --title="cc-picker" --text="$text" --column="$column" \
                    "$@" --height=350 --width=400 ;;
        yad)    yad --list --title="cc-picker" --text="$text" --column="$column" \
                    "$@" --height=350 --width=400 --print-column=1 --separator="" ;;
        kdialog)
            for item in "$@"; do args+=("$item" "$item"); done
            kdialog --title "cc-picker" --menu "$text" "${args[@]}" ;;
        *) return 1 ;;
    esac
}

# dlg_entry <title> <text> — prints the entered text
dlg_entry() {
    case "$DIALOG" in
        zenity)  zenity --entry --title="$1" --text="$2" ;;
        yad)     yad --entry --title="$1" --text="$2" ;;
        kdialog) kdialog --title "$1" --inputbox "$2" ;;
        *) return 1 ;;
    esac
}

# dlg_error <text>
dlg_error() {
    case "$DIALOG" in
        zenity)  zenity --error --text="$1" ;;
        yad)     yad --title="cc-picker" --image=dialog-error --text="$1" --button=OK ;;
        kdialog) kdialog --title "cc-picker" --error "$1" ;;
        *) return 1 ;;
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

open_terminal() {
    local dir="$1"; shift
    local inner_cmd="$*"
    local full_cmd="$inner_cmd; exec \"$USER_SHELL\""
    case "$TERMINAL_BIN" in
        gnome-terminal)   gnome-terminal --working-directory="$dir" -- bash -c "$full_cmd" ;;
        konsole)          konsole --workdir "$dir" -e bash -c "$full_cmd" ;;
        xfce4-terminal)   xfce4-terminal --working-directory="$dir" -e "bash -c '$full_cmd'" ;;
        alacritty)        alacritty --working-directory "$dir" -e bash -c "$full_cmd" ;;
        kitty)            kitty --directory "$dir" bash -c "$full_cmd" ;;
        xterm)            (cd "$dir" && xterm -e bash -c "$full_cmd") ;;
        *)                echo "$T_NO_TERMINAL"; return 1 ;;
    esac
}

new_project_gui() {
    local new_name target clone_url
    new_name=$(dlg_entry "$T_NEW_TITLE" "$T_NEW_NAME") || return 1
    [ -z "$new_name" ] && return 1
    target="$BASE/$new_name"
    mkdir -p "$target"
    clone_url=$(dlg_entry "$T_CLONE_TITLE" "$T_CLONE_GUI") || true
    [ -n "$clone_url" ] && git clone "$clone_url" "$target"
    echo "$target"
}

new_project_shell() {
    local new_name target clone_url
    read -rp "$T_NEW_NAME " new_name
    [ -z "$new_name" ] && return 1
    target="$BASE/$new_name"
    mkdir -p "$target"
    read -rp "$T_CLONE_SHELL " clone_url
    [ -n "$clone_url" ] && git clone "$clone_url" "$target"
    echo "$target"
}

run_gui() {
    mapfile -t projects < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d | sort)
    names=("$T_NEW_ENTRY")
    for p in "${projects[@]}"; do
        names+=("$(basename "$p")")
    done

    choice=$(dlg_list "$T_PICK_PROJECT" "$T_COL_PROJECT" "${names[@]}") || exit 0

    [ -z "$choice" ] && exit 0

    if [ "$choice" == "$T_NEW_ENTRY" ]; then
        target=$(new_project_gui) || exit 0
    else
        target="$BASE/$choice"
    fi

    open_terminal "$target" "\"$CLAUDE_BIN\""
}

run_shell() {
    mapfile -t projects < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d | sort)

    echo "$T_SHELL_HEADER"
    echo

    options=()
    for p in "${projects[@]}"; do
        options+=("$(basename "$p")")
    done
    options+=("$T_NEW_ENTRY")

    select choice in "${options[@]}"; do
        [ -z "$choice" ] && { echo "$T_INVALID"; continue; }
        if [ "$choice" == "$T_NEW_ENTRY" ]; then
            target=$(new_project_shell) || exit 0
        else
            target="$BASE/$choice"
        fi
        cd "$target" || exit 1
        exec "$CLAUDE_BIN"
    done
}

if [ "${1:-}" == "--shell-mode" ]; then
    run_shell
    exit 0
fi

if [ -n "$DIALOG" ] && [ -n "$TERMINAL_BIN" ]; then
    mode=$(dlg_list "$T_PICK_MODE" "$T_COL_MODE" "GUI" "Shell") || exit 0

    case "$mode" in
        "GUI")   run_gui ;;
        "Shell") open_terminal "$BASE" "\"$0\" --shell-mode" ;;
        *)       exit 0 ;;
    esac
else
    run_shell
fi
