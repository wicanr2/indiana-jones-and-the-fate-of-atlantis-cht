#!/usr/bin/env python3
"""Compile translations/zh.tsv (UTF-8) -> atlantis_zh.tab (Big5) for the engine.

Source line:   english<TAB>繁體中文      (# comment, blank lines ignored)
Output line:   english<TAB><big5 bytes>   (read by Scumm::CHT::loadTable)

Big5 never emits 0x09/0x0A/0x0D, so tab/newline framing is byte-safe. Characters
with no Big5 mapping are reported (so the glyph font / translation can be fixed)
and skipped rather than silently corrupting the table.
"""
import sys, argparse, os, re

# SCUMM newline control code (0xFF 0x01). In the Chinese value, author line
# breaks as a literal "\n" (backslash-n); they become this in the .tab so the
# engine wraps long dialogue itself (CJK has no spaces to wrap on).
SCUMM_NL = b"\xff\x01"


def normalize_key(s):
    # Match Scumm::CHT::normalizeKey: collapse whitespace runs to one space, trim.
    return re.sub(r"\s+", " ", s).strip()


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
            # author line breaks in the Chinese as literal "\n"
            segments = zh.split("\\n")
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
