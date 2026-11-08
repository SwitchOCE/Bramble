# Review: pass 2 build (`ideation/pass2`, 11 commits)

Fresh cloud scope review, 9 Nov 2026, of `origin/ideation/main...origin/ideation/pass2` against pass2-a/b/c as amended by DECISIONS "Pass 2 design: review calls".

**Counts: 2 cut, 6 ask, the rest fine.** About 30 cards and 6 rules were checked.

**Does it move the problem? Partly.** Parity holds at 16 per tribe, 3/3/3/3/2/2, and tests pin it. Every named trap and dominant card got its amended fix, and the new rules work as specified. Bog is still the open problem. On the R9 boards it loses almost every fight, and the Mire wait, its main fix, changes 1 result in 8,800. The fixtures are too uneven to say how weak Bog really is (see 6).

## Cut (fix before merge)

1. **Elder Ooze's "Drips count" isn't true.** The details say so, and so does the spec (pass2-b:82–84). But Wee Wobbly's Drip enters through `combat.summon_into` (`wobbly.gd:34`), which doesn't set `came_out`, and `CombatHeld.emerged` returns early without it (`combat_held.gd:234`). Elder never buffs a Drip, and no test covers it. That is a silent fizzle. Either make Drips count and add a test, or delete "Drips count" from the details.
2. **The Pass note always says "Lands at End of Turn."** It's in `recruit_view.gd:566`. Dr Urchin's Pass ("After this pricks") lands right away in combat (rulebook 12.1.6), so the UI is wrong for that card. Only say "End of Turn" for recruiting Passes.

## Ask (orchestrator's call)

1. **Beadle Warrenby lost "Your summons Spill."** The build follows the DECISIONS line word for word, and that line leaves Spill out. But the spec text and its competitors line ("plus Spill on any tribe's full board") keep it. Costing quoted the text without Spill, and it's unclear whether that was deliberate. Losing it removes one of the Hoard route's Acorn sources. Confirm it was meant.
2. **No test for "Early Spoils doesn't pay on ties."** I changed `winner >= 0` to `winner >= -1` (`game_session.gd:789`), so a tie paid the second side, and all **1,557 tests still pass**. The code is right, but a stated rule has no guard. One assertion would cover it.
3. **The R9 fixtures aren't matched on spend.** All boards assume 62 base income, but they spend very different amounts:

   | Boards | Gold spent | Stats |
   |---|---|---|
   | Oozes high | 69 | 118 |
   | Fairies high | 63 | 98 |
   | Hunters high | 58 | 88 |
   | Bog high | 48 (14 unspent, 1 Supper vs 2) | 72 |
   | Bog low | 34 (28 unspent) | 35 |
   | Birds low | 41 | 65 |

   Gold spent tracks the matrix, so the matrix partly measures the spending, not the tribes. Before anyone retunes Bog from the 0.0% and 0.3%, rebuild the fixtures to a common spend (for example, ±3 gold and the same Supper count), or say plainly that the bench isn't a tribe ranking.
4. **The Mire wait does almost nothing on these boards.** In the paired ablation, turning it off changes 1 result in 8,800 fights. The bench is meant to watch the Bridge Toad and Peat Cutter gold rate, and at 0.59 a fight the Peat Cutter is already above the 0.5 trigger costing named for "three times in all". The soak is mixed chaos, not lobbies, so this isn't conclusive. But it's a reason to decide on the fallback now, not later.
5. **Details repeat the text or general rules** ("If it's implied, let it be implied"). Trim: Agnes (Pack rules), Isegrim ("does not buff the leader"), Pym, Hayward, Lollop, Clover, Soup ("Combat swallows…"), Pie ("no lifetime payment limit", which describes the old card), Figgy, Ranocchio, Lob, Stork; Beadle's details redefine "a turn" (spec: once, in rulebook 3.1.1a); golden Hob/Lob/Silky print "Shy pays 4 gold" in text and details.
6. **Mrs Clover's "Twice a fight" caps fights only**; Recruit Phase summons are buffed without limit (`mrs_clover.gd:5–10`). Literal, but readers may expect two in all: say so in the details, or cap per turn.

## Fine

**(1) Cards.** Everything else matches on tier, stats, text, limits and behaviour, across all six tribes, Lamp Moth and the Nest Egg display. Golden Pie (2 gold) and golden Figgy ("every other turn") are reasonable builder calls the spec left open. Hob's "in front" (spec: "in front of this") predates this build. Stork's "leftmost" tie-break uses zigzag order, which is left to right on the staggered board.

**(2) Mechanics and tests.** I ran GUT in the cloud: 1,557 of 1,557 pass on the branch. Then I mutated each new rule and ran `test_pass2*`, and the full suite for the survivor:

| Mutation | Caught by |
|---|---|
| Pass searches from the front instead of the end | 3 tests |
| Pass may land on its source | The suite floods errors in `attack_order.gd` and never finishes. It's caught, but not by a named test. |
| Mire wait disabled | 2 tests |
| Shy never leaves | 4 tests |
| An unaimed spell buffs Shy | 1 test |
| Spoils in round 5 | 1 test |
| Spoils against ghosts | 1 test |
| Spoils on ties | **not caught (ask 2)** |
| Tier 1 shows 3 units | 2 tests |
| Stork returns a Bird flown this turn | 1 test |

**(3) Ask for Kin is off.** `defaults()` and `full_game()` set it false; `RecruitKin.available` checks the flag first and `legal_actions` offers it only then; the UI sets it only from a saved Settings latch that defaults false, so bots and the soak never see it. Tests pin both defaults. Nests count as Birds; the "Neutral units" line is gone.

**(4) No changes beyond spec.** No other tribe card changed (Urchin and Crumb only take the new Pass wording). Bot changes are `cards.json` hints and mechanic-keyed scoring (Shy departure, Tom Tit via the Egg forecast, Lamp Moth, Soup in `bot_held`); strategies, tribe weights and route priors are untouched. Leftovers to tidy: dead `soak_shop`/no-op `wash_shop`, stale "Pass right" comments (`combat_moves.gd:11`, `board_upkeep.gd:173`, `urchin.gd:2`, `keyword_rules.gd:82`).

**(5) Wording.** The Pass, Mire and Shy reminders are short and match the amended text; the problems are in the details (ask 5).

**(6) R9 benchmark.**
- **The adapter is sound.** `tools/sim/pass2_boards.gd` builds each fixture through RecruitRules and PlayerState, strips live layers so they apply once, and asserts that the effective stats match the fixture. Each fight uses a fresh deep copy at round 9, both seats, and the same seeds.
- **The Bog diagnosis holds as "no bug".** Its turn traces show Mire binding, waits firing once, and locks ending when the maker dies. Committee's +21 Attack decides the Hedgerow mirror. Its fixture audit is honest: no numbers were raised to rescue Bog.
- **Its tribe-level reading doesn't hold**, for the reason in ask 3.

**(7) Out of scope.** Rulebook, deltas, engine.md and guide edits follow the spec; the Old Tern doc example was corrected as asked (its "Great buy" line still describes the old one). Nothing touches `main`.

## What I didn't run

- I didn't rerun the 13,200-fight bench, the ablation or the 200-game soak.
- I didn't play a game in the UI.
- I didn't check the bot values numerically.
