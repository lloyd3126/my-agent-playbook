#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
  printf 'usage: serve-player.sh <workspace> <player-directory> [port]\n'
  exit 0
fi
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  caption_die "usage: serve-player.sh <workspace> <player-directory> [port]"
fi

caption_set_paths "$1"
caption_assert_safe_workspace
caption_require_runtime

player_dir="$2"
port="${3:-8000}"
[ -d "$player_dir" ] || caption_die "player directory not found: $player_dir"
caption_require_file "$player_dir/index.html"

case "$port" in
  ''|*[!0-9]*) caption_die "port must be numeric" ;;
esac

caption_note "Serving $player_dir at http://127.0.0.1:$port/"
caption_note "Press Ctrl+C to stop."
exec "$CAPTION_PYTHON" -m http.server "$port" --bind 127.0.0.1 --directory "$player_dir"
