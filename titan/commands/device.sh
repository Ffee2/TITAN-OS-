#!/usr/bin/env bash
# Path: titan/commands/device.sh  (sourced by titan: battery, storage, security, network)

titan_cmd_battery() {
  t_head "Battery"
  if battery_read; then
    t_row "Level" "$(t_bar "$BAT_PCT")"
    t_row "Status" "${BAT_STATUS:-unknown}"
    [ -n "$BAT_TEMP" ] && t_row "Temperature" "$BAT_TEMP C"
    t_row "Source" "$BAT_SRC"
  else
    t_row "Status" "no readable battery"
    if titan_is_termux; then
      t_note "Install the Termux:API app, then run: ti add termux-api"
    else t_note "No battery found (desktop or virtual machine)."; fi
  fi
}

titan_cmd_storage() {
  t_head "Storage"
  storage_report
  echo
  t_head "Cache sizes (nothing is deleted)"
  storage_cache_sizes
}

titan_cmd_network() {
  local r d
  t_head "Network"
  t_row "Internet" "$(net_online)"
  r=$(net_default_route); t_row "Gateway" "${r:-$(t_unavail)}"
  d=$(net_dns | paste -sd' ' -); t_row "DNS" "${d:-$(t_unavail)}"
  t_head "Interfaces"
  net_ifaces
  t_note "Internet check contacts: $TITAN_NET_CHECK_URL (override with TITAN_NET_CHECK_URL)."
}

titan_cmd_security() {
  local issues ports
  t_head "Security"
  if [ "$(id -u)" -eq 0 ] && ! titan_is_proot; then t_row "User" "root (prefer a normal user)"
  else t_row "User" "$(whoami)"; fi
  t_row "Firewall" "$(sec_firewall)"
  t_row "umask" "$(umask)"
  if pgrep -x sshd >/dev/null 2>&1; then t_row "SSH server" "running"; else t_row "SSH server" "not detected"; fi
  issues=$(sec_ssh_perms)
  if [ -n "$issues" ]; then t_row "SSH files" "problems found"; printf '  %s\n' "$issues"
  else t_row "SSH files" "no permission problems found"; fi
  ports=$(sec_listening)
  t_head "Listening sockets"
  if [ "$ports" = unavailable ]; then echo "$(t_unavail) (needs ss or netstat)"; else echo "$ports"; fi
  t_note "Read-only checks. The full audit toolkit arrives in a later step."
}
