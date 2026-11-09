# Scope review: ideation/c-gameprofile (49366332..12f2aab2)

**Inputs:** I had all three: the target, the owner's words (2026-11-10a) and the approved plan text (step 3). No verdict depends on a missing input.

- **Counts:** keep 7, cut 0, simplify 0, ask 0.
- **Does it move the original problem?** Yes, a little. On the single measured run each side, the tests step went from 418 s to 390 s (-7%), and a Hard lobby got 11.4% faster. The bigger result is the diagnosis: about 1,400 quiet search fights per Hard lobby are 75-78% of its time. That points step 4 at its real lever, fewer or shared Hard lobbies. The suite is still slow: 390 s now against 69 s on 7 Nov, and step 4's target is a 25% cut.
- **Cut and ask items:** none.

I did not run Godot. Local Godot runs compete for the shared lock that is the owner's problem, and Claude's Godot work is routed to the cloud. So I took the timing and hash numbers from the evidence files. I checked that each fast path keeps behaviour the same by reading the code, for all inputs, not just the 12 seeds.

---

## Part 1: PR report (facts)

**Commits**
- aaf38843 "Combat hot path: cheaper health reads, Hex-percent and Ring fast paths, cached slot tables"
- 12f2aab2 "Game profile: ... lint order fix": the evidence, plus the static vars moved above the functions for gdlint's order rule

**Size:** 16 files, +325 / -5.
- Source: 5 files, +33 / -5.
- Evidence: 11 files, +292.

### 7. Internal machinery

**I1. Health reads compute the golden factor inline**
- **What:** `_raw_health` and `_get_health` now compute `2 if golden else 1` themselves instead of calling `golden_factor()`. `_get_health` also repeats the `_raw_health` sum instead of calling it. (`src/core/board_unit.gd:113-115`, `:128-132`)
- **Used by:** every `health` read. The profile shows 1.48M reads per lobby, mostly from death checks. `_raw_health` is now called only by `set_aura` and `_get_max_health`.
- **Stated reason:** plan step 3: "Any fix leaves fight results and event hashes identical on 12 seeds". That permits a fix. The commit message describes this particular one.

**I2. `Combat.hex_percents_used` flag and an early return in `hex_loss`**
- **What:** a new public bool on Combat (`src/core/combat/combat.gd:65-66`), set by `CombatScale.add_hex` (`src/core/combat/combat_scale.gd:9`). `hex_loss` returns 0 while the flag is false (`combat_scale.gd:27-30`).
- **Used by:** `Combat._slot_bonus` → `hex_loss` (`combat.gd:804`). That runs for every unit on every aura recalculation: 195k calls per lobby.
- **Stated reason:** as in I1.

**I3. Early return in `CombatRings.bonus`**
- **What:** returns `Vector2i.ZERO` when the slot has no effects (`src/core/combat/combat_rings.gd:29-30`).
- **Used by:**
  - `Combat._slot_bonus` (`combat.gd:801`)
  - after wave 2a, also `Pass3RowSwap.improves_ring`
- **Stated reason:** as in I1.

**I4. Cached typed copies of the slot tables in BoardGeometry**
- **What:**
  - Three `static var` tables, built once by the new `_int_rows` from the `const` tables ADJACENT, IN_FRONT and BEHIND (`src/core/board_geometry.gd:32-35`, `:164-168`).
  - `adjacent`, `in_front_of` and `behind` return `row.duplicate()` of the cached row (`:50-62`).
- **Used by:** `neighbours`, `named_slot`, `empty_adjacent` and about 98 call sites across src (at 2fa5247f).
- **Stated reason:** as in I1.

### Evidence (docs only)

**E1. `docs/ideation/evidence/test-suite/game-profile/README.md`**
- **What:** the time breakdown, the hot path, the fix, the results, and what would speed things up further.
- **Used by:** the orchestrator's merge decision, this review, and step 4's ranking.
- **Stated reason:** criterion 1, "The hot path is named with its share of time."

**E2. `probe/hashes.gd.txt`, `probe/lobby.gd.txt`, `probe/top.py`**
- **What:**
  - the 12-seed hash and timing probe
  - the phase breakdown probe
  - the profiler-output sorter
- **Used by:** they were used to make `raw/*`; nothing runs them now. The `.gd.txt` extension keeps Godot from importing or compiling them. `top.py` is outside ruff's scope (`ruff.toml` includes only tools/checks and tools/audio), like other evidence scripts.
- **Stated reason:** criterion 2.

**E3. `raw/*`: nine output files**
- **What:**
  - breakdown-before
  - hashes before and after
  - check before and after
  - script profile before and after
- **Used by:** E1, and this review.
- **Stated reason:** criteria 1 and 2.

### None
- Schema and data
- Scheduled and background
- Features (no visible behaviour change)
- External
- Config
- Public interfaces (apart from the `hex_percents_used` field, listed under I2)
- Deleted (`_ints` stays and `_int_rows` uses it)

**Unrequested:** nothing marked "none stated" or "nothing yet". The fix items rest on the plan's "Any fix ..." clause.

---

## Part 2: Interrogation

### Classification
- **In scope:**
  - the profile and hot-path naming (E1, E3)
  - the behaviour-preserving fix (I1-I4)
  - the 12-seed hash check (E2, E3)

  All three are plan step 3, and they fit the owner's "a smarter, more performant test suite".
- **Supports scope:** the probes (E2). Without them, criterion 2 can't be reproduced.
- **Outside scope:** nothing.
  - No rules, numbers, bot budgets, tests, plan files or status files are touched.
  - The "lint order fix" only moves I4's static vars.
  - Time box: the base was committed at 20:35Z and the last commit at 21:10Z, inside the 90 minutes.

### Does each fast path behave exactly as before, for all inputs?

**I1 (health): exact.**
- `golden` is a typed bool, and `golden_factor()` is `2 if golden else 1` (`board_unit.gd:56`).
- No subclass overrides it. I checked CombatUnit and RecruitUnit, the only `extends BoardUnit`.
- The arithmetic is the same, in the same order, so even overflow behaves the same.
- `_get_attack` already inlined the factor at base.
- **Note:** the golden rule is now written out three times (`_raw_health`, `_get_attack`, `_get_health`) as well as in `golden_factor()`. A future rule that changes golden doubling has to change all four. The `_raw_health` copy is off the hot path and could go back to `golden_factor()`, but either way the effect is small.

**I2 (Hex-percent flag): exact today.**
- `combat_scale.gd:8` is the only writer of `hex_percent_*` notes in src and tests, and it sets the flag on the next line, before it emits or recalculates.
- Every fight builds a fresh Combat (`combat.gd:88`; `board_search.gd:207`; `game_session.gd:22`).
- No code clears, copies or assigns `notes`.
- With no note, the old code computed `StatFraction.part(x, 0)` = `maxi(0,x) * 0 / 100` = 0. `attack_before_auras` has no side effects.
- Zero or negative percents set the flag and take the old path, so the result is the same.
- **Inputs that would differ:**
  - any future code that writes a `hex_percent_S_N` note without going through `CombatScale.add_hex`;
  - a Combat built with `notes` already filled in.

  Neither exists at 12f2aab2 or at 2fa5247f.
- **Guard:** `tests/core/test_scale_mechanics.gd:189-195` expects 7500 Attack after a 25% Hex. If the flag were never set, that test would fail with 10000.

**I3 (Ring): exact for all inputs.**
- With `effects` empty, `BoardUpkeep.ring_stats([])` is ZERO (`board_upkeep.gd:234-241`). The Horseshoe loop does nothing, `has_weakened` stays false, and the old code returned `total`, which is ZERO.
- The return comes after the `shy` check, as before.
- The skipped code has no side effects (`units_of` is reached only when something is weakened).

**I4 (slot tables): exact for all inputs.**
- The sources are `const`, so the cache can never go stale.
- Each call returns `duplicate()`, so a caller that mutates its result (`neighbours` appends and sorts) can't change the shared rows.
- Negative slots wrap the same way in both versions (`ADJACENT[-1]` and `_adjacent_ints[-1]` are both row 6). Slots of 7 or more error in both.
- `duplicate()` keeps the `Array[int]` type. If it didn't, the typed return would fail at runtime, and 1,910 tests pass.
- Nothing in src, tools or tests uses threads, so the shared static arrays are never read concurrently.
- No code outside `board_geometry.gd` touches the `_*_ints` tables.

### Interaction with wave 2a (2fa5247f)
- **Overlap:** wave 2a does not touch `board_unit.gd`, `board_geometry.gd`, `combat_rings.gd`, `combat_scale.gd`, `board_upkeep.gd` or `stat_fraction.gd`. Its `combat.gd` hunks don't overlap this change's two-line addition.
- **Trial merge:** `git merge-tree --write-tree 2fa5247f origin/ideation/c-gameprofile` merges cleanly.
- **Hex notes:** wave 2a adds no `hex_percent_*` writer. Its new notes keys are all `bog_*` and `hunter_*`.
- **Hot path:** wave 2a adds work to the same hot path, which these edits neither fix nor break:
  - `Pass3BogCombat.sync_hopkin` in `CombatAuras.recalc`, `_choose_attacker` and `_side_can_attack`
  - Hunter hooks in `enter_board`
- **Rings:** wave 2a's `Pass3RowSwap.improves_ring` calls `CombatRings.bonus` twice per row pair. It changes `unit.slot` temporarily, but `bonus` is pure, so I3 stays exact there.
- **What is unmeasured:** the timing gain and the 12-seed hashes were measured on 4936633, before wave 2a. The equivalence argument above doesn't depend on wave 2a.

### Item questions
- **I2: who reads the flag, and what breaks if it's deleted?**
  - Only `hex_loss` reads it.
  - Deleting the flag brings back about 195k string formats per lobby, with no change in behaviour.
  - Keeping Hex percents in their own dictionary, like `hexes`, would remove the coupling with the notes key, but it's a bigger change and isn't needed now.
- **I4: why not use what exists?** `_ints` re-typed the const rows on every call: 550k calls per lobby. GDScript can't declare nested typed const arrays, so built-once static rows are the plain way to do this.
- **E2: who reads the probes, and when?**
  - Nobody runs them now.
  - They are how you would recheck criterion 2 on the merge, or on any later engine speedup.
  - The README says what each one is for.

### Does it fully do the in-scope thing?

**Criterion 1 is met.** `raw/breakdown-before.txt` shows fights at 13,962 ms of 18,553 ms (seed 1, 75%) and 14,332 of 18,285 (seed 2, 78%). The README then breaks fight time down:
- death resolution: about 44% (`_rd` 7.0 of 16.1 s)
- aura recalculation: about 26% (4.2 s)
- `units_of`: about 15% (2.37 s)

The numbers match the profile.

**Criterion 2 is met on paper:**
- `raw/hashes-before.txt` and `raw/hashes-after.txt` have the same `fight_hash` and `log_hash` for all 12 seeds.
- The seed 1 and 2 log hashes also match `breakdown-before.txt`.
- My code reading shows the result can't differ for any seed.

### Gaps and corrections
- **README figure:**
  - **The problem:** the "script self-time fell by 19%" figure counts the temporary timers' own cost. The before profile ran on an instrumented `combat.gd`: functions sit 11-17 lines lower than at 4936633, and `Combat._rd` appears. It includes `BotProfile._charge` (0.31 s), `BotProfile.enter` (0.15 s, 192k calls) and `_rd` (0.32 s). None of these appear in the after profile.
  - **The fix:** without them, the drop is about 14%. The README mentions the timers but not their size. One sentence would fix it.
  - **What to trust instead:** the -11.4% wall time over 12 seeds, which was measured without the profiler.
- **Timing samples:** the 418 → 390 s tests step comes from one run each side, on a 4-core cloud machine. Seed 6 got slightly slower (13,009 → 13,092 ms). Neither is a criterion, so report the numbers as rough. The gain on ideation/main after wave 2a (498 s tests step) hasn't been measured.
- **Optional test:** no test checks that changing a result of `adjacent()`/`behind()` leaves the next call unchanged. It would guard against someone "optimizing" away the `duplicate()`. It's a one-line test and optional.
- **Optional recheck:** on the merge commit, the normal cloud gate is enough. Re-running `probe/hashes.gd.txt` on the merge (about 6 minutes in the cloud) would only be belt-and-braces, given the code-level proof.

### Table

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| I1 health inline | keep | `board_unit.gd:113-132`; `golden_factor` not overridden; same arithmetic | Optional: put `_raw_health` back on `golden_factor()` (off the hot path) |
| I2 `hex_percents_used` | keep | only writer `combat_scale.gd:8-9`; fresh Combat per fight `combat.gd:88`; `part(x,0)=0`; guarded by `test_scale_mechanics.gd:189-195` | none |
| I3 Ring early return | keep | `combat_rings.gd:29-30`; `ring_stats([])` = ZERO `board_upkeep.gd:234-241` | none |
| I4 slot-table caches | keep | `board_geometry.gd:32-35,50-62,164-168`; const sources; `duplicate()`; no threads | Optional: a test that changing a result doesn't poison the cache |
| E1 README | keep | criterion 1; numbers match `raw/*` | Fix the 19% sentence (about 14% without the timers' cost) |
| E2 probes | keep | reproduce criterion 2; `.gd.txt` stays out of Godot's compile | none |
| E3 raw outputs | keep | evidence for criteria 1 and 2 | none |

- **Cut:** none.
- **Simplify:** none required. Optionally, `_raw_health` could call `golden_factor()` again, leaving one copy fewer of the golden rule.
- **Gaps:** see above: the README's 19% figure, timings from single runs and before wave 2a, the optional cache-mutation test, the optional hash rerun on the merge.
- **Original problem:** it moves it a little. The tests step is about 7% faster and a Hard lobby 11% faster, with identical results. More important, it shows that the per-game cost is the Hard search's roughly 1,400 quiet fights per lobby, not a regression to bisect. That points step 4 at fewer or shared Hard lobbies. The suite isn't fast yet: about 390 s against 69 s on 7 Nov.

### Open questions (the orchestrator's call on ideation)
1. **The search budget.** The README's biggest lever is Hard's 20-fight search budget: halving it roughly halves a lobby. It changes Hard's choices, so it's a bot-behaviour decision with re-pins, not a pure speedup. The question is whether tests and sims that don't test Hard's choices should run a cheaper search, decided in step 4 or later.
2. **The "10x slower" question.** The README puts the gap down to a config difference: the 7 Nov soak seated half its players on random SoakBots and ran the 53-card slice. It didn't measure this; the plan allowed skipping the bisect once the profile named a path. One Hard lobby timed at a 7 Nov commit would settle it. The question is whether to accept the explanation or pay for that one run.
