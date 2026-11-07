# Making tribe commitment pay: build evidence

Branch: `ideation/commit`. Problem: “Committing to a tribe doesn't pay.” Owner's direction: “It needs to focus on interesting designs and strategic depth.” Source package: [commit-review.md](commit-review.md); read both critics and the costing before implementation.

**Corrected headline (cloud review): commitment's full-board mid-game advantage is about half a place, not two places. At round 10, boards with at least six units placed 4.00 with 6+ of a tribe versus 4.38 with at most four (gap 0.38; review seeds 47000–47029). Final-board comparisons below are descriptive and inflated by early eliminations; they are not the mid-game effect size.**

Five tribes are retained for rotation variety, not as the commitment fix. The same review's six-tribe run still paid commitment (3.37 versus 5.48 on final boards), so there is no measured commitment benefit attributable to reducing six to five. The spell/rule changes and bot priors carry that claim; the original before/after package is not an isolated tribe-count experiment.

## Method and acceptance

Build and measure in order: items 1–8, then 13–14, then 9–12. No item is silently dropped. Run `tools/sim/commit_probe.gd` (promoted from the review's `.gd.txt`) on 30 eight-seat Hard lobbies, seeds 91000–91029, at each stage. Summarize with `python3 tools/sim/summarize_commit.py <log>`. Raw logs and JSON summaries live in `build/commit/` (ignored build artifacts); the tables below preserve the results.

Pass: final boards with six or more units of a tribe place better than boards with four or fewer; own-tribe stats clearly exceed 2% at round 15; both Oozes and Birds exceed 5% of Hard strategy picks. Report all six tribes' pick shares and placement, plus the biggest unit's stats and share of the board by sampled round. These are observational bot lobbies, not randomized commitment assignments; small placement differences remain noisy.

Round snapshots cover all fight participants, including seats eliminated in that round. Commitment counts are literal recruit-board tribe counts, matching the original acceptance test: Eggs have no tribe, and away Birds are not relabelled as on-board units.

The permanent-stat attribution observer is optional and inert in normal play. Like the original probe, it attributes permanent gains using the last logged trigger and scales histories through triples. It is approximate, particularly for unlogged growth. The standing tribe bonus is measured directly from its separate stat layer, not credited as a generic spell or a second Moss trigger. “Own tribe” combines that layer with grants from a unit sharing the recipient's tribe. Its direct standing-bonus share is also reported as a robust lower bound, independent of the approximate trigger/triple ledger. Pick share means the final selected strategy's tribe; board placement is also reported by the most numerous tribe.

## Implementation and tuning ledger

- Baseline: original branch head `113b573013cc9f80b9e598b5fc6db3b9f7e86f20`, six tribes and original bot priors. The initial run reproduced the reported commitment deficit (6+: 4.610, n=82; ≤4: 4.352, n=91; Ooze picks 1.25%, Birds 0%).
- Measurement correction: the prototype sampled after `end_turn`, after next-round upkeep and elimination. The real tool now samples every fight participant through `fight_observer`, after End of Turn but before carry, elimination or next-round upkeep. The baseline was rerun from a `git archive` of the original head under `/tmp`, with only the optional probe hook and real probe added. This archive is not another worktree. Superseded logs retain `-prototype-timing` in their names.
- Review fixes before the corrected core bench: preserve the separate tribe layer through combat construction so Alderman Dozey’s permanent-buff ceiling cannot erase it; preserve Shy avoidance in live kin aiming. Both have regressions.
- Rule interpretation: a dual-tribe target would grant both of its tribe bonuses; current pool cards have one tribe. Each tribe remains capped separately, and a dual-tribe recipient receives both.
- Exhausted shared-pool copies cannot be guaranteed by Hiring Fair; it uses the ordinary legal fallback. This is explained in the player help and covered by pool-conservation checks.
- Items 1–8 built and benched first: 30 lobbies, 240 Hard seats; 6+ place **4.101** (n=99), ≤4 place **5.041** (n=74). Round-15 own-tribe share **10.746%**, including an independently measured **8.038%** standing bonus. Oozes **15.00%** of picks (place 5.056); Birds **14.17%** (place 5.618). Core passes the stated thresholds, but Birds remain weak in placement, so continue the requested package.
- Items 13–14 built only after the completed core bench: mirrored Eggs, no flight sale gold, landing cooldown, Goose’s own Egg 0/2, and initially counted Whistlers at cap 6/12. The first Bird bench completed 30 lobbies: 6+ **4.416** (n=101), ≤4 **4.531** (n=81). Its 0.115-place advantage is too small to read as reliable.
- **Whistlers overshoot, measured and tuned:** `tools/sim/commit_whistlers_curve.gd -- 100` ran 3,000 real Combat fights, then reproduced all 30 result rows after tuning. Six inert Birds plus the live 3/3 Whistlers face seven equal inert enemies at 4/6, 13/13 and 12/14. On the late boards, cap 6 removes **84** Attack+Health, golden cap 12 removes **168**, without overkill. Historical caps 1/2/3/6 remove 14/28/42/84. This verifies the costing warning; seeded win rates saturate at stat breakpoints and are not lobby win-rate estimates.
- Adopted the costing reviewer’s **flat 1 Attack and 1 Health per enemy across a Bird or Egg; golden 2/2**. The amount-per-Bird clause is deliberately removed because its seven-target power overshoots; extra Birds/Nests still widen the footprint. Item 14 remains built, with each copy firing as printed; no hidden once-per-side guard. The bot hint falls from 22 to 12 to match the reduced effect.
- Bird bot correction before the tuned bench: an empty Nest now has its real Egg’s opportunity cost when buying/playing units. Fight search inserts Eggs at their fixed Nest slots after arranging each candidate; Eggs never move with recruits. Flying does not erase strategy identity. Directed regressions cover all of these. The tuned Bird bench then completed all 30 lobbies before items 9–12: 6+ **3.787** (n=94), ≤4 **5.226** (n=93), own-tribe **12.806%** including direct bonus **8.395%**; Oozes **15.42%** of picks, Birds **17.92%**. Birds average **6.488 place**. This is a pick-share pass, not tribe win-rate parity. Matched-lobby bot diagnosis found much of the worsening average came from more weak Summer and Winter picks, rather than a demonstrated Egg-search bug; no speculative flight penalty was added.
- Items 9–12 built only after the completed tuned Bird bench: flat Fairy Ring additions, bounded friendly emergence buffs with Belly 1, direct spell gifts copied inside Oozes, and Hunter gains after each Take. Fairy Monarch, Elder Ooze and Moss Ooze were old non-slice skeletons; all three are promoted into the real slice pool (93 → 96 pool units). Keeping them outside the pool would silently omit their gameplay. Their portraits use the existing tribe fallback and are explicitly listed as pending bespoke art. Independent code review found no material issue; final 30-lobby bench completed with the results below.
- Final gate and then `tools/checks/soak.sh 100 61`: **PASS**; run sequentially, never concurrently.

## Numbered package audit

| Item | Built behavior |
|---|---|
| 1 | Stand Behind Me: tier 3, cost 2; behind the chosen front unit, permanent +1/+1 or +2/+2 for kin. |
| 2 | Bread from the Back: tier 2, cost 2; the matching front-of-back-unit kin rule. |
| 3 | Harvest Supper: tier 5, cost 3; aimed tribe bonus +1/+1, once a turn, cap +3/+3, all owned locations and future arrivals, no fight summons. |
| 4 | Hiring Fair: tier 5, cost 6; a distinct tier-6 kin choice at five board units, subject to real shared-pool supply. |
| 5 | Equal-scale Ooze/Bird priors; kin, standing bonus, tutor and new payoff values; corrected fixed-Nest search, purchasing, flight and build identity. |
| 6 | Five tribes per live lobby. |
| 7 | Queen of Elfland splits only among her other Fairies. |
| 8 | Charcoal Burner 4/6; burn at most 4, golden 8, at the same +1/+1 per 2 rate. |
| 13 | Mirror Eggs keep their away Bird’s stats without text; Goose’s own Egg 0/2; flight pays no sale gold; landing-turn flight blocked. |
| 14 | Whistlers 3/3; measured overshoot tuned to flat 1/1, golden 2/2, across each Bird or Egg. Each copy fires. |
| 9 | Fairy Monarch 4/6; Rings under Fairies add a flat +1/+1, golden +2/+2. |
| 10 | Elder Ooze 3/4, Belly 1; friendly releases count through the fight, capped +3/+3 per source, golden +6/+6. |
| 11 | Moss Ooze tier 2, 2/4; direct spell stat gifts to an Ooze copy inside it, golden twice; Supper excluded. |
| 12 | Laird 3/5; bell quarry assignment retained; after each Take, surviving Hunters gain combat +1/+1, golden +2/+2. |

No item is dropped. The amount-per-Bird clause of item 14 is the logged, measured tuning departure.

## Before and after

All stages use 30 lobbies / 240 Hard seats and seeds 91000–91029. Lower placement is better. Own-tribe total = approximate same-tribe unit grants + directly measured standing bonus; the bonus alone comfortably passes the threshold.

| Stage | 6+ place (n) | ≤4 place (n) | Own tribe at R15 | Direct bonus | Ooze picks | Bird picks |
|---|---:|---:|---:|---:|---:|---:|
| Before | 4.610 (82) | 4.352 (91) | 1.763% | 0.000% | 1.25% | 0.00% |
| Items 1–8 | 4.101 (99) | 5.041 (74) | 10.746% | 8.038% | 15.00% | 14.17% |
| Birds, cap 6/12 | 4.416 (101) | 4.531 (81) | 9.401% | 6.584% | 15.42% | 12.92% |
| Birds, tuned | 3.787 (94) | 5.226 (93) | 12.806% | 8.395% | 15.42% | 17.92% |
| Full package | 3.745 (94) | 5.545 (77) | 12.112% | 8.068% | 16.67% | 18.75% |

### Every tribe: picks and placement

Picks mean the final strategy chosen by each Hard seat; these six cohorts are disjoint. Main-board placement is a separate descriptive cohort, based on the tribe with most recruit-board units (ties may count in both cohorts). These results do not establish causal tribe balance. A dash means no picks.

| Tribe | Before picks | Before place | After picks | After place | After main-board place |
|---|---:|---:|---:|---:|---:|
| Hedgerow folk | 31.67% (76) | 5.105 | 25.83% (62) | 4.210 | 4.175 |
| Fairies | 22.50% (54) | 3.463 | 16.67% (40) | 3.350 | 3.545 |
| Oozes | 1.25% (3) | 7.667 | 16.67% (40) | 4.600 | 4.727 |
| Birds | 0.00% (0) | — | 18.75% (45) | 5.711 | 5.732 |
| Bog folk | 28.33% (68) | 4.618 | 13.75% (33) | 5.152 | 5.452 |
| Hunters | 16.25% (39) | 4.308 | 8.33% (20) | 3.700 | 3.870 |

### Biggest unit, every round

Attack + Health at combat start, after auras and before bell effects. Unlike the prototype’s recruit-only snapshot, this includes fighting mirror Eggs. The first two numeric columns are means of each nonempty board’s largest unit and its share of that board; “peak” is the largest single observation. Later rounds have fewer boards, so compare them with their sample sizes.

| Round | Boards before/after | Mean largest before → after | Mean board share before → after | Peak before → after |
|---|---:|---:|---:|---:|
| 1 | 76/76 | 3.974 → 3.724 | 96.842% → 96.842% | 5 → 5 |
| 2 | 240/240 | 4.733 → 4.325 | 67.290% → 67.386% | 9 → 9 |
| 3 | 240/240 | 6.671 → 6.246 | 42.836% → 43.244% | 18 → 17 |
| 4 | 240/240 | 8.425 → 7.925 | 33.529% → 33.423% | 19 → 27 |
| 5 | 240/240 | 10.617 → 10.012 | 29.957% → 29.184% | 24 → 37 |
| 6 | 240/240 | 12.796 → 12.488 | 28.729% → 28.791% | 35 → 41 |
| 7 | 240/240 | 16.512 → 15.925 | 28.733% → 29.015% | 35 → 42 |
| 8 | 240/240 | 20.733 → 20.275 | 29.168% → 29.450% | 38 → 46 |
| 9 | 234/239 | 25.556 → 25.753 | 29.725% → 30.161% | 55 → 63 |
| 10 | 217/217 | 30.765 → 30.207 | 30.581% → 30.502% | 61 → 72 |
| 11 | 186/187 | 35.452 → 35.679 | 30.668% → 31.454% | 79 → 80 |
| 12 | 147/144 | 39.633 → 38.799 | 30.399% → 30.207% | 85 → 84 |
| 13 | 112/116 | 43.036 → 43.216 | 29.808% → 30.388% | 86 → 84 |
| 14 | 82/86 | 46.110 → 45.384 | 28.588% → 29.157% | 105 → 86 |
| 15 | 52/58 | 49.519 → 46.310 | 28.182% → 28.032% | 107 → 92 |
| 16 | 26/22 | 50.154 → 45.682 | 25.848% → 25.763% | 72 → 76 |
| 17 | 2/10 | 58.500 → 46.800 | 30.756% → 23.808% | 69 → 82 |
| 18 | 0/2 | — → 38.500 | — → 20.210% | — → 40 |

At round 15, the largest combat-start unit averages **49.52 → 46.31** stats and **28.18% → 28.03%** of its board. The peak changes **107 → 92**. Neutral spell share changes **28.87% → 22.84%**; the package shifts payment toward tribe membership without adding an anti-giant rule.

### Late-card presence (descriptive)

Final-board holders are a selected survivor cohort, not randomized card tests. Their placement is recorded to expose uptake; it is not used alone to decide tuning.

| Card | Final boards | Mean holder place |
|---|---:|---:|
| seven_whistlers | 7 | 2.286 |
| fairy_monarch | 23 | 2.870 |
| elder_ooze | 10 | 2.200 |
| moss_ooze | 24 | 4.750 |
| laird_of_sett | 10 | 3.300 |
| queen_of_elfland | 24 | 2.667 |
| charcoal_burner | 0 | — |

All requested pass-test thresholds pass in the full-package run. Bird placement remains weak; the package is not presented as tribe parity. Every numbered item is implemented. The only substantive departure is the explicitly measured Whistlers amount tuning; the three bespoke portraits remain tracked art work.

## Phone checks and focused validation

[Before recruit view](ui/recruit_1688x780.jpg) → [bonus icons after](commit-build-phone/commit_bonus.jpg). Also inspected the [Harvest grant](commit-build-phone/commit_harvest.jpg), [Bird help](commit-build-phone/commit_mrs_jay.jpg), [tribe guide](commit-build-phone/guide_11.jpg), and [commitment guide](commit-build-phone/guide_12.jpg) at the 1688×780 phone render. The initial bonus strip overlapped shop stat beads; it was moved below the lobby. Harvest’s complete rule and scope fit in the reader. The strip displays each tribe’s current bonus on its portrait icon; card/grant help explains where it applies.

Focused checks before the final gate: core commitment 12/12 (55 assertions), broader touched core suites 88/88; Bird rules 84/84 (189 assertions); Egg-aware bot/held/commitment suites 39/39 (99 assertions); relevant UI suites 41/41 (474 assertions). Content, GDScript formatting/lint and the summarizer’s Ruff checks pass. Accidental broad GUT invocations that retained configured directories were superseded by isolated `-gconfig=` focused runs; they are not claimed as passes. Final gate and soak results follow below. The final normal/golden card readers were all rendered at phone scale with no scroll or clipping and visually inspected: [cards 1](commit-build-phone/card-rules-1.jpg), [cards 2](commit-build-phone/card-rules-2.jpg), [cards 3](commit-build-phone/card-rules-3.jpg).

## Final gate and soak

The first full gate passed tools, versions, shell, Python, content, format, lint, import and compile, then found five failing tests: one pinned-strategy fixture assumed six available tribes; one Nest fixture lacked its real away Bird; the tier-six reward fixture’s legacy pool had only two distinct tier-six choices after promotion and correctly fell back; two UI tests caught Moss Ooze’s generic “Ability” tile label. The three fixtures were corrected without weakening their behavioral assertions. Moss now says **Spells inside** in both forms, with explicit regression coverage and an inspected [phone tile and reader](commit-build-phone/commit_moss_ooze.jpg). These are fixture/UI changes only, so the final gameplay benchmark remains valid.

The gate rerun passed every step: **1,215 tests, 15,891 assertions, 104 scripts**, strict hook clean. Its subsequent 100-game soak completed seeds 61–160, 1,533 rounds and 4,848 fights, but reported four duplicated seed-zero parameter-check violations: the soak checker assumed Charcoal Burner’s golden buff rate must double. The reviewed card explicitly doubles the burn limit (4 → 8) at the same +1/+1 per 2 rate. The checker now follows the existing `golden_static` declaration and still asserts that every fixed value remains unchanged. Independent review confirmed this is a validator correction, with no gameplay change and no unrelated checks skipped. Full gate and the same 100-game soak are being repeated in that order.

**Final repeated gate: PASS**, every step, **1,215 tests / 15,891 assertions / 104 scripts**, strict hook clean; 357 scripts compile with zero failures. **Then soak: PASS**, `tools/checks/soak.sh 100 61`, seeds **61–160**, **100 games, 1,533 rounds, 4,848 fights, zero violations**, exit 0. The no-attacks result at seed 144 is a recorded legitimate stalled board, not an invariant violation. Coverage gaps are reported, not hidden: Gabble Ratchet, Pipistrelle Echo and Young Pretender did not fire in this sample. All new package cards did fire. Logs: `build/commit/gate.log`, `build/commit/soak-summary.log`, `build/check/soak.log`.

All gameplay, card data, bots, UI, documentation, tests, probe tools and phone evidence are ready in this branch. Remaining follow-up: Bird balance (18.75% picks, 5.711 placement) and the three explicitly tracked bespoke portraits. No package item is left unbuilt.

## Round4 merge and fresh difficulty ladder (8 Nov 2026)

The user explicitly authorized merging `origin/ideation/round4` at `ede4f800aed8dc5c13ccf1e195e6ac80e328208a` into this worktree's `ideation/commit`. Merge commit **`eec558a7a70cb552a669cc1411f01cb2f0560680`** has parents `47b1f486d6f484d6cd5ff0c8444e05cf0bb566bb` and `ede4f800aed8dc5c13ccf1e195e6ac80e328208a`. Neither `main` nor `ideation/main` is touched; nothing is pushed.

The conflict in `tests/core/test_bot_held.gd` retains both behavioral checks: Easy can fly with a spare body without gaining sale gold, and that same Bird misses its first fight and returns after its two-turn trip. Round4's deterministic return coverage stays; obsolete cash-short wording is removed because commitment flights do not pay sale gold. The whole-game fixture keeps round4's distinction between guaranteed deterministic coverage and events not guaranteed by one unplanned Easy seed. Commitment's Egg-aware behavior, tribe weights and flight economics remain alongside round4's teaching tier limits and per-turn spell-purchase budgets. No further tuning is applied.

All work in this follow-up uses **core 2 only**, with **one sequential job**: full gate, then soak, then ladder. The detached host tmux socket/session is `bramble-commit-round4` / `commit-round4-merge`, with an overall 2,400-second timeout and per-stage limits. Job affinity is recorded as CPU 2 in `build/sim/commit-round4-merge/affinity.log`; runtime head, status, timestamps and logs are in that directory. The existing 1,000-game spread retains its own frozen `b872a6b` snapshot and is neither restarted nor modified.

Requested ladder: `plain_easy`, `easy_naive`, `normal_easy`, `hard_normal`, 100 games each. Also run `hard_naive=100` because the user explicitly supplied its top-four/win targets; this avoids reporting an old unmerged-tree result as fresh. Each suite uses fresh seeds **3001–3100**, one shard, on the same merged runtime. “Near 3” and “near 2.5” have no supplied numerical tolerance; report exact means and 95% placement margins rather than inventing a hard pass band. The strict supplied bars are Hard/Normal **<3.5**, and Hard/Naive **≥85% top four and ≥45% wins**. Easy/Naive should show Easy beating Naive; no new numerical target is invented.

```sh
# Each stage starts only after the previous stage exits successfully.
taskset -c 2 ./scripts/check.sh
taskset -c 2 tools/checks/soak.sh 100 171
taskset -c 2 tools/sim/bench.sh --cores 1 --seed 3001 \
  --out build/sim/commit-round4-merge/ladder \
  --report build/sim/commit-round4-merge/ladder/report.md --timeout 300 \
  plain_easy=100 easy_naive=100 normal_easy=100 hard_normal=100 hard_naive=100
```

The actual detached wrapper also supplies writable `XDG_DATA_HOME`/`XDG_CONFIG_HOME` within the ignored output directory and `LP_NUM_THREADS=1 OMP_NUM_THREADS=1`. The stock summary omits `plain_easy` and uses the older Normal/Easy <4.5 bar, so the evidence below independently checks every requested rung against the user's stated targets.

Corrected runtime **`4a5a0b7f0bec8adadec03ef879addced76314592`** (fixture-only child of the merge): **gate PASS**, all ten steps, **1,220/1,220 tests, 15,907 assertions, 104 scripts**, strict hook clean; 358 scripts compiled with zero failures. Then **soak PASS**, `100 171`: **100 games, seeds 171–270, 1,497 rounds, 4,742 fights, zero violations**, exit 0. The seed-174 no-attacks finish is report-only. Every slice card fired; keyword coverage gaps are retained in the soak log.

| Suite | Games | Mean place ± 95% margin | Wins | Top 4 | Target comparison |
|---|---:|---:|---:|---:|---|
| plain_easy | 100 | 3.91 ± 0.60 | 44% | 56% | above 3; target outside 95% interval |
| easy_naive | 100 | 1.52 ± 0.20 | 69% | 96% | Easy ahead of Naive |
| normal_easy | 100 | 2.25 ± 0.46 | 75% | 80% | target 2.5 lies inside 95% interval |
| hard_normal | 100 | 1.59 ± 0.16 | 56% | 99% | PASS: mean <3.5 |
| hard_naive | 100 | 1.00 ± 0.00 | 100% | 100% | PASS: top4 >=85%, wins >=45% |

**Target crossing:** Plain/Easy is above its near-third target: **3.91**, 95% interval **3.31–4.51**. The earlier round4 reference was 3.11 ±0.56 on different seeds. This is a fresh merged-tree target check, not a paired causal estimate of the commitment package. Normal/Easy's interval **1.79–2.71** includes 2.5. Easy clearly beats Naive; Hard/Normal and both Hard/Naive bars pass. No difficulty retuning was applied in response to these measurements.

Independent CSV validation confirms five complete 100-game suites (500 completed games), exactly seeds 3001–3100 and eight distinct placements 1–8 per seed, one focus seat, and 4,000 seat rows. The 100 seeds are independent within each suite and shared across suites. All stamps identify runtime `4a5a0b7`; no product source/data changed after that commit. Raw data and requested-target report: `build/sim/commit-round4-merge/ladder/`; accepted gate/soak logs are alongside it. Initial failed gate logs are preserved separately. The final wrapper rerun used a 2,100-second overall timeout and completed normally. The portrait follow-up `915d5c5` remains present; the earlier three pending portraits are now complete.


The first merged gate passed the other nine steps and 1,219 of 1,220 tests, then exposed an additional integration fixture: round4's toll-guide test assumed the toll page was the final page. Commitment adds two tribe/travel pages after it. The test now finds the unique “Stay standing to win” page by title and retains both assertions about the permanent 12 cap and final duel. Product text and gameplay are unchanged. The failed gate is retained as `gate-first.log`; the sequential gate/soak/ladder pipeline is restarted after this fixture correction, with the corrected runtime committed before the run.

## Cloud commit review follow-up A — cuts (8 Nov 2026)

Reviewed `origin/ideation/c-review-commit:docs/ideation/evidence/review-commit.md`, items 1–3. The orchestrator fixes the stale CLI 0/2 Nest reminder, states Hiring Fair's count as units **on your board**, and adds golden **total** stat assertions in recruit and combat. The test recipient is **8 Attack / 11 Health**, including its separate owner bonus.

Mutation proof: changing only attack to `tribe_attack * factor` fails at **11 versus expected 8**; changing only health to `tribe_health * golden_factor()` fails at **14 versus expected 11**. Both mutant runs exit 1. `board_unit.gd` is restored byte-for-byte (SHA256 `6ab8415350d6dc2ac089d47b8227c35925e1d4222ac2b6b11bd4a53c58b174f1`). Normal focused validation: **43/43 tests, 271 assertions**, formatting/lint clean. Logs: `/tmp/commit-review-A-mutant-{attack,health}.log`. Group A contains no numbers tuning.

## Cloud commit review follow-up B — orchestrator calls

- Item 4: hide all zero-bonus chips; earned bonuses appear with a readable **Tribe bonus** label. All five earned chips fit on phone. Focused UI/phone/guide checks **19/19, 324 assertions**; inspected [labelled phone strip](commit-build-phone/bonus-labelled.jpg).
- Item 8: Queen pools only golden-adjusted printed stats plus permanent unit buffs. Tribe bonuses, Rings, other auras and combat bonuses do not enter the pool. A regression injects all excluded layers into a victim displayed at 19/24 and verifies the actual normal pool is 3/5, golden 6/10.
- Monarch coverage: an optional inert aura observer reports actual nonzero Monarch contributions after aura application. Presence/buying alone, a neutral on a Ring, no Monarch and unchanged recalculations do not count as firing. This measures the aura without inventing combat trigger spam. Queen/coverage focus **33/33 tests, 136 assertions**, content/format/lint clean.
- Item 7: retain five tribes for **variety**, not for a demonstrated commitment gain. The cited [27 October note](../../design/owner-notes/2026-10-27-battlegrounds-direction.md) says “having a certain number of tribes per game in the pool to keep things varied”. The corrected headline and methodology above retain the review's fixed-round, full-board comparison: round 10 **4.00 versus 4.38**, about half a place. The larger final-board gap remains visible as a confounded descriptive metric.
- Round4 A3: retain Normal's shop-spell start at round 12 as an explicit difficulty **tuning knob, not a skill**. No policy change is made under this call.

These are the orchestrator's calls and reasons, recorded by review item; they are not attributed to the owner.
