#!/usr/bin/env bash
# Path: tests/test_titan.sh  (read-only commands; safe to run anywhere)
# Run from the project root: bash tests/test_titan.sh
set -u
TITAN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/titan/bin/titan"
export TITAN_STATE_DIR; TITAN_STATE_DIR="$(mktemp -d)"
export TITAN_CONFIG_DIR; TITAN_CONFIG_DIR="$(mktemp -d)"
export NO_COLOR=1
pass=0; fail=0
check() { local n="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); echo "ok   $n"
  else fail=$((fail+1)); echo "FAIL $n"; fi; }
fails() { ! "$@"; }

check "version"            "$TITAN" --version
check "help"               "$TITAN" --help
for c in info status cpu memory thermal gpu battery storage security network performance logs doctor; do
  check "titan $c"         "$TITAN" "$c"
done
check "processes -n 3"     "$TITAN" processes -n 3
check "monitor --once"     "$TITAN" monitor --once
check "profile list"       "$TITAN" performance profile
check "profile set"        "$TITAN" performance profile gaming
check "profile bad name"   fails "$TITAN" performance profile '../x'
check "bad interval"       fails "$TITAN" monitor -i 0
check "bad count"          fails "$TITAN" processes -n abc
check "unknown command"    fails "$TITAN" frobnicate
check "info credits BARATH" bash -c "'$TITAN' info | grep -q BARATH"
rm -rf "$TITAN_STATE_DIR" "$TITAN_CONFIG_DIR"
echo "passed: $pass failed: $fail"; [ "$fail" -eq 0 ]
