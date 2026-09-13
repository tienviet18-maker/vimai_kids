#!/usr/bin/env python3
"""Generate offline ViMai Kids learning audio.

Vietnamese: Piper vi_VN-vais1000-medium (CC BY 4.0)
Japanese: Piper Plus Tsukuyomi-chan (corpus credit required)

Models stay in tool/.cache and are NOT packaged into the APK.
"""
from __future__ import annotations

import json
import os
import shutil
import struct
import subprocess
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "tool" / ".cache"
PIPER_DIR = CACHE / "piper"
VI_MODEL_DIR = CACHE / "piper-voices" / "vi_VN-vais1000-medium"
JA_MODEL_DIR = CACHE / "piper-plus-models"
JOBS_PATH = ROOT / "assets" / "audio" / "audio_jobs.json"
MANIFEST_PATH = ROOT / "assets" / "audio" / "audio_manifest.json"
INVENTORY_JSON = ROOT / "tool" / "audio_inventory.json"

VI_ONNX = (
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/"
    "vi/vi_VN/vais1000/medium/vi_VN-vais1000-medium.onnx"
)
VI_JSON = (
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/"
    "vi/vi_VN/vais1000/medium/vi_VN-vais1000-medium.onnx.json"
)
PIPER_ZIP = "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip"
JA_ONNX = (
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/"
    "ja/ja_JA/hi_fi_captain/medium/ja_JA-hi_fi_captain-medium.onnx"
)
JA_JSON = (
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/"
    "ja/ja_JA/hi_fi_captain/medium/ja_JA-hi_fi_captain-medium.onnx.json"
)
TSUKU_ONNX = "https://huggingface.co/ayousanz/piper-plus-tsukuyomi-chan/resolve/main/tsukuyomi-chan-6lang-fp16.onnx"
TSUKU_CFG = "https://huggingface.co/ayousanz/piper-plus-tsukuyomi-chan/resolve/main/config.json"


def log(msg: str) -> None:
    try:
        print(msg, flush=True)
    except UnicodeEncodeError:
        sys.stdout.buffer.write((msg + "\n").encode("utf-8", errors="backslashreplace"))
        sys.stdout.buffer.flush()


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and dest.stat().st_size > 1024:
        return
    log(f"Downloading {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "ViMaiKids-audio-pipeline/1.0"})
    with urllib.request.urlopen(req, timeout=180) as resp, open(dest, "wb") as out:
        shutil.copyfileobj(resp, out)


def ensure_piper() -> Path:
    if os.name == "nt":
        exe = PIPER_DIR / "piper.exe"
        if not exe.exists():
            zpath = CACHE / "piper_windows_amd64.zip"
            download(PIPER_ZIP, zpath)
            PIPER_DIR.mkdir(parents=True, exist_ok=True)
            with zipfile.ZipFile(zpath) as zf:
                zf.extractall(PIPER_DIR)
            nested = list(PIPER_DIR.rglob("piper.exe"))
            if nested and nested[0] != exe:
                for item in nested[0].parent.iterdir():
                    target = PIPER_DIR / item.name
                    if not target.exists():
                        shutil.move(str(item), str(target))
        if not exe.exists():
            raise RuntimeError("piper.exe not found after extract")
        return exe
    exe = PIPER_DIR / "piper"
    if not exe.exists():
        tgz = CACHE / "piper_linux_x86_64.tar.gz"
        download(PIPER_LINUX, tgz)
        PIPER_DIR.mkdir(parents=True, exist_ok=True)
        subprocess.check_call(["tar", "-xzf", str(tgz), "-C", str(PIPER_DIR)])
        nested = list(PIPER_DIR.rglob("piper"))
        if nested:
            return nested[0]
    if not exe.exists():
        raise RuntimeError("piper binary not found")
    return exe


def ensure_vi_model() -> Path:
    onnx = VI_MODEL_DIR / "vi_VN-vais1000-medium.onnx"
    cfg = VI_MODEL_DIR / "vi_VN-vais1000-medium.onnx.json"
    download(VI_ONNX, onnx)
    download(VI_JSON, cfg)
    if onnx.stat().st_size < 1_000_000:
        raise RuntimeError("Vietnamese Piper model is too small; download failed")
    return onnx


def run_piper(
    exe: Path,
    model: Path,
    text: str,
    out_wav: Path,
    *,
    length_scale: float = 1.0,
    sentence_silence: float = 0.2,
    head_pad_s: float = 0.08,
    tail_keep_s: float = 0.06,
    tail_silence_s: float = 0.14,
) -> None:
    out_wav.parent.mkdir(parents=True, exist_ok=True)
    tmp = out_wav.with_suffix(".raw.wav")
    cmd = [
        str(exe),
        "--model",
        str(model),
        "--output_file",
        str(tmp),
        "--length_scale",
        str(length_scale),
        "--sentence_silence",
        str(sentence_silence),
    ]
    proc = subprocess.run(
        cmd,
        input=text.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=str(exe.parent),
        timeout=60,
    )
    produced = tmp if tmp.exists() and tmp.stat().st_size >= 44 else None
    if produced is None and out_wav.exists() and out_wav.stat().st_size >= 44:
        produced = out_wav
    if produced is None:
        raise RuntimeError(
            f"Piper failed for {text!r}: {proc.stderr.decode('utf-8', errors='replace')}"
        )
    norm = {
        "head_pad_s": head_pad_s,
        "tail_keep_s": tail_keep_s,
        "tail_silence_s": tail_silence_s,
    }
    if produced != out_wav:
        normalize_wav(produced, out_wav, **norm)
        produced.unlink(missing_ok=True)
    elif out_wav.stat().st_size >= 44:
        tmp_norm = out_wav.with_suffix(".norm.wav")
        normalize_wav(out_wav, tmp_norm, **norm)
        tmp_norm.replace(out_wav)


def ensure_ja_model() -> tuple[Path, str]:
    """Classic Piper Japanese voice. Tsukuyomi-chan needs piper-plus (not this binary)."""
    onnx = JA_MODEL_DIR / "ja_JA-hi_fi_captain-medium.onnx"
    cfg = JA_MODEL_DIR / "ja_JA-hi_fi_captain-medium.onnx.json"
    download(JA_ONNX, onnx)
    download(JA_JSON, cfg)
    if onnx.stat().st_size < 1_000_000:
        raise RuntimeError("Japanese Piper model is too small; download failed")
    return onnx, "hi_fi_captain"


def run_japanese_sapi(text: str, out_wav: Path) -> None:
    """Build-time Japanese voice on Windows. Output is bundled WAV; runtime does not use SAPI."""
    import tempfile
    import time
    import uuid

    out_wav.parent.mkdir(parents=True, exist_ok=True)
    escaped = text.replace("'", "''")
    last_error: Exception | str | None = None
    for attempt in range(5):
        tmp = Path(tempfile.gettempdir()) / f"vimai_ja_{os.getpid()}_{uuid.uuid4().hex}.wav"
        script = f"""
Add-Type -AssemblyName System.Speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
$speak.Rate = -2
$ja = $speak.GetInstalledVoices() | ForEach-Object {{ $_.VoiceInfo }} | Where-Object {{ $_.Culture.Name -eq 'ja-JP' }} | Select-Object -First 1
if (-not $ja) {{ throw 'No ja-JP voice installed' }}
if ($ja.Culture.Name -notmatch '^ja') {{ throw 'Refusing non-Japanese SAPI voice' }}
$speak.SelectVoice($ja.Name)
$speak.SetOutputToWaveFile('{tmp.as_posix()}')
$speak.Speak('{escaped}')
$speak.Dispose()
Start-Sleep -Milliseconds 80
"""
        try:
            proc = subprocess.run(
                ["powershell", "-NoProfile", "-Command", script],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=40,
            )
            time.sleep(0.12)
            if proc.returncode != 0 or not tmp.exists() or tmp.stat().st_size < 64:
                err = proc.stderr.decode("utf-8", "replace") if proc.stderr else "empty wav"
                raise RuntimeError(err)
            normalize_wav(tmp, out_wav)
            return
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            time.sleep(0.35 * (attempt + 1))
        finally:
            tmp.unlink(missing_ok=True)
    raise RuntimeError(last_error)


def read_wav_pcm(path: Path) -> tuple[int, int, list[int]]:
    with path.open("rb") as fh:
        if fh.read(4) != b"RIFF":
            raise RuntimeError(f"Not a WAV file: {path}")
        fh.read(4)
        if fh.read(4) != b"WAVE":
            raise RuntimeError(f"Not a WAVE file: {path}")
        fmt = None
        data = b""
        while True:
            hdr = fh.read(8)
            if len(hdr) < 8:
                break
            chunk_id, size = struct.unpack("<4sI", hdr)
            payload = fh.read(size)
            if chunk_id == b"fmt ":
                fmt = payload
            elif chunk_id == b"data":
                data = payload
        if fmt is None or not data:
            raise RuntimeError(f"Invalid WAV: {path}")
        audio_format, channels, rate, _byte_rate, _block, width = struct.unpack("<HHIIHH", fmt[:16])
        if audio_format != 1:
            return rate, 1, []
        sampwidth = width // 8
        samples: list[int] = []
        if sampwidth == 2:
            samples = list(struct.unpack("<" + "h" * (len(data) // 2), data))
            if channels == 2:
                samples = samples[0::2]
        elif sampwidth == 1:
            samples = [((b - 128) * 256) for b in data[::channels]]
        else:
            raise RuntimeError(f"Unsupported sample width {sampwidth} in {path}")
        return rate, 1, samples


def write_wav_pcm(path: Path, rate: int, samples: list[int]) -> None:
    payload = struct.pack("<" + "h" * len(samples), *[max(-32767, min(32767, s)) for s in samples])
    with path.open("wb") as fh:
        fh.write(b"RIFF")
        fh.write(struct.pack("<I", 36 + len(payload)))
        fh.write(b"WAVEfmt ")
        fh.write(struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16))
        fh.write(b"data")
        fh.write(struct.pack("<I", len(payload)))
        fh.write(payload)


def normalize_wav(
    src: Path,
    dest: Path,
    *,
    head_pad_s: float = 0.08,
    tail_keep_s: float = 0.06,
    tail_silence_s: float = 0.14,
    peak_target: int = 22000,
) -> None:
    rate, _ch, samples = read_wav_pcm(src)
    if not samples:
        shutil.copyfile(src, dest)
        return
    peak = max(abs(s) for s in samples) or 1
    threshold = max(60, int(peak * 0.012))
    start = 0
    end = len(samples) - 1
    while start < end and abs(samples[start]) < threshold:
        start += 1
    while end > start and abs(samples[end]) < threshold:
        end -= 1
    head_pad = int(rate * head_pad_s)
    tail_keep = int(rate * tail_keep_s)
    start = max(0, start - head_pad)
    end = min(len(samples) - 1, end + tail_keep)
    clipped = samples[start : end + 1]
    if not clipped:
        clipped = samples
    peak = max(abs(s) for s in clipped) or 1
    gain = min(peak_target / peak, 3.2)
    normalized = [int(s * gain) for s in clipped]
    normalized.extend([0] * int(rate * tail_silence_s))
    write_wav_pcm(dest, rate, normalized)
    if dest.stat().st_size < 44:
        raise RuntimeError(f"Normalized WAV empty: {dest}")


def wav_duration_seconds(path: Path) -> float:
    rate, _ch, samples = read_wav_pcm(path)
    if not samples:
        size = path.stat().st_size
        return max(0.0, (size - 44) / (rate * 2 if rate else 44100))
    return len(samples) / float(rate)


def ensure_piper_plus() -> None:
    JA_MODEL_DIR.mkdir(parents=True, exist_ok=True)


def load_jobs() -> list[dict]:
    subprocess.check_call([sys.executable, str(ROOT / "tool" / "build_content_and_audio_jobs.py")])
    return load_jobs_existing()


def load_jobs_existing() -> list[dict]:
    jobs = json.loads(JOBS_PATH.read_text(encoding="utf-8"))
    ids = [j["id"] for j in jobs]
    if len(ids) != len(set(ids)):
        dup = sorted({i for i in ids if ids.count(i) > 1})
        raise SystemExit(f"Duplicate audioId: {dup}")
    return jobs


def vi_ids_needing_replacement() -> list[str]:
    if not INVENTORY_JSON.exists():
        raise SystemExit("tool/audio_inventory.json is missing. Run python tool/audit_audio_ux.py first.")
    data = json.loads(INVENTORY_JSON.read_text(encoding="utf-8"))
    ids: list[str] = []
    for item in data.get("items") or []:
        if item.get("language") != "vi":
            continue
        notes = str(item.get("notes") or "")
        status = item.get("status")
        if status == "NEEDS_REPLACEMENT" or "too_fast_or_short" in notes or "praise_too_fast" in notes:
            audio_id = item.get("id")
            if audio_id:
                ids.append(audio_id)
    return ids


def vi_synth_params(job: dict) -> dict:
    text = str(job.get("text") or "").strip()
    audio_id = str(job.get("id") or "")
    compact = text.replace(" ", "")
    if audio_id == "vi_phrase_gioi_lam":
        # Slow, clear praise for ages 3–7. Keep a natural rest, but stay under
        # audit's 450ms long_tail_silence cap and the 0.8–1.5s duration window.
        return {
            "length_scale": 1.5,
            "sentence_silence": 0.18,
            "head_pad_s": 0.08,
            "tail_keep_s": 0.08,
            "tail_silence_s": 0.28,
        }
    if "phrase" in audio_id:
        return {
            "length_scale": 1.5,
            "sentence_silence": 0.22,
            "head_pad_s": 0.08,
            "tail_keep_s": 0.08,
            "tail_silence_s": 0.28,
        }
    if audio_id in {"vi_ph", "vi_th", "vi_kh", "vi_nh", "vi_ch", "vi_tr", "vi_gh", "vi_ng", "vi_ngh"} or len(compact) <= 3:
        return {
            "length_scale": 1.12,
            "sentence_silence": 0.05,
            "head_pad_s": 0.05,
            "tail_keep_s": 0.04,
            "tail_silence_s": 0.10,
        }
    return {
        "length_scale": 1.18,
        "sentence_silence": 0.08,
        "head_pad_s": 0.06,
        "tail_keep_s": 0.05,
        "tail_silence_s": 0.12,
    }


def update_manifest_entries(updated: list[dict]) -> None:
    if not MANIFEST_PATH.exists():
        raise SystemExit("assets/audio/audio_manifest.json is missing")
    records = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    by_id = {row["id"]: row for row in records}
    for job in updated:
        by_id[job["id"]] = job
    merged = [by_id[row["id"]] for row in records]
    if not MANIFEST_PATH.parent.exists():
        MANIFEST_PATH.parent.mkdir(exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def generate_vi_jobs(jobs: list[dict], piper_exe: Path, vi_model: Path) -> list[str]:
    missing: list[str] = []
    for i, job in enumerate(jobs, start=1):
        text = str(job.get("text") or "").strip()
        dest = ROOT / job["asset"]
        if not text:
            log(f"SKIP empty text {job['id']}")
            continue
        if job.get("language") != "vi":
            raise SystemExit(f"Refusing non-Vietnamese job in VI replace mode: {job['id']}")
        params = vi_synth_params(job)
        log(f"[{i}/{len(jobs)}] {job['id']}  {text!r}  scale={params['length_scale']}")
        try:
            run_piper(piper_exe, vi_model, text, dest, **params)
            duration = wav_duration_seconds(dest)
            if duration <= 0:
                raise RuntimeError("duration is 0")
            if job["id"] == "vi_phrase_gioi_lam" and not (0.8 <= duration <= 1.5):
                log(f"WARN gioi_lam duration {duration:.3f}s outside 0.8-1.5s")
        except Exception as exc:  # noqa: BLE001
            log(f"ERROR {job['id']}: {exc}")
            if not dest.exists() or dest.stat().st_size < 800:
                missing.append(job["id"])
    return missing


def main() -> int:
    force_vi = "--force-vi" in sys.argv
    force_ja = "--force-ja" in sys.argv
    replace_invalid_vi = "--replace-invalid-vi" in sys.argv
    if replace_invalid_vi and (force_vi or force_ja):
        raise SystemExit("Use --replace-invalid-vi alone. Do not combine with --force-vi/--force-ja.")

    if replace_invalid_vi:
        replace_ids = vi_ids_needing_replacement()
        log(f"REPLACE-INVALID-VI count={len(replace_ids)} (must not be 913)")
        if len(replace_ids) == 913:
            raise SystemExit("Refusing to replace 913 files. Incremental mode would overwrite everything.")
        if len(replace_ids) > 200:
            raise SystemExit(f"Refusing {len(replace_ids)} replacements; expected a small invalid-VI set.")
        for audio_id in replace_ids:
            log(f"  - {audio_id}")
        if not replace_ids:
            log("No Vietnamese NEEDS_REPLACEMENT items.")
            return 0
        jobs = load_jobs_existing()
        by_id = {j["id"]: j for j in jobs}
        selected = []
        for audio_id in replace_ids:
            job = by_id.get(audio_id)
            if job is None:
                log(f"ERROR inventory id missing from jobs: {audio_id}")
                return 1
            if job.get("language") != "vi":
                log(f"ERROR refusing non-vi job {audio_id}")
                return 1
            selected.append(job)
        piper_exe = ensure_piper()
        vi_model = ensure_vi_model()
        missing = generate_vi_jobs(selected, piper_exe, vi_model)
        update_manifest_entries(selected)
        if missing:
            log(f"MISSING {len(missing)} assets")
            for mid in missing:
                log(f"  - {mid}")
            return 1
        log(f"Incremental VI replace complete. Regenerated={len(selected)} Missing=0")
        return 0

    jobs = load_jobs()
    vi_jobs = [j for j in jobs if j["language"] == "vi"]
    ja_jobs = [j for j in jobs if j["language"] == "ja"]
    log(f"Jobs: {len(jobs)} (vi={len(vi_jobs)} ja={len(ja_jobs)}) force_vi={force_vi} force_ja={force_ja}")

    piper_exe = ensure_piper()
    vi_model = ensure_vi_model()
    ja_model, ja_kind = ensure_ja_model()
    log(f"Japanese voice backend: {ja_kind}  model={ja_model.name}")
    if ja_kind != "tsukuyomi":
        for job in ja_jobs:
            job["source"] = "Windows ja-JP voice (build-time only) / Piper Japanese fallback"
            job["license"] = "See AUDIO_LICENSES.md"
            job["attribution"] = (
                "Japanese audio generated at build time from a ja-JP voice. "
                "Tsukuyomi-chan is preferred when piper-plus runs. "
                "Audio packaged by ViMai Kids; runtime does not use OS TTS."
            )

    ja_use_sapi = os.name == "nt"
    missing: list[str] = []
    for i, job in enumerate(jobs, start=1):
        dest = ROOT / job["asset"]
        for leftover in (dest.with_suffix(".raw.wav"), Path(str(dest) + ".raw.wav")):
            if leftover.exists() and leftover.stat().st_size < 64:
                leftover.unlink(missing_ok=True)
        skip_existing = dest.exists() and dest.stat().st_size > 800
        if skip_existing:
            try:
                skip_existing = wav_duration_seconds(dest) > 0.05
            except Exception:
                skip_existing = False
        if job["language"] == "vi" and force_vi:
            skip_existing = False
        if job["language"] == "ja" and force_ja:
            skip_existing = False
        if skip_existing:
            if i % 50 == 0:
                log(f"skip existing {i}/{len(jobs)} {job['id']}")
            continue
        log(f"[{i}/{len(jobs)}] {job['id']}  {job['text']!r}")
        try:
            if job["language"] == "vi":
                phrase = "phrase" in job["id"]
                run_piper(
                    piper_exe,
                    vi_model,
                    job["text"],
                    dest,
                    length_scale=1.45 if phrase else 1.32,
                    sentence_silence=0.45 if phrase else 0.32,
                )
            elif job["language"] == "ja":
                spoken = "あー" if job["text"].strip() in {"ー", "-"} else job["text"]
                if not ja_use_sapi:
                    try:
                        run_piper(piper_exe, ja_model, spoken, dest)
                    except Exception as piper_exc:
                        log(f"Classic Piper Japanese failed ({piper_exc}); using installed ja-JP voice at build time")
                        ja_use_sapi = True
                        run_japanese_sapi(spoken, dest)
                else:
                    run_japanese_sapi(spoken, dest)
            else:
                raise RuntimeError(f"Unsupported language {job['language']}")
            if wav_duration_seconds(dest) <= 0:
                raise RuntimeError("duration is 0")
        except Exception as exc:  # noqa: BLE001
            log(f"ERROR {job['id']}: {exc}")
            if not dest.exists() or dest.stat().st_size < 800:
                missing.append(job["id"])

    if not MANIFEST_PATH.parent.exists():
        MANIFEST_PATH.parent.mkdir(exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(jobs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    still_missing = []
    for job in jobs:
        path = ROOT / job["asset"]
        if not path.exists() or path.stat().st_size < 800:
            still_missing.append(job["id"])
    missing = sorted(set(missing + still_missing))
    if missing:
        log(f"MISSING {len(missing)} assets")
        for mid in missing[:40]:
            log(f"  - {mid}")
        return 1
    log("Audio generation complete. Missing = 0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
