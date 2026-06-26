# CONTEXT — 印第安納·瓊斯：亞特蘭提斯之謎 繁體中文化

Domain glossary。寫程式、命名變數、寫文件、翻譯時一律用這套術語。
源頭概念見 Eric Evans, *Domain-Driven Design*。

## Game / engine

- **Atlantis / FOA** — *Indiana Jones and the Fate of Atlantis*（LucasArts, 1992）。本中文化標的。中文標題《印第安納·瓊斯：亞特蘭提斯之謎》。
- **SCUMM v5** — LucasArts 的 *Script Creation Utility for Maniac Mansion* 引擎,第 5 版。FOA 用此版。ScummVM `scumm` engine 遊玩(game id `atlantis`、`GID_INDY4`、`version 5`)。
- **CD Talkie 版** — 本 Steam 版為 1993 年 256 色 CD 語音版(`5.5.00 (May 05 1993)`,iMUSE 1993)。`MONSTER.SOU` = 數位語音;`*.IMS` = iMUSE 音樂(AdLib / Roland MT-32)。
- **ATLANTIS.000** — **索引檔**(index)。RNAM/MAXS/DROO/DSCR/DSOU/DCOS/DCHR/DOBJ 目錄,把全域資源編號映射到 `(room#, offset)`。ScummVM 偵測遊戲時讀此檔。**目前 Steam 複本缺此檔**(見 PLAN.md「Phase 0」)。
- **ATLANTIS.001** — **資料檔**(data archive)。XOR `0x69` 編碼的 `LECF` 容器。LOFF(房間位移表)+ 96 個 `LFLF`(房間)。對白與物件名都在此。
- **Block / Chunk** — SCUMM 資源區塊:4-byte ASCII tag + 4-byte big-endian size(含 8-byte header)。容器類(LECF/LFLF/ROOM/OBCD/OBIM/SOUN/RMIM)內含子區塊。
- **LFLF** — 一個「房間 + 其資源」打包單位(本遊戲 96 個)。內含 ROOM、全域 SCRP/SOUN/COST/CHAR。
- **ROOM** — 房間區塊:RMHD/CYCL/TRNS/PALS/RMIM/OBIM*/OBCD*/EXCD/ENCD/LSCR*/BOXD…。

## 文字所在(可譯單位)

- **SCRP** — 全域腳本(163 個)。內嵌 print/talk 字串。
- **LSCR** — 房間區域腳本(1079 個)。多數對白在此。
- **EXCD / ENCD** — 房間進入 / 離開腳本(各 96)。
- **VERB** — 物件動詞腳本(在 OBCD 內,1372 個)。物件被操作時的回應台詞。
- **OBNA** — 物件名稱(1372 個,`@` padding 結尾)。游標指到物件時顯示的名字。
- **Sentence line / Verb UI** — 畫面底部的動詞列(Open/Pick up/Talk to…)與組合的句子。在 charset / verb script 路徑繪出。

## SCUMM 字串格式

- 字串為可印 ASCII run,`0x00` 結尾。`0xFF` 為跳脫:
  - `0xFF 0x01` = 換行;`0xFF 0x02/0x03/0x08` = keepText / wait / 控制(1 byte 參數);
  - `0xFF 0x04/0x06/0x07/0x09/0x0A` = var/verb/name 等(2 byte 參數)。
- **Source encoding** — DOS **CP437 / ASCII**。FOA 英文版只用 ASCII。

## Localization 路線(engine-side overlay,沿用 `~/willy`)

不改遊戲資料;patch ScummVM 在繪字處(`engines/scumm/charset.cpp`)攔截英文字串 → 查表 → 用點陣 CJK 字型重畫到 hi-res 疊圖層。F-key 切語言。

- **Translation slot** — 單一可譯單位,鍵 = 原文英文字串(runtime 攔截到的)。
- **zh.json / zh.dtr** — 翻譯表(Big5)。`tools/build_translation.py` 產(待建)。
- **atlantis_zh{16,24}** — 點陣 CJK 字型(Big5 linear index)。`tools/build_cjk_font.py` 產(待建,沿用 willy)。
- **Hi-res canvas** — 中文走 24×24 點陣,底圖 nearest-neighbor 放大(見 rule `81-retro-cjk-hires-canvas`)。**不縮小中文字塞原版 8px 字位**。
- **DisplayMode** — F-key 循環:英文原版 / 中文 24×24 / 中文 16×16。

## 譯名表(character / proper-noun glossary）

> 翻譯一律用,確保全劇本一致。`✓`=定案(對齊 1990s 軟體世界攻略 + 電影官方譯名),`?`=草稿待確認。
> 數字 = 該專有名詞在 5400+ 句語料中的出現次數(出場份量)。
> **方針:主角與電影通用譯名忠實直譯(瓊斯/印第);納粹反派音譯;玩梗從簡。**

### 主角陣營 — 忠實(對齊電影官方譯名)

| 英文 | 中文 | 備註 |
|---|---|---|
| Indy / Indiana ✓ | **印第 / 印第安納** | 57+5 句。主角暱稱「印第」、全名「印第安納·瓊斯」。電影通用譯名 |
| Jones / Dr. Jones ✓ | **瓊斯 / 瓊斯博士** | 38 句。姓。攻略沿用「瓊斯」 |
| Sophia Hapgood ✓ | **蘇菲亞·哈普古德** | 37 句。女主角,前考古學家、現靈媒。名牌「蘇菲亞」 |
| Marcus Brody ? | **馬可仕·布洛迪** | 博物館館長。電影常客 |

### 納粹反派 — 音譯

| 英文 | 中文 | 備註 |
|---|---|---|
| Kerner ? | **柯納** | 13 句。納粹博士,偽裝身分接近瓊斯(攻略提及 Smith→Kerner)|
| Trottier ? | **特羅蒂耶** | 19 句。待確認身分 |
| Sternhart ? | **史登哈特** | 5 句。神父 / 學者角色 |
| Übermann / Nur-Ab-Sal ? | 待定 | Nur-Ab-Sal = 亞特蘭提斯古王(劇情關鍵)|

### 專有名詞

| 英文 | 中文 | 備註 |
|---|---|---|
| Atlantis ✓ | **亞特蘭提斯** | 41 句。攻略 + 通用譯名。標題核心 |
| Nazi ✓ | **納粹** | 12 句 |
| orichalcum ? | **山銅 / 奧利哈剛** | 亞特蘭提斯傳說金屬,劇情關鍵物。待選一 |
| Plato's dialogue ? | **柏拉圖對話錄** | 劇情線索來源 |

> 說話人標籤 / 全形標點:對白統一全形冒號與標點。原文若有拼字錯誤翻譯時一併歸位。

## 動詞介面譯名(MVP — 第一個中文化里程碑)

畫面底部的九個動詞 + 句子列動詞,字數少、出現頻率最高、是驗證 overlay 機制的最小集合。沿用 1990s SCUMM 中文化通用譯法:

| 英文 | 中文 | 英文 | 中文 |
|---|---|---|---|
| Give | 給 | Push | 推 |
| Pick up | 拿起 | Close | 關 |
| Use | 使用 | Look at | 看 |
| Open | 開 | Pull | 拉 |
| Talk to | 交談 | Walk to | 走向 |

> 句子列範例:`Walk to ticket taker` → `走向 售票員`。動詞 + 物件名組合,物件名走 OBNA 譯表。

## 1990s 官方術語 oracle

- **中文攻略**(Big5,作者「青衫」)逐頁見 [`docs/atlantis_utf8.txt`](docs/atlantis_utf8.txt)、PDF 見 `docs/DDSC-J-00160-*.pdf`。標題《亞特蘭提斯之謎》、瓊斯、亞特蘭提斯等 1990s 用法可參考。
- **人名 / 拼字一律以遊戲語料為準**(攻略有 OCR 與人工翻譯誤差,如 Kerner 在攻略先以 Smith 偽裝出現)。

## Flagged ambiguities

- 三線劇情分支(Wits / Fists / Team path)用語是否需區分譯法,待玩到再定。
- orichalcum 譯「山銅」(常見學名)或「奧利哈剛」(音譯),待確認。
- 反派 Trottier/Sternhart 的身分與敬語層級待玩到對應段落確認。
