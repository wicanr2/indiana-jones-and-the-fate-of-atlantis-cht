#!/usr/bin/env python3
"""Dump normalized translation keys straight from ATLANTIS.001 — no game run.

normalizeKey() here is byte-for-byte the same transform as
engines/scumm/cjk_cht.cpp and tools/build_translation.py, so a key dumped here
matches what the engine looks up at runtime (verified against the NY narration).
Lets us harvest the whole script offline and translate in batches.

Usage: dump_keys.py [ATLANTIS.001] [--min N] [--max N]
"""
import sys, struct, re

XOR = 0x69
CONTAINER = {b"LECF", b"LFLF", b"ROOM", b"OBCD", b"OBIM", b"SOUN", b"RMIM"}
SCRIPT = {b"SCRP", b"LSCR", b"ENCD", b"EXCD", b"VERB"}
# 0xFF control codes that carry two argument bytes (var/verb/name/colour refs)
FF_2ARG = {0x04, 0x06, 0x07, 0x09, 0x0A, 0x0C, 0x0E}


def load(path):
    with open(path, "rb") as f:
        return bytes(b ^ XOR for b in f.read())


def walk(buf, start=0, end=None):
    if end is None:
        end = len(buf)
    off = start
    while off + 8 <= end:
        tag = buf[off:off + 4]
        size = struct.unpack(">I", buf[off + 4:off + 8])[0]
        if size < 8 or off + size > end:
            break
        yield tag, off + 8, off + size
        if tag in CONTAINER:
            yield from walk(buf, off + 8, off + size)
        off += size


def normalize_key(raw):
    """Mirror Scumm::CHT::normalizeKey on a raw byte string (no NUL)."""
    out = []
    last_space = True
    i = 0
    n = len(raw)
    while i < n:
        c = raw[i]
        if c == 0xFF:
            code = raw[i + 1] if i + 1 < n else 0
            i += 4 if code in FF_2ARG else 2
            if not last_space:
                out.append(" "); last_space = True
            continue
        if c <= 0x20 or c == 0x7F or c == 0x5E:
            if not last_space:
                out.append(" "); last_space = True
            i += 1
            continue
        out.append(chr(c)); last_space = False; i += 1
    return "".join(out).strip()


def extract_raw_strings(buf, ps, pe):
    """Yield raw byte strings (NUL-terminated, with 0xFF escapes) in a script block."""
    i = ps
    while i < pe:
        # a string starts at a printable letter or an 0xFF escape
        if (0x41 <= buf[i] <= 0x7A) or buf[i] == 0xFF:
            j = i
            saw = False
            ok = True
            while j < pe and buf[j] != 0x00:
                c = buf[j]
                if c == 0xFF:
                    code = buf[j + 1] if j + 1 < pe else 0
                    j += 4 if code in FF_2ARG else 2
                    continue
                if 0x20 <= c <= 0x7E or c <= 0x20 or c == 0x7F:
                    if 0x41 <= c <= 0x7A:
                        saw = True
                    j += 1
                else:
                    ok = False
                    break
            if ok and saw and j > i and (j - i) >= 2:
                yield buf[i:j]
                i = j + 1
                continue
        i += 1


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else (
        "/home/anr2/indian_jones/atlantis/game/ATLANTIS.001")
    mn = 1
    mx = 9999
    for a in sys.argv[1:]:
        if a.startswith("--min"):
            mn = int(a.split("=")[1]) if "=" in a else 1
        if a.startswith("--max"):
            mx = int(a.split("=")[1]) if "=" in a else 9999
    buf = load(path)
    seen = {}
    for tag, ps, pe in walk(buf):
        if tag not in SCRIPT:
            continue
        for raw in extract_raw_strings(buf, ps, pe):
            key = normalize_key(raw)
            if not key or len(key) < mn or len(key) > mx:
                continue
            # keep only sentence-/word-like keys (a letter present)
            if not re.search(r"[A-Za-z]", key):
                continue
            seen[key] = seen.get(key, 0) + 1
    # print most-frequent first (common responses bubble up)
    for key, cnt in sorted(seen.items(), key=lambda kv: (-kv[1], kv[0])):
        print(f"{cnt}\t{key}")


if __name__ == "__main__":
    main()
