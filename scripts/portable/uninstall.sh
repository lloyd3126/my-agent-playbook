#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/common.sh"

exec "$PORTABLE_PLAYBOOK/scripts/uninstall.sh" "$PORTABLE_WORKSPACE" "$@"
