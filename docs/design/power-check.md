# Rough utility power check

**Ten-minute use.** Run `godot --headless -s res://tools/checks/power_check.gd -- mouse_catapult '{"times":1}'`, replacing the effect and parameters. Keep the ten layouts below, body size 10 and slot Attack 10. Compare Health left at the end; when that ties, compare the carrying unit's starting Attack + Health.

Report **built around first, all-ten second**. Set up means the effect actually fired at least once; include it even if it did not help. Built around is the median of those cases. Numbers mean rough **total stats of the carrying unit**, including its body, not the entire board.

| Effect | Built around | All ten | Set-up cases |
|---|---|---|---|
| Master of Engines | ×4 | ×4 | 7/10 |
| Catapult | ×2 | ×1.75 | 8/10 |
| Pile on | ×2.5 | ×1.75 | 6/10 |
| Ballista | ×2 | ×2 | 10/10 |
| Cleave | ×3 | ×1.25 | 5/10 |
| One 4/4 death summon | ×1.25 | ×1.25 | 10/10 |
| +50% Attack and Health | ×1.5 | ×1.5 | 10/10 |
| Pigeon row volley | >×6.5 | ×1 | 2/10 |

**Limits:** these are not win rates or final card prices. They omit buying the setup, other text, long fights and goldens. Pigeon front volley >×8 and back ×5 give a median >×6.5. An effect firing does not mean this is its best board.

**Frozen after one repair and rerun.** The measure changed after seeing trial one because its +50% buff read ×1 in three cases. Buff-only calibration now reads ×1.5 in all ten. Cleave's built-around ×3 was already present in trial one under the same setup rule; the control repair did not raise it. Utility with unchanged final Health can still be missed.

## Working and rerunning

Brief 6, 17 Nov 2026; agent measurement, not a balance decision. The first trial used combat/content at `e1715630`; its implementation and report are in `02abf2f7`. No combat or content code changed for either trial. The bar was known, so neither is a blind test.

### The fixed ten layouts

Slots are zero-based F1–F4 = 0–3, B1–B3 = 4–6. Both boards use the same layout and stats, apart from enemy Guard in case 7. One friendly unit carries the effect. Other text is stripped; slot buffs are held equal between the two boards before a plain comparison is scaled.

| # | Layout on both boards | Carrier | What it exposes |
|---|---|---|---|
| 1 | One 10/10 at F1 | F1 | A lone unit, no protection or splash |
| 2 | Three 10/10s at F1–F3 | F2 | Small front row and neighbours |
| 3 | Four 10/10s, full front row | F1 | Edge carrier, dense enemy row |
| 4 | Seven 10/10s | F1 | Full board, exposed carrier |
| 5 | Seven 10/10s | B1 | Full board, protected carrier |
| 6 | 10/10s at F1, F3, B1, B3 | B1 | Gaps, adjacency and early exposure |
| 7 | Seven 10/10s; enemy F2 has Guard | B1 | Target restriction |
| 8 | Full board: front 10/20, back 20/5 | B1 | High Attack, fragile protected utility |
| 9 | Seven 10/10s, every slot +10 Attack | F1 | Reusing slot Attack, full front-row volley |
| 10 | Seven 10/10s, every slot +10 Attack | B1 | Reusing slot Attack, full back-row volley |

The parameters remain **B = 10** and **S = 10**. The death summon is 0.4B/0.4B = 4/4; the buff adds 50% of the unit's total Attack and Health, rounding each addition to the nearest integer. Each case uses seed 1, alternating the friendly side, exactly as in trial one.

### Control repair and rules fixed before the second run


The owner authorized one further round, then a freeze. This change is being made **after seeing the first-trial results**, because the +50% buff read ×1 in cases 8–10. It is not a response to Cleave's rating. Calibration will run only the plain comparisons and the buff, without new utility results.

Candidate measure: compare final surviving-Health margin first. **When margins are equal, compare the carrier's starting Attack + Health, including slot stats.** Pick the smallest plain multiplier that reaches that pair of values. This adds no weight or parameter, and makes known stats visible when final Health is tied. It does not claim that an unobserved utility benefit is worth zero. The ten layouts, BODY = 10 and SLOT_ATTACK = 10 are unchanged; plain comparisons now also include ×5, ×6 and ×8.

**Control passed; measure now frozen before the utility rerun.** The control-only run used 90 fights and returned ×1.5 in all ten cases, including 8–10. No new Hit, Cleave, summon or pigeon ratings were run or inspected during this calibration. The starting-stats comparison is a general tie-break, not a special buff score; the buff assertion only checks its answer. No further change to this measure is authorized in this round.

**Set-up rule fixed before the rerun:** an effect is set up if it actually fires at least once in the case, regardless of whether it improves the final result. For these hooks that means at least one Hit for each Mouse effect, an own-attack splash onto an adjacent enemy for Cleave, a body entering for the death summon, the stat addition for the buff, or positive opening slot damage for Lieutenant. A hook called with no recipient or zero slot damage does not count as the effect firing. All fired cases stay in the built-around median, including weak outcomes; all ten cases stay in the second median. The same event rule will also classify first-trial cases from their existing fights. There is no post-result choice of which cases count.

**Reporting rule fixed before the rerun:** report built-around median first, all-ten median second, and the number of set-up cases. If none fire, say “no set-up cases.” Compare against ×1, ×1.5, ×2, ×3, ×4, ×5, ×6, ×8, without another search. If a middle value exceeds ×8, preserve the lower bound when averaging: for example, ×5 and >×8 give >×6.5, not >×8. Keep the full first-trial table unchanged beside the new table. This is the only utility rerun; report any remaining miss and stop.


### First trial: final Health alone, comparisons up to ×4

The first run used 130 fights: 50 plain comparisons and 80 effect fights. All finished normally and all ten plain comparisons increased or stayed equal as stats rose. This is the **unchanged first-trial table**. Its buff error in cases 8–10 is deliberately retained.

| Case | Catapult | Pile on | Ballista | Engines | Cleave | Summon | Buff | Pigeon row |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2 | 1 | 1 | 1.5 | 1.5 | 1 |
| 2 | 2 | 2 | 2 | 1 | 1 | 1.5 | 1.5 | 1 |
| 3 | 1.5 | 1 | 1.5 | 1 | 3 | 1 | 1.5 | 1 |
| 4 | 1.5 | 1 | 1.5 | 4 | 1.5 | 1 | 1.5 | 1 |
| 5 | 1.5 | 3 | 1.5 | 4 | 1.5 | 1 | 1.5 | 1 |
| 6 | 2 | 2 | 2 | 3 | 1 | 1.5 | 1.5 | 1 |
| 7 | 1 | 1.5 | 1.5 | 4 | 1 | 1 | 1.5 | 1 |
| 8 | 3 | 4 | 3 | >4 | 1 | 1 | 1 | 1 |
| 9 | 3 | 1 | 3 | >4 | >4 | 3 | 1 | >4 |
| 10 | 3 | 4 | 3 | >4 | 4 | 3 | 1 | >4 |
| **Raw median** | **1.75** | **1.75** | **2** | **4** | **1.25** | **1.25** | **1.5** | **1** |

First-trial summary with the fixed setup rule applied retrospectively. The engine, treatment fights, layouts, parameters and seed are unchanged; all 80 effect Health margins match the second run. The second run's event evidence therefore identifies which identical first-trial treatment fights fired; the old ratings themselves have not been recalculated with the new measure.

| Effect | Built around | All ten | Set-up cases |
|---|---|---|---|
| Master of Engines | ×4 | ×4 | 7/10 |
| Catapult | ×2 | ×1.75 | 8/10 |
| Pile on | ×2.5 | ×1.75 | 6/10 |
| Ballista | ×2 | ×2 | 10/10 |
| Cleave | ×3 | ×1.25 | 5/10 |
| One 4/4 death summon | ×1.25 | ×1.25 | 10/10 |
| +50% Attack and Health | ×1.5 | ×1.5 | 10/10 |
| Pigeon row volley | >×4 | ×1 | 2/10 |

### Second trial: Health, then starting stats on ties, comparisons up to ×8

There was **one control-only run (90 fights)**, followed by **one effects run (160 fights: 80 plain + 80 effects), 1.04 seconds**. No utility was run during calibration. The control is ×1.5 in all ten cases, all fights end normally and all ten plain Health sequences are monotone. **Bold cells are set-up cases**, using the rule written before this run. The full first-trial table above remains beside this one for comparison.

| Case | Catapult | Pile on | Ballista | Engines | Cleave | Summon | Buff | Pigeon row |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | 1 | **2** | 1 | 1 | **1.5** | **1.5** | 1 |
| 2 | **2** | **2** | **2** | 1 | 1 | **1.5** | **1.5** | 1 |
| 3 | **1.5** | 1 | **1.5** | 1 | **3** | **1** | **1.5** | 1 |
| 4 | **1.5** | 1 | **1.5** | **4** | **1.5** | **1** | **1.5** | 1 |
| 5 | **1.5** | **3** | **1.5** | **4** | **1.5** | **1** | **1.5** | 1 |
| 6 | **2** | **2** | **2** | **3** | 1 | **1.5** | **1.5** | 1 |
| 7 | 1 | **1.5** | **1.5** | **4** | 1 | **1** | **1.5** | 1 |
| 8 | **3** | **4** | **3** | **5** | 1 | **1** | **1.5** | 1 |
| 9 | **3** | 1 | **3** | **8** | **5** | **3** | **1.5** | **>8** |
| 10 | **3** | **4** | **3** | **5** | **4** | **3** | **1.5** | **5** |
| **All-ten median** | **1.75** | **1.75** | **2** | **4** | **1.25** | **1.25** | **1.5** | **1** |

Second-trial summary:

| Effect | Built around | All ten | Set-up cases |
|---|---|---|---|
| Master of Engines | ×4 | ×4 | 7/10 |
| Catapult | ×2 | ×1.75 | 8/10 |
| Pile on | ×2.5 | ×1.75 | 6/10 |
| Ballista | ×2 | ×2 | 10/10 |
| Cleave | ×3 | ×1.25 | 5/10 |
| One 4/4 death summon | ×1.25 | ×1.25 | 10/10 |
| +50% Attack and Health | ×1.5 | ×1.5 | 10/10 |
| Pigeon row volley | >×6.5 | ×1 | 2/10 |

### What changed and what did not

**Measure repair:** compare `(final friendly Health − final enemy Health, starting unit Attack + Health)` in that order. The second value only breaks ties in the first. Use the smallest plain multiplier that reaches the pair. This is a general comparison, not a buff-specific override; only the control assertion names the buff. In case 9 the unbuffed and +50% buffed boards both end at margin zero. Their starting unit stats are 30 and 45; the ×1.5 plain unit also starts at 45, so the buff now reads ×1.5. Case 8's rounding produces 38 stats on both buffed and ×1.5 plain units.

**Separate causes:** the repair changes only the three buff answers among values already measurable in trial one. Higher comparisons turn the old `>4` entries into Engines ×5/×8/×5 (cases 8/9/10), Cleave ×5 (case 9), and pigeon >×8/×5 (cases 9/10). Reporting built-around medians changes which cases are summarized; it does not change any individual fight or choose successful cases after seeing them.

**Cleave and the bar:** Cleave actually splashes in cases 3, 4, 5, 9 and 10: ×3, ×1.5, ×1.5, ×5, ×4. Their median is ×3, a very strong signal when built around. Across all ten it remains ×1.25; inactive cases hide its benefit. Master of Engines is ×4 built around, while the other Mouse uses are ×2–×2.5 and must keep their own prices. This supports the qualitative warning for Cleave and multi-unit Hit, not a claim that every Hit trigger is among the strongest effects in the entire game. No further tuning or simulations follow from this round.

**Remaining blind spot:** the tie-break preserves known starting stats; it does not recover utility that changes damage or timing but leaves the same final Health. The buff passing is necessary, not proof that every unknown effect is priced correctly. Even in set-up cases, no outcome improvement can mean “the measure missed it,” not “worth zero.” Decimal quarters come from averaging two middle case answers, not precision in a balance price.

**Exact current effects:** Catapult (`mouse_catapult`) replaces its turn with a weakest-enemy Hit; Pile on (`mouse_pile_on`) Hits before a neighbour's attack exchanges damage; Ballista (`mouse_ballista`) makes one opening weakest-enemy Hit; Master of Engines (`mouse_engines`) gives each back-row unit an opening Hit. Free Hits take no retaliation. The pigeon row is Lieutenant (`pigeon_lieutenant`): positive **slot Attack** dealt across a full row before ordinary attacks. It is not full-Attack Hit or Wing Commander's immediate Sortie attacks. The summon reuses the slot buff: with +10 slot Attack it enters as 14/4. No acquisition cost is waived by the measurement.

For the [tier guide](tier-guide.md), added in-fight bodies are `(M − 1) × the carrying unit's total stats / same-tier plain-body stats`. Do not count the original body twice or treat this as permanent growth per turn. A high number is a reason to pay for utility through tier, stats, recipient count or trigger conditions, not a ban on creativity or permission to re-tier cards without design review.

### Rerun note

On a fresh checkout, run `godot --headless --import` once, then `godot --headless -s res://tools/checks/power_check.gd`. This small driver uses `src/core/combat` and real registered hooks, with no bots or whole games. The default costs 160 small fights; `-- control` costs 90 and prints only the +50% buff. For one new effect use `-- mouse_catapult '{"times":1}'`, replacing the registered id and JSON parameters: 90 fights, the same ten layouts and eight plain comparisons each. Another tribe needs its name added to the loader's two-name list. If a replacement changes how its effect is logged, define its setup event before running; do not choose it after seeing ratings. Restricted sandboxes can put `XDG_DATA_HOME` and `XDG_CONFIG_HOME` in writable temporary directories.

Budget two minutes to state the effect and when it fires, one to run, and five to inspect ten answers and write built-around median, all-ten median, setup count and caveat. A weaker Hit must be compared separately with Master of Engines, Catapult, Pile on and Ballista as applicable, preserving both historical tables. If it is unimplemented, hand-work these same cases instead of writing another simulator. No new calibration round or extra layout search is part of this frozen method.

The owner's original scope and reasons: [brief 6](../workstreams/backlog-briefs.md#6-a-rough-power-check-for-utility-effects) and [full words](sources/2026-11-17a-backlog-scope-shop-tooltips-data.md): “I don't want them doing endless simulations and ... writing Python scripts that simulate a million different boards”; “Something like Cleave is incredibly good. Something like Hit is unbelievably good”; “I don't want to completely eliminate creativity.”

Verification for the frozen second round: `./scripts/check.sh` passed every step (720/720 GUT tests, compilation, film and required soaks). All 80 treatment Health margins match trial one; only the comparisons and summary rule changed. The two parameters and all ten layouts were checked against `02abf2f7`. No third effects run was made.
