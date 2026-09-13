from __future__ import annotations

import math
import struct
from pathlib import Path


def read_wav_pcm(path: Path) -> tuple[int, list[int]]:
    with path.open("rb") as fh:
        header = fh.read(12)
        if header[:4] != b"RIFF" or header[8:12] != b"WAVE":
            raise RuntimeError(f"not WAV: {path}")
        rate = 22050
        sampwidth = 2
        channels = 1
        data = b""
        while True:
            chunk = fh.read(8)
            if len(chunk) < 8:
                break
            cid, size = struct.unpack("<4sI", chunk)
            payload = fh.read(size + (size % 2))[:size]
            if cid == b"fmt " and len(payload) >= 16:
                _audio, channels, rate, _br, _ba, bits = struct.unpack_from("<HHIIHH", payload, 0)
                sampwidth = bits // 8
            elif cid == b"data":
                data = payload
        if sampwidth != 2:
            raise RuntimeError(f"need 16-bit PCM, got sampwidth={sampwidth} in {path}")
        samples = list(struct.unpack("<" + "h" * (len(data) // 2), data))
        if channels == 2:
            samples = samples[0::2]
        return rate, samples


def write_wav_pcm(path: Path, rate: int, samples: list[int]) -> None:
    clipped = [max(-32767, min(32767, int(s))) for s in samples]
    payload = struct.pack("<" + "h" * len(clipped), *clipped)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as fh:
        fh.write(b"RIFF")
        fh.write(struct.pack("<I", 36 + len(payload)))
        fh.write(b"WAVEfmt ")
        fh.write(struct.pack("<IHHIIHH", 16, 1, 1, rate, rate * 2, 2, 16))
        fh.write(b"data")
        fh.write(struct.pack("<I", len(payload)))
        fh.write(payload)


def _rms(samples: list[int]) -> float:
    if not samples:
        return 0.0
    return math.sqrt(sum(s * s for s in samples) / len(samples))


def _silence_index(samples: list[int], rate: int, from_start: bool) -> int:
    thresh = 400
    window = max(1, int(rate * 0.01))
    indices = range(0, len(samples) - window) if from_start else range(len(samples) - window, 0, -1)
    for i in indices:
        chunk = samples[i : i + window]
        if _rms(chunk) > thresh:
            return i if from_start else i + window
    return 0 if from_start else len(samples)


def postprocess_wav(
    src: Path,
    dest: Path,
    *,
    trailing_ms: int = 220,
    peak_target: int = 26000,
    max_scale: float = 4.0,
) -> None:
    """Conservative peak trim. No pitch change. Do not stretch or cartoon-shift."""
    rate, samples = read_wav_pcm(src)
    if not samples:
        raise RuntimeError(f"empty wav {src}")
    start = _silence_index(samples, rate, True)
    start = max(0, start - int(rate * 0.02))
    end = _silence_index(samples, rate, False)
    body = samples[start:end] or samples
    peak = max(abs(s) for s in body) or 1
    if peak >= 32767:
        scale = peak_target / peak
    elif peak < 8000:
        scale = min(peak_target / peak, max_scale)
    else:
        scale = 1.0
    body = [int(s * scale) for s in body]
    tail = [0] * max(0, int(rate * trailing_ms / 1000))
    write_wav_pcm(dest, rate, body + tail)


def _silence_ms(samples: list[int], rate: int, from_start: bool) -> int:
    idx = _silence_index(samples, rate, from_start)
    if from_start:
        return int(idx / rate * 1000)
    return int((len(samples) - idx) / rate * 1000)


def measure_wav(path: Path) -> dict:
    rate, samples = read_wav_pcm(path)
    peak = max((abs(s) for s in samples), default=0)
    rms = _rms(samples)
    peak_db = 20 * math.log10(peak / 32767) if peak else -99
    rms_db = 20 * math.log10(rms / 32767) if rms else -99
    clip = sum(1 for s in samples if abs(s) >= 32767)
    near_clip = sum(1 for s in samples if abs(s) >= 32000)
    dc = (sum(samples) / len(samples)) if samples else 0.0
    return {
        "durationMs": int(len(samples) / rate * 1000),
        "sampleRate": rate,
        "bitDepth": 16,
        "channels": 1,
        "format": "wav_pcm16",
        "peak": peak,
        "peakDb": round(peak_db, 2),
        "rmsDb": round(rms_db, 2),
        "clipping": clip > 0,
        "clipCount": clip,
        "nearClipping": near_clip > 8,
        "leadingSilenceMs": _silence_ms(samples, rate, True) if samples else 0,
        "trailingSilenceMs": _silence_ms(samples, rate, False) if samples else 0,
        "dcOffset": round(dc, 2),
        "empty": not samples,
    }
