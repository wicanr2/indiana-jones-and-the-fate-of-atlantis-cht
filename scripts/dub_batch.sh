#!/usr/bin/env bash
# Batch-dub all translated+voiced lines into game/voice/*.voc.
#   tools/build_voice.py  -> extracted/dub_manifest.tsv + game/atlantis_voice.tab
#   docker(uv+edge-tts)   -> game/voice/*.mp3  (concurrent, resumable)
#   host ffmpeg           -> game/voice/*.voc  (FOA talkie format)
# Bounded, foreground, --rm; no sentinel loops (rule 35).
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tools/build_voice.py
mkdir -p game/voice
cp extracted/dub_manifest.tsv game/voice/dub_manifest.tsv

echo "=== TTS (docker edge-tts, Indy voice B) ==="
timeout 1800 docker run --rm \
  -e DUB_VOICE -e DUB_RATE -e DUB_PITCH -e DUB_CONC \
  -v "$PWD/game/voice":/work/voice \
  -v "$PWD/game/voice/dub_manifest.tsv":/work/dub_manifest.tsv:ro \
  -v "$PWD/scripts/dub_worker.py":/work/dub_worker.py:ro \
  ghcr.io/astral-sh/uv:python3.12-bookworm-slim \
  uv run --with edge-tts -- python /work/dub_worker.py

# fix docker root-owned files
docker run --rm -v "$PWD/game/voice":/v ghcr.io/astral-sh/uv:python3.12-bookworm-slim \
  chown -R "$(id -u):$(id -g)" /v 2>/dev/null || true

echo "=== mp3 -> voc (host ffmpeg, 11025/8-bit/mono unsigned) ==="
made=0
for mp3 in game/voice/*.mp3; do
  [ -e "$mp3" ] || continue
  voc="${mp3%.mp3}.voc"
  if [ ! -s "$voc" ]; then
    ffmpeg -y -loglevel error -i "$mp3" -ar 11025 -ac 1 -acodec pcm_u8 "$voc" && made=$((made+1))
  fi
done
rm -f game/voice/dub_manifest.tsv
echo "=== done: $(ls game/voice/*.voc 2>/dev/null | wc -l) voc files ($made new) ==="
