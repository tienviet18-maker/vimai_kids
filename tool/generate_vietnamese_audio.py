"""Generate real Vietnamese speech MP3s with Microsoft vi-VN neural TTS (edge-tts).
Only writes files that succeed. Does not create empty/placeholder files.
"""
from __future__ import annotations

import asyncio
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "vietnamese"

LETTERS = [
    ("A", "a", "a", "a"),
    ("Ă", "ă", "ă", "aw"),
    ("Â", "â", "â", "aa"),
    ("B", "bê", "bờ", "b"),
    ("C", "xê", "cờ", "c"),
    ("D", "dê", "dờ", "d"),
    ("Đ", "đê", "đờ", "dd"),
    ("E", "e", "e", "e"),
    ("Ê", "ê", "ê", "ee"),
    ("G", "giê", "gờ", "g"),
    ("H", "hát", "hờ", "h"),
    ("I", "i", "i", "i"),
    ("K", "ca", "cờ", "k"),
    ("L", "e-lờ", "lờ", "l"),
    ("M", "em-mờ", "mờ", "m"),
    ("N", "en-nờ", "nờ", "n"),
    ("O", "o", "o", "o"),
    ("Ô", "ô", "ô", "oo"),
    ("Ơ", "ơ", "ơ", "ow"),
    ("P", "pê", "pờ", "p"),
    ("Q", "quy", "quờ", "q"),
    ("R", "e-rờ", "rờ", "r"),
    ("S", "ét", "sờ", "s"),
    ("T", "tê", "tờ", "t"),
    ("U", "u", "u", "u"),
    ("Ư", "ư", "ư", "uw"),
    ("V", "vê", "vờ", "v"),
    ("X", "ích", "xờ", "x"),
    ("Y", "i", "i", "y"),
]

TELEX = {
    "ă": "aw", "â": "aa", "đ": "dd", "ê": "ee", "ô": "oo", "ơ": "ow", "ư": "uw",
    "á": "as", "à": "af", "ả": "ar", "ã": "ax", "ạ": "aj",
    "ắ": "aws", "ằ": "awf", "ẳ": "awr", "ẵ": "awx", "ặ": "awj",
    "ấ": "aas", "ầ": "aaf", "ẩ": "aar", "ẫ": "aax", "ậ": "aaj",
    "é": "es", "è": "ef", "ẻ": "er", "ẽ": "ex", "ẹ": "ej",
    "ế": "ees", "ề": "eef", "ể": "eer", "ễ": "eex", "ệ": "eej",
    "í": "is", "ì": "if", "ỉ": "ir", "ĩ": "ix", "ị": "ij",
    "ó": "os", "ò": "of", "ỏ": "or", "õ": "ox", "ọ": "oj",
    "ố": "oos", "ồ": "oof", "ổ": "oor", "ỗ": "oox", "ộ": "ooj",
    "ớ": "ows", "ờ": "owf", "ở": "owr", "ỡ": "owx", "ợ": "owj",
    "ú": "us", "ù": "uf", "ủ": "ur", "ũ": "ux", "ụ": "uj",
    "ứ": "uws", "ừ": "uwf", "ử": "uwr", "ữ": "uwx", "ự": "uwj",
    "ý": "ys", "ỳ": "yf", "ỷ": "yr", "ỹ": "yx", "ỵ": "yj",
}


def slug(text: str) -> str:
    chars = []
    for ch in text.strip().lower():
        if ch in TELEX:
            chars.append(TELEX[ch])
        elif ch.isalnum():
            chars.append(ch)
        elif ch in "- ":
            chars.append("_")
    value = "".join(chars).strip("_")
    return value or "clip"


def load_answers(rel: str) -> list[str]:
    path = ROOT / rel
    data = json.loads(path.read_text(encoding="utf-8"))
    out = []
    for item in data:
        text = (item.get("metadata") or {}).get("audioText") or item.get("answer") or ""
        if text:
            out.append(text)
    return out


def jobs() -> list[tuple[Path, str]]:
    items: list[tuple[Path, str]] = []
    for _letter, name, sound, letter_slug in LETTERS:
        items.append((OUT / "letters" / "name" / f"{letter_slug}.mp3", name))
        items.append((OUT / "letters" / "sound" / f"{letter_slug}.mp3", sound))
    for text in load_answers("assets/content/vietnamese/phonics.json"):
        items.append((OUT / "phonics" / f"{slug(text)}.mp3", text))
    for text in load_answers("assets/content/vietnamese/rimes.json"):
        items.append((OUT / "rimes" / f"{slug(text)}.mp3", text))
    for text in load_answers("assets/content/vietnamese/words.json"):
        items.append((OUT / "words" / f"{slug(text)}.mp3", text))
    items.append((OUT / "phrases" / "gioi_lam.mp3", "Giỏi lắm"))
    unique: dict[Path, str] = {}
    for path, text in items:
        unique[path] = text
    return list(unique.items())


def _write_if_valid(tmp: Path, path: Path, text: str) -> bool:
    if not tmp.exists() or tmp.stat().st_size < 500:
        if tmp.exists():
            tmp.unlink()
        print(f"FAIL empty {path.name} ({text})", file=sys.stderr)
        return False
    tmp.replace(path)
    print(f"OK {path.relative_to(ROOT)} <- {text}")
    return True


def _synthesize_google_vi(path: Path, text: str) -> bool:
    """Fetch real Vietnamese MPEG audio. Stdlib only; never writes silent placeholders."""
    import urllib.parse
    import urllib.request

    encoded = urllib.parse.quote(text)
    url = f"https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=vi&q={encoded}"
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Accept": "audio/mpeg",
            "Referer": "https://translate.google.com/",
        },
    )
    tmp = path.with_suffix(".tmp.mp3")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
            content_type = (response.headers.get("Content-Type") or "").lower()
        looks_mpeg = data.startswith(b"ID3") or (len(data) >= 2 and data[0] == 0xFF and data[1] & 0xE0 == 0xE0)
        if len(data) < 500 or (not looks_mpeg and "audio" not in content_type):
            print(
                f"FAIL short {path.name} ({text}) bytes={len(data)} type={content_type}",
                file=sys.stderr,
            )
            return False
        tmp.write_bytes(data)
        time.sleep(0.15)
        return _write_if_valid(tmp, path, text)
    except Exception as error:
        if tmp.exists():
            tmp.unlink()
        print(f"FAIL {path.name} ({text}): {error}", file=sys.stderr)
        return False


async def synthesize(path: Path, text: str, semaphore: asyncio.Semaphore) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.stat().st_size > 500:
        return True
    async with semaphore:
        try:
            import edge_tts
        except ImportError:
            edge_tts = None
        if edge_tts is not None:
            communicate = edge_tts.Communicate(text, "vi-VN-HoaiMyNeural", rate="-10%")
            tmp = path.with_suffix(".tmp.mp3")
            try:
                await communicate.save(str(tmp))
                return _write_if_valid(tmp, path, text)
            except Exception as error:
                if tmp.exists():
                    tmp.unlink()
                print(f"FAIL edge-tts {path.name} ({text}): {error}", file=sys.stderr)
                return False
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, _synthesize_google_vi, path, text)


def ensure_pubspec_audio_assets() -> None:
    pubspec = ROOT / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    entries = [
        "    - assets/audio/vietnamese/letters/name/",
        "    - assets/audio/vietnamese/letters/sound/",
        "    - assets/audio/vietnamese/phonics/",
        "    - assets/audio/vietnamese/rimes/",
        "    - assets/audio/vietnamese/words/",
        "    - assets/audio/vietnamese/phrases/",
    ]
    if all(entry in text for entry in entries):
        return
    marker = "    - assets/licenses/"
    if marker not in text:
        print("WARN: could not update pubspec.yaml asset list", file=sys.stderr)
        return
    addition = marker + "\n" + "\n".join(entries)
    pubspec.write_text(text.replace(marker, addition, 1), encoding="utf-8")
    print("updated pubspec.yaml Vietnamese audio asset directories")


def write_dart_registry(successful: list[Path]) -> None:
    rels = sorted(
        p.relative_to(ROOT).as_posix()
        for p in successful
        if p.exists() and p.stat().st_size > 500
    )
    lines = ",\n".join(f"  '{rel}'" for rel in rels)
    dart = (
        "/// Generated by tool/generate_vietnamese_audio.py.\n"
        "/// Contains only MP3 files that actually exist and are non-empty.\n"
        "const Set<String> kRecordedVietnameseAssets = {\n"
        f"{lines}{',' if lines else ''}\n"
        "};\n"
    )
    target = ROOT / "lib" / "core" / "audio" / "vietnamese_recorded_assets.dart"
    target.write_text(dart, encoding="utf-8")
    print(f"wrote {len(rels)} paths to {target.relative_to(ROOT)}")


async def main() -> int:
    clips = jobs()
    semaphore = asyncio.Semaphore(1)
    flags = await asyncio.gather(*[synthesize(path, text, semaphore) for path, text in clips])
    successful = [path for (path, _text), ok in zip(clips, flags) if ok]
    write_dart_registry(successful)
    if successful:
        ensure_pubspec_audio_assets()
    ok = len(successful)
    print(f"generated {ok}/{len(clips)} Vietnamese clips")
    return 0 if ok == len(clips) else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
