#!/usr/bin/env python3
"""
Deterministic combat attack-hit generator for Bramble.

Produces 15 game-ready SFX in assets/audio/sfx/:
  - hit_light_01.wav  .. hit_light_05.wav   (Ladder 3 pocket: snappy, chunky light hit)
  - hit_medium_01.wav .. hit_medium_05.wav  (Ladder 4 anchor: owner's favorite chunky hit)
  - hit_heavy_01.wav  .. hit_heavy_05.wav   (Ladder 5 pocket: heavy slam + fierce crack)

With --audition, also writes listening reels to .copies/audition/ (gitignored):
  - hits_showcase.wav : 3 light -> 3 medium -> 3 heavy takes in sequence
  - fight_10s.wav     : 10.0 s battle test built from the 15 generated assets at real
                        Bramble pacing (median 0.55 s steps, 1 crisp impact per 1v1
                        clash, plus one 3-hit cleave cascade)

Format & loudness standard (single method for all Bramble SFX):
  - 48 kHz, 16-bit mono PCM WAV, zero digital clips
  - Game-ready onset at ~1.5-2.5 ms (peak ~2.6-3.5 ms, lands on contact frame)
  - Loudness calibrated by ungated K-weighted Max Momentary Loudness (M400_max,
    ITU-R BS.1770 400 ms sliding window via pyloudnorm K-weighting filter):
      hit_light  : -17.0 LUFS (M400_max)
      hit_medium : -16.0 LUFS (M400_max, matching Round 2 ladder-4.wav at -15.89)
      hit_heavy  : -15.0 LUFS (M400_max)
  - True Peak strictly <= -1.2 dBTP (4x oversampled + verified with ffmpeg loudnorm).

Dependencies: /data/sound-tools/venv/bin/python (numpy, scipy, soundfile, pyloudnorm)
and ffmpeg. Source samples are CC0-only packs in /data/sound-library/ (see
assets/audio/sfx/SOURCES.md). No audio from other games is ever loaded or copied.
"""

import argparse
import math
import os
import re
import subprocess
import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy.signal import butter, resample_poly, sosfilt

SR = 48000
HIT_TIME = 0.0025  # 2.5 ms lead-in so impact lands immediately on game trigger
LIB = "/data/sound-library"

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "audio", "sfx")
AUDITION_DIR = os.path.join(REPO_ROOT, ".copies", "audition")

_SAMPLE_CACHE = {}
_K_METER = pyln.Meter(SR)


# ---------------------------------------------------------------------------
# Sample loading, alignment, filtering, and physical impact DSP
# ---------------------------------------------------------------------------

def load_cc0(rel_path):
    """Load a CC0 audio sample from /data/sound-library/, resample to 48 kHz mono float64."""
    if rel_path in _SAMPLE_CACHE:
        return _SAMPLE_CACHE[rel_path].copy()
    full = os.path.join(LIB, rel_path)
    x, sr = sf.read(full, dtype="float64")
    if x.ndim > 1:
        x = np.mean(x, axis=1)
    if sr != SR:
        g = math.gcd(SR, sr)
        x = resample_poly(x, SR // g, sr // g)
    x = x - np.mean(x)
    x = x / (np.max(np.abs(x)) + 1e-12)
    _SAMPLE_CACHE[rel_path] = x
    return x.copy()


def pitch_shift_resample(x, semitones):
    if abs(semitones) < 1e-4:
        return x.copy()
    ratio = 2.0 ** (semitones / 12.0)
    new_len = max(16, int(round(len(x) / ratio)))
    idx = np.linspace(0.0, len(x) - 1.0, new_len)
    return np.interp(idx, np.arange(len(x)), x).astype(np.float64)


def soft_clip(x, ceil=0.85):
    """Smooth soft-clipper so narrow spikes never steal mix headroom."""
    ax = np.abs(x)
    knee = 0.65 * ceil
    excess = np.maximum(0.0, ax - knee)
    return np.sign(x) * np.where(
        ax <= knee,
        ax,
        knee + (ceil - knee) * np.tanh(excess / max(ceil - knee, 1e-6)),
    )


def rms_norm_window(x, hit_s=HIT_TIME, win_ms=65.0):
    """Normalize layer by active impact RMS starting at hit_s for predictable blending."""
    s0 = max(0, int((hit_s - 0.0015) * SR))
    s1 = min(len(x), s0 + int(win_ms * 1e-3 * SR))
    rms = math.sqrt(float(np.mean(x[s0:s1] ** 2)) + 1e-12)
    return x / rms * 0.25


def align_sample(x, out_len, hit_s=HIT_TIME, pre_ms=1.0, gate_ms=None, fade_out_ms=25.0):
    """Align the sample's sharp onset (backward scan from peak to 15% peak) to hit_s."""
    pk_idx = int(np.argmax(np.abs(x)))
    pk_val = float(np.abs(x[pk_idx])) + 1e-12
    onset = pk_idx
    search_start = max(0, pk_idx - int(0.035 * SR))
    sub = np.abs(x[search_start:pk_idx + 1])
    hits = np.where(sub >= 0.15 * pk_val)[0]
    if len(hits) > 0:
        onset = search_start + int(hits[0])

    pre_smp = int(pre_ms * 1e-3 * SR)
    src_start = max(0, onset - pre_smp)
    trimmed = x[src_start:].copy()

    r = min(len(trimmed), int(0.0004 * SR))
    if r > 1:
        trimmed[:r] *= np.linspace(0.0, 1.0, r)

    if gate_ms is not None:
        t_ms = np.arange(len(trimmed), dtype=np.float64) / SR * 1000.0
        hold = pre_ms + 3.0
        env = np.where(
            t_ms <= hold,
            1.0,
            np.exp(-(np.maximum(0.0, t_ms - hold) / max(gate_ms, 1.0)) ** 1.35),
        )
        trimmed *= env

    out = np.zeros(out_len, dtype=np.float64)
    dst_start = max(0, int(round(hit_s * SR)) - (onset - src_start))
    avail = min(len(trimmed), out_len - dst_start)
    if avail > 0:
        out[dst_start:dst_start + avail] = trimmed[:avail]

    fo = min(out_len, int(fade_out_ms * 1e-3 * SR))
    if fo > 1:
        out[-fo:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
    return out


def hp_filter(x, fc, order=2):
    return sosfilt(butter(order, fc, btype="highpass", fs=SR, output="sos"), x)


def lp_filter(x, fc, order=2):
    return sosfilt(butter(order, fc, btype="lowpass", fs=SR, output="sos"), x)


def bp_filter(x, fl, fh, order=2):
    return sosfilt(butter(order, [fl, fh], btype="bandpass", fs=SR, output="sos"), x)


def biquad_eq(x, kind, fc, q=1.0, gain_db=0.0):
    if abs(gain_db) < 1e-3:
        return x
    w0 = 2.0 * math.pi * max(15.0, min(fc, SR * 0.46)) / SR
    cw, sw = math.cos(w0), math.sin(w0)
    alpha = sw / (2.0 * max(q, 0.1))
    A = 10.0 ** (gain_db / 40.0)
    if kind == "peak":
        b0, b1, b2 = 1 + alpha * A, -2 * cw, 1 - alpha * A
        a0, a1, a2 = 1 + alpha / A, -2 * cw, 1 - alpha / A
    elif kind == "lowshelf":
        sqA = math.sqrt(A)
        b0 = A * ((A + 1) - (A - 1) * cw + 2 * sqA * alpha)
        b1 = 2 * A * ((A - 1) - (A + 1) * cw)
        b2 = A * ((A + 1) - (A - 1) * cw - 2 * sqA * alpha)
        a0 = (A + 1) + (A - 1) * cw + 2 * sqA * alpha
        a1 = -2 * ((A - 1) + (A + 1) * cw)
        a2 = (A + 1) + (A - 1) * cw - 2 * sqA * alpha
    elif kind == "highshelf":
        sqA = math.sqrt(A)
        b0 = A * ((A + 1) + (A - 1) * cw + 2 * sqA * alpha)
        b1 = -2 * A * ((A - 1) + (A + 1) * cw)
        b2 = A * ((A + 1) - (A - 1) * cw - 2 * sqA * alpha)
        a0 = (A + 1) - (A - 1) * cw + 2 * sqA * alpha
        a1 = 2 * ((A - 1) - (A + 1) * cw)
        a2 = (A + 1) - (A - 1) * cw - 2 * sqA * alpha
    else:
        raise ValueError(kind)
    sos = np.array([[b0 / a0, b1 / a0, b2 / a0, 1.0, a1 / a0, a2 / a0]])
    return sosfilt(sos, x)


def instant_sub_thump(n, hit_s, f_start, f_end, pitch_tau_ms, amp_tau_ms, attack_ms=0.5, drive=1.6):
    """Instant-attack physical chest weight (46-150 Hz), zero swell."""
    t = np.arange(n, dtype=np.float64) / SR - hit_s
    y = np.zeros(n, dtype=np.float64)
    m = t >= 0.0
    tm = t[m]
    pt = pitch_tau_ms * 1e-3
    at = amp_tau_ms * 1e-3
    phase = 2.0 * math.pi * (f_end * tm + (f_start - f_end) * pt * (1.0 - np.exp(-tm / pt)))
    raw = np.sin(phase) + 0.30 * np.sin(2.0 * phase + 0.35) * np.exp(-tm / (at * 0.55))
    atk = np.minimum(1.0, tm / max(attack_ms * 1e-3, 1e-5))
    atk = np.sin(0.5 * np.pi * atk)
    env = atk * np.exp(-np.power(tm / at, 1.25))
    sig = raw * env
    sig = np.tanh(drive * sig) / math.tanh(drive)
    y[m] = sig
    return y


def instant_snap_crack(n, hit_s, rng, fl=1800.0, fh=9000.0, dec_ms=6.0, amp=0.35):
    """Sub-millisecond high-frequency contact crack, soft-clipped so it never spikes over the body."""
    w = bp_filter(rng.standard_normal(n), fl, fh, order=3)
    w /= (np.std(w) + 1e-12)
    t = np.arange(n, dtype=np.float64) / SR - hit_s
    env = np.zeros(n, dtype=np.float64)
    m = t >= 0.0
    tm = t[m]
    atk = np.minimum(1.0, tm / 0.0003)
    env[m] = atk * np.exp(-np.power(tm / (dec_ms * 1e-3), 1.3))
    out = soft_clip(w * env, ceil=1.2)
    return (out / (np.max(np.abs(out)) + 1e-12)) * amp


def transient_punch_shaper(x, hit_s, boost_db=3.5, window_ms=6.0):
    if abs(boost_db) < 0.05:
        return x
    t = (np.arange(len(x), dtype=np.float64) / SR - hit_s) * 1000.0
    g_pk = 10.0 ** (boost_db / 20.0)
    w = np.where(t < -0.6, 0.0, np.where(t < 0.0, (t + 0.6) / 0.6, np.exp(-np.maximum(0.0, t) / window_ms)))
    return x * (1.0 + (g_pk - 1.0) * w)


def punch_master(x, hp_hz=36.0, drive=1.65, scoop_db=-4.5, scoop_hz=330.0, low_db=0.0, hi_db=0.0, fade_out_ms=22.0):
    x = x - np.mean(x)
    x = hp_filter(x, hp_hz, order=2)
    if abs(scoop_db) > 0.1:
        x = biquad_eq(x, "peak", scoop_hz, q=1.05, gain_db=scoop_db)
    if abs(low_db) > 0.1:
        x = biquad_eq(x, "lowshelf", 135.0, q=0.75, gain_db=low_db)
    if abs(hi_db) > 0.1:
        x = biquad_eq(x, "highshelf", 2200.0, q=0.75, gain_db=hi_db)
    x = x / (np.max(np.abs(x)) + 1e-12) * 0.92
    x = np.tanh(drive * (x + 0.05 * x * x)) / math.tanh(drive)
    x = x - np.mean(x)
    x = hp_filter(x, max(30.0, hp_hz * 0.9), order=2)
    # Very short 0.4 ms start fade so 2.5 ms hit onset stays untouched
    fi = int(0.0004 * SR)
    fo = int(fade_out_ms * 1e-3 * SR)
    x[:fi] *= 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, fi))
    x[-fo:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
    return x


# ---------------------------------------------------------------------------
# Three-weight Combat Hit Set (Ladder 3 / Ladder 4 / Ladder 5)
# ---------------------------------------------------------------------------

WEIGHT_CFG = {
    "light": dict(
        dur_s=0.36, target_m400=-17.0,
        chunk=0.58, atk=0.80, pre_ms=1.1,
        sub_f=(145.0, 68.0), sub_tau=48.0,
        w_sub=1.02, w_punch=0.98, w_book=0.82, w_wood=0.65, w_crack=0.46, w_snap=0.28,
        t_boost=3.4, drive=1.80, scoop=-4.8, low_db=3.6, hi_db=2.2, hp=40.0, base_pitch=-0.4,
        takes=[
            ("kenney-impact-sounds/Audio/impactPunch_heavy_003.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_000.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_01.ogg", 0.00),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_000.ogg", "kenney-rpg-audio/Audio/bookPlace1.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_001.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_02.ogg", +0.35),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_001.ogg", "kenney-rpg-audio/Audio/bookPlace2.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_002.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_03.ogg", -0.35),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_002.ogg", "kenney-rpg-audio/Audio/bookPlace3.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_003.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_04.ogg", +0.20),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_004.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_004.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_05.ogg", -0.25),
        ],
    ),
    "medium": dict(
        dur_s=0.42, target_m400=-16.0,
        chunk=0.82, atk=0.92, pre_ms=0.8,
        sub_f=(132.0, 56.0), sub_tau=66.0,
        w_sub=1.18, w_punch=1.10, w_book=0.86, w_wood=0.72, w_crack=0.60, w_snap=0.36,
        t_boost=4.2, drive=2.05, scoop=-5.5, low_db=4.5, hi_db=3.0, hp=34.0, base_pitch=-1.6,
        takes=[
            ("kenney-impact-sounds/Audio/impactPunch_heavy_003.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_000.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_01.ogg", 0.00),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_000.ogg", "kenney-rpg-audio/Audio/bookPlace1.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_001.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_02.ogg", +0.30),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_001.ogg", "kenney-rpg-audio/Audio/bookPlace2.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_002.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_04.ogg", -0.30),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_002.ogg", "kenney-rpg-audio/Audio/bookPlace3.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_003.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_03.ogg", +0.20),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_004.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_004.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_05.ogg", -0.25),
        ],
    ),
    "heavy": dict(
        dur_s=0.48, target_m400=-15.0,
        chunk=1.00, atk=1.00, pre_ms=0.6,
        sub_f=(124.0, 46.0), sub_tau=86.0,
        w_sub=1.50, w_punch=1.30, w_book=0.88, w_wood=0.84, w_crack=0.68, w_snap=0.44,
        t_boost=5.0, drive=2.35, scoop=-6.2, low_db=5.8, hi_db=3.6, hp=30.0, base_pitch=-2.7,
        takes=[
            ("kenney-impact-sounds/Audio/impactPunch_heavy_003.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_000.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_01.ogg",  0.00, "oga-100-cc0-wood-metal-sfx/wood_slam_01.ogg", "kenney-rpg-audio/Audio/chop.ogg"),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_004.ogg", "kenney-rpg-audio/Audio/bookPlace1.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_001.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_02.ogg", +0.25, "oga-100-cc0-wood-metal-sfx/wood_slam_02.ogg", "oga-100-cc0-wood-metal-sfx/wood_breaking_01.ogg"),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_002.ogg", "kenney-rpg-audio/Audio/bookPlace2.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_002.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_04.ogg", -0.25, "oga-10-impactshield-blocks/impact.1.ogg",     "kenney-rpg-audio/Audio/chop.ogg"),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_000.ogg", "kenney-rpg-audio/Audio/bookPlace3.ogg", "kenney-impact-sounds/Audio/impactWood_heavy_003.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_03.ogg", +0.20, "oga-100-cc0-wood-metal-sfx/wood_slam_03.ogg", "oga-10-impactshield-blocks/impact.2.ogg"),
            ("kenney-impact-sounds/Audio/impactPunch_heavy_001.ogg", "kenney-rpg-audio/Audio/bookClose.ogg",  "kenney-impact-sounds/Audio/impactWood_heavy_004.ogg", "oga-100-cc0-wood-metal-sfx/wood_hit_05.ogg", -0.20, "oga-10-impactshield-blocks/impact.3.ogg",     "oga-100-cc0-wood-metal-sfx/wood_breaking_01.ogg"),
        ],
    ),
}


def synth_hit(weight, take_idx):
    cfg = WEIGHT_CFG[weight]
    take = cfg["takes"][take_idx]
    punch_file, book_file, wood_file, crack_file, jitter_st = take[:5]

    n = int(round(cfg["dur_s"] * SR))
    seed_base = {"light": 3000, "medium": 4000, "heavy": 5000}[weight]
    rng = np.random.default_rng(seed_base + take_idx)

    p = cfg["base_pitch"] + jitter_st
    pre = cfg["pre_ms"]

    s_punch = pitch_shift_resample(load_cc0(punch_file), -0.8 + p)
    s_book = pitch_shift_resample(load_cc0(book_file), -0.2 + p * 0.8)
    s_wood = pitch_shift_resample(load_cc0(wood_file), -0.5 + p * 0.9)
    s_crack = pitch_shift_resample(load_cc0(crack_file), +0.5 + p * 0.5)

    l_punch = rms_norm_window(lp_filter(align_sample(s_punch, n, HIT_TIME, pre_ms=pre, gate_ms=65 + 55 * cfg["chunk"]), 420.0))
    # Preserve crisp 2-3.5 kHz leather snap while curbing harsh >4 kHz slap spikes across takes
    l_book = rms_norm_window(lp_filter(align_sample(s_book, n, HIT_TIME, pre_ms=pre, gate_ms=60 + 38 * cfg["chunk"]), 3600.0))
    l_wood = rms_norm_window(lp_filter(align_sample(s_wood, n, HIT_TIME, pre_ms=pre, gate_ms=70 + 42 * cfg["chunk"]), 1800.0))
    l_crack_raw = bp_filter(align_sample(s_crack, n, HIT_TIME, pre_ms=max(0.5, pre * 0.7), gate_ms=22 + 14 * cfg["chunk"]), 1100.0, 8000.0)
    l_crack = rms_norm_window(soft_clip(l_crack_raw / (np.max(np.abs(l_crack_raw)) + 1e-12), ceil=0.75), win_ms=35.0)

    # Slight per-take sub pitch variation (+-2.5%) for organic non-robotic feel
    sub_scale = 2.0 ** ((jitter_st * 0.45) / 12.0)
    l_sub = rms_norm_window(
        instant_sub_thump(
            n, HIT_TIME,
            f_start=cfg["sub_f"][0] * sub_scale,
            f_end=cfg["sub_f"][1] * sub_scale,
            pitch_tau_ms=16.0 + 10.0 * cfg["chunk"],
            amp_tau_ms=cfg["sub_tau"],
            attack_ms=max(0.35, 1.6 - 1.25 * cfg["atk"]),
            drive=1.5 + 0.8 * cfg["chunk"],
        ),
        win_ms=85.0,
    )
    l_snap = instant_snap_crack(n, HIT_TIME, rng, fl=2000.0, fh=9000.0, dec_ms=4.8 + 2.5 * cfg["chunk"], amp=cfg["w_snap"])

    mix = (
        cfg["w_punch"] * l_punch
        + cfg["w_book"] * l_book
        + cfg["w_wood"] * l_wood
        + cfg["w_crack"] * l_crack
        + cfg["w_sub"] * l_sub
        + l_snap
    )

    if weight == "heavy":
        slam_file, edge_file = take[5], take[6]
        s_slam = pitch_shift_resample(load_cc0(slam_file), -1.8 + jitter_st)
        s_edge = pitch_shift_resample(load_cc0(edge_file), jitter_st)
        l_slam_raw = bp_filter(align_sample(s_slam, n, HIT_TIME, pre_ms=0.5, gate_ms=42.0), 380.0, 5000.0)
        l_slam = rms_norm_window(soft_clip(l_slam_raw / (np.max(np.abs(l_slam_raw)) + 1e-12), ceil=0.78), win_ms=45.0)
        l_edge_raw = bp_filter(align_sample(s_edge, n, HIT_TIME, pre_ms=0.5, gate_ms=26.0), 1200.0, 7500.0)
        l_edge = rms_norm_window(soft_clip(l_edge_raw / (np.max(np.abs(l_edge_raw)) + 1e-12), ceil=0.75), win_ms=35.0)
        mix += 0.55 * l_slam + 0.52 * l_edge

    mix = transient_punch_shaper(mix, HIT_TIME, boost_db=cfg["t_boost"], window_ms=5.6)
    return punch_master(
        mix,
        hp_hz=cfg["hp"],
        drive=cfg["drive"],
        scoop_db=cfg["scoop"],
        scoop_hz=330.0,
        low_db=cfg["low_db"],
        hi_db=cfg["hi_db"],
    )


# ---------------------------------------------------------------------------
# Single Loudness Standard: Ungated K-weighted Max Momentary (M400_max) + TP
# ---------------------------------------------------------------------------

def k_weight(x):
    y = x.copy()
    for f in _K_METER._filters.values():
        y = f.apply_filter(y)
    return y


def measure_m_max(x, win_s=0.400):
    """Ungated ITU-R BS.1770 K-weighted max momentary loudness over sliding win_s window."""
    y = k_weight(x)
    w = int(round(win_s * SR))
    if len(y) < w:
        pad = np.zeros(w, dtype=np.float64)
        pad[:len(y)] = y
        y = pad
    sq = y * y
    cs = np.concatenate([[0.0], np.cumsum(sq)])
    means = (cs[w:] - cs[:-w]) / w
    return -0.691 + 10.0 * math.log10(float(np.max(means)) + 1e-18)


def measure_true_peak_4x(x):
    """4x oversampled True Peak in dBTP."""
    up = resample_poly(x, 4, 1)
    return 20.0 * math.log10(float(np.max(np.abs(up))) + 1e-12)


def measure_ffmpeg_tp(path):
    p = subprocess.run(
        ["ffmpeg", "-nostats", "-i", path, "-af", "loudnorm=I=-18:TP=-1:LRA=11:print_format=summary", "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    )
    m_tp = re.search(r"Input True Peak:\s*([+\-\d.]+)\s*dBTP", p.stderr)
    if not m_tp:
        raise RuntimeError(f"Could not parse ffmpeg loudnorm TP for {path}")
    return float(m_tp.group(1))


def write_wav_16bit(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sf.write(path, np.clip(samples, -1.0, 1.0), SR, subtype="PCM_16")


def calibrate_m400_tp(samples, out_path, target_m400, max_tp_db=-1.2):
    """Calibrate deterministically to target M400_max LUFS with True Peak <= max_tp_db."""
    x = samples / (np.max(np.abs(samples)) + 1e-12) * 0.45
    ceil_db = max_tp_db - 0.6
    for _ in range(20):
        m400 = measure_m_max(x, 0.400)
        tp = measure_true_peak_4x(x)
        diff = target_m400 - m400
        if abs(diff) <= 0.05 and tp <= max_tp_db - 0.05:
            break
        if abs(diff) > 0.05:
            x = x * (10.0 ** (diff / 20.0))
        tp = measure_true_peak_4x(x)
        if tp > max_tp_db - 0.05:
            ceil_db -= max(0.25, (tp - (max_tp_db - 0.05)) * 0.85)
        ceil = 10.0 ** (ceil_db / 20.0)
        if float(np.max(np.abs(x))) > ceil:
            x = soft_clip(x, ceil=ceil)

    # Final verification against ffmpeg True Peak (ensuring <= max_tp_db strictly)
    for _ in range(6):
        write_wav_16bit(out_path, x)
        ff_tp = measure_ffmpeg_tp(out_path)
        if ff_tp <= max_tp_db:
            break
        ceil_db -= max(0.25, (ff_tp - max_tp_db) + 0.15)
        x = soft_clip(x, ceil=10.0 ** (ceil_db / 20.0))
        m400 = measure_m_max(x, 0.400)
        if abs(target_m400 - m400) > 0.08:
            x = x * (10.0 ** ((target_m400 - m400) / 20.0))

    write_wav_16bit(out_path, x)
    x16, _ = sf.read(out_path, dtype="float64")
    return measure_m_max(x16, 0.400), measure_m_max(x16, 0.200), measure_ffmpeg_tp(out_path)


def diagnostics(path):
    x, sr = sf.read(path, dtype="float64")
    dur = len(x) / sr
    pk = float(np.max(np.abs(x)))
    pk_ms = int(np.argmax(np.abs(x))) / sr * 1000.0
    onset_ms = int(np.argmax(np.abs(x) > 0.10 * pk)) / sr * 1000.0
    s0 = max(0, int(onset_ms * 1e-3 * sr))
    seg = x[s0:min(len(x), s0 + int(0.200 * sr))]
    X = np.abs(np.fft.rfft(seg)) ** 2
    f = np.fft.rfftfreq(len(seg), 1.0 / sr)
    tot = np.sum(X) + 1e-18
    lo = np.sum(X[f < 150]) / tot
    mid = np.sum(X[(f >= 150) & (f < 1500)]) / tot
    hi = np.sum(X[f >= 1500]) / tot
    clips = int(np.sum(np.abs(x) >= 0.9999))
    return dur, onset_ms, pk_ms, lo, mid, hi, clips


# ---------------------------------------------------------------------------
# Audition reels built strictly from the finished game WAVs
# ---------------------------------------------------------------------------

def build_audition_reels():
    os.makedirs(AUDITION_DIR, exist_ok=True)

    # 1. Showcase: 3 light -> pause -> 3 medium -> pause -> 3 heavy
    parts = []
    t_cursor = 0.20
    schedule = []
    for weight, gap in [("light", 0.50), ("medium", 0.55), ("heavy", 0.62)]:
        for i in range(1, 4):
            schedule.append((t_cursor, os.path.join(OUT_DIR, f"hit_{weight}_{i:02d}.wav")))
            t_cursor += gap
        t_cursor += 0.45
    n_show = int(round((t_cursor + 0.35) * SR))
    show = np.zeros(n_show, dtype=np.float64)
    for t_s, path in schedule:
        w, _ = sf.read(path, dtype="float64")
        pos = int(round(t_s * SR))
        end = min(n_show, pos + len(w))
        show[pos:end] += w[:end - pos]
    show_path = os.path.join(AUDITION_DIR, "hits_showcase.wav")
    write_wav_16bit(show_path, soft_clip(show, ceil=0.89))

    # 2. 10-second battle mix simulating real Bramble pacing (median 0.55 s step gap,
    #    single crisp hit per 1v1 clash at the heavier damage weight, plus one 3-hit cleave)
    n_fight = int(10.0 * SR)
    fight = np.zeros(n_fight, dtype=np.float64)
    # (time_s, weight, take_idx, pitch_st, gain_db)
    events = [
        (0.200, "light",  1, +0.3,  0.0),
        (0.750, "light",  2, -0.3,  0.0),
        (1.320, "medium", 1, +0.2,  0.0),
        (1.700, "light",  3, +0.4,  0.0),
        (2.250, "medium", 2, -0.2,  0.0),
        (2.850, "heavy",  1, +0.1,  0.0),
        (3.480, "light",  4, -0.2,  0.0),
        (3.820, "medium", 3, +0.3,  0.0),  # quick counter-trade (0.34 s)
        (4.180, "medium", 4, -0.3,  0.0),  # brisk follow-up (0.36 s)
        # 3-hit cleave cascade (0 ms, +28 ms -4.5 dB, +58 ms -7.0 dB)
        (4.920, "heavy",  2, +0.1,  0.0),
        (4.948, "medium", 5, -0.2, -4.5),
        (4.978, "light",  5, +0.3, -7.0),
        (5.720, "medium", 1, -0.2,  0.0),
        (6.280, "heavy",  3, -0.1,  0.0),
        (6.880, "medium", 2, +0.2,  0.0),
        (7.420, "light",  1, -0.2,  0.0),
        (8.020, "heavy",  4, -0.2,  0.0),
        (8.620, "medium", 3, +0.2,  0.0),
        (9.180, "heavy",  5, -0.1,  0.0),  # finishing blow
    ]
    for t_s, weight, idx, p_st, g_db in events:
        w, _ = sf.read(os.path.join(OUT_DIR, f"hit_{weight}_{idx:02d}.wav"), dtype="float64")
        w = pitch_shift_resample(w, p_st) * (10.0 ** (g_db / 20.0))
        pos = int(round(t_s * SR))
        end = min(n_fight, pos + len(w))
        if end > pos:
            fight[pos:end] += w[:end - pos]
    fo = int(0.05 * SR)
    fight[-fo:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
    # Keep peaks cleanly <= -1.2 dBTP without changing relative weight balance
    if measure_true_peak_4x(fight) > -1.2:
        fight = soft_clip(fight, ceil=10.0 ** (-1.6 / 20.0))
    fight_path = os.path.join(AUDITION_DIR, "fight_10s.wav")
    write_wav_16bit(fight_path, fight)

    for p in (show_path, fight_path):
        x, _ = sf.read(p, dtype="float64")
        print(f"Audition: {os.path.relpath(p, REPO_ROOT):34s} | dur={len(x)/SR:5.2f}s | M400={measure_m_max(x, 0.4):6.2f} | TP={measure_ffmpeg_tp(p):5.1f} dBTP")


def main():
    parser = argparse.ArgumentParser(description="Generate Bramble combat hit SFX.")
    parser.add_argument("--audition", action="store_true", help="Also generate gitignored audition reels in .copies/audition/")
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"{'File':20s} | {'dur':5s} | {'onset':6s} {'pk':6s} {'rise':5s} | {'<150':4s} {'mid':4s} {'>1.5k':5s} | {'M400':6s} {'M200':6s} {'TP':6s} | {'clip':4s}")
    print("-" * 108)
    for weight in ("light", "medium", "heavy"):
        cfg = WEIGHT_CFG[weight]
        for idx in range(len(cfg["takes"])):
            fname = f"hit_{weight}_{idx + 1:02d}.wav"
            path = os.path.join(OUT_DIR, fname)
            sig = synth_hit(weight, idx)
            m400, m200, tp = calibrate_m400_tp(sig, path, target_m400=cfg["target_m400"], max_tp_db=-1.2)
            dur, onset, pk, lo, mid, hi, clips = diagnostics(path)
            print(
                f"{fname:20s} | {dur:4.2f}s | {onset:5.1f}m {pk:5.1f}m {pk - onset:4.1f}m | "
                f"{lo:4.2f} {mid:4.2f} {hi:5.2f} | {m400:6.2f} {m200:6.2f} {tp:6.1f} | {clips:4d}"
            )

    if args.audition:
        print()
        build_audition_reels()


if __name__ == "__main__":
    main()
