#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
. "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'usage: transcribe.sh <workspace> <audio-file> <output-directory> [--model NAME] [--language CODE] [--device cpu|cuda]\n'
}

[ "$#" -ge 1 ] || { usage >&2; exit 1; }
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi
[ "$#" -ge 3 ] || { usage >&2; exit 1; }

workspace_input="$1"
audio_input="$2"
output_input="$3"
shift 3

model_name="turbo"
language_code=""
device_name="cpu"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model)
      [ "$#" -ge 2 ] || caption_die "--model requires a value"
      model_name="$2"
      shift 2
      ;;
    --language)
      [ "$#" -ge 2 ] || caption_die "--language requires a value"
      language_code="$2"
      shift 2
      ;;
    --device)
      [ "$#" -ge 2 ] || caption_die "--device requires a value"
      device_name="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) caption_die "unknown option: $1" ;;
  esac
done

caption_set_paths "$workspace_input"
caption_assert_safe_workspace
caption_require_runtime
caption_require_command ffmpeg
caption_require_file "$audio_input"

mkdir -p "$output_input" "$CAPTION_MODELS"

fp16_value="False"
if [ "$device_name" = "cuda" ]; then
  fp16_value="True"
fi

whisper_args=(
  "$audio_input"
  --model "$model_name"
  --model_dir "$CAPTION_MODELS"
  --output_dir "$output_input"
  --output_format all
  --device "$device_name"
  --fp16 "$fp16_value"
  --verbose False
)

if [ -n "$language_code" ]; then
  whisper_args+=(--language "$language_code")
fi

caption_note "Transcribing with model=$model_name device=$device_name..."
"$CAPTION_WHISPER" "${whisper_args[@]}"

vtt_file=$(find "$output_input" -maxdepth 1 -type f -name '*.vtt' | head -n 1)
[ -n "$vtt_file" ] || caption_die "Whisper finished without producing a VTT file"
caption_validate_vtt "$vtt_file"

caption_note "Transcription complete: $output_input"
caption_note "VTT: $vtt_file"
