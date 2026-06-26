#!/usr/bin/env bash
# Look at several NY objects, burst-screenshot during Indy's spoken line to catch a
# good long dialogue frame. Bounded (rule 35).
set -u
SV="/home/anr2/willy/scummvm-src/scummvm"
GAME="/home/anr2/indian_jones/atlantis/game"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/lines}"
mkdir -p "$OUT"
DISP=:94
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_lines.log 2>&1 & XP=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 >/tmp/scummvm_lines.log 2>&1 & SP=$!
sleep 9
for n in $(seq 1 6); do DISPLAY=$DISP xdotool key Escape; sleep 1.5; done
sleep 3
shot(){ DISPLAY=$DISP import -window root "$OUT/$1.png" 2>/dev/null; }
look(){ # $1,$2 = object screen coords ; $3 = tag
  DISPLAY=$DISP xdotool mousemove 355 818; sleep 0.3; DISPLAY=$DISP xdotool click 1; sleep 0.4
  DISPLAY=$DISP xdotool mousemove "$1" "$2"; sleep 0.3; DISPLAY=$DISP xdotool click 1
  for k in 1 2 3 4; do sleep 0.9; shot "${3}_${k}"; done
  DISPLAY=$DISP xdotool key Escape; sleep 1
}
look 490 185 marquee     # MADAME SOPHIA marquee
look 700 235 newssign    # NEWS sign
look 520 320 booth       # ticket booth
look 1010 270 lamp2      # lamp
kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null