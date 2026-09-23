#!/bin/bash
# install.sh — installs cc-picker for the current user
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# --- Output language: German for de_* locales, English otherwise ---
UI_LANG="${CC_PICKER_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
case "$UI_LANG" in
    de*)
        T_INSTALLED="cc-picker installiert:"
        T_SCRIPT="Skript: "
        T_MENU="Menü:   "
        T_ICON="Icon:   "
        T_IN_PATH="ist bereits im PATH."
        T_RC_HAS="enthält bereits einen Eintrag für ~/.local/bin."
        T_ADDED="Eintrag für ~/.local/bin ergänzt in"
        T_EFFECT="Wirksam in neuen Terminals (oder: source %s)."
        T_MISSING="fehlt im PATH. Bitte selbst eintragen in"
        T_DEPS="Abhängigkeiten:"
        T_DEP_OK="gefunden"
        T_DEP_NO_CLAUDE="nicht gefunden – bitte Claude Code installieren: https://claude.com/product/claude-code"
        T_DEP_NO_GIT="nicht gefunden (optional, nur zum Klonen neuer Projekte)"
        T_DEP_NO_TERM="kein unterstütztes Terminal gefunden – GUI-Modus nicht verfügbar. Unterstützt: %s"
        T_DEP_NO_DIALOG="kein Dialog-Programm (zenity, kdialog, yad) gefunden – ohne eines gibt es nur das Terminal-Menü, und der Start per Icon funktioniert nicht."
        T_DEP_ASK="%s jetzt installieren? Ausgeführt wird:"
        T_DEP_PROMPT="Installieren? [J/n] "
        T_DEP_YES_RE='^([jJyY].*)?$'
        T_DEP_DONE="%s installiert."
        T_DEP_FAIL="Installation fehlgeschlagen. Du kannst es später selbst ausführen:"
        T_DEP_SKIP="Übersprungen. Später nachholen mit:"
        T_DEP_MANUAL="Bitte %s über den Paketmanager deiner Distribution installieren."
        T_START_TERM="Start per Terminal:  cc-picker"
        T_START_ICON="Start per Icon:      im Anwendungsmenü nach 'cc-picker' suchen"
        ;;
    *)
        T_INSTALLED="cc-picker installed:"
        T_SCRIPT="Script: "
        T_MENU="Menu:   "
        T_ICON="Icon:   "
        T_IN_PATH="is already in PATH."
        T_RC_HAS="already contains an entry for ~/.local/bin."
        T_ADDED="Added ~/.local/bin entry to"
        T_EFFECT="Takes effect in new terminals (or run: source %s)."
        T_MISSING="is not in PATH. Please add it yourself to"
        T_DEPS="Dependencies:"
        T_DEP_OK="found"
        T_DEP_NO_CLAUDE="not found – please install Claude Code: https://claude.com/product/claude-code"
        T_DEP_NO_GIT="not found (optional, only needed to clone new projects)"
        T_DEP_NO_TERM="no supported terminal emulator found – GUI mode unavailable. Supported: %s"
        T_DEP_NO_DIALOG="no dialog tool (zenity, kdialog, yad) found – without one only the terminal menu works, and launching from the app menu won't."
        T_DEP_ASK="Install %s now? This will run:"
        T_DEP_PROMPT="Install? [Y/n] "
        T_DEP_YES_RE='^([yY].*)?$'
        T_DEP_DONE="%s installed."
        T_DEP_FAIL="Installation failed. You can run it yourself later:"
        T_DEP_SKIP="Skipped. To do it later, run:"
        T_DEP_MANUAL="Please install %s using your distribution's package manager."
        T_START_TERM="Start from a terminal:  cc-picker"
        T_START_ICON="Start from the menu:    search for 'cc-picker' in your app menu"
        ;;
esac

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_DIR"

cp "$REPO_DIR/cc-picker.sh" "$BIN_DIR/cc-picker"
chmod +x "$BIN_DIR/cc-picker"

if [ -f "$REPO_DIR/cc-picker.svg" ]; then
    cp "$REPO_DIR/cc-picker.svg" "$ICON_DIR/cc-picker.svg"
    ICON_PATH="$ICON_DIR/cc-picker.svg"
else
    ICON_PATH="utilities-terminal"
fi

cat > "$APP_DIR/cc-picker.desktop" << EOF
[Desktop Entry]
Type=Application
Name=cc-picker
Comment=Pick or create a project and launch Claude Code in it
Comment[de]=Projekt wählen oder anlegen und Claude Code darin starten
Exec=$BIN_DIR/cc-picker
Icon=$ICON_PATH
Terminal=false
Categories=Development;
EOF

echo "$T_INSTALLED"
echo "  $T_SCRIPT $BIN_DIR/cc-picker"
echo "  $T_MENU $APP_DIR/cc-picker.desktop"
echo "  $T_ICON $ICON_PATH"
echo

# --- Make sure ~/.local/bin is in PATH ---
# Checks the current PATH first, then the login shell's config file.
# Disable with CC_PICKER_NO_PATH=1.
ensure_path() {
    local user_shell rc_file line
    case ":$PATH:" in
        *":$BIN_DIR:"*)
            echo "PATH: '$BIN_DIR' $T_IN_PATH"
            return 0 ;;
    esac

    user_shell="${CC_PICKER_SHELL:-$(getent passwd "$(id -u)" 2>/dev/null | cut -d: -f7)}"
    user_shell="${user_shell:-${SHELL:-/bin/bash}}"
    case "$(basename "$user_shell")" in
        bash) rc_file="$HOME/.bashrc"
              line='export PATH="$HOME/.local/bin:$PATH"' ;;
        zsh)  rc_file="${ZDOTDIR:-$HOME}/.zshrc"
              line='export PATH="$HOME/.local/bin:$PATH"' ;;
        fish) rc_file="$HOME/.config/fish/config.fish"
              line='fish_add_path "$HOME/.local/bin"' ;;
        *)    rc_file="$HOME/.profile"
              line='export PATH="$HOME/.local/bin:$PATH"' ;;
    esac

    if [ -f "$rc_file" ] && grep -q '\.local/bin' "$rc_file"; then
        echo "PATH: '$rc_file' $T_RC_HAS"
        printf "      $T_EFFECT\n" "$rc_file"
        return 0
    fi

    if [ "${CC_PICKER_NO_PATH:-0}" = "1" ]; then
        echo "PATH: '$BIN_DIR' $T_MISSING '$rc_file':"
        echo "  $line"
        return 0
    fi

    mkdir -p "$(dirname "$rc_file")"
    printf '\n# added by cc-picker install.sh\n%s\n' "$line" >> "$rc_file"
    echo "PATH: $T_ADDED '$rc_file'."
    printf "      $T_EFFECT\n" "$rc_file"
}
ensure_path
echo

# --- Check dependencies; offer to install a dialog tool if none is present ---
# Never runs anything as root on its own: the exact command is shown and
# only executed after the user agrees. Disable with CC_PICKER_NO_DEPS=1.
first_found() {
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 && { echo "$c"; return 0; }
    done
    return 1
}

install_cmd() {
    local pkg="$1"
    if   command -v pacman  >/dev/null 2>&1; then echo "sudo pacman -S --needed $pkg"
    elif command -v apt-get >/dev/null 2>&1; then echo "sudo apt-get install $pkg"
    elif command -v dnf     >/dev/null 2>&1; then echo "sudo dnf install $pkg"
    elif command -v zypper  >/dev/null 2>&1; then echo "sudo zypper install $pkg"
    else return 1
    fi
}

check_deps() {
    local terms=(gnome-terminal konsole xfce4-terminal alacritty kitty xterm)
    local found pkg cmd answer

    echo "$T_DEPS"
    if found=$(first_found claude "$HOME/.local/bin/claude"); then
        printf "  ✓ %-15s %s\n" claude "$T_DEP_OK"
    else
        printf "  ✗ %-15s %s\n" claude "$T_DEP_NO_CLAUDE"
    fi
    if found=$(first_found "${terms[@]}"); then
        printf "  ✓ %-15s %s\n" "$found" "$T_DEP_OK"
    else
        printf "  ✗ %-15s $T_DEP_NO_TERM\n" terminal "${terms[*]}"
    fi
    if command -v git >/dev/null 2>&1; then
        printf "  ✓ %-15s %s\n" git "$T_DEP_OK"
    else
        printf "  – %-15s %s\n" git "$T_DEP_NO_GIT"
    fi
    if found=$(first_found zenity kdialog yad); then
        printf "  ✓ %-15s %s\n" "$found" "$T_DEP_OK"
        return 0
    fi

    printf "  ✗ %-15s %s\n" dialog "$T_DEP_NO_DIALOG"
    echo
    case "${XDG_CURRENT_DESKTOP:-}" in
        *KDE*) pkg="kdialog" ;;
        *)     pkg="zenity" ;;
    esac
    if ! cmd=$(install_cmd "$pkg"); then
        printf "$T_DEP_MANUAL\n" "$pkg"
        return 0
    fi
    if [ "${CC_PICKER_NO_DEPS:-0}" = "1" ] || [ ! -t 0 ]; then
        echo "$T_DEP_SKIP"
        echo "  $cmd"
        return 0
    fi

    printf "$T_DEP_ASK\n" "$pkg"
    echo "  $cmd"
    read -rp "$T_DEP_PROMPT" answer || answer="n"
    if [[ "$answer" =~ $T_DEP_YES_RE ]]; then
        if $cmd; then
            printf "$T_DEP_DONE\n" "$pkg"
        else
            echo "$T_DEP_FAIL"
            echo "  $cmd"
        fi
    else
        echo "$T_DEP_SKIP"
        echo "  $cmd"
    fi
}
check_deps
echo

echo "$T_START_TERM"
echo "$T_START_ICON"
