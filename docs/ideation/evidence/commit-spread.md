# Pinned spread after the commitment package

The owner requested a 1,000-game pinned-strategy spread on `b872a6b`, using cores **0 and 1**, detached, with a hard **two-hour** timeout. The requested bar is **at least five strategies winning 6–25% of their seats, with none above 25%**. A Bird text/number proposal is conditional on the larger sample establishing a weak Bird line; the Nest idea stays unchanged.

## Run and reproducibility

- Gameplay head: `b872a6bf82963245c303ed99122284922a2f523d`.
- Started: **7 Nov 2026, 18:41:18 UTC / 8 Nov, 05:41:18 Melbourne**.
- Output: `build/sim/commit-b872a6b-spread/`.
- Seeds: **61000–61999**, two disjoint 500-game shards; each shard is individually pinned to CPU 0 or CPU 1.
- Absolute hard deadline: **20:41:18 UTC / 07:41:18 Melbourne**.
- Initial smoke: one complete real game, exit 0, 9.5 seconds; all pinned strategies eligible for the actual lobby.
- At the first useful progress estimate, 47 completed games implied approximately **20:11 UTC / 07:11 Melbourne** completion. This is an estimate; `progress.json` refreshes it every minute.

The detached host tmux socket is `bramble-commit-spread`; its session is `commit-b872a6b`. The job pane runs:

```sh
timeout --signal=TERM --kill-after=15s 7200 bash \
  build/sim/commit-b872a6b-spread/job.sh \
  build/sim/commit-b872a6b-spread
```

The outer timeout covers both shards and report generation. Its TERM handler kills the shard PIDs and records failure. A separately detached [absolute-deadline guard](../../../tools/sim/commit_spread_guard.sh) verifies the owned timeout leader (process group 625129) and sends SIGKILL to that group at exactly 20:41:18 UTC if it remains alive. This makes the two-hour CPU ceiling strict even if a child ignores TERM; it does not restart or alter any game. The job body is [commit_spread_job.sh](../../../tools/sim/commit_spread_job.sh). The `progress` tmux window runs the lightweight reporter pinned to cores 0–1, exits on completion/failure or the same absolute deadline, and does not start more games. Sandboxed background processes did not survive their launcher; the real host tmux launch was approved and verified alive through subsequent independent tool calls.

The output contains `manifest.json`, `started.utc`, `finished.utc`, `status`, `shards.pid`, per-shard logs/CSVs, merged `spread.*.csv`, `progress.json`, `requested-report.md`, and round/card diagnostics. The frozen `snapshot/` is a `git archive` of the baseline, not another worktree. `baseline-verification.json` checks all **542 tracked `src/core/` and `content/` files** against their baseline Git blobs: **zero mismatches**. Later portrait commits cannot change the running game rules, card numbers, bots or data.

## Corrected measurement, unchanged gameplay

The stock spread suite can pin a strategy whose tribe was excluded from that seed's five-tribe lobby. That would confound an unavailable build with a weak build, particularly when investigating Birds. The measurement-only [commit_spread.gd](../../../tools/sim/commit_spread.gd) inherits the existing bench and:

1. Uses the baseline session's own deterministic lobby draw for that seed.
2. Filters available strategies before the original seeded spread shuffle and seating.
3. Asserts the actual game draws exactly that lobby and every pin is eligible.
4. Preserves the real five-tribe rule, all baseline gameplay, bot heuristics, shop odds and card data.
5. Flushes CSVs and logs after every finished game, so partial progress and ETA are observable.

The stock readable report retains its separate 2,000-game standard. [summarize_commit_spread.py](../../../tools/sim/summarize_commit_spread.py) produces an explicit **PENDING / PASS / FAIL** for this owner's **1,000-game** bar, with no confidence-interval relaxation of the thresholds. It also reports pick share, win rate and Wilson intervals, placement and placement intervals, tier-six reach, final units/stats, and whether a Bird line is clearly separated as weakest. Round/card diagnostics retain every strategy, not just Birds.

To inspect progress independently:

```sh
python3 tools/sim/summarize_commit_spread.py build/sim/commit-b872a6b-spread
```

## Birds and dominance: pending the full sample

The earlier 30-lobby result (Birds 18.75% of choices, 5.711 place) came from freely chosen builds, not these pinned cohorts. Do not transfer its placement directly to a specific pinned Bird strategy. Interim spread rows are provisional; neither a dominant strategy nor a weakest Bird line is established by a small early sample.

The completion report compares all strategies and all three Bird lines. The weakest-Bird flags require the complete requested sample and nonoverlapping 95% placement intervals; raw rates and intervals remain visible even when no flag fires. The recorded round stats are **recruit-board** stats; they exclude fighting mirror Eggs and Belly releases, so low recruit stats alone are not evidence that the Nest body is lost. If a Bird line is convincingly weak, inspect its round survival, tier timing, card uptake, flight/return incentives and spell opportunities, then propose the smallest specific numeric or text change. No gameplay fix or Nest change is applied while this baseline runs.

### Provisional Bird diagnosis and conditional proposal

At **87 completed games**, Summer and Winter had 29 seats, 1 win (3.45%) and 5.931 mean place (95% interval 5.172–6.690). Passage had 28 seats, no wins and 5.607 place (4.818–6.397). Highway Robbery had 39 seats, 6 wins (15.38%) and 4.333 place (3.553–5.113). Summer and Passage intervals overlap: **no unique weakest Bird build is established**.

At round 10, Summer and Highway both averaged 6.83 recruit-board units, but Summer had 85.3 Attack+Health against Highway's 98.3. These are survivor/recruit cohorts, not a measurement of fighting mirror Eggs. A provisional hypothesis is thin rotation bodies, rather than an empty-Nest problem; it remains unproven by these interim rows.

**Proposal only, conditional on the full spread confirming Summer is weak:** Old Tern **1/3 → 1/4**, with the natural golden +2 Health. Trip length, return Discover, flight restrictions and the Nest idea stay unchanged. Costing's approximate 7.8 stat-point estimate would rise to about 8.8, roughly +10% over tier-three V=8; that is an unverified estimate, and one Health may be too small. No card, bot or gameplay data is changed and no comparison bench is substituted for the requested baseline.

## Checks and commit scope

- Real-game smoke: one complete eligible pinned lobby, exit 0; the detached shards continue to assert valid seating.
- Baseline verification: 542 gameplay/data files match `b872a6b`.
- GDScript formatting/lint, ShellCheck and explicit Ruff lint/format pass.
- Three meaningful report checks pass: a partial sample cannot claim success; a balanced 1,000-game fixture passes; a dominant-strategy fixture fails.
- Bench setup/reporting is committed separately from portraits. No push, gameplay tuning, changed strategy weight, or changed Nest rule is included.


## Final 1,000-game pinned spread on b872a6b

Gameplay `b872a6bf82963245c303ed99122284922a2f523d`; 1,000 games, seeds61000–61999, cores0/1. Finished2026-11-07T20:15:52Z. Each pin was eligible for its actual five-tribe lobby. Frozen code/data verified before launch.

**Requested spread bar PASS:** 19 strategies at6–25% wins, none above25%. Highest win rate: oozes_second_helpings (22.286%).

| Strategy | Seats | Wins | Win% (95% Wilson) | Place (95% interval) | Tier6 reach% |
|---|---:|---:|---:|---:|---:|
| neutrals_low_roll | 424 | 91 | 21.462 (17.82–25.62) | 3.300 (3.098–3.501) | 4.245 |
| fairies_hag | 359 | 54 | 15.042 (11.72–19.11) | 3.674 (3.464–3.884) | 63.231 |
| fairies_rainbow | 393 | 52 | 13.232 (10.23–16.94) | 3.799 (3.601–3.997) | 62.341 |
| hedgerow_parish | 360 | 78 | 21.667 (17.72–26.21) | 3.856 (3.618–4.093) | 36.389 |
| oozes_second_helpings | 350 | 78 | 22.286 (18.24–26.93) | 4.023 (3.774–4.272) | 28.000 |
| hunters_pact | 363 | 70 | 19.284 (15.56–23.66) | 4.110 (3.873–4.347) | 40.220 |
| bog_bitter | 361 | 48 | 13.296 (10.18–17.19) | 4.175 (3.942–4.407) | 28.809 |
| bog_borrowed | 364 | 45 | 12.363 (9.37–16.14) | 4.209 (3.986–4.432) | 28.571 |
| hunters_sett | 394 | 48 | 12.183 (9.31–15.78) | 4.353 (4.128–4.577) | 27.919 |
| fairies_help | 374 | 50 | 13.369 (10.29–17.19) | 4.374 (4.154–4.594) | 46.791 |
| oozes_rude_awakening | 385 | 46 | 11.948 (9.08–15.57) | 4.382 (4.165–4.599) | 29.610 |
| bog_tongues | 365 | 51 | 13.973 (10.79–17.91) | 4.466 (4.235–4.696) | 23.836 |
| fairies_rings | 378 | 23 | 6.085 (4.09–8.96) | 4.529 (4.332–4.727) | 47.090 |
| birds_highway | 403 | 41 | 10.174 (7.59–13.51) | 4.568 (4.346–4.790) | 23.573 |
| hunters_open_season | 375 | 59 | 15.733 (12.40–19.76) | 4.592 (4.352–4.832) | 32.000 |
| hedgerow_treasury | 387 | 25 | 6.460 (4.41–9.36) | 4.793 (4.581–5.005) | 43.411 |
| oozes_waste_not | 366 | 35 | 9.563 (6.96–13.01) | 4.828 (4.605–5.051) | 38.251 |
| neutrals_economy | 422 | 55 | 13.033 (10.15–16.58) | 4.893 (4.664–5.122) | 54.502 |
| neutrals_purse | 456 | 37 | 8.114 (5.94–10.98) | 5.667 (5.448–5.885) | 39.912 |
| birds_passage | 362 | 9 | 2.486 (1.31–4.66) | 5.680 (5.480–5.879) | 25.691 |
| birds_summer_winter | 359 | 5 | 1.393 (0.60–3.22) | 6.106 (5.915–6.296) | 10.306 |

## Birds

Summer and Winter is the weakest mean placement in this completed pinned sample:6.106 (5.915–6.296), against Passage5.680 (5.480–5.879) and Highway Robbery4.568 (4.346–4.790). The place intervals do not overlap the next-worst upper endpoint, satisfying the predeclared conservative place-interval flag. Win-rate intervals are reported separately; no multiplicity-adjusted causal claim is made.

| Build | Round | Seats reaching | Recruit units | Recruit stats | Tier | Gold left |
|---|---:|---:|---:|---:|---:|---:|
| birds_highway | 3 | 403 | 3.474 | 14.156 | 1.64 | 0.496 |
| birds_highway | 5 | 403 | 6.33 | 32.032 | 2.161 | 0.841 |
| birds_highway | 8 | 403 | 6.787 | 67.757 | 3.179 | 1.407 |
| birds_highway | 10 | 374 | 6.773 | 93.561 | 4.104 | 1.04 |
| birds_highway | 12 | 243 | 6.815 | 122.436 | 4.481 | 1.132 |
| birds_highway | 15 | 100 | 6.93 | 154.74 | 5.9 | 0.44 |
| birds_passage | 3 | 362 | 3.472 | 14.138 | 1.652 | 0.522 |
| birds_passage | 5 | 362 | 6.094 | 30.282 | 2.528 | 0.619 |
| birds_passage | 8 | 362 | 6.807 | 62.169 | 3.912 | 1.508 |
| birds_passage | 10 | 307 | 6.788 | 88.016 | 4.505 | 1.195 |
| birds_passage | 12 | 154 | 6.786 | 108.909 | 5.266 | 0.805 |
| birds_passage | 15 | 24 | 6.792 | 135.833 | 6 | 0.5 |
| birds_summer_winter | 3 | 359 | 3.476 | 13.705 | 1.618 | 0.518 |
| birds_summer_winter | 5 | 359 | 6.045 | 29.387 | 2.12 | 0.802 |
| birds_summer_winter | 8 | 359 | 6.755 | 62.591 | 3.053 | 1.195 |
| birds_summer_winter | 10 | 286 | 6.71 | 88.633 | 4.045 | 0.902 |
| birds_summer_winter | 12 | 118 | 6.797 | 116.602 | 4.958 | 0.983 |
| birds_summer_winter | 15 | 23 | 6.913 | 156.826 | 6 | 0.217 |

Recruit-board stats exclude fighting mirror Eggs and Belly releases. Lower recruit stats alone do not prove empty Nests or missing combat bodies. These are descriptive survivor cohorts, not paired assignments of the same opening to different strategies.

Final-card uptake (selected survivor cohorts):

birds_summer_winter: mrs_stork 176, mr_redbreast 156, great_lump 147, old_tern 105, wee_wobbly 97, mrs_dunnock 94, one_swallow 81, lodger 73, old_brock 68, chiffchaff 66

birds_passage: mrs_stork 213, mother_goose 143, great_lump 133, jack_daw 122, mr_redbreast 103, wee_wobbly 93, old_brock 88, seven_whistlers 80, gabble_ratchet 75, belladonna 73

birds_highway: mag_pye 296, jack_daw 295, mrs_dunnock 153, tom_tit 136, belladonna 93, old_brock 92, great_lump 90, wee_wobbly 89, seven_whistlers 87, lodger 80

The previous minimal proposal (Old Tern1/3→1/4, natural golden+2Health) remains a candidate, not a measured fix here. The completed baseline supports investigating thin rotation bodies/reward timing; the later D experiments are separate gameplay and are not part of this old spread. No Nest change or gameplay patch is inferred from this report alone.
