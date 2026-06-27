#!/usr/bin/env bash
# Package the docker-cross-built scummvm.exe into a Windows x64 folder.
#   full : + Chinese voice + your game data (開箱即玩, 個人自留 — copyrighted data)
#   slim : engine + CHT light assets only (player drops in their own game data)
# SDL2 is static-linked, so only the 3 mingw runtime DLLs are bundled.
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-full}"
EXE=build-win/out/scummvm.exe
[ -f "$EXE" ] || { echo "run scripts/build_windows_docker.sh first (need $EXE)"; exit 1; }
P="dist-all/windows/IndyAtlantis-CHT-win64-$MODE"
rm -rf "$P"; mkdir -p "$P/data/voice"
cp "$EXE" "$P/"
cp build-win/out/*.dll "$P/" 2>/dev/null || true     # libgcc_s_seh-1 / libstdc++-6 / libwinpthread-1
# CHT light assets
cp game/atlantis_zh16.dcjk game/atlantis_zh24.dcjk game/atlantis_zh.tab fonts/atlantis_title.spr "$P/data/"
if [ "$MODE" = full ]; then
  cp game/atlantis_voice.tab "$P/data/"
  cp game/voice/*.voc "$P/data/voice/" 2>/dev/null || true
  cp game/ATLANTIS.000 game/ATLANTIS.001 game/MONSTER.SOU "$P/data/"
  cp game/*.IMS "$P/data/" 2>/dev/null || true
else
  rmdir "$P/data/voice" 2>/dev/null || true
fi
printf '@echo off\r\nscummvm.exe --extrapath=data -p data --auto-detect %%*\r\n' > "$P/play.bat"
printf '印第安納·瓊斯:亞特蘭提斯之謎 — 繁中版 (Windows x64, %s)\r\n雙擊 play.bat 執行。F8 切字幕語言、F9 切語音。\r\n' "$MODE" > "$P/README.txt"
[ "$MODE" = slim ] && printf '\r\nslim 版不含原版遊戲資料,請把合法持有的 ATLANTIS.000/.001/MONSTER.SOU 放進 data\\\r\n' >> "$P/README.txt"
du -sh "$P"; echo "Windows $MODE -> $P"
