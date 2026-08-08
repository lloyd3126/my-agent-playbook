---
name: youtube-caption-library
description: Build, run, repair, or remove a portable local YouTube video library with download status, timestamped subtitles, translation handoff, and an iframe player. Use when a user wants to archive an authorized YouTube video, obtain captions, transcribe locally or through the OpenAI API, translate captions, resume jobs, or operate the fixed localhost library homepage.
---

# YouTube Caption Library

Keep the user on one localhost library homepage while Codex manages downloads, captions, transcription, translation, recovery, and cleanup through deterministic scripts.

## Start Safely

1. Read [references/workflow.md](references/workflow.md) for a first installation, interrupted job, cleanup, or unfamiliar request. Read [references/troubleshooting.md](references/troubleshooting.md) when a check fails.
2. Confirm that the user has the right to download and process the requested media. Do not bypass DRM, paywalls, memberships, private access, region restrictions, or account controls.
3. Use the repository-local workspace ".local/youtube-caption/" for a portable release. For a developer checkout, use a dedicated workspace supplied by the user.
4. Run "scripts/portable/doctor.sh" from the repository root in portable mode, or "scripts/doctor.sh WORKSPACE" from this skill.
5. Before the first setup, explain network use and approximate disk impact. Local Whisper can consume several GB; the API provider avoids the model download but uploads audio externally and may incur API charges.

## Choose a Provider

- Prefer available author or automatic YouTube captions; they avoid transcription entirely.
- Use "local" when audio must remain on the device. It installs Whisper, PyTorch, and the selected model inside the workspace.
- Use "openai" only after explicit user authorization to upload audio. Require "OPENAI_API_KEY" in the process environment and never save or print it. The workflow uses "whisper-1" because timestamped segment output is required.
- If both are installed, the default remains local unless the user chooses API upload.

Portable setup:

~~~bash
scripts/portable/setup.sh --provider local --model turbo
scripts/portable/setup.sh --provider openai
scripts/portable/setup.sh --provider both --model turbo
~~~

Do not use sudo, Homebrew, apt, a global pip, or a global npm install. The setup script installs uv, Python, Deno, FFmpeg, Python packages, models, and known caches below the workspace.

## Run the Library

~~~bash
scripts/portable/serve.sh 8000
scripts/portable/add-video.sh 'https://www.youtube.com/watch?v=VIDEO_ID'
~~~

For explicit OpenAI transcription:

~~~bash
export OPENAI_API_KEY='set-this-in-the-terminal'
scripts/portable/add-video.sh 'YOUTUBE_URL' --provider openai --allow-api-upload
~~~

Never add "--allow-api-upload" merely because an API key exists. It records that the user authorized this upload.

The homepage is "http://127.0.0.1:8000/". It is a read-mostly status surface: downloads, transcription, translation, failures, logs, provider metadata, storage, captions, and playback progress remain visible. Watching opens a same-origin iframe modal so the user does not leave the library.

## Translation

Use an existing target-language track when available. Otherwise translate cue text while preserving every VTT timestamp and cue order, validate the VTT, then import it:

~~~bash
plugins/my-agent-playbook/skills/youtube-caption-library/scripts/import-caption.sh \
  .local/youtube-caption VIDEO_ID zh-TW translated.vtt \
  --source agent-translation --label '繁體中文'
~~~

Do not claim that Whisper translated into Traditional Chinese; Whisper's translation task targets English.

## Recovery, Updating, and Removal

- Re-run the same job command after interruption; durable "status.json" and logs are the source of truth.
- Use $playbook-manager for repository/plugin updates. Updating code must preserve ".local/" and jobs.
- Preview runtime removal with "scripts/portable/uninstall.sh". Add "--yes" to remove tools and caches while retaining jobs; add "--include-generated --yes" only when the user explicitly wants videos, subtitles, logs, and progress removed.
- For complete portable removal, stop foreground processes, clean up as authorized, then move the exact extracted repository folder to Trash. No workflow-owned persistent data should exist elsewhere.

At handoff, report the provider, workspace, homepage, final job state, artifacts, next-use command, and exact removal boundary.
