#!/usr/bin/env bash
# shellcheck disable=SC1091
# Path: core/system-info/sysinfo.sh  (prints real detected system facts)
set -u
. "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

row() { printf '%s%-14s%s %s\n' "$C_PURPLE" "$1" "$C_RESET" "$2"; }
mb() { case "$1" in unknown) echo unknown ;; *) echo "$(( $1 / 1024 )) MiB" ;; esac; }

printf '%s%s %s%s\n' "$C_CYAN" "$TITAN_NAME" "$TITAN_VERSION" "$C_RESET"
row "Platform"     "$(titan_platform)"
row "OS"           "$(titan_os_name)"
row "Architecture" "$(titan_arch) ($(uname -m))"
row "Kernel"       "$(titan_kernel)"
row "CPU"          "$(titan_cpu_model) x$(titan_cpu_cores)"
row "Memory"       "$(mb "$(titan_mem_kb MemAvailable)") free of $(mb "$(titan_mem_kb MemTotal)")"
if [ "$(titan_platform)" = "android-proot" ]; then
  log_info "PRoot uses the Android device kernel; TITAN OS never replaces it."
fi
