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
    # actor -> (voice, rate, pitch). a2 = Sophia (confirmed). Default = Indy B.
    INDY = ("zh-TW-YunJheNeural", "-8%", "-12Hz")     # 馬蓋仙味
    SOPHIA = ("zh-TW-HsiaoChenNeural", "+0%", "+0Hz")  # 台灣女聲
    def voice_for(actor):
        return SOPHIA if actor == "a2" else INDY

    voc_meta = {}        # voc filename -> (中文, voice, rate, pitch)
    offset_voc = []      # (offset, voc)
    for line in open(VOICE, encoding="utf-8"):
        if line.startswith("#") or "\t" not in line:
            continue
        parts = line.rstrip("\n").split("\t", 3)
        if len(parts) < 4:
            continue
        off, ln, actor, key = parts
        cn = zh.get(norm(key))
        if not cn:
            continue
        vp = voice_for(actor)
        # Indy(default) keyed by text only (reuse existing VOCs); other voices
        # keyed by text+voice so the same line in a different voice is distinct.
        tag = cn if vp == INDY else (cn + "|" + vp[0])
        h = hashlib.md5(tag.encode("utf-8")).hexdigest()[:10]
        voc = f"c{h}.voc"
        voc_meta.setdefault(voc, (cn, vp[0], vp[1], vp[2]))
        offset_voc.append((int(off), voc))

    offset_voc.sort()
    with open(MANIFEST, "w", encoding="utf-8") as mf:
        for voc, (cn, v, r, p) in sorted(voc_meta.items()):
            mf.write(f"{voc}\t{v}\t{r}\t{p}\t{cn}\n")
    with open(VTAB, "w", encoding="utf-8") as vt:
        vt.write("# offset(decimal)\tvoc(relative to game dir)\n")
        for off, voc in offset_voc:
            vt.write(f"{off}\tvoice/{voc}\n")
    nsoph = sum(1 for _, (_, v, _, _) in voc_meta.items() if v == SOPHIA[0])
    print(f"unique audios: {len(voc_meta)} ({nsoph} Sophia female) -> {len(offset_voc)} offsets")
    print(f"manifest: {MANIFEST}   voice map: {VTAB}")


if __name__ == "__main__":
    main()
