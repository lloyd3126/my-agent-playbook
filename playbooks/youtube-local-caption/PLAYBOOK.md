# YouTube 本機影片、轉錄、翻譯字幕與播放器

## 目的

把使用者有權處理的 YouTube 影片整理成一個可在本機播放的資料夾，支援繁體中文與英文 VTT 字幕切換。流程涵蓋從零環境檢查、隔離安裝、影片／字幕取得、Whisper 本機轉錄、翻譯、播放器建立、持續使用、更新與完整移除。

## 不處理的範圍

- 不繞過付費、DRM、地區或帳號存取限制。
- 不把影片、音訊、字幕、cookie 或 Whisper 模型 commit 到這個 repository。
- 不保證 YouTube 一定提供自動字幕或自動翻譯。
- Whisper 的 `translate` 是將語音翻成英文，不會直接產生繁體中文；繁中字幕需要既有字幕、YouTube 可用翻譯，或由 Agent 逐 cue 翻譯。
- 不使用使用者未明確授權的登入 cookie。需要登入時，使用者自行登入瀏覽器，Agent 另行說明 cookie 存取的風險與範圍。

## 支援環境

附帶腳本支援 macOS、Linux，以及 Windows 的 WSL。原生 Windows 使用者可依同一流程手動安裝 uv、Python、Deno、FFmpeg 與套件，但這一版 shell 腳本不直接支援 PowerShell。

建議預留：

- 至少 10 GB 可用空間，另加影片本身大小
- 8 GB RAM 可使用較小模型；16 GB 以上較適合 `turbo`
- 穩定網路，用於下載工具、Python、模型與使用者授權的媒體
- 長影片在純 CPU 轉錄可能需要接近或超過影片時長

## 資料夾契約

指定一個工作資料夾後，工具與使用者產物分開：

```text
<workspace>/
├── .agent-tools/youtube-local-caption/   # uv、Deno、Python、venv、模型、快取
└── jobs/
    └── <video-id>/
        ├── source/                       # 影片與音訊
        ├── youtube-captions/             # YouTube 可取得的字幕
        ├── whisper/                      # Whisper VTT、SRT、JSON 等
        └── player/                       # 可直接啟動的播放器
```

完整移除工具時，`jobs/` 預設保留。只有使用者明確要求刪除產物時才移除。

## 階段 0：取得 playbook

如果 Agent 已經能讀取這個 repository，直接使用目前版本。全新環境不一定有 Git，可以二選一：

- 使用瀏覽器從 GitHub repository 頁面下載 ZIP 並解壓縮。
- 已有 Git 時執行 `git clone https://github.com/lloyd3126/my-agent-playbook.git`。

不需要為了單次使用強制安裝 Git。下載後先讀根目錄 `AGENTS.md` 與本文件，再執行腳本。

## 階段 1：確認需求與權利

開始前確認：

1. YouTube URL 與是否只處理單支影片；預設 `--no-playlist`。
2. 使用者有權下載／轉錄內容，並理解 YouTube 條款與所在地規範可能適用。
3. 原始語言、需要的字幕語言，以及是否接受機器翻譯。
4. 需要最高畫質、瀏覽器相容 MP4，或只需要音訊／字幕。
5. 是否允許下載數 GB 的 Python 套件與 Whisper 模型。
6. 產物保存位置與是否包含敏感內容。

如果使用者只要現成字幕，先嘗試字幕路徑；不要一開始就下載完整影片與 Whisper 模型。

## 階段 2：環境盤點

在 repository 根目錄執行：

```bash
playbooks/youtube-local-caption/scripts/doctor.sh work/youtube-caption
```

`doctor.sh` 只讀取環境，不會安裝或刪除。Agent 應把結果翻譯成白話，至少說明：

- 作業系統和 CPU 架構是否支援
- `curl`、`unzip`、`ffmpeg`、`ffprobe` 是否存在
- 是否已經有本流程建立的 runtime
- 可用磁碟是否合理
- 需要安裝哪些元件、安裝在哪裡

如果連基本的 `curl` 或 `unzip` 都不存在，先取得系統層安裝同意，再使用作業系統套件管理器：

- Ubuntu／Debian：`sudo apt-get update`，再執行 `sudo apt-get install -y curl unzip`
- Fedora：`sudo dnf install -y curl unzip`
- Arch：`sudo pacman -S --needed curl unzip`
- macOS 通常內建；若缺少，先透過 Apple 的系統更新／命令列工具修復，不執行未知第三方安裝器

如果連受支援的套件管理器也不存在，暫停自動安裝，改依作業系統官方文件安裝；Agent 不自行編譯一整套 bootstrap 工具。

## 階段 3：從零安裝

### 3.1 預設隔離安裝

```bash
playbooks/youtube-local-caption/scripts/setup-environment.sh \
  work/youtube-caption \
  --model turbo
```

腳本會在 `<workspace>/.agent-tools/youtube-local-caption/` 內：

- 安裝專案私有 uv，不修改 shell profile
- 安裝專案私有 Deno，供 yt-dlp 的 YouTube JavaScript 支援使用
- 由 uv 安裝 Python 3.11
- 建立專用 `.venv`
- 安裝 `openai-whisper` 與 `yt-dlp[default]`
- 下載指定 Whisper 模型
- 記錄套件版本和安裝狀態

不會覆蓋系統 Python，也不會把 uv 或 Deno 放進全域 `PATH`。

低記憶體或想先做最小測試時可用 `--model small`。如果先不下載模型，可用 `--skip-model`，之後第一次轉錄時再下載。

### 3.2 FFmpeg

Whisper 與 yt-dlp 的合併／轉檔需要真正的 `ffmpeg` 和 `ffprobe` 執行檔，不是同名 Python package。

如果系統沒有 FFmpeg，預設安裝腳本會停止並顯示對應命令。Agent 說明影響並取得使用者同意後，才可執行：

```bash
playbooks/youtube-local-caption/scripts/setup-environment.sh \
  work/youtube-caption \
  --install-ffmpeg \
  --model turbo
```

腳本只支援已存在的 Homebrew、APT、DNF 或 Pacman，不會自動安裝套件管理器。它會記錄 FFmpeg 是否由本流程新增，供後續安全移除。

### 3.3 安裝後驗證

再次執行 doctor，確認 `status: ready`：

```bash
playbooks/youtube-local-caption/scripts/doctor.sh work/youtube-caption
```

Agent 同時回報 uv、Deno、Python、yt-dlp、Whisper 與 FFmpeg 版本，以及模型位置。

## 階段 4：取得影片、音訊與 YouTube 字幕

```bash
playbooks/youtube-local-caption/scripts/download-video.sh \
  work/youtube-caption \
  'https://www.youtube.com/watch?v=VIDEO_ID'
```

腳本會：

1. 先解析影片 ID 與標題。
2. 嘗試下載可取得的英文、繁體中文與自動字幕 VTT；字幕失敗不會掩蓋影片下載結果。
3. 下載偏向瀏覽器相容的 MP4；若來源沒有相容組合，退回 yt-dlp 可取得的最佳格式。
4. 另外輸出 Whisper 使用的音訊檔。
5. 把結果放在 `jobs/<video-id>/` 並寫入 manifest。

下載後用 `ffprobe` 檢查影片長度、容器、視訊和音訊 stream。若影片需要登入或出現 bot 驗證，先看 [故障排除](references/troubleshooting.md)，不要反覆高速重試。

## 階段 5：選擇英文／原文字幕來源

依序選擇：

1. 影片作者上傳的字幕
2. YouTube 自動字幕
3. Whisper 本機轉錄

現成字幕可用時，仍要抽查前段、中段和末段時間戳。若字幕不存在或品質不足，執行：

```bash
playbooks/youtube-local-caption/scripts/transcribe.sh \
  work/youtube-caption \
  work/youtube-caption/jobs/VIDEO_ID/source/audio.m4a \
  work/youtube-caption/jobs/VIDEO_ID/whisper \
  --model turbo \
  --language en
```

腳本預設使用 CPU 和 `fp16=false`，在不同機器上較穩定。確定 CUDA 可用時可指定 `--device cuda`。Apple Silicon 遇到 MPS／Torch crash 時退回 CPU，不要無限重試。

選定來源後，將通過抽查的英文／原文 VTT 複製為 `jobs/VIDEO_ID/captions.en.vtt`。這個固定檔名代表「播放器使用的英文 track」，不是要求覆蓋原始 YouTube 或 Whisper 輸出；原始檔仍保留在各自子目錄。

## 階段 6：建立繁體中文翻譯

### 有 YouTube 繁中 VTT

先檢查是否真的為繁體中文、是否包含有效 cue、時間是否覆蓋全片。YouTube 自動翻譯可能有重複 cue 或片段式文字，必要時清理。

### 需要 Agent 翻譯

1. 以通過抽查的英文／原文 VTT 為唯一時間軸。
2. 每個 cue 保留原始起訖時間與順序，只翻譯文字。
3. 專有名詞第一次出現時保留英文；數字、股票代號、產品名不可臆改。
4. 不合併跨越重要停頓的 cue；若為可讀性合併，必須同步調整時間並重新驗證。
5. 輸出 UTF-8、以 `WEBVTT` 開頭的 `captions.zh-TW.vtt`。
6. 檢查 cue 數、首尾時間、空白 cue、重疊與譯文遺漏。

完成的繁中檔放在 `jobs/VIDEO_ID/captions.zh-TW.vtt`，與前一步選定的 `captions.en.vtt` 一起交給播放器。

翻譯長字幕時採批次處理，但要用 cue ID 或時間戳銜接，避免漏段或重複。完成後抽查影片開頭、中間、結尾及專有名詞密集區。

## 階段 7：建立播放器

```bash
playbooks/youtube-local-caption/scripts/prepare-player.sh \
  --video work/youtube-caption/jobs/VIDEO_ID/source/video.mp4 \
  --zh work/youtube-caption/jobs/VIDEO_ID/captions.zh-TW.vtt \
  --en work/youtube-caption/jobs/VIDEO_ID/captions.en.vtt \
  --output work/youtube-caption/jobs/VIDEO_ID/player
```

腳本會驗證檔案、複製 [播放器模板](../../templates/youtube-caption-player/README.md)，並使用固定檔名：

- `video.mp4`
- `captions.zh-TW.vtt`
- `captions.en.vtt`
- `index.html`
- `config.js`

`config.js` 可以改標題、影片檔名、預設語言和字幕清單，不必修改 HTML。

## 階段 8：啟動與驗證

```bash
playbooks/youtube-local-caption/scripts/serve-player.sh \
  work/youtube-caption \
  work/youtube-caption/jobs/VIDEO_ID/player \
  8000
```

開啟 <http://127.0.0.1:8000/>。伺服器只綁定本機，不對區域網路公開。不要使用 `file://`，因為瀏覽器可能阻擋 VTT 的 `fetch`。

驗證清單：

- [ ] MP4 可載入，時間長度合理，影像與聲音都存在
- [ ] 繁中與英文 VTT 都至少有一個有效 cue
- [ ] 預設字幕正確，切換語言後 cue 數與文字更新
- [ ] 播放、暫停、拖曳與跳轉後字幕仍同步
- [ ] 開頭、中段與結尾各抽查至少一段
- [ ] Plyr CDN 無法載入時，原生瀏覽器控制仍可播放
- [ ] 重新整理後仍能載入，不依賴某次 console 狀態

## 日常重複使用

環境只需安裝一次。下一支影片從環境檢查後直接重複：

1. `download-video.sh`
2. 選擇既有字幕或 `transcribe.sh`
3. 翻譯並驗證 VTT
4. `prepare-player.sh`
5. `serve-player.sh`

每支影片使用不同 `jobs/<video-id>/`，不要覆蓋上一支影片。完成後告訴使用者：

- 工作資料夾與播放器路徑
- 使用了哪個字幕來源和 Whisper 模型
- 哪些步驟是機器翻譯
- 如何重新啟動伺服器
- 仍保留哪些大型檔案

## 更新工具

先停止轉錄和本機伺服器，再執行：

```bash
playbooks/youtube-local-caption/scripts/update-environment.sh work/youtube-caption
playbooks/youtube-local-caption/scripts/doctor.sh work/youtube-caption
```

更新會刷新專案私有 uv、Deno、yt-dlp 與 Whisper 套件，並記錄新的套件版本。更新後先用已知短片測試，再處理重要長片。

## 完整移除

### 先預覽

```bash
playbooks/youtube-local-caption/scripts/uninstall.sh work/youtube-caption
```

預設只列出將移除的 runtime，完全不刪除。

### 只移除工具、模型與快取，保留影片／字幕

```bash
playbooks/youtube-local-caption/scripts/uninstall.sh \
  work/youtube-caption \
  --yes
```

### 同時刪除所有 jobs 產物

這會刪除下載影片、音訊、字幕與播放器，先備份需要保留的檔案：

```bash
playbooks/youtube-local-caption/scripts/uninstall.sh \
  work/youtube-caption \
  --include-generated \
  --yes
```

### 移除本流程安裝的系統 FFmpeg

只有安裝狀態能證明 FFmpeg 是由本流程新增時才允許：

```bash
playbooks/youtube-local-caption/scripts/uninstall.sh \
  work/youtube-caption \
  --include-system-ffmpeg \
  --yes
```

如果 FFmpeg 原本就存在，移除腳本會保留它。完成後再次執行 doctor，確認 runtime 已不存在，並回報 `jobs/`、repository clone 和任何瀏覽器下載是否仍保留。

## 使用者可以怎麼請 Agent

> 依照 YouTube 本機字幕 playbook 處理這支影片。先做 doctor，告訴我需要安裝什麼和大約多少空間；我確認後再下載模型與影片。

> 沿用既有 `work/youtube-caption` 環境處理這支影片。優先使用作者英文字幕，沒有才跑 Whisper；翻成繁體中文並建立播放器。

> 依照 uninstall 章節先做 dry run，列出會刪除的工具、模型、快取和影片；先不要真的刪除。

## 上游文件

- [uv 安裝與自訂安裝位置](https://docs.astral.sh/uv/reference/installer/)
- [OpenAI Whisper](https://github.com/openai/whisper)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [Deno 安裝](https://docs.deno.com/runtime/getting_started/installation/)
- [FFmpeg 下載與套件來源](https://ffmpeg.org/download.html)
