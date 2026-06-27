# SETUP — 在另一台電腦還原本專案開發環境

印第安納·瓊斯:亞特蘭提斯之謎 繁體中文化(patched-ScummVM)。
這份 dev-setup 解開後,能 (1) 重建整套 build / 打包環境,(2) 用 `claude --resume` 接續同一個 Claude 對話與記憶繼續工作。

## 包內容

```
dev-setup/
├── SETUP.md                      ← 本檔
├── previous-work.md              ← 做到哪、為什麼、還有什麼沒做、最近 session UUID
├── repo/atlantis.gitbundle       ← 完整 git repo(所有分支與歷史,單檔可攜)
├── claude-session/projects/-home-anr2-indian-jones-atlantis/
│   ├── 22323f24-...jsonl          ← 對話記錄(讓 claude --resume 接續)
│   └── memory/                    ← 專案記憶(6 個 .md + MEMORY.md 索引)
├── game-data/                    ← 版權素材(原版遊戲 + 中文配音,本機自留勿散布)
└── prebuilt/scummvm-linux-x86_64 ← 預編 Linux 引擎(便利用;正式請照下方從 patch 重編)
```

## 還原步驟

### 0. 工具鏈(新機先裝)
- `git`、`docker`、`zstd`、`gh`(GitHub CLI,macOS workflow 觸發用)
- AppImage 打包:`appimagetool`(放任意路徑,設 `APPIMAGETOOL` 環境變數指過去)
- 配音重烘(可選):`edge-tts`(`pip install edge-tts`)
- 其餘 Python(字型/標題)一律走 docker,不污染系統。

### 1. 還原 repo
```bash
# ★ 放到「相同絕對路徑」最省事(claude --resume 依 cwd 編碼找 session)
mkdir -p /home/<你>/indian_jones && cd /home/<你>/indian_jones
git clone /path/to/dev-setup/repo/atlantis.gitbundle atlantis
cd atlantis
```
> 若無法用相同路徑,改用 UUID 直接接續(見 previous-work.md §接續),repo 放哪都行。

### 2. 還原 Claude session(關鍵 — 沒這層只是備份不是 handoff)
```bash
# 編碼規則:cwd /home/<你>/indian_jones/atlantis → -home-<你>-indian-jones-atlantis
DST=~/.claude/projects/-home-<你>-indian-jones-atlantis
mkdir -p "$DST"
cp -a /path/to/dev-setup/claude-session/projects/*/.  "$DST"/
# 之後:cd atlantis && claude --resume 22323f24-eebd-4984-8518-f685ab31adb6
```

### 3. 還原版權素材(原版遊戲 + 中文配音)
```bash
mkdir -p game && cp -a /path/to/dev-setup/game-data/. game/
# game/ 內:ATLANTIS.000/.001、MONSTER.SOU(原版,不可重建,需你合法持有)
#          voice/*.voc、atlantis_voice.tab、atlantis_zh{12,16,24}.dcjk(可重建,見下)
```

### 4. 取得引擎(二選一)
**A. 便利(Linux,立刻能跑)**:用 `prebuilt/scummvm-linux-x86_64`。
**B. 正式 / 跨平台(從 patch 重編,canonical)**:
```bash
git clone --depth 1 https://github.com/scummvm/scummvm.git sv && cd sv
git apply ../patches/scumm-cjk.patch
./configure --disable-all-engines --enable-engine=scumm --enable-release \
  --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth   # 原版+配音都 raw VOC
make -j"$(nproc)"; cd ..
```
> ⚠️ 本專案歷史上「借用 `~/willy/scummvm-src` 的 binary 再 reconfigure 加 scumm 引擎」,
> 那條路**會因 willy 重編而壞**(見 memory `scummvm-build-dependency`)。**新機一律從 patch 自編,不要再依賴 willy。**

### 5. 重建 CHT 資產(若要改字型/譯文/配音/標題)
```bash
python3 tools/build_translation.py --out game/atlantis_zh.tab     # 由 translations/zh.tsv
# 字型 build_cjk_font.py、標題 tools/title/design_title.py(docker+PIL)、
# 配音 scripts/dub_batch.sh + tools/build_voice.py(edge-tts;game-data 已含烘好的,可跳過)
```

### 6. 三平台打包(成品進 dist-all/,gitignored)
```bash
bash scripts/package_appimage.sh full          # Linux AppImage
docker run --rm -v $PWD:/work -w /work debian:12-slim bash scripts/build_windows_docker.sh
bash scripts/package_windows.sh full           # Windows zip
gh workflow run build-macos.yml                # macOS universal(CI)→ 下載 .app →
bash scripts/package_macos_local.sh <下載的.app>  #   注入語音+遊戲
```
打包細節與踩雷見 skill `retro-game-cht-package`(repo `skills/` 內也有一份)。

### 7. 接續 Claude
```bash
cd atlantis
claude --resume 22323f24-eebd-4984-8518-f685ab31adb6
```
路徑對不上時:`claude --resume <UUID>` 用 UUID 不卡路徑(同 repo 任意目錄都找得到)。

## ⚠️ 隱私 / 版權
本包含**完整對話記錄**(`*.jsonl`)與**版權素材**(原版遊戲 + 配音)。屬**私用 handoff**,勿公開散布。
要給他人前先評估是否抽掉 `claude-session/` 與 `game-data/`。
