#!/usr/bin/env python3
"""SCUMM v5 resource reader for Indiana Jones and the Fate of Atlantis.

Reads ATLANTIS.001 directly (XOR-0x69 encoded LECF container) and walks the
block tree LECF -> LOFF -> LFLF(room) -> {ROOM, SCRP, SOUN, COST, CHAR, ...}.
No ATLANTIS.000 index needed for *reading text* — the index only maps global
resource numbers, which string extraction does not require.

Block header (v5): 4-byte ASCII tag + 4-byte big-endian size (size includes the
8-byte header). Container blocks (LECF/LFLF/ROOM/OBCD/OBIM/SOUN) hold children.
"""
import sys, struct

XOR = 0x69
# tags whose payload is a sequence of child blocks
CONTAINER = {b"LECF", b"LFLF", b"ROOM", b"OBCD", b"OBIM", b"SOUN", b"RMIM"}
# tags whose payload contains SCUMM bytecode with embedded print strings
SCRIPT = {b"SCRP", b"LSCR", b"ENCD", b"EXCD", b"VERB"}


def load(path):
    with open(path, "rb") as f:
        return bytes(b ^ XOR for b in f.read())


def walk(buf, start=0, end=None, depth=0):
    """Yield (tag, payload_start, payload_end, depth)."""
    if end is None:
        end = len(buf)
    off = start
    while off + 8 <= end:
        tag = buf[off:off + 4]
        size = struct.unpack(">I", buf[off + 4:off + 8])[0]
        if size < 8 or off + size > end:
            break
        yield tag, off + 8, off + size, depth
        if tag in CONTAINER:
            yield from walk(buf, off + 8, off + size, depth + 1)
        off += size


def extract_scumm_string(buf, i, end):
    """Decode one SCUMM v5 string starting at i, return (text, next_index) or None.

    Strings are printable runs terminated by 0x00. 0xFF introduces an escape:
      0xFF 0x01/0x02/0x03/0x08      -> 1 control byte  (newline/keep/wait/...)
      0xFF 0x04/0x06/0x07/0x09/0x0a -> control byte + 2-byte arg (var/verb/name)
    We keep the readable text and drop control codes (recorded as markers).
    """
    out = []
    n = i
    saw_letter = False
    while n < end:
        c = buf[n]
        if c == 0x00:
            n += 1
            break
        if c == 0xFF:
            if n + 1 >= end:
                return None
            code = buf[n + 1]
            if code in (0x01,):       # newline
                out.append("\n"); n += 2
            elif code in (0x02, 0x03, 0x08):  # keepText / wait / unknown
                n += 2
            elif code in (0x04, 0x06, 0x07, 0x09, 0x0a, 0x0e):  # var/verb/name/start/end + 2-byte
                n += 4
            else:
                return None
            continue
        if 0x20 <= c <= 0x7E:
            if 0x41 <= c <= 0x7A:
                saw_letter = True
            out.append(chr(c)); n += 1
        else:
            return None
    text = "".join(out).strip()
    if not saw_letter or len(text) < 2:
        return None
    return text, n


def extract_strings(buf):
    """Walk script/object blocks, return ordered unique list of (tag, text)."""
    seen = set()
    result = []
    for tag, ps, pe, depth in walk(buf):
        if tag not in SCRIPT and tag != b"OBNA":
            continue
        if tag == b"OBNA":  # object name: a single null-terminated string, @-padded
            s = extract_scumm_string(buf, ps, pe)
            if s:
                name = s[0].rstrip("@").strip()
                if name and name not in seen:
                    seen.add(name); result.append(("OBNA", name))
            continue
        i = ps
        while i < pe:
            s = extract_scumm_string(buf, i, pe)
            if s:
                text, nxt = s
                if 0x41 <= buf[i] <= 0x7A or buf[i] == 0xFF:
                    if text not in seen:
                        seen.add(text); result.append((tag.decode(), text))
                i = nxt
            else:
                i += 1
    return result


def main():
    path = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else (
        "/home/anr2/.local/share/Steam/steamapps/common/"
        "Indiana Jones and the Fate of Atlantis/ATLANTIS/ATLANTIS.001")
    buf = load(path)
    cmd = sys.argv[2] if len(sys.argv) > 2 else "tree"
    if cmd == "tree":
        counts = {}
        for tag, ps, pe, depth in walk(buf):
            counts[tag] = counts.get(tag, 0) + 1
        for t, c in sorted(counts.items(), key=lambda x: -x[1]):
            print(f"{t.decode(errors='replace'):6} x{c}")
    elif cmd == "strings":
        items = extract_strings(buf)
        print(f"# {len(items)} unique strings", file=sys.stderr)
        for tag, text in items:
            print(f"{tag}\t{text!r}")


if __name__ == "__main__":
    main()
