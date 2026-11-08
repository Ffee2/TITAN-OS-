#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091
# TITAN OS shared core library. Source this file; do not execute it.
# Path: core/lib/common.sh

[ -n "${TITAN_COMMON_LOADED:-}" ] && return 0
TITAN_COMMON_LOADED=1

TITAN_NAME="TITAN OS"
TITAN_VERSION="0.2.0"
TITAN_AUTHOR="BARATH"
TITAN_ROOT="${TITAN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
TITAN_STATE_DIR="${TITAN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/titan}"
TITAN_CONFIG_DIR="${TITAN_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/titan}"
TITAN_LOG_FILE="${TITAN_LOG_FILE:-$TITAN_STATE_DIR/titan.log}"

# ---- colors: dark titanium with purple and cyan accents (plain text, no emoji)
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_PURPLE=$'\033[38;5;135m'; C_CYAN=$'\033[38;5;45m'
  C_RED=$'\033[38;5;203m';    C_YELLOW=$'\033[38;5;179m'
  C_DIM=$'\033[2m';           C_RESET=$'\033[0m'
else
  C_PURPLE=""; C_CYAN=""; C_RED=""; C_YELLOW=""; C_DIM=""; C_RESET=""
fi

# ---- logging (file log is best effort and never fatal)
_titan_log_write() {
  mkdir -p "$TITAN_STATE_DIR" 2>/dev/null || return 0
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" \
    >>"$TITAN_LOG_FILE" 2>/dev/null || true
}
log_info()  { _titan_log_write INFO  "$*"; printf '%s[info]%s %s\n'  "$C_CYAN"   "$C_RESET" "$*"; }
log_warn()  { _titan_log_write WARN  "$*"; printf '%s[warn]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error() { _titan_log_write ERROR "$*"; printf '%s[error]%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; }
die()       { log_error "$*"; exit 1; }

# ---- command helpers
have_cmd() { command -v "$1" >/dev/null 2>&1; }
require_cmd() {
  local c missing=0
  for c in "$@"; do
    have_cmd "$c" || { log_error "missing command: $c"; missing=1; }
  done
  return "$missing"
}

# ---- confirmation: default is NO. Only an explicit TITAN_ASSUME_YES=1
# (set by a command's own -y flag) skips the prompt.
titan_confirm() {
  local prompt="${1:-Continue?}" reply
  [ "${TITAN_ASSUME_YES:-0}" = "1" ] && return 0
  if [ ! -t 0 ]; then
    log_warn "no terminal available for confirmation, refusing: $prompt"
    return 1
  fi
  printf '%s%s%s [y/N] ' "$C_PURPLE" "$prompt" "$C_RESET" >&2
  read -r reply || return 1
  case "$reply" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ---- never silently overwrite: copy an existing file aside first
titan_backup_file() {
  local f="$1" b
  [ -e "$f" ] || return 0
  b="$f.titan-bak.$(date +%Y%m%d%H%M%S)"
  cp -p -- "$f" "$b" || return 1
  log_info "backed up $f to $b"
}

# ---- platform detection
# PRoot detection is a heuristic: PRoot runs under ptrace, so a non-zero
# TracerPid (or PROOT_L2S_DIR from proot-distro) indicates it. A debugger
# attached to this shell would also trigger it.
titan_is_proot() {
  [ -n "${PROOT_L2S_DIR:-}" ] && return 0
  [ -r /proc/self/status ] || return 1
  local tracer
  tracer=$(awk '/^TracerPid:/{print $2}' /proc/self/status 2>/dev/null)
  [ -n "$tracer" ] && [ "$tracer" != "0" ]
}
titan_is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] && return 0
  case "${PREFIX:-}" in */com.termux/*) return 0 ;; esac
  return 1
}
# prints: android-proot | android-termux | linux
titan_platform() {
  if titan_is_proot; then echo "android-proot"
  elif titan_is_termux; then echo "android-termux"
  else echo "linux"; fi
}

# ---- architecture: amd64 | arm64 | armhf | unsupported
titan_arch() {
  case "$(uname -m)" in
    x86_64|amd64)          echo amd64 ;;
    aarch64|arm64)         echo arm64 ;;
    armv7*|armv8l|armhf)   echo armhf ;;
    *)                     echo unsupported ;;
  esac
}

# ---- hardware facts (real values only; "unknown" when not readable)
titan_kernel() { uname -r; }
titan_cpu_model() {
  local m=""
  [ -r /proc/cpuinfo ] && m=$(awk -F'[[:space:]]*:[[:space:]]*' \
    '/^(model name|Hardware|Processor)[[:space:]]*:/{print $2; exit}' /proc/cpuinfo)
  if [ -z "$m" ] && have_cmd getprop; then
    m=$(getprop ro.soc.model 2>/dev/null)
    [ -z "$m" ] && m=$(getprop ro.board.platform 2>/dev/null)
  fi
  echo "${m:-unknown}"
}
titan_cpu_cores() { nproc 2>/dev/null || echo unknown; }
titan_mem_kb() {  # usage: titan_mem_kb MemTotal|MemAvailable|MemFree
  awk -v k="$1:" '$1==k{print $2; f=1; exit} END{if(!f) print "unknown"}' \
    /proc/meminfo 2>/dev/null || echo unknown
}
titan_os_name() {
  if [ -r /etc/os-release ]; then
    (. /etc/os-release; echo "${PRETTY_NAME:-${NAME:-unknown}}")
  elif titan_is_termux; then echo "Termux"
  else uname -s; fi
}
