"""Hash snapshot of production WAVs. Never writes under assets/audio/."""
from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROD_AUDIO = ROOT / "assets" / "audio"
SNAPSHOT = ROOT / "tool" / "audio_v3_production_snapshot.json"


def iter_production_wavs() -> list[Path]:
    return sorted(p for p in PROD_AUDIO.rglob("*.wav") if p.is_file())


def file_record(path: Path) -> dict:
    data = path.read_bytes()
    st = path.stat()
    return {
        "path": str(path.relative_to(ROOT)).replace("\\", "/"),
        "sha256": hashlib.sha256(data).hexdigest(),
        "size": st.st_size,
        "mtimeNs": st.st_mtime_ns,
    }


def take_snapshot() -> dict:
    files = [file_record(p) for p in iter_production_wavs()]
    payload = {
        "takenAt": datetime.now(timezone.utc).isoformat(),
        "root": "assets/audio",
        "count": len(files),
        "files": files,
    }
    SNAPSHOT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def verify_unchanged(before: dict) -> tuple[bool, list[str]]:
    errors: list[str] = []
    current = {row["path"]: row for row in (file_record(p) for p in iter_production_wavs())}
    previous = {row["path"]: row for row in before["files"]}
    if len(current) != before["count"]:
        errors.append(f"production WAV count {len(current)} != snapshot {before['count']}")
    for path, row in previous.items():
        now = current.get(path)
        if now is None:
            errors.append(f"deleted: {path}")
            continue
        if now["sha256"] != row["sha256"]:
            errors.append(f"hash changed: {path}")
        if now["mtimeNs"] != row["mtimeNs"]:
            errors.append(f"mtime changed: {path}")
    for path in current:
        if path not in previous:
            errors.append(f"added: {path}")
    return not errors, errors
