#!/usr/bin/env bash
# 拍「句子列(動作句)中文不再被裁」的證明圖:選動詞 → hover 物件(不點擊)→ 句子列顯示
# 「<動詞> <物件>」中文 → 截圖。用修正後引擎(verbs.cpp drawVerb 跨界上提 ypos)。
# Bounded:固定 sleep + SIGKILL,無 sentinel 迴圈、無 GUI viewer(rule 35)。
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
OUT="${1:-/home/anr2/indian_jones/atlantis/screenshots/sentence}"
mkdir -p "$OUT"
DISP=:93
Xvfb $DISP -screen 0 1280x960x24 >/tmp/xvfb_sent.log 2>&1 & XP=$!
sleep 1
DISPLAY=$DISP "$SV" -p "$GAME" --auto-detect --no-fullscreen --scaler=normal --scale-factor=3 >/tmp/scummvm_sent.log 2>&1 & SP=$!
sleep 9
for n in $(seq 1 10); do DISPLAY=$DISP xdotool key Escape; sleep 1.5; done
sleep 3
shot(){ DISPLAY=$DISP import -window root "$OUT/$1.png" 2>/dev/null; echo "  shot $1"; }
selverb(){ DISPLAY=$DISP xdotool mousemove "$1" "$2"; sleep 0.3; DISPLAY=$DISP xdotool click 1; sleep 0.4; }
hover(){ DISPLAY=$DISP xdotool mousemove "$1" "$2"; sleep 0.8; }
# verb coords(1280x960):看=(355,818) 拿起=(355,710) 交談=(355,765) 使用=(510,710)
# 選「看」→ hover 物件,句子列顯示「看 <物件>」
selverb 355 818; hover 700 235; shot 01_look_news       # 看 報攤/NEWS
selverb 355 818; hover 470 185; shot 02_look_marquee     # 看 看板(MADAME SOPHIA)
selverb 355 710; hover 770 470; shot 03_take_booth       # 拿起 電話亭
selverb 510 710; hover 315 295; shot 04_use_taxi         # 使用 計程車
# 純 hover(預設動詞「走到」)
hover 470 185; shot 05_walkto_marquee
kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
echo "done -> $OUT"
