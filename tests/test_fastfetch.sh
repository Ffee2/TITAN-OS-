#!/usr/bin/env bash
# Path: tests/test_fastfetch.sh  (run after: bash fastfetch/install.sh)
# Run from the project root: bash tests/test_fastfetch.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch"; cfg="$dir/config.jsonc"
pass=0; fail=0
check() { local n="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); echo "ok   $n"
  else fail=$((fail+1)); echo "FAIL $n"; fi; }

check "fastfetch installed"           command -v fastfetch
check "template has the credit line"  grep -q 'CREATED BY: BARATH' "$ROOT/fastfetch/config.jsonc.in"
check "installed config has credit"   grep -q 'CREATED BY: BARATH' "$cfg"
check "no placeholders left"          bash -c "! grep -q '@[A-Z]*@' '$cfg'"
check "logo installed"                test -s "$dir/titan-logo.txt"
if command -v python3 >/dev/null 2>&1; then
  check "config is valid JSON"        python3 -m json.tool "$cfg"
else echo "skip config JSON check (python3 not installed)"; fi
out() { fastfetch --config "$cfg" 2>&1 | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g'; }
check "output shows credit"           bash -c "$(declare -f out); cfg='$cfg'; out | grep -q 'CREATED BY: BARATH'"
check "output shows kernel"           bash -c "$(declare -f out); cfg='$cfg'; out | grep -qi 'kernel'"
echo "passed: $pass failed: $fail"; [ "$fail" -eq 0 ]
