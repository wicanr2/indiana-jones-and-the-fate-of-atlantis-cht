# previous-work — 工作狀態交接(印第安納瓊斯:亞特蘭提斯之謎 繁中化)

> 給接手的 Claude Code 兄弟:先讀這份,再 `claude --resume`(UUID 在最下方 §接續)。

## 專案現況快照

- **repo**:`git@github.com:wicanr2/indiana-jones-and-the-fate-of-atlantis-cht.git`,分支 `master`。
- **做法**:不改原版一個 byte,改 ScummVM —— 在繪字 / 播音處攔截英文 → 查表 → 點陣中文重畫 / 中文配音重導。引擎走 scumm(`GID_INDY4`)既有 `ZH_TWN` Big5 路徑。
- **成果**:字幕 4760 條全翻、語音 5552 點重導(印第=馬蓋仙腔、蘇菲亞 581 句獨立聲線)、中文標題疊圖、動詞格對齊。F8 切字幕、F9 切語音。
- **三平台打包**:`dist-all/` 內 Linux AppImage(slim 30M / full 155M)、Windows zip(slim 24M / full 150M)、macOS universal `.app`(372M)。slim 公開、full(含版權)本機自留。

## 本次 session 做的工作(依主題)

1. **翻譯收尾**:zh.tsv ~4848 條,所有實際對白翻完(剩製作群/碎片/熱點代碼,玩不到)。
2. **語音**:重導驗證正確(VCTL offset 6968/6968);headless 測不到語音(subtitles-only 模式)。
3. **動詞格對齊**:`_chtVerbYOffset` 垂直微調,12px 字置中於格。
4. **中文標題**:`tools/title/design_title.py` 設計圖 → `drawAtlantisTitle()` 調色盤最近色疊圖,隨 logo 淡入。
5. **三平台打包**(重點,踩雷多):
   - Linux:`scripts/package_appimage.sh`,單檔 AppImage,實測獨立啟動 OK。
   - Windows:`scripts/build_windows_docker.sh`(docker mingw cross),自編 SDL2 靜態、force LE 繞端序檢測、objdump 遞迴收 DLL。靜態 exe + 3 個 mingw runtime DLL。
   - macOS:`.github/workflows/build-macos.yml` —— **universal 走 `macos-14`(arm64)+ `macos-15-intel`(x86_64)分弧 native 編 + `lipo` 合併三 job**;`scripts/package_macos_local.sh` 抓回注入語音/遊戲。
6. **玩家交付 UX**:三平台各附繁中 `使用說明.txt`(SmartScreen / FUSE / quarantine 首跑雷);`.app` 用 tar.gz 不用 zip。
7. **README** 更新:快速開始改「下載即玩 + 自己編」,打包表更新為已完成。
8. **沉澱經驗**:skill `retro-game-cht-package`(repo `skills/` + `~/.claude` + `~/my_skill` 三鏡像)、rule `42-reference-fidelity`。

## 工具鏈 / harness

- Windows 打包:docker `debian:12-slim` + mingw-w64;macOS:GitHub Actions(`gh` 觸發 + watch + download)。
- 配音:edge-tts(印第 `zh-TW-YunJheNeural` -8%/-12Hz、蘇菲亞 `zh-TW-HsiaoChenNeural`)。
- 標題 / 字型:docker + PIL。AppImage:`appimagetool`。
- **headless 測不到語音**(`_voiceMode==2` subtitles-only 預設);語音要真有音訊輸出的環境。

## 待辦 / 開放項目

- [ ] `CONTEXT.md` 幾個待確認譯名:Trottier / Sternhart 敬語、orichalcum 譯「山銅」or「奧利哈剛」。
- [ ] (可選)打 **GitHub Release** 把三平台 **slim 公開版**掛上去(full 維持本機自留)。
- [ ] (使用者想要的)FB 介紹短言已草擬(印第語氣);可再調更痞 / 加 repo 連結。
- [ ] 真 Windows / 真 Mac 上跑完整玩法驗證(dev box 上 wine 不可靠、無 Mac 機)。

## 鐵則 / 硬約束(別違反)

- **版權切分**:原版遊戲資料(`*.001`/`MONSTER.SOU`)+ TTS 中文語音 **只進本機 full 包 / dev-setup,絕不上公開 CI / release / git**。`dist-all/`、`build-win/`、`game/` 都 gitignore。
- **參考保真度**(rule 42):CLAUDE.md `@~/willy` 是 reference,要動 CI / 打包先讀 willy 實際設定逐項照抄(本次教訓:沒抄 willy 的 `macos-14` → 寫退役 `macos-13` 卡死)。
- **ScummVM autoconf ≠ CMake**:macOS universal **不能單次 `-arch x86_64 -arch arm64`**(炸 configure 版本解析),必須分弧 native + lipo。
- **CJK hi-res canvas**:中文用 24×24 畫在拉高的畫布,**不縮小硬塞**原版小字位。
- **語氣**:印第口吻 + 黑色幽默,不字面直譯;人名 / 謎題詞精確(見 `translation-voice` memory + CONTEXT.md)。
- **不依賴 willy binary**:新機從 `patches/scumm-cjk.patch` 自編引擎。

## § 在別台電腦接續(claude --resume)

1. repo 放到相同絕對路徑最省事;還原 `claude-session/projects/<dir>` → `~/.claude/projects/<同編碼>`(見 SETUP.md 步驟 2)。
2. `cd atlantis && claude --resume 22323f24-eebd-4984-8518-f685ab31adb6`
3. 路徑對不上 → 直接 `claude --resume 22323f24-eebd-4984-8518-f685ab31adb6`(UUID 不卡路徑)。

**最近 session UUID:`22323f24-eebd-4984-8518-f685ab31adb6`**

## 記憶索引(claude-session/memory/)

- `MEMORY.md` — 索引(每條一行)
- `scummvm-build-dependency` — 借 willy binary 加 scumm 引擎,willy 重編會壞 → 新機改自編
- `translation-voice` — 印第口吻 + 黑色幽默,名詞精確
- `voice-redirect-verified` — 中文語音重導驗證正確(6968/6968);英文=覆蓋缺口;headless 測不到
- `translation-loop-state` — 自動翻譯 loop 的 SOP 與進度
- `packaging-cross-build` — 三平台打包架構 + cross-compile 踩雷(端序 / wine / SDL2 自編 / macos-14+15-intel / lipo)
