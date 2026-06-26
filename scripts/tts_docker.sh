#!/usr/bin/env bash
# Chinese TTS via Docker (edge-tts in the uv image) — no system Python pollution.
# Outputs an MP3, then converts to the SCUMM talkie VOC-ish WAV (11025 Hz / 8-bit
# mono unsigned) so it can be fed into MONSTER.SOU or the engine voice-redirect.
#
# Usage: tts_docker.sh "中文文字" OUT_BASENAME [voice] [rate] [pitch]
#   produces OUT_BASENAME.mp3 and OUT_BASENAME.wav
#   印第(MacGyver/馬蓋仙 味):台灣國語男聲 zh-TW-YunJheNeural + 壓低音調、放慢
#   蘇菲亞:zh-TW-HsiaoChenNeural(女);納粹:zh-CN-YunyangNeural(冷硬)
#   rate 例 "-8%"、pitch 例 "-10Hz"(留空為原值)
set -euo pipefail
# 印第預設嗓(定案 B,馬蓋仙味):台灣國語男聲 + 壓低音調、放慢
TEXT="$1"; OUTBASE="$2"; VOICE="${3:-zh-TW-YunJheNeural}"; RATE="${4:--8%}"; PITCH="${5:--12Hz}"
OUTDIR="$(cd "$(dirname "$OUTBASE")" && pwd)"; NAME="$(basename "$OUTBASE")"
IMG="ghcr.io/astral-sh/uv:python3.12-bookworm-slim"
EXTRA=""
[ -n "$RATE" ]  && EXTRA="$EXTRA --rate=$RATE"
[ -n "$PITCH" ] && EXTRA="$EXTRA --pitch=$PITCH"

timeout 180 docker run --rm -v "$OUTDIR":/out "$IMG" \
  uv run --with edge-tts -- edge-tts --voice "$VOICE" $EXTRA --text "$TEXT" \
  --write-media "/out/${NAME}.mp3"

# host ffmpeg: mp3 -> 11025Hz 8-bit unsigned mono (matches FOA talkie samples)
ffmpeg -y -loglevel error -i "${OUTBASE}.mp3" -ar 11025 -ac 1 -acodec pcm_u8 "${OUTBASE}.wav"
echo "tts -> ${OUTBASE}.mp3 + ${OUTBASE}.wav ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "${OUTBASE}.wav" 2>/dev/null)s, voice=$VOICE)"
