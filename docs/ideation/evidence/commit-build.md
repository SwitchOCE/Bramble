# Making tribe commitment pay: build evidence

**Evidence status (8 Nov owner direction): all Bird and Charcoal Burner measurements here are Hard bot data, weak evidence. They do not establish human card strength. Easy/Normal ladders are historical difficulty measurements, never card-balance evidence. No further card tuning follows these numbers.**

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
| 8 | Charcoal Burner tier 4, 4/6; burn gold above 5, at most 6 / golden 12, same +1/+1 per 2 rate. Review trials and bot banking/placement evidence follow below. |
| 13 | Eggs mirror half each away Bird stat, rounded up, without text; Goose’s own Egg 0/2; flight pays no sale gold; landing-turn flight blocked. Swallow/Chiffchaff Health 2 ensures an initial body cost. |
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

## Cloud commit review follow-up C — measured Burner trial and next candidate

The orchestrator first applies the review's numeric trial: **4/6, cap 6 / golden 12**, same +1/+1 per two burned. Focused normal/golden cap checks: **30/30 tests, 90 assertions**. Normal/golden reader text fits on phone alongside the revised Queen: [inspected readers](commit-build-phone/review-queen-burner.jpg).

Fresh Hard probe seeds **73000–73029**, 30 lobbies / 240 seats, retain all A/B changes and use a frozen snapshot. Results: **1 buy of 4,175 unit purchases (0.024%)**, **1 buyer / 240 seats (0.417%), place 5**, and **1 final holder / 240 (0.417%), place 5**. The single burn event burned **0 gold**. The cap was not exercised. This numeric trial is still dead; it is not presented as balanced or fixed.

On the same sample, the corrected round-10 cohort (boards of at least six units) places **3.633 with 6+ of a tribe (n=79)** versus **4.145 with at most four (n=62)**, a **0.512-place** gap. The separately retained final-board gap is 3.627 versus 5.410 and is not the headline. Summary/logs: `build/sim/commit-review-C/c-full-egg/`.

Next candidate keeps the cap/body and corrects the missed banking choice: bots compare a purchase's gain with the actual marginal burn it forfeits, model funded draft value, and cash post-feeding surplus Acorns only when extra burn beats held value. The helper accounts for odd rounding, shared gold across Burners, caps, recipient eligibility and Shy. Kin offers can beat banking; low gold/no targets do not manufacture draft value. Root focused validation **10/10 tests, 30 assertions**, lint clean (`/tmp/commit-C2-root-focused.log`). Fresh seeds **73100–73129** then produced **zero buyers, final holders and burns in 240 seats**. Banking alone does not make a tier-five Burner available early enough to be a choice. This failed candidate is retained in the log; it is not called a successful retune. The next isolated trial moves only its tier from five to four (same 4/6, cap 6/12 and banking), fresh seeds **73200–73229**; results follow below.

The measurement overlay records real purchases, buyer placement, final holdings and gold actually burned; the reader distinguishes missing old observations from measured zero. Fresh round-10 headlines use six-or-more-unit boards. The original spread job remains untouched on its own baseline snapshot.


### Burner follow-up trials: availability, reserve and a real bot move

All arms have 30 Hard lobbies / 240 seats and cap 6 / golden 12, +1/+1 per two actually burned. Buyers and holders are selected cohorts; their placement is descriptive, not a causal card rating.

| Trial | Seeds | Unit buys | Buyer seats / 240 | Buyer place | Final holders | Positive burns / gold burned |
|---|---|---:|---:|---:|---:|---:|
| C1: tier 5, reserve 5 | 73000–73029 | 1 / 4,175 (0.024%) | 1 (0.417%) | 5.000 | 1 | 0 / 0 |
| C2: same card, marginal banking | 73100–73129 | 0 | 0 | — | 0 | 0 / 0 |
| C3: tier 4, same banking/reserve | 73200–73229 | 9 / 4,153 (0.217%) | 7 (2.917%) | 5.143 | 0 | 3 / 14 |
| C4: tier 4, reserve 3 | 73300–73329 | 12 / 4,142 (0.290%) | 9 (3.750%) | 4.556 | 1 | 3 / 13 |
| Selected C5: tier 4, reserve 5, legal placement before shopping | 73200–73229 | 7 / 4,133 (0.169%) | 7 (2.917%) | 4.000 | 1 (place 5) | 11 / 54 |

Neither availability alone nor the lower reserve supplies convincing usage evidence. C3's logs expose three same-turn play/sale cases: a Burner played into the back row was valued as if it would stay there, then sold before the bot's end-turn placement. The orchestrator corrects this sequence: a funded Burner in hand uses a legal deployment forecast; after play, the bot makes the actual free legal front swap immediately, respecting pinned Nests. Further shopping evaluates real recipients and real gold. This adds no forced purchase or minimum holding period. C5 retains tier 4 **and the original reserve 5** and pairs seeds 73200–73229 against C3; its measured result is recorded below.

Human readability follows the same decision: the card states the reserve, cap, targets and permanent rate; the reader gives a live-number bank-or-buy example. Normal: keep **11 gold**, burn **6**, give each unit behind **+3/+3**, keep **5**; golden: keep **17**, burn **12**, give **+6/+6**, keep **5**. It also names F2/F3 for two recipients and says to spend instead when a better buy is available. The hint is tested and inspected at phone size, not hidden in bot weights. The reserve-3 alternative is not selected unless a later logged measurement justifies it.


**C5 selected (orchestrator):** paid use now reaches **six distinct players**, compared with one in paired C3. Their places are 2, 3, 4, 5, 5 and 5. The normal cap of six is exercised; no rate or reserve reduction is needed. Hard bot data, weak evidence: paid mid-game use appears in these games, not a human/card-strength verdict or a must-buy conclusion from a large randomized trial: only 2.917% of seats buy it, buyer place is 4.000, and final holding remains only **1/240**. Temporary growth engines can be sold after their permanent gifts, so this result establishes actual paid use rather than improved final-board popularity. Keep that limitation explicit. C4's lower reserve is rejected because the simpler corrected sequence already pays for growth.

C validation: **84/84 tests, 249 assertions**, including Tier-4 supply, normal/golden cap and reserve rules, legacy balance fixtures and readable hints; the separate bot/E focus passes **19/19, 96 assertions**. Content validation, formatting and import pass. New phone proof shows tier **4**, normal/golden examples and no scrolling/clipping: [bank or buy](commit-build-phone/burner-bank-or-buy.jpg). **A human can read the same banking choice from the card and hint.** Raw paired summaries: `build/sim/commit-review-C3/tier4-burner/` and `build/sim/commit-review-C5/retained-burner/`; lower-reserve trial: `build/sim/commit-review-C4/tier4-floor3/`.


## Cloud commit review follow-up D — Egg comparisons and selected rule

For review item 5, the orchestrator selects **D-iii: half-strength Eggs, rounding each stat up, plus Chiffchaff and One Swallow's printed Health raised from 1 to 2**. Mother Goose's own Egg remains 0/2. This keeps one common travel rule: the Egg pays only part of the Bird's body while the Bird is away, with no text. Normal play, sale and native homecoming effects remain available. The two small Health changes ensure these Birds pay a body cost even before buffs: a 1/2 Bird leaves a 1/1 Egg. Without that guard, rounding half of an unbuffed 1/1 up leaves the whole 1/1 body.

All four rows use **30 Hard lobbies / 240 seats, paired seeds 73000–73029**, from frozen snapshots with the same cap-6 Burner control. The exact D-i and D-ii variants were measured first; D-iii changes only the two printed Health values relative to exact D-ii. These are small, descriptive samples, not proof that the placement differences were caused by the Egg change.

| Arm | Rule tested | Bird picks / 240 | Bird mean place | Potential equal-body departures / observed |
|---|---|---:|---:|---:|
| Control | Full mirror Egg; normal replay rewards | 43 (17.92%) | 6.000 | Not recorded |
| Exact D-i | Full mirror Egg; suppress generic replay on-play/on-sale rewards | 43 (17.92%) | 5.767 | 68 / 73 |
| Exact D-ii | Half each Egg stat, rounded up; normal replay rewards | 40 (16.67%) | 6.025 | 87 / 174 |
| Selected D-iii | Exact D-ii; Chiffchaff and One Swallow Health 1 → 2 | 44 (18.33%) | 5.636 | 0 / 195 |

**The last column compares the potential Egg specification at departure with the departing Bird's body. It does not count realized loops, income, growth or retained combat bodies.** A Nest can be occupied, stats can change before combat, and losing combat text can matter even when the body's numbers match. Exact D-i's generic replay on-play/on-sale suppression is established by deterministic tests; its native homecoming effects remain allowed. In particular, its 18 Old Tern departure observations do not demonstrate an illicit reward loop.

D-iii's 195 observed departures all have a smaller potential Egg body, with mean Attack-plus-Health loss **1.974**. Exact D-ii still has 87 equal-body observations, largely the two 1/1 starters; D-i has 68 despite its different reward rule. The orchestrator therefore chooses the common, visible body-cost rule rather than retain a separate replay exception. Its Bird placement is descriptively lower than control (5.636 versus 6.000), but still weak; this is not a claim of tribe parity or statistical causal certainty. D-iii's fixed-round full-board comparison is **4.014 for 6+ of a tribe (n=71)** versus **4.136 for at most four (n=66)** at round 10.

Evidence: `build/sim/commit-review-outcomes.{json,md}`; exact-arm summaries/manifests in `build/sim/commit-review-D/`; guarded follow-up in `build/sim/commit-review-D-followup/half-egg-health/summary.json`. The completed baseline spread and bot-route correction are recorded next; the final combined-rule probe remains pending. The older spread belongs to its frozen baseline and cannot validate this selected rule. Final post-selection gate/soak results are recorded separately when complete. These are the orchestrator's design calls, not additional owner statements.


### Completed spread and Bird route choice

The untouched frozen **b872a6b** spread completes **1,000 lobbies / 8,000 seats**, seeds 61000–61999, at 20:15:52 UTC. **Spread bar PASS: 19 of 21 strategies win 6–25%, none above 25%; highest 22.286% (Oozes / Second Helpings).** All per-strategy wins, placements, intervals and Bird round diagnostics are retained in [commit-spread.md](commit-spread.md).

Bird Highway wins **10.174%**, mean place **4.568** (95% interval 4.346–4.790); Passage **2.486%**, **5.680** (5.480–5.879); Summer/Winter **1.393%**, **6.106** (5.915–6.296). Summer is clearly weakest by the predeclared nonoverlapping-place-interval flag. Only 10.306% of Summer seats reach tier 6, versus Highway's 23.573%; round-10 survival is 79.7% versus 92.8%. Similar board counts with weaker recruit bodies support a mid-game/reward-timing concern, not proof of empty Nests or the sole cause of the gap.

**Orchestrator route call:** Highway's Hard power prior stays 8; Passage becomes 3 and Summer/Winter 1. Deduct four points per observed place of deficit, rounded up and bounded at zero. Tribe weight 5 and each route's unit priorities remain unchanged; pinned strategies and Normal do not use this Hard-only correction. This prevents free-choice bots preferring the demonstrated weakest line. It does not repair the weak route's underlying cards. **Summer/Winter still merits a separate design/strength review** after the selected Egg/body-cost changes; no unmeasured extra buff is bundled here.

D checks: core **89/89, 214 assertions**; Egg-aware bot focus **33/33, 78 assertions**; route priors **12/12, 41 assertions**; UI/hint focus **22/22, 446 assertions**. Phone inspection confirms readable actions, actual Nest stats and guide text: [Bird actions](commit-build-phone/bird-half-cost.jpg), [Nest](commit-build-phone/nest-half-stats.jpg), [guide](commit-build-phone/guide-half-eggs.jpg). Content/format checks pass. Final combined Hard measurement and gate/soak follow below.


## Cloud commit review follow-up E — stale replacements and fresh ladder

The orchestrator retains Easy's one-replacement budget and actual improvement guard, but waives its old eight-point margin only for a weakest unit two tiers behind. A buffed giant is not discarded merely because it is low tier; a Belly clear consumes the same one-replacement budget. Focus **6/6 tests, 49 assertions**, existing teaching **4/4, 19 assertions**; the combined C/E regression focus also passes. Normal's A3 round-12 spell knob is unchanged and remains documented as a handicap, not a skill.

Fresh frozen-tree measurement queues 100 games each of Plain/Easy, Easy/Naive and Normal/Easy, seeds **4001–4100**, with two serial shards on cores 0/1. If Plain/Easy remains above 3.5, the user's follow-up authorizes weaker human-looking offer judgement until its measured mean is 3.0–3.5, while preserving live upgrades and stale replacement. Results and any conditional tuning follow below; no pass is claimed while jobs are pending.


### Completed E ladder: no additional Easy weakening

All **300 games complete** on the final C5/D-iii/route/E gameplay, 100 per suite, seeds **4001–4100**. The minimal frozen project's 544 `src/core`/`content` files match committed runtime **fb33c16** byte-for-byte (digest `702a9390f73273c7…`; full proof in `build/sim/commit-review-E/freeze-provenance.json`). Its initial candidate label predates the commits; provenance establishes runtime equivalence rather than pretending that label is a commit. Every suite independently validates exact seeds, eight distinct seats/placements 1–8 and one focus seat per game.

| Suite | Games | Mean place ± 95% margin | Wins | Top 4 | Target comparison |
|---|---:|---:|---:|---:|---|
| plain_easy | 100 | **3.340 ± 0.544** | **47%** | **66%** | requested 3.0–3.5 point target met |
| easy_naive | 100 | **1.430 ± 0.199** | **78%** | **98%** | Easy ahead of Naive |
| normal_easy | 100 | **2.730 ± 0.521** | **63%** | **74%** | 2.5 inside 95% interval 2.209–3.251 |

**Orchestrator call:** no additional weakening. The user's trigger was Plain/Easy remaining above about 3.5; its point mean is 3.34 and Plain wins 47%. This is a plain-bot surrogate, not a first-time human study; its interval is 2.796–3.884. Do not infer an isolated E causal gain from the earlier merged 3.91: seeds and other reviewed changes differ. Off-repo Easy valuation-noise 0.8/1.0 and no-paid-refresh alternatives were prepared but **never applied**, because the measured trigger was not met. Boards continue developing: focus final-board units average Plain 6.84, Easy 6.79 and Normal 6.68. No board freeze or upgrade block is added.

The requested pre-review merged Hard rungs remain recorded above: Hard/Normal **1.59** (<3.5), Hard/Naive **100% wins / 100% top four**. The latest authorized remeasurement is the three E rungs, not another Hard difficulty retune. Raw CSVs, validated summaries, manifests, logs and provenance: `build/sim/commit-review-E/`. The completed baseline spread's route weakness remains a separate card-design concern.


## Binding bot-data direction and final forecast repair

Read `origin/ideation/main:docs/design/owner-notes/2026-11-08a-bots-and-data.md`: “I think that we should be designing around the best bots we can.” No further Easy or Normal tuning is made; Plain/Easy remains **3.34**. All Bird/Burner results above are **Hard bot data, weak evidence**. Earlier descriptive selections do not establish card strength for humans. No further Bird or Burner card change is made.

The first final checkpoint passes **1,257 tests / 16,094 assertions / 112 scripts**, compiles 368 scripts, then passes soak 100 seeds 371–470 with zero violations. A separate strict Hard probe subsequently catches a two-Burner forecast failure at seed 73420: the empty exclusion sentinel was treated as a recipient. That probe is rejected and its raw logs retained. A guard excludes empty-definition sentinels; a multi-Burner regression checks exact values and unchanged board identity (**14/14, 53 assertions**, lint/format pass). This is a bot calculation fix, not an Egg/card change. Gate and soak are repeated after it; results follow below.

The later removal instruction in `origin/ideation/main:docs/design/owner-notes/2026-11-08b-remove-easy-medium.md` supersedes retaining a difficulty ladder. Step 1 of `docs/ideation/BOTS.md` will be implemented only after this checkpoint's corrected gate, soak and head report. Existing evidence remains history.


## Final frozen Hard probe

**Hard bot data, weak evidence.** Bird and Burner numbers describe these bot choices and are not human-play or card-strength verdicts. This recheck completes the earlier failed measurement after a bot-choice error fix; no further Bird/Burner card changes or Easy/Normal tuning follow from it.

30 full-game Hard lobbies / 240 seats, fresh seeds 73400–73429. Runtime provenance/digest are recorded in this run’s freeze-provenance.json and manifest.json. Frozen source includes C5 Tier4/floor5 retention, Diii half Egg plus two tiny Bird Health changes, route priors and E. No forced route pins in this final probe.

Placement differences from 30 lobbies are descriptive; different fresh seed cohorts do not isolate causal effects. Source attribution is approximate. The headline commitment cohort is measured at round 10, among recruit boards holding at least six units.

| Cohort | 6+ of one tribe: place (n) | 4 or fewer: place (n) | Gap (mixed minus committed) |
|---|---:|---:|---:|
| R10 boards >=6 | 4.342 (76) | 4.189 (74) | -0.153 |
| Final boards | 4.097 (113) | 4.943 (53) | +0.846 |

Round 15 own-tribe sources 0.892% + standing tribe bonus 7.181% = 8.073% of recruit-board stats. Standing bonus alone 7.181%.

| Tribe | Final strategy picks | Pick share | Mean placement | Main-board placement |
|---|---:|---:|---:|---:|
| Hedgerow folk | 65 | 27.08% | 4.200 | 4.190 |
| Fairies | 30 | 12.50% | 3.767 | 3.690 |
| Oozes | 64 | 26.67% | 4.766 | 4.788 |
| Birds | 23 | 9.58% | 5.174 | 5.318 |
| Bog folk | 32 | 13.33% | 4.375 | 4.167 |
| Hunters | 26 | 10.83% | 5.000 | 5.000 |

| Round | Boards observed | Largest fight-unit mean stats | Mean share of fight-board stats | Maximum fight-unit stats |
|---|---:|---:|---:|---:|
| 3 | 240 | 6.096 | 43.147% | 17 |
| 5 | 240 | 10.088 | 30.705% | 34 |
| 8 | 240 | 19.650 | 29.166% | 45 |
| 10 | 231 | 30.177 | 31.033% | 79 |
| 12 | 155 | 39.613 | 31.514% | 78 |
| 15 | 58 | 49.793 | 29.834% | 78 |

Burner purchases/buyers/final holders and actual paid activations:

```json
{
  "unit_purchases": {
    "events": 4245,
    "observed": true
  },
  "burner": {
    "final_boards": 4,
    "place": 5.75,
    "buy_events": 13,
    "buy_event_share_percent": 0.306,
    "buyer_seats": 11,
    "buyer_share_percent": 4.583,
    "buyer_place": 4.273,
    "final_board_share_percent": 1.667,
    "final_unit_share_percent": 0.245
  },
  "burns": {
    "events": 32,
    "positive_events": 30,
    "zero_events": 2,
    "gold_total": 141,
    "gold_mean": 4.406,
    "gold_max": 6
  }
}
```

| Bird route | Picks | Share of 240 seats | Mean placement |
|---|---:|---:|---:|
| birds_highway | 23 | 9.58% | 5.174 |
| birds_passage | 0 | 0.00% | n/a |
| birds_summer_winter | 0 | 0.00% | n/a |

Departure body metric: {"flight_events": 81, "observed_events": 81, "measurements_available": true, "free_body_flights": 0, "free_body_native_home_flights": 0, "mean_body_loss": 1.951, "by_card": {"chiffchaff": {"events": 33, "free_body_flights": 0, "native_on_home_events": 0, "mean_bird_attack": 1, "mean_bird_health": 2, "mean_egg_attack": 1, "mean_egg_health": 1, "mean_body_loss": 1}, "jack_daw": {"events": 3, "free_body_flights": 0, "native_on_home_events": 0, "mean_bird_attack": 2, "mean_bird_health": 3, "mean_egg_attack": 1.333, "mean_egg_health": 1.667, "mean_body_loss": 2}, "mother_goose": {"events": 6, "free_body_flights": 0, "native_on_home_events": 0, "mean_bird_attack": 4.167, "mean_bird_health": 7.167, "mean_egg_attack": 0, "mean_egg_health": 2, "mean_body_loss": 9.333}, "mrs_jay": {"events": 7, "free_body_flights": 0, "native_on_home_events": 0, "mean_bird_attack": 2.857, "mean_bird_health": 2.857, "mean_egg_attack": 1.429, "mean_egg_health": 1.429, "mean_body_loss": 2.857}, "old_tern": {"events": 1, "free_body_flights": 0, "native_on_home_events": 1, "mean_bird_attack": 1, "mean_bird_health": 3, "mean_egg_attack": 1, "mean_egg_health": 2, "mean_body_loss": 1}, "one_swallow": {"events": 31, "free_body_flights": 0, "native_on_home_events": 0, "mean_bird_attack": 1.29, "mean_bird_health": 2.323, "mean_egg_attack": 1.097, "mean_egg_health": 1.161, "mean_body_loss": 1.355}}}

This observes potential Egg spec at departure, not realized Nest occupation/combat retention or actual replay reward occurrence.

```json
{
  "passes": {
    "commitment": false,
    "own_tribe_above_2": true,
    "direct_bonus_above_2": true,
    "oozes_above_5": true,
    "birds_above_5": true,
    "final_board_commitment": true
  }
}
```

| E rung (100 games each, seeds4001–4100) | Focus mean place | Approx95% margin | 95% interval |
|---|---:|---:|---|
| plain_easy | 3.340 | ±0.544 | [2.796, 3.884] |
| easy_naive | 1.430 | ±0.199 | [1.231, 1.629] |
| normal_easy | 2.730 | ±0.521 | [2.209, 3.251] |

E ran on the pre-sentinel-guard frozen hash. Its 300 clean logs show the funded empty-def error path was absent; the guard changes only that path. E was not replayed. E fixtures validated 100 games per suite, every requested seed exactly once, eight distinct seats and placements 1–8, exactly one focus seat per game. Plain/Easy point mean is within 3.0–3.5; no adaptive weakening performed. Original frozen b872a6b 1000-game spread passed 19/21 strategies in 6–25% wins, none above25%; maximum22.286%. It is a historical baseline, not a fresh spread on this final candidate.


**Final fixed-round result is not a pass:** round-10 full boards show 4.342 versus 4.189, a -0.153 point gap, in this 30-lobby Hard-bot sample. The favorable final-board cohort is retained as descriptive and does not replace that headline. Other observed thresholds are own-tribe share 8.073%, Birds 9.58% picks and Oozes 26.67%. These are **Hard bot data, weak evidence**. No Bird or Burner card retuning follows: the binding best-bot direction requires better bots/hand play before card-strength conclusions.


## Corrected review checkpoint before BOTS step 1

**Gate PASS:** all ten steps; **1,258/1,258 tests, 16,100 assertions, 112 scripts**, strict clean; 368 scripts compile with zero failures. **Then soak PASS:** 100 games, fresh seeds **471–570**, **1,518 rounds / 4,774 fights / zero violations**, exit 0. Logs: `build/sim/commit-review-guard-final/`. Accepted gameplay runtime **c050419**; the final evidence-only amendment does not change it. Its 544 core/content files exactly match the clean final Hard recheck (full SHA256/proof retained in that run's `freeze-provenance.json`). The failed prior probe and first clean gate/soak remain recorded separately. Review groups A–E are committed separately and unpushed; this is the checkpoint to report before implementing the later removal instruction.


## Follow-up review with no cuts: provisional numbers and visible Nest stats

Read the follow-up to `b872a6b..7529183` on `origin/ideation/c-review-commit` (aa4427a): **0 cuts, 2 asks, 1 simplify**. The orchestrator keeps Burner's existing retune provisionally and flags it in PLAYTEST as **bot-tuned, to be judged by human play**. Accept nearly-free small-Bird trips: Old Tern's payoff is its homecoming; One Swallow trades a body for gold when replayed beside a Bird. Human playtests should watch both. No card numbers or bot strategy weights change in this follow-up, and previous Bird/Burner results remain **Hard bot data, weak evidence**.

The simplify puts known Egg Attack/Health directly on the empty Nest tile, retaining the reader explanation, occupied-unit stats and scouting privacy. Focused checks and actual phone/desktop inspection are recorded below before the merge sequence. The requested inputs are `origin/ideation/main` (47eff7a), `origin/ideation/c-review-commit` (aa4427a), then `origin/ideation/c-review-round4` (552279c), one merge at a time. Final gate and 100-game soak use the finished merged HEAD on core 2 only; immutable head stamps and logs will be in `build/sim/commit-followup-merge/`, with fresh soak seeds **874001–874100**. No post-validation amendment or push is planned.


**Tile validation:** 43/43 focused UI tests, 318 assertions (four scripts), formatting/lint clean. Numeric Ring stats are added after half-ceil exactly once, tested against a real combat-start Egg; Goose's exception, occupied-Nest hide/restore, public scout Egg cards and private scouting boundaries are covered. The tapped reader explicitly includes the Ring. Editor import generated the new test UID before committing. Log: `/tmp/nest-tile-focus-final.log`.

**Actually rendered and inspected:** [phone, 1688×780](commit-build-phone/nest-tile-phone.jpg) and [desktop, 1920×1080](commit-build-phone/nest-tile-desktop.jpg). Both show an empty Ring Nest at **6 Attack / 7 Health**, Goose's own Egg **0/2**, and an occupied **On Nest 2** with only its standing unit's stats. Badges and Nest labels fit without overlap or clipping; no tap is required. The earlier [reader-only state](commit-build-phone/nest-half-stats.jpg) is retained as the before view. No gameplay/card/bot policy changes are made.
