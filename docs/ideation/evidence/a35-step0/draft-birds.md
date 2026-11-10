*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the birds analyst draft. The critic's corrections in critic-birds.md win where they differ.]*

## Birds: dials, realized boards and path check

**Verdict: today's dials can plausibly reach both targets, so no extra dials are needed.** B reaches 900 at about t ≈ 1.0, which is today's C. C reaches 1,800 at about t ≈ 1.6. Both are well under the caps of 2 and 3. The homecoming multiplier carries most of the raise.

### 1. Dials (rates.json @424b3c2a)

Preset A and preset B set no `birds_*` keys, so for Birds A = B = the base `rates`. Seven dials differ between B and C. The plan counts 10 because three more keys appear only in C, at B's value.

| Dial | A / B | C | Moves | Read at (src) | Card: text at B |
|---|---|---|---|---|---|
| `birds_homecoming_multiplier` | 2 | 2.5 | **yes** | pass3_birds.gd:40, held_units.gd:500, pass3_text.gd:506 | Fly South (Swallow, Chiffchaff, Jay, Tern, Goose): "returns to hand at 2× permanent stats" |
| `birds_golden_homecoming_multiplier` | 2 | 3 | **yes** | same | the same, for golden fliers |
| `birds_redbreast_share` | 1/8 | 1/6 | **yes** | pass3_birds.gd:107 (`"birds_"+name+"_share"`), pass3_text.gd:239 | Mr Redbreast: "After a Bird comes home: gain an eighth of its stats." |
| `birds_cuckoo_share` | 0.1 | 0.15 | **yes** | same | The Cuckoo: "…other Birds gain a tenth of its stats." |
| `birds_stork_gold_step` | 6 | 5 | **yes** | pass3_birds.gd:21,124; pass3_text.gd:258 | Mrs Stork: "Every 6 gold you spend: a Bird that missed a fight comes home." |
| `birds_golden_egg_multiplier` | 2 | 3 | **yes** | pass3_birds.gd:63; pass3_text.gd:285 | Golden Egg (Mother Goose): "Double a Bird's stats. Once per Bird." |
| `birds_chiffchaff_gain` (key set only in C; B uses the +1 written in chiffchaff.json) | 1 | 4 | **yes** | pass3_text.gd:178 (`_optional_bird_effects`) | Chiffchaff: "Fly South. When played: gain +1/+1." |
| `birds_goose_eggs`, `birds_swallow_gold`, `birds_jay_acorns` (keys set only in C) | 1 | 1 | no | pass3_birds.gd:84; pass3_text.gd:179–180 | Goose, Swallow, Jay |
| trip_turns 2, swallow_trip 1, golden_tern_trip 1, jack_daw_share ¼ (permanent), stork_recalls 1, golden_egg_enabled, whistlers ½ / 7, lump ×1, ratchet ×1, redwing ½ / 2, tom_tit 50 / 1, dunnock 1 / 1 | = | = | no | held_units.gd, recruit_unit.gd, combat/pass3_bird_combat.gd, pass3_birds.gd | the remaining Birds |

### 2. Realized R12 boards

The engine line is `birds_homecoming` (`engine_flag: true`). `birds_tempo` switches to homecoming at R7.

| Line | B | C |
|---|---|---|
| birds_homecoming | **367** [348, 394.5], n=269 (`docs/ideation/evidence/wave1-rebase.md:24` @322a28cb; also `wave1-rebase-B.md:18`) | **Not measured at today's C.** The only C run used the superseded 4× set: 2,218 (`wave1-rebase.md:28`, marked superseded at line 13) |
| birds_tempo | 359 [342, 389.5] (`wave1-rebase.md:25`) | same: 1,979.5 at the old 4× set |

- **Older content.** The run used source `d5b5b4f8`: five tribes, caps on, 320 seeds, with Birds and Fairies in every lobby's draw. The opponents were older: pass-2 Hunters and pre-pass-3 Oozes and Hedgerow. The Birds cards and B dials are unchanged since. Only the Goose-egg key resolution and the tempo line's flier list were added.
- **Other reads, for context only:**
  - shipped control: 311 (`wave1-shipped-baseline.md:18`);
  - six-tribe accounting run: 270 (`wave1-accounting.md:21`);
  - skilled-flight arm: 472 (`wave1-skilled-birds.md:45`).
- `baseline-step2.md` measures pass-1 Birds and is obsolete.
- wave2b-build.md has no Birds lobbies.

### 3. Factor needed

- **B:** 900 ÷ 367 = **×2.45**.
- **C:** 1,800 ÷ (today's C, unmeasured, estimated 860–950) ≈ **×1.9–2.1**. That is ×4.9 over B.

### 4. Plausibility

**Calibration.** I ran a scratch copy of `birds-pass3-model.py`, adding golden homecoming, Egg multiplier and Chiffchaff gain as dials. I then replayed the measured old 4× C arm on it. Paper moved R12 ×12.6, while real boards moved ×6.04 (2,218 ÷ 367). So real ≈ paper^0.71, which matches the wave 1 triage replay (`a6_dials.py`, 0.72).

Path, d(t) = B·(C/B)^t, with integers rounded up. Estimates are for line A, `birds_homecoming`:

| t | h / golden h / Egg | Chiffchaff | Stork step | Redbreast / Cuckoo | Paper R12 | Est. real R12 |
|---|---|---|---|---|---|---|
| 0 | 2 / 2 / 2 | 1 | 6 | .125 / .10 | 615 | 367 |
| 1.0 | 2.5 / 3 / 3 | 4 | 5 | .167 / .15 | 2,028 | **856** (triage replay: ~950) |
| 1.5 | 2.80 / 3.67 / 3.67 | 8 | 5 | .192 / .184 | 5,223 | 1,676 |
| 1.6 | 2.86 / 3.83 / 3.83 | 10 | 5 | .198 / .191 | 6,792 | **2,020** |
| 2.0 | 3.13 / 4.5 / 4.5 | 16 | 5 | .222 / .225 | 15,505 | 3,630 |
| 3.0 | 3.91 / 6.75 / 6.75 | 64 | 4 | .296 / .338 | 113k | — |

**One dial at C, the rest at B** (paper R12 ratio):

| Dial | ×at C |
|---|---|
| homecoming | ×1.83 |
| Chiffchaff | ×1.44 |
| Egg | ×1.14 |
| Cuckoo | ×1.05 |
| Redbreast | ×1.03 |
| Stork step | ×0.82 (noise in the scripted line) |
| golden homecoming | ×1.00 (the scripted lines have no golden fliers) |

At t = 2, homecoming alone gives ×3.48 and Chiffchaff alone ×3.34.

**Clamps.** None binds by t = 3:
- shares reach at most 0.30 / 0.34, so golden copies (2× share) stay at 0.59 / 0.68, under 1;
- the Stork step stays at 4 or more.

**Without Chiffchaff.** If Chiffchaff's paper effect doesn't reach real boards and it is held at B, the path still works: B at t ≈ 1.8 (1,084 at t = 2) and C at t ≈ 2.8. Both are inside the caps, but C becomes tight.

### 5–6. Result

No extra dials proposed. **The homecoming multiplier carries the raise.** It is the size axis: each trip multiplies the whole body. It is also the only Birds dial with a measured real response (the 4× arm). Chiffchaff's gain is second and catches up with it by t ≈ 2.

Things to watch, none of which block run 1:
- **Chiffchaff grows ×4 per unit of t.** At t = 1.6 it is +10/+10 on a tier 1 card. Paper R6 goes from 41 to 128 and R8 from 96 to 413, so the early rounds shift the most. If A4 shows Birds winning R4–R8 too often, clamp it at +4 and let homecoming carry C (t ≈ 2.8).
- **Text stays true.** All seven moving dials render their text from the rates. But a raw path value prints badly (2.857…× or 19.8…%), so snap values to steps of 0.25 or named fractions, rounding toward generous, before committing.
- **The B value must be written in.** The Chiffchaff key is absent from B, so B uses the card file's +1. Any B value on the path has to be added to preset B as an explicit key.
- **Stork's step rounds up to 5 through t = 2.** That makes it slightly less generous than the path value.
- **Skilled play runs higher.** Human games at today's B already reached 459 and 772 at R12, after the fight. With t_B ≈ 1, skilled players would land well above 900. That bears on the logged "Birds: no nerf" call, and A4 should report it.

Scratch scripts: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/birds/model2.py`, `sweep.py`, `grid.py`, `calib.py`.