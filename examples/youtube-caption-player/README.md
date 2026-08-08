# YouTube 字幕播放器範例

這個資料夾只說明模板的完成形態，不提交影片、音訊、字幕、模型或虛擬環境。

固定影片庫直接使用 `jobs/<video-id>/source/video.mp4` 和 `captions/*.vtt`，不需要複製播放器。只有選用的單支 export 會像這樣：

```text
player/
├── index.html
├── config.js
├── video.mp4
├── captions.zh-TW.vtt
├── captions.en.vtt
└── media-info.txt
```

建立方式請依照 [YouTube 本機字幕 skill](../../plugins/my-agent-playbook/skills/youtube-caption-library/SKILL.md)，模板說明位於 [player-template.md](../../plugins/my-agent-playbook/skills/youtube-caption-library/references/player-template.md)。

範例不內含媒體的原因：

- 避免 repository 體積持續增加
- 避免散布未授權影片或字幕
- 避免提交可能包含私密內容的使用者產物
- 讓模板和單一 YouTube 影片 ID 解耦
