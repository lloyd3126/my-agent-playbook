# Release ZIP 從這裡開始

用 Codex 開啟整個解壓縮後的 `my-agent-playbook-vVERSION` 資料夾。Repository-scoped skills 已放在 `.agents/skills/`，不需要先安裝 plugin。

選一個請求開始：

> 請使用 $x-account-research，研究這個 X 帳號最近七天的公開貼文，保留日期與來源連結，不要做任何互動。

> 請使用 $statementdog-company-analysis，以目前可查到的財報狗頁面與公司原始揭露研究這家公司，清楚區分事實、平台評論與推論。

> 請使用 $x-thread-publishing，把這份內容整理成 X 串文；先只給草稿、編號與字數檢查，不要發布。

再次開啟同一資料夾不需要安裝環境。若要檢查更新，使用 `$playbook-manager`；若要處理影片，改用 [Xeruca Player](https://github.com/lloyd3126/xeruca-player) 的 `$watch-video`。

完整移除前先確認 repository root 與 `.local/` 是否有要保留的資料，然後只把這個解壓縮資料夾移到垃圾桶。
