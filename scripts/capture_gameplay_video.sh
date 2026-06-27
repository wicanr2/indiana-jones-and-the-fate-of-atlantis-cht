#!/usr/bin/env bash
# 錄「FOA 實機畫面 + 遊戲 iMUSE 音樂」素材(headless:Xvfb + ffmpeg x11grab + SDL disk 音訊)。
# --fullscreen 讓每格都填滿 1280x960(避免 logo/標題切 mode 後變小);背景 xdotool 送鍵驅動
# 跳 logo → 看中文標題 → 進開場(中文字幕)→ Escape 跳到 gameplay(中文動詞)。
# 有界:固定秒數後 SIGKILL,無 sentinel,無 GUI viewer(rule 35)。照 run_headless.sh 的引擎咒語。
set -u
SV="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"
GAME="${GAME:-/home/anr2/indian_jones/atlantis/game}"
SECS="${1:-44}"
DISP=:96; WH=1280x960
RAW=/tmp/foa_cap.raw; VID=/tmp/foa_cap.mp4; WAV=/tmp/foa_cap.wav
rm -f "$RAW" "$VID" "$WAV"

Xvfb $DISP -screen 0 ${WH}x24 >/tmp/xvfb_cap.log 2>&1 & XP=$!
sleep 1
DISPLAY=$DISP SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE="$RAW" SDL_DISKAUDIODELAY=10 \
  "$SV" -p "$GAME" --auto-detect --fullscreen --subtitles \
  --scaler=normal --output-rate=44100 >/tmp/sv_cap.log 2>&1 & SP=$!
sleep 1

# 背景送鍵:驅動 logo→標題→開場→gameplay(時間軸對齊 ffmpeg 的 0s 起點)
( K(){ DISPLAY=$DISP xdotool key "$1" 2>/dev/null; }
  sleep 3;  K Escape; K Escape                 # ~3s 跳 LucasArts/LucasFilm logo
  sleep 9                                       # 4-12s 停在中文標題(highlight)
  K Return; K period                            # 進開場動畫
  sleep 16                                      # 12-28s 開場過場,中文字幕
  K Escape; sleep 1; K Escape; sleep 1; K Escape  # 28s 跳到可操作場景
  sleep 12                                       # 30-44s gameplay,底部中文動詞
) & KP=$!

DISPLAY=$DISP ffmpeg -y -loglevel error -f x11grab -video_size $WH -framerate 25 -i $DISP \
  -t "$SECS" -c:v libx264 -pix_fmt yuv420p -crf 18 "$VID"

kill $KP 2>/dev/null; kill $SP 2>/dev/null; sleep 1; kill -9 $SP 2>/dev/null; kill $XP 2>/dev/null
ffmpeg -y -loglevel error -f s16le -ar 44100 -ac 2 -i "$RAW" "$WAV" 2>/dev/null
echo "畫面 -> $VID ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VID" 2>/dev/null)s)"
echo "音樂 -> $WAV ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$WAV" 2>/dev/null)s)"
