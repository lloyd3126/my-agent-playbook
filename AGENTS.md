# Agent rules

本 repository 以 Codex skills 為操作入口。先選擇 `.agents/skills/` 中符合任務的 skill；該入口會要求讀取 `plugins/my-agent-playbook/skills/` 的完整實作。使用者本次明確指示優先。

## Evidence and knowledge

- 公司、人物、帳號、法規、財務數字與近期事件可能改變；依 canonical skill 的證據層級查證目前資訊。
- 保留來源連結與日期，清楚區分直接事實、來源評論與 Agent 推論；不可捏造無法存取的數字或貼文。
- 只更新任務指定的 `knowledge/` 記錄，保留既有有用內容與可追溯來源。
- 公司分析不是個人化投資建議。

## External state

- 公開資訊讀取、本機診斷與草稿可在任務範圍內執行。
- 發文、留言、按讚、追蹤、轉發、刪除、購買、登入或撤銷帳號權限，需要對精確動作的明確授權。
- 發布前回報帳號、完整內容、順序、連結、媒體與作用範圍；授權後依序執行並回傳結果 URL。
- 不要求使用者貼密碼、cookie、token、API key 或雙重驗證碼；登入由使用者在正式介面完成。

## Update and removal

- 檢查更新是 read-only；只有使用者要求更新才加 `--apply`。
- Git 只接受 clean worktree 的 fast-forward。Release ZIP 更新必須驗證 checksum 與內部 manifest，保留 `.local/`。
- Git／Release ZIP 模式沒有影片 runtime。完整移除前解析精確 repository root、檢查 `.local/`，再取得移動該資料夾到垃圾桶的確認。
- 不對 home 或廣泛父資料夾使用遞迴刪除。
- 影片下載、轉錄、翻譯與播放器需求應導向 `https://github.com/lloyd3126/xeruca-player` 的 `$watch-video`。

## Repository maintenance

- 完整 skill 的唯一來源在 `plugins/my-agent-playbook/skills/`；`.agents/skills/` 只做 repository discovery bridge。
- Plugin、marketplace、每個 `SKILL.md` 與 `agents/openai.yaml` 都要通過官方 validator。
- 文件命令與腳本需有語法或最小整合測試。Credentials 與個人資料不得 commit。
- 只有使用者明確要求時才 commit、push、release 或變更外部 repository。
