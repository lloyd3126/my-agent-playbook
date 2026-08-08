#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'usage: uninstall.sh <workspace> [--include-generated] [--include-system-ffmpeg] [--yes]\n'
}

[ "$#" -ge 1 ] || { usage >&2; exit 1; }
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

workspace_input="$1"
shift
include_generated=0
include_system_ffmpeg=0
confirmed=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --include-generated) include_generated=1; shift ;;
    --include-system-ffmpeg) include_system_ffmpeg=1; shift ;;
    --yes) confirmed=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) caption_die "unknown option: $1" ;;
  esac
done

caption_set_paths "$workspace_input"
caption_assert_safe_workspace

ffmpeg_installed_by_workflow=0
ffmpeg_package_manager="none"
if [ -f "$CAPTION_STATE" ]; then
  saved_ffmpeg_owner=$(caption_state_value "$CAPTION_STATE" FFMPEG_INSTALLED_BY_WORKFLOW)
  saved_ffmpeg_manager=$(caption_state_value "$CAPTION_STATE" FFMPEG_PACKAGE_MANAGER)
  ffmpeg_installed_by_workflow="${saved_ffmpeg_owner:-0}"
  ffmpeg_package_manager="${saved_ffmpeg_manager:-none}"
fi

printf 'Removal preview\n'
if [ -d "$CAPTION_RUNTIME" ]; then
  printf '  runtime: %s (%s)\n' "$CAPTION_RUNTIME" "$(du -sh "$CAPTION_RUNTIME" 2>/dev/null | awk '{print $1}')"
else
  printf '  runtime: not present\n'
fi

if [ "$include_generated" -eq 1 ]; then
  if [ -d "$CAPTION_WORKSPACE/jobs" ]; then
    printf '  generated jobs: %s (%s)\n' "$CAPTION_WORKSPACE/jobs" "$(du -sh "$CAPTION_WORKSPACE/jobs" 2>/dev/null | awk '{print $1}')"
  else
    printf '  generated jobs: not present\n'
  fi
else
  printf '  generated jobs: preserved\n'
fi

if [ "$include_system_ffmpeg" -eq 1 ]; then
  if [ "$ffmpeg_installed_by_workflow" = "1" ]; then
    printf '  system FFmpeg: remove through %s\n' "$ffmpeg_package_manager"
  else
    printf '  system FFmpeg: preserved; workflow cannot prove it installed this package\n'
  fi
else
  printf '  system FFmpeg: preserved\n'
fi

if [ "$confirmed" -ne 1 ]; then
  printf 'dry-run: nothing was removed; rerun with --yes after checking the paths above\n'
  exit 0
fi

if [ "$include_system_ffmpeg" -eq 1 ] && [ "$ffmpeg_installed_by_workflow" = "1" ]; then
  case "$ffmpeg_package_manager" in
    brew) brew uninstall ffmpeg ;;
    apt) sudo apt-get remove -y ffmpeg ;;
    dnf) sudo dnf remove -y ffmpeg ;;
    pacman) sudo pacman -R --noconfirm ffmpeg ;;
    *) caption_note "warning: unknown package manager; system FFmpeg was not removed" ;;
  esac
fi

if [ -d "$CAPTION_RUNTIME" ]; then
  rm -rf -- "$CAPTION_RUNTIME"
fi

if [ "$include_generated" -eq 1 ] && [ -d "$CAPTION_WORKSPACE/jobs" ]; then
  rm -rf -- "$CAPTION_WORKSPACE/jobs"
fi

caption_note "Removal complete. The repository clone and browser downloads were not removed."
