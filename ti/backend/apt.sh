#!/usr/bin/env bash
# Path: ti/backend/apt.sh  (sourced by ti)
# Backend: Debian APT/DPKG (also used by Termux). ti does not yet have an
# independent package format or repository ecosystem.
# shellcheck disable=SC2016

TI_APT_ETC="${TI_APT_ETC:-${PREFIX:-}/etc/apt}"
TI_PROTECTED="apt dpkg bash coreutils libc6 termux-tools termux-keyring termux-core termux-exec"

be_check() { require_cmd apt-get apt-cache dpkg-query; }

# Run a command with the privileges the platform needs.
# Termux: app user, no root needed. Root/PRoot: direct. Otherwise: sudo.
be_priv() {
  if [ "$(id -u)" -eq 0 ] || titan_is_termux; then "$@"
  elif have_cmd sudo; then sudo "$@"
  else log_error "root privileges are required and sudo is not installed"; return 1
  fi
}

be_valid_pkg() { [[ "$1" =~ ^[a-z0-9][a-z0-9+.:-]*$ ]]; }

be_candidate() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/{print $2; exit}'; }

be_installed() {
  dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null | grep -q '^ii'
}

be_is_protected() {
  local p
  for p in $TI_PROTECTED; do [ "$p" = "$1" ] && return 0; done
  return 1
}

# Packages apt would remove for the given simulated action (no changes made)
be_simulate() {  # usage: be_simulate remove|autoremove [PKG...]
  apt-get -s "$@" 2>/dev/null | awk '/^Remv/{print "  " $2 " " $3}'
}

be_apt() {  # usage: be_apt ACTION [ARGS...]  (adds -y only if user passed -y)
  local act="$1"; shift
  local y=()
  [ "${TITAN_ASSUME_YES:-0}" = "1" ] && y=(-y)
  be_priv apt-get "$act" "${y[@]}" "$@"
}
