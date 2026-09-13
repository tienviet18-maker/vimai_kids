#!/usr/bin/env python3
"""Audit ViMai Kids bundled audio quality and coverage. Read-only besides writing inventory."""
from __future__ import annotations

import csv
import json
import math
import re
import struct
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "audio" / "audio_manifest.json"
OUT_JSON = ROOT / "tool" / "audio_inventory.json"
OUT_CSV = ROOT / "tool" / "audio_inventory.csv"


def read_wav(path: Path) -> dict:
    info = {
        "exists": path.exists(),
        "file_size": path.stat().st_size if path.exists() else 0,
        "format": "unknown",
        "sample_rate": 0,
        "channels": 0,
        "duration_ms": 0,
        "peak_db": None,
        "rms_db": None,
        "silence_head_ms": 0,
        "silence_tail_ms": 0,
        "clipping": False,
        "valid_riff": False,
    }
    if not path.exists() or path.stat().st_size < 44:
        return info
    with path.open("rb") as fh:
        header = fh.read(12)
        if header[:4] != b"RIFF" or header[8:12] != b"WAVE":
            return info
        info["valid_riff"] = True
        info["format"] = "wav"
        fmt = None
        data = b""
        while True:
            chunk = fh.read(8)
            if len(chunk) < 8:
                break
            cid, size = struct.unpack("<4sI", chunk)
            payload = fh.read(size + (size % 2))[:size]
            if cid == b"fmt ":
                fmt = payload
            elif cid == b"data":
                data = payload
    if not fmt or not data:
        return info
    audio_format, channels, rate, _br, _ba, width = struct.unpack("<HHIIHH", fmt[:16])
    info["sample_rate"] = rate
    info["channels"] = channels
    if audio_format != 1 or width != 16:
        info["duration_ms"] = int(1000 * len(data) / max(rate * channels * max(width // 8, 1), 1))
        return info
    n = len(data) // 2
    if n == 0:
        return info
    samples = struct.unpack("<" + "h" * n, data)
    if channels == 2:
        samples = samples[0::2]
    peak = max(abs(s) for s in samples) or 1
    rms = math.sqrt(sum(s * s for s in samples) / len(samples)) or 1
    info["duration_ms"] = int(1000 * len(samples) / rate)
    info["peak_db"] = round(20 * math.log10(peak / 32767), 2)
    info["rms_db"] = round(20 * math.log10(rms / 32767), 2)
    info["clipping"] = peak >= 32767
    thresh = max(120, int(peak * 0.02))
    start = 0
    end = len(samples) - 1
    while start < end and abs(samples[start]) < thresh:
        start += 1
    while end > start and abs(samples[end]) < thresh:
        end -= 1
    info["silence_head_ms"] = int(1000 * start / rate)
    info["silence_tail_ms"] = int(1000 * (len(samples) - 1 - end) / rate)
    return info


def collect_used_ids() -> dict[str, list[str]]:
    used: dict[str, list[str]] = defaultdict(list)
    dart_re = re.compile(r"['\"]((?:vi|ja)_[a-z0-9_]+)['\"]")
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        for match in dart_re.findall(text):
            used[match].append(rel)
    for json_path in (ROOT / "assets" / "content").rglob("*.json"):
        raw = json_path.read_text(encoding="utf-8")
        rel = str(json_path.relative_to(ROOT)).replace("\\", "/")
        for match in re.findall(r'"(?:audioId|audioNameId|audioSoundId)"\s*:\s*"([^"]+)"', raw):
            used[match].append(rel)
    return used


def status_for(rec: dict, wav: dict, used_by: list[str]) -> tuple[str, str]:
    notes: list[str] = []
    lang = rec.get("language")
    text = rec.get("text") or ""
    asset = (rec.get("asset") or "").replace("\\", "/")
    audio_id = rec.get("id") or ""

    if not wav["exists"] or not wav["valid_riff"]:
        return "MISSING", "file missing or not a WAV"
    if lang == "vi" and "/vi/" not in asset:
        return "WRONG_LANGUAGE", "Vietnamese id not under /vi/"
    if lang == "ja" and "/ja/" not in asset:
        return "WRONG_LANGUAGE", "Japanese id not under /ja/"
    if lang == "vi" and ("/ja/" in asset or "/en/" in asset):
        return "WRONG_LANGUAGE", "Vietnamese mapped to non-vi path"
    if lang == "ja" and ("/vi/" in asset or "/en/" in asset):
        return "WRONG_LANGUAGE", "Japanese mapped to non-ja path"

    if wav["clipping"]:
        notes.append("clipping")
    if wav["duration_ms"] < 80:
        notes.append("too_short")
    if wav["silence_head_ms"] > 280:
        notes.append("long_head_silence")
    if wav["silence_tail_ms"] > 450:
        notes.append("long_tail_silence")
    if wav["peak_db"] is not None and wav["peak_db"] < -18:
        notes.append("too_quiet")
    if wav["peak_db"] is not None and wav["peak_db"] > -0.2:
        notes.append("near_clip")

    syllables = max(1, len(text.replace(" ", "")))
    expected_min = 220 if audio_id.startswith("vi_phrase") else (140 if syllables <= 2 else 280)
    if lang == "vi" and wav["duration_ms"] < expected_min:
        notes.append("too_fast_or_short")
    if audio_id == "vi_phrase_gioi_lam" and wav["duration_ms"] < 700:
        notes.append("praise_too_fast")

    if notes:
        return "NEEDS_REPLACEMENT", "; ".join(notes)
    if not used_by and not audio_id.endswith("_example"):
        return "UNUSED", "not referenced from dart/content"
    return "VALID", "ok"


def main() -> int:
    records = json.loads(MANIFEST.read_text(encoding="utf-8"))
    used = collect_used_ids()
    inventory = []
    counts = defaultdict(int)
    for rec in records:
        wav = read_wav(ROOT / rec["asset"])
        used_by = sorted(set(used.get(rec["id"], [])))
        status, notes = status_for(rec, wav, used_by)
        counts[status] += 1
        counts[f"{rec['language']}_{status}"] += 1
        inventory.append(
            {
                "id": rec["id"],
                "language": rec["language"],
                "text": rec["text"],
                "asset_path": rec["asset"],
                "type": "phrase"
                if "phrase" in rec["id"]
                else ("letter" if "letter" in rec["id"] else ("kana" if rec["id"].startswith("ja_") else "content")),
                "duration_ms": wav["duration_ms"],
                "sample_rate": wav["sample_rate"],
                "channels": wav["channels"],
                "peak_db": wav["peak_db"],
                "loudness": wav["rms_db"],
                "silence_head_ms": wav["silence_head_ms"],
                "silence_tail_ms": wav["silence_tail_ms"],
                "clipping": wav["clipping"],
                "file_size": wav["file_size"],
                "format": wav["format"],
                "status": status,
                "used_by": used_by,
                "notes": notes,
            }
        )

    expected_ids = set()
    vn_dir = ROOT / "assets" / "content" / "vietnamese"
    for name in ("alphabet.json", "phonics.json", "rimes.json", "words.json", "sentences.json"):
        for item in json.loads((vn_dir / name).read_text(encoding="utf-8")):
            meta = item.get("metadata") or {}
            for key in ("audioId", "audioNameId", "audioSoundId"):
                if meta.get(key):
                    expected_ids.add(meta[key])
    expected_ids.add("vi_phrase_gioi_lam")
    kana_dir = ROOT / "assets" / "content" / "japanese" / "kana"
    for path in kana_dir.glob("*.json"):
        for item in json.loads(path.read_text(encoding="utf-8")):
            if item.get("id"):
                expected_ids.add(f"ja_{item['id']}")

    by_id = {row["id"] for row in inventory}
    missing_required = sorted(expected_ids - by_id)
    counts["REQUIRED_MISSING"] = len(missing_required)

    report = {
        "counts": dict(counts),
        "required_missing": missing_required,
        "items": inventory,
    }
    OUT_JSON.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with OUT_CSV.open("w", encoding="utf-8", newline="") as fh:
        fields = [
            "id",
            "language",
            "text",
            "asset_path",
            "type",
            "duration_ms",
            "sample_rate",
            "channels",
            "peak_db",
            "loudness",
            "status",
            "used_by",
            "notes",
        ]
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        for row in inventory:
            out = {k: row.get(k) for k in fields}
            out["used_by"] = "|".join(row["used_by"])
            writer.writerow(out)

    gioi = next((r for r in inventory if r["id"] == "vi_phrase_gioi_lam"), None)
    print("inventory", len(inventory))
    print("counts", dict(counts))
    print("required_missing", missing_required)
    if gioi:
        print("gioi_lam", gioi["duration_ms"], "ms", gioi["status"], gioi["notes"])
    short_vi = [r for r in inventory if r["language"] == "vi" and r["status"] == "NEEDS_REPLACEMENT"]
    print("vi_needs_replacement", len(short_vi))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
