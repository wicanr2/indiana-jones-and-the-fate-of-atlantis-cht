#!/usr/bin/env bash
# Boot FOA, ESC-skip the intro to the playable New York scene, then drive the verb
# interface with xdotool to elicit Chinese dialogue (Look at / Talk to), screenshotting
# each. Bounded: fixed sleeps + SIGKILL, no sentinel loop, no GUI viewer (rule 35).
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/look}"
mkdir -p "$OUT"
DISP=:95
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_look.log 2>&1 &
XP=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 \
  >/tmp/scummvm_look.log 2>&1 &
SP=$!
sleep 9
# skip intro cutscene
for n in $(seq 1 10); do DISPLAY=$DISP xdotool key Escape; sleep 1.5; done
sleep 3
shot(){ DISPLAY=$DISP import -window root "$OUT/$1.png" 2>/dev/null; echo "  shot $1"; }
click(){ DISPLAY=$DISP xdotool mousemove "$1" "$2"; sleep 0.4; DISPLAY=$DISP xdotool click 1; sleep 0.5; }
# verb coords (1280x960): 看=(355,818) 交談=(355,765) 拿起=(355,710) 使用=(510,710)
LOOK_X=355; LOOK_Y=818; TALK_X=355; TALK_Y=765

shot 00_scene                       # clean verb UI

click $LOOK_X $LOOK_Y               # 看
click 735 300                       # newsstand "NEWS"
sleep 1.5; shot 01_look_news
DISPLAY=$DISP xdotool key Escape; sleep 1

click $LOOK_X $LOOK_Y
click 1010 270                      # street lamp
sleep 1.5; shot 02_look_lamp
DISPLAY=$DISP xdotool key Escape; sleep 1

click $LOOK_X $LOOK_Y
click 315 295                       # taxi
sleep 1.5; shot 03_look_taxi
DISPLAY=$DISP xdotool key Escape; sleep 1

click $LOOK_X $LOOK_Y
click 775 450                       # phone booth
sleep 1.5; shot 04_look_booth
DISPLAY=$DISP xdotool key Escape; sleep 1

click $TALK_X $TALK_Y               # 交談
click 395 300                       # figure on street
sleep 1.5; shot 05_talk_figure

kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
echo "=== console (CHT lines) ==="; grep -iE 'CHTVOICE|CHTMISS|big5' /tmp/scummvm_look.log | tail -5