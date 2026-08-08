# 從這裡開始

這是可攜式 Agent 作業手冊。解壓縮後，請用 Codex 或其他 Agent **開啟整個資料夾**，再告訴 Agent：

> 請先閱讀 `START-HERE.md` 與 `AGENTS.md`，檢查可攜式工作區，不要在這個資料夾之外安裝工具。完成環境說明後，幫我啟動本機影片庫。

## 你會得到什麼

- 固定的本機影片庫首頁、狀態表與 iframe 播放 modal
- workflow-local uv、Python、virtual environment、Deno、FFmpeg、yt-dlp、Whisper 與模型
- 下載影片、字幕、任務 log、播放進度與所有已知快取
- 不需要 Git、Homebrew、PHP、Node、Deno、FFmpeg 或 Python 預先存在

所有由 YouTube 字幕流程控制的持久資料都放在：

```text
<這個資料夾>/.local/youtube-caption/
```

第一次設定仍需要網路，且 Python 套件、Whisper 模型和影片可能使用數 GB。Agent 必須先說明估計下載量與磁碟影響，再執行設定。

## Agent 使用的固定入口

```bash
scripts/portable/doctor.sh
scripts/portable/setup.sh --model turbo
scripts/portable/serve.sh 8000
scripts/portable/add-video.sh 'https://www.youtube.com/watch?v=VIDEO_ID'
```

低資源電腦可把 `turbo` 改成 `small`；只建立工具、暫不下載模型可使用 `--skip-model`。

日常使用時不必重裝。再次開啟同一資料夾後，Agent 只要執行 `doctor.sh`，然後重新啟動 `serve.sh`；原有 jobs、模型與進度會繼續沿用。

## 移除契約

先預覽流程內資料：

```bash
scripts/portable/uninstall.sh
```

移除工具與快取、保留影片庫：

```bash
scripts/portable/uninstall.sh --yes
```

連影片、字幕、log 與播放進度一起移除：

```bash
scripts/portable/uninstall.sh --include-generated --yes
```

若要完整移除整套作業手冊，先停止本機 server 和處理程序，再刪除這個解壓縮資料夾即可。流程不修改 shell profile、不使用 `sudo`、不安裝系統套件，也不建立背景 daemon。作業系統的一般暫存檔、瀏覽器歷史與瀏覽器 cache 不由本專案控制，可能依瀏覽器政策自行保留；網站播放進度則存回 job 資料夾，不使用 `localStorage`。

## Release 驗證

下載頁會同時提供 ZIP 與 `.sha256`。可在 macOS 驗證：

```bash
shasum -a 256 -c my-agent-playbook-v0.1.0-portable.zip.sha256
```

Linux 通常可使用：

```bash
sha256sum -c my-agent-playbook-v0.1.0-portable.zip.sha256
```
