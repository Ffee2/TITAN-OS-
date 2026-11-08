#!/usr/bin/env bash
set -uo pipefail

DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

if [ -f "$ROOT/core/lib/common.sh" ]; then
    . "$ROOT/core/lib/common.sh"
fi

VERSION="0.2.0"

usage() {
    cat <<'HELP'
TITAN ti - Arch package backend

Usage:
  ti --version
  ti help
  ti add PACKAGE...
  ti remove PACKAGE...
  ti search QUERY
  ti info PACKAGE
  ti list
  ti update
  ti upgrade
  ti autoremove
  ti clean
  ti doctor
  ti repo list
HELP
}

fail() {
    printf '[error] %s\n' "$*" >&2
    exit 1
}

need_pacman() {
    command -v pacman >/dev/null 2>&1 || fail "Pacman is not installed."
}

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail "Root access or sudo is required."
    fi
}

confirm() {
    local answer
    printf '%s [y/N] ' "$1"
    read -r answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

protected_package() {
    case "$1" in
        base|filesystem|glibc|bash|coreutils|pacman|systemd|linux|linux-firmware)
            return 0 ;;
        *) return 1 ;;
    esac
}

main() {
    need_pacman

    case "${1:-help}" in
        --version|-v)
            echo "ti $VERSION (TITAN OS, backend: pacman)"
            ;;

        help|-h|--help)
            usage
            ;;

        add)
            shift
            [ "$#" -gt 0 ] || fail "Specify a package."
            as_root pacman -S --needed "$@"
            ;;

        remove)
            shift
            [ "$#" -gt 0 ] || fail "Specify a package."
            for pkg in "$@"; do
                protected_package "$pkg" && fail "Protected package: $pkg"
            done
            if confirm "Remove the selected packages and unused dependencies?"; then
                as_root pacman -Rns "$@"
            else
                echo "Cancelled."
            fi
            ;;

        search)
            shift
            [ "$#" -gt 0 ] || fail "Specify a search term."
            pacman -Ss "$*"
            ;;

        info)
            shift
            [ "$#" -eq 1 ] || fail "Specify one package."
            pacman -Si "$1" 2>/dev/null || pacman -Qi "$1"
            ;;

        list)
            pacman -Q
            ;;

        update|upgrade)
            echo "Running a complete system upgrade to avoid partial upgrades."
            as_root pacman -Syu
            ;;

        autoremove)
            mapfile -t orphans < <(pacman -Qtdq 2>/dev/null || true)
            if [ "${#orphans[@]}" -eq 0 ]; then
                echo "No orphan packages found."
                return 0
            fi
            printf 'Orphan packages:\n'
            printf '  %s\n' "${orphans[@]}"
            if confirm "Remove these packages?"; then
                as_root pacman -Rns -- "${orphans[@]}"
            else
                echo "Cancelled."
            fi
            ;;

        clean)
            if confirm "Clean uninstalled package cache files?"; then
                as_root pacman -Sc
            else
                echo "Cancelled."
            fi
            ;;

        doctor)
            echo "TITAN Package Manager Doctor"
            echo "Backend: Pacman"
            echo "Architecture: $(uname -m)"
            command -v pacman >/dev/null && echo "[OK] Pacman found"
            command -v pacman-conf >/dev/null && echo "[OK] pacman-conf found"
            pacman-conf --repo-list 2>/dev/null || true
            echo "Note: repository connectivity requires an actual Arch system test."
            ;;

        repo)
            [ "${2:-}" = "list" ] || fail "Supported command: ti repo list"
            pacman-conf --repo-list
            ;;

        *)
            fail "Unknown command: $1"
            ;;
    esac
}

main "$@"
