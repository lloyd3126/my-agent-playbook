# Release ZIP 從這裡開始

解壓縮後，用 Codex 開啟整個 "my-agent-playbook-vVERSION" 資料夾。Repository-scoped skills 已放在 ".agents/skills/"，不需要先安裝 plugin。

第一次可以直接說：

> 請使用 $youtube-caption-library，先檢查可攜式工作區。所有 workflow-owned 工具、模型、cache、影片與字幕都留在這個資料夾；說明影響後幫我啟動本機影片庫。

## 資料邊界

所有影片庫持久資料位於：

~~~text
<解壓縮資料夾>/.local/youtube-caption/
~~~

不使用 sudo、Homebrew、apt、系統 Python、系統 FFmpeg、全域 npm 或全域 pip，也不修改 shell profile，不建立 daemon。第一次設定需要網路；本機 Whisper 可能下載數 GB，OpenAI API 模式則會在明確授權後把音訊上傳並可能產生費用。

## 固定入口

~~~bash
scripts/portable/doctor.sh
scripts/portable/setup.sh --provider local --model turbo
scripts/portable/setup.sh --provider openai
scripts/portable/serve.sh 8000
scripts/portable/add-video.sh 'YOUTUBE_URL'
scripts/portable/update.sh
~~~

日常使用不必重裝。再次開啟同一資料夾，只要執行 doctor，再啟動 serve；jobs、模型、字幕和播放進度會繼續沿用。

## 更新與移除

"scripts/portable/update.sh" 預設只檢查；加 "--apply" 才會驗證 release 並更新 managed files，".local/" 永遠保留。

"scripts/portable/uninstall.sh" 預設只預覽。加 "--yes" 移除工具、模型與 cache但保留影片；加 "--include-generated --yes" 才會移除影片庫。完整移除時先停止 server，再把這個解壓縮資料夾移到垃圾桶。

若之後改成全域 Codex plugin 模式，請依根目錄 README 安裝；完整移除時還要移除 Codex plugin 與 marketplace。
