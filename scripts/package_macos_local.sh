#!/usr/bin/env bash
# Take the macOS engine .app downloaded from the GitHub Action artifact and fold in
# the Chinese voice + your own game data -> a full, ready-to-play bundle in dist-all.
# 產出一個資料夾(.app + 使用說明.txt)並打成 .tar.gz(保留 .app 權限/symlink;
# 不用 zip — zip 會破壞執行權限與 bundle symlink)。
# Usage: package_macos_local.sh <path-to-downloaded IndyAtlantis-CHT.app>
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:?give the downloaded IndyAtlantis-CHT.app path}"
[ -d "$SRC/Contents/MacOS" ] || { echo "not a .app: $SRC"; exit 1; }

PKG="dist-all/macos/IndyAtlantis-CHT-mac-full"     # 交付資料夾(.app + 說明)
OUT="$PKG/印第安納瓊斯-亞特蘭提斯之謎(繁中).app"   # 給使用者看的中文 app 名
rm -rf "$PKG"; mkdir -p "$PKG"
cp -a "$SRC" "$OUT"
D="$OUT/Contents/Resources/data"
mkdir -p "$D/voice"
# Chinese voice + voice table (the heavy CHT asset, kept out of public CI)
cp game/atlantis_voice.tab "$D/" 2>/dev/null || true
cp game/voice/*.voc "$D/voice/" 2>/dev/null || true
# your legally-owned game data
cp game/ATLANTIS.000 game/ATLANTIS.001 game/MONSTER.SOU "$D/"
cp game/*.IMS "$D/" 2>/dev/null || true

# ---- 使用說明.txt(繁中,放在 .app 旁邊讓使用者一眼看到)----
cat > "$PKG/使用說明.txt" <<'TXT'
印第安納瓊斯：亞特蘭提斯之謎  繁體中文版（macOS）
====================================================

這是什麼
--------
LucasArts 1992 年經典冒險遊戲《Indiana Jones and the Fate of Atlantis》
的繁體中文化版本，以 ScummVM 引擎執行。本包已內含遊戲資料與中文語音，
解壓即可玩，不需另外安裝原版遊戲。

支援機型：Intel 與 Apple Silicon（M1/M2/M3…）皆可（universal 二進位）。
系統需求：macOS 11.0 以上。

怎麼玩（第一次請照做）
----------------------
這個 app 沒有經過 Apple 簽章，macOS 預設會擋下來。請二選一：

  做法 A（最簡單，建議）— 對 app 按右鍵
    1. 在 Finder 對「印第安納瓊斯-亞特蘭提斯之謎(繁中).app」按右鍵 →「打開」。
    2. 跳出警告時，再按一次「打開」。之後雙擊就能直接玩。

  做法 B — 終端機解除隔離（整包一次處理）
    打開「終端機」，把下面這行貼上去（把路徑換成你放的位置）後按 Enter：
        xattr -dr com.apple.quarantine "印第安納瓊斯-亞特蘭提斯之謎(繁中).app"
    然後雙擊 app 即可。

如果出現「已損毀，無法打開」
--------------------------
那是 Gatekeeper 的隔離標記造成的，不是檔案壞掉。照上面「做法 B」執行
xattr 那行指令即可解決。

存檔位置
--------
遊戲存檔在 ~/Documents/ScummVM Savegames/（或 ScummVM 預設存檔目錄），
不在這個 app 內，刪除 app 不會動到存檔。

包內容
------
‧ app 本體（ScummVM 引擎 + 繁中字型/譯名/標題 + 遊戲資料 + 中文語音）
‧ 本說明檔

備註
----
本包含原版遊戲版權資料與中文配音，僅供個人保存使用，請勿散布。
TXT

# ---- 打包成 tar.gz(Mac 之間傳輸用,保留權限)----
TARBALL="dist-all/macos/IndyAtlantis-CHT-mac-full.tar.gz"
rm -f "$TARBALL"
tar -C dist-all/macos -czf "$TARBALL" "$(basename "$PKG")"

du -sh "$PKG" "$TARBALL"
echo "full macOS 交付 -> $PKG/  (含 .app + 使用說明.txt)"
echo "             tar -> $TARBALL  (傳到 Mac 用,個人自留,含版權資料,勿散布)"
