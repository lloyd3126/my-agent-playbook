# YouTube 本機字幕流程：故障排除

先執行：

```bash
playbooks/youtube-local-caption/scripts/doctor.sh <workspace>
```

不要在不知道前一步是否成功時重跑整套流程。保存錯誤訊息、命令、影片 ID 與完成到哪一階段。

## `ffmpeg` 或 `ffprobe` 找不到

Whisper 需要真正的 FFmpeg 命令列工具，不是 `pip install ffmpeg`。

- macOS 且已有 Homebrew：`brew install ffmpeg`
- Ubuntu／Debian：`sudo apt-get update` 後執行 `sudo apt-get install ffmpeg`
- 其他平台參考 [FFmpeg 官方下載頁](https://ffmpeg.org/download.html)

需要系統層安裝時，Agent 先說明影響並取得使用者同意；不要默默使用 `sudo`。

## yt-dlp 顯示 JavaScript runtime 或 EJS 警告

目前完整 YouTube 支援可能需要 `yt-dlp-ejs` 和 JavaScript runtime。此 playbook 安裝 `yt-dlp[default]`，並在工作 runtime 內放置 Deno。確認：

```bash
<workspace>/.agent-tools/youtube-local-caption/bin/deno --version
<workspace>/.agent-tools/youtube-local-caption/.venv/bin/yt-dlp --verbose --version
```

使用腳本時會明確傳入專案私有 Deno。若仍有警告，先執行 `update-environment.sh`，再用短片測試。

## YouTube 回傳 403、要求登入或 bot 驗證

- 停止高速重試，確認 yt-dlp 是否為最新版。
- 先在一般瀏覽器確認影片確實可由使用者觀看。
- 年齡、會員、私人或地區限制不能靠本 playbook 規避。
- `--cookies-from-browser` 會讀取登入工作階段，屬於敏感權限；只有使用者明確要求、理解風險且有權存取時才使用。
- 不匯出 cookie 到 repository，不把 cookie 貼進聊天；完成後依需要登出或撤銷工作階段。

## 找不到繁體中文字幕

先列出實際可用字幕，不要假設語言代碼一定存在。依序採用：作者字幕、YouTube 自動字幕、Whisper 原文轉錄，再由 Agent 保留時間戳翻譯。Whisper 的翻譯任務目標是英文，不會直接產生繁中。

## VTT 已下載但播放器顯示 0 cues

- 確認檔案以 `WEBVTT` 開頭。
- 確認至少有一行 `00:00:00.000 --> 00:00:01.000` 格式的時間戳。
- YouTube VTT 可能在時間戳與文字間插入空行；模板 parser 已兼容，但仍要檢查內容不是空檔或錯誤頁面。
- 確認檔案是 UTF-8，而且沒有把 JSON 或 HTML 錯誤內容存成 `.vtt`。

## `file://` 可以播放影片但字幕載入失敗

瀏覽器通常會限制本機頁面 `fetch` 其他檔案。用 `serve-player.sh` 啟動 `http://127.0.0.1:<port>/`，不要直接雙擊 HTML。

## Plyr 載入失敗或離線

模板會保留瀏覽器原生 `<video controls>` 作為 fallback，因此 CDN 失敗仍應可播放。若影片也不能播，檢查：

- `video.mp4` 是否存在
- 瀏覽器是否支援影片 codec
- `ffprobe` 是否顯示視訊與音訊 stream
- HTTP server 的 terminal 是否回傳 404

## Whisper 安裝失敗

- 確認使用 Python 3.11 和 workflow-local `.venv`。
- 若 `tiktoken` 缺少適用 wheel，Whisper 上游可能要求 Rust；先保存完整錯誤，再依上游 README 安裝 Rust，不要直接修改系統 Python。
- 公司網路若有 TLS proxy，說明憑證問題；不要關閉 TLS 驗證作為長期解法。

## Whisper 模型下載中斷或磁碟不足

- 用 `doctor.sh` 檢查可用空間。
- 刪除前先確認模型目錄只屬於此 workflow：`<workspace>/.agent-tools/youtube-local-caption/models/`。
- 可以改用較小模型，例如 `small`，但要重新抽查品質。
- 不要把未完成模型移到 repository 或誤認為有效模型。

## Apple Silicon 出現 MPS／Torch segmentation fault

此流程預設使用 CPU。若手動指定 MPS 後 crash，改回：

```bash
transcribe.sh <workspace> <audio> <output> --model turbo --device cpu
```

CPU 可能較慢，但通常比反覆 crash 更可預期。

## 字幕逐漸不同步

- 比較 MP4 和音訊來源的實際 duration。
- 確認轉錄使用的音訊來自同一支影片版本。
- 檢查是否在翻譯時合併 cue 卻沒有保留原時間。
- 開頭準確、末段偏移通常是來源時基或剪輯版本不同，不是單一句翻譯問題。

## Port 已被占用

改用其他 port，例如：

```bash
serve-player.sh <workspace> <player-directory> 8010
```

如果上一個 server 還在執行，先回到其 terminal 按 `Ctrl+C`；不要任意終止不確定來源的程序。

