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
echo "Falls '$BIN_DIR' nicht in deinem PATH ist, füge in ~/.bashrc oder ~/.zshrc hinzu:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo
echo "Start per Terminal:  cc-picker"
echo "Start per Icon:      im Anwendungsmenü nach 'cc-picker' suchen"
