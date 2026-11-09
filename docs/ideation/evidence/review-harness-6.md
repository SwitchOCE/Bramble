# Scope review 6: ideation/harness a7dceac9..2c16ee0a

Everything below was read from committed revisions only (`git show`, `git diff`, and `git archive` of 2c16ee0a). Scope sources are the owner's words and plan v3, the same as in earlier reviews; none were missing. The DECISIONS entries on ideation/main are the orchestrator's calls, so I treat them as proposals.

**Counts:** 9 keep, 0 cut, 2 simplify, 4 ask.

**Does it move the original problem?** Yes, on the measurement side. The growth criterion (lobby median ×1.3 per round, R8 to R14, pre-start boards) is now measured at the shipped five-tribe config on one set of seeds:
- Shipped: ×1.301 [1.290, 1.312]. That sits right at the 1.3 line, and the interval falls on both sides of it.
- Preset B: ×1.420.
- Preset C: ×1.795.

This range changes no game code, and it does not touch the other deciding criterion (logged progress moments).

**Clear to merge into ideation/main:** yes. There are no cut items. It is not a fast-forward, because ideation/main has 18 docs commits since a7dceac9, but no file is changed on both sides and `git merge-tree --write-tree ideation/main 2c16ee0a` is clean.

**Ask items:**
1. **Rebase source not fully stated.** The rebase doc doesn't say that harness files and a `bot_pass3` adapter were copied onto source d5b5b4f8. It also records `harness_commit` 6358dd7, a commit that sits on no branch; its bytes equal 5c54cb5d. Add one sentence and point it at 5c54cb5d.
2. **Bans refuse a card; they don't remove it.** The banned card still takes a shop slot for that seat, so a "keystone-removed low roll" comes out slightly weaker than a real one. Either say so wherever low rolls are reported, or remove the card from that seat's offers.
3. **One bad trial aborts the whole run.** A single forced grant or summon of a banned card fails the entire run, with no resample. Decide before the head runs whether to keep that or to drop the trial and report it.
4. **A test depends on a commit only ideation/wave2a holds.** `tests/sim/test_wave1_archive_compatibility.py` needs commit d5b5b4f8, and the rebase evidence cites it. Tag it, or make the test skip when the commit is missing. Otherwise deleting that branch breaks the test and loses the cited source.

## Answers to the five questions

**1. Did the review 5 follow-ups land?** Yes.
- The second classification is gone (`r12_built_timing_inside_same_band` deleted from `tools/sim/wave1_accounting_report.py`).
- The config sentence is in `docs/ideation/evidence/wave1-accounting.md` word for word, and the Homecoming R12 cell now reads "False (config-sensitive)".
- Bot-run rules and advisory notes are split (`tools/sim/line_policies.gd:16` `BOT_RULE_KEYS`, `:37` `ADVISORY_KEYS`), with the table printed in HARNESS.md.
- The shipped rerun ran in two settings on the same 320 seeds (4610b2d7).
- Each committed line plays only in lobbies with its tribe. That is done by keeping lobbies whose native five-tribe draw includes Birds and Fairies, and the docs disclose it as the calibration population.

**2. Are the measurements sound?** Yes, apart from ask 1.
- **Same seeds:** shipped, checkpoint, B and C use an identical 320-seed list. The shipped and rebase probes have the same 421 eligible seeds and the same tribe draws.
- **Phases labelled:** pre-start and post-fight figures are in separate tables, and human comparisons use post-fight only.
- **Intervals:** whole-seed bootstrap.
- **Recomputed:** from the committed board archives I got growth 1.301 / 1.303 / 1.420 / 1.795 and R12 medians of 311 (shipped Homecoming) and 367 / 359 / 401.5 / 306 (B). All match the docs.
- **Temp source copy:** the adapter imports only `best_flight` and the `court` expression. Their defaults are the native values (from_round 3, keep_home 3, line_court false). So blind Hard seats play exactly as at d5b5b4f8, which the diff of d5b5b4f8 against 5c54cb5d confirms. The gap is only what the doc says (ask 1).

**3. Is the forced carry-flight line a fair skilled ceiling?** It uses legal moves only and changes no rules, but it is one fixed rule, not a ceiling.
- **Legal and native:** it asserts `not is_choosing() and HeldUnits.flies(unit)`, flies through the native `_rules.sell`, and asserts the trip became a real native trip (`tools/sim/skilled_birds_brain.gd:51-58`).
- **Control matches:** the control arm reproduces 613 historical pre-start snapshots exactly.
- **Not a ceiling:** each turn's first flight is the biggest legal Bird. That overrides the line file's own from_round, keep_home_min, omen and max_away rules and the native danger guard (`tests/core/test_skilled_birds.gd:29`). Later flights are native.
- The evidence doc itself says "one skilled decision, not optimal human play". "Ceiling" is the orchestrator's word in the "Birds: no nerf" entry.

**4. Do the bans remove the card for that seat only and reject contaminated trials?**
- They refuse rather than remove (ask 2). HARNESS.md says this plainly.
- The ban applies to that seat only, and other seats can still buy the card.
- Contaminated trials are rejected:
  - the brain observes buys, swallows, choices, summons and triples (`tools/sim/line_brain.gd:120`);
  - the runner writes `ban_violation` (`tools/sim/wave1_baseline.gd:331`);
  - Python rejects any audit showing a banned card owned, played or acquired, or a failure (`tools/sim/wave1_baseline.py:157`, `:375`).
- **Supplemental native check, run:** under `/tmp/bramble-godot.lock` on an archive of 2c16ee0a, 26/26 tests passed with 324 asserts. That covers `test_line_bans.gd` (8), `test_skilled_birds.gd` (6) and `test_wave1_lines.gd` (12), including `test_acquisition_audit_keeps_native_bypass_violation_after_card_has_left`.
- **Python suite:** 192/193 pass. The one error is the d5b5b4f8 lookup (ask 4); it fails only because an archive copy has no git history.

**5. Anything gold-plated?** Two small things, both under simplify:
- The same seated-line check is written four times.
- The plan and probe files repeat per-seed tribe lists and source manifests.

The range adds 85,296 lines across 107 files, mostly evidence JSON.

## Table

| Item | Verdict | Evidence | Action |
|---|---|---|---|
| Review 5 follow-ups (f9c924b9) | keep | `wave1_accounting_report.py`, `wave1-accounting.md`, `line_policies.gd:16,37`; asked in "Harness follow-up 5" | none |
| Shipped and checkpoint five-tribe baselines (4610b2d7) | keep | `wave1-shipped-baseline.md`; "shipped rerun at 5 tribes in two settings" (DECISIONS) | Nit: a Homecoming sentence appears twice |
| B/C rebase measurement at d5b5b4f8 (5c54cb5d) | keep | Same seeds, eligibility disclosed, phases labelled; my recomputation matches | none |
| What the rebase doc says about its source | ask | `wave1-rebase.md:5` "use source d5b5b4f8" and `:251` "no other worktree is imported"; the overlay is mentioned only in `wave1-rebase-verification.json:7`; `harness_commit` 6358dd7 is on no branch | One sentence; point it at 5c54cb5d |
| Peat King / Cutter tables by round | keep | Asked in the Bog review (DECISIONS) | none |
| Tribe drift, report only | keep | `wave1-rebase.md:67-69`; read by the Hunters pin-filter call (DECISIONS) | none |
| Provisional C Birds marked superseded (28f917e4) | keep | Rows labelled superseded | none |
| Per-seat bans: audit, fail-closed, schema (8d3d5b78, 7baaa754, 160950f0) | keep | `line_brain.gd:85,97,120,148`, `committed_line_brain.gd:35`, `line_policies.gd:117,140`; proposed by the orchestrator for keystone-removed low rolls, and fits the owner's "journeys with skips" | none |
| Bans refuse rather than remove | ask | HARNESS.md "scripted refusal, not removed from pool/offers" | Disclose where low rolls are reported, or remove the card from that seat's offers |
| One bad trial aborts the whole run | ask | HARNESS.md:890 "exits unsuccessfully; it never silently" resamples | Decide abort or drop-and-report before the head runs |
| Seated-line check written four times | simplify | `wave1_baseline.py:152`, `line_policies.gd:140`, capture reader, native admission | Keep the Python prep check plus one Godot admission check |
| Skilled Birds brain, runner and evidence (2c16ee0a) | keep | `skilled_birds_brain.gd:35-58`; control matches 613 snapshots; proposed by the orchestrator ("skilled-play policies check ceilings") | none (see open question) |
| Repeated per-seed tribe lists and source manifests in each plan and probe | simplify | About 4.5k lines of `tribes` and 850 lines of `source_sha256` per plan; about 5.4k-line probes, four times over | Store once, reference by hash |
| Archive compatibility test needs d5b5b4f8 | ask | `test_wave1_archive_compatibility.py:27`; d5b5b4f8 is reachable only from ideation/wave2a | Tag the commit, or skip the test when it's missing |
| Verification records and the rerun native check | keep | 26/26 GUT; 192/193 Python (the error is environmental) | none |

**Cut:** none.

**Simplify:** the seated-line check (four places down to two), and the plan and probe data duplicated per run (store once, reference by hash).

**Gaps:** No low-roll trial has run yet; the only ban run is a one-lobby smoke test. The first real use is the head measurement after the Hunters merge.

**Open questions for the orchestrator:**
- Is "skilled Birds" the ceiling or one sample of skilled play? If it's a lower bound on skilled play, the "no nerf" call rests on a floor, not a ceiling.
- Shipped growth's interval falls on both sides of the ×1.3 line. Do you plan from B (×1.42)?

Temp copies `/var/tmp/scope-review-h7g` and `/var/tmp/scope-review-h7p` are deleted. Neither worktree was modified.
