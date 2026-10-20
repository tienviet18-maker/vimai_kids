"""Synthesise ViMai Kids sound effects and the games music loop.

Every sound is generated from sine/noise maths in this file (no samples, no
recordings, no third-party audio), so the output is ours to ship. Tones are
soft, rounded and never harsh: a wrong answer is a gentle "boop", not a buzzer.

Writes assets/audio/sfx_*.mp3 and assets/audio/bgm_games.mp3; never overwrites
an existing file unless --force is given.

Usage:
  python tools/generate_sfx.py            # needs numpy + ffmpeg
  python tools/generate_sfx.py --force    # re-render after tweaking
"""

import argparse
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join("assets", "audio")


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.005, decay=0.25):
    x = np.arange(n) / SR
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    return a * np.exp(-x / decay)


def bell(freq, sec=0.8, decay=0.28, bright=0.35):
    x = t(sec)
    tone = np.sin(2 * np.pi * freq * x)
    tone += bright * np.sin(2 * np.pi * freq * 2.0 * x) * np.exp(-x / (decay * 0.5))
    tone += bright * 0.4 * np.sin(2 * np.pi * freq * 3.01 * x) * np.exp(-x / (decay * 0.3))
    return tone * env(len(x), 0.003, decay)


def marimba(freq, sec=0.6, decay=0.18):
    x = t(sec)
    tone = np.sin(2 * np.pi * freq * x) + 0.25 * np.sin(2 * np.pi * freq * 4.0 * x) * np.exp(-x / 0.03)
    return tone * env(len(x), 0.002, decay)


def soft_square(freq, sec, decay=0.4):
    x = t(sec)
    tone = sum(np.sin(2 * np.pi * freq * k * x) / k for k in (1, 3, 5))
    return tone * env(len(x), 0.01, decay)


def noise(sec, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(SR * sec))


def lowpass(sig, alpha):
    out = np.empty_like(sig)
    acc = 0.0
    for i, v in enumerate(sig):
        acc += alpha * (v - acc)
        out[i] = acc
    return out


def mix(length_sec, *parts):
    """parts: (start_sec, signal, gain)."""
    out = np.zeros(int(SR * length_sec))
    for start, sig, gain in parts:
        i = int(SR * start)
        j = min(len(out), i + len(sig))
        out[i:j] += gain * sig[: j - i]
    return out


def note(name):
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semis = names[name[0]] + (int(name[-1]) - 4) * 12
    return 440.0 * 2 ** (semis / 12)


def sweep(f0, f1, sec):
    x = t(sec)
    f = np.linspace(f0, f1, len(x))
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def sfx():
    s = {}
    x = t(0.06)
    s["tap"] = sweep(1500, 900, 0.06) * env(len(x), 0.001, 0.015)
    s["pop"] = sweep(380, 950, 0.09) * env(int(SR * 0.09), 0.002, 0.03)
    s["correct"] = mix(0.9, (0, bell(note("C6"), 0.6), 0.6), (0.11, bell(note("G6"), 0.8), 0.7))
    w1 = soft_square(note("G4"), 0.22, 0.09)
    w2 = soft_square(note("E4"), 0.3, 0.12)
    s["wrong"] = mix(0.55, (0, w1, 0.35), (0.16, w2, 0.35))
    s["star"] = mix(0.9, *[(i * 0.07, bell(note(n), 0.6, 0.2), 0.45) for i, n in enumerate(["C6", "E6", "G6", "C7", "E7"])])
    nz = noise(0.45, 3)
    s["whoosh"] = lowpass(nz, 0.08) * np.sin(np.linspace(0, np.pi, len(nz))) ** 2 * 2.2
    s["flip"] = mix(0.1, (0, lowpass(noise(0.05, 5), 0.3) * env(int(SR * 0.05), 0.001, 0.012), 0.8),
                    (0.03, sweep(700, 1100, 0.04) * env(int(SR * 0.04), 0.001, 0.01), 0.4))
    s["coin"] = mix(0.45, (0, soft_square(note("B5"), 0.08, 0.05), 0.3), (0.07, soft_square(note("E6"), 0.38, 0.12), 0.3))
    fan = [("C5", 0.0), ("E5", 0.12), ("G5", 0.24), ("C6", 0.36)]
    parts = [(st, soft_square(note(n), 0.3, 0.12), 0.22) for n, st in fan]
    parts += [(0.48, soft_square(note("G5"), 0.18, 0.1), 0.22), (0.62, soft_square(note("C6"), 0.9, 0.35), 0.26)]
    parts += [(0.62, bell(note("C7"), 0.9, 0.3), 0.25), (0.62, bell(note("E6"), 0.9, 0.35), 0.2)]
    s["win"] = mix(1.6, *parts)
    xd = t(0.4)
    tom = np.sin(2 * np.pi * np.cumsum(np.linspace(150, 70, len(xd))) / SR) * env(len(xd), 0.001, 0.12)
    s["drum"] = mix(0.4, (0, tom, 0.9), (0, lowpass(noise(0.04, 7), 0.4) * env(int(SR * 0.04), 0.001, 0.01), 0.3))
    for i, n in enumerate(["C5", "D5", "E5", "G5", "A5", "C6"], start=1):
        s[f"bell_{i}"] = bell(note(n), 0.9, 0.35, 0.25)
    return s


def games_loop():
    """8 bars of 4/4 at 104 bpm: C - Am - F - G, marimba pentatonic melody, seamless."""
    beat = 60 / 104
    bars = 8
    length = bars * 4 * beat
    out = np.zeros(int(SR * length))
    chords = [["C3", "G3"], ["A2", "E3"], ["F2", "C3"], ["G2", "D3"]] * 2
    melody = [
        "E5", "G5", "A5", "G5", "C6", "A5", "G5", "E5",
        "E5", "C5", "D5", "E5", "A5", "G5", "E5", "D5",
        "C5", "D5", "E5", "G5", "A5", "C6", "A5", "G5",
        "D5", "E5", "G5", "A5", "G5", "E5", "D5", None,
    ]
    melody = melody + melody
    events = []
    for b, ch in enumerate(chords):
        for k in range(4):
            start = (b * 4 + k) * beat
            root = ch[0] if k % 2 == 0 else ch[1]
            events.append((start, marimba(note(root), 0.5, 0.2), 0.28))
    for i, n in enumerate(melody):
        if n:
            events.append((i * beat / 2, marimba(note(n), 0.5, 0.16), 0.22))
    for i in range(bars * 8):
        events.append((i * beat / 2, lowpass(noise(0.03, i), 0.5) * env(int(SR * 0.03), 0.001, 0.008), 0.05 if i % 2 else 0.08))
    for start, sig, gain in events:
        i0 = int(SR * start)
        idx = (np.arange(len(sig)) + i0) % len(out)  # wrap tails: seamless loop
        np.add.at(out, idx, gain * sig)
    return out


def write_mp3(name, sig, force, bitrate="96k", level=0.85):
    path = os.path.join(OUT, f"{name}.mp3")
    if os.path.exists(path) and not force:
        print(f"= {name}.mp3 (exists)")
        return
    peak = np.max(np.abs(sig)) or 1.0
    sig = sig / peak * level
    pcm = (sig * 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-ac", "1", "-b:a", bitrate, path], check=True)
    os.remove(wav_path)
    print(f"+ {name}.mp3")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    # A wrong answer and taps sit well under the reward sounds.
    levels = {"wrong": 0.4, "tap": 0.5, "flip": 0.55, "pop": 0.6, "whoosh": 0.6}
    for name, sig in sfx().items():
        write_mp3(f"sfx_{name}", sig, args.force, level=levels.get(name, 0.85))
    write_mp3("bgm_games", games_loop(), args.force, "112k", 0.7)


if __name__ == "__main__":
    main()
