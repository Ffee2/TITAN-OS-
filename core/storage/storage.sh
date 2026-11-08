#!/usr/bin/env bash
# Path: core/storage/storage.sh  (sourced; needs core/lib/common.sh)

storage_report() {  # one df row per distinct filesystem/mount
  local p row seen=""
  printf '%-22s %6s %6s %6s %5s  %s\n' Filesystem Size Used Avail Use% Mount
  for p in "$HOME" / /sdcard /storage/emulated/0 /tmp; do
    [ -d "$p" ] || continue
    row=$(df -hP "$p" 2>/dev/null | awk 'NR==2{print $1, $2, $3, $4, $5, $6}') || continue
    [ -n "$row" ] || continue
    case "$seen" in *"|$row|"*) continue ;; esac
    seen="$seen|$row|"
    # shellcheck disable=SC2086
    set -- $row
    printf '%-22s %6s %6s %6s %5s  %s\n' "$1" "$2" "$3" "$4" "$5" "$6"
  done
}

storage_home_pct() { df -P "$HOME" 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}'; }

storage_cache_sizes() {  # real sizes of known cache directories
  local d
  for d in "$HOME/.cache" "${PREFIX:-}/var/cache/apt/archives"; do
    [ -d "$d" ] && printf '%-8s %s\n' "$(du -sh "$d" 2>/dev/null | cut -f1)" "$d"
  done
  return 0
}
