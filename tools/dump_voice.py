#!/usr/bin/env python3
"""Extract (talkie offset, length, text-key) for every voiced line from ATLANTIS.001.

The talkie offset is encoded in the message as FOUR consecutive 0xFF 0x0A blocks
(see scumm string.cpp convertMessageToString + handleNextCharsetCode case 10):

    FF 0A b0 b1   FF 0A b2 b3   FF 0A b4 b5   FF 0A b6 b7   <text...> 00
    offset = b0|b1<<8|b2<<16|b3<<24      length = b4|b5<<8|b6<<16|b7<<24

The text key is normalised exactly like Scumm::CHT::normalizeKey / build_translation.py
so it matches the runtime lookup key. Output: TSV  offset <TAB> length <TAB> key.
"""
import sys, os, re

XOR = 0x69
FF_2ARG = {0x04, 0x06, 0x07, 0x09, 0x0A, 0x0C, 0x0E}  # for normalising the *text* part


def load(path):
    return bytes(b ^ XOR for b in open(path, "rb").read())


def normalize_key(raw):
    out, last_space, i, n = [], True, 0, len(raw)
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


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else \
        "/home/anr2/indian_jones/atlantis/game/ATLANTIS.001"
    dec = load(path)
    sou = os.path.getsize(os.path.join(os.path.dirname(path), "MONSTER.SOU"))
    seen = {}
    i, n = 0, len(dec)
    while i < n - 16:
        # four consecutive FF 0A blocks?
        if (dec[i] == 0xFF and dec[i + 1] == 0x0A and dec[i + 4] == 0xFF and dec[i + 5] == 0x0A
                and dec[i + 8] == 0xFF and dec[i + 9] == 0x0A and dec[i + 12] == 0xFF and dec[i + 13] == 0x0A):
            b = [dec[i + 2], dec[i + 3], dec[i + 6], dec[i + 7],
                 dec[i + 10], dec[i + 11], dec[i + 14], dec[i + 15]]
            off = b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)
            ln = b[4] | (b[5] << 8) | (b[6] << 16) | (b[7] << 24)
            if 0 < off < sou and 0 < ln < 4_000_000:
                # read text until 0x00
                j = i + 16
                raw = bytearray()
                while j < n and dec[j] != 0 and len(raw) < 400:
                    raw.append(dec[j]); j += 1
                key = normalize_key(bytes(raw))
                if key and re.search(r"[A-Za-z]", key):
                    seen.setdefault(off, (ln, key))
                i = j
                continue
        i += 1
    for off, (ln, key) in sorted(seen.items()):
        print(f"{off}\t{ln}\t{key}")
    print(f"# {len(seen)} voiced lines", file=sys.stderr)


if __name__ == "__main__":
    main()
