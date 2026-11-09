# Harness follow-up, 9 November 2026

This implements the follow-up review and the orchestrator's calls in
`ideation/main:docs/ideation/DECISIONS.md`, “Harness follow-up review: calls”.
No card content or combat rule changed.

| Lever build | Candidate against blind Hard | Mean placement gain | 95% seed-cluster interval | Lobby wins |
|---|---|---:|---|---:|
| g25 | Hedgerow tempo policy | +0.59375 | [+0.36644, +0.82106] | 114/160 |
| g25 | Frozen tribal mixture | −0.57813 | [−0.79811, −0.35814] | 71/160 |
| g50 | Hedgerow tempo policy | +0.68750 | [+0.42678, +0.94822] | 107/160 |
| g50 | Frozen tribal mixture | −0.52188 | [−0.70312, −0.34063] | 77/160 |

Each comparison used exactly 80 fresh independent seeds and 160 swapped-seat
lobbies, with unchanged committed profiles. Shop comparisons are unpaired. g25
combines caps off, a 25% engine, answers/keywords, economy and hero/spell scaling;
g50 uses a 50% engine and adds the doubler. The best policy includes its frozen
shared-fast fallback when Hedgerow folk are absent.

Both best-policy tests pass. The orchestrator's pre-result call opens general
reads; mixture losses do not veto engine/tribe reads. Losing lines' observations
are labelled lower bounds from weak play, never adverse card-content results.
Both mixtures lose on placement and lobby wins; the earlier capped-pool
high-variance description is not pre-applied here.

[Full four-way gate](../../../tools/sim/evidence/lever-build-strength-gate.json),
[per-line qualifications](../../../tools/sim/evidence/lever-read-qualifications.json).

1. **Attribution:** both the historical flat-shape ruling and the mechanics merge
   are credited to the orchestrator in HARNESS.md.
2. **A falsifiable real null:** `check()` applies identical tail, lobby-win and
   field bars to engine and null. The engine must pass all; the null must fail
   every one. Actual null: 0/8 R6 tails, 1/8 wins, 45.13% field points. Actual
   engine: 8/8 tails, 8/8 wins, 97.00% field points. The additional null/reference
   field used 32 boards, two seeds per orientation, 1,984 fights in 14.118 seconds.
   Inert-definition and byte-equivalent real-body controls remain; a do-something
   card labelled null is rejected. [Current check](../../../tools/sim/evidence/real-null-dominance-result.json).
3. **Committed drivers:** the three supervisor drivers are archived byte-for-byte
   under [evidence/drivers](../../../tools/sim/evidence/drivers/README.md), matching
   their sealed hashes. They retain their original paths/APIs and are historical,
   not quietly migrated executable workflows. The new designed-run driver is
   committed before execution and does not auto-commit its outputs.
4. **Curvature and phase:** 2,000 deterministic whole-seed bootstrap draws preserve
   every seed's seats, legs and surviving rounds. Current post-start baseline:
   relative RMSE 0.03028 [0.02637, 0.03482], late/early growth ratio 1.4412
   [1.3714, 1.5588]. Its point flat check fails the unchanged ratio bar. The
   review's historical pre-start curve is 1.1875 [1.1250, 1.2581], with relative
   RMSE 0.01289 [0.01119, 0.01678]; its point passes but its ratio interval crosses
   1.25. All 35,564 post-start observations from 500 original seeds are supported.
   These are pooled survivor-median curves, not proof of within-player
   compounding; survival and opponent Start of Combat effects can bend them.
   [Values, medians and source hashes](../../../tools/sim/evidence/baseline-curvature.json).
5. **Simplification:** `line_tune` and the unused local sweep executor/CLI are
   removed. Portable shards remain the active runner; shared analysis/report
   helpers remain. The full 3,508,136-byte progress JSON is an exact deterministic
   313,762-byte gzip archive, with a compact summary and hashes. Forced-dose R6
   medians (+1/+4/+16/+64) are 56/94.5/228.5/803.5 against population medians
   46/48/48.5/45; the engine step reads these as dose-to-size calibration.
   [Summary and archive hashes](../../../tools/sim/evidence/review-run-summary.json).
6. **Missing negative tests:** each weak-engine bar fails independently; a
   do-something null fails; exactly one passing lever build fails the gate in
   either direction; each curvature half fails with the other half passing.
   The 15% compounding positive control remains.
7. **Designed generator:** `designed_setups.py` writes the existing designed-input
   schema with complete config/slots/rules/hero state. Parameters cover R6/9/12/15,
   numeric board totals (typical 52/150/500/1,700; strong 1.4×), 1–7 bodies,
   carry/even allocation, Shield, Damage Reduction 2 and Cleave, and one fixed
   biggest-enemy or adjustable percentage answer. Bodies are neutral Mouse
   tokens; keyword grants copy existing lever mechanics, and answers use existing
   lever cards. Total Attack+Health includes every 1/1 support and printed 3/3
   answer. Carry keywords sit on the carry; even-board keywords sit on all stat
   holders. Keyword copies and gold costs are not matched, and these are fixed
   possibilities, not claims about shop attainability.
8. **First designed field:** the frozen experiment has 32 setups per round at
   R9/R12/R15: two totals × two distributions × four keyword profiles × answer
   absent/present. The full round robin uses 64 independent seeds per pair, both
   orientations, for 190,464 fights. Two additional 768-fight fields cover the
   owner's large-number example and its below-clamp ratio analogue. Outcomes and
   intervals are recorded after execution below.

The literal owner example is 3×500M/500M against one 2.1B/2.1B. This engine clamps
each stat at 1B, so that carry realizes 1B/1B. The generator rejects over-clamp
requests by default; the explicit boundary mode records requested and realized
values separately. The below-clamp analogue uses 3×500/500 versus 2,100/2,100,
with/without a separate 3/3 biggest-enemy answer. It preserves the large-body
ratio without claiming the literal 2.1B fight is representable.

To create a custom setup:

```sh
python3 tools/sim/designed_setups.py board --round 12 --total 500 --bodies 7 --distribution carry --keywords shield cleave --answer percent --answer-percent 25 --out build/sim/custom-designed.json
```

Use `make_document([make_board(...), ...])` for custom fields. The frozen first
experiment is reproducible, at its recorded source revision, with:

```sh
source /opt/bramble/env.sh
python3 tools/sim/evidence/drivers/run_designed_first.py
```

The driver verifies source/input/field hashes, runs one Godot at a time under the
harness lock, 3G memory scope and timeout, and archives per-seed results. Win-rate
intervals are conservative two-sided 95% Hoeffding bounds over independent
paired-seed observations. Orientations count as one cluster. They describe combat
RNG for these exact boards/layouts; they are not player-board population intervals
or simultaneous family bounds. Draws are reported separately from strict wins.

For custom paired fields, give setups unique identifiers and keep the common
`config` and `answer_percent` identical on every board, including boards without
an answer. Each unit's allocated stats split evenly, with an odd point going to
Health. The first field uses one fixed blind layout (carry first, answer last),
not a searched or claimed optimal layout.

The 52/150/500/1,700 checkpoints are the requested constructed target scale;
they are not relabelled as measured Battlegrounds medians. The reference-curve
comparison motivates the scale experiment, while these exact inputs remain
explicit design parameters.

Designed input totals are fixed before Start of Combat. Answer-induced stat
losses are the intended intervention; boards are not retuned afterward to erase
that effect. This differs from the lobby strength/curvature reader's explicitly
post-start measurement phase.

## Designed outcomes

All **192,000 fights** completed in **975.7 seconds** including imports,
validation and archiving. The 190,464-fight factorial field took 962.9 seconds;
the boundary and ratio-analogue fields took 6.4 and 6.5 seconds.

At R12's typical 500-stat total, strict carry-win rates were:

| Keywords on stat holders | Neither has an answer | Only wide has an answer |
|---|---:|---:|
| None | 50.8% [33.8%, 67.8%] | 0.0% [0.0%, 17.0%] |
| Cleave | 92.2% [75.2%, 100.0%] | 0.0% [0.0%, 17.0%] |
| Damage Reduction 2 | 100.0% [83.0%, 100.0%] | 0.0% [0.0%, 17.0%] |
| Shield | 0.0% [0.0%, 17.0%] | 0.0% [0.0%, 17.0%] |

These are distribution-and-keyword-copy comparisons, not equal keyword-cost
comparisons: wide boards have one keyword copy on each stat holder, while the
carry has one. In particular, the Shield result is not evidence that Shield is
weak. An enemy answer removes half the carry's concentrated stats; its effect on
one of many wide holders is much smaller.

The below-clamp 500/2,100 analogue makes the owner's point directly on this engine:
the single 2,100/2,100 carry wins **100.0% [83.0%, 100.0%]** against three
500/500s without answers, but **25.0% [8.0%, 42.0%]** when the wide board adds
one 3/3 biggest-enemy answer. This is conditional on the fixed layout, including
that extra answer's slot; it does not establish an optimal layout. At the literal
clamp boundary, three 500M/500M bodies beat the carry that actually realizes
1B/1B: carry wins **0.0% [0.0%, 17.0%]** even without answers. The literal result
cannot be described as a simulated 2.1B/2.1B carry.

- [All R9/R12/R15 equal-total cells and intervals](designed-screen.md)
- [Below-clamp owner-ratio analogue](designed-analogue.md)
- [Actual clamp-boundary cases](designed-boundary.md)
- [Frozen plan and source/input hashes](../../../tools/sim/evidence/designed-first-plan.json)
- [Run counts, runtimes and result/archive hashes](../../../tools/sim/evidence/designed-first-progress.json)
- [Complete factorial pair results](../../../tools/sim/evidence/designed-screen-result.json.gz)

Trials are archived as deterministic gzip JSONL, preserving each paired seed and
orientation counts. No observed outcome changed the declared setups or sample.

## Verification

The final shared-lock, 3G full gate passes **1,697 tests and 29,037 assertions**; strict GUT checks pass. All **117 Python harness tests** pass using disk-backed temporary storage after shared `/tmp` quota exhaustion on the first repeat. Seven isolated in-memory mutation probes are all caught: each engine bar bypass, an either-build gate, each curvature half removed, and null bars always accepted. All designed archives reconstruct the committed reports exactly, budgets total 192,000 fights, and the final simulation source fingerprint matches the frozen plan.

[Verification and log hashes](../../../tools/sim/evidence/harness-followup-verification.json) · [Mutation evidence](../../../tools/sim/evidence/followup-mutation-checks.json). No pushes, merges or denied actions. All requested items are complete; the engine clamp is an explicit limit, not a changed rule.
