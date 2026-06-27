#!/usr/bin/env bash
# 把整個開發環境打包成可攜 dev-setup,讓「另一台電腦」解開後能重建環境 +
# 用 `claude --resume` 接續同一個對話/記憶。照 dev-setup-bundle skill 的三層必含:
#   (1) 可重建環境(repo git bundle + 腳本 + 素材)
#   (2) 工作交接(SETUP.md + previous-work.md)
#   (3) claude-session(jsonl + memory)
# 產物:dist-all/dev-setup/(資料夾)+ dist-all/dev-setup-<date>.tar.zst
# ⚠️ 私用 handoff:含完整對話記錄 + 版權素材,勿公開散布(dist-all 已 gitignore)。
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
ENC="-home-anr2-indian-jones-atlantis"               # cwd 編碼(claude session 目錄)
SESS="$HOME/.claude/projects/$ENC"
UUID="22323f24-eebd-4984-8518-f685ab31adb6"          # 最近 session(接續用)
ENGINE="${SCUMMVM:-/home/anr2/willy/scummvm-src/scummvm}"  # 目前借用的引擎 binary

OUT="dist-all/dev-setup"
rm -rf "$OUT"; mkdir -p "$OUT/repo" "$OUT/claude-session/projects/$ENC" "$OUT/game-data" "$OUT/prebuilt"

echo "== (1) repo:git bundle --all(完整歷史/分支,單檔可攜)=="
git bundle create "$OUT/repo/atlantis.gitbundle" --all

echo "== (2) 工作交接文件 =="
cp packaging/dev-setup/SETUP.md packaging/dev-setup/previous-work.md "$OUT/"
# 把當下 HEAD 戳進去,接手者一眼知道是哪個 commit 的快照
{ echo; echo "---"; echo "_bundle 產出時 HEAD:$(git rev-parse --short HEAD) ($(git log -1 --format=%s | cut -c1-60))_"; } >> "$OUT/previous-work.md"

echo "== (3) claude-session:對話 jsonl + memory(讓 claude --resume 接續)=="
cp -a "$SESS/$UUID.jsonl" "$OUT/claude-session/projects/$ENC/" 2>/dev/null || echo "  ⚠️ 找不到 $UUID.jsonl(改抓最新)"
[ -f "$OUT/claude-session/projects/$ENC/$UUID.jsonl" ] || cp -a "$SESS"/*.jsonl "$OUT/claude-session/projects/$ENC/" 2>/dev/null || true
cp -a "$SESS/memory" "$OUT/claude-session/projects/$ENC/" 2>/dev/null || true

echo "== 素材:版權遊戲 + 配音(本機自留)=="
cp -a game/. "$OUT/game-data/" 2>/dev/null || echo "  ⚠️ game/ 不在,略過"

echo "== 便利:預編 Linux 引擎(canonical 仍是從 patch 重編,見 SETUP.md)=="
[ -f "$ENGINE" ] && cp "$ENGINE" "$OUT/prebuilt/scummvm-linux-x86_64" || echo "  ⚠️ 引擎 binary 不在 $ENGINE,略過(新機從 patch 自編)"

echo "== 壓成 tar.zst =="
DATE="$(date +%Y%m%d)"
TARBALL="dist-all/dev-setup-$DATE.tar.zst"
rm -f "$TARBALL"
# 排除可重建肥肉(這裡素材是刻意要帶的,只排 pyc 之類)
tar --zstd -C dist-all -cf "$TARBALL" --exclude='__pycache__' --exclude='*.pyc' dev-setup

echo ""
du -sh "$OUT" "$TARBALL"
echo "dev-setup 資料夾 -> $OUT/"
echo "          tar.zst -> $TARBALL  (私用 handoff,含對話記錄+版權素材,勿公開散布)"
echo "新機接續:還原後 cd 專案 → claude --resume $UUID(細節見 $OUT/SETUP.md)"
