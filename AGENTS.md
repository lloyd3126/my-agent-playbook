# Agent rules

本 repository 以 Codex skills 為操作入口。先選擇 ".agents/skills/" 中符合任務的 skill；該入口會要求讀取 "plugins/my-agent-playbook/skills/" 的完整實作。使用者本次明確指示優先。

## Portable contract

- 根目錄含 "START-HERE.md" 與 "VERSION" 時，預設 workspace 是 ".local/youtube-caption/"。
- 不在 repository 之外安裝影片庫工具，不使用 sudo、系統套件管理器、全域 pip/npm，也不修改 shell profile。
- uv、Python、venv、Deno、FFmpeg、yt-dlp、Whisper、OpenAI SDK、模型與已知 cache 都留在 workspace。
- Server 只以前景程序綁定 localhost，不建立 daemon 或開機啟動項目。
- 初次大型下載前說明網路與磁碟影響。

## Transcription providers

- 優先使用影片已有的作者或自動字幕。
- 本機 provider 不把音訊傳出裝置，但需要較大的套件與模型。
- OpenAI provider 只有在使用者明確同意這次音訊上傳後才能使用；命令必須帶 "--allow-api-upload" 或 "--consent-to-upload"。
- 不因環境中有 "OPENAI_API_KEY" 就推定同意。Key 不得寫進檔案、log、狀態、Git 或對話輸出。
- OpenAI API translation endpoint不是繁中翻譯方案；繁中字幕需保留 VTT cue 時間軸另行翻譯。

## External state

- 公開資訊讀取與本機診斷可在任務範圍內執行。
- 發文、留言、按讚、追蹤、轉發、購買、刪除、登入或撤銷帳號權限，需要對精確動作的明確授權。
- 不要求使用者貼密碼、cookie、token、API key 或雙重驗證碼；登入由使用者在正式介面完成。
- 下載媒體前確認使用者有權處理，不繞過 DRM、付費、會員、私人、地區或帳號限制。

## Long-running jobs and UI

- "status.json"、stage、progress、process metadata 與 log 是持久狀態來源；中斷後依檔案恢復，不依記憶猜測。
- 影片庫首頁保持 read-mostly；新增、重試、取消、刪除與翻譯由 Agent 或明確命令執行。
- 觀看使用同源 iframe modal；關閉時釋放播放器，播放進度寫回 job。
- Server 使用 allowlist route，不提供任意目錄瀏覽，不暴露工具、模型或 credentials。

## Update and removal

- 檢查更新是 read-only；只有使用者要求更新才加 "--apply"。
- Git 只接受 clean worktree 的 fast-forward。Portable release 必須驗證外部 checksum 與內部 manifest，保留 ".local/"。
- 移除先預覽；工具與使用者產物分開。只有明確要求才包含影片、字幕、log 和播放進度。
- 完整 portable 移除前停止程序，解析精確 repository root，再確認是否移到垃圾桶。不要對 home 或廣泛父資料夾使用遞迴刪除。

## Repository maintenance

- 完整 skill 的唯一來源在 "plugins/my-agent-playbook/skills/"；".agents/skills/" 只做 repository discovery bridge。
- Plugin、marketplace、每個 SKILL.md 與 agents/openai.yaml 都要通過官方 validator。
- 文件命令與腳本需有語法或最小整合測試。大型媒體、模型、環境、cache 與 credentials 不得 commit。
- 只有使用者明確要求時才 commit、push、release 或變更外部 repository。
