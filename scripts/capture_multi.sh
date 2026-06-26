#!/usr/bin/env bash
# Boot FOA headless once, take a burst of screenshots across the intro/opening so
# we can pick the frames that show Chinese dialogue. Bounded: fixed sleeps + SIGKILL,
# no sentinel loop, no GUI viewer (rule 35).
# Usage: capture_multi.sh <out_dir> [shot_times_csv]   e.g. "10,16,22,28,34,40,46,52,58"
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/cand}"
TIMES="${2:-10,16,22,28,34,40,46,52,58}"
mkdir -p "$OUT"
DISP=:97
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_multi.log 2>&1 &
XP=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 \
  >/tmp/scummvm_multi.log 2>&1 &
SP=$!
prev=0
IFS=',' read -ra TS <<< "$TIMES"
for t in "${TS[@]}"; do
  d=$(( t - prev )); prev=$t
  sleep "$d"
  f="$OUT/t${t}.png"
  DISPLAY=$DISP import -window root "$f" 2>/dev/null
  echo "shot t=${t}s -> $f ($(identify -format '%wx%h' "$f" 2>/dev/null))"
done
kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
echo "=== scummvm log tail ==="; tail -6 /tmp/scummvm_multi.log