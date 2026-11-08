#!/usr/bin/env bash
# Path: core/security/basic.sh  (sourced; needs core/lib/common.sh)
# Defensive, read-only checks. The full toolkit arrives in Step 12.

sec_firewall() {
  local tools=() t
  for t in nft ufw iptables firewall-cmd; do have_cmd "$t" && tools+=("$t"); done
  if [ "${#tools[@]}" -eq 0 ]; then echo "no firewall tool installed"; return; fi
  if [ "$(id -u)" -ne 0 ] || titan_is_proot; then
    echo "tools present: ${tools[*]} (rule status needs real root)"
  elif have_cmd nft; then
    if nft list ruleset 2>/dev/null | grep -q .; then echo "nftables ruleset loaded"
    else echo "nftables installed, no rules loaded"; fi
  else echo "tools present: ${tools[*]}"; fi
}

sec_listening() {  # listening TCP/UDP sockets or "unavailable"
  if have_cmd ss && ss -tuln >/dev/null 2>&1; then ss -tuln
  elif have_cmd netstat && netstat -tuln >/dev/null 2>&1; then netstat -tuln
  else echo unavailable; fi
}

sec_ssh_perms() {  # prints problems only
  local d="$HOME/.ssh" m f
  [ -d "$d" ] || return 0
  m=$(stat -c '%a' "$d" 2>/dev/null) || return 0
  [ "$m" = "700" ] || echo "$d mode is $m (expected 700)"
  for f in "$d"/id_*; do
    [ -f "$f" ] || continue
    case "$f" in *.pub) continue ;; esac
    m=$(stat -c '%a' "$f" 2>/dev/null) || continue
    [ "$m" = "600" ] || [ "$m" = "400" ] || echo "$f mode is $m (expected 600)"
  done
}
