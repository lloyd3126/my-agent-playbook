#!/usr/bin/env bash

PORTABLE_SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PORTABLE_ROOT=$(cd "$PORTABLE_SCRIPT_DIR/../.." && pwd -P)
PORTABLE_WORKSPACE="$PORTABLE_ROOT/.local/youtube-caption"
PORTABLE_PLAYBOOK="$PORTABLE_ROOT/playbooks/youtube-local-caption"

portable_require_layout() {
  [ -f "$PORTABLE_ROOT/VERSION" ] || { printf 'error: VERSION is missing from %s\n' "$PORTABLE_ROOT" >&2; exit 1; }
  [ -f "$PORTABLE_PLAYBOOK/PLAYBOOK.md" ] || { printf 'error: YouTube playbook is missing\n' >&2; exit 1; }
  case "$PORTABLE_WORKSPACE/" in
    "$PORTABLE_ROOT"/.local/*) ;;
    *) printf 'error: portable workspace escaped the repository root\n' >&2; exit 1 ;;
  esac
}

portable_require_layout
