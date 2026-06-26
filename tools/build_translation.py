#!/usr/bin/env python3
"""Compile translations/zh.tsv (UTF-8) -> atlantis_zh.tab (Big5) for the engine.

Source line:   english<TAB>繁體中文      (# comment, blank lines ignored)
Output line:   english<TAB><big5 bytes>   (read by Scumm::CHT::loadTable)

Big5 never emits 0x09/0x0A/0x0D, so tab/newline framing is byte-safe. Characters
with no Big5 mapping are reported (so the glyph font / translation can be fixed)
and skipped rather than silently corrupting the table.
"""
import sys, argparse, os, re

# SCUMM newline control code (0xFF 0x01). CJK has no spaces, so we auto-insert
# these breaks: dialogue renders in the 24x24 font, ~11 CJK chars fit per line at
# the 320px game width. (CJK breaks anywhere, so word boundaries don't matter.)
SCUMM_NL = b"\xff\x01"
WRAP = int(os.environ.get("CHT_WRAP", "11"))  # max CJK chars per dialogue line


def normalize_key(s):
    # Match Scumm::CHT::normalizeKey: control bytes (<=0x20), DEL, and '^' all
    # collapse to a single space; then trim. Author keys as plain English.
    return re.sub(r"[\x00-\x20\x5e\x7f]+", " ", s).strip()


def wrap_cjk(s):
    """Yield Big5-encoded lines, auto-wrapping to ~WRAP CJK chars. Respects any
    explicit literal '\\n' the author put in. ASCII counts as half a CJK width."""
    out_lines = []
    for para in s.split("\\n"):
        cur, width = [], 0.0
        for ch in para:
            w = 1.0 if ord(ch) > 0x7F else 0.5
            if width + w > WRAP and cur:
                out_lines.append("".join(cur)); cur, width = [], 0.0
            cur.append(ch); width += w
        if cur:
            out_lines.append("".join(cur))
    return out_lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.path.join(os.path.dirname(__file__), "..", "translations", "zh.tsv"))
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "game", "atlantis_zh.tab"))
    args = ap.parse_args()

    n, bad = 0, 0
    with open(args.src, encoding="utf-8") as f, open(args.out, "wb") as out:
        for lineno, raw in enumerate(f, 1):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if "\t" not in line:
                print(f"  warn L{lineno}: no TAB, skipped: {line!r}", file=sys.stderr)
                continue
            en, zh = line.split("\t", 1)
            en, zh = normalize_key(en), zh.strip()
            if not en or not zh:
                continue
            # auto-wrap to the 24px dialogue width (respects explicit \n too)
            segments = wrap_cjk(zh)
            try:
                big5 = SCUMM_NL.join(seg.encode("big5") for seg in segments)
            except UnicodeEncodeError as e:
                ch = e.object[e.start:e.start + 1]
                print(f"  BAD L{lineno}: U+{ord(ch):04X} {ch!r} not in Big5 ({en!r})", file=sys.stderr)
                bad += 1
                continue
            out.write(en.encode("ascii", "replace") + b"\t" + big5 + b"\n")
            n += 1
    print(f"# wrote {args.out}: {n} entries" + (f", {bad} skipped (non-Big5)" if bad else ""))


if __name__ == "__main__":
    main()
