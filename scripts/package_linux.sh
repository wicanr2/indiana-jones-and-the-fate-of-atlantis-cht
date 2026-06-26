#!/usr/bin/env bash
# Assemble a portable, self-contained Linux package of the FOA-CHT build.
#   full  : engine + bundled libs + CHT assets + original game data  (開箱即玩, NOT for public release — copyrighted game data)
#   slim  : engine + bundled libs + CHT assets only (player supplies game data)  — safe to publish
# Bundles the media .so deps next to the binary + an LD_LIBRARY_PATH launcher.
set -euo pipefail
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
ROOT="/home/anr2/indian_jones/atlantis"
GAME="$ROOT/game"
MODE="${1:-full}"            # full | slim
OUT="$ROOT/dist-all/linux/indyatlantis-cht-linux-x86_64-$MODE"
rm -rf "$OUT"; mkdir -p "$OUT/bin" "$OUT/lib" "$OUT/data"

cp "$SV" "$OUT/bin/scummvm"
# bundle non-core shared libs (skip glibc/loader so the host's matching ones are used)
ldd "$SV" | awk '/=>/ {print $3}' | grep -E '\.so' | \
  grep -viE '/(libc|libm|libpthread|libdl|librt|ld-linux|libstdc\+\+|libgcc_s)\.' | \
  while read -r so; do [ -f "$so" ] && cp -Ln "$so" "$OUT/lib/" || true; done

# CHT assets (always) — fonts, translation+voice tables, title, Chinese voice
cp "$GAME"/atlantis_zh16.dcjk "$GAME"/atlantis_zh24.dcjk "$OUT/data/"
cp "$GAME"/atlantis_zh.tab "$GAME"/atlantis_voice.tab "$OUT/data/"
cp "$ROOT"/fonts/atlantis_title.spr "$OUT/data/"
mkdir -p "$OUT/data/voice"; cp "$GAME"/voice/*.voc "$OUT/data/voice/" 2>/dev/null || true

if [ "$MODE" = full ]; then
  # original game data (copyrighted — local/personal use only)
  cp "$GAME"/ATLANTIS.000 "$GAME"/ATLANTIS.001 "$GAME"/MONSTER.SOU "$OUT/data/"
  cp "$GAME"/*.IMS "$GAME"/ADLIB.IMS "$OUT/data/" 2>/dev/null || true
fi

# minimal config: an 'atlantis' target pointing at data/
cat > "$OUT/scummvm.ini" <<INI
[scummvm]
gui_theme=builtin
[atlantis]
engineid=scumm
gameid=atlantis
description=Indiana Jones and the Fate of Atlantis (CHT)
path=./data
language=zh-Hant
INI

cat > "$OUT/play.sh" <<'LAUNCH'
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/bin/scummvm" -c "$HERE/scummvm.ini" -p "$HERE/data" --auto-detect "$@"
LAUNCH
chmod +x "$OUT/play.sh" "$OUT/bin/scummvm"

cat > "$OUT/README.txt" <<TXT
印第安納·瓊斯:亞特蘭提斯之謎 — 繁體中文版 (Linux x86_64, $MODE)
執行: ./play.sh
F8 切換字幕語言(中/英)  F9 切換語音(中/英)
TXT
[ "$MODE" = slim ] && cat >> "$OUT/README.txt" <<TXT

此為 slim 版:不含原版遊戲資料。請自行把合法持有的
ATLANTIS.000 / ATLANTIS.001 / MONSTER.SOU 放進 data/ 目錄。
TXT

du -sh "$OUT"
echo "built: $OUT"
