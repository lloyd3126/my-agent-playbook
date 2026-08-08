#!/usr/bin/env bash
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
  printf 'usage: doctor.sh <workspace>\n'
  exit 0
fi
if [ "$#" -ne 1 ]; then
  caption_die "usage: doctor.sh <workspace>"
fi

caption_set_paths "$1"
caption_assert_safe_workspace

printf 'workflow: youtube-local-caption\n'
printf 'workspace: %s\n' "$CAPTION_WORKSPACE"
printf 'platform: %s\n' "$(uname -s 2>/dev/null || printf unknown)"
printf 'architecture: %s\n' "$(uname -m 2>/dev/null || printf unknown)"

disk_target="$CAPTION_WORKSPACE"
if [ ! -e "$disk_target" ]; then
  disk_target=$(dirname "$disk_target")
fi
if [ -e "$disk_target" ]; then
  available_kb=$(df -Pk "$disk_target" 2>/dev/null | awk 'NR == 2 { print $4 }')
  if [ -n "$available_kb" ]; then
    printf 'available-disk-kb: %s\n' "$available_kb"
  fi
fi

missing=0
for command_name in curl unzip ffmpeg ffprobe; do
  if command -v "$command_name" >/dev/null 2>&1; then
    command_path=$(command -v "$command_name")
    printf 'command-%s: %s\n' "$command_name" "$command_path"
  else
    printf 'command-%s: missing\n' "$command_name"
    missing=1
  fi
done

if [ -x "$CAPTION_UV" ]; then
  printf 'uv: %s\n' "$($CAPTION_UV --version 2>/dev/null || printf installed-but-unreadable)"
else
  printf 'uv: not-installed-by-workflow\n'
  missing=1
fi

if [ -x "$CAPTION_DENO" ]; then
  printf 'deno: %s\n' "$($CAPTION_DENO --version 2>/dev/null | sed -n '1p')"
else
  printf 'deno: not-installed-by-workflow\n'
  missing=1
fi

if [ -x "$CAPTION_PYTHON" ]; then
  printf 'python: %s\n' "$($CAPTION_PYTHON --version 2>&1)"
else
  printf 'python: not-installed-by-workflow\n'
  missing=1
fi

if [ -x "$CAPTION_YTDLP" ]; then
  printf 'yt-dlp: %s\n' "$($CAPTION_YTDLP --version 2>/dev/null)"
else
  printf 'yt-dlp: not-installed-by-workflow\n'
  missing=1
fi

if [ -x "$CAPTION_WHISPER" ]; then
  whisper_version=$($CAPTION_PYTHON -c 'import importlib.metadata; print(importlib.metadata.version("openai-whisper"))' 2>/dev/null || printf installed)
  printf 'whisper: %s\n' "$whisper_version"
else
  printf 'whisper: not-installed-by-workflow\n'
  missing=1
fi

if [ -d "$CAPTION_MODELS" ]; then
  model_count=$(find "$CAPTION_MODELS" -maxdepth 1 -type f | wc -l | tr -d ' ')
  printf 'whisper-model-files: %s\n' "$model_count"
else
  printf 'whisper-model-files: 0\n'
fi

if [ "$missing" -eq 0 ]; then
  printf 'status: ready\n'
  exit 0
fi

printf 'status: setup-required\n'
exit 1
