# Rough utility power check

Brief 6 trial, 17 Nov 2026. Agent method, not a balance decision. Surgical, mechanical route: test the costing step on existing effects before changing any content. The owner's constraint is "it needs to be rough"; this is a ten-minute costing aid, not a matchup predictor.

## Method fixed before the trial

1. Use the ten cases below, unchanged for each effect. Two parameters: ordinary body size **B = 10** (10 Attack / 10 Health) and established slot Attack **S = 10**. The small death summon is 0.4B/0.4B; the control buff adds half the carrier’s total Attack and Health (rounding each addition to the nearest integer).
2. Start with identical plain boards. Give one carrier the effect, with its real trigger and targeting. All other text is absent. Slots and enemy Guard are held identical between the effect fight and its plain comparisons. For slot cases both boards have the same buffs.
3. Fight once per case using seed 1, alternating which side owns the effect between cases. Record **friendly surviving Health minus enemy surviving Health** after the fight (zero for a mutual clear). Separately run a plain carrier at ×1, ×1.5, ×2, ×3 and ×4 of its own Attack AND Health against that same enemy. Scale its slot Attack too: total stats, not a buffed body with an unscaled slot. Other units stay unchanged. Do not scale the whole opponent board: that would dilute one card's price across seven bodies.
4. Find the *smallest* plain multiplier whose margin reaches the effect's. Report that coarse rung, not an interpolated decimal. If none reaches it, report **>×4**. If the effect performs below the unmodified carrier, flag it. These are equivalent **carrier stats in this case**, including its original body, not added bodies and not a damage multiplier.
5. Give the median of all ten rungs, rounded to the nearest half, plus the range and a good-setup example. Keep non-triggering cases: they show the setup cost. A >×4 result is censored, never silently counted as exactly four. Inspect the actual margins: a non-monotone ladder or equal margins at multiple rungs makes that case ambiguous, not precise evidence.
6. Then check the bar: Hit among the strongest, Cleave very strong, and +50% stats about ×1.5 total stats. **Do not change cases, weights or parameters to pass.** State any miss and why. No bots, whole games, searches for favourable boards or further sweeps.

Ten fixed cases (slots are zero-based F1–F4 = 0–3; B1–B3 = 4–6):

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

## Trial results

The first completed run used combat/content at `e1715630`, with the method above written before the run. The bar was already in the brief, so this was a frozen-method trial, **not a blind test**. **130 fights total:** 50 reusable plain comparisons and 80 effect fights, all ending normally, all ten plain ladders monotone. No parameter or scenario was subsequently changed to improve the ratings.

**The check misses the full bar.** The buff median calibrates, and the Hit engine is the highest median, but Cleave's median is only ×1.25. It must not be treated as a validated universal utility budget. Keep that failure when comparing a weaker Hit replacement later.

| Effect | One rough number | What that number describes |
|---|---|---|
| **Hit, as Mice use it now** | **about ×2 carrier stats** | Catapult and Pile on medians 1.75; Ballista 2. The multi-recipient Master of Engines is about ×4, sometimes >×4. Trigger and recipient count are part of the price. |
| **Cleave** | **about ×1.5 carrier stats — calibration miss** | Median 1.25, range 1 to >4. A full front-row case reaches ×3; slot-fed cases reach ×4 or exceed it. The median understates its strong setups. |
| **One death summon, a plain 4/4** | **about ×1.5 carrier stats** | Median 1.25, range 1–3. With +10 slot Attack the replacement arrives as 14/4 and both loaded cases reach ×3. |
| **Plain buff: +50% Attack and Health** | **about ×1.5 carrier stats** | Median 1.5. Seven cases read exactly 1.5; three read 1 because the final margin cannot distinguish the buff from no buff. |
| **Pigeon full front-row volley, Lieutenant, slots +10 Attack** | **>×4 carrier stats** | Case 9 kills all four enemy front units before an ordinary attack; 40 friendly Health survives. Across all ten layouts its median is 1 because eight have no slot Attack. That inactive median does not price the prepared board. |

These are **total carrier multipliers**, not multipliers of all seven units. Only the utility hook is borrowed from a real card; carriers are normalized bodies, not the printed 12/4 Catapult or 5/11 Lieutenant. Normal, non-golden copies throughout; no economy, acquisition cost, buffs from other text or lasting growth is priced.

### Working: all ten cases

Each cell is the smallest matching plain rung; `>4` means the five-rung ladder did not match. Headline numbers round medians to the nearest half; 1.25 and 1.75 are worksheet arithmetic, not precision claims.

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

For example, case 1's plain margins are `[0, 5, 10, 20, 30]` at `[1, 1.5, 2, 3, 4]` stats. Ballista kills its opponent with a free opening Hit and keeps 10 Health: the ×2 plain carrier also keeps 10, so the rung is ×2. The 4/4 death summon leaves 4 Health: it is below the ×1.5 plain margin of 5, so the coarse rung is ×1.5.

In case 9 the plain margins are `[0, 0, 0, 10, 10]`. Lieutenant gives each of four front units 10 opening damage, killing four enemy 10-Health units with no retaliation. The effect margin is +40, well beyond the +10 of the ×4 plain carrier. This establishes **>×4**, not a guessed ×5 or a claim that it wins every matchup. Case 10's back-row volley similarly kills three back units before normal attacks, leaving +30; it is a separate setup, not a front-row volley.

### What the trial shows about costing

**Hit is not one trigger.** The actual hooks tested are `mouse_catapult` (replace each attack turn with a weakest-enemy Hit), `mouse_pile_on` (a neighbour's attack triggers a Hit before its exchange), `mouse_ballista` (one opening weakest-enemy Hit), and `mouse_engines` (each back unit makes an opening Hit). Hits do not retaliate, are not attacks, and can bypass Guard and rows through the effect's targeting. Pile on can kill the target before its ordinary exchange, protecting the attacker too. A price for one opening Hit cannot be reused for every neighbour's attack or an entire back row.

**Why Cleave misses.** Lone targets and gaps offer no splash; in some dense cases the carrier dies before its own attack. Equal 10/10 bodies also clear each other so quickly that many buffs never buy another attack. The ten layouts are useful probes, but their median is not a distribution of good player setups. Cases 3, 9 and 10 show the danger that the median hides. Neither changing the averaging rule after seeing that nor replacing its headline with the best case would validate this trial. The costing step must carry setup and the active-case range alongside its rough number.

**Why the buff control is only a partial pass.** The median returns the known ×1.5 total stats, but cases 8–10 return ×1 despite those stats being present. Their final Health margins are unchanged at ×1 and ×1.5. This outcome measure misses sublethal damage and threshold improvements that leave the same final survivors. A zero observed improvement is not zero value.

**Summon and pigeon setup are paid for elsewhere.** The same established slot Attack is present on both sides and in all comparison fights. The summon reuses it; Lieutenant spends none of it to fire before ordinary combat. The volley is plain damage equal to **slot Attack**, not a full-Attack Hit, and a partial row or zero slot Attack does nothing. Wing Commander is a different effect: immediate Sortie attacks into the back row with retaliation; it was not substituted for the owner's front-row example.

For the [tier guide](tier-guide.md), convert a total multiplier M to **added in-fight value**: `(M − 1) × carrier's total stats / same-tier vanilla body stats`. Do not charge the original body twice, convert to permanent growth per turn, or count purchased slot buffs as free printed stats. E.g. ×3 on one same-tier body adds about two bodies of combat value, around the tier-4 in-fight target; >×4 adds more than three. Because calibration missed, these remain flagged estimates, not grounds to declare a card on budget or re-tier it. Goldens and repeatable scaling can change trigger counts and need their own explicit setup.

## Rerun in under ten minutes

From the repository root, with the pinned Godot installed, run `godot --headless --import` once on a fresh checkout, then `godot --headless -s res://tools/checks/power_check.gd`. The small driver uses `src/core/combat` and the real registered hooks; it prints the plain margins, effect margins, rungs, opening kills, Hits and summons. The default trial runs exactly 130 small fights, no whole games, and took about a second after import on this machine. For a new or changed Mouse/Pigeon/shared mechanic, run `godot --headless -s res://tools/checks/power_check.gd -- mouse_catapult '{"times":1}'`, replacing the id and JSON parameters. This costs exactly 60 fights (the same 50 plain comparisons plus ten effect fights). A mechanic from another tribe needs that tribe added to the loader's two-name list. In a restricted sandbox, set `XDG_DATA_HOME` and `XDG_CONFIG_HOME` to writable temporary directories before both commands.

Spend roughly two minutes specifying the exact trigger/recipients and parameters, one minute running, and five minutes checking the ten rows and writing **one number + setup + range + calibration caveat**. For a proposed weaker Hit, preserve the layouts, parameters and old results above; add its rungs and any trigger/target differences side by side. If its mechanic is not implemented, hand-work the same cases and state assumptions rather than build another simulator. Stop at ten minutes and report ambiguity. No confidence intervals, win-rate claim or proof against arbitrary enemy abilities follows from these cases.

Verification: the single-effect command reproduced Catapult's original ten rungs in 60 fights / 0.88 seconds. `./scripts/check.sh` passed every step, including 720 GUT tests, compilation, the 126-frame film check and required soaks. Sandbox runs used temporary Godot data/config directories and `FEEL_TMP` in the designated `night-media/power` directory. The 80 worksheet cells were checked against the first-run output. These checks prove reproducibility and normal engine termination, not calibration against a metagame.
