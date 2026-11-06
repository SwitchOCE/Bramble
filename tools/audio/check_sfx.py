#!/usr/bin/env python3
"""Measures assets/audio/*.wav, since no agent can hear them. Prints a table and exits 1 on a breach.

    python3 tools/audio/check_sfx.py

Also proves the generator is deterministic: it builds everything again and compares bytes.
These limits say a sound is safe, not that it sounds good.
"""

from __future__ import annotations

import sys
import tempfile
import wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import make_sfx

MAX_SECONDS = 1.5
MAX_PEAK_DB = -5.5
MIN_PEAK_DB = -20.0
MIN_RMS_DB = -42.0
MAX_DC = 0.001
MAX_CENTROID_HZ = 4000.0
# Shares of energy: above 5 kHz is what reads as harsh.
MAX_BRIGHT = 0.12
MAX_EDGE = 0.005
MAX_TOTAL_MB = 6.0
FULL_SCALE = 32768.0


def db(value: float) -> float:
    return 20.0 * np.log10(max(value, 1e-9))


def read(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as src:
        if (src.getframerate(), src.getnchannels(), src.getsampwidth()) != (make_sfx.RATE, 1, 2):
            raise ValueError(f"{path.name}: not 44.1 kHz mono 16-bit")
        return np.frombuffer(src.readframes(src.getnframes()), dtype="<i2").astype(float) / FULL_SCALE


def measure(samples: np.ndarray) -> dict[str, float]:
    peak = float(np.max(np.abs(samples)))
    power = np.abs(np.fft.rfft(samples)) ** 2
    freqs = np.fft.rfftfreq(samples.size, 1.0 / make_sfx.RATE)
    loud = np.flatnonzero(np.abs(samples) >= peak * 0.5)
    return {
        "ms": 1000.0 * samples.size / make_sfx.RATE,
        "peak": db(peak),
        "rms": db(float(np.sqrt(np.mean(samples**2)))),
        "clipped": int(np.sum(np.abs(samples) >= 0.999)),
        "dc": abs(float(np.mean(samples))),
        "centroid": float(np.sum(freqs * power) / np.sum(power)),
        "bright": float(np.sum(power[freqs > 5000.0]) / np.sum(power)),
        "rise_ms": 1000.0 * float(loud[0]) / make_sfx.RATE,
        "edge": max(abs(float(samples[0])), abs(float(samples[-1]))),
    }


def breaches(m: dict[str, float]) -> list[str]:
    tests = (
        (m["ms"] > MAX_SECONDS * 1000.0, "too long"),
        (m["peak"] > MAX_PEAK_DB, "too loud"),
        (m["peak"] < MIN_PEAK_DB, "too quiet"),
        (m["rms"] < MIN_RMS_DB, "low RMS"),
        (m["clipped"] > 0, "clipped"),
        (m["dc"] > MAX_DC, "DC offset"),
        (m["centroid"] > MAX_CENTROID_HZ, "too bright"),
        (m["bright"] > MAX_BRIGHT, "harsh top"),
        (m["edge"] > MAX_EDGE, "click at an end"),
    )
    return [words for failed, words in tests if failed]


def main() -> int:
    bad = 0
    total = 0
    print(
        f"{'sound':<15}{'ms':>6}{'peak dB':>9}{'RMS dB':>8}{'clip':>6}{'DC %':>7}"
        f"{'centroid':>10}{'>5kHz':>7}{'rise ms':>9}  problems"
    )
    for name in make_sfx.SOUNDS:
        path = make_sfx.DEFAULT_OUT / f"{name}.wav"
        if not path.is_file():
            print(f"{name:<15} MISSING")
            bad += 1
            continue
        total += path.stat().st_size
        m = measure(read(path))
        found = breaches(m)
        bad += len(found)
        print(
            f"{name:<15}{m['ms']:>6.0f}{m['peak']:>9.1f}{m['rms']:>8.1f}{m['clipped']:>6d}"
            f"{m['dc'] * 100.0:>7.3f}{m['centroid']:>10.0f}{m['bright']:>7.3f}{m['rise_ms']:>9.1f}"
            f"  {', '.join(found)}"
        )
    strays = sorted(p.stem for p in make_sfx.DEFAULT_OUT.glob("*.wav") if p.stem not in make_sfx.SOUNDS)
    if strays:
        print(f"files no sound makes: {strays}")
        bad += len(strays)
    megabytes = total / 1e6
    print(f"total {megabytes:.2f} MB (limit {MAX_TOTAL_MB})")
    if megabytes > MAX_TOTAL_MB:
        bad += 1
    with tempfile.TemporaryDirectory() as scratch:
        for name in make_sfx.SOUNDS:
            make_sfx.write(Path(scratch) / f"{name}.wav", make_sfx.build(name))
            same = (Path(scratch) / f"{name}.wav").read_bytes() == (make_sfx.DEFAULT_OUT / f"{name}.wav").read_bytes()
            if not same:
                print(f"{name}: differs from a fresh build")
                bad += 1
    print("deterministic check done" if bad == 0 else f"{bad} problem(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
