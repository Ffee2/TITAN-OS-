#!/usr/bin/env bash
# Path: ti/backend/history.sh  (sourced by ti)
# shellcheck disable=SC2034
TI_HISTORY_FILE="${TI_HISTORY_FILE:-$TITAN_STATE_DIR/ti-history.tsv}"

ti_history_add() {  # usage: ti_history_add ACTION ITEMS RESULT
  mkdir -p "$TITAN_STATE_DIR" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" "$3" \
    >>"$TI_HISTORY_FILE" 2>/dev/null || true
}

ti_history_show() {  # usage: ti_history_show [COUNT]
  local n="${1:-20}"
  case "$n" in ''|*[!0-9]*) die "invalid count: $n" ;; esac
  if [ ! -s "$TI_HISTORY_FILE" ]; then echo "no history yet"; return 0; fi
  tail -n "$n" "$TI_HISTORY_FILE" |
    awk -F'\t' '{printf "%s  %-12s %-7s %s\n", $1, $2, $4, $3}'
}
