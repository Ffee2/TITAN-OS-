#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2015
# Path: ti/backend/repo.sh  (sourced by ti)
# Repository management. ti only creates or removes files named ti-NAME.list
# and its key; it never edits system repository files.

TI_SOURCES_D="$TI_APT_ETC/sources.list.d"
TI_KEYRINGS_D="$TI_APT_ETC/keyrings"
TI_REPO_BACKUP="$TITAN_STATE_DIR/repo-backup"

repo_list() {
  local f base tag found=0
  for f in "$TI_APT_ETC/sources.list" "$TI_SOURCES_D"/*.list "$TI_SOURCES_D"/*.sources; do
    [ -f "$f" ] || continue
    base=$(basename "$f"); tag=""
    case "$base" in ti-*) tag=" [managed by ti]" ;; esac
    printf '%s%s%s%s\n' "$C_PURPLE" "$base" "$C_RESET" "$tag"
    grep -E '^(deb |deb-src |URIs:|Suites:|Components:)' "$f" | sed 's/^/  /'
    found=1
  done
  [ "$found" -eq 1 ] || echo "no repository files found under $TI_APT_ETC"
}

repo_add() {  # usage: repo_add NAME URL SUITE COMPONENT... --key FILE
  local pos=() key="" c
  while [ $# -gt 0 ]; do
    case "$1" in
      --key) [ $# -ge 2 ] || die "--key needs a file"; key="$2"; shift 2 ;;
      *) pos+=("$1"); shift ;;
    esac
  done
  [ "${#pos[@]}" -ge 4 ] || die "usage: ti repo add NAME URL SUITE COMPONENT... --key KEYFILE"
  local name="${pos[0]}" url="${pos[1]}" suite="${pos[2]}" comps=("${pos[@]:3}")
  [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid repository name: $name"
  [[ "$url" =~ ^https?://[^[:space:]]+$ ]] || die "invalid URL: $url"
  [[ "$suite" =~ ^[A-Za-z0-9._/-]+$ ]] || die "invalid suite: $suite"
  for c in "${comps[@]}"; do
    [[ "$c" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid component: $c"
  done
  [ -n "$key" ] || die "a signing key is required (--key FILE.asc or FILE.gpg); unsigned repositories are not supported"
  [ -r "$key" ] || die "cannot read key file: $key"
  case "$key" in *.asc|*.gpg) ;; *) die "key file must end in .asc or .gpg" ;; esac
  case "$url" in http://*) log_warn "repository uses plain HTTP; package signatures are still verified" ;; esac

  local ext="${key##*.}" list keyd arch line
  list="$TI_SOURCES_D/ti-$name.list"; keyd="$TI_KEYRINGS_D/ti-$name.$ext"
  [ ! -e "$list" ] || die "repository '$name' already exists: $list"
  arch=$(dpkg --print-architecture 2>/dev/null) || die "cannot determine dpkg architecture"
  line="deb [arch=$arch signed-by=$keyd] $url $suite ${comps[*]}"

  echo "New repository entry:"; echo "  $line"
  titan_confirm "Add this repository?" || { log_info "cancelled"; return 1; }
  local tmp; tmp=$(mktemp) || die "cannot create temp file"
  printf '%s\n' "$line" >"$tmp"
  if be_priv mkdir -p "$TI_SOURCES_D" "$TI_KEYRINGS_D" &&
     be_priv install -m 0644 "$key" "$keyd" &&
     be_priv install -m 0644 "$tmp" "$list"; then
    rm -f "$tmp"
    ti_history_add repo-add "$name $url" ok
    log_info "added repository '$name'. Run 'ti update' to fetch its index."
  else
    rm -f "$tmp"; ti_history_add repo-add "$name $url" failed
    die "could not write repository files"
  fi
}

repo_remove() {  # usage: repo_remove NAME
  local name="${1:-}"
  [[ "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "usage: ti repo remove NAME"
  local list="$TI_SOURCES_D/ti-$name.list" f found=()
  for f in "$list" "$TI_KEYRINGS_D/ti-$name".asc "$TI_KEYRINGS_D/ti-$name".gpg; do
    [ -e "$f" ] && found+=("$f")
  done
  [ -e "$list" ] || die "no ti-managed repository named '$name' (system repositories are never touched)"
  echo "Files to remove:"; printf '  %s\n' "${found[@]}"
  titan_confirm "Remove repository '$name'? A backup is kept." || { log_info "cancelled"; return 1; }
  local bdir="$TI_REPO_BACKUP/$(date +%Y%m%d%H%M%S)-$name"
  mkdir -p "$bdir" && cp -p -- "${found[@]}" "$bdir"/ || die "backup failed, nothing removed"
  if be_priv rm -f -- "${found[@]}"; then
    ti_history_add repo-remove "$name" ok
    log_info "removed repository '$name'. Backup: $bdir"
  else
    ti_history_add repo-remove "$name" failed; die "could not remove files"
  fi
}
