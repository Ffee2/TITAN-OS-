#!/usr/bin/env bash
set -euo pipefail

[ -n "${PREFIX:-}" ] || {
    echo "Run this installer inside Termux."
    exit 1
}

SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.local/share/titan-os"
mkdir -p "$DEST"
BIN="$PREFIX/bin"
STAMP="$(date +%Y%m%d-%H%M%S)"

for item in core ti titan fastfetch terminal src Makefile; do
    [ -e "$SOURCE/$item" ] && cp -a "$SOURCE/$item" "$DEST/"
done

mkdir -p "$BIN"

for command_name in ti titan; do
    target="$BIN/$command_name"

    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$target.backup.$STAMP"
    fi

    ln -s "$DEST/$command_name/bin/$command_name" "$target"
done

chmod +x "$DEST/ti/bin/ti" "$DEST/ti/bin/ti-apt"
chmod +x "$DEST/ti/backend/pacman-cli.sh" "$DEST/titan/bin/titan"

echo "TITAN Android command installation completed."
echo "Installation: $DEST"
echo "This installs TITAN tools, not a replacement Android operating system."
