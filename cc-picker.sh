#!/bin/bash
# cc-picker — project picker & launcher for Claude Code
# https://github.com/bruneler/cc-picker
#
# Not affiliated with or endorsed by Anthropic. "Claude" is a trademark
# of Anthropic, PBC. This tool simply launches the `claude` CLI in a
# chosen project directory.

set -euo pipefail

BASE="${CC_PICKER_BASE:-$HOME/Entwicklung/claude-code}"
NEW_ENTRY="+ Neues Projekt erstellen"

# --- Claude-Binary automatisch finden ---
find_claude_bin() {
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
    zenity --error --text="claude wurde nicht gefunden. Bitte CC_PICKER_BIN setzen oder claude installieren." 2>/dev/null \
        || echo "Fehler: claude wurde nicht gefunden. Bitte CC_PICKER_BIN setzen oder claude installieren." >&2
    exit 1
}
CLAUDE_BIN="${CC_PICKER_BIN:-$CLAUDE_BIN}"

# --- Terminal-Emulator automatisch finden ---
find_terminal() {
    local terms=("gnome-terminal" "konsole" "xfce4-terminal" "alacritty" "kitty" "xterm")
    for t in "${terms[@]}"; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return 0; }
    done
    return 1
}
TERMINAL_BIN="${CC_PICKER_TERMINAL:-$(find_terminal || echo "")}"

# --- Nutzer-Shell automatisch erkennen (bash, zsh, fish, ...) ---
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
        *)                echo "Kein unterstütztes Terminal gefunden. Bitte CC_PICKER_TERMINAL setzen."; return 1 ;;
    esac
}

new_project_gui() {
    local new_name target clone_url
    new_name=$(zenity --entry --title="Neues Projekt" --text="Name des neuen Projektordners:") || return 1
    [ -z "$new_name" ] && return 1
    target="$BASE/$new_name"
    mkdir -p "$target"
    clone_url=$(zenity --entry --title="Git-Repo (optional)" \
        --text="Git-Remote-URL zum Klonen, oder leer lassen für leeren Ordner:") || true
    [ -n "$clone_url" ] && git clone "$clone_url" "$target"
    echo "$target"
}

new_project_shell() {
    local new_name target clone_url
    read -rp "Name des neuen Projektordners: " new_name
    [ -z "$new_name" ] && return 1
    target="$BASE/$new_name"
    mkdir -p "$target"
    read -rp "Git-Remote-URL zum Klonen (leer lassen für leeren Ordner): " clone_url
    [ -n "$clone_url" ] && git clone "$clone_url" "$target"
    echo "$target"
}

run_gui() {
    mapfile -t projects < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d | sort)
    names=("$NEW_ENTRY")
    for p in "${projects[@]}"; do
        names+=("$(basename "$p")")
    done

    choice=$(zenity --list \
        --title="cc-picker" \
        --text="In welchem Projekt starten?" \
        --column="Projekt" \
        "${names[@]}" \
        --height=350 --width=400) || exit 0

    [ -z "$choice" ] && exit 0

    if [ "$choice" == "$NEW_ENTRY" ]; then
        target=$(new_project_gui) || exit 0
    else
        target="$BASE/$choice"
    fi

    open_terminal "$target" "\"$CLAUDE_BIN\""
}

run_shell() {
    mapfile -t projects < <(find "$BASE" -mindepth 1 -maxdepth 1 -type d | sort)

    echo "cc-picker — Projekt wählen:"
    echo

    options=()
    for p in "${projects[@]}"; do
        options+=("$(basename "$p")")
    done
    options+=("$NEW_ENTRY")

    select choice in "${options[@]}"; do
        [ -z "$choice" ] && { echo "Ungültige Auswahl, nochmal."; continue; }
        if [ "$choice" == "$NEW_ENTRY" ]; then
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

if command -v zenity >/dev/null 2>&1 && [ -n "$TERMINAL_BIN" ]; then
    mode=$(zenity --list \
        --title="cc-picker" \
        --text="Wie möchtest du das Projekt auswählen?" \
        --column="Modus" \
        "GUI" "Shell" \
        --height=200 --width=300) || exit 0

    case "$mode" in
        "GUI")   run_gui ;;
        "Shell") open_terminal "$BASE" "\"$0\" --shell-mode" ;;
        *)       exit 0 ;;
    esac
else
    run_shell
fi
