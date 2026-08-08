#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'usage: transcribe.sh <workspace> <video-id> [--model NAME] [--language CODE] [--track CODE] [--device cpu|cuda]\n'
}

[ "$#" -ge 1 ] || { usage >&2; exit 1; }
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then usage; exit 0; fi
[ "$#" -ge 2 ] || { usage >&2; exit 1; }

workspace_input="$1"
video_id="$2"
shift 2
model_name="turbo"
language_code=""
track_code=""
device_name="cpu"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model) [ "$#" -ge 2 ] || caption_die "--model requires a value"; model_name="$2"; shift 2 ;;
    --language) [ "$#" -ge 2 ] || caption_die "--language requires a value"; language_code="$2"; shift 2 ;;
    --track) [ "$#" -ge 2 ] || caption_die "--track requires a value"; track_code="$2"; shift 2 ;;
    --device) [ "$#" -ge 2 ] || caption_die "--device requires a value"; device_name="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) caption_die "unknown option: $1" ;;
  esac
done

caption_validate_video_id "$video_id"
case "$model_name" in ''|*[!A-Za-z0-9._-]*) caption_die "invalid model name: $model_name" ;; esac
[ "$device_name" = "cpu" ] || [ "$device_name" = "cuda" ] || caption_die "device must be cpu or cuda"
if [ -n "$language_code" ]; then caption_validate_language "$language_code"; fi
if [ -z "$track_code" ]; then track_code="${language_code:-source}"; fi
caption_validate_language "$track_code"

caption_set_paths "$workspace_input"
caption_assert_safe_workspace
caption_require_runtime
caption_require_command ffmpeg

job_dir="$CAPTION_JOBS/$video_id"
source_dir="$job_dir/source"
whisper_dir="$job_dir/whisper"
caption_dir="$job_dir/captions"
audio_file="$source_dir/audio.m4a"
video_file="$source_dir/video.mp4"
[ -d "$job_dir" ] || caption_die "job not found: $job_dir"
caption_require_file "$video_file"
mkdir -p "$whisper_dir" "$caption_dir" "$CAPTION_MODELS" "$job_dir/logs"

fail_job() {
  local exit_code=$?
  trap - ERR
  caption_job_state update --job-dir "$job_dir" --state failed --stage transcription --message "本機轉錄失敗" --error "transcribe.sh exited with status $exit_code" --record-history >/dev/null || true
  exit "$exit_code"
}
trap fail_job ERR

if [ ! -f "$audio_file" ]; then
  caption_note "Extracting an audio copy from video.mp4..."
  "$CAPTION_PYTHON" "$CAPTION_PROGRESS_RUNNER" \
    --job-dir "$job_dir" --state transcribing --stage extracting_audio --message "正在從影片擷取音訊" --success-message "音訊擷取完成" -- \
    ffmpeg -nostdin -hide_banner -y -i "$video_file" -vn -c:a aac -b:a 192k "$audio_file"
  caption_job_state asset --job-dir "$job_dir" --name audio --path "$audio_file" >/dev/null
fi

fp16_value="False"
if [ "$device_name" = "cuda" ]; then fp16_value="True"; fi
whisper_args=("$audio_file" --model "$model_name" --model_dir "$CAPTION_MODELS" --output_dir "$whisper_dir" --output_format all --device "$device_name" --fp16 "$fp16_value" --verbose False)
if [ -n "$language_code" ]; then whisper_args+=(--language "$language_code"); fi

caption_note "Transcribing with model=$model_name device=$device_name..."
"$CAPTION_PYTHON" "$CAPTION_PROGRESS_RUNNER" \
  --job-dir "$job_dir" --state transcribing --stage whisper --message "Whisper 正在本機轉錄" --success-message "Whisper 轉錄完成" -- \
  "$CAPTION_WHISPER" "${whisper_args[@]}"

vtt_file="$whisper_dir/$(basename "${audio_file%.*}").vtt"
if [ ! -f "$vtt_file" ]; then
  vtt_file=$(find "$whisper_dir" -maxdepth 1 -type f -name '*.vtt' -print | LC_ALL=C sort | head -n 1)
fi
[ -n "$vtt_file" ] || caption_die "Whisper finished without producing a VTT file"
caption_validate_vtt "$vtt_file"
cp "$vtt_file" "$caption_dir/$track_code.vtt"
caption_validate_vtt "$caption_dir/$track_code.vtt"
caption_job_state subtitle --job-dir "$job_dir" --language "$track_code" --path "$caption_dir/$track_code.vtt" --source whisper --label "$track_code" >/dev/null

if [ -f "$caption_dir/zh-TW.vtt" ]; then
  caption_job_state update --job-dir "$job_dir" --state ready --stage complete --message "影片與繁體中文字幕已可觀看" --progress 100 --clear-error --record-history >/dev/null
else
  caption_job_state update --job-dir "$job_dir" --state needs_translation --stage translation --message "本機轉錄已完成；等待繁中翻譯" --progress 0 --clear-error --record-history >/dev/null
fi

trap - ERR
caption_note "Transcription complete: $caption_dir/$track_code.vtt"
