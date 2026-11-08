#!/usr/bin/env bash
# Path: titan/commands/system.sh  (sourced by titan: ui helpers, info, status, doctor, logs)

t_head() { printf '%s== %s ==%s\n' "$C_CYAN" "$*" "$C_RESET"; }
t_row()  { printf '%s%-14s%s %s\n' "$C_PURPLE" "$1" "$C_RESET" "$2"; }
t_note() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
t_unavail() {
  case "$(titan_platform)" in
    android-*) echo "unavailable (may be restricted by Android)" ;;
    *) echo "unavailable" ;;
  esac
}
t_bar() {  # usage: t_bar PERCENT
  local p="${1:-}" n i out=""
  [[ "$p" =~ ^[0-9]+$ ]] || { printf 'n/a'; return; }
  [ "$p" -gt 100 ] && p=100
  n=$((p / 5))
  for ((i = 0; i < 20; i++)); do
    if [ "$i" -lt "$n" ]; then out+="#"; else out+="."; fi
  done
  printf '[%s] %s%%' "$out" "$p"
}
t_kb() {  # usage: t_kb KIB
  [[ "${1:-}" =~ ^[0-9]+$ ]] || { echo unavailable; return; }
  awk -v k="$1" 'BEGIN{ if (k>=1048576) printf "%.1f GiB\n", k/1048576; else printf "%.0f MiB\n", k/1024 }'
}
t_int() {  # usage: t_int VALUE NAME [MIN MAX]
  [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge "${3:-1}" ] && [ "$1" -le "${4:-3600}" ] || die "invalid $2: $1"
}

titan_cmd_info() {
  local pk
  t_head "$TITAN_NAME $TITAN_VERSION"
  t_row "Created by"   "$TITAN_AUTHOR"
  t_row "Platform"     "$(titan_platform)"
  t_row "OS"           "$(titan_os_name)"
  t_row "Architecture" "$(titan_arch) ($(uname -m))"
  t_row "Kernel"       "$(titan_kernel)"
  t_row "CPU"          "$(titan_cpu_model) x$(titan_cpu_cores)"
  t_row "Memory"       "$(t_kb "$(titan_mem_kb MemTotal)")"
  t_row "Uptime"       "$(perf_uptime)"
  t_row "Shell"        "bash ${BASH_VERSION%%(*}"
  t_row "Terminal"     "${TERM:-unknown}"
  t_row "Desktop"      "${XDG_CURRENT_DESKTOP:-none}"
  if have_cmd dpkg-query; then
    pk=$(dpkg-query -W -f='${db:Status-Abbrev}\n' 2>/dev/null | grep -c '^ii')
    t_row "Packages" "$pk (dpkg)"
  fi
  if [ "$(titan_platform)" = "android-proot" ] || titan_is_termux; then
    t_note "Android note: the kernel above is the device kernel. TITAN OS never replaces it."
  fi
}

titan_cmd_status() {
  local u l t a used
  t_head "Status"
  u=$(perf_cpu_usage)
  if [ "$u" = unavailable ]; then
    l=$(perf_load)
    t_row "CPU" "usage $(t_unavail); load: $l"
  else t_row "CPU" "$(t_bar "$u")"; fi
  read -r t a _ _ <<<"$(perf_mem)"
  if [ "$t" != unavailable ] && [ "${t:-0}" -gt 0 ]; then
    used=$((t - a)); t_row "Memory" "$(t_bar $((used * 100 / t))) $(t_kb "$used") of $(t_kb "$t")"
  else t_row "Memory" "$(t_unavail)"; fi
  u=$(storage_home_pct); t_row "Storage" "$(t_bar "${u:-x}") (home)"
  if battery_read; then t_row "Battery" "$BAT_PCT% ${BAT_STATUS,,}"
  else t_row "Battery" "not available"; fi
  t_row "Network" "$(net_online)"
}

titan_cmd_doctor() {
  local fails=0 warns=0 f
  d_ok()   { printf '%s[ ok ]%s %s\n' "$C_CYAN"   "$C_RESET" "$*"; }
  d_warn() { printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; warns=$((warns + 1)); }
  d_fail() { printf '%s[fail]%s %s\n' "$C_RED"    "$C_RESET" "$*"; fails=$((fails + 1)); }
  readable() { cat "$1" >/dev/null 2>&1; }

  if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then d_ok "bash ${BASH_VERSION%%(*}"; else d_fail "bash 4 or newer required"; fi
  if mkdir -p "$TITAN_STATE_DIR" 2>/dev/null && [ -w "$TITAN_STATE_DIR" ]; then d_ok "state directory writable"
  else d_fail "state directory not writable: $TITAN_STATE_DIR"; fi
  if [ "$(titan_arch)" != unsupported ]; then d_ok "architecture $(titan_arch)"; else d_fail "unsupported architecture"; fi

  for f in /proc/meminfo /proc/cpuinfo /proc/stat /proc/loadavg /proc/uptime; do
    if readable "$f"; then d_ok "readable: $f"; else d_warn "not readable: $f ($(t_unavail))"; fi
  done
  if [ -n "$(perf_cpu_freqs)" ]; then d_ok "cpu frequency readable"; else d_warn "cpu frequency not readable"; fi
  if [ -n "$(perf_thermal)" ]; then d_ok "thermal zones readable"; else d_warn "thermal zones not readable"; fi
  if battery_read; then d_ok "battery readable via $BAT_SRC"; else d_warn "battery not readable"; fi
  if titan_is_termux && ! have_cmd termux-battery-status; then
    d_warn "optional: install the Termux:API app and 'ti add termux-api' for battery and device info"
  fi
  for f in ti fastfetch man curl ss ip nft; do
    if have_cmd "$f"; then d_ok "command present: $f"; else d_warn "command missing: $f"; fi
  done
  echo "summary: $fails failure(s), $warns warning(s)"
  [ "$fails" -eq 0 ]
}

titan_cmd_logs() {
  local which="titan" n=30
  while [ $# -gt 0 ]; do
    case "$1" in
      titan|ti) which="$1"; shift ;;
      -n) [ $# -ge 2 ] || die "-n needs a number"; t_int "$2" count 1 1000; n="$2"; shift 2 ;;
      *) die "usage: titan logs [titan|ti] [-n COUNT]" ;;
    esac
  done
  if [ "$which" = ti ]; then t_head "ti history"; ti_history_show_file "$n"
  else
    t_head "titan log ($TITAN_LOG_FILE)"
    if [ -s "$TITAN_LOG_FILE" ]; then tail -n "$n" "$TITAN_LOG_FILE"; else echo "no log entries yet"; fi
  fi
}

ti_history_show_file() {
  local f="${TI_HISTORY_FILE:-$TITAN_STATE_DIR/ti-history.tsv}"
  if [ -s "$f" ]; then tail -n "$1" "$f" | awk -F'\t' '{printf "%s  %-12s %-7s %s\n", $1, $2, $4, $3}'
  else echo "no ti history yet"; fi
}
