"""Generate every missing ViMai Kids voice clip with the existing brand voices.

Synthetic speech (Microsoft Edge neural TTS), same voices and rates as
tools/generate_audio_azure.py: vi-VN-HoaiMyNeural / ja-JP-NanamiNeural.
These clips are AI-generated, not human recordings; every file this script
writes is logged as such in tool/speech/generated_audio_log.json.

Safety rules:
  * never overwrites or deletes an existing file in assets/audio/
  * only adds new ids to assets/audio/audio_manifest.json

Inputs:
  * assets/data/vietnamese/*.json  content clips (metadata.audioId + audioText)
  * tool/speech/speech_lines.json  every on-screen line, exported by
      flutter test tool/speech/export_speech_lines_test.dart
  * math numbers 0..100 (math_num_<n>)

Usage:
  pip install edge-tts
  python tools/generate_missing_audio.py --dry-run     # list what is missing
  python tools/generate_missing_audio.py               # generate
  python tools/generate_missing_audio.py --only vi_say # one family
  python tools/generate_missing_audio.py --ca-bundle /path/ca.crt   # behind a TLS proxy
"""

import argparse
import asyncio
import datetime
import json
import os
import sys

AUDIO_DIR = os.path.join("assets", "audio")
MANIFEST_PATH = os.path.join(AUDIO_DIR, "audio_manifest.json")
LINES_PATH = os.path.join("tool", "speech", "speech_lines.json")
LOG_PATH = os.path.join("tool", "speech", "generated_audio_log.json")
VI_DIR = os.path.join("assets", "data", "vietnamese")

VOICE_VI = "vi-VN-HoaiMyNeural"
RATE_LINE = "-10%"   # instructions, words, sentences
RATE_SOUND = "-15%"  # phonics blends (sound-by-sound)


# Consonant sounds, same as the bundled v_b / v_c_ch clips (sound-first, not letter names).
ONSET_SOUND = {
    "b": "bờ", "c": "cờ", "k": "cờ", "d": "dờ", "đ": "đờ", "g": "gờ", "gh": "gờ", "h": "hờ",
    "l": "lờ", "m": "mờ", "n": "nờ", "p": "pờ", "qu": "quờ", "r": "rờ", "s": "sờ", "t": "tờ",
    "v": "vờ", "x": "xờ", "ch": "chờ", "gi": "giờ", "kh": "khờ", "nh": "nhờ", "ng": "ngờ",
    "ngh": "ngờ", "ph": "phờ", "th": "thờ", "tr": "trờ",
}


def blend_text(meta, answer):
    text = meta.get("audioText") or answer or ""
    if " - " in text:
        return text
    onset = (meta.get("onset") or "").strip().lower()
    rime = (meta.get("rime") or "").strip().lower()
    syllable = (meta.get("syllable") or answer or text).strip().lower()
    if onset in ONSET_SOUND and rime:
        return f"{ONSET_SOUND[onset]} - {rime} - {syllable}"
    return text


def exists(audio_id):
    return os.path.exists(os.path.join(AUDIO_DIR, f"{audio_id}.mp3"))


def schema_id(audio_id):
    """Mirror of AudioService.normalizeKey for content ids."""
    k = audio_id.strip().lower()
    if k.startswith("vi_phonics_"):
        return "v_blend_" + k[len("vi_phonics_"):]
    if k.startswith("vi_rime_"):
        return "v_rime_" + k[len("vi_rime_"):]
    if k.startswith("vi_word_"):
        return "v_word_" + k[len("vi_word_"):]
    if k.startswith("vi_") and not k.startswith("vi_say_"):
        return "v_" + k[3:]
    return k


def playable_candidates(audio_id):
    """Ids AudioService.playAudio would accept for this content id."""
    k = schema_id(audio_id)
    out = {audio_id, k}
    if k.startswith("v_word_"):
        out.add("vi_" + k[2:])
    if k.startswith("v_rime_"):
        rest = k[len("v_rime_"):]
        out |= {"v_blend_" + rest, "v_word_" + rest, "v_v_" + rest}
    return out


def with_period(text):
    t = text.strip()
    return t if t[-1:] in ".!?…" else t + "."


def content_jobs():
    jobs = {}
    for name in sorted(os.listdir(VI_DIR)):
        if not name.endswith(".json"):
            continue
        with open(os.path.join(VI_DIR, name), encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, list):
            continue
        for item in data:
            meta = item.get("metadata") or {}
            audio_id = meta.get("audioId")
            if not audio_id or (meta.get("audioLocale") or "vi-VN") != "vi-VN":
                continue
            if any(exists(c) for c in playable_candidates(audio_id)):
                continue
            target = schema_id(audio_id)
            if target.startswith("v_rime_"):
                # Sound-first: the rime clip says the rime itself ("an"),
                # like the existing v_v_* clips; example syllables are voiced
                # through vi_say_* lines.
                text, rate = meta.get("rime") or target[len("v_rime_"):], RATE_LINE
            elif target.startswith("v_blend_"):
                text, rate = blend_text(meta, item.get("answer")), RATE_SOUND
            else:
                text, rate = meta.get("audioText") or item.get("answer"), RATE_LINE
            if text:
                jobs.setdefault(target, {"text": with_period(text), "voice": VOICE_VI, "rate": rate, "family": target.split("_")[1]})
    return jobs


def line_jobs():
    if not os.path.exists(LINES_PATH):
        sys.exit(f"Missing {LINES_PATH}. Run: flutter test tool/speech/export_speech_lines_test.dart")
    with open(LINES_PATH, encoding="utf-8") as f:
        groups = json.load(f)
    jobs = {}
    for lines in groups.values():
        for line in lines:
            if not exists(line["id"]):
                jobs.setdefault(line["id"], {"text": with_period(line["text"]), "voice": VOICE_VI, "rate": RATE_LINE, "family": "say"})
    return jobs


def number_jobs():
    return {
        f"math_num_{n}": {"text": f"{n}.", "voice": VOICE_VI, "rate": RATE_LINE, "family": "num"}
        for n in range(0, 101)
        if not exists(f"math_num_{n}")
    }


async def synth(sem, audio_id, cfg, edge_tts):
    path = os.path.join(AUDIO_DIR, f"{audio_id}.mp3")
    async with sem:
        for attempt in range(3):
            if os.path.exists(path):
                return audio_id, False
            tmp = path + ".part"
            try:
                await edge_tts.Communicate(text=cfg["text"], voice=cfg["voice"], rate=cfg["rate"]).save(tmp)
                if os.path.getsize(tmp) < 1000:
                    raise RuntimeError("clip too small")
                os.replace(tmp, path)
                print(f"+ {audio_id}.mp3  [{cfg['text']}]")
                return audio_id, True
            except Exception as e:  # noqa: BLE001
                if os.path.exists(tmp):
                    os.remove(tmp)
                if attempt == 2:
                    print(f"! {audio_id}: {e}")
                else:
                    await asyncio.sleep(1 + attempt * 2)
    return audio_id, False


async def run(jobs, concurrency):
    import edge_tts

    sem = asyncio.Semaphore(concurrency)
    results = await asyncio.gather(*(synth(sem, k, v, edge_tts) for k, v in jobs.items()))
    return [k for k, ok in results if ok]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", choices=["content", "vi_say", "num"])
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--concurrency", type=int, default=4)
    ap.add_argument("--ca-bundle", help="CA bundle for a TLS-inspecting proxy")
    args = ap.parse_args()

    if args.ca_bundle:
        import certifi

        certifi.where = lambda: args.ca_bundle

    jobs = {}
    if args.only in (None, "content"):
        jobs.update(content_jobs())
    if args.only in (None, "num"):
        jobs.update(number_jobs())
    if args.only in (None, "vi_say"):
        jobs.update(line_jobs())
    if args.limit:
        jobs = dict(list(jobs.items())[: args.limit])

    by_family = {}
    for v in jobs.values():
        by_family[v["family"]] = by_family.get(v["family"], 0) + 1
    print(f"Missing clips: {len(jobs)} {by_family}")
    if args.dry_run or not jobs:
        for k, v in list(jobs.items())[:40]:
            print(f"  {k}: {v['text']}")
        return

    made = asyncio.run(run(jobs, args.concurrency))

    with open(MANIFEST_PATH, encoding="utf-8") as f:
        manifest = json.load(f)
    for audio_id in made:
        if not audio_id.startswith("vi_say_"):
            manifest.setdefault(audio_id, f"{audio_id}.mp3")
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    log = {}
    if os.path.exists(LOG_PATH):
        with open(LOG_PATH, encoding="utf-8") as f:
            log = json.load(f)
    stamp = datetime.date.today().isoformat()
    for audio_id in made:
        cfg = jobs[audio_id]
        log[audio_id] = {
            "text": cfg["text"],
            "voice": cfg["voice"],
            "rate": cfg["rate"],
            "source": "synthetic TTS (edge-tts neural voice), not a human recording",
            "date": stamp,
        }
    with open(LOG_PATH, "w", encoding="utf-8") as f:
        json.dump(dict(sorted(log.items())), f, ensure_ascii=False, indent=1)
    print(f"Done: {len(made)} new clips, {len(jobs) - len(made)} failed or skipped.")


if __name__ == "__main__":
    main()
