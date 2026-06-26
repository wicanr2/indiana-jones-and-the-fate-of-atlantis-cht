# 印第安納·瓊斯:亞特蘭提斯之謎 — 繁體中文化

> *Indiana Jones and the Fate of Atlantis*(LucasArts, 1992)SCUMM v5 CD 語音版的繁體中文化專案。
> 沿用姊妹作《威利奇遇記》的 ScummVM engine-side overlay 路線:不動原版資料,在繪字處攔截、查表、用點陣中文字重畫。

還記得嗎?那是 1992 年,《法櫃奇兵》《聖戰奇兵》之後,大銀幕沒給我們第四集,LucasArts 卻用一張磁片給了——一部**你自己操控的印第安納·瓊斯電影**。鞭子、納粹、柏拉圖失落的對話錄、沉在海底一萬年的亞特蘭提斯。那年我們十幾歲,守著 14 吋 CRT,對著滿螢幕英文一句一句查《電腦玩家》的手冊翻譯,硬是把它破關了。

三十幾年過去。這個 repo 想做的,是把當年那台機器上沒能給我們的東西補上:**一份能讀的中文**。

這份說明你可以三層讀:想知道進度就看 [成果現況](#status);想重溫這款遊戲為什麼是神作,讀 [一部你能操控的電影](#magazine);想看技術怎麼挖的,跳到 [資料考古](#tech)。

---

## 目錄

- [成果現況](#status)
- [一部你能操控的電影](#magazine)
- [資料考古:SCUMM v5 與那個消失的索引檔](#tech)
- [中文化路線](#route)
- [快速開始](#quickstart)
- [譯名與攻略致謝](#credits)
- [後續藍圖](#roadmap)

---

<a name="status"></a>
## 成果現況

機制已經跑通了。引擎、資料、字型、繪字管線全部到位,遊戲底部介面已經是繁體中文;剩下的不再是「能不能做」,而是「把 ~5400 句翻完」。

| 項目 | 狀態 |
|---|---|
| 引擎鑑定 | ✅ SCUMM v5,1993-05 CD 語音版(iMUSE) |
| 遊戲資料完整性 | ✅ CD ISO 補回 `ATLANTIS.000` 索引,`.001` md5 與 Steam 版相同 |
| ScummVM 偵測 | ✅ `scumm:atlantis ... (CD/DOS/English)` |
| 資料解碼 | ✅ 96 房間、1372 物件、~5450 句字串已解出(`tools/scumm_v5.py`) |
| scumm 引擎 ScummVM build | ✅ 自行編進 scumm 引擎(willy 版原只有 dgds) |
| CJK 字型 | ✅ `atlantis_zh{12,16,24}.dcjk`(Big5 點陣) |
| **引擎 CJK patch** | ✅ **動詞列 + 句子列實機渲染中文;對白注入已接好** |
| 完整對白翻譯 | 🛠️ 機制已通,逐句翻譯進行中 |

完整分階段計畫見 **[PLAN.md](PLAN.md)**。

### 它跑起來了——而且開始講中文了

用補回索引的 CD 資料、加上自行編進 scumm 引擎的 ScummVM,遊戲先是原封不動地開起來——那張我們三十年前看過的開場畫面:

![Indiana Jones 開場標題](screenshots/foa_intro.png)

接著就是動刀的地方。原版畫面底部那排英文動詞選單(Give / Pick up / Use / Open / Talk to / Push / Close / Look at / Pull):

![FOA 英文動詞介面](screenshots/foa_gameplay.png)

加上引擎 CJK patch、查表把英文換成 Big5、走 scumm 既有的雙位元組繪字路徑之後——**同一個畫面,底部整排變中文了**:

![FOA 中文介面](screenshots/foa_cht_verbs.png)

> 動詞:給 · 拿起 · 使用 / 開 · **交談** · 推 / 關 · 看 · 拉(游標停在「交談」,黃字反白)。
> 句子列:**走向 售票員**(Walk to ticket taker)——「動詞+物件」用樣板比對組出來。
> 上圖是紐約那家戲院,招牌寫著 *MADAME SOPHIA TONIGHT*——女主角蘇菲亞·哈普古德的通靈秀。
> 整條管線(Big5 點陣字 + 線性索引 + 查表注入)在實機跑通了;演員對白(`actorTalk`)用同一條注入路徑,接上譯文即可講中文。

---

<a name="magazine"></a>
## 一部你能操控的電影

上一段講了進度,但進度表冷冰冰的,撐不起這款遊戲在我們心裡的份量。先說說它為什麼值得有中文版。

老冒險迷絕對記得那個開場:瓊斯博士在自家博物館的閣樓翻箱倒櫃,為了一尊牛角小雕像,結果一鞭子下去,牽出了沉睡一萬年的亞特蘭提斯。這不是隨便編的。LucasArts 把柏拉圖《對話錄》裡那段真實存在的亞特蘭提斯記載,當成整條主線的考據起點——你蒐集的不是寶物,是**線索**:山銅(orichalcum)、失落的城邦、Nur-Ab-Sal 的王冠。

**這款遊戲最狠的設計是**:玩到中段,它會問你怎麼繼續——靠腦袋(Wits)、靠拳頭(Fists),還是帶著女主角蘇菲亞一起(Team)?**三條路,三套謎題,三種過法**。當年沒有 GameFAQ、沒有 Discord、沒有 wiki,我們只能靠《電腦玩家》《軟體世界》三大誌的攻略,或者 BBS 上的討論板,才知道原來自己選的那條路根本不是別人玩的那條。一款 1992 年的遊戲做到這個格局,放到今天都不算過時。

蘇菲亞·哈普古德更是少見的女主角寫法:她不是被救的公主,是瓊斯的前同事、現在靠通靈吃飯的考古學家,嘴利、有主見,還真的會在謎題裡幫上忙。瓊斯和她一路鬥嘴到亞特蘭提斯,那股 1940 年代冒險片的對白節奏,是這款遊戲的靈魂。

而當年的我們,是隔著一層英文在看這部電影的。每一句俏皮話、每一段考據,都得先翻手冊才懂。**這個 repo 就是想把那層隔閡拿掉。**

---

<a name="tech"></a>
## 資料考古:SCUMM v5 與那個消失的索引檔

講完情懷,接下來是冷的部分——這批資料到底長什麼樣,以及第一塊絆腳石是怎麼被挖出來的。

### 引擎與版本鑑定

`ATLANTIS.001` 開頭 16 bytes 與常數 `0x69` 逐 byte XOR 後,得到 `LECF ... LOFF`——SCUMM v5 的容器標記。`ATLANTIS.EXE` 內字串 `5.5.00 (May 05 1993 18:15:17)` 與 `iMUSE, patents pending, tm & (c) 1993 LucasArts` 進一步定版:這是 1993 年的 **256 色 CD 語音版**(`MONSTER.SOU` 即 150 MB 數位語音)。

```
ATLANTIS.001  (XOR 0x69)
└─ LECF                  容器
   ├─ LOFF               房間位移表
   ├─ LFLF  × 96         每個 = 一間房 + 其資源
   │  ├─ ROOM            RMHD / CYCL / PALS / OBIM* / OBCD* / LSCR* / EXCD / ENCD …
   │  ├─ SCRP            全域腳本(對白內嵌)
   │  ├─ SOUN / COST / CHAR
   │  └─ …
```

區塊頭 = 4-byte ASCII tag + 4-byte big-endian size(含 8-byte header)。`tools/scumm_v5.py` 走完整棵樹,從 SCRP/LSCR/VERB/OBNA 解出 ~5450 句字串——對白清楚可讀:

```
VERB  "It's my favorite piece of equipment."
VERB  "It's my old ice box.I haven't used it in months."
OBNA  "horned statue"
```

### 那個消失的索引檔

但這裡撞到第一道牆。SCUMM v5 的遊戲資料是**兩個檔**:`.001`(資料)+ `.000`(索引)。索引檔存的是「全域腳本 / 音效 / 服裝 / 字型的**編號 → 位移**」對照表——而 `.001` 裡的區塊**只有 tag 和 size,沒有編號**。

這份 Steam 複本**只有 `.001`,缺 `.000`**。驗證很直接:

```
$ scummvm --detect --path=".../ATLANTIS"
WARNING: ScummVM could not find any game in .../ATLANTIS

# 對照組:同一個 Steam 庫裡的 Sam & Max(有 samnmax.000)
$ scummvm --detect --path=".../Sam and Max Hit the Road"
scumm:samnmax   Sam & Max Hit the Road (CD/English)
```

少了 `.000`,ScummVM 連遊戲都認不出來。而且**沒辦法只憑 `.001` 把它重建回去**——編號資訊已經遺失,硬湊只會叫錯腳本。這不是程式能繞過去的,得把原始的索引檔補回來。

解法是那張 **CD 版 ISO**:裡頭的 `ATLANTIS/` 帶著完整的 `ATLANTIS.000`(12 KB 索引)。而且關鍵一點——CD 版的 `ATLANTIS.001` 與 Steam 版**md5 完全相同**,證明是同一個版本,先前在 Steam 資料上做的抽字一句都沒白費。補上索引後:

```
$ scummvm --detect --path="atlantis/game"
scumm:atlantis   Indiana Jones and the Fate of Atlantis (CD/DOS/English)
```

石頭搬開了。從這裡開始,遊戲能跑、能改、能截圖。

---

<a name="route"></a>
## 中文化路線

原本打算照姊妹作《威利奇遇記》(`~/willy`,ScummVM `dgds` 引擎)的做法,自己寫一層繪字疊圖層。但翻 scumm 引擎原始碼時發現一件事:**它本來就會畫雙位元組中日韓字**——日文 FM-Towns、韓文、簡體 GB 版都靠這條路;而且裡頭**已經有一個 `ZH_TWN`(繁體 Big5)分支**,只是被限制在較晚的 v7/v8 遊戲。

所以路線改成「接管現成的路,不另起爐灶」:

- **不改遊戲資料**——原版 `.001` 一個 byte 都不動,改的是 ScummVM。
- 把亞特蘭提斯(v5)接上引擎既有的 `ZH_TWN` 繪字路徑,字型索引換成自家 Big5 線性版(配合 `tools/build_cjk_font.py` 烘的點陣字)。**遮罩、定位、文字還原這些麻煩事,引擎全包了。**
- 繪字前在 `drawString`(動詞/句子列)與 `actorTalk`(對白)兩處攔截:**英文原文查表 → 換成 Big5 → 交給既有渲染器畫**。
- 字級隨版位而定:動詞格只有約 10px 高,用 12×12 剛好(與引擎簡體 GB 版同尺寸);對白空間夠,規劃改走 2× 文字層上 24×24,**不把中文縮小硬塞**(rule:拉高畫布,別縮字)。

完整 patch(7 檔)見 `patches/scumm-cjk.patch`;與 willy 的逐項差異見 [PLAN.md](PLAN.md#與-willy-的關鍵差異必讀)。

---

<a name="quickstart"></a>
## 快速開始

> 打包檔尚未產出;目前是「自備遊戲資料 + 套 patch 自行編 ScummVM」的開發流程。

1. 準備遊戲資料:CD 版 ISO 解開後的 `ATLANTIS/`(需含 `ATLANTIS.000` 索引),放成 `game/`。
2. 取 ScummVM 原始碼,套 `patches/scumm-cjk.patch`,以 `--enable-engine=scumm` 編譯。
3. 把 `atlantis_zh16.dcjk`(`tools/build_cjk_font.py` 烘)放進 `game/`。
4. 啟動即偵測為 *Indiana Jones and the Fate of Atlantis*,底部介面顯示中文。headless 驗證見 `scripts/run_headless.sh` / `scripts/capture_scene.sh`。

---

<a name="credits"></a>
## 譯名與攻略致謝

譯名以**遊戲內語料**為準,並對齊 1990s 中文圈通用譯法:瓊斯、亞特蘭提斯、蘇菲亞、納粹。完整譯名表見 [CONTEXT.md](CONTEXT.md)。

當年那份 Big5 中文攻略(作者署名「青衫」)是重要的時代術語 oracle——它讓「瓊斯」「亞特蘭提斯」這些譯名有了 1990s 的依據。**人名與拼字仍一律以遊戲語料為準**(攻略有 OCR 與人工翻譯誤差,例如反派 Kerner 在攻略前段以偽名 Smith 出現)。在此向那個沒有 wiki、只能靠雜誌與 BBS 攻略板撐過每一關的年代,以及寫攻略的人,致謝。

> 攻略全文為第三方著作,只在本機作術語對照參考,不入庫(合理引用)。

---

<a name="roadmap"></a>
## 後續藍圖

完整六階段(補索引 → 抽字 → 烘字型 → 引擎 patch → 翻譯 → 打包驗證)見 **[PLAN.md](PLAN.md)**。

---

> 版權:本 repo 只含工具、patch、翻譯表與文件。**遊戲原始資料、語音、執行檔一律不入庫**,請自備合法 Steam / CD 版。
