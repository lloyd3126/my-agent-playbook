# 我的 Agent 作業手冊

這個 repository 是給人與 Agent 共用的個人作業系統：把可重複的工作流程、可直接使用的模板，以及需要長期維護的知識分開保存。它不是單一程式，也不假設使用者電腦已經裝好任何工具。

## 怎麼使用

給 Agent 一個明確的目標，並指定對應 playbook。例如：

> 請依照 `playbooks/youtube-local-caption/PLAYBOOK.md` 建立固定的本機影片庫首頁，從環境檢查開始，把這支影片加入佇列並產生繁體中文與英文字幕；完成後告訴我安裝了什麼、下次怎麼用，以及如何移除。

> 請依照 `playbooks/x-account-research.md` 更新 Serenity 最近 7 天的公開內容，只讀取與整理，不要與帳號互動。

> 請依照 `playbooks/statementdog-company-analysis.md` 研究指定公司，區分來源事實、網站觀點與 Agent 推論。

Agent 應先閱讀 [AGENTS.md](AGENTS.md)，再讀指定 playbook。若 playbook 與使用者本次指示衝突，以使用者本次指示為準。

## Repository 地圖

```text
my-agent-playbook/
├── README.md                         # 人類入口與流程索引
├── AGENTS.md                         # 全 repository 共用的 Agent 規則
├── playbooks/                        # 如何完成任務
│   ├── x-thread-publishing.md
│   ├── x-account-research.md
│   ├── statementdog-company-analysis.md
│   └── youtube-local-caption/
│       ├── PLAYBOOK.md
│       ├── requirements.txt
│       ├── scripts/
│       └── references/
├── templates/                        # 可以複製使用的成品骨架
│   ├── youtube-library/              # 固定首頁、狀態表與 iframe modal
│   └── youtube-caption-player/       # 可嵌入或獨立播放
├── knowledge/                        # 可持續更新的研究與背景資料
│   └── x/accounts/
└── examples/                         # 不含大型媒體的使用範例
```

## Playbooks

| 任務 | Playbook | 是否會改變外部狀態 |
| --- | --- | --- |
| 發布 X 串文 | [X 串文發布](playbooks/x-thread-publishing.md) | 會；每次發布前需要明確確認 |
| 整理 X 帳號 | [X 帳號研究](playbooks/x-account-research.md) | 不會；預設只讀 |
| 財報狗研究 | [財報狗公司與產業研究](playbooks/statementdog-company-analysis.md) | 不會；預設只讀 |
| YouTube 本機影片庫與字幕 | [YouTube 本機字幕流程](playbooks/youtube-local-caption/PLAYBOOK.md) | 會建立本機檔案；下載前確認權利與範圍 |

## Templates

- [YouTube 本機影片庫首頁](templates/youtube-library/README.md)：固定首頁、任務狀態表、log、搜尋／篩選與 iframe modal。
- [YouTube 本機字幕播放器](templates/youtube-caption-player/README.md)：播放本機 MP4，以 VTT 顯示並切換字幕，可獨立匯出或嵌入影片庫。

## Knowledge

- [Serenity 帳號研究紀錄](knowledge/x/accounts/serenity.md)

`knowledge/` 保存可追溯的研究紀錄，不保存登入憑證、瀏覽器 cookie、API key、下載的影片、Whisper 模型或虛擬環境。

## 共用生命週期

每個會操作網站、安裝工具或建立可持續資料的流程，都必須涵蓋以下階段：

1. **確認環境**：檢查作業系統、Agent 可用能力、瀏覽器／登入狀態、既有工具、磁碟與權限。
2. **說明影響**：安裝或登入前，列出會新增的工具、檔案、網路存取與可能的系統變更。
3. **最小安裝**：優先使用專案內或工作資料夾內的隔離環境，不覆蓋系統 Python，也不默默修改 shell 設定。
4. **首次驗證**：用最小案例確認流程可執行，再處理完整資料。
5. **持續使用**：提供下次可直接重複的命令、檔名規則、更新方式與檢查點。
6. **教學交接**：完成時用白話說明做了什麼、產物在哪裡、怎麼重新啟動。
7. **完整移除**：先預覽要移除的項目，只移除本流程建立的工具與資料；既有工具和使用者內容預設保留。

## 安全預設

- 不要求使用者提供密碼、cookie、API key 或雙重驗證碼；登入由使用者在瀏覽器中自行完成。
- 不靜默安裝系統層套件。需要 `sudo`、套件管理器或修改帳戶狀態時，先說明並取得同意。
- 不因為能控制網站就自動發布、按讚、追蹤、收藏、回覆、購買或刪除。
- 外部資訊可能過時時，先重新查證；金融、政策與產業內容要標明來源日期與不確定性。
- 移除預設採 dry run 或先列清單；使用者產生的影片、字幕與研究紀錄不會跟著工具自動刪除。

## 不放進 repository 的內容

- 下載的影片與音訊
- 自動字幕、翻譯字幕與大型模型
- `.venv`、套件快取、Deno／uv 執行檔
- cookie、token、密碼、瀏覽器 profile
- 未取得再散布權利的內容
