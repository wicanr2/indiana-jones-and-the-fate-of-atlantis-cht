#!/usr/bin/env python3
"""Build the Chinese-voice batch-dub manifest + voice map.

Joins extracted/voice_offsets.tsv (offset -> English key) with translations/zh.tsv
(key -> 中文). For every line that is BOTH voiced and translated, emit:
  - a manifest line  offset <TAB> voc_name <TAB> 中文文字   (for scripts/dub_batch.sh)
  - game/atlantis_voice.tab line  offset <TAB> voice/<voc_name>

Run scripts/dub_batch.sh afterwards to TTS the manifest into game/voice/*.voc.
"""
import os, re

ROOT = os.path.join(os.path.dirname(__file__), "..")
VOICE = os.path.join(ROOT, "extracted", "voice_offsets.tsv")
TSV = os.path.join(ROOT, "translations", "zh.tsv")
MANIFEST = os.path.join(ROOT, "extracted", "dub_manifest.tsv")
VTAB = os.path.join(ROOT, "game", "atlantis_voice.tab")


def norm(s):
    return re.sub(r"[\x00-\x20\x5e\x7f]+", " ", s).strip()


def main():
    # key -> 中文
    zh = {}
    for line in open(TSV, encoding="utf-8"):
        s = line.rstrip("\n")
        if not s.strip() or s.lstrip().startswith("#") or "\t" not in s:
            continue
        en, cn = s.split("\t", 1)
        zh[norm(en)] = cn.strip()

    import hashlib
    cn_voc = {}          # 中文 -> voc filename (dedup: one audio per unique line)
    offset_voc = []      # (offset, voc)
    for line in open(VOICE, encoding="utf-8"):
        if line.startswith("#") or "\t" not in line:
            continue
        off, ln, key = line.rstrip("\n").split("\t", 2)
        cn = zh.get(norm(key))
        if not cn:
            continue
        if cn not in cn_voc:
            h = hashlib.md5(cn.encode("utf-8")).hexdigest()[:10]
            cn_voc[cn] = f"c{h}.voc"
        offset_voc.append((int(off), cn_voc[cn]))

    offset_voc.sort()
    with open(MANIFEST, "w", encoding="utf-8") as mf:
        for cn, voc in sorted(cn_voc.items(), key=lambda kv: kv[1]):
            mf.write(f"-\t{voc}\t{cn}\n")          # one TTS per unique line
    with open(VTAB, "w", encoding="utf-8") as vt:
        vt.write("# offset(decimal)\tvoc(relative to game dir)\n")
        for off, voc in offset_voc:
            vt.write(f"{off}\tvoice/{voc}\n")
    print(f"unique lines to TTS: {len(cn_voc)}  ->  {len(offset_voc)} offsets mapped")
    print(f"manifest: {MANIFEST}   voice map: {VTAB}")


if __name__ == "__main__":
    main()
