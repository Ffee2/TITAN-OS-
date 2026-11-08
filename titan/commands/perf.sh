#!/usr/bin/env bash
# Path: titan/commands/perf.sh  (sourced by titan: cpu, memory, thermal, gpu, processes, performance, monitor)

titan_cmd_cpu() {
  local u g n mhz any=0
  t_head "CPU"
  t_row "Model" "$(titan_cpu_model)"
  t_row "Cores" "$(titan_cpu_cores)"
  t_row "Architecture" "$(titan_arch) ($(uname -m))"
  u=$(perf_cpu_usage)
  if [ "$u" = unavailable ]; then t_row "Usage" "$(t_unavail)"; else t_row "Usage" "$(t_bar "$u")"; fi
  t_row "Load" "$(perf_load)"
  g=$(perf_governor); t_row "Governor" "$g"
  while read -r n mhz; do t_row "$n" "$mhz MHz"; any=1; done < <(perf_cpu_freqs)
  [ "$any" -eq 1 ] || t_row "Frequency" "$(t_unavail)"
}

titan_cmd_memory() {
  local t a st sf used
  t_head "Memory"
  read -r t a st sf <<<"$(perf_mem)"
  if [ "$t" = unavailable ] || [ "${t:-0}" -le 0 ]; then t_row "Status" "$(t_unavail)"; return 0; fi
  used=$((t - a))
  t_row "Total" "$(t_kb "$t")"
  t_row "Used" "$(t_kb "$used")"
  t_row "Available" "$(t_kb "$a")"
  t_row "Usage" "$(t_bar $((used * 100 / t)))"
  if [ "$st" -gt 0 ]; then t_row "Swap" "$(t_kb $((st - sf))) of $(t_kb "$st")"; else t_row "Swap" "none"; fi
}

titan_cmd_thermal() {
  local n c any=0
  t_head "Thermal"
  while read -r n c; do t_row "$n" "$c C"; any=1; done < <(perf_thermal)
  if battery_read && [ -n "$BAT_TEMP" ]; then t_row "battery" "$BAT_TEMP C"; any=1; fi
  if [ "$any" -eq 0 ]; then
    t_row "Status" "no readable sensors"
    case "$(titan_platform)" in android-*) t_note "Android may hide temperature sensors from apps." ;; esac
  fi
  t_note "Read-only. TITAN OS never changes thermal limits."
}

titan_cmd_gpu() {
  t_head "GPU"
  t_row "Detected" "$(perf_gpu)"
}

titan_cmd_processes() {
  local n=10
  if [ "${1:-}" = "-n" ]; then [ $# -ge 2 ] || die "-n needs a number"; t_int "$2" count 1 200; n="$2"; fi
  t_head "Top $n processes by CPU"
  perf_processes "$n"
  case "$(titan_platform)" in android-*) t_note "Android only shows processes owned by this app user." ;; esac
}

_profile_field() {  # usage: _profile_field FILE KEY
  sed -n "s/^$2=//p" "$1" | head -n1
}

titan_cmd_performance() {
  local f sel="" cfg="$TITAN_CONFIG_DIR/profile" p
  case "${1:-}" in
    "")
      t_head "Performance"
      t_row "Governor" "$(perf_governor)"
      t_row "Load" "$(perf_load)"
      t_row "Thermal" "run 'titan thermal'"
      for p in gamemoded steam; do
        if have_cmd "$p"; then t_row "$p" "installed"; else t_row "$p" "not installed"; fi
      done
      [ -r "$cfg" ] && sel=$(head -n1 "$cfg")
      t_row "Profile" "${sel:-balanced}"
      t_note "Software monitoring does not raise CPU speed. See 'titan performance profile'."
      ;;
    profile)
      if [ -z "${2:-}" ]; then
        t_head "Profiles"
        for f in "$TITAN_ROOT"/titan/profiles/*.conf; do
          t_row "$(_profile_field "$f" NAME)" "$(_profile_field "$f" DESC)"
        done
      else
        [[ "$2" =~ ^[a-z-]+$ ]] || die "invalid profile name"
        f="$TITAN_ROOT/titan/profiles/$2.conf"
        [ -f "$f" ] || die "unknown profile: $2 (see 'titan performance profile')"
        mkdir -p "$TITAN_CONFIG_DIR" && printf '%s\n' "$2" >"$cfg" || die "cannot save profile"
        log_info "profile set to $2"
        t_row "PC" "$(_profile_field "$f" PC)"
        t_row "Android" "$(_profile_field "$f" ANDROID)"
      fi
      ;;
    *) die "usage: titan performance [profile [NAME]]" ;;
  esac
}

titan_cmd_monitor() {
  local interval=2 once=0 u t a used n c
  while [ $# -gt 0 ]; do
    case "$1" in
      --once) once=1; shift ;;
      -i) [ $# -ge 2 ] || die "-i needs seconds"; t_int "$2" interval 1 3600; interval="$2"; shift 2 ;;
      *) die "usage: titan monitor [-i SECONDS] [--once]" ;;
    esac
  done
  trap 'echo; exit 0' INT
  while :; do
    [ -t 1 ] && [ "$once" -eq 0 ] && printf '\033[H\033[2J'
    t_head "Monitor ($(date '+%H:%M:%S'), Ctrl+C to exit)"
    u=$(perf_cpu_usage)
    if [ "$u" = unavailable ]; then t_row "CPU" "$(t_unavail)"; else t_row "CPU" "$(t_bar "$u")"; fi
    t_row "Load" "$(perf_load)"
    read -r t a _ _ <<<"$(perf_mem)"
    if [ "$t" != unavailable ] && [ "${t:-0}" -gt 0 ]; then
      used=$((t - a)); t_row "Memory" "$(t_bar $((used * 100 / t))) $(t_kb "$used")"
    else t_row "Memory" "$(t_unavail)"; fi
    u=$(storage_home_pct); t_row "Storage" "$(t_bar "${u:-x}")"
    if battery_read; then t_row "Battery" "$BAT_PCT% ${BAT_STATUS,,}${BAT_TEMP:+, $BAT_TEMP C}"; fi
    while read -r n c; do t_row "$n" "$c C"; done < <(perf_thermal | head -n 3)
    [ "$once" -eq 1 ] && break
    sleep "$interval"
  done
}
