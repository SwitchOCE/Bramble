# Bramble Audio Spec & Implementation Guide

*Status: Draft v3 (21 Nov 2026) — Agreed with `sound/engine` (Opus) using measured telemetry from 40 bot games (2,018 fights, 3,881 shop turns). Wave 1 (15 combat hit WAVs) is ready for owner audition; Waves 2–3 await owner approval of the cue list.*

## 1. Layout, Format & Loudness Standard

- **Game assets & cue table (`sound/files` owns):**
  - `assets/audio/sfx/*.wav` — finished `48 kHz`, `16-bit` mono PCM `.wav`
  - `assets/audio/sfx/SOURCES.md` — verbatim CC0 licences + per-file sample provenance
  - `assets/audio/cues.json` — data-driven cue table (thresholds, gains, pitch ranges, polyphony, overlap rules)
  - `tools/sound/generate_hits.py` — deterministic generator (excluded from Windows export)
  - `docs/workstreams/sound/audio-spec.md` — this spec
- **Engine (`sound/engine` owns):** `src/sound/` and screen hooks.
- **Onset:** Every combat hit starts within **`1.5–2.5 ms`** of file start (peak `~2.6–3.4 ms`, well under the `5 ms` budget). Trigger directly on the visual contact frame — no lead-time offset needed.
- **Single loudness meter (`M400_max`):** Ungated ITU-R BS.1770 K-weighted Maximum Momentary Loudness over a `400 ms` sliding window (computed reproducibly via `pyloudnorm`'s K-weighting filter in `tools/sound/generate_hits.py`).
  - *Why not integrated LUFS (`ffmpeg loudnorm` / gated BS.1770)?* On `0.36–0.55 s` hits, ITU-R BS.1770's `-10 dB` relative gate drops the second overlapping `400 ms` block on fast-decaying hits (`ladder-3`) while keeping it on heavier low-end tails (`ladder-4`/`5`), causing integrated LUFS to calibrate heavier files `~2.0 dB` hotter at the same reading. `M400_max` is ungated, repeatable to `±0.05 dB`, and independent of silence padding.
- **True Peak ceiling:** Strictly `<= -1.2 dBTP` (verified via `ffmpeg loudnorm`). Zero digital clips.

## 2. Combat Multi-Hit Rule (When 2–7 Hits Land on One Frame)

From `sound/engine` telemetry, a hit step has **2 hits 74% of the time** (attacker + defender trading), 1 hit 21%, 3 hits 5%, and 4–7 hits rarely (cleave/area).

- **1–2 normal (non-blocked) hits on the same frame (95% of attacks):** Play **one single hit** at the **heaviest damage weight** (`0 ms`, `0.0 dB`).
  - *Why (verified by ear in `fight_10s.wav`):* Visually, one attacker bumps one defender once. Stacking two hits on frame 0 causes `+6 dB` low-end doubling/comb-filtering; staggering them by `22 ms` sounded audibly like a snare drum flam (`ba-BAP`) on every normal clash. One crisp impact at the heavier weight syncs cleanly with the single visual contact.
- **Shield block alongside a hit:** If one hit in a 2-hit clash is `blocked` (`0` damage) and the other deals damage, play the damage hit at `0 ms` (`0.0 dB`) and `fight.hit.blocked` at `+15 ms` (`-3.0 dB`). If all hits in the step are blocked, play `fight.hit.blocked` once at `0 ms`.
- **3–7 hits on the same frame (cleave/area, 5% of steps):** Sort by damage descending and play **at most 3 hits** with distinct takes:
  - Hit #1 at `+0 ms` (`0.0 dB`)
  - Hit #2 at `+28 ms` (`-4.5 dB`)
  - Hit #3 at `+58 ms` (`-7.0 dB`)
  - Drop hits #4–#7 so big cleaves read as a distinct rapid triple-crunch cascade instead of brickwalled noise.

## 3. Wave 1 — Ready Now: Combat Hits (`assets/audio/sfx/`)

Anchored on the owner's Round 2 feedback (Ladder 3–5 good; Ladder 4 favorite). Thresholds use **damage dealt** mapped to actual match percentiles (`p25 = 4`, `median = 6`, `p75 = 11`, `p90 = 18`) so **~55% of all hits** land in Ladder 4 (`medium`), ~25% in Ladder 3 (`light`), and ~20% in Ladder 5 (`heavy`).

| Cue | Files (5 takes each) | Damage Dealt | Target `M400_max` | `volume_db` | Pitch Range | Gain Jitter | `max_voices` | `min_gap_s` |
|---|---|---|---:|---:|---|---|---:|---:|
| `fight.hit.light` | `hit_light_01..05.wav` | `1–4` (~25%) | `-17.0 LUFS` | `0.0 dB` | `[0.977, 1.023]` (`±0.4 st`) | `±0.5 dB` | `4` | `0.025` |
| `fight.hit.medium` | `hit_medium_01..05.wav` | `5–13` (~55%) | `-16.0 LUFS` | `0.0 dB` | `[0.980, 1.020]` (`±0.35 st`) | `±0.5 dB` | `4` | `0.025` |
| `fight.hit.heavy` | `hit_heavy_01..05.wav` | `>= 14` (~20%) | `-15.0 LUFS` | `0.0 dB` | `[0.983, 1.017]` (`±0.3 st`) | `±0.5 dB` | `4` | `0.025` |

## 4. Proposed Cue List — Waves 2 & 3 *(For Owner Approval Before Building)*

Hover over cards stays **silent** (fires too often). Turn-start gold/trigger bursts collapse to at most 1 gold clink + 1 soft trigger tick.

| Wave | Cue | Takes | Target `M400_max` | Notes |
|---|---|---:|---:|---|
| **Wave 2: Fight** | `fight.hit.blocked` | 3 | `-17.5 LUFS` | Crisp leaded-glass / shield deflect clink (`damage == 0`) |
| | `fight.death` | 4 | `-16.5 LUFS` | Compact wooden-tile shatter + low drop (`0.35–0.45 s`). Multiple deaths in one pass → play 1 take (or max 2 at `+45 ms`, `-4 dB`), delayed `+35 ms` after lethal hit if same step |
| | `fight.summon` | 3 | `-18.5 LUFS` | Brisk wood/leaf pop-in (`~1/fight`) |
| | `fight.trigger` | 3 | `-20.0 LUFS` | Tiny soft glass spark (`~8/fight`, `<0.22 s`; must stay quiet so it never crowds hits) |
| | `fight.win` / `fight.lose` / `fight.tie` | 1 each | `-16.0` / `-17.5` / `-18.5 LUFS` | Short `0.8–1.2 s` woodland cadences (warm win, muted loss, neutral tie) |
| **Wave 3: Shop & UI** | `shop.play` | 4 | `-16.5 LUFS` | Chunky leaded-glass + oak card thunk onto board (`3.3/turn`, most frequent shop sound) |
| | `shop.buy` | 3 | `-18.0 LUFS` | Crisp coin clink + solid card pickup (`2.7/turn`) |
| | `shop.sell` | 3 | `-18.0 LUFS` | Brighter double coin drop (`1.4/turn`) |
| | `shop.refresh` | 3 | `-18.5 LUFS` | Brisk wooden/parchment tile shuffle (`0.8/turn`) |
| | `shop.discover_pick` | 2 | `-17.5 LUFS` | Clean glass/wood selection chime (`1.0/turn`) |
| | `shop.freeze` | 2 | `-19.0 LUFS` | Cool crystalline glass/frost lock click |
| | `shop.tier_up` | 1 | `-15.5 LUFS` | Rewarding upward chime + oak thump (`0.4/turn`) |
| | `shop.triple` | 1 | `-14.5 LUFS` | Celebratory leaded-glass shimmer + warm chord (`~1/game`) |
| | `shop.error` *(refused action)* | 2 | `-19.0 LUFS` | Soft blunt muted wooden thud (not harsh buzzer) |
| | `ui.card_pickup` / `ui.card_drop` | 2 each | `-21.0` / `-19.0 LUFS` | Very light tactile card lift & settle (distinct from `shop.play` thunk) |
| | `ui.click` | 3 | `-22.0 LUFS` | Tiny soft wood/glass button tick (`<0.08 s`) |

## 5. Overlap & Exclusion Rules

- **`shop.triple` wins the room:** Suppress `shop.buy`, `shop.play`, and `ui.click` for `0.65 s` and duck other active shop SFX by `-4 dB`.
- **`shop.tier_up`:** Suppress `ui.click` for `0.45 s` and duck other shop SFX by `-2 dB`.
- **Simultaneous deaths:** Cap at 1 take per death step (or max 2 staggered `+45 ms`, `-4 dB`), never stacking 3–7 deaths on one frame.
- **Turn-start burst:** Collapse simultaneous turn-start gold + triggers to at most 1 sound per cue (`min_gap_s >= 0.08` on `fight.trigger` / shop gold).
- **Safety limiter:** Transparent limiter on the sound bus (`-1.0 dB` ceiling) as a safety net only, not for loudness crushing.
- **Music:** Deferred until SFX are in and signed off.
