#!/usr/bin/env bash
# Boot FOA headless, skip the intro with ESC, screenshot the gameplay scene.
# Bounded (fixed sleeps + SIGKILL, no sentinel loop, no GUI viewer — rule 35).
# Usage: capture_scene.sh <out.png> [pre_secs] [esc_count]
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/scene.png}"
PRE="${2:-8}"; ESC="${3:-6}"
DISP=:96
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_scene.log 2>&1 &
XP=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 >/tmp/scummvm_scene.log 2>&1 &
SP=$!
sleep "$PRE"
for n in $(seq 1 "$ESC"); do DISPLAY=$DISP xdotool key Escape 2>/dev/null; sleep 2; done
sleep 3
DISPLAY=$DISP import -window root "$OUT" 2>/dev/null
echo "shot -> $OUT ($(identify -format '%wx%h' "$OUT" 2>/dev/null))"
kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
