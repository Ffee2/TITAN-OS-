#!/usr/bin/env bash
# Path: fastfetch/install.sh  -  installs the TITAN OS Fastfetch config
# Usage: bash fastfetch/install.sh [-y]
# shellcheck disable=SC1091
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/../core/lib/common.sh"
[ "${1:-}" = "-y" ] && export TITAN_ASSUME_YES=1

require_cmd fastfetch sed cmp mktemp || die "missing tools; install Fastfetch with: ti add fastfetch"
dest="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"
mkdir -p "$dest" || die "cannot create $dest"

# Logo (copied next to the config so Fastfetch can always find it)
if [ ! -e "$dest/titan-logo.txt" ] || ! cmp -s "$HERE/logo.txt" "$dest/titan-logo.txt"; then
  titan_backup_file "$dest/titan-logo.txt" || die "backup failed"
  cp -- "$HERE/logo.txt" "$dest/titan-logo.txt" || die "cannot install logo"
fi

# Config: fill in the real TITAN OS version and logo path
tmp="$(mktemp)" || die "cannot create temp file"
sed -e "s|@VERSION@|$TITAN_VERSION|g" -e "s|@LOGO@|$dest/titan-logo.txt|g" \
  "$HERE/config.jsonc.in" >"$tmp" || die "cannot build config"

if [ -e "$dest/config.jsonc" ] && ! cmp -s "$tmp" "$dest/config.jsonc"; then
  titan_confirm "Replace your existing Fastfetch config? A backup is kept." \
    || { rm -f "$tmp"; die "cancelled; existing config left untouched"; }
  titan_backup_file "$dest/config.jsonc" || { rm -f "$tmp"; die "backup failed"; }
fi
cp -- "$tmp" "$dest/config.jsonc" && rm -f "$tmp" || die "cannot install config"
log_info "installed: $dest/config.jsonc"
