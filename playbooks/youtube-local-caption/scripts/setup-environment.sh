#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
PLAYBOOK_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P)
. "$SCRIPT_DIR/lib.sh"

usage() {
  printf 'usage: setup-environment.sh <workspace> [--model NAME] [--skip-model] [--install-ffmpeg]\n'
}

[ "$#" -ge 1 ] || { usage >&2; exit 1; }
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  usage
  exit 0
fi

workspace_input="$1"
shift
model_name="turbo"
skip_model=0
install_ffmpeg=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model)
      [ "$#" -ge 2 ] || caption_die "--model requires a value"
      model_name="$2"
      shift 2
      ;;
    --skip-model)
      skip_model=1
      shift
      ;;
    --install-ffmpeg)
      install_ffmpeg=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      caption_die "unknown option: $1"
      ;;
  esac
done

case "$model_name" in
  ''|*[!A-Za-z0-9._-]*) caption_die "model name contains unsupported characters: $model_name" ;;
esac

caption_set_paths "$workspace_input"
caption_assert_safe_workspace
caption_require_command curl
caption_require_command unzip

mkdir -p "$CAPTION_WORKSPACE" "$CAPTION_BIN" "$CAPTION_MODELS" "$CAPTION_UV_CACHE" "$CAPTION_UV_PYTHON" "$CAPTION_DENO_CACHE"

ffmpeg_installed_by_workflow=0
ffmpeg_package_manager="none"
if [ -f "$CAPTION_STATE" ]; then
  saved_ffmpeg_owner=$(caption_state_value "$CAPTION_STATE" FFMPEG_INSTALLED_BY_WORKFLOW)
  saved_ffmpeg_manager=$(caption_state_value "$CAPTION_STATE" FFMPEG_PACKAGE_MANAGER)
  ffmpeg_installed_by_workflow="${saved_ffmpeg_owner:-0}"
  ffmpeg_package_manager="${saved_ffmpeg_manager:-none}"
fi

install_ffmpeg_package() {
  case "$(uname -s)" in
    Darwin)
      command -v brew >/dev/null 2>&1 || caption_die "Homebrew is required for automatic FFmpeg installation on macOS; install it manually or install FFmpeg yourself"
      brew install ffmpeg
      ffmpeg_package_manager="brew"
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y ffmpeg
        ffmpeg_package_manager="apt"
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y ffmpeg
        ffmpeg_package_manager="dnf"
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm ffmpeg
        ffmpeg_package_manager="pacman"
      else
        caption_die "no supported package manager found; install FFmpeg from https://ffmpeg.org/download.html"
      fi
      ;;
    *)
      caption_die "automatic FFmpeg installation is supported only on macOS and Linux"
      ;;
  esac
  ffmpeg_installed_by_workflow=1
}

if ! command -v ffmpeg >/dev/null 2>&1 || ! command -v ffprobe >/dev/null 2>&1; then
  if [ "$install_ffmpeg" -eq 1 ]; then
    install_ffmpeg_package
  else
    caption_die "FFmpeg is missing. Install it manually, or rerun with --install-ffmpeg after the user approves a system package change"
  fi
fi

caption_note "Installing workflow-local uv..."
curl -LsSf https://astral.sh/uv/install.sh | env UV_UNMANAGED_INSTALL="$CAPTION_BIN" sh
[ -x "$CAPTION_UV" ] || caption_die "uv installation did not produce $CAPTION_UV"

install_deno_binary() {
  local deno_target
  local temp_dir
  local archive_path

  case "$(uname -s):$(uname -m)" in
    Darwin:arm64) deno_target="aarch64-apple-darwin" ;;
    Darwin:x86_64) deno_target="x86_64-apple-darwin" ;;
    Linux:aarch64|Linux:arm64) deno_target="aarch64-unknown-linux-gnu" ;;
    Linux:x86_64|Linux:amd64) deno_target="x86_64-unknown-linux-gnu" ;;
    *) caption_die "unsupported Deno platform: $(uname -s) $(uname -m)" ;;
  esac

  temp_dir=$(mktemp -d)
  archive_path="$temp_dir/deno.zip"
  trap "rm -rf -- '$temp_dir'" EXIT
  curl -fL "https://github.com/denoland/deno/releases/latest/download/deno-${deno_target}.zip" -o "$archive_path"
  unzip -q "$archive_path" -d "$temp_dir"
  install -m 0755 "$temp_dir/deno" "$CAPTION_DENO"
  rm -rf -- "$temp_dir"
  trap - EXIT
}

if [ ! -x "$CAPTION_DENO" ]; then
  caption_note "Installing workflow-local Deno..."
  install_deno_binary
fi

caption_note "Installing Python 3.11 and creating the isolated environment..."
"$CAPTION_UV" python install 3.11
if [ ! -x "$CAPTION_PYTHON" ]; then
  "$CAPTION_UV" venv --python 3.11 "$CAPTION_VENV"
fi

caption_note "Installing Whisper and yt-dlp..."
"$CAPTION_UV" pip install --python "$CAPTION_PYTHON" --upgrade -r "$PLAYBOOK_DIR/requirements.txt"
"$CAPTION_UV" pip freeze --python "$CAPTION_PYTHON" > "$CAPTION_RUNTIME/requirements.lock.txt"

if [ "$skip_model" -eq 0 ]; then
  caption_note "Downloading Whisper model: $model_name"
  "$CAPTION_PYTHON" -c 'import sys, whisper; whisper.load_model(sys.argv[1], download_root=sys.argv[2]); print("model ready:", sys.argv[1])' "$model_name" "$CAPTION_MODELS"
fi

{
  printf 'FFMPEG_INSTALLED_BY_WORKFLOW=%s\n' "$ffmpeg_installed_by_workflow"
  printf 'FFMPEG_PACKAGE_MANAGER=%s\n' "$ffmpeg_package_manager"
  printf 'PYTHON_SERIES=3.11\n'
  printf 'DEFAULT_MODEL=%s\n' "$model_name"
} > "$CAPTION_STATE"

caption_note "Setup complete. Run: $SCRIPT_DIR/doctor.sh $CAPTION_WORKSPACE"
