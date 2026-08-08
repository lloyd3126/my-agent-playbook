# YouTube 本機字幕播放器模板

這個模板以 Plyr 播放本機 MP4，並用外部 VTT 字幕依影片時間同步顯示繁體中文翻譯。

## 固定檔名

把以下檔案放在 `index.html` 同一層：

- `video.mp4`：影片檔
- `captions.zh-TW.vtt`：繁體中文字幕
- `captions.en.vtt`：英文字幕，通常可放 Whisper 產生的 VTT

播放器預設載入繁體中文，也可以從下方選單切換英文。

## 使用方式

```bash
python3 -m http.server 8000
```

接著開啟 <http://localhost:8000/index.html>。

不要直接用 `file://` 開啟，因為瀏覽器會阻擋字幕 VTT 的 `fetch`。

## 與本次流程的關係

本模板只負責播放與字幕顯示；影片下載、YouTube 自動字幕、翻譯與 Whisper 轉錄，請依照 `playbooks/youtube-local-caption-workflow.md` 執行。
