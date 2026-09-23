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

echo "$T_START_TERM"
echo "$T_START_ICON"
