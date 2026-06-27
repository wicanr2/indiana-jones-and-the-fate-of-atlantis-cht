#!/usr/bin/env bash
# 用截圖 + 中文字幕烘一段 YouTube 介紹 MP4(1280x720,淡入淡出)。
# 純截圖 montage(headless 環境無法穩定錄實機 gameplay/語音);要實機錄製見檔尾註解。
# 產物:dist-all/video/foa-cht-intro.mp4
set -euo pipefail
cd "$(dirname "$0")/.."
SHOT=screenshots
FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc
BG='#0a0e1a'; GOLD='#f0c000'; CAP='#f5d020'; WHITE='#e8e8e8'
W=1280; H=720
TMP="$(mktemp -d)"; OUT=dist-all/video; mkdir -p "$OUT"

card(){ # card <out> <title> <sub>  —— 純文字卡
  convert -size ${W}x${H} xc:"$BG" -font "$FONT" -gravity center \
    -fill "$GOLD" -pointsize 60 -annotate +0-50 "$2" \
    -fill "$WHITE" -pointsize 34 -annotate +0+60 "$3" "$1"
}
slide(){ # slide <out> <screenshot> <caption>  —— 截圖 + 底部字幕
  convert -size ${W}x${H} xc:"$BG" \
    \( "$SHOT/$2" -resize x560 \) -gravity north -geometry +0+30 -composite \
    -font "$FONT" -fill "$CAP" -gravity south -pointsize 38 -annotate +0+45 "$3" "$1"
}

echo "== 烘投影片 =="
card "$TMP/00.png" '印第安納·瓊斯:亞特蘭提斯之謎' '繁體中文化　LucasArts 1992　ScummVM'
slide "$TMP/01.png" foa_intro.png     '1992 年的神作　當年沒有官方中文版'
slide "$TMP/02.png" foa_cht_title.png '連開場標題都說起了中文　——　設計過的中文片名'
slide "$TMP/03.png" foa_gameplay.png  '原版:滿屏英文的操作介面'
slide "$TMP/04.png" foa_cht_verbs.png '同一個畫面　底部整排變中文了'
slide "$TMP/05.png" foa_cht_dialogue.png '印第的口吻:都火燒眉毛了還在碎念'
slide "$TMP/06.png" foa_cht_look.png  '連隨手一瞥的吐槽　都是中文'
card "$TMP/99.png" '他說沒有中文版。現在有了。' '字幕 4760 條 · 語音 5552 點 · Windows / Linux / macOS 三平台'

echo "== 每張轉成帶淡入淡出的片段 =="
FPS=25; i=0; LIST="$TMP/list.txt"; : > "$LIST"
for f in 00 01 02 03 04 05 06 99; do
  case $f in 00|99) D=4.5;; *) D=3.6;; esac
  FO=$(awk "BEGIN{print $D-0.5}")
  ffmpeg -y -loglevel error -loop 1 -t "$D" -i "$TMP/$f.png" \
    -vf "fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=$FO:d=0.5" \
    -c:v libx264 -pix_fmt yuv420p "$TMP/clip_$f.mp4"
  echo "file '$TMP/clip_$f.mp4'" >> "$LIST"
  i=$((i+1))
done

echo "== concat + 加無聲音軌(平台相容)=="
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
  -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.0 -crf 20 \
  -c:a aac -shortest -movflags +faststart "$OUT/foa-cht-intro.mp4"
rm -rf "$TMP"
ls -lh "$OUT/foa-cht-intro.mp4" | awk '{print "影片 ->",$9,"("$5")"}'
ffprobe -v error -show_entries format=duration:stream=width,height -of default=noprint_wrappers=1 "$OUT/foa-cht-intro.mp4" 2>/dev/null | head -4

# 想錄「實機 gameplay + 中文語音」而非截圖 montage:需有顯示+音訊輸出的環境,
# 用 `scummvm` 跑遊戲,搭 ffmpeg x11grab(畫面)+ pulse(聲音)錄製;headless dev box 不適合。
