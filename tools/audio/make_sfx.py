#!/usr/bin/env python3
"""Makes every sound effect in assets/audio/ from nothing but arithmetic, so no licence question arises.

    python3 tools/audio/make_sfx.py [--out DIR]

Deterministic: each sound seeds its own generator from SEED and its name, so re-running gives byte-identical
files, and adding a sound leaves the others alone. Output: 44.1 kHz, mono, 16-bit WAV.

The palette is wood knocks, plucked strings, hand claps, small bells, acorn rattles and leaf rustle. Levels
stay low (loudest peak -6 dBFS), attacks are gentle and tails are short. tools/audio/check_sfx.py measures it.
No one has listened to these yet.
"""

from __future__ import annotations

import argparse
import wave
import zlib
from collections.abc import Callable
from pathlib import Path

import numpy as np

RATE = 44100
SEED = 20261106
DEFAULT_OUT = Path(__file__).resolve().parents[2] / "assets" / "audio"
FADE_IN = 0.0015
FADE_OUT = 0.012
HIGH_PASS_HZ = 45.0
# Everything above this is removed: warm, not electronic.
TOP_HZ = 9000.0

Signal = np.ndarray
Rng = np.random.Generator


def _times(seconds: float) -> Signal:
    return np.arange(round(seconds * RATE)) / RATE


def _band(signal: Signal, low: float, high: float) -> Signal:
    """Keeps low..high Hz, with soft edges so nothing rings."""
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(signal.size, 1.0 / RATE)
    rise = np.clip(freqs / max(low, 1.0), 0.0, 1.0) ** 2 if low > 0.0 else np.ones_like(freqs)
    fall = 1.0 / (1.0 + (freqs / high) ** 4)
    return np.fft.irfft(spectrum * rise * fall, signal.size)


def _mix(seconds: float, *parts: tuple[float, Signal, float]) -> Signal:
    """Lays (start time, signal, gain) parts into one buffer."""
    out = np.zeros(round(seconds * RATE))
    for start, signal, gain in parts:
        first = round(start * RATE)
        count = min(signal.size, out.size - first)
        out[first : first + count] += signal[:count] * gain
    return out


def knock(rng: Rng, freq: float, seconds: float = 0.09, body: float = 1.0) -> Signal:
    """A wood block: a few inharmonic modes that die quickly, and a soft contact tick."""
    t = _times(seconds)
    out = np.zeros(t.size)
    for ratio, level, decay in ((1.0, 1.0, 1.0), (2.41, 0.42, 0.55), (3.89, 0.16, 0.32)):
        tau = seconds * 0.28 * decay * body
        phase = rng.uniform(0.0, 0.3)
        out += level * np.sin(2.0 * np.pi * freq * ratio * t + phase) * np.exp(-t / tau)
    tick = _band(rng.normal(0.0, 1.0, t.size), 500.0, 3000.0) * np.exp(-t / 0.004)
    return out + 0.18 * tick / max(np.max(np.abs(tick)), 1e-9)


def pluck(rng: Rng, freq: float, seconds: float = 0.35, warmth: float = 0.5) -> Signal:
    """A plucked string (Karplus-Strong): a burst of soft noise circling a damped delay line."""
    size = max(2, round(RATE / freq))
    line = _band(rng.uniform(-1.0, 1.0, size * 4), 0.0, 1400.0 + 3000.0 * (1.0 - warmth))[:size]
    line = line / max(np.max(np.abs(line)), 1e-9)
    out = np.zeros(round(seconds * RATE))
    damping = 0.992
    for i in range(out.size):
        at = i % size
        out[i] = line[at]
        line[at] = damping * 0.5 * (line[at] + line[(at + 1) % size])
    return out * np.exp(-_times(seconds) / (seconds * 0.45))


def clap(rng: Rng, seconds: float = 0.1, centre: float = 1300.0) -> Signal:
    """A hand clap: a few quick noise bursts around 1 kHz, then a short room tail."""
    t = _times(seconds)
    gate = 0.45 * np.exp(-t / (seconds * 0.3))
    for offset in (0.0, 0.009, 0.019):
        gate = gate + np.where(t >= offset, np.exp(-np.maximum(t - offset, 0.0) / 0.0035), 0.0)
    return _band(rng.normal(0.0, 1.0, t.size), centre * 0.55, centre * 1.7) * gate


def bell(rng: Rng, freq: float, seconds: float = 0.4) -> Signal:
    """A small hand bell: slightly detuned partials, the high ones dying first."""
    t = _times(seconds)
    out = np.zeros(t.size)
    for ratio, level, decay in ((1.0, 1.0, 1.0), (2.0, 0.45, 0.7), (2.74, 0.3, 0.5), (4.1, 0.1, 0.3)):
        partial = freq * ratio * (1.0 + rng.uniform(-0.002, 0.002))
        out += level * np.sin(2.0 * np.pi * partial * t) * np.exp(-t / (seconds * 0.3 * decay))
    return out


def rattle(rng: Rng, seconds: float = 0.2, hits: int = 9, centre: float = 1700.0) -> Signal:
    """Acorns in a cup: tiny knocks at uneven times, thinning out."""
    out = np.zeros(round(seconds * RATE))
    for _ in range(hits):
        start = round((rng.uniform(0.0, 1.0) ** 1.5) * seconds * 0.8 * RATE)
        tap = knock(rng, centre * rng.uniform(0.75, 1.3), 0.03) * rng.uniform(0.35, 1.0)
        count = min(tap.size, out.size - start)
        out[start : start + count] += tap[:count]
    return out


def rustle(rng: Rng, seconds: float = 0.25, low: float = 900.0, high: float = 4500.0) -> Signal:
    """Leaves: band-limited noise with a slow, uneven swell."""
    t = _times(seconds)
    flutter = np.interp(t, np.linspace(0.0, seconds, 14), rng.uniform(0.25, 1.0, 14))
    swell = np.sin(np.pi * np.clip(t / seconds, 0.0, 1.0)) ** 1.5
    return _band(rng.normal(0.0, 1.0, t.size), low, high) * flutter * swell


def squeak(rng: Rng, start: float, end: float, seconds: float, wobble: float) -> Signal:
    """A rubbery toy squeak: a rounded tone that bends, with a quick wobble."""
    t = _times(seconds)
    slide = start + (end - start) * np.sin(0.5 * np.pi * t / seconds)
    vibrato = 1.0 + wobble * np.sin(2.0 * np.pi * 26.0 * t + rng.uniform(0.0, 1.0))
    phase = 2.0 * np.pi * np.cumsum(slide * vibrato) / RATE
    tone = np.sin(phase) + 0.28 * np.sin(2.0 * phase) + 0.08 * np.sin(3.0 * phase)
    return tone * np.sin(np.pi * t / seconds) ** 0.8


# --- notes (a warm, low, folk-ish G major and its minor) ---------------------------------------------------

G3, A3, B3, D4, E4, FS4, G4, A4, B4, D5, E5, G5, BF3, BF4 = (
    196.0,
    220.0,
    246.9,
    293.7,
    329.6,
    370.0,
    392.0,
    440.0,
    493.9,
    587.3,
    659.3,
    784.0,
    233.1,
    466.2,
)


# --- the sounds: name -> (target peak in dBFS, builder) ------------------------------------------------------


def s_tap(r: Rng) -> Signal:
    return _mix(0.06, (0.0, knock(r, 980.0, 0.05), 1.0))


def s_place(r: Rng) -> Signal:
    return _mix(0.12, (0.0, knock(r, 330.0, 0.11), 1.0), (0.0, knock(r, 760.0, 0.05), 0.25))


def s_buy(r: Rng) -> Signal:
    return _mix(0.28, (0.0, knock(r, 520.0, 0.07), 0.8), (0.03, pluck(r, D4, 0.2), 0.8), (0.1, pluck(r, G4, 0.18), 0.9))


def s_sell(r: Rng) -> Signal:
    return _mix(0.3, (0.0, rattle(r, 0.16, 7), 0.5), (0.05, pluck(r, G4, 0.2), 0.8), (0.12, pluck(r, D4, 0.18), 0.8))


def s_refresh(r: Rng) -> Signal:
    return _mix(
        0.32, (0.0, rustle(r, 0.28), 0.8), (0.12, knock(r, 640.0, 0.06), 0.5), (0.2, knock(r, 820.0, 0.05), 0.4)
    )


def s_freeze(r: Rng) -> Signal:
    return _mix(
        0.4,
        (0.0, bell(r, E5, 0.24), 0.8),
        (0.07, bell(r, B4 * 1.5, 0.22), 0.6),
        (0.14, bell(r, E5 * 1.5, 0.24), 0.45),
    )


def s_tier_up(r: Rng) -> Signal:
    return _mix(
        0.72,
        (0.0, pluck(r, G3, 0.3), 0.9),
        (0.1, pluck(r, D4, 0.3), 0.9),
        (0.2, pluck(r, G4, 0.32), 0.9),
        (0.3, bell(r, B4, 0.4), 0.45),
        (0.3, pluck(r, B4, 0.38), 0.7),
    )


def s_gold(r: Rng) -> Signal:
    return _mix(0.22, (0.0, rattle(r, 0.15, 7, 1900.0), 0.8), (0.07, bell(r, D5, 0.15), 0.3))


def s_acorns_combine(r: Rng) -> Signal:
    return _mix(
        0.46,
        (0.0, rattle(r, 0.22, 12), 0.7),
        (0.2, knock(r, 450.0, 0.1), 1.0),
        (0.24, bell(r, G4, 0.22), 0.4),
    )


def s_triple(r: Rng) -> Signal:
    return _mix(
        0.95,
        (0.0, pluck(r, G3, 0.34), 0.9),
        (0.09, pluck(r, B3, 0.34), 0.9),
        (0.18, pluck(r, D4, 0.34), 0.9),
        (0.27, pluck(r, G4, 0.5), 0.9),
        (0.27, bell(r, G4 * 2.0, 0.5), 0.35),
        (0.37, bell(r, B4 * 2.0, 0.5), 0.3),
    )


def s_discover(r: Rng) -> Signal:
    return _mix(
        0.6,
        (0.0, rustle(r, 0.2, 800.0, 3500.0), 0.4),
        (0.08, pluck(r, G3, 0.46), 0.7),
        (0.13, pluck(r, D4, 0.42), 0.7),
        (0.18, pluck(r, G4, 0.4), 0.7),
        (0.23, bell(r, D5, 0.34), 0.35),
    )


def s_hero_power(r: Rng) -> Signal:
    return _mix(
        0.46,
        (0.0, knock(r, 260.0, 0.13), 0.9),
        (0.06, clap(r, 0.08), 0.35),
        (0.1, pluck(r, D4, 0.3), 0.7),
        (0.1, pluck(r, A4, 0.3), 0.6),
        (0.16, bell(r, A4, 0.28), 0.3),
    )


def s_turn_end(r: Rng) -> Signal:
    return _mix(0.34, (0.0, knock(r, 240.0, 0.13), 1.0), (0.16, knock(r, 210.0, 0.16), 1.0))


def s_attack(r: Rng) -> Signal:
    return _mix(0.18, (0.0, rustle(r, 0.17, 500.0, 2200.0), 1.0))


def s_hit_small(r: Rng) -> Signal:
    return _mix(0.1, (0.0, knock(r, 560.0, 0.08), 1.0), (0.0, clap(r, 0.06), 0.25))


def s_hit_medium(r: Rng) -> Signal:
    return _mix(0.16, (0.0, knock(r, 320.0, 0.14), 1.0), (0.0, clap(r, 0.1), 0.35))


def s_hit_big(r: Rng) -> Signal:
    return _mix(
        0.28,
        (0.0, knock(r, 150.0, 0.26, 1.2), 1.0),
        (0.0, knock(r, 380.0, 0.1), 0.4),
        (0.0, clap(r, 0.14, 1000.0), 0.4),
    )


def s_death(r: Rng) -> Signal:
    return _mix(
        0.46,
        (0.0, knock(r, 280.0, 0.1), 0.7),
        (0.04, pluck(r, D4, 0.22), 0.7),
        (0.13, pluck(r, A3, 0.26), 0.7),
        (0.08, rustle(r, 0.36, 700.0, 3000.0), 0.35),
    )


def s_summon(r: Rng) -> Signal:
    return _mix(
        0.34,
        (0.0, rustle(r, 0.2, 900.0, 3500.0), 0.4),
        (0.07, pluck(r, D4, 0.22), 0.8),
        (0.15, pluck(r, A4, 0.19), 0.8),
    )


def s_keyword(r: Rng) -> Signal:
    return _mix(0.25, (0.0, bell(r, A4 * 1.5, 0.22), 0.7), (0.0, pluck(r, E4, 0.2), 0.5))


def s_ring(r: Rng) -> Signal:
    swell = np.minimum(_times(0.6) / 0.07, 1.0)
    glow = _mix(0.6, (0.0, bell(r, G4, 0.56), 0.8), (0.07, bell(r, D5, 0.5), 0.55), (0.14, bell(r, G5, 0.44), 0.35))
    return glow * swell


def s_win(r: Rng) -> Signal:
    return _mix(
        1.25,
        (0.0, pluck(r, G3, 0.42), 0.9),
        (0.12, pluck(r, B3, 0.42), 0.9),
        (0.24, pluck(r, D4, 0.42), 0.9),
        (0.42, pluck(r, G4, 0.7), 1.0),
        (0.42, pluck(r, D4, 0.7), 0.6),
        (0.42, bell(r, G4 * 2.0, 0.7), 0.3),
        (0.42, clap(r, 0.1), 0.3),
        (0.62, clap(r, 0.1), 0.26),
        (0.82, clap(r, 0.1), 0.22),
    )


def s_loss(r: Rng) -> Signal:
    return _mix(
        1.0,
        (0.0, pluck(r, D4, 0.42), 0.9),
        (0.2, pluck(r, BF3, 0.46), 0.9),
        (0.44, pluck(r, G3, 0.56), 1.0),
        (0.44, knock(r, 130.0, 0.2, 1.2), 0.5),
    )


def s_squeak_ooze(r: Rng) -> Signal:
    return squeak(r, 1250.0, 2100.0, 0.13, 0.035)


def s_squeak_fairy(r: Rng) -> Signal:
    return _mix(0.17, (0.0, squeak(r, 1900.0, 2500.0, 0.09, 0.012), 0.6), (0.03, bell(r, BF4 * 4.0, 0.14), 0.4))


SOUNDS: dict[str, tuple[float, Callable[[Rng], Signal]]] = {
    "tap": (-15.0, s_tap),
    "place": (-11.0, s_place),
    "buy": (-9.0, s_buy),
    "sell": (-10.0, s_sell),
    "refresh": (-11.0, s_refresh),
    "freeze": (-13.0, s_freeze),
    "tier_up": (-7.0, s_tier_up),
    "gold": (-12.0, s_gold),
    "acorns_combine": (-8.0, s_acorns_combine),
    "triple": (-6.0, s_triple),
    "discover": (-9.0, s_discover),
    "hero_power": (-8.0, s_hero_power),
    "turn_end": (-8.0, s_turn_end),
    "attack": (-15.0, s_attack),
    "hit_small": (-13.0, s_hit_small),
    "hit_medium": (-9.0, s_hit_medium),
    "hit_big": (-6.0, s_hit_big),
    "death": (-9.0, s_death),
    "summon": (-11.0, s_summon),
    "keyword": (-13.0, s_keyword),
    "ring": (-13.0, s_ring),
    "win": (-6.0, s_win),
    "loss": (-8.0, s_loss),
    "squeak_ooze": (-19.0, s_squeak_ooze),
    "squeak_fairy": (-17.0, s_squeak_fairy),
}


def finish(signal: Signal, peak_db: float) -> np.ndarray:
    """Cleans a raw signal: no rumble, no DC, no clicks at either end, at the target peak."""
    out = _band(signal, HIGH_PASS_HZ, TOP_HZ)
    out = out - np.mean(out)
    fade_in = min(round(FADE_IN * RATE), out.size // 4)
    fade_out = min(round(FADE_OUT * RATE), out.size // 3)
    out[:fade_in] *= 0.5 - 0.5 * np.cos(np.pi * np.arange(fade_in) / fade_in)
    out[-fade_out:] *= 0.5 + 0.5 * np.cos(np.pi * np.arange(fade_out) / fade_out)
    out = out * 10.0 ** (peak_db / 20.0) / max(np.max(np.abs(out)), 1e-9)
    return np.round(out * 32767.0).astype("<i2")


def build(name: str) -> bytes:
    peak_db, builder = SOUNDS[name]
    rng = np.random.default_rng([SEED, zlib.crc32(name.encode())])
    return finish(builder(rng), peak_db).tobytes()


def write(path: Path, frames: bytes) -> None:
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    for name in SOUNDS:
        write(args.out / f"{name}.wav", build(name))
    print(f"wrote {len(SOUNDS)} sounds to {args.out}")


if __name__ == "__main__":
    main()
