#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

if [ "$#" -eq 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
  printf 'usage: download-video.sh <workspace> <youtube-url>\n'
  exit 0
fi
if [ "$#" -ne 2 ]; then
  caption_die "usage: download-video.sh <workspace> <youtube-url>"
fi

caption_set_paths "$1"
caption_assert_safe_workspace
caption_require_runtime
caption_require_command ffmpeg
caption_require_command ffprobe

video_url="$2"
common_args=(--js-runtimes "deno:$CAPTION_DENO" --no-playlist)

caption_note "Resolving video metadata..."
video_id=$(
  "$CAPTION_YTDLP" "${common_args[@]}" --skip-download --print '%(id)s' "$video_url" | tail -n 1
)
video_title=$(
  "$CAPTION_YTDLP" "${common_args[@]}" --skip-download --print '%(title)s' "$video_url" | tail -n 1
)

[ -n "$video_id" ] || caption_die "could not resolve a video ID"
case "$video_id" in
  *[!A-Za-z0-9_-]*) caption_die "unsafe video ID returned by yt-dlp: $video_id" ;;
esac

job_dir="$CAPTION_WORKSPACE/jobs/$video_id"
source_dir="$job_dir/source"
caption_dir="$job_dir/youtube-captions"
mkdir -p "$source_dir" "$caption_dir"

caption_note "Attempting to download available English and Traditional Chinese subtitles..."
if ! "$CAPTION_YTDLP" "${common_args[@]}" \
  --skip-download \
  --write-subs \
  --write-auto-subs \
  --sub-langs 'en.*,zh-Hant.*,zh-TW.*' \
  --sub-format vtt \
  --output "$caption_dir/%(id)s.%(ext)s" \
  "$video_url"; then
  caption_note "warning: subtitle download was incomplete; continuing with media download"
fi

caption_note "Downloading a browser-oriented MP4..."
"$CAPTION_YTDLP" "${common_args[@]}" \
  --format 'bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b' \
  --merge-output-format mp4 \
  --recode-video mp4 \
  --output "$source_dir/video.%(ext)s" \
  "$video_url"

caption_note "Downloading an audio copy for Whisper..."
"$CAPTION_YTDLP" "${common_args[@]}" \
  --format ba \
  --extract-audio \
  --audio-format m4a \
  --audio-quality 0 \
  --output "$source_dir/audio.%(ext)s" \
  "$video_url"

video_file=$(find "$source_dir" -maxdepth 1 -type f -name 'video.mp4' | head -n 1)
audio_file=$(find "$source_dir" -maxdepth 1 -type f -name 'audio.m4a' | head -n 1)
[ -n "$video_file" ] || caption_die "video.mp4 was not created"
[ -n "$audio_file" ] || caption_die "audio.m4a was not created"

ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name -of default=noprint_wrappers=1 "$video_file" > "$job_dir/ffprobe.txt"

{
  printf 'video-id: %s\n' "$video_id"
  printf 'title: %s\n' "$video_title"
  printf 'source-url: %s\n' "$video_url"
  printf 'video-file: %s\n' "$video_file"
  printf 'audio-file: %s\n' "$audio_file"
} > "$job_dir/manifest.txt"

caption_note "Download complete: $job_dir"
caption_note "Video: $video_file"
caption_note "Audio: $audio_file"
