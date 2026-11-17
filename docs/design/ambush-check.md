# Ambush: original, quarter and frozen final revision

**Final rules:** Ambush deals **half current Attack, rounded up**, once per unit per fight across every source. Bodkin is the capstone: **pile-on Ambushes deal full Attack**, normal or golden, still one use. Lieutenant keeps the row charge: on a full row, each original unit makes one ordinary attack against the enemy across, taking retaliation; an empty across slot is skipped.

**The half revision is frozen after this one round. Most medians still tie the quarter version.** Bodkin increases from **×1 / ×1** to **×2 / ×1.5**, below its original **×2.5 / ×1.75**. The smaller strike alone still reads ×1 in most of these plain-board cases. That is the observed answer, not evidence that half damage does nothing. No layout, weight, parameter or measurement rule was changed to improve it.

## Every affected card: built around / all ten

Each pair is **built-around median / all-ten median**, in total normalized carrying-unit stats, including the original body. The quarter column is retained exactly from the first Ambush implementation (`20e85db2`, now rebased as `4bb53b29` with identical gameplay content); the original is `2e0b9081`. Normal copies, all combat text, the same ten layouts, body size 10 and slot Attack 10. Actual printed-stat differences, gold, acquisition cost and a fully tribal board are not priced.

| Card | Original Hit | Quarter Ambush / Health | Final half Ambush / charge | Set-up cases original / quarter / final |
|---|---|---|---|---|
| Cousin | ×2.5 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 6 / 6 / 6 |
| Needle Page | ×2.5 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 6 / 6 / 6 |
| Hedgerow Scout | ×1.5 / ×1.25 | ×1.5 / ×1.25 | ×1.5 / ×1.25 | 7 / 7 / 7 |
| Harvest Piper | ×2.5 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 6 / 6 / 6 |
| Shrew Cutpurse | ×2.5 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 6 / 6 / 6 |
| Thimble Captain | ×1.5 / ×1 | ×1.5 / ×1 | ×1.5 / ×1 | 5 / 5 / 5 |
| Needle Pikeman | ×3 / ×2.5 | ×1 / ×1 | ×1 / ×1 | 9 / 9 / 9 |
| Toothpick Ballista | ×2 / ×2 | ×1 / ×1 | ×1 / ×1 | 10 / 10 / 10 |
| Spoon Catapult | ×2 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 8 / 8 / 8 |
| Fencing Master | ×2.5 / ×1.75 | ×1 / ×1 | ×1 / ×1 | 6 / 6 / 6 |
| Master of Engines | ×4 / ×4 | ×1 / ×1 | ×1 / ×1 | 7 / 7 / 7 |
| King Speck | ×3 / ×3 | ×3 / ×1.5 | ×3 / ×1.5 | 7 / 7 / 7 |
| Dame Bodkin | ×2.5 / ×1.75 | ×1 / ×1 | ×2 / ×1.5 | 6 / 6 / 6 |
| Lieutenant | >×6.5 / ×1 | ×1 / ×1 | ×1 / ×1 | 2 / 2 / 7 |

**The broad “every card well below original” bar is not claimed.** Scout and Captain still tie because their bodies and normal Cousins remain unchanged; King Speck's built-around median also ties, though its all-ten number halves. Lieutenant's all-ten number remains at the ×1 floor. Bodkin intentionally retains a stronger one-use opening as the owner-directed capstone. The revision preserves summon counts, payoff rules, Master selection and buffs, printed stats and tiers rather than rebalance those to force a score.

## What these numbers can and cannot see

The check compares final friendly-minus-enemy Health, then starting carrying-unit Attack + Health when tied. Against equal 10/10 bodies, a single half-Attack Ambush still often fails to prevent the full ordinary retaliation, so it can finish with the same Health as a quarter strike. The other units are plain: the cases do not measure several Ambushers combining their openings on a tribal board. A printed 2-Attack Cousin deals 1 at either fraction after rounding; slot Attack can make the distinction matter. **×1 is not a claim that the utility has no value.**

Bodkin's full opening does change the observed outcome: its built-around median is ×2 and all-ten ×1.5. Master and Ballista still reach ×3 in fragile-backline case 8. Lieutenant's row charge is neutral in these matched plain-board cases; its real benefit with attack triggers, Cleave and differently built rows is outside these cases. Its seven active cases now include rows without slot buffs, so its setup group differs from the original and quarter groups of two.

The owner's explicit revision was “HALF of current Attack,” full-Attack Bodkin as the capstone, and Lieutenant's row charge that trades. These exact changes were made once, measured once, then frozen. There is no further tuning in this round.

## Rules and setup fixed before this run

Ambush keeps the same one-per-unit allowance across Pile on, Ballista, Catapult and every Master. Returns retain spent uses; windfury, goldens and several Masters never refill them. A newly summoned Cousin is a new unit. Ballista opens against the weakest enemy; Pile on joins a neighbour; Catapult Ambushes before its first ordinary attack and then trades. Master reinforces only the leftmost back unit by +4 Attack (+8 golden) before asking it to Ambush. Pike, Fencing Master and Cutpurse still pay only on pile-on, and Pike gains once.

Lieutenant reuses `attack_now` with an explicit across target and **no immunity**. It snapshots a full living row and commands each original unit in reading order; dead, dying or unable attackers and absent/dying targets are skipped, with no fallback. The command continues after Lieutenant dies, but replacement summons and returns inherit no command. Normal attack/attacked hooks, Thorns, Fury, Cleave and retaliation apply. Across overrides normal Guard/front-row selection, including a back-row charge. Golden and windfury add no commanded attacks, and out-of-turn attacks do not move the normal pointer.

Setup was fixed before running: each full card must actually strike, summon or give a positive buff. For Lieutenant specifically, the original needs positive opening damage, quarter needs a positive temporary Health buff, and final needs an actual friendly out-of-turn attack event—even one stopped by Thorns. A no-op trigger is not setup; poor fired outcomes are never dropped. The table shows all three setup counts.

## Reproducible, bounded comparison

The [frozen check](power-check.md) keeps `_cases`, `_matches`, `_median`, BODY, SLOT_ATTACK and LADDER byte-for-byte unchanged. Each version used **220 fights: 80 plain comparisons and 14 cards × ten cases**. All three finished normally. One additional live-effects/control run used 160 fights; the +50% buff still reads ×1.5 in all ten. No bots, whole games, new boards, seed searches or parameter sweeps were used for these numbers.

The exporter reads original `2e0b9081` and rebased quarter `4bb53b29`, copies only their small Mouse/Pigeon/shared scripts and data into ignored build folders, and remaps their own preload paths. It does not change tracked content or Git history. The engine's `hit` primitive keeps historical truncation by default; Ambush alone requests rounding up. With the two parent commit objects available locally, run from the final Ambush revision:

```sh
python3 tools/research/ambush_baseline.py
python3 tools/research/ambush_baseline.py --quarter
godot --headless -s res://tools/checks/power_check.gd -- --cards res://build/ambush-baseline
godot --headless -s res://tools/checks/power_check.gd -- --cards res://build/ambush-quarter
godot --headless -s res://tools/checks/power_check.gd -- --cards
```

Each command prints ten per-card answers, event evidence, setup flags and both medians. Single-effect commands automatically include the +50% buff wiring check (100 fights total); the default live-effect mode also includes it. Its ×1.5 result follows from the same stats by construction, not independent calibration. All five live tribes load. On a restricted filesystem, use writable `XDG_DATA_HOME` and `XDG_CONFIG_HOME`. On a fresh squashed checkout, obtain the historical commit objects before exporting. Run one Godot at a time.

Choices and owner direction: [taste-ambush.md](../workstreams/night-18-nov/taste-ambush.md). The earlier tables in `power-check.md` remain unchanged historical evidence. This report retains the complete quarter column, including its ties, rather than overwriting it with the final revision.

Verification before the final commit: `./scripts/check.sh` passed all steps, including **734/734 tests**, compile, film, both required soak sets with zero violations, and all six fault plants. Focused content tests passed 338/338. Original and quarter answers match the previously published values; each historical/current version ran once for 220 fights, and the live/control run used 160. The +50% control remains ×1.5 in every case. No further gameplay or measurement changes were made after these results.

PR 123 review verification after rebase: `check.sh` passed on night/power (720 tests) and night/ambush (734 tests), including both soak sets. All fourteen Ambush summaries and setup counts reproduce unchanged. Gameplay and test files match the frozen `50c13958` tree exactly; only the checker/docs and reachable quarter-baseline reference changed.
