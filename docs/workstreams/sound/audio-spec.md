# Bramble Audio Spec & Implementation Guide

*Status: Draft v4 (21 Nov 2026) — Wave 1 (combat hits) accepted in-game and merged to `dev` (PR #239). Wave 2 (rest of fight: blocked, death, destroy, summon, trigger, win/lose/tie) is generated and ready to wire. Wave 3 (shop & UI) comes next.*

## 1. Layout, Format & Loudness Standard

- **Game assets & cue table (`sound/files` owns):**
  - `assets/audio/sfx/*.wav` — finished `48 kHz`, `16-bit` mono PCM `.wav`
  - `assets/audio/sfx/SOURCES.md` — verbatim CC0 licences + per-file sample provenance
  - `assets/audio/cues.json` — data-driven cue table (thresholds, gains, pitch ranges, polyphony, overlap rules)
  - `tools/sound/generate_hits.py`, `tools/sound/generate_wave2.py` — deterministic generators (excluded from Windows export)
  - `docs/workstreams/sound/audio-spec.md` — this spec
- **Engine (`sound/engine` owns):** `src/sound/` and screen hooks.
- **Onset:** Every combat action cue (`hit.*`, `death`, `destroy`, `summon`, `trigger`) starts within **`1.6–2.9 ms`** of file start (well under the `5 ms` budget). Fire directly on the visual contact/event frame — no lead-time offset needed.
- **Single loudness meter (`M400_max`):** Ungated ITU-R BS.1770 K-weighted Maximum Momentary Loudness over a `400 ms` sliding window (computed reproducibly via `pyloudnorm`'s K-weighting filter).
  - *Why not integrated LUFS (`ffmpeg loudnorm` / gated BS.1770)?* On short one-shots, ITU-R BS.1770's `-10 dB` relative gate drops the second overlapping `400 ms` block on fast-decaying hits while keeping it on heavier low-end tails, creating a hidden `~2.0 dB` loudness jump. `M400_max` is ungated, repeatable to `±0.05 dB`, and independent of silence padding.
- **True Peak ceiling:** Strictly `<= -1.2 dBTP` (verified via `ffmpeg loudnorm`). Zero digital clips.

## 2. Combat Multi-Hit, Destroy & Simultaneous-Death Rules

From `sound/engine` telemetry, a hit step has **2 hits 74% of the time** (attacker + defender trading), 1 hit 21%, 3 hits 5%, and 4–7 hits rarely (cleave/area).

- **1–2 normal (non-blocked) hits on the same frame (95% of attacks):** Play **one single hit** at the **heaviest damage weight** (`0 ms`, `0.0 dB`).
- **Shield block (`blocked == true`, 0 damage):**
  - `fight.hit.blocked` is **strictly for shield-blocked hits**, never for destroys.
  - If a 2-hit clash has one normal hit and one shield block, play the damage hit at `0 ms` (`0.0 dB`) and `fight.hit.blocked` at `+15 ms` (`-3.0 dB`). If all hits in the step are blocked, play `fight.hit.blocked` once at `0 ms`.
- **Outright destroy (removed with no damage number, not a shield):**
  - Play **`fight.destroy`** (`hit_weights.destroy_cue` in `cues.json`) instead of `fight.hit.heavy`.
  - If a destroy step is immediately followed by a separate death step on the next frame/pass for that unit, the death step still works fine (or can be suppressed for a destroyed-only pass if it feels redundant in play — check by ear in the build).
- **3–7 hits on the same frame (cleave/area, 5% of steps):** Sort by damage descending and play **at most 3 hits** with distinct takes at `+0 ms` (`0.0 dB`), `+28 ms` (`-4.5 dB`), and `+58 ms` (`-7.0 dB`).
- **Simultaneous deaths (`simultaneous_deaths` in `cues.json`):** Units of one pass die together (15-frame shrink/fade).
  - 1 unit dies → play 1 take of `fight.death` at `+0 ms` (`0.0 dB`).
  - 2+ units die in the same step → play **at most 2** distinct takes at `+0 ms` (`0.0 dB`) and `+55 ms` (`-4.5 dB`). Never stack 3–7 deaths on one frame.
- **Round-end cadence (`fight.win` / `fight.lose` / `fight.tie`):** Fire once when the fight outcome banner/result appears (`max_voices: 1`).

## 3. Wave 1 — Accepted & Merged: Combat Hits (`assets/audio/sfx/`)

| Cue | Files (5 takes each) | Damage Dealt | Target `M400_max` | `volume_db` | Pitch Range | Gain Jitter | `max_voices` | `min_gap_s` |
|---|---|---|---:|---:|---|---|---:|---:|
| `fight.hit.light` | `hit_light_01..05.wav` | `1–4` (~25%) | `-17.0 LUFS` | `0.0 dB` | `[0.977, 1.023]` | `±0.5 dB` | `4` | `0.025` |
| `fight.hit.medium` | `hit_medium_01..05.wav` | `5–13` (~55%) | `-16.0 LUFS` | `0.0 dB` | `[0.980, 1.020]` | `±0.5 dB` | `4` | `0.025` |
| `fight.hit.heavy` | `hit_heavy_01..05.wav` | `>= 14` (~20%) | `-15.0 LUFS` | `0.0 dB` | `[0.983, 1.017]` | `±0.5 dB` | `4` | `0.025` |

## 4. Wave 2 — Ready Now: Rest of Fight (`assets/audio/sfx/`)

| Cue | Files | Length | Onset | Target `M400_max` | `volume_db` | Pitch Range | `max_voices` | `min_gap_s` | Notes |
|---|---|---:|---:|---:|---:|---|---:|---:|---|
| `fight.hit.blocked` | `hit_blocked_01..03.wav` | 0.36 s | `2.5 ms` | `-17.0 LUFS` | `0.0 dB` | `[0.975, 1.025]` | `3` | `0.025` | Chunky leaded-glass & metal shield deflect (`blocked == true`) |
| `fight.death` | `death_01..04.wav` | 0.44 s | `2.2–2.3 ms` | `-16.5 LUFS` | `0.0 dB` | `[0.975, 1.025]` | `3` | `0.045` | Oak-and-glass card crack + descending drop (`~9/fight`) |
| `fight.destroy` | `destroy_01..02.wav` | 0.54 s | `2.4–2.5 ms` | `-15.0 LUFS` | `0.0 dB` | `[0.980, 1.020]` | `2` | `0.060` | Heavy dark Ladder-5 slam + glass shatter (outright destroy) |
| `fight.summon` | `summon_01..03.wav` | 0.34 s | `2.0–2.5 ms` | `-18.0 LUFS` | `0.0 dB` | `[0.975, 1.025]` | `3` | `0.050` | Tactile woodland card arrival thunk + leaf flutter (`~1/fight`) |
| `fight.trigger` | `trigger_01..03.wav` | 0.24 s | `2.4–2.9 ms` | `-21.0 LUFS` | `0.0 dB` | `[0.990, 1.010]` | `2` | `0.080` | Delicate D-pentatonic stained-glass glint (`~8/fight`; narrow pitch range keeps musical harmony) |
| `fight.win` | `fight_win.wav` | 1.15 s | `12.0 ms` | `-16.0 LUFS` | `0.0 dB` | `[1.0, 1.0]` | `1` | `0.500` | Warm D-major woodland harp & stained-glass victory cadence |
| `fight.lose` | `fight_lose.wav` | 1.10 s | `16.7 ms` | `-17.5 LUFS` | `0.0 dB` | `[1.0, 1.0]` | `1` | `0.500` | Gentle descending D-minor woodland sigh (not a buzzer) |
| `fight.tie` | `fight_tie.wav` | 0.80 s | `10.5 ms` | `-18.5 LUFS` | `0.0 dB` | `[1.0, 1.0]` | `1` | `0.500` | Clean neutral two-note open-fifth chime |

## 5. Planned Wave 3 — Shop & UI *(Next, after Wave 2 is heard)*

Hover over cards stays **silent**. Turn-start gold/trigger bursts collapse to at most 1 sound per cue.

- `shop.play` (4 takes, `-16.5 LUFS`) — chunky leaded-glass + oak card thunk onto board (`3.3/turn`)
- `shop.buy` (3 takes, `-18.0 LUFS`) — crisp coin clink + solid card pickup (`2.7/turn`)
- `shop.sell` (3 takes, `-18.0 LUFS`) — brighter double coin drop (`1.4/turn`)
- `shop.refresh` (3 takes, `-18.5 LUFS`) — brisk wooden/parchment tile shuffle (`0.8/turn`)
- `shop.discover_pick` (2 takes, `-17.5 LUFS`) — clean glass/wood selection chime (`1.0/turn`)
- `shop.freeze` (2 takes, `-19.0 LUFS`) — cool crystalline glass/frost lock click
- `shop.tier_up` (1 take, `-15.5 LUFS`) — rewarding upward chime + oak thump (`0.4/turn`)
- `shop.triple` (1 take, `-14.5 LUFS`) — celebratory leaded-glass shimmer + warm chord (`~1/game`; suppresses `shop.buy`, `shop.play`, `ui.click` for `0.65 s` and ducks others `-4 dB`)
- `shop.error` (2 takes, `-19.0 LUFS`) — soft blunt wooden thud (refused action)
- `ui.card_pickup` / `ui.card_drop` (2 each, `-21.0` / `-19.0 LUFS`) — light tactile lift & settle
- `ui.click` (3 takes, `-22.0 LUFS`) — tiny soft wood/glass button tick (`<0.08 s`)
- **Music:** Deferred until SFX are in and signed off.
