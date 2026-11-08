#!/usr/bin/env bash
# Path: core/network/basic.sh  (sourced; needs core/lib/common.sh)
# Basic read-only network facts. Full tooling arrives with "ti net" (Step 8).

TITAN_NET_CHECK_URL="${TITAN_NET_CHECK_URL:-https://connectivitycheck.gstatic.com/generate_204}"

net_ifaces() {
  if have_cmd ip && ip -brief addr >/dev/null 2>&1; then ip -brief addr
  elif have_cmd ifconfig && ifconfig >/dev/null 2>&1; then
    ifconfig 2>/dev/null | awk '/^[a-zA-Z]/{i=$1} /inet /{print i, $2}'
  else echo unavailable; fi
}

net_default_route() {
  have_cmd ip && ip route show default 2>/dev/null | head -n1
}

net_dns() {  # nameserver addresses, one per line
  local f
  for f in /etc/resolv.conf "${PREFIX:-}/etc/resolv.conf"; do
    [ -r "$f" ] && grep -E '^nameserver' "$f" 2>/dev/null | awk '{print $2}' && return 0
  done
  return 1
}

net_online() {  # prints: online | offline | unknown
  have_cmd curl || { echo unknown; return; }
  local code
  code=$(curl -s -m 4 -o /dev/null -w '%{http_code}' "$TITAN_NET_CHECK_URL" 2>/dev/null)
  case "$code" in 2??|3??) echo online ;; *) echo offline ;; esac
}
