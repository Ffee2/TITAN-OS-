#!/usr/bin/env bash
set -euo pipefail

[ "$(id -u)" -eq 0 ] || {
    echo "Run with sudo or as root."
    exit 1
}

[ -r /etc/os-release ] || {
    echo "Cannot identify this Linux distribution."
    exit 1
}

. /etc/os-release

case " ${ID:-} ${ID_LIKE:-} " in
    *" arch "*|*" archlinux "*|*" archarm "*) ;;
    *)
        echo "This installer supports Arch-based systems only."
        exit 1
        ;;
esac

[ "$(uname -m)" = "x86_64" ] || {
    echo "This PC installer currently targets x86_64."
    exit 1
}

command -v pacman >/dev/null 2>&1 || {
    echo "Pacman not found."
    exit 1
}

command -v pacman-conf >/dev/null 2>&1 || {
    echo "pacman-conf not found."
    exit 1
}

[ -n "$(pacman-conf --repo-list 2>/dev/null)" ] || {
    echo "No configured Pacman repositories found."
    exit 1
}

SOURCE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="/opt/titan-os"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DEST"

for item in core ti titan fastfetch terminal src Makefile; do
    [ -e "$SOURCE/$item" ] && cp -a "$SOURCE/$item" "$DEST/"
done

for command_name in ti titan; do
    target="/usr/local/bin/$command_name"

    if [ -e "$target" ] || [ -L "$target" ]; then
        mv "$target" "$target.backup.$STAMP"
    fi

    ln -s "$DEST/$command_name/bin/$command_name" "$target"
done

chmod +x "$DEST/ti/bin/ti" "$DEST/ti/bin/ti-apt"
chmod +x "$DEST/ti/backend/pacman-cli.sh" "$DEST/titan/bin/titan"

echo "TITAN PC command installation completed."
echo "Installation: $DEST"
echo "This installs TITAN tools on Arch; it does not partition disks or install a complete OS."
