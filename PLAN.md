# PLAN — 印第安納·瓊斯:亞特蘭提斯之謎 繁體中文化

路線沿用姊妹專案 [`~/willy`](../willy)(*The Adventures of Willy Beamish* 繁中化)的
**engine-side overlay** 做法,移植到 ScummVM 的 `scumm` 引擎(FOA = SCUMM v5,`GID_INDY4`)。
不改遊戲資料;patch ScummVM 在繪字處攔截英文 → 查表 → 用點陣 CJK 字型重畫到 hi-res 疊圖層。

術語見 [CONTEXT.md](CONTEXT.md)。

---

## 現況快照(2026-06-26)

| 項目 | 狀態 | 證據 |
|---|---|---|
| 引擎判定 | ✅ SCUMM v5 CD Talkie(1993-05) | `ATLANTIS.001` XOR `0x69` → `LECF`;EXE 字串 `5.5.00 (May 05 1993)`、iMUSE 1993 |
| ScummVM 支援 | ✅ 內建 `atlantis`/`Steam`/`GID_INDY4` | `scummvm-src/engines/scumm/detection_tables.h:213` |
| scumm 引擎 build | ✅ 已編進 ScummVM(willy 版原只有 dgds) | reconfigure `--enable-engine=scumm`,53 個 scumm `.o`,FOA 開場 + 遊玩畫面實機跑出 |
| CJK 字型 | ✅ `atlantis_zh{24,16}.dcjk`(Big5 點陣,13709 字) | `tools/build_cjk_font.py` |
| 資料可讀 | ✅ 96 房間、1372 物件、~5450 句字串可解出 | `tools/scumm_v5.py`、`extracted/strings_raw.tsv` |
| **遊戲索引檔** | ✅ **已從 CD ISO 補回 `ATLANTIS.000`** → 偵測成功 | `scummvm --detect` 回 `scumm:atlantis ... (CD/DOS/English)`;CD 版 `.001` md5 與 Steam 版**完全相同**(同版本,先前抽字有效) |
| **引擎 CJK patch(MVP)** | ✅ **中文動詞選單實機渲染成功** | `patches/scumm-cjk.patch`、`screenshots/foa_cht_verbs.png` |
| 翻譯 pipeline | ✅ `zh.tsv`→`build_translation.py`→`atlantis_zh.tab`,免重編 | 物件名只在檔案、實機渲染 → 確認生效 |
| 完整對白翻譯 | ⬜ 逐句進行中(~5400 句) | `translations/zh.tsv` |

---

## Phase 0 — 補回 `ATLANTIS.000` 索引檔 ✅【已解決】

**原問題**:Steam 複本只有 `ATLANTIS.001`(資料)缺 `ATLANTIS.000`(索引)。SCUMM v5 把
「全域腳本 / 音效 / 服裝 / 字型」的**編號 → 位移**映射全放在 `.000`;`.001` 的區塊只有
tag+size 沒有編號,**無法只憑 `.001` 重建**(編號資訊已遺失,重建會叫錯腳本)。

**解法**:使用者提供 **FOA CD 版 ISO**(`game_cd/FATE.ISO`)。從中抽出完整 `ATLANTIS/` 到
`game/`(gitignore),含 `ATLANTIS.000`(12 KB 索引)、`ATLANTIS.001`、`MONSTER.SOU`(語音)、`*.IMS`(iMUSE)。

**驗證**:
- CD `.001` md5 == Steam `.001` md5 → **同版本**,先前在 Steam 版上做的抽字完全有效。
- `.000` XOR `0x69` → `RNAM/MAXS/DROO/DSCR/DSOU/DCOS/DCHR/DOBJ` 八個目錄齊全 → 合法索引。
- `scummvm --detect --path=game` → `scumm:atlantis  Indiana Jones and the Fate of Atlantis (CD/DOS/English)` ✅

---

## Phase 1 — 字串抽取與語料建立

- [x] `tools/scumm_v5.py`:XOR 解碼 + LECF/LFLF 區塊樹走訪 + SCUMM v5 字串解碼。
- [x] 初步語料 `extracted/strings_raw.tsv`(~5450 句,含 VERB/LSCR/SCRP/OBNA)。
- [ ] **權威語料用 runtime 攔截**(沿用 willy):patch ScummVM 把每次要繪的英文字串 log 出來,實際走過遊戲收完整、無碎片的對白集(離線抽取對 SCUMM 字串邊界仍有碎片,當估算用)。
- [ ] 字串分類:對白 / 物件名 / 動詞 UI / 告示牌,分流到不同翻譯批次。
- [ ] 標注三線劇情分支(Wits / Fists / Team)對應段落。

## Phase 2 — CJK 字型烘製 ✅

- [x] 重用 `tools/build_cjk_font.py`(取自 willy):TTF → 點陣 atlas(Big5 linear index)。
- [x] 產 `fonts/atlantis_zh24.dcjk`(24×24,主,1.4 MB)+ `fonts/atlantis_zh16.dcjk`(16×16,備)。13709 字 rendered。
- [ ] (可選)出貨時改子集化,只含語料用到的漢字以縮小體積。

## Phase 3 — ScummVM `scumm` 引擎 CJK patch

**關鍵發現**:scumm 引擎**本來就有**完整的雙位元組 CJK 繪字(`loadCJKFont` / `get2byteCharPtr` /
`printChar`),供日文 FM-Towns、韓文、簡體 GB 版使用,且已內建 `Common::ZH_TWN`(繁中 Big5)路徑,
只是 gate 在 v7+。所以**不必自寫疊圖層** — 把 FOA 接上這條既有路徑即可,masking / 定位 / 還原全部免費。

**做法(已實作,`patches/scumm-cjk.patch`,226 行 6 檔)**:
- [x] 新增 `engines/scumm/cjk_cht.{h,cpp}`:`big5LinearIndex()`(對齊 `build_cjk_font.py` 字型順序)+ 英文→Big5 查表 `translateInPlace()`。
- [x] `charset.cpp loadCJKFont()`:偵測到 `atlantis_zh16.dcjk` 就強制 `_language = ZH_TWN`、載入本專案 Big5 點陣字、`_useCJKMode = true`。
- [x] `charset.cpp get2byteCharPtr()`:ZH_TWN case 加 `_chtBig5` 分支,改用 `big5LinearIndex`(配合本字型 16×16 / 12×12,而非 v7/v8 的 `chinese.fnt` 版面)。
- [x] `string.cpp drawString()`:`convertMessageToString` 後注入查表,命中則就地把英文換成 Big5 → 既有渲染器繪出。
- [x] **MVP 達成**:九個動詞 + 走向 在實機渲染成功(`screenshots/foa_cht_verbs.png`)。
- [x] 字型大小:動詞格只有 ~10px 高,16×16 會重疊 → **12×12 剛好**(與 ScummVM 既有 GB 簡中 v5 路徑同尺寸);loader 從 DCJK header 讀尺寸,換字型免重編。

- [x] **演員對白**:`actorTalk()`(actor.cpp)在 `convertMessageToString` 後同樣注入 → 任何進譯表的對白即講中文(機制與動詞同,已驗證)。
- [x] **句子列樣板**:「動詞+物件」前綴比對 → `走向 售票員`(`screenshots/foa_cht_verbs.png`)。

**待辦(Phase 3 收尾)**:
- [ ] **大字 / hi-res text surface**:對白文字空間夠,改走 `_textSurfaceMultiplier = 2`(FM-Towns 用的 2× 文字層 = rule `81` 的拉高畫布)讓對白用 24×24 更清楚,**不縮字**。
- [ ] 字型檔名正名(目前 12×12 資料暫存成 `atlantis_zh16.dcjk`)。
- [ ] F-key 切換中/英(DisplayMode)。
- [ ] 對白自動換行(CJK 無空格)用 `_newLineCharacter` / `addLinebreaks` 調校,長句不溢出。

- [x] **譯表改檔案載入**:`engines/scumm/charset.cpp` 載字型後一併讀 `atlantis_zh.tab`(Big5),`cjk_cht.cpp` 進 HashMap;C++ 內只留 10 動詞 fallback。**翻譯不再需要重編引擎**。已驗證:物件名「售票員」只在檔案裡、實機仍渲染 → 確認檔案載入生效。

## Phase 4 — 翻譯【pipeline 就緒,逐句進行中】

**工作流(已建好,免重編引擎)**:編輯 `translations/zh.tsv`(UTF-8,`英文<TAB>中文`)→
`tools/build_translation.py` 編成 `game/atlantis_zh.tab`(Big5)→ 引擎啟動時載入。

- [x] `tools/build_translation.py`:UTF-8 TSV → Big5 `.tab`,非 Big5 字會回報不靜默吞掉。
- [x] 已翻 200+ 條(動詞 + 開場/紐約物件名 + 金珠計數 + 印第口吻通用回應),實機驗證「看 戲院招牌」。
- [x] **對話風格定案**:印第口吻 + 黑色幽默(CONTEXT.md「對話風格」);兩份攻略整理成 Markdown 當術語 / 語氣 oracle。
- [x] **多行對白支援**:`cjk_cht.cpp normalizeKey()` 查表前剝掉 SCUMM 控制碼(`0xFF`+code)、空白收斂 → 多行對白用單行英文鍵即可命中;中文值用 `\n` 標換行,`build_translation.py` 轉成 `0xFF 0x01`,引擎照樣斷行。已驗證:`.tab` 值含 `FF01`;normalizeKey 重編後句子列無 regression。
- [ ] 依 CONTEXT.md 譯名表逐句翻 ~5400 句語料(`extracted/strings_raw.tsv`)。
- [x] **多行 CJK 對白實機渲染**:開場旁白「好啦,我人是到紐約了…」三行斷行成功(`screenshots/foa_cht_dialogue.png`),印第口吻。
- [x] **runtime 字串攔截工作流**:`cjk_cht.cpp` dump 模式(放 `atlantis_dump_on` 到 game 夾即開)把未翻字串經 `warning("CHTMISS…")` 印到 log;翻的是引擎真正畫的字串,normalizeKey 兩端一致(剝 `0xFF`+code、`<=0x20`、`^`、`0x7F` → 空白收斂)→ 一翻就中。
- [ ] 對齊 1990s 攻略術語,人名拼字以遊戲語料為準。
- [ ] 三線劇情分支(Wits / Fists / Team)台詞校對。

## Phase 6 — 語音中文化(worklist,實驗中)

把遊戲英文語音(`MONSTER.SOU`,150 MB talkie)換成中文配音。**不重建 SOU**,改在引擎
`Sound::startTalkSound(offset,…)` 攔截:某句的 MONSTER.SOU offset 命中重導表就改播外部中文音檔。

- [x] **TTS pipeline**:`scripts/tts_docker.sh`——docker(`ghcr.io/astral-sh/uv` + edge-tts)生中文語音,
  host ffmpeg 轉成 FOA talkie 格式(11025 Hz / 8-bit unsigned mono)。已試:`voice_test/narration_ny.wav`(男聲 Yunjian)。
- [x] **offset 攔截 + 重導**:patch `startTalkSound`——命中 `atlantis_voice.tab`(offset→VOC)就改播中文。dump 模式(`atlantis_voice_dump`)印 `CHTVOICE<offset>`。
- [x] **印第預設嗓定案**:B = `zh-TW-YunJheNeural` + `-8%` 語速 + `-12Hz` 音調(馬蓋仙台灣配音味)。已設為 `tts_docker.sh` 預設。

**✅ offset 來源破解 → 一鍵批次配音成立**:
- talkie offset 編碼 = 訊息裡**連續四個 `\xFF\x0A` 區塊**(`string.cpp` convertMessageToString 把每個 `\xFF\x0A XX` 複製成 4 byte;`handleNextCharsetCode` case 10 讀 14 byte)。`offset = b0|b1<<8|b2<<16|b3<<24`(前兩塊)。
- [x] `tools/dump_voice.py`:靜態抽出**全 6968 句語音的 (offset, length, text key)**。驗證:journal 句 offset=117849910 逐字對上 runtime。
- [x] `tools/build_voice.py`:join 語音 offset × 譯表 → **255 句已翻且有配音** → 去重後 255 段音檔對應 **1135 個遊戲內 offset**;產 `game/atlantis_voice.tab`。
- [x] `scripts/dub_worker.py`(容器內並行 edge-tts)+ `scripts/dub_batch.sh`(docker TTS → ffmpeg 轉 VOC)→ 255 段中文語音(印第 B 嗓)全生成。
- [x] **分角色配音 v1**:`dump_voice.py` 靜態抽講者(o5_print 的 actor / o5_printEgo=Indy);**a2 = 蘇菲亞**(以「Don't leave me here, Indy」驗證)→ 配台灣女聲 `zh-TW-HsiaoChenNeural`,其餘印第 B。`build_voice.py` 依 actor 分嗓。
  - [ ] 細分其他 NPC(納粹冷硬男聲等):需更多 actor↔角色對照(部分 backward-scan 命中率 ~81%)。

**⚠️ 台語版 = edge-tts 做不到**:edge-tts 只有台灣**國語**(zh-TW-YunJhe/HsiaoChen),**沒有台語(閩南語/Hokkien)**。要台語得換 TTS 引擎:
- [ ] Meta **MMS**(`nan` 閩南語,開源、可 docker)或意傳科技/教育部台語 TTS——另一套整合。

- [ ] 嘴型同步沿用原 timing 或重算。
- [ ] 配音分角色:印第=B 嗓、蘇菲亞=`zh-TW-HsiaoChenNeural`(女)、納粹=`zh-CN-YunyangNeural`(冷硬)。

## Phase 7 — 語言 / 語音切換鍵(worklist)

- [x] **F8 切文字中英**:`input.cpp processKeyboard` 攔截 → `_chtTextOn` toggle(實機驗證:F8 後重繪元素變回英文)。覆寫原本 F8=重新開始(restart 改走選單)。
- [x] **F9 切語音中英**:`_chtVoiceOn` toggle(守 sound.cpp 重導 hook,機制同 F8)。
- [ ] 台語語音集(待 Phase 6 台語子專案)。

## Phase 5 — 打包與展示

- [ ] Linux AppImage / Windows zip / (macOS / Android 視需要),沿用 willy `scripts/package_*.sh`。
- [ ] **game tester 實機驗證**(rule `retro-game-playtest`):正常玩家路徑,確認對白、動詞列、物件名、告示牌都中文化且不破版。
- [ ] 截圖 `screenshots/` 進 README。
- [ ] README 三層 voice 收尾(rule `80-retro-cht-readme-polish`)。

---

## 安全鐵則(沿用 willy)

遊戲 / disc / `extracted/` / `dist/` / `scummvm-src/` / `*.SOU` / `*.EXE` 全 gitignore,**永不 push**。
只 push 工具、patch、`translations/`、docs。Repo:`github.com/wicanr2/indiana-jones-and-the-fate-of-atlantis-cht`。

## 與 willy 的關鍵差異(必讀)

| 項目 | willy(DGDS) | atlantis(SCUMM v5) |
|---|---|---|
| 引擎 | ScummVM `dgds` | ScummVM `scumm`(`GID_INDY4`) |
| 封裝 | `RESOURCE.MAP`+`.001` | `ATLANTIS.000`(索引)+`.001`(資料) |
| 編碼 | chunk `TAG:`+size,部分 LZW | XOR `0x69` 全檔 + tag+BE size |
| 對白所在 | `D#.DDS` 鍵 `<檔號>:<num>` | 腳本內嵌(SCRP/LSCR/VERB),runtime 攔截 |
| 繪字 patch 點 | `engines/dgds` | `engines/scumm/charset.cpp` |
| 字型樣板 | `beamish_zh{16,24}.dcjk` | `atlantis_zh{16,24}`(同 pipeline) |
