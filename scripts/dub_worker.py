#!/usr/bin/env python3
"""Runs INSIDE the docker (uv --with edge-tts). Reads /work/dub_manifest.tsv,
generates /work/voice/<voc_name>.mp3 for each line with the Indy voice (B),
concurrently, skipping any that already exist. Host side converts mp3->voc.

Manifest line: offset <TAB> voc_name(e.g. v123.voc) <TAB> 中文文字
"""
import asyncio, os, sys
import edge_tts

VOICE = os.environ.get("DUB_VOICE", "zh-TW-YunJheNeural")
RATE = os.environ.get("DUB_RATE", "-8%")
PITCH = os.environ.get("DUB_PITCH", "-12Hz")
CONC = int(os.environ.get("DUB_CONC", "6"))


async def one(sem, mp3, text):
    async with sem:
        for attempt in range(3):
            try:
                c = edge_tts.Communicate(text, VOICE, rate=RATE, pitch=PITCH)
                await c.save(mp3)
                return True
            except Exception as e:
                if attempt == 2:
                    print(f"  FAIL {mp3}: {e}", file=sys.stderr)
                    return False
                await asyncio.sleep(2)


async def main():
    rows = []
    for line in open("/work/dub_manifest.tsv", encoding="utf-8"):
        if "\t" not in line:
            continue
        off, voc, text = line.rstrip("\n").split("\t", 2)
        mp3 = f"/work/voice/{voc[:-4]}.mp3"   # v123.voc -> v123.mp3
        if os.path.exists(mp3) and os.path.getsize(mp3) > 0:
            continue
        rows.append((mp3, text))
    print(f"dub_worker: {len(rows)} to generate (voice={VOICE} {RATE} {PITCH}, conc={CONC})")
    sem = asyncio.Semaphore(CONC)
    done = 0
    tasks = [one(sem, mp3, t) for mp3, t in rows]
    for i, fut in enumerate(asyncio.as_completed(tasks), 1):
        await fut
        if i % 25 == 0:
            print(f"  {i}/{len(rows)}")
    print("dub_worker: done")


if __name__ == "__main__":
    asyncio.run(main())
