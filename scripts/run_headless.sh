#!/usr/bin/env bash
# Launch ScummVM (FOA / atlantis) headless under Xvfb, screenshot after N sec, then kill.
# Bounded: fixed sleep then SIGKILL, no sentinel loop, no GUI viewer. (rule 35)
# Usage: run_headless.sh <out.png> [seconds] [extra scummvm args...]
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/smoke.png}"; shift || true
SECS="${1:-15}"; shift || true
mkdir -p "$(dirname "$OUT")"
DISP=:98
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_atl.log 2>&1 &
XVFB_PID=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 "$@" >/tmp/scummvm_atl.log 2>&1 &
SV_PID=$!
sleep "$SECS"
DISPLAY=$DISP import -window root "$OUT" 2>/tmp/import_atl.log
echo "screenshot -> $OUT ($(identify -format '%wx%h' "$OUT" 2>/dev/null))"
kill $SV_PID 2>/dev/null; sleep 1; kill -9 $SV_PID 2>/dev/null
kill $XVFB_PID 2>/dev/null
echo "=== scummvm log tail ==="; tail -15 /tmp/scummvm_atl.log
