#!/usr/bin/env bash
# Path: tests/test_ti.sh  (safe: never installs or removes real packages)
# Run from the project root: bash tests/test_ti.sh
set -u
TI="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ti/bin/ti"
export TITAN_STATE_DIR; TITAN_STATE_DIR="$(mktemp -d)"
export TI_APT_ETC; TI_APT_ETC="$(mktemp -d)"
export NO_COLOR=1
pass=0; fail=0
check() { local n="$1"; shift
  if "$@" >/dev/null 2>&1; then pass=$((pass+1)); echo "ok   $n"
  else fail=$((fail+1)); echo "FAIL $n"; fi; }
fails() { ! "$@"; }
key="$TI_APT_ETC/k.asc"; echo dummy >"$key"

check "version"                  "$TI" --version
check "help"                     "$TI" --help
check "unknown command fails"    fails "$TI" frobnicate
check "bad package name fails"   fails "$TI" add 'bad;name'
check "missing package fails"    fails "$TI" add no-such-package-xyz
check "protected remove fails"   fails "$TI" remove bash
check "remove needs confirm"     fails "$TI" remove no-such-package-xyz
check "repo without key fails"   fails "$TI" repo add t https://example.org/apt stable main </dev/null
check "repo add with -y"         "$TI" -y repo add t https://example.org/apt stable main --key "$key"
check "repo duplicate fails"     fails "$TI" -y repo add t https://example.org/apt stable main --key "$key"
check "repo list shows entry"    bash -c "'$TI' repo list | grep -q ti-t.list"
check "repo remove needs tty"    fails "$TI" repo remove t </dev/null
check "repo remove with -y"      "$TI" -y repo remove t
check "history records"          bash -c "'$TI' history | grep -q repo-add"
rm -rf "$TITAN_STATE_DIR" "$TI_APT_ETC"
echo "passed: $pass failed: $fail"; [ "$fail" -eq 0 ]
