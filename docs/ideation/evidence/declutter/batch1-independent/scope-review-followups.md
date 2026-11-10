**Scope check: declutter batch 1 follow-up fixes (`d400831e..cea9d0e2` on `ideation/declutter`, 13 commits)**

*[Saved by the orchestrator from the reviewer's final message, verbatim.]*

The brief gave all three inputs: the target, the owner's words (09e), and the approved plan text (the two 10 Nov DECISIONS entries on ideation/main). I changed nothing, checked nothing out and did not run Godot.

**Counts:** 23 keep, 1 cut, 0 simplify, 2 ask.

**Does it move 09e? Yes.** It removes the two things the last check found standing on the board: the kept-gain reserve column and the Toll badge. The lunge goes back to the depth readers already passed. Every new mark fades within about 1.1 s. At rest after the fight there are no ancillary labels (`test_combat_wave2a.gd:98`, `:166`). In the Bog shots, ancillary labels drop from 1–3 to 0–2 per frame.

**Cut**
- **The DECISIONS.md entry on the branch.** It is pasted inside the Format line's code span (`docs/ideation/DECISIONS.md:5-15`), which breaks the Format instruction. It mostly repeats main's two entries. A 3-way merge with ideation/main applies it with no conflict, so the broken line would land unnoticed. Drop the hunk.

**Ask**
- **`c4c0b174` makes the next attack wait for the last stat cue to finish** (`combat_screen.gd:438`). The barrier goes from 0.15 s to 0.75 s plus the stat delay, in real seconds at every speed. Measured at ×1: +0.53 s and +1.57 s on the two reshot fights; the Bog fight is +16% at ×4. DECISIONS asked w4 only to *check* cue lag. Keep the wait, or end the old cues when the next attack starts?
- **The Bog "before" was shot on `d400831e`, which is already decluttered**, not on the pre-batch screen with wave 2a's word chips. So the pair shows badge versus no badge, not the wave 2a port itself. Plan step 3 asks for per-batch before/after. Accept it as is, or replay the saved fight on the pre-batch UI?

**Gate blocker (not scope, but it will stop the merge)**
- **gdlint fails** with `tests/ui/test_combat_declutter.gd:863: Error: duplicated loading of "res://src/ui/widgets/combat_attack_cue.gd" (duplicated-load)`. The same file already preloads it at `:497`. `d400831e` passes. `scripts/check.sh` step_lint runs `(cd tests && gdlint .)`. The follow-up note says "Formatting/lint … pass". Fix: one `const AttackCue := preload(...)` at the top of the file.

---

## 1. PR report (facts)

**Schema, scheduled, external, config, public interfaces:** none.

**Features**

- **F1. Kept gain lands, then fades (`8472e643`).**
  - What: the portrait shows 0.35 s after the gain is sent, holds 0.55 s, fades over 0.15 s and is freed (`combat_special_motion.gd:76-106`). There is one spot per side (`:35`). A new landing hides other kept portraits on the same side (`:88-97`).
  - Used by: `_permanent_reward` (`combat_motion.gd:542`) and `WaveMotion._pending` (`combat_wave_motion.gd:52`).
  - Stated reason: DECISIONS, "the portrait fades. No column stays beside the board."
- **F2. Repeated gain to the same portrait restarts its hold (`5aedf076`, plus the guard in `6e389277`).**
  - What: kills the previous landing tween; a generation counter stops an old fade from freeing the new one (`:77-83`, `:103-105`).
  - Used by: F1.
  - Stated reason: the branch DECISIONS entry, "Repeated gains … need explicit lifetime cleanup" (the worker's line).
- **F3. Skip to end creates no kept portrait on either path.**
  - What: `combat_motion.gd:529`, `combat_wave_motion.gd:33`. `_toll` also returns when not animating (`:56`).
  - Stated reason: DECISIONS, "Skip to end shows no reserve, for both paths."
- **F4. The kept portrait reads `portrait_id`** (`combat_special_motion.gd:39`).
  - Stated reason: DECISIONS gaps.
- **F5. Only joint attacks get the deeper lunge** (`combat_motion.gd:231`, `0.85 if _joiners.is_empty() else 0.35`).
  - Stated reason: DECISIONS ask 1.
- **F6. Toll is a transient cue.**
  - What: the badge is removed. A splash travels to the hero centre and pulses it (`combat_wave_motion.gd:55-74`). The hero reader keeps the total.
  - Stated reason: DECISIONS ask 2.
- **F7. Restart resets the plaque's tint and scale** (`combat_screen.gd:243-245`, `7489c19a`).
  - Used by: replay during a Toll pulse.
  - Stated reason: none in DECISIONS. It supports F6.
- **F8. Counter clears its stored target on the answering unit's next attack** (`combat_motion.gd:31`, `:124-126`, `:391`, `:853`).
  - Stated reason: DECISIONS gaps.
- **F9. Pounce hands over the attack frame and sends a red sword** (`combat_motion.gd:552-563`, `:854-855`). The lunge comes from the attack event that follows (snap).
  - Stated reason: DECISIONS (fourth cold reader).
- **F10. Mire wait draws a line to its target.**
  - What: a moss Line2D appears at 0.12 s, is visible 0.43 s, fades over 0.15 s and is freed (`combat_special_motion.gd:539-565`).
  - Stated reason: same DECISIONS entry.
- **F11. Stats barrier (`c4c0b174`).**
  - What: `_effect_remaining` goes from 0.15 s to 0.75 s plus the stat delay (`combat_screen.gd:436-439`). `_source` now prefers the target itself when it is one of the sources, so the self-loop delay of 0.47 s applies (`combat_motion.gd:306`, `:387`).
  - Used by: the next `attack` and `mire_wait` in `advance_playback`.
  - Stated reason: DECISIONS says only "w4 also checks whether cues lag behind their events." The wait itself: none stated by the orchestrator.

**Internal machinery**
- **I1. `_out_of_turn_answer`** (`combat_motion.gd:552`). Two users, Counter and Pounce, which are the only two `queue_attack` kinds (`bog_folk.gd:62`, `combat_hunt.gd:119`).
- **I2. Bog capture tooling** (`tests/ui/shots/declutter_bog_*`): a fixture generator, two frame runners, two shell wrappers and an assembler. It reuses `declutter_frames.gd` and asserts the 10-label cap on every frame (`declutter_bog_strips.py:27`).

**Evidence:** `strips/bog-followup/` (before/after at ×1, ×4 and reduce; 3 named moments), `strips/narrow-followup/` (rival 025 plus adjacent 033, combat_mid 045, at ×1 and reduce), the cold-reader reshoot answers and score, follow-up note Part 5, and `process-history.md`.

**Tests:**
- New file `test_combat_cue_lifetime.gd` (3 tests).
- `test_combat_wave2a.gd`: 4 tests added, 2 rewritten.
- `test_combat_declutter.gd`: 3 tests added, 1 flipped.

**Deleted:** the Toll badge (Panel, glyph and number), the stacked kept-gain columns, and Pounce's gold spark.

**Unrequested:** F11's wait; F2 and F7 (supporting); the branch DECISIONS entry.

**Size:** 56 files, +13,974/−131. Most of it is manifests and JPEGs. The code is 4 source files (+204/−100 across `src`) and 4 test files.

## 2. Verdicts

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| F1 kept gain fades | keep | Freed by about 1.05 s; tests `test_combat_declutter.gd:398`, `test_combat_wave2a.gd:52` | none |
| F2 refresh and guard | keep | Without it, the first fade hides the second landing; test `wave2a.gd:200` | none |
| F3 skip to end | keep | Test `wave2a.gd:166` (end of test) | none |
| F4 `portrait_id` | keep | `special_motion.gd:39` | no test (gap) |
| F5 joint-only lunge | keep | `combat_motion.gd:231` | no test (gap) |
| F6 transient Toll | keep | Test `wave2a.gd:98`: no badge, travels to hero, pulse, freed, reader total, both motion modes | none |
| F7 plaque reset | keep | Test `wave2a.gd:218` | none |
| F8 Counter clear | keep | Test `declutter.gd:819`; fails on the old code (stale sword at 0.7 s) | none |
| F9 Pounce handoff | keep | Test `declutter.gd:851` | fix the lint failure at `:863` |
| I1 shared answer helper | keep | 2 real users | none |
| F10 Mire line | keep | Test `declutter.gd:884`; freed by 1.0 s, inside the 0.9 s barrier and hold | none |
| F11 stats barrier wait | **ask** | Probe 3 | Keep the wait, or end old routes at the next attack |
| `test_combat_cue_lifetime.gd` | keep | Fails on the old 0.15 s barrier; it checks that no cue survives into the next attack, not how that is achieved | none |
| 2 flipped persistence tests | keep | As DECISIONS directed | none |
| Many-kept-gains cap test | keep | 14 recipients, ≤ 10 labels on every tick, both motion modes | none |
| Repeated-gain test | keep | — | none |
| Toll and restart tests | keep | Removed font-fit checks were for the removed badge | none |
| Zero-gain Counter, Pounce, Mire tests | keep | — | — |
| I2 Bog capture tooling | keep | Needed for DECISIONS ask 3 | none |
| Bog before/after strips | **ask** | `capture-report.json`: "Before d400831e" | Accept, or add a pre-batch before |
| Narrow reshoot strips | keep | 033 is labelled context: the Pounce attack (event 33) opens the next window | none |
| Cold-reader reshoot files | keep | Verbatim input | none |
| Follow-up note and process history | keep | One false claim (lint passes) | Correct it |
| Branch DECISIONS.md entry | **cut** | Probe 5 | Drop the hunk |

## 3. Probes

**1. Each DECISIONS item, as written, with a test.**
- Done with tests: kept-gain fade; both tests flipped; many-gains cap test; Toll; Counter clear; skip to end; Pounce; Mire line; narrow reshoot.
- Done without tests: joint-only lunge, `portrait_id`.
- Done differently: the Bog shoot (ask).
- "w4 checks cue lag" became the F11 wait (ask).
- Nothing stands after its moment:
  - kept gain freed after about 1.05 s;
  - Toll splash and pulse gone, plaque back to white;
  - Mire line freed after 0.7 s;
  - the Pounce frame is the normal held attacker frame, replaced on the next attack.

**2. The 10-label cap still holds.**
- Many-kept-gains case: `test_combat_wave2a.gd:166` checks 14 gains on every tick for 1.5 s, in both motion modes. It holds because only one kept portrait per side is ever visible.
- Rest state: still tested.
- Captures: the cap is asserted on every saved frame (`declutter_bog_strips.py:27`). Bog after: 0–2 per frame.

**3. `c4c0b174` slows some attacks, not every attack.**
- It adds a wait only where a stat cue's route is still drawn when the next attack would start. In the reshot fights that is 1 of 8 windows (rival), 3 of 11 (combat_mid) and 2 of 4 (Bog). Each such window waits up to 0.6 s more, and the wait doesn't shrink at ×4.
- Measured from the committed manifests (same event streams, fixed 1/120 s ticks):

| Fight | Before | After | Change |
|---|---|---|---|
| rival ×1 | 19.07 s | 19.59 s | +0.53 s (+2.8%) |
| combat_mid ×1 | 25.77 s | 27.33 s | +1.57 s (+6.1%) |
| Bog ×1 | 9.72 s | 9.83 s | +0.11 s (+1.1%) |
| Bog ×4 | 5.64 s | 6.56 s | +0.92 s (+16%) |

  - Reduce motion matches ×1.
  - ×4 for rival and combat_mid is estimated, not measured: +0.71 s (+5%) and +1.78 s (+9%). The estimate comes from a model that reproduces the Bog numbers within 0.02 s.
- **Is it a fix for cue lifetime, or a new delay?** It is a new delay that fits the existing lifetime. The worker's diagnosis checks out: the queue was on time, and the route holds 0.6 s after arrival (`transfer_mote`). The barrier equals that lifetime exactly; the cue itself is unchanged.
- It adds to the ×4 problem DECISIONS deferred to batch 3.
- It covers stat routes only (see the gaps).
- Alternative: fade or free old stat routes when the next attack starts, or scale the hold by speed. That costs no time, and the new test would still pass.

**4. No test was loosened.**
- The flips are the ones DECISIONS ordered.
- The removed Toll font checks tested the removed badge. Budget assertions tightened from 1 to 0.
- The `null` → `-1` source change in the cue-lifetime test is equivalent (`Data.i` returns the default for null), and a lead-time assertion was added beside it.

**5. What the branch DECISIONS entry adds beyond main's two entries:**
- the F11 wait call ("the next attack waits for that lifetime"), logged under "Picked (orchestrator)", though main only asked for a check;
- "Batch 2 is saved as WIP 2474292e until these fixes are committed and merged back", a process note;
- "Repeated gains and interrupted replay need explicit lifetime cleanup", the rationale for F2 and F7;
- a Source line, "orchestrator's explicit follow-up in the batch 2 session", which the repo can't confirm.

  Everything else restates main's entries. It has no Agreed by line.

**6. No owner misattribution.** That covers the commits, the note, the tests and the DECISIONS edit. The only owner reference is "following 09e" in the branch entry's Why line, which cites direction the owner did give.

## 4. Gaps
1. **The gdlint failure** above.
2. **Non-stat routes still overlap the next attack.** In the Bog fight at ×1 (after):
   - The Toll fires at tick 776 and the pending gain at 812. Their routes last 1.1 s, to ticks 908 and 944.
   - Attack 25 starts at tick 872.
   - Frame 2 of `bog-followup/after/bog-x1/attack-025.jpg` still shows the Toll route to the hero while the Vole attacks.

   F11 gates only on `stats` events. This is the same kind of overlap the reader flagged. If the wait is kept, it has to grow to cover these routes too.
3. **No test pins the lunge depth** (0.85 for ordinary attacks, 0.35 for joint).
4. **No test for `portrait_id`** on the kept portrait.
5. **Simultaneous gains on one side all land on a single spot.** Only the last recipient's face shows (`special_motion.gd:88-97`). Minor; it only matters for mass rewards to dead units.

## 5. Open questions (orchestrator's call)
- **F11:** keep the wait, or end old routes at the next attack?
- **Bog before/after:** accept `d400831e` as "before", or replay the saved fight on the pre-batch UI?

## 6. What I ran and didn't
**Ran**
- git log, diff, show and grep on the range.
- Python over the committed manifests, for the tick comparisons and the ×4 estimate. Scripts in the session scratchpad.
- gdformat and gdlint 4.5.0 (the pinned version) on the changed `.gd` files in a temp copy, with the repo's `gdlintrc` and `tests/gdlintrc`.
- ruff and shellcheck on the new scripts. The Python file isn't ruff-formatted, but `ruff.toml` only includes `tools/checks` and `tools/audio`, so the gate doesn't cover it.
- `git merge-file` of DECISIONS.md against ideation/main at `5425c907`, in scratch.
- Looked at 3 frames of the Bog strips.

**Didn't run:** Godot or GUT, so the "62/62" is not verified. I didn't read the newer ideation/main commit `951f7c72` or `ideation/declutter-b2`.
