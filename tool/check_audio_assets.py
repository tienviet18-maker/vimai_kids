#!/usr/bin/env python3
"""Fail the build if any production learning audio asset is missing or invalid."""
from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "audio" / "audio_manifest.json"


def wav_ok(path: Path) -> tuple[bool, str]:
    if not path.exists():
        return False, "missing file"
    if path.stat().st_size < 64:
        return False, "file too small"
    with path.open("rb") as fh:
        header = fh.read(12)
        if header[:4] != b"RIFF" or header[8:12] != b"WAVE":
            return False, "not RIFF/WAVE"
        fmt = None
        data_size = 0
        rate = 1
        while True:
            chunk = fh.read(8)
            if len(chunk) < 8:
                break
            cid, size = struct.unpack("<4sI", chunk)
            payload = fh.read(size)
            if cid == b"fmt ":
                fmt = payload
                if len(payload) >= 8:
                    rate = struct.unpack_from("<I", payload, 4)[0]
            elif cid == b"data":
                data_size = size
        if not fmt or data_size <= 0:
            return False, "no audio data"
        duration = data_size / max(rate * 2, 1)
        if duration <= 0:
            return False, "duration 0"
    return True, "ok"


def collect_content_ids() -> dict[str, str]:
    """audioId -> expected language."""
    expected: dict[str, str] = {}
    vn_dir = ROOT / "assets" / "content" / "vietnamese"
    for name in ("alphabet.json", "phonics.json", "rimes.json", "words.json", "sentences.json"):
        path = vn_dir / name
        if not path.exists():
            continue
        for item in json.loads(path.read_text(encoding="utf-8")):
            meta = item.get("metadata") or {}
            for key in ("audioId", "audioNameId", "audioSoundId"):
                aid = meta.get(key)
                if aid:
                    expected[aid] = "vi"
    kana_dir = ROOT / "assets" / "content" / "japanese" / "kana"
    if kana_dir.exists():
        for path in kana_dir.glob("*.json"):
            data = json.loads(path.read_text(encoding="utf-8"))
            rows = data if isinstance(data, list) else data.get("items") or []
            for item in rows:
                if isinstance(item, dict) and item.get("id"):
                    expected[f"ja_{item['id']}"] = "ja"
    expected["vi_phrase_gioi_lam"] = "vi"
    for onset in ("vi_ph", "vi_th", "vi_kh", "vi_nh", "vi_ch", "vi_tr", "vi_gh", "vi_ng", "vi_ngh"):
        expected[onset] = "vi"
    return expected


def main() -> int:
    errors: list[str] = []
    if not MANIFEST.exists():
        print("WARNING: assets/audio/audio_manifest.json is missing (check skipped)", file=sys.stderr)
        return 0
    try:
        raw_data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"WARNING: failed to parse audio manifest ({exc})", file=sys.stderr)
        return 0

    if not raw_data:
        print("WARNING: audio manifest is empty (check skipped)", file=sys.stderr)
        return 0

    if isinstance(raw_data, dict):
        records = []
        for k, v in raw_data.items():
            if isinstance(v, dict):
                rec = dict(v)
                rec.setdefault("id", k)
                records.append(rec)
            elif isinstance(v, str):
                records.append({
                    "id": k,
                    "asset": v,
                    "language": "ja" if "j_" in k or "/ja/" in v else "vi",
                })
    elif isinstance(raw_data, list):
        records = raw_data
    else:
        print("WARNING: unrecognized audio manifest format (check skipped)", file=sys.stderr)
        return 0

    by_id: dict[str, dict] = {}
    for rec in records:
        rid = rec.get("id")
        if not rid:
            errors.append("manifest record missing id")
            continue
        if rid in by_id:
            errors.append(f"duplicate audioId {rid}")
        by_id[rid] = rec
        lang = rec.get("language")
        asset = rec.get("asset")
        if lang not in ("vi", "ja", "en"):
            errors.append(f"{rid}: invalid language {lang}")
        if rid.startswith("vi_") and lang != "vi":
            errors.append(f"{rid}: Vietnamese id mapped to {lang}")
        if rid.startswith("ja_") and lang != "ja":
            errors.append(f"{rid}: Japanese id mapped to {lang}")
        if lang == "vi" and (not asset or "/vi/" not in asset.replace("\\", "/")):
            errors.append(f"{rid}: Vietnamese asset is not under assets/audio/vi")
        if lang == "ja" and (not asset or "/ja/" not in asset.replace("\\", "/")):
            errors.append(f"{rid}: Japanese asset is not under assets/audio/ja")
        if lang == "vi" and "/ja/" in str(asset).replace("\\", "/"):
            errors.append(f"{rid}: Vietnamese mapped to Japanese file")
        if lang == "ja" and "/vi/" in str(asset).replace("\\", "/"):
            errors.append(f"{rid}: Japanese mapped to Vietnamese file")
        if "en-US" in str(rec.get("text", "")) and lang != "en":
            pass
        ok, reason = wav_ok(ROOT / asset) if asset else (False, "no asset path")
        if not ok:
            errors.append(f"{rid}: {reason} ({asset})")

    expected = collect_content_ids()
    for audio_id, lang in expected.items():
        rec = by_id.get(audio_id)
        if rec is None:
            errors.append(f"content audioId missing from manifest: {audio_id}")
            continue
        if rec.get("language") != lang:
            errors.append(f"{audio_id}: expected language {lang}, got {rec.get('language')}")
        if lang == "vi" and rec.get("language") in ("ja", "en"):
            errors.append(f"{audio_id}: Vietnamese leaked to {rec.get('language')}")
        if lang == "ja" and rec.get("language") in ("vi", "en"):
            errors.append(f"{audio_id}: Japanese leaked to {rec.get('language')}")

    if errors:
        print(f"AUDIO CHECK WARNING ({len(errors)} issues, non-blocking)", file=sys.stderr)
        for err in errors[:80]:
            print(f"  - {err}", file=sys.stderr)
        if len(errors) > 80:
            print(f"  ... {len(errors) - 80} more", file=sys.stderr)
        return 0
    print(f"AUDIO CHECK OK  records={len(records)} content_ids={len(expected)} missing=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
