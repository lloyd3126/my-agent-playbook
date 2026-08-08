# My Agent Playbook

一套給 Codex 使用的可追溯研究與發布 skills。它同時支援 Codex plugin，以及「下載 Release ZIP、解壓縮、用 Codex 開啟資料夾就開始」的 repository-scoped 模式。

自 `v0.3.0` 起，影片下載、轉錄、翻譯與本機播放器已獨立為 [Xeruca Player](https://github.com/lloyd3126/xeruca-player)。這個 repository 專注於研究、知識累積、X 串文與自身版本管理，不再重複維護媒體 runtime。

## 最快開始

### Release ZIP / Git 資料夾

1. 從 GitHub Releases 下載 `my-agent-playbook-vVERSION-portable.zip` 與同名 `.sha256`，或 clone repository。
2. 用 Codex 開啟整個資料夾。
3. 直接說：

> 請使用 $x-account-research，研究這個 X 帳號最近七天的公開貼文，保留日期與來源連結，不要按讚、追蹤、回覆或發布任何內容。

Codex 會從 `.agents/skills/` 發現入口，再讀取 `plugins/my-agent-playbook/skills/` 的 canonical skill；不需要先安裝 plugin。

### Codex plugin

```bash
codex plugin marketplace add https://github.com/lloyd3126/my-agent-playbook.git
codex plugin add my-agent-playbook@my-agent-playbook
```

完成後重新開啟 Codex task。

## Skills

| Skill | 用途 | 範例請求 |
| --- | --- | --- |
| `$x-account-research` | X 公開內容的只讀研究與知識檔更新 | 「整理這個帳號最近七天的公開貼文」 |
| `$x-thread-publishing` | X 串文草稿、長度檢查與經確認後發布 | 「把這份內容整理成串文，先不要發布」 |
| `$statementdog-company-analysis` | 公司、財務與產業的來源化研究 | 「以財報狗與原始揭露研究這家公司」 |
| `$playbook-manager` | 檢查版本、安全更新與完整移除 | 「檢查更新，先不要套用」 |

研究 skills 會區分來源事實、平台評論與 Agent 推論。草稿與只讀研究不造成外部變更；發布、回覆、刪除、按讚、追蹤與轉發都必須取得精確動作的明確授權。

## 需要處理影片？

請改用 Xeruca Player：

```bash
codex plugin marketplace add https://github.com/lloyd3126/xeruca-player.git
codex plugin add xeruca-player@xeruca-player
```

然後對 Codex 說：

> 請使用 $watch-video，把這支我有權處理的影片加入 Xeruca Player，取得字幕、翻成繁體中文並在本機影片庫開啟。

## 更新

先檢查，不修改：

```bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py status
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update
```

取得使用者明確同意後套用：

```bash
python3 plugins/my-agent-playbook/skills/playbook-manager/scripts/manage.py update --apply
```

Git 模式只接受乾淨 worktree 的 fast-forward；plugin 模式使用 Codex marketplace upgrade；Release ZIP 模式驗證外部 checksum 與內部 manifest，拒絕覆蓋被修改的 managed files，並保留 `.local/` 中的 updater backup 或使用者資料。

## 移除

Plugin 模式：

```bash
codex plugin remove my-agent-playbook@my-agent-playbook
codex plugin marketplace remove my-agent-playbook
```

Git／Release ZIP 模式不會在專案外安裝研究 runtime。先讓 `$playbook-manager` 回報精確 repository root 與 `.local/` 狀況，確認是否要保留其中資料，再把「這一個資料夾」移到垃圾桶即可完整移除。Manager 不會自刪 repository，也不會對 home 或父資料夾做廣泛刪除。

## Repository 結構

```text
my-agent-playbook/
├── .agents/
│   ├── plugins/marketplace.json
│   └── skills/                       # 資料夾模式的 discovery bridge
├── plugins/my-agent-playbook/
│   ├── .codex-plugin/plugin.json
│   └── skills/                       # 唯一完整 skill 實作
├── knowledge/                        # 可追溯、可持續更新的研究
├── scripts/build-release.sh          # 產生含 manifest 的 Release ZIP
├── tests/                            # manager 與 release 結構測試
├── START-HERE.md
└── VERSION
```

Cookie、token、密碼、API key、個人資料與未授權內容不得進入 Git。
