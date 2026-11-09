# Five-tribe wave 1 baseline method

This implements “Harness follow-up 5” and “Wave 1 triage: what we fix” in
DECISIONS.md. The two deciding measures are the pre-start R8–R14 median growth
(all eight seats, with committed-only beside it) and each starting line’s realized
committed R12 median with a whole-seed 95% interval. P90, 2× shares, wins and R14
survival are reported only. No new bands or tail bars are introduced.

The frozen source is `f9c924b9`, whose content is unchanged from the supplied
`ideation/main@a7dceac`; the intervening commit changes loader/documentation
accounting only. `wave1_baseline.gd` is separately hashed measurement
instrumentation over the same GameSession/FightCapture path.

Both settings use `full_game()` and its five-tribe rotation. The shipped setting
leaves caps on; checkpoint changes only `card_size_caps` and `card_rate_limits`
to false. Pass 3 and loop guards stay on, and `content/pass3/rates.json` stays
unchanged. No Birds dial is increased.

The native `GameSession._draw_lobby_tribes()` probes the original accounting seeds
1901001–1901640. Of 640 candidates, 421 naturally contain both Birds and Fairies;
219 lack a focus tribe. The sample is the first **320 eligible seeds**, fixed
before fight outcomes; 101 otherwise eligible seeds are unused. The historical
2.65 s/lobby estimate projects 14.1 min/setting, leaving time for shared-lock
waiting and the full gate below the approximately 30 min/setting ceiling.

Each selected lobby has one Homecoming, one Tempo, one Ring and one Court seat,
plus four blind Hard seats, shuffled by the original accounting seat stream.
This is a five-tribe calibration population **conditioned on both focus tribes**,
not an estimate of unconditional shipped lobbies. Missing tribes are excluded
by the probe, never treated as a bot error. Heroes, damage, eliminations and the
finite shared pool run normally. Both settings use exactly the same seed list;
shop luck is unpaired because purchases and pool use change later draws.

Capture reads active board Attack+Health after initial auras and before Start of
Combat. Eggs count; off-board reserves do not. Every real living seat is retained,
including a seat paired against a ghost. Starting and final lines are separate:
Tempo never becomes a Homecoming observation merely because its R7 policy switched.
Round summaries contain survivors only. “Alive at R14” means present before that
fight. Whole-lobby seed bootstrap draws preserve all seats/rounds and eliminated
empty clusters. Growth is population-median growth, not within-player compounding.

The existing accounting convention supplies `(median_R14/median_R8)^(1/6)`.
There are 2,000 deterministic whole-seed draws, RNG seed 19014531. The line R12
interval has the same seed clusters. Lobby wins are first places/all assigned
seats; combat wins are strict R8–R14 wins/all captured real-seat fights, with
draws not counted as wins.

Both original human Bird logs were checked through their supplied Git refs.
Tester C has 459/883 at R12/R14; tester A has 772/2,085. These sum the post-fight
review-log live board stats (`GameLog.record_round`), whereas the harness uses
pre-start combat snapshots. They are two contextual cases, not a matched-phase
estimate of a skilled-player population. The comparison report gives the actual
Homecoming median beside them. The later skilled-play check uses CURRENT values
and competent carry flight, superseding the proposed Birds C tail check.

## Commands and provenance

`tools/sim/evidence/drivers/wave1-shipped-baseline.sh` records this run’s exact
prepare/run/report commands. It runs detached with logs. Each 20-lobby chunk
writes durable progress and hashes, and gzip-archives its full captured fight
inputs/results. `wave1_baseline.py` verifies source/driver hashes before each
chunk and verifies the actual five-tribe roster and starting labels during parsing.
Every Godot invocation sources `/opt/bramble/env.sh`, has a timeout and a 3 GB
systemd scope. Simulations now hold `/tmp/bramble-harness-godot.lock`; imports,
probes and gates retain `/tmp/bramble-godot.lock`. No Godot processes from this
worker overlap. The user-approved lock change preserved the first 80 accepted
shipped lobbies and resumed at the next chunk, without changing seeds, dials or
native code. `wave1-shipped-resume.sh` records the continuation;
`wave1-baseline-lock-revision.json` and its history archive retain both plan and
driver hashes and the accepted capture hashes.

The reusable interface is:

```sh
python3 tools/sim/wave1_baseline.py prepare --source-tree /path/to/source --commit COMMIT --preset shipped --output build/sim/run --max-lobbies 320
python3 tools/sim/wave1_baseline.py run --plan build/sim/run/plan.json
python3 tools/sim/wave1_baseline.py report --plan build/sim/run/plan.json --out tools/sim/evidence/wave1-run.json --markdown docs/ideation/evidence/wave1-run.md
```

Named future presets such as B and C require `--overrides preset.json`, with
explicit config/rate values; no dials are guessed. Another source worktree,
including its HEAD, is copied with `git archive` under the output directory.
Only this worker’s own current source tree may be played in place. Other
worktrees are neither imported nor modified. Stage 3 will measure the provided `d5b5b4f8` in a separate archive, adding
per-round Peat King Peatlings/fight and Peat Cutter gold/fight, including zero
outcomes and eligible-fight counts. That measurement remains deferred.

`wave1_baseline_compare.py` checks source, dials, cap flags, archive integrity and
identical selected seed lists before rebuilding the combined comparison. The
per-setting JSON and sufficient-analysis gzip archives retain all deciding and
reported measurements. Full capture archives remain in `build/` with hashes in
progress. The combined result/report paths are
`tools/sim/evidence/wave1-baseline-comparison.json` and
`docs/ideation/evidence/wave1-shipped-baseline.md`.

## Completed measurement

Both fixed settings completed all 320 planned eligible lobbies on the frozen game
source. The archived progress lists every accepted chunk and its capture hashes;
all analysis archives, full capture hashes, seed coverage and byte-identical plan
copies were checked before the final comparison. The verification JSON records
the final artifact hashes and the passed 1,896-test / 42,407-assertion full gate
plus 163 Python harness tests after the execution-only lock revision.

Shipped: 740.469 s native Godot execution; 2161.007 s accepted chunk wall time, including shared-lock queueing before the approved lock revision and excluding its interrupted queued attempt.

Checkpoint: 796.518 s native Godot execution; 1214.198 s accepted chunk wall time, including shared-lock queueing before the approved lock revision and excluding its interrupted queued attempt.

`wave1-baseline-execution.log.gz` archives the per-chunk native timing logs.
The approved split-lock revision and the original plans/accepted progress are
retained in `wave1-baseline-lock-revision.json` and its hashed history archive.
No seed, dial, game-source or deciding-measure change accompanied that revision.
