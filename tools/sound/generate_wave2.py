#!/usr/bin/env python3
"""
Deterministic Wave 2 combat SFX generator for Bramble.

Produces 18 game-ready SFX in assets/audio/sfx/:
  - hit_blocked_01..03.wav : shield-blocked hit (0 damage), chunky leaded-glass/metal deflect
  - death_01..04.wav       : unit death (~9/fight), compact stained-glass & oak crack + drop
  - destroy_01..02.wav     : outright destroy (no damage number), heavy dark slam + glass shatter
  - summon_01..03.wav      : unit/reserve enters board, tactile woodland card pop-thunk
  - trigger_01..03.wav     : ability trigger (~8/fight), delicate stained-glass sunlight glint
  - fight_win.wav          : short warm woodland harp & stained-glass victory cadence
  - fight_lose.wav         : gentle muted descending woodland loss cadence
  - fight_tie.wav          : crisp neutral open-fifth tie chime

With --audition, also writes listening reels to .copies/audition/ (gitignored):
  - wave2_showcase.wav     : progression of all Wave 2 cues
  - fight_wave2_12s.wav    : 12 s full-fight mix combining Wave 1 hits + Wave 2 cues

Format & loudness standard (same single method as Wave 1):
  - 48 kHz, 16-bit mono PCM WAV, zero digital clips
  - Action cues start within ~1.5-4 ms of file start (instant on visual contact/event)
  - Loudness calibrated by ungated K-weighted Max Momentary Loudness (M400_max,
    ITU-R BS.1770 400 ms sliding window via pyloudnorm K-weighting filter)
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
HIT_TIME = 0.0025
LIB = "/data/sound-library"

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "audio", "sfx")
AUDITION_DIR = os.path.join(REPO_ROOT, ".copies", "audition")

_SAMPLE_CACHE = {}
_K_METER = pyln.Meter(SR)


# ---------------------------------------------------------------------------
# Core audio helpers
# ---------------------------------------------------------------------------

def load_cc0(rel_path):
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
    ax = np.abs(x)
    knee = 0.65 * ceil
    excess = np.maximum(0.0, ax - knee)
    return np.sign(x) * np.where(
        ax <= knee,
        ax,
        knee + (ceil - knee) * np.tanh(excess / max(ceil - knee, 1e-6)),
    )


def rms_norm_window(x, hit_s=HIT_TIME, win_ms=70.0):
    s0 = max(0, int((hit_s - 0.0015) * SR))
    s1 = min(len(x), s0 + int(win_ms * 1e-3 * SR))
    rms = math.sqrt(float(np.mean(x[s0:s1] ** 2)) + 1e-12)
    return x / rms * 0.25


def align_sample(x, out_len, hit_s=HIT_TIME, pre_ms=1.0, gate_ms=None, fade_out_ms=24.0):
    pk_idx = int(np.argmax(np.abs(x)))
    pk_val = float(np.abs(x[pk_idx])) + 1e-12
    onset = pk_idx
    search_start = max(0, pk_idx - int(0.040 * SR))
    sub = np.abs(x[search_start:pk_idx + 1])
    hits = np.where(sub >= 0.15 * pk_val)[0]
    if len(hits) > 0:
        onset = search_start + int(hits[0])

    pre_smp = int(pre_ms * 1e-3 * SR)
    src_start = max(0, onset - pre_smp)
    trimmed = x[src_start:].copy()

    r = min(len(trimmed), int(0.0005 * SR))
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


def pitched_body(n, hit_s, f_start, f_end, pitch_tau_ms, amp_tau_ms, attack_ms=0.6, drive=1.5, harmonic2=0.25):
    t = np.arange(n, dtype=np.float64) / SR - hit_s
    y = np.zeros(n, dtype=np.float64)
    m = t >= 0.0
    tm = t[m]
    pt = pitch_tau_ms * 1e-3
    at = amp_tau_ms * 1e-3
    phase = 2.0 * math.pi * (f_end * tm + (f_start - f_end) * pt * (1.0 - np.exp(-tm / pt)))
    raw = np.sin(phase) + harmonic2 * np.sin(2.0 * phase + 0.3) * np.exp(-tm / (at * 0.55))
    atk = np.minimum(1.0, tm / max(attack_ms * 1e-3, 1e-5))
    atk = np.sin(0.5 * np.pi * atk)
    env = atk * np.exp(-np.power(tm / at, 1.2))
    sig = raw * env
    sig = np.tanh(drive * sig) / math.tanh(drive)
    y[m] = sig
    return y


def transient_punch_shaper(x, hit_s, boost_db=3.5, window_ms=5.8):
    if abs(boost_db) < 0.05:
        return x
    t = (np.arange(len(x), dtype=np.float64) / SR - hit_s) * 1000.0
    g_pk = 10.0 ** (boost_db / 20.0)
    w = np.where(t < -0.6, 0.0, np.where(t < 0.0, (t + 0.6) / 0.6, np.exp(-np.maximum(0.0, t) / window_ms)))
    return x * (1.0 + (g_pk - 1.0) * w)


def finish_master(x, hp_hz=38.0, drive=1.5, scoop_db=0.0, scoop_hz=350.0, low_db=0.0, hi_db=0.0, fade_in_ms=0.5, fade_out_ms=26.0):
    x = x - np.mean(x)
    x = hp_filter(x, hp_hz, order=2)
    if abs(scoop_db) > 0.1:
        x = biquad_eq(x, "peak", scoop_hz, q=1.0, gain_db=scoop_db)
    if abs(low_db) > 0.1:
        x = biquad_eq(x, "lowshelf", 140.0, q=0.75, gain_db=low_db)
    if abs(hi_db) > 0.1:
        x = biquad_eq(x, "highshelf", 2400.0, q=0.75, gain_db=hi_db)
    x = x / (np.max(np.abs(x)) + 1e-12) * 0.92
    if drive > 1.05:
        x = np.tanh(drive * (x + 0.03 * x * x)) / math.tanh(drive)
    x = x - np.mean(x)
    x = hp_filter(x, max(28.0, hp_hz * 0.85), order=2)
    fi = max(2, int(fade_in_ms * 1e-3 * SR))
    fo = max(2, int(fade_out_ms * 1e-3 * SR))
    x[:fi] *= 0.5 - 0.5 * np.cos(np.linspace(0.0, np.pi, fi))
    x[-fo:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
    return x


# ---------------------------------------------------------------------------
# Clean acoustic wooden-harp / marimba + stained-glass celesta voices
# ---------------------------------------------------------------------------

def synth_warm_harp_note(n, start_s, freq_hz, decay_s, rng, amp=1.0, warmth=0.65):
    """
    Warm acoustic woodland harp / wooden-mallet note with zero harsh buzz:
    pure harmonic body + natural fast-decaying upper partials + subtle finger-pluck transient.
    """
    t = np.arange(n, dtype=np.float64) / SR - start_s
    y = np.zeros(n, dtype=np.float64)
    m = t >= 0.0
    tm = t[m]

    atk = np.minimum(1.0, tm / 0.0045)
    atk = np.sin(0.5 * np.pi * atk)

    # Slight warm micro-detune on chorus twin for acoustic richness
    h1 = 1.00 * np.sin(2.0 * math.pi * freq_hz * tm) * np.exp(-tm / decay_s)
    h1b = 0.20 * np.sin(2.0 * math.pi * (freq_hz * 1.0012) * tm + 0.7) * np.exp(-tm / (decay_s * 0.92))
    h2 = (0.34 - 0.14 * warmth) * np.sin(2.0 * math.pi * (freq_hz * 2.0005) * tm + 0.3) * np.exp(-tm / (decay_s * 0.45))
    h3 = (0.14 - 0.07 * warmth) * np.sin(2.0 * math.pi * (freq_hz * 3.001) * tm + 1.1) * np.exp(-tm / (decay_s * 0.22))
    h4 = (0.05 - 0.03 * warmth) * np.sin(2.0 * math.pi * (freq_hz * 4.002) * tm + 1.9) * np.exp(-tm / (decay_s * 0.11))

    # Subtle soft finger/felt pluck transient (2.5-6 ms)
    pluck_n = bp_filter(rng.standard_normal(len(tm)), max(250.0, freq_hz * 0.8), min(4200.0, freq_hz * 5.0), order=2)
    pluck_n /= (np.std(pluck_n) + 1e-12)
    pluck = 0.08 * pluck_n * np.exp(-tm / 0.0055)

    y[m] = (h1 + h1b + h2 + h3 + h4 + pluck) * atk * amp
    return y


def synth_stained_glass_chime(n, start_s, freq_hz, decay_s, amp=0.35, attack_ms=2.5):
    """Warm, softly damped leaded-stained-glass celesta chime (zero metallic ring)."""
    t = np.arange(n, dtype=np.float64) / SR - start_s
    y = np.zeros(n, dtype=np.float64)
    m = t >= 0.0
    tm = t[m]
    atk = np.minimum(1.0, tm / max(attack_ms * 1e-3, 1e-4))
    atk = np.sin(0.5 * np.pi * atk)
    sig = (
        1.00 * np.sin(2.0 * math.pi * freq_hz * tm) * np.exp(-tm / decay_s)
        + 0.26 * np.sin(2.0 * math.pi * (freq_hz * 2.001) * tm + 0.4) * np.exp(-tm / (decay_s * 0.42))
        + 0.09 * np.sin(2.0 * math.pi * (freq_hz * 3.012) * tm + 1.1) * np.exp(-tm / (decay_s * 0.20))
    )
    y[m] = sig * atk * amp
    return y


def add_soft_room(x, wet=0.16):
    """Short warm woodland-hall early reflections for musical round-end cadences."""
    ref = np.zeros_like(x)
    taps = [(0.018, 0.36), (0.031, 0.28), (0.047, 0.21), (0.067, 0.14), (0.091, 0.09)]
    for delay_s, gain in taps:
        d = int(round(delay_s * SR))
        if d < len(x):
            ref[d:] += gain * x[:-d]
    ref = lp_filter(ref, 3200.0, order=2)
    return x + wet * ref


# ---------------------------------------------------------------------------
# Wave 2 Cue Synthesizers
# ---------------------------------------------------------------------------

def synth_hit_blocked(take_idx):
    """Shield-blocked hit (0 damage): chunky leaded-glass & metal deflect clink."""
    n = int(0.36 * SR)
    takes = [
        ("kenney-impact-sounds/Audio/impactPlate_medium_000.ogg", "kenney-impact-sounds/Audio/impactMetal_light_000.ogg", "kenney-impact-sounds/Audio/impactGlass_medium_000.ogg",  0.00),
        ("kenney-impact-sounds/Audio/impactPlate_medium_001.ogg", "kenney-impact-sounds/Audio/impactMetal_light_001.ogg", "kenney-impact-sounds/Audio/impactGlass_medium_001.ogg", +0.55),
        ("kenney-impact-sounds/Audio/impactPlate_medium_002.ogg", "kenney-impact-sounds/Audio/impactMetal_light_002.ogg", "kenney-impact-sounds/Audio/impactGlass_medium_002.ogg", -0.45),
    ]
    plate_f, metal_f, glass_f, p_st = takes[take_idx]

    s_plate = pitch_shift_resample(load_cc0(plate_f), -0.5 + p_st)
    s_metal = pitch_shift_resample(load_cc0(metal_f), +1.2 + p_st)
    s_glass = pitch_shift_resample(load_cc0(glass_f), -1.0 + p_st)

    l_plate = rms_norm_window(bp_filter(align_sample(s_plate, n, HIT_TIME, pre_ms=0.7, gate_ms=65.0), 280.0, 5000.0))
    l_metal_raw = bp_filter(align_sample(s_metal, n, HIT_TIME, pre_ms=0.5, gate_ms=56.0), 1100.0, 8200.0)
    l_metal = rms_norm_window(soft_clip(l_metal_raw / (np.max(np.abs(l_metal_raw)) + 1e-12), ceil=0.75), win_ms=42.0)
    l_glass_raw = bp_filter(align_sample(s_glass, n, HIT_TIME + 0.002, pre_ms=0.5, gate_ms=72.0), 1400.0, 8500.0)
    l_glass = rms_norm_window(soft_clip(l_glass_raw / (np.max(np.abs(l_glass_raw)) + 1e-12), ceil=0.75), win_ms=50.0)

    # Solid dead-lead cushion underneath so it feels chunky & physical, not thin tin
    l_thud = rms_norm_window(pitched_body(n, HIT_TIME, 168.0, 90.0, pitch_tau_ms=14.0, amp_tau_ms=38.0, attack_ms=0.5, drive=1.55), win_ms=55.0)
    f_glint = 1174.66 * (2.0 ** (p_st / 12.0))  # D6
    l_glint = synth_stained_glass_chime(n, HIT_TIME, f_glint, decay_s=0.068, amp=0.12, attack_ms=0.8)

    mix = 1.00 * l_plate + 0.62 * l_metal + 0.52 * l_glass + 0.78 * l_thud + l_glint
    mix = transient_punch_shaper(mix, HIT_TIME, boost_db=2.8, window_ms=5.0)
    return finish_master(mix, hp_hz=55.0, drive=1.60, scoop_db=-3.0, scoop_hz=420.0, low_db=0.8, hi_db=1.4)


def synth_death(take_idx):
    """Unit death (~9/fight): compact stained-glass & oak card crack + chunky descending drop."""
    n = int(0.44 * SR)
    takes = [
        ("oga-75-cc0-breaking-falling-hit-sfx/bfh1_wood_breaking_01.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_01.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_rock_breaking_01.ogg",  0.00),
        ("oga-75-cc0-breaking-falling-hit-sfx/bfh1_wood_breaking_02.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_02.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_rock_breaking_02.ogg", +0.40),
        ("oga-75-cc0-breaking-falling-hit-sfx/bfh1_wood_breaking_03.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_03.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_rock_breaking_03.ogg", -0.35),
        ("oga-75-cc0-breaking-falling-hit-sfx/bfh1_wood_breaking_04.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_04.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_wood_falling_01.ogg",  -0.15),
    ]
    wood_f, glass_f, tumble_f, p_st = takes[take_idx]

    s_wood = pitch_shift_resample(load_cc0(wood_f), -1.0 + p_st)
    s_glass = pitch_shift_resample(load_cc0(glass_f), -2.5 + p_st)
    s_tumble = pitch_shift_resample(load_cc0(tumble_f), -1.5 + p_st)

    l_wood_raw = bp_filter(align_sample(s_wood, n, HIT_TIME, pre_ms=0.7, gate_ms=82.0), 260.0, 5600.0)
    l_wood = rms_norm_window(soft_clip(l_wood_raw / (np.max(np.abs(l_wood_raw)) + 1e-12), ceil=0.76), win_ms=55.0)

    # Tight stained-glass card crackle (delayed 8 ms so front snap hits immediately on frame 0)
    l_glass_raw = bp_filter(align_sample(s_glass, n, HIT_TIME + 0.008, pre_ms=0.8, gate_ms=105.0), 1250.0, 6400.0)
    l_glass = rms_norm_window(soft_clip(l_glass_raw / (np.max(np.abs(l_glass_raw)) + 1e-12), ceil=0.72), hit_s=HIT_TIME + 0.008, win_ms=80.0)

    l_tumble_raw = bp_filter(align_sample(s_tumble, n, HIT_TIME + 0.018, pre_ms=1.0, gate_ms=120.0), 160.0, 2400.0)
    l_tumble = rms_norm_window(soft_clip(l_tumble_raw / (np.max(np.abs(l_tumble_raw)) + 1e-12), ceil=0.76), hit_s=HIT_TIME + 0.018, win_ms=85.0)

    scale = 2.0 ** (p_st / 12.0)
    l_drop = rms_norm_window(
        pitched_body(n, HIT_TIME, 144.0 * scale, 44.0 * scale, pitch_tau_ms=48.0, amp_tau_ms=100.0, attack_ms=0.8, drive=1.75, harmonic2=0.22),
        win_ms=95.0,
    )

    mix = 1.00 * l_wood + 0.42 * l_glass + 0.48 * l_tumble + 1.15 * l_drop
    mix = transient_punch_shaper(mix, HIT_TIME, boost_db=3.2, window_ms=5.5)
    return finish_master(mix, hp_hz=36.0, drive=1.80, scoop_db=-3.8, scoop_hz=370.0, low_db=2.6, hi_db=-0.6, fade_out_ms=35.0)


def synth_destroy(take_idx):
    """Outright destroy (no damage number): massive dark Ladder-5 slam + crisp stained-glass shatter."""
    n = int(0.54 * SR)
    takes = [
        ("kenney-impact-sounds/Audio/impactPunch_heavy_004.ogg", "kenney-impact-sounds/Audio/impactSoft_heavy_000.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_05.ogg", "oga-100-cc0-wood-metal-sfx/wood_breaking_01.ogg",  0.00),
        ("kenney-impact-sounds/Audio/impactPunch_heavy_002.ogg", "kenney-impact-sounds/Audio/impactSoft_heavy_001.ogg", "oga-75-cc0-breaking-falling-hit-sfx/bfh1_glass_breaking_06.ogg", "oga-100-cc0-wood-metal-sfx/wood_breaking_02.ogg", -0.45),
    ]
    punch_f, soft_f, glass_f, wood_f, p_st = takes[take_idx]

    s_punch = pitch_shift_resample(load_cc0(punch_f), -3.0 + p_st)
    s_soft = pitch_shift_resample(load_cc0(soft_f), -3.2 + p_st)
    s_glass = pitch_shift_resample(load_cc0(glass_f), -2.5 + p_st)
    s_wood = pitch_shift_resample(load_cc0(wood_f), -1.8 + p_st)

    l_punch = rms_norm_window(lp_filter(align_sample(s_punch, n, HIT_TIME, pre_ms=0.6, gate_ms=145.0), 380.0), win_ms=90.0)
    l_soft = rms_norm_window(lp_filter(align_sample(s_soft, n, HIT_TIME, pre_ms=0.6, gate_ms=165.0), 280.0), win_ms=100.0)
    l_wood_raw = bp_filter(align_sample(s_wood, n, HIT_TIME, pre_ms=0.6, gate_ms=95.0), 300.0, 5600.0)
    l_wood = rms_norm_window(soft_clip(l_wood_raw / (np.max(np.abs(l_wood_raw)) + 1e-12), ceil=0.75), win_ms=65.0)
    # Tasteful glass shatter kept in proportion so low-end slam stays king (~75% <150 Hz)
    l_glass_raw = bp_filter(align_sample(s_glass, n, HIT_TIME + 0.008, pre_ms=0.8, gate_ms=170.0), 1100.0, 6200.0)
    l_glass = rms_norm_window(soft_clip(l_glass_raw / (np.max(np.abs(l_glass_raw)) + 1e-12), ceil=0.72), hit_s=HIT_TIME + 0.008, win_ms=110.0)

    scale = 2.0 ** (p_st / 12.0)
    l_drop = rms_norm_window(
        pitched_body(n, HIT_TIME, 126.0 * scale, 36.0 * scale, pitch_tau_ms=58.0, amp_tau_ms=140.0, attack_ms=0.5, drive=2.20, harmonic2=0.30),
        win_ms=120.0,
    )

    mix = 1.15 * l_punch + 1.00 * l_soft + 0.85 * l_wood + 0.44 * l_glass + 1.55 * l_drop
    mix = transient_punch_shaper(mix, HIT_TIME, boost_db=4.4, window_ms=6.0)
    return finish_master(mix, hp_hz=30.0, drive=2.20, scoop_db=-5.2, scoop_hz=330.0, low_db=5.0, hi_db=0.4, fade_out_ms=42.0)


def synth_summon(take_idx):
    """Unit/reserve enters board (~1/fight): tactile woodland card arrival thunk + crisp leaf flutter."""
    n = int(0.34 * SR)
    takes = [
        ("kenney-rpg-audio/Audio/bookPlace1.ogg", "kenney-rpg-audio/Audio/cloth1.ogg",   "kenney-impact-sounds/Audio/impactPlank_medium_000.ogg",  0.00, 587.33),  # D5
        ("kenney-rpg-audio/Audio/bookPlace2.ogg", "kenney-rpg-audio/Audio/cloth2.ogg",   "kenney-impact-sounds/Audio/impactPlank_medium_001.ogg", +0.45, 659.25),  # E5
        ("kenney-rpg-audio/Audio/bookPlace3.ogg", "kenney-rpg-audio/Audio/bookOpen.ogg", "kenney-impact-sounds/Audio/impactPlank_medium_002.ogg", -0.35, 739.99),  # F#5
    ]
    card_f, air_f, plank_f, p_st, glint_hz = takes[take_idx]

    s_card = pitch_shift_resample(load_cc0(card_f), +0.6 + p_st)
    s_air = pitch_shift_resample(load_cc0(air_f), +1.2 + p_st)
    s_plank = pitch_shift_resample(load_cc0(plank_f), +0.8 + p_st)

    # Brief leafy/card arrival brush leading into solid wooden-card placement
    l_air = rms_norm_window(bp_filter(align_sample(s_air, n, HIT_TIME, pre_ms=1.0, gate_ms=45.0), 800.0, 6200.0), win_ms=40.0)
    l_card = rms_norm_window(lp_filter(align_sample(s_card, n, HIT_TIME + 0.003, pre_ms=0.8, gate_ms=65.0), 2800.0), hit_s=HIT_TIME + 0.003, win_ms=55.0)
    l_plank = rms_norm_window(lp_filter(align_sample(s_plank, n, HIT_TIME + 0.003, pre_ms=0.8, gate_ms=70.0), 2000.0), hit_s=HIT_TIME + 0.003, win_ms=60.0)

    # Gentle upward wooden lift (92 -> 136 Hz, restrained so it feels physical, never cartoony)
    scale = 2.0 ** (p_st / 12.0)
    l_pop = rms_norm_window(
        pitched_body(n, HIT_TIME + 0.002, 92.0 * scale, 136.0 * scale, pitch_tau_ms=22.0, amp_tau_ms=46.0, attack_ms=1.2, drive=1.40, harmonic2=0.16),
        win_ms=55.0,
    )
    l_glint = synth_stained_glass_chime(n, HIT_TIME + 0.008, glint_hz, decay_s=0.085, amp=0.18, attack_ms=2.0)

    mix = 0.42 * l_air + 0.92 * l_card + 0.85 * l_plank + 0.58 * l_pop + l_glint
    mix = transient_punch_shaper(mix, HIT_TIME + 0.003, boost_db=2.2, window_ms=5.0)
    return finish_master(mix, hp_hz=50.0, drive=1.45, scoop_db=-2.8, scoop_hz=350.0, low_db=1.8, hi_db=0.8, fade_out_ms=30.0)


def synth_trigger(take_idx):
    """Ability trigger (~8/fight): delicate, single-gesture stained-glass sunlight glint (D pentatonic)."""
    n = int(0.24 * SR)
    configs = [
        (880.00,  "oga-100-cc0-sfx/bell_01.ogg", "kenney-rpg-audio/Audio/bookPlace1.ogg",  0.0),  # A5
        (987.77,  "oga-100-cc0-sfx/bell_02.ogg", "kenney-rpg-audio/Audio/bookPlace2.ogg", +1.0),  # B5
        (1174.66, "oga-100-cc0-sfx/bell_03.ogg", "kenney-rpg-audio/Audio/bookPlace3.ogg", +2.0),  # D6
    ]
    hz, bell_f, tick_f, p_st = configs[take_idx]

    # Single warm stained-glass glint + soft lower fifth undertone
    l_glass = (
        synth_stained_glass_chime(n, HIT_TIME, hz, decay_s=0.078, amp=0.82, attack_ms=2.2)
        + synth_stained_glass_chime(n, HIT_TIME, hz * 0.6667, decay_s=0.068, amp=0.38, attack_ms=2.8)
    )
    s_bell = pitch_shift_resample(load_cc0(bell_f), p_st)
    l_bell = rms_norm_window(bp_filter(align_sample(s_bell, n, HIT_TIME, pre_ms=0.8, gate_ms=68.0), 1200.0, 5600.0), win_ms=50.0)
    s_tick = load_cc0(tick_f)
    l_tick = rms_norm_window(bp_filter(align_sample(s_tick, n, HIT_TIME, pre_ms=0.6, gate_ms=18.0), 900.0, 4200.0), win_ms=22.0)

    mix = 0.85 * l_glass + 0.14 * l_bell + 0.14 * l_tick
    return finish_master(mix, hp_hz=240.0, drive=1.08, hi_db=-1.2, fade_in_ms=0.8, fade_out_ms=34.0)


def synth_fight_win():
    """Short warm woodland harp & stained-glass victory cadence (D major, ~1.15 s)."""
    n = int(1.15 * SR)
    rng = np.random.default_rng(7101)
    mix = np.zeros(n, dtype=np.float64)

    # Warm ascending D major woodland cadence: D4 -> F#4 -> A4 -> warm D5+F#5+D3 chord bloom
    notes = [
        (0.010, 293.66, 0.34, 0.72),  # D4
        (0.095, 369.99, 0.34, 0.76),  # F#4
        (0.180, 440.00, 0.36, 0.82),  # A4
        (0.285, 587.33, 0.44, 1.00),  # D5 arrival
        (0.300, 739.99, 0.40, 0.50),  # F#5 warm third
        (0.285, 293.66, 0.46, 0.56),  # D4 body
        (0.285, 146.83, 0.48, 0.58),  # D3 grounded bass
    ]
    for t_s, hz, dec_s, amp in notes:
        mix += synth_warm_harp_note(n, t_s, hz, dec_s, rng, amp=amp, warmth=0.68)

    mix += synth_stained_glass_chime(n, 0.285, 587.33, decay_s=0.34, amp=0.28, attack_ms=4.5)
    mix += synth_stained_glass_chime(n, 0.300, 880.00, decay_s=0.28, amp=0.15, attack_ms=5.5)

    # Warm grounded oak-drum tap on the arrival beat (0.285 s)
    s_wood = pitch_shift_resample(load_cc0("kenney-impact-sounds/Audio/impactWood_heavy_000.ogg"), -2.2)
    l_tap = rms_norm_window(lp_filter(align_sample(s_wood, n, 0.285, pre_ms=1.0, gate_ms=85.0), 620.0), hit_s=0.285, win_ms=70.0)
    l_sub = rms_norm_window(pitched_body(n, 0.285, 118.0, 73.42, pitch_tau_ms=22.0, amp_tau_ms=90.0, attack_ms=2.0, drive=1.35, harmonic2=0.14), hit_s=0.285, win_ms=80.0)
    mix += 0.58 * l_tap + 0.55 * l_sub

    mix = add_soft_room(mix, wet=0.18)
    return finish_master(mix, hp_hz=42.0, drive=1.14, low_db=1.2, hi_db=-0.6, fade_in_ms=2.0, fade_out_ms=95.0)


def synth_fight_lose():
    """Gentle muted descending woodland loss cadence (D minor sigh, ~1.10 s — warm, never harsh)."""
    n = int(1.10 * SR)
    rng = np.random.default_rng(7102)
    mix = np.zeros(n, dtype=np.float64)

    # Clear, warm descending D minor sigh: F4 -> E4 -> D4 over soft grounded D3
    notes = [
        (0.015, 349.23, 0.28, 0.72),  # F4
        (0.165, 329.63, 0.28, 0.70),  # E4
        (0.325, 293.66, 0.44, 0.90),  # D4 arrival
        (0.325, 146.83, 0.48, 0.65),  # D3 grounded bass
        (0.335, 220.00, 0.40, 0.42),  # A3 hollow fifth
    ]
    for t_s, hz, dec_s, amp in notes:
        mix += synth_warm_harp_note(n, t_s, hz, dec_s, rng, amp=amp, warmth=0.82)

    mix += synth_stained_glass_chime(n, 0.325, 293.66, decay_s=0.30, amp=0.14, attack_ms=7.0)

    # Soft muted dead-lead/wood knock on final beat
    s_soft = pitch_shift_resample(load_cc0("kenney-impact-sounds/Audio/impactSoft_heavy_000.ogg"), -2.5)
    l_thud = rms_norm_window(lp_filter(align_sample(s_soft, n, 0.325, pre_ms=1.5, gate_ms=110.0), 340.0), hit_s=0.325, win_ms=80.0)
    mix += 0.56 * l_thud

    mix = add_soft_room(mix, wet=0.16)
    return finish_master(mix, hp_hz=38.0, drive=1.12, low_db=1.4, hi_db=-2.0, fade_in_ms=2.5, fade_out_ms=95.0)


def synth_fight_tie():
    """Crisp neutral two-note open-fifth woodland-glass chime (D4 -> A4, ~0.80 s)."""
    n = int(0.80 * SR)
    rng = np.random.default_rng(7103)
    mix = np.zeros(n, dtype=np.float64)

    mix += synth_warm_harp_note(n, 0.010, 293.66, 0.30, rng, amp=0.78, warmth=0.72)  # D4
    mix += synth_warm_harp_note(n, 0.135, 440.00, 0.36, rng, amp=0.84, warmth=0.70)  # A4
    mix += synth_stained_glass_chime(n, 0.010, 587.33, decay_s=0.18, amp=0.16, attack_ms=3.0)
    mix += synth_stained_glass_chime(n, 0.135, 880.00, decay_s=0.22, amp=0.18, attack_ms=3.5)

    s_wood = load_cc0("kenney-rpg-audio/Audio/bookPlace1.ogg")
    l_tap = rms_norm_window(lp_filter(align_sample(s_wood, n, 0.135, pre_ms=1.0, gate_ms=55.0), 1100.0), hit_s=0.135, win_ms=45.0)
    mix += 0.28 * l_tap

    mix = add_soft_room(mix, wet=0.14)
    return finish_master(mix, hp_hz=55.0, drive=1.10, hi_db=-0.8, fade_in_ms=2.0, fade_out_ms=85.0)


# ---------------------------------------------------------------------------
# Single Loudness Standard: M400_max + ffmpeg True Peak <= -1.2 dBTP
# ---------------------------------------------------------------------------

def k_weight(x):
    y = x.copy()
    for f in _K_METER._filters.values():
        y = f.apply_filter(y)
    return y


def measure_m_max(x, win_s=0.400):
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
    x = samples / (np.max(np.abs(samples)) + 1e-12) * 0.45
    ceil_db = max_tp_db - 0.6
    for _ in range(22):
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
# Audition Reels (showcase + full Wave 1 + Wave 2 fight context)
# ---------------------------------------------------------------------------

def build_audition_reels():
    os.makedirs(AUDITION_DIR, exist_ok=True)

    groups = [
        (["hit_blocked_01.wav", "hit_blocked_02.wav"], 0.46),
        (["death_01.wav", "death_02.wav"], 0.54),
        (["destroy_01.wav", "destroy_02.wav"], 0.64),
        (["summon_01.wav", "summon_02.wav"], 0.46),
        (["trigger_01.wav", "trigger_02.wav", "trigger_03.wav"], 0.30),
        (["fight_win.wav"], 1.30),
        (["fight_lose.wav"], 1.25),
        (["fight_tie.wav"], 0.95),
    ]
    t = 0.20
    events = []
    for files, step_s in groups:
        for f in files:
            events.append((t, os.path.join(OUT_DIR, f)))
            t += step_s
        t += 0.36
    n_show = int(round((t + 0.30) * SR))
    show = np.zeros(n_show, dtype=np.float64)
    for t_s, path in events:
        w, _ = sf.read(path, dtype="float64")
        pos = int(round(t_s * SR))
        end = min(n_show, pos + len(w))
        show[pos:end] += w[:end - pos]
    show_path = os.path.join(AUDITION_DIR, "wave2_showcase.wav")
    write_wav_16bit(show_path, soft_clip(show, ceil=0.89))

    n_fight = int(12.0 * SR)
    fight = np.zeros(n_fight, dtype=np.float64)
    seq = [
        (0.200, "trigger_01.wav",      0.0),
        (0.650, "hit_light_01.wav",    0.0),
        (0.665, "hit_blocked_01.wav", -3.0),
        (1.300, "hit_medium_01.wav",   0.0),
        (1.700, "death_01.wav",        0.0),
        (2.150, "trigger_02.wav",      0.0),
        (2.550, "summon_01.wav",       0.0),
        (3.250, "hit_heavy_01.wav",    0.0),
        (3.650, "death_02.wav",        0.0),
        (3.705, "death_03.wav",       -4.5),
        (4.450, "hit_blocked_02.wav",  0.0),
        (5.050, "trigger_03.wav",      0.0),
        (5.450, "hit_medium_02.wav",   0.0),
        (6.200, "destroy_01.wav",      0.0),
        (7.100, "hit_medium_03.wav",   0.0),
        (7.520, "hit_heavy_02.wav",    0.0),
        (7.920, "death_04.wav",        0.0),
        (8.450, "summon_02.wav",       0.0),
        (9.050, "hit_heavy_03.wav",    0.0),
        (9.450, "death_01.wav",        0.0),
        (10.250, "fight_win.wav",      0.0),
    ]
    for t_s, fname, g_db in seq:
        fpath = os.path.join(OUT_DIR, fname)
        if not os.path.exists(fpath):
            continue
        w, _ = sf.read(fpath, dtype="float64")
        w = w * (10.0 ** (g_db / 20.0))
        pos = int(round(t_s * SR))
        end = min(n_fight, pos + len(w))
        if end > pos:
            fight[pos:end] += w[:end - pos]
    fo = int(0.05 * SR)
    fight[-fo:] *= 0.5 + 0.5 * np.cos(np.linspace(0.0, np.pi, fo))
    if measure_true_peak_4x(fight) > -1.2:
        fight = soft_clip(fight, ceil=10.0 ** (-1.6 / 20.0))
    fight_path = os.path.join(AUDITION_DIR, "fight_wave2_12s.wav")
    write_wav_16bit(fight_path, fight)

    for p in (show_path, fight_path):
        x, _ = sf.read(p, dtype="float64")
        print(f"Audition: {os.path.relpath(p, REPO_ROOT):34s} | dur={len(x)/SR:5.2f}s | M400={measure_m_max(x, 0.4):6.2f} | TP={measure_ffmpeg_tp(p):5.1f} dBTP")


def main():
    parser = argparse.ArgumentParser(description="Generate Bramble Wave 2 combat SFX.")
    parser.add_argument("--audition", action="store_true", help="Also generate gitignored audition reels in .copies/audition/")
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)
    jobs = [
        ("hit_blocked_01.wav", lambda: synth_hit_blocked(0), -17.0),
        ("hit_blocked_02.wav", lambda: synth_hit_blocked(1), -17.0),
        ("hit_blocked_03.wav", lambda: synth_hit_blocked(2), -17.0),
        ("death_01.wav",       lambda: synth_death(0),       -16.5),
        ("death_02.wav",       lambda: synth_death(1),       -16.5),
        ("death_03.wav",       lambda: synth_death(2),       -16.5),
        ("death_04.wav",       lambda: synth_death(3),       -16.5),
        ("destroy_01.wav",     lambda: synth_destroy(0),     -15.0),
        ("destroy_02.wav",     lambda: synth_destroy(1),     -15.0),
        ("summon_01.wav",      lambda: synth_summon(0),      -18.0),
        ("summon_02.wav",      lambda: synth_summon(1),      -18.0),
        ("summon_03.wav",      lambda: synth_summon(2),      -18.0),
        ("trigger_01.wav",     lambda: synth_trigger(0),     -21.0),
        ("trigger_02.wav",     lambda: synth_trigger(1),     -21.0),
        ("trigger_03.wav",     lambda: synth_trigger(2),     -21.0),
        ("fight_win.wav",      synth_fight_win,              -16.0),
        ("fight_lose.wav",     synth_fight_lose,             -17.5),
        ("fight_tie.wav",      synth_fight_tie,              -18.5),
    ]

    print(f"{'File':20s} | {'dur':5s} | {'onset':6s} {'pk':6s} {'rise':5s} | {'<150':4s} {'mid':4s} {'>1.5k':5s} | {'M400':6s} {'M200':6s} {'TP':6s} | {'clip':4s}")
    print("-" * 108)
    for fname, fn, target in jobs:
        path = os.path.join(OUT_DIR, fname)
        sig = fn()
        m400, m200, tp = calibrate_m400_tp(sig, path, target_m400=target, max_tp_db=-1.2)
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
