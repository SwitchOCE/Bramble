# Review: pass 2 build (`ideation/pass2`, 11 commits)

Fresh cloud scope review, 9 Nov 2026. Target: `git diff origin/ideation/main...origin/ideation/pass2`. Scope: `content/pass2-a.md`, `pass2-b.md` and `pass2-c.md`, as amended by DECISIONS "Pass 2 design: review calls (the build spec)", plus plan step 4 and the owner's words on traps, parity and concise wording.

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
5. **The details repeat the card text or general rules.** The owner said "If it's implied, let it be implied", and these could be cut:
   - Grey Agnes: "Each Pack unit joins once a cycle. Only the leader takes the counter-hit."
   - Old Isegrim: "It does not buff the leader."
   - Mr Pym: "Pass waits until End of Turn."
   - Goodman Hayward: "Buffs are permanent."
   - Squire Lollop: "These buffs last for this fight."
   - Mrs Clover: "Recruiting buffs are permanent…never entered the board."
   - Stone Soup: "Combat swallows do not count."
   - Sixpenny Pie: "There is no lifetime payment limit." This describes the old card.
   - Figgy Duff: "Both copies must be bought… After a pair, this skips the next turn."
   - Signor Ranocchio: "The gain stays after the fight."
   - Lob: "Only a spell aimed at this…"
   - Mrs Stork: "Among eligible Birds, longest away first."
   - Beadle's details define "a turn" again, though the spec says to define it once, in rulebook 3.1.1a.
   - Golden Hob, Lob and Silky print "Shy pays 4 gold" in the text and again in the details.
   - Elder Ooze: the "While this lives; …" sentence should be rewritten.
6. **Mrs Clover's "Twice a fight" caps only fights.** Recruit Phase summons are buffed without limit (`mrs_clover.gd:5–10`). That's literal to the text, but a reader may expect two in all. Either keep it and put "Recruiting: no limit" in the details, or cap it per turn.

## Fine

**(1) Cards against the amended spec.** These match: Wick, Young Brock, Little Nip, Mistress Russet, Grey Agnes, Old Isegrim, Beadle, Mr Pym, Mrs Clover, Mrs Mallow, Goodman Hayward, Squire Lollop, Stone Soup, Sixpenny Pie, Figgy Duff, Elder Ooze (apart from cut 1), Cut-and-Come-Again, Signor Ranocchio, Tiddy Mun, the Lantern Man, Hob, Lob, Silky, Cradle Fetch, Tom Tit, Old Tern, Jack Daw, Mrs Stork, Lamp Moth and the Nest Egg display. "Matches" covers tier, stats, text, limits and behaviour.
- The golden numbers follow the usual doubling. The spec doesn't set two of them, so the builder made a call: Pie pays 2 gold, and golden Figgy keeps "every other turn". Both are reasonable.
- Hob says "in front", where the spec says "in front of this". That wording is older than this build.
- Mallow skips Shy, and her details say so.
- Stork's "leftmost Nest" tie-break uses zigzag order, which is left to right on the staggered board.

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

**(3) Ask for Kin is off by default.**
- `GameConfig.defaults()` and `full_game()` both have `ask_for_kin: false`.
- `RecruitKin.available` checks the flag first, and `legal_actions` offers the action only when it's available.
- The UI sets the flag only from the saved Settings latch, which defaults to false, so bots and the soak never see it.
- Tests pin the default in both config and Settings.
- Nests count as Birds (`recruit_kin.gd:13`), and the "Neutral units don't count as a tribe" wording is gone.

**(4) Nothing changed beyond the spec.**
- No Hunter, Hedgerow, Ooze, Bog, Fairy or Bird card outside the spec changed. Dr Urchin and Mr Crumb change only to the new Pass wording.
- The bot changes are card hints in `cards.json` plus scoring keyed to specific mechanics: Shy departure value, Tom Tit through the Egg forecast, Lamp Moth's discount, and Stone Soup's swallow in `bot_held`. Strategy files, tribe weights and route priors are unchanged, so there is no tribe routing.
- Some dead code is left: `HeldUnits.soak_shop` and the no-op `wash_shop`, plus stale "Pass right" comments in `combat_moves.gd:11`, `board_upkeep.gd:173`, `urchin.gd:2` and `keyword_rules.gd:82`. These are cleanups, not blockers.

**(5) Wording.** The new reminders are short and match the amended text:
- Pass: "Pass X: your last unit, other than this, gains X"
- Mire: "Start of Combat: the enemy across must attack this while this lives. This waits for it, once."
- Shy: the spec's 15 words.

The problems are in the details, and ask 5 lists them.

**(6) R9 benchmark.**
- **The adapter is sound.** `tools/sim/pass2_boards.gd` builds each fixture through RecruitRules and PlayerState, strips live layers so they apply once, and asserts that the effective stats match the fixture. Each fight uses a fresh deep copy at round 9, both seats, and the same seeds.
- **The Bog diagnosis holds as "no bug".** Its turn traces show Mire binding, waits firing once, and locks ending when the maker dies. Committee's +21 Attack decides the Hedgerow mirror. Its fixture audit is honest: no numbers were raised to rescue Bog.
- **Its tribe-level reading doesn't hold**, for the reason in ask 3.

**(7) Out of scope.**
- The rulebook, deltas, engine.md and guide edits all follow the spec.
- The pass2-c Old Tern example was corrected, as the amendment asked, though its "Great buy" line still describes the old example.
- Pending portraits follow the existing convention.
- Nothing was pushed to `main`.

## What I didn't run

- I didn't rerun the 13,200-fight bench, the ablation or the 200-game soak.
- I didn't play a game in the UI.
- I didn't check the bot values numerically.
