#!/bin/bash
# install.sh — installs cc-picker for the current user
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

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
Exec=$BIN_DIR/cc-picker
Icon=$ICON_PATH
Terminal=false
Categories=Development;
EOF

echo "cc-picker installiert:"
echo "  Skript:  $BIN_DIR/cc-picker"
echo "  Icon:    $APP_DIR/cc-picker.desktop"
echo

# --- ~/.local/bin im PATH sicherstellen ---
# Prüft zuerst den aktuellen PATH, dann die Shell-Config der Login-Shell.
# Abschalten mit CC_PICKER_NO_PATH=1.
ensure_path() {
    local user_shell rc_file line
    case ":$PATH:" in
        *":$BIN_DIR:"*)
            echo "PATH: '$BIN_DIR' ist bereits im PATH."
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
        echo "PATH: '$rc_file' enthält bereits einen Eintrag für ~/.local/bin."
        echo "      Wirksam in neuen Terminals (oder: source $rc_file)."
        return 0
    fi

    if [ "${CC_PICKER_NO_PATH:-0}" = "1" ]; then
        echo "PATH: '$BIN_DIR' fehlt im PATH. Bitte selbst in '$rc_file' eintragen:"
        echo "  $line"
        return 0
    fi

    mkdir -p "$(dirname "$rc_file")"
    printf '\n# added by cc-picker install.sh\n%s\n' "$line" >> "$rc_file"
    echo "PATH: Eintrag für ~/.local/bin in '$rc_file' ergänzt."
    echo "      Wirksam in neuen Terminals (oder: source $rc_file)."
}
ensure_path
echo
echo "Start per Terminal:  cc-picker"
echo "Start per Icon:      im Anwendungsmenü nach 'cc-picker' suchen"
