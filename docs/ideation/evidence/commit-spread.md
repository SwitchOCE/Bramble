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
