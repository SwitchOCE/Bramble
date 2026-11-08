# Damage v0.5

Pre-registered 2026-11-08, before measurements. Baseline: b99b5ad full_game damage (40 Health, compressed tiers, floor, caps, toll). All arms retain Last Stand/Last Blow. v0.5 replaces toll with round base: toll would double-charge pacing and damage ties, contrary to v0.5. No cap; +1 per own starting survivor, including returns/golden, excluding combat creations and stolen units.

Schedules (round-indexed; final entry repeats):

|Arm|Health|Base R1 onward|
|---|---:|---|
|A|40|0,0,1,1,2,2,3,3,4,4,5,6,7,8,9,10|
|B|40|0,0,0,1,1,2,2,3,4,5,7,9,11,13|
|C|40|0,0,0,0,1,1,2,2,3,4,6,8,10,12|
|D|40|1,1,1,1,2,2,2,2,4,4,6,6,8,8,10|
|E|48|0,0,0,1,1,2,2,3,4,5,7,9,11,13|

200 complete best-bot lobbies/arm via BenchSuites.hard_lobby_hard, paired seeds 860001–860200; four shards on cores 1–4. Each background batch has a 3000-second hard timeout and logs. No adaptive tuning. Record per-round Health/results, final placements/elimination rounds, and base/performance damage to real heroes. Baseline performance attribution is surviving-tier contribution after floor/cap/toll (base allocated first). T3 uses resolved combat charges, including Armor/overkill, before Last Stand, excluding damage to ghosts; also report effective absorbed damage sensitivity.

Targets: T1 qualifying players (maximal consecutive-loss streak length ≥5, starting ≤R6; draws break streaks) have median elimination ≥baseline+2; T2 median final round within ±1; T3 performance/all hero damage 25–45%; T4 median first elimination ≥baseline+1; T5 eventual top-four fraction among bottom two living by Health after R8 ≥baseline (ties: seat ID). Survivors use final round+1 for elimination censoring; report counts. Pick most targets; ties: fewer base changes, then 40 Health, then alphabetical.

Analytic Health after consecutive losses from R3, three survivors; no Armor/saves. Baseline assumes winner tiers R3–10 = 2,2,3,3,4,4,5,5 and three same-tier survivors, eight living (caps retained). Negative values show theoretical continuation.

|Arm|R3|R4|R5|R6|R7|R8|R9|R10|
|---|---:|---:|---:|---:|---:|---:|---:|---:|
|Baseline|35|29|22|14|5|-5|-16|-28|
|A|36|32|27|22|16|10|3|-4|
|B|37|33|29|24|19|13|6|-2|
|C|37|34|30|26|21|16|10|3|
|D|36|32|27|22|17|12|5|-2|
|E|45|41|37|32|27|21|14|6|

Results: all 1,200 games complete; logs clean. Frozen official release runtime matched editor JSON byte-for-byte on baseline/A smoke games. [Raw data, provenance and validation](damage-v05/) include 75,043 verified charges.

|Arm|Streak out (n/censored)|Game end|First out|Performance|Effective performance|Comeback|Targets|
|---|---:|---:|---:|---:|---:|---:|---|
|baseline|10.0 (258/12)|17.0|9.0|19.97%|18.22%|88/400 (22.00%)|—|
|A|13 (283/9)|21.0|12.0|28.79%|31.05%|114/400 (28.50%)|T1,T3,T4,T5|
|B|13.0 (278/19)|19.0|12.0|25.75%|28.98%|122/400 (30.50%)|T1,T3,T4,T5|
|C|14.0 (278/19)|20.0|12.0|27.46%|30.70%|143/400 (35.75%)|T1,T3,T4,T5|
|D|13 (287/16)|21.0|12.0|28.50%|30.74%|120/400 (30.00%)|T1,T3,T4,T5|
|E|14 (275/18)|21.0|13.0|24.13%|26.53%|128/400 (32.00%)|T1,T4,T5|

Selected D by preregistered target count and tie-breaks.

The preregistered pick was D (5 base changes). The later approved redesign decision selects **B as the playable default**, prioritizing its median round 19 ending over D's 21. A–D meet T1/T3/T4/T5; E misses T3 too. All miss T2. `GameConfig.full_game()` now uses B; `full_game("legacy")` retains the baseline rule. Bots, tools/play, the bench and soak inherit the playable default. No burst guard is added. Starting Eggs count once: they are present before Start of Combat, as in the archived B runs.

Prior selectable-rule validation: `./scripts/check.sh` passed (1,310 tests). No new soak at that stage; prior gate/soak archived separately for 9d3006c.

## Same-round knockouts (existing data, 8 Nov 2026)

Count each lobby-round once for each threshold it meets: 3+ is included in 2+. A hero went out in its final recorded round if its final `alive` is false. Living winners are excluded; a round with several eliminations counts once, regardless of fight order or cause (including ghost losses and debt). No lobbies were rerun. These are bot results, not human pacing evidence.

|Arm|Lobbies|All rounds|Rounds with 2+ out|Rounds with 3+ out|Exactly 2 / 3 / 4 out|
|---|---:|---:|---:|---:|---|
|baseline|200|3,321|275|37|238 / 36 / 1|
|B|200|3,879|279|54|225 / 51 / 3|

There were no rounds with 5+ out. B has 4 more 2+ rounds and 17 more 3+ rounds across the paired sets. No burst guard, per the approved implementation scope.

Reproduce from this directory's archived `baseline.[0-3].jsonl.gz` and `B.[0-3].jsonl.gz`, from the repository root:

```python
import gzip, json
from collections import Counter
from pathlib import Path

for arm in ("baseline", "B"):
    games = [json.loads(line)
             for path in sorted(Path("docs/ideation/evidence/damage-v05").glob(f"{arm}.*.jsonl.gz"))
             for line in gzip.open(path, "rt")]
    assert len(games) == 200 and all(game["complete"] for game in games)
    histogram = Counter()
    for game in games:
        outs = Counter(p["rounds"][-1]["round"] for p in game["players"] if not p["alive"])
        histogram.update(outs.values())
    print(arm, *(sum(n for k, n in histogram.items() if k >= threshold) for threshold in (2, 3)),
          dict(sorted(histogram.items())))
```

## Default-B validation

`./scripts/check.sh` was invoked once; failed stages were resumed after fixes rather than repeating passed stages. The merged combat file exceeded the 1,000-line lint limit by two lines; only redundant comments were trimmed. Six failing tests exposed old damage expectations, early-round nonlethal Last Blow fixtures, and an overflowing recruit hint. These were corrected. All ten gate stages passed across the original invocation and its resumes: final GUT **1,410/1,410 tests**, 132 scripts, 19,648 assertions, no risky or pending tests. [Gate log](damage-v05/check-arm-b.log).

Every Godot invocation used `systemd-run --user --scope -p MemoryMax=3G -- <command>` and `/tmp/bramble-godot.lock`. The other worker launched its soak during our test run (22:17:11–22:20:03 AEDT overlap, confirmed by the systemd journal). Our soak waited until that worker finished at 22:23:30. The shared lock was requested for any further runs. Our soak's scope was verified at `MemoryMax=3221225472`, with just one Godot process active.

`tools/checks/soak.sh 100 1719862560` passed: seeds 1719862560–1719862659, **100 games, zero violations**, exit 0, clean engine log. The standard soak mixes bare rules, the playable slice and synthetic content; its full-game configurations inherit B. Coverage gaps are report-only. [Soak log](damage-v05/soak-arm-b.log).

## Review fixes

Applied the wording and schedule-test fixes from `origin/ideation/c-review-damage-b:docs/ideation/evidence/review-damage-b.md`. How-to-play, recruit hint and glossary now use **starting survivor**. The Round base slip says “Rises each round, up to 13.”; the full 14-entry schedule stays in rulebook 10.1.4a. Starting survivor and Last Blow slips omit the implied golden-count and survivor-damage explanations. The new regression asserts the whole `V05_BASE_DAMAGE` array and the default config's schedule, including R10.

Waited for w1 through `/tmp/bramble-godot.lock`, then held that lock across the gate and soak. Each Godot invocation used `systemd-run --user --scope -p MemoryMax=3G --`. `./scripts/check.sh` passed all ten stages on its single invocation: **1,411/1,411 tests**, no risky or pending tests. [Gate log](damage-v05/check-arm-b-review.log).

`tools/checks/soak.sh 50 1744150805` passed: seeds 1744150805–1744150854, **50 games, zero violations**, exit 0, clean engine log. [Soak log](damage-v05/soak-arm-b-review.log).
