# My Agent Playbook

這是一套以 Codex 為主要使用者的 skills 與 plugin，同時保留「下載 Release ZIP、解壓縮、用 Codex 開啟資料夾就能開始」的可攜模式。

目前包含固定首頁的本機字幕影片庫、本機 Whisper／OpenAI API 轉錄、安全更新與移除、X 研究／發布流程，以及財報狗公司研究。

## 兩種使用模式

| 模式 | 適合誰 | Codex 設定影響 | 工具與影片 |
| --- | --- | --- | --- |
| Release ZIP / Git 資料夾 | 希望所有內容跟著資料夾走 | 無；repository-scoped skills 由 Codex 在資料夾內發現 | 全部放在 ".local/" |
| Codex plugin | 希望每個 Codex task 都能使用 | marketplace、plugin cache 與設定由 Codex 管理 | 影片庫仍可指定在專案內 |

可攜模式最符合「刪除整個資料夾即移除 workflow-owned 持久資料」的需求。Plugin 模式需要先用 "$playbook-manager" 移除 Codex 設定與 cache。

## 最快開始：Release ZIP

1. 從 GitHub Releases 下載 "my-agent-playbook-vVERSION-portable.zip" 與同名 ".sha256"。
2. 驗證 checksum 並解壓縮。
3. 用 Codex 開啟整個資料夾。
4. 直接說：

> 請使用 $youtube-caption-library，先檢查這個可攜式工作區。所有工具與資料都留在此資料夾；說明本機與 API 轉錄的差異後，幫我啟動影片庫。

Codex 會從 ".agents/skills/" 發現 repository-scoped 入口，再讀取 "plugins/my-agent-playbook/skills/" 的完整 skill。

## 安裝成 Codex plugin

若要在所有 Codex 工作中使用：

~~~bash
codex plugin marketplace add https://github.com/lloyd3126/my-agent-playbook.git
codex plugin add my-agent-playbook@my-agent-playbook
~~~

完成後重新開啟 Codex task。Plugin manifest 位於 "plugins/my-agent-playbook/.codex-plugin/plugin.json"，marketplace 位於 ".agents/plugins/marketplace.json"。

## Skills

| Skill | 用途 | 範例請求 |
| --- | --- | --- |
| "$youtube-caption-library" | 下載、字幕、轉錄、翻譯、本機影片庫 | 「把這支有權處理的 YouTube 影片加入本機影片庫」 |
| "$transcribe-media" | 本機或 OpenAI API 時間軸轉錄 | 「用 API 轉錄這支檔案並輸出 VTT」 |
| "$playbook-manager" | 檢查版本、更新、診斷、移除 | 「檢查更新，先不要套用」 |
| "$x-account-research" | X 公開內容只讀研究 | 「整理這個帳號最近七天的公開貼文」 |
| "$x-thread-publishing" | X 串文草稿與經確認後發布 | 「把這份內容整理成串文，先不要發布」 |
| "$statementdog-company-analysis" | 公司、財務與產業研究 | 「以財報狗與原始來源研究這家公司」 |

## 本機影片庫

影片庫固定入口是 "http://127.0.0.1:8000/"。首頁顯示下載中、轉錄中、待翻譯、失敗與完成等狀態；觀看時在同頁 iframe modal 開啟，播放進度寫回 job 資料夾。

Portable 命令：

~~~bash
scripts/portable/doctor.sh
scripts/portable/setup.sh --provider local --model turbo
scripts/portable/serve.sh 8000
scripts/portable/add-video.sh 'YOUTUBE_URL'
~~~

API 模式不下載 Whisper 模型，但音訊會傳到 OpenAI 且可能產生費用：

~~~bash
scripts/portable/setup.sh --provider openai
export OPENAI_API_KEY='只放在目前 terminal'
scripts/portable/add-video.sh 'YOUTUBE_URL' --provider openai --allow-api-upload
~~~

程式不會儲存或輸出 API key。API 轉錄以 "whisper-1" 取得 segment timestamps，並把音訊切成符合 25 MB 上限的片段後還原成單一時間軸。

## 更新

最簡單的互動方式：

> 請使用 $playbook-manager 檢查 my-agent-playbook 是否有更新；先報告差異，不要套用。

> 請使用 $playbook-manager 安全更新；保留 ".local/"、影片、字幕與播放進度，完成後驗證版本。

命令：

~~~bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py status
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update --apply
~~~

Git 模式只接受乾淨 worktree 的 fast-forward；plugin 模式使用 Codex marketplace upgrade；portable 模式驗證 release checksum 與內部 manifest，先備份 managed files，永遠保留 ".local/"。

## 移除

Portable 預覽：

~~~bash
scripts/portable/uninstall.sh
~~~

移除工具、模型與 cache，保留影片庫：

~~~bash
scripts/portable/uninstall.sh --yes
~~~

連影片、字幕、log 與播放進度一起移除：

~~~bash
scripts/portable/uninstall.sh --include-generated --yes
~~~

停止所有前景程序後，再把解壓縮資料夾移到垃圾桶，即可完整移除 portable 模式。系統瀏覽器的一般歷史與 cache 依瀏覽器政策管理，不屬於本專案。

Plugin 模式請用：

~~~bash
codex plugin remove my-agent-playbook@my-agent-playbook
codex plugin marketplace remove my-agent-playbook
~~~

## Repository 結構

~~~text
my-agent-playbook/
├── .agents/
│   ├── plugins/marketplace.json
│   └── skills/                       # 開啟資料夾即可發現的薄入口
├── plugins/my-agent-playbook/
│   ├── .codex-plugin/plugin.json
│   └── skills/                       # 唯一完整 skill 實作
├── knowledge/                        # 可追溯、可持續更新的研究
├── scripts/portable/                 # 固定使用 repository 內 ".local/"
├── tests/                            # 結構、腳本、server、provider、release 測試
├── START-HERE.md
└── VERSION
~~~

大型媒體、模型、venv、cache、cookie、token、密碼與 API key 不進 Git。下載與處理媒體前，使用者必須確認自己有相應權利。
