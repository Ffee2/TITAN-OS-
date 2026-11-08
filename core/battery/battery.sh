#!/usr/bin/env bash
# Path: core/battery/battery.sh  (sourced; needs core/lib/common.sh)
# battery_read sets BAT_PCT BAT_STATUS BAT_TEMP BAT_SRC. Returns 1 if no source works.

battery_read() {
  BAT_PCT=""; BAT_STATUS=""; BAT_TEMP=""; BAT_SRC=""
  local d t out
  for d in /sys/class/power_supply/battery /sys/class/power_supply/BAT*; do
    [ -d "$d" ] || continue
    BAT_PCT=$(cat "$d/capacity" 2>/dev/null) || BAT_PCT=""
    [[ "$BAT_PCT" =~ ^[0-9]+$ ]] || { BAT_PCT=""; continue; }
    BAT_STATUS=$(cat "$d/status" 2>/dev/null) || BAT_STATUS="unknown"
    if t=$(cat "$d/temp" 2>/dev/null) && [[ "$t" =~ ^-?[0-9]+$ ]]; then
      BAT_TEMP=$(awk -v t="$t" 'BEGIN{printf "%.1f", t/10}')
    fi
    BAT_SRC="sysfs"; return 0
  done
  if have_cmd termux-battery-status; then
    out=$(timeout 5 termux-battery-status 2>/dev/null) || out=""
    BAT_PCT=$(printf '%s' "$out" | sed -n 's/.*"percentage": *\([0-9][0-9]*\).*/\1/p' | head -n1)
    if [ -n "$BAT_PCT" ]; then
      BAT_STATUS=$(printf '%s' "$out" | sed -n 's/.*"status": *"\([A-Za-z_]*\)".*/\1/p' | head -n1)
      BAT_TEMP=$(printf '%s' "$out" | sed -n 's/.*"temperature": *\([-0-9.]*\).*/\1/p' | head -n1)
      BAT_SRC="termux-api"; return 0
    fi
  fi
  return 1
}
