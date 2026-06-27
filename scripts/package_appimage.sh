#!/usr/bin/env bash
# Build a single-file AppImage of the FOA-CHT build (adapts willy's approach).
#   slim : engine + bundled libs + CHT assets (玩家把遊戲資料放 .AppImage 旁或當參數傳)  — 可公開
#   full : 再內嵌中文語音 + 原版遊戲資料 -> 開箱即玩 (個人自留, 含版權資料, 勿散布)
# Output: dist-all/linux/IndyAtlantis-CHT[-FULL]-x86_64.AppImage
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-full}"
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="game"
TOOL="${APPIMAGETOOL:-/home/anr2/zak-cht-build/appimagetool}"
[ -x "$TOOL" ] || { echo "need appimagetool at $TOOL"; exit 1; }
SUF=""; [ "$MODE" = full ] && SUF="-FULL"
APPDIR="dist-all/linux/IndyAtlantis-CHT${SUF}.AppDir"
OUT="dist-all/linux/IndyAtlantis-CHT${SUF}-x86_64.AppImage"
rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/indyatlantis-cht/voice"

cp "$SV" "$APPDIR/usr/bin/scummvm"
ldd "$SV" | awk '/=>/{print $3}' | grep -E '\.so' \
  | grep -viE '/(libc|libm|libpthread|libdl|librt|ld-linux|libstdc\+\+|libgcc_s)\.' \
  | while read -r so; do [ -f "$so" ] && cp -Ln "$so" "$APPDIR/usr/lib/" || true; done

# CHT assets -> usr/share (passed via --extrapath at runtime)
A="$APPDIR/usr/share/indyatlantis-cht"
cp "$GAME"/atlantis_zh16.dcjk "$GAME"/atlantis_zh24.dcjk "$GAME"/atlantis_zh.tab "$GAME"/atlantis_voice.tab "$A/"
cp fonts/atlantis_title.spr "$A/"
[ "$MODE" = full ] && cp "$GAME"/voice/*.voc "$A/voice/" 2>/dev/null || true

if [ "$MODE" = full ]; then
  mkdir -p "$APPDIR/game"
  cp "$GAME"/ATLANTIS.000 "$GAME"/ATLANTIS.001 "$GAME"/MONSTER.SOU "$APPDIR/game/"
  cp "$GAME"/*.IMS "$APPDIR/game/" 2>/dev/null || true
fi

cat > "$APPDIR/AppRun" <<'RUN'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
SV="$HERE/usr/bin/scummvm"; EXTRA="$HERE/usr/share/indyatlantis-cht"
has_game(){ [ -f "$1/ATLANTIS.001" ] || [ -f "$1/atlantis.001" ]; }
# 1) explicit game dir arg
[ $# -ge 1 ] && [ -d "$1" ] && { exec "$SV" --extrapath="$EXTRA" -p "$1" --auto-detect; }
# 2) game embedded in the AppImage (full build) -> download & play
has_game "$HERE/game" && exec "$SV" --extrapath="$EXTRA" -p "$HERE/game" --auto-detect
# 3) game data sitting next to the .AppImage / in CWD
IMGDIR="$(dirname "$(readlink -f "${APPIMAGE:-$0}")")"
for b in "$IMGDIR" "$PWD"; do has_game "$b" && exec "$SV" --extrapath="$EXTRA" -p "$b" --auto-detect; done
echo "找不到遊戲資料(ATLANTIS.001)。把它放在 .AppImage 旁,或: ./IndyAtlantis*.AppImage /path/to/game" >&2
exec "$SV" --extrapath="$EXTRA"
RUN
chmod +x "$APPDIR/AppRun" "$APPDIR/usr/bin/scummvm"

NAME="Indy Atlantis CHT"; [ "$MODE" = full ] && NAME="Indy Atlantis CHT (FULL)"
cat > "$APPDIR/indyatlantis-cht.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$NAME
Comment=印第安納·瓊斯:亞特蘭提斯之謎 繁體中文版
Exec=AppRun
Icon=indyatlantis-cht
Categories=Game;
Terminal=false
DESK
# icon from the title screenshot, else a fallback glyph
if command -v convert >/dev/null 2>&1; then
  if [ -f screenshots/foa_cht_title.png ]; then
    convert screenshots/foa_cht_title.png -gravity center -resize 256x256^ -extent 256x256 "$APPDIR/indyatlantis-cht.png" 2>/dev/null || true
  fi
  [ -f "$APPDIR/indyatlantis-cht.png" ] || convert -size 256x256 xc:'#101830' -fill '#f0c000' -gravity center -pointsize 120 -annotate 0 "印" "$APPDIR/indyatlantis-cht.png" 2>/dev/null || true
fi
[ -f "$APPDIR/indyatlantis-cht.png" ] || : > "$APPDIR/indyatlantis-cht.png"
cp "$APPDIR/indyatlantis-cht.png" "$APPDIR/.DirIcon" 2>/dev/null || true

ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APPDIR" "$OUT" 2>&1 | tail -3
rm -rf "$APPDIR"
ls -lh "$OUT" 2>/dev/null && echo "AppImage ($MODE) -> $OUT" || { echo "AppImage build FAILED"; exit 1; }
