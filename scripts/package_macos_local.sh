#!/usr/bin/env bash
# Take the macOS engine .app downloaded from the GitHub Action artifact and fold in
# the Chinese voice + your own game data -> a full, ready-to-play .app in dist-all.
# Usage: package_macos_local.sh <path-to-downloaded IndyAtlantis-CHT.app>
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:?give the downloaded IndyAtlantis-CHT.app path}"
[ -d "$SRC/Contents/MacOS" ] || { echo "not a .app: $SRC"; exit 1; }
OUT="dist-all/macos/IndyAtlantis-CHT-FULL.app"
rm -rf "$OUT"; mkdir -p "$(dirname "$OUT")"
cp -a "$SRC" "$OUT"
D="$OUT/Contents/Resources/data"
mkdir -p "$D/voice"
# Chinese voice + voice table (the heavy CHT asset, kept out of public CI)
cp game/atlantis_voice.tab "$D/" 2>/dev/null || true
cp game/voice/*.voc "$D/voice/" 2>/dev/null || true
# your legally-owned game data
cp game/ATLANTIS.000 game/ATLANTIS.001 game/MONSTER.SOU "$D/"
cp game/*.IMS "$D/" 2>/dev/null || true
du -sh "$OUT"; echo "full macOS .app -> $OUT  (個人自留,含版權遊戲資料,勿散布)"
