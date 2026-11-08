#!/usr/bin/env bash
# Path: tests/test_common.sh
# Run from the project root: bash tests/test_common.sh
set -u
. "$(dirname "${BASH_SOURCE[0]}")/../core/lib/common.sh"
pass=0; fail=0
check() {  # check "name" command...
  local n="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); echo "ok   $n"
  else fail=$((fail+1)); echo "FAIL $n"; fi
}
is_one_of() { local v="$1"; shift; local x; for x in "$@"; do [ "$v" = "$x" ] && return 0; done; return 1; }

check "arch is known"           is_one_of "$(titan_arch)" amd64 arm64 armhf
check "platform is known"       is_one_of "$(titan_platform)" linux android-termux android-proot
check "kernel not empty"        test -n "$(titan_kernel)"
check "cpu model not empty"     test -n "$(titan_cpu_model)"
check "have_cmd bash"           have_cmd bash
check "have_cmd missing"        bash -c '! have_cmd definitely-not-a-cmd'
check "confirm refuses w/o tty" bash -c '. core/lib/common.sh; ! titan_confirm x </dev/null'
check "confirm honors -y flag"  bash -c '. core/lib/common.sh; TITAN_ASSUME_YES=1 titan_confirm x'
tmp=$(mktemp); echo data >"$tmp"
check "backup creates copy"     bash -c ". core/lib/common.sh; titan_backup_file '$tmp' && ls '$tmp'.titan-bak.*"
rm -f "$tmp" "$tmp".titan-bak.*
echo "passed: $pass failed: $fail"; [ "$fail" -eq 0 ]
