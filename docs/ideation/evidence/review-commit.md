# Review: tribe commitment build (`113b573..b872a6b` on `ideation/commit`)

Fresh cloud reviewer, 7 Nov 2026. Nothing in the code was changed.

**Counts:** 19 verdicts: 11 keep, 3 cut (fix), 1 simplify, 4 ask.

**Does it move the problem?** Partly.
- **"Committing doesn't pay": yes.** On fresh seeds the result holds, though the headline figure overstates it.
- **"Generic stat engines decide games": no.** The build says so itself.
- **"Birds weak and fiddly": no.** Birds are now picked, but they still place worst, and the Egg rule adds a fiddly loop.

**Cut (fix before merge)**
1. `tools/play/play_view.gd:271` still says "empty Nests hold a 0/2 Egg in fights". That is wrong under the new Egg rule, and playtesters read this screen.
2. Hiring Fair's card says "5 or more of your units". The code (`recruit_discover.gd:76`) and rulebook 6.2.4 count only units on the board, so away Birds and hand units don't count. Change the card text to "on your board".
3. Tests don't catch a golden unit doubling its tribe bonus. Changing `board_unit.gd:119` to `tribe_attack * factor` passes every relevant suite, because the tests check the `tribe_attack` field and not the unit's total Attack. Add a total-stat assertion.

**Simplify**
4. The bonus strip shows "+0/+0" on all five tribes from turn 1, with no label. Its only explanation is a tooltip, and phones have no hover. Hide a tribe's chip until its bonus is above 0, or add a "Tribe bonus" label.

**Ask**
5. **The Egg rule (item 13)** makes Fly South free for the Birds whose text is on play or on sale: Chiffchaff, One Swallow, Mrs Jay and Old Tern. Their text doesn't matter in a fight, so the Egg loses nothing, and they come home to trigger again. In play I flew and replayed Chiffchaff every cycle for +1 Attack, and Swallow for +1 gold, at no cost. A Hard bot ran the same loop (Chiffchaff 5/6 by round 6). Flying is a real choice only for Jack Daw and Mother Goose. Options: Eggs keep half the Bird's stats, or a flown Bird returns to the shop tier rather than to hand.
6. **Charcoal Burner is dead:** 1 of 240 final boards on fresh seeds (0 in the build's run), and 12 buys in 100 soak games. It's no longer a real choice. Retune it (for example, cap 6, golden 12) or accept that it's dead.
7. **Five tribes per lobby (item 6) has no measured effect.** The same 30 seeds with 6 tribes: committed boards place 3.37 against 5.48, Oozes still take 20.8% of picks and Birds 16.3%. Commitment pays just as well with 6 tribes. Keep it for variety (the owner's 27 Oct note: "a certain number of tribes per game... to keep things varied"), but not as part of the commitment fix.
8. **The Queen launders the tribe bonus.** `teind.gd` pools the victims' `unit.attack`/`unit.health`, which include the separate tribe layer. A +3/+3 Fairy that is destroyed hands its bonus to other Fairies as permanent stats, on top of their own bonus. Pool printed + permanent stats only, or accept it.

**Keep:** Stand Behind Me, Bread from the Back, Harvest Supper and the tribe-bonus rule, Hiring Fair's guarantee, the bot priors, the Queen's Fairy-only split, Fairy Monarch, Elder Ooze, Moss Ooze, the Laird, and the flat Whistlers.

## What I ran

| Run | Result |
|---|---|
| `./scripts/check.sh` | PASS, 1,215 tests, 15,891 assertions, strict hook clean |
| `tools/checks/soak.sh 100 91` | PASS, 0 violations. Two legitimate no-attack stalls (seeds 144 and 174). **Fairy Monarch is listed as "never fired" despite 38 buys.** Its bonus is applied as an aura with no trigger log, so the soak can't see it. Its new card was not shown firing in this run. |
| `commit_probe.gd` on fresh seeds 47000–47029, 5 tribes | 6+ of a tribe: 3.809 (n=115); ≤4: 5.500 (n=68). Picks: Hedgerow 22.9% (3.62), Fairies 12.9% (3.74), Oozes 18.8% (4.73), Birds 20.4% (5.74), Bog 14.6% (5.06), Hunters 10.4% (3.76). All five pass flags are true. |
| Same seeds, `tribes=6` | 6+: 3.366; ≤4: 5.484 |
| 11 rule breaks against 13 suites (255 tests) | 9 caught. Missed: golden doubling (item 3), and Moss without its Ooze check, which is probably an equivalent mutant because only Oozes hold units in recruit. |
| 3 games with `play.sh`, Hard | Birds: 8th, out in round 8. Oozes: 8th, round 9. Hunters: 6th, round 12. |

The 11 rule breaks: Supper cap 4; golden doubles the bonus; flying pays sale gold; Goose's Egg mirrors her stats; no landing cooldown; Queen splits to all units; Whistlers ignore Eggs; 6 tribes; Moss on any unit; Elder Ooze uncapped; Supper twice a turn. Each was reverted.

**The headline figure is inflated by early eliminations.** Final boards of seats knocked out early hold few units, so most of the ≤4 group are early losers. Restricting to full boards (6 or more units) at a fixed round shrinks the gap:
- Round 10, 5 tribes: 4.00 (n=84) against 4.38 (n=58).
- Round 10, 6 tribes: 3.74 against 4.24.
- Round 8, 5 tribes: 3.90 against 5.00.

Commitment pays, by about half a place in mid-game. The baseline had the same confound, so the direction of the change is real. I did not rerun the baseline.

## The questions in the brief

- **Did a new dominant strategy replace the old one?** No. The 30 winners came from 12 different builds, with Hedgerow taking 11 wins. Hedgerow was already the leader. At round 15 the tribe bonus is 6.6% of all stats, so neither Hedgerow nor Fairies runs away with it. The most common units on top-2 boards are Standing Committee, Old Mother Mast, Beadle, Grizel and the Laird. That spread is healthy.
- **Generic engines:** at round 15, spells give 24.6% of stats, Rings 12.1%, the tribe bonus 6.6%, and same-tribe unit text 0.8%. The largest unit averages 51 stats, 28% of its board, the same as before the build. In my Oozes game, the winner fought round 9 with a tier-1 Bridge Toad at 23/28. Nearly all of the "own tribe" payoff is one tier-5 spell, Harvest Supper. In about ten tier-5 shops I never saw it, while Stand Behind Me showed up constantly (627 casts in the soak).
- **Birds:** 20% of picks, but the worst placement (5.74). 37 of the 49 Bird seats chose `birds_summer_winter`, which places 6.08; `birds_highway` places 4.0 (n=10). Birds aren't strong by any route yet, boring or not. The weak placement is partly the bots' build choice.
- **Charcoal Burner:** dead (ask 6). **The Queen:** a real choice. She was on 19 final boards with an average place of 2.79.
- **Clarity:** Bread from the Back and Stand Behind Me read cleanly in play, and the kin bonus showed exactly as written. Elder Ooze is long, but it fits the reader. Hiring Fair's wording is item 2.
- **Is the bonus visible?** Yes, as a strip of icons, but it is noisy and unlabeled (item 4).
- **Stacking with Rings, Bellies, golden units, copies, Fetch and Mag Pye:**
  - Golden units, triples and combat construction keep the bonus as a separate layer. The test gap is item 3.
  - Fetch's copy is a summon, so it gets no bonus, which matches "as printed".
  - Mag Pye takes text only.
  - Mirror Eggs carry the Bird's bonus as a body.
  - The Queen's leak is item 8.
  - Two Moss Oozes stack ×2, and gold plus normal gives ×3. That's acceptable within the tribe.
  - Gabble Ratchet now gets two full bodies: the mirror Egg dies, then its Bird lands. It's rare (4 buys in the soak), so watch it.
- **Owner notes:** I found no conflict. Five of six tribes per lobby fits the 27 Oct note.

## Summary

The gate and the soak pass. On fresh seeds, committed boards do better, but by about half a place in mid-game, not the two places the headline shows. Nothing new dominates. The build doesn't touch generic stat engines, and Birds still place last. Fix three things: the stale 0/2 Egg text, Hiring Fair's wording, and the missing golden-bonus test. The orchestrator should decide four: the Egg rule (it makes Fly South free for four Birds), the dead Charcoal Burner, five tribes per lobby (no measured benefit), and the Queen passing on the tribe bonus.

## Follow-up: `b872a6b..7529183` (7 Nov 2026)

I skipped the round4 merge (`ede4f80`), which was already reviewed; it caused no conflicts. Nothing in the code was changed.

**Counts:** 0 cut, 2 ask, 1 simplify. Everything else keeps.

**Ask**
1. **Charcoal Burner's retune rests only on bot numbers.** It moves from tier 5 to 4 and its cap from 4 to 6 (golden 12). The DECISIONS entries justify both purely by Hard-bot uptake, which the owner's 8 Nov note calls weak evidence ("the Hard bots will be giving us subpar data"). It is no longer dead: the soak shows 33 buys and 51 fires, against 12 and 14 before. A human can read the choice from the card and hint: "Keep 11 gold to burn 6: each unit behind gains +3/+3 permanently; 5 gold remains. Or spend that gold on a better buy." Judge the numbers by human play, not by bots.
2. **Old Tern and One Swallow still fly almost free.** The half-stat Egg closes the full-body loop. A Chiffchaff at 1/2 now leaves a 1/1 Egg, and the cost grows with the Bird's buffs and tribe bonus, so for a built-up Bird flying is a real choice. But Old Tern (1/3 leaves a 1/2 Egg) gives up 1 Health for three fights to Discover a unit of its tier. One Swallow gives up 1 Health for +1 gold. For small Birds, Fly South is still nearly always correct. Accept this, since Tern's whole card is its homecoming, or give the Egg no stats when the Bird is unbuffed.

**Simplify**
3. The Nest tile still shows no Egg stats. The 3/5 appears only in the tapped slot reader (`nest-half-stats.jpg`). Put the Egg's stats on the tile.

**Checked and kept**
- **The 3 cuts are fixed.**
  - The play tool's Egg text now matches the rule (verified in a live game: "half their Bird's Attack and Health, rounded up").
  - Hiring Fair now says "on your board".
  - The golden total-stat assertions exist, and the build's notes say both stat mutations now fail.
- **Chip display:** chips at +0 are hidden, and a "Tribe bonus" caption is shown.
- **The Queen fix:** she now pools printed stats plus permanent buffs only, without the tribe layer.
- **Fairy Monarch** now fires in the soak (31 fires); it had never fired before.
- **The Easy and Normal removal is complete:**
  - `BotLevel.ALL` is just Naive and Hard, and Naive is a yardstick for tools and tests only.
  - The menu offers one choice, and its record shows no level words (tested).
  - The legacy record sections migrate once, with sanitized data.
  - Old play saves from a non-Hard level are refused with a clear message.
  - `PLAYTEST.md` says "one bot strength".
  - The bench suites and tests for the retired levels are removed.
  - The owner notes match `origin/ideation/main` exactly.
- **Hard's play is unchanged.** I ran `commit_probe` on 4 all-Hard lobbies (seeds 88100–88103) at `887d9fc` and at `7529183`. All 432 rows are byte-identical.
- **Card changes resting only on bot numbers:** only the Burner (ask 1). The Egg rule and the Health change from 1 to 2 rest on a mechanical argument: they remove the 1/1 fixed point. The Bird route prior changes bot choices, not cards.

**Runs**
- `./scripts/check.sh`: PASS, 1,250 tests, 15,984 assertions.
- `tools/checks/soak.sh 100 1201`: PASS, 0 violations, with two legitimate no-attack stalls (seeds 1224 and 1242). Gabble Ratchet never fired in this sample.

**Follow-up summary:** No cuts remain. The orchestrator should decide two things: whether the Burner's bot-only retune stands until people play it, and whether small Birds may still fly almost free. Put the Egg's stats on its tile.
