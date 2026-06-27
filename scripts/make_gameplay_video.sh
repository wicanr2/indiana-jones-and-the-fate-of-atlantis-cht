#!/usr/bin/env bash
# 合成最終 YouTube 介紹片:真實 LucasArts logo 實機動畫 + 設計標題卡 +
# 中文截圖(Ken Burns 緩動 + 中文字幕)+ 結尾卡,全程鋪「遊戲真實 iMUSE 音樂」。
# 依賴:先跑 capture_gameplay_video.sh(產 /tmp/foa_cap.mp4 實機畫面 + /tmp/foa_cap.wav 遊戲音樂)。
# 產物:dist-all/video/foa-cht-intro-music.mp4
set -u
cd "$(dirname "$0")/.."
SHOT=screenshots; FONT=/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc
BG='#0a0e1a'; GOLD='#f0c000'; CAP='#f5d020'; WHITE='#e8e8e8'
W=1280; H=720; FPS=25
CAP_V=/tmp/foa_cap.mp4; CAP_A=/tmp/foa_cap.wav
TMP="$(mktemp -d)"; OUT=dist-all/video; mkdir -p "$OUT"
[ -f "$CAP_V" ] || { echo "缺 $CAP_V,先跑 scripts/capture_gameplay_video.sh"; exit 1; }

card(){ convert -size ${W}x${H} xc:"$BG" -font "$FONT" -gravity center \
  -fill "$GOLD" -pointsize 60 -annotate +0-50 "$2" \
  -fill "$WHITE" -pointsize 34 -annotate +0+60 "$3" "$1"; }
slide(){ convert -size ${W}x${H} xc:"$BG" \
  \( "$SHOT/$2" -resize x560 \) -gravity north -geometry +0+30 -composite \
  -font "$FONT" -fill "$CAP" -gravity south -pointsize 38 -annotate +0+45 "$3" "$1"; }

# 靜態圖 → 淡入淡出片段(zoompan 對 looped 輸入會爆量,改用穩定的靜態+fade)
kenburns(){ # <png> <out> <dur>
  local FO; FO=$(awk "BEGIN{print $3-0.5}")
  ffmpeg -y -loglevel error -loop 1 -t "$3" -i "$1" \
    -vf "fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=$FO:d=0.5" \
    -c:v libx264 -pix_fmt yuv420p "$2"; }

echo "== 烘卡片/投影片 =="
card  "$TMP/00.png" '印第安納·瓊斯:亞特蘭提斯之謎' '繁體中文化　LucasArts 1992　ScummVM'
slide "$TMP/02.png" foa_cht_title.png    '連開場標題都說起了中文　——　設計過的中文片名'
slide "$TMP/03.png" foa_gameplay.png     '原版:滿屏英文的操作介面'
slide "$TMP/04.png" foa_cht_verbs.png    '同一個畫面　底部整排變中文了'
slide "$TMP/05.png" foa_cht_dialogue.png '印第的口吻:都火燒眉毛了還在碎念'
slide "$TMP/06.png" foa_cht_look.png     '連隨手一瞥的吐槽　都是中文'
card  "$TMP/99.png" '他說沒有中文版。現在有了。' '字幕 4760 條 · 語音 5552 點 · Windows / Linux / macOS 三平台'

echo "== 真實 logo 實機片段(填滿、有動態)=="
ffmpeg -y -loglevel error -ss 1 -t 6 -i "$CAP_V" \
  -vf "scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:-1:-1:color=black,fps=$FPS,format=yuv420p,fade=t=in:st=0:d=0.6,fade=t=out:st=5.4:d=0.6" \
  -an "$TMP/seg_logo.mp4"

echo "== 卡片/投影片轉片段 =="
LIST="$TMP/list.txt"; : > "$LIST"
echo "file '$TMP/seg_logo.mp4'" >> "$LIST"
for f in 00 02 03 04 05 06 99; do
  case $f in 00|99) D=4.0;; *) D=3.6;; esac
  kenburns "$TMP/$f.png" "$TMP/seg_$f.mp4" "$D"
  echo "file '$TMP/seg_$f.mp4'" >> "$LIST"
done

echo "== concat 影像 =="
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" -c:v libx264 -pix_fmt yuv420p -crf 20 "$TMP/silent.mp4"
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4")

echo "== 鋪遊戲音樂(取前 ${DUR}s,淡入淡出)=="
FO=$(awk "BEGIN{print $DUR-3}")
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -i "$CAP_A" \
  -filter_complex "[1:a]atrim=0:$DUR,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3,volume=0.9[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart \
  "$OUT/foa-cht-intro-music.mp4"
rm -rf "$TMP"
ls -lh "$OUT/foa-cht-intro-music.mp4" | awk '{print "影片 ->",$9,"("$5")"}'
ffprobe -v error -show_entries format=duration:stream=codec_type -of default=noprint_wrappers=1 "$OUT/foa-cht-intro-music.mp4" 2>/dev/null | grep -E 'duration|codec_type'
