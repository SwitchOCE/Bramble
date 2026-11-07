# Review: round 3 fixes (20b41ab..52876e8 on ideation/round3)

Fresh cloud reviewer, 7 Nov 2026. Nothing in the code was changed.

**Counts:** 12 changes reviewed. 7 keep, 1 cut, 1 simplify, 3 ask, plus 1 ask on a playtest-2 item that was left unfixed. Gate: 977/977 tests pass. Soak: 0 violations.

**Does it move the problem?** Partly. Round 3 fixes the defects that the three playtesters agreed on, and the numbers hold up when rerun. Damage and shop odds work exactly as claimed. The Acorn runaway is smaller but not gone. None of this adds strategic depth on its own, so whether "good" becomes "very good" needs a fresh playtest.

**Cut**
- The Acorn keyword (`content/schema/effects.json`) still says "Great Hoard 20". The card now pays 16, so a new player reads the wrong number on every Acorn.

**Simplify**
- The new Shy keyword text says "Its gold arrives next turn" but no longer says how much. The old text said 2 gold. Put the amount back.

**Ask**
- Hiring Fair went from 6 to 4 gold with no measurement. It gives a repeatable tier-6 pick for 4 gold from tier 5.
- Phone: with a bird selected, the purse, Tier and Refresh are still hidden. The detail panel also cuts off the Fly South text mid-sentence and overlaps it with the next line.
- Alderman Dozey is the largest unit in every probe (64/71 and 56/76). Doubling plus Acorns is the runaway that remains. Separately, Old Mother Mast paid an Acorn when Mast itself was bought from the shop.
- Unfixed from playtest 2: the board shows Hedge Witch's Hex one lower than the fight applies. The board said Hex 1 and the fight applied -2; Hex 2 gave -3; Hex 3 gave -4.

## What I ran

| Check | Result |
|---|---|
| `./scripts/check.sh` | All steps pass. 977/977 tests, 11,574 asserts, 1m52s. The first import aborted (exit 134) and the retry passed. |
| `tools/checks/soak.sh 100 77`, run afterwards | Exit 0. Seeds 77–176: 1,745 rounds, 5,314 fights, 0 violations, 3 `no_attacks` endings. Pennywort Snail never fired. |
| `tools/sim/round3_probe.gd`, seeds 41–52 at 52876e8 | Matches the worker's final numbers exactly: openings tempo/economy/climb 4.812/4.438/4.250, maximum loss 12, the same shop table. |
| Same probe, fresh seeds 53–64, at 20b41ab and at 52876e8 | Before → after. Maximum loss 30 → 12. Round-15 mean loss 15.6 → 10.4. Biggest unit 101/113 → 56/76, Dozey both times. Round-18 mean largest unit 32.7/41.2 → 25.8/30.8. Opening spread 0.72 → 0.50. |
| Rules broken on purpose | With Money Spider set back to per 5, and the Treasurer cap removed, `test_round3_saving` and `test_round3_acorns` fail (5 and 4 assertions). Restored afterwards; tree clean. |
| 2 games, `tools/play/play.sh`, Hard | Seed 77, Brother Bracken: 3rd. Seed 78, Mousewife, greedy opening then Acorns and Treasurer: 6th. |
| `tests/ui/render_screens.sh` at 1688×780 | recruit_held_bird, scout_held, recruit_slice, recruit_late, guide_2. |

Not run: a placement bench, Hiring Fair's effect on win rate, a real phone.

## Verdicts

| Change | Verdict | Why |
|---|---|---|
| Changeling Start of Combat fires once | keep | It was a bug. A 20-seed regression test covers it. |
| Glossary entries, Shy and Nest notices, front/behind guide, Whistlers text, who emptied the board, Pipkin warning, `@handles` | keep, but simplify Shy | All read clearly. Handles made item plays reliable in both games. The Shy text lost its gold amount. |
| Phone layout | ask | Idle recruiting is fixed, and the scout columns line up. The selected-bird state still hides the purse and buttons, and its detail text is clipped. In scout, unit stat badges still cover some opponent slot labels (F2, B3). |
| Shop tier odds | keep | `UnitPool.draw_by_odds` picks a tier first, skips empty tiers and renormalizes, with separate unit and spell streams. That is what rulebook 6.1.3a says. In play, a refreshed tier-4 shop showed 5 tier-4 units. Shops at tier 3 to 6 still showed lower-tier units. |
| Hiring Fair 6 → 4 gold | ask | No data behind the price. Bots cast it 187 times in the soak. |
| Damage: floor 4, survivors halved, cap 12 | keep | Confirmed on fresh seeds. My greedy opening cost 4+7+9+9 Health by round 8, so greed now has a price. A tie on an empty round 1 still costs nothing, which is fine. |
| Great Hoard 16; Treasurer per 3 gold, capped at +8/+8 | keep; cut the stale keyword text | Holding versus cashing survives. One Hoard gives each Treasurer +5/+5, and cashing it gives 16 gold, so it's still a real choice, and Cut-and-Come copies share the cap. Holding past 24 gold now adds nothing. Cost: a few loose Acorns (2–4 gold) give a Treasurer +0 or +1, so the early hold barely pays. |
| Dozey per 2 gold rounded up; Mast's shared once-a-turn key | keep, plus an ask | Works as described. Dozey stays the top unit in every sample. |
| Money Spider per 3 carried | keep | The test catches the old value. Saving 3 gold now earns 1. A modest, bounded change. |
| Nest replacement wording | keep | Matches the rule. |
| check.sh marker fix | keep | It removes a false failure; it doesn't loosen the gate. |

## Rule text read as a new player

Clear: Mast ("After your first unit buy each turn"), Dozey, Treasurer, Spider, Borrowed, Mired, front/behind.

Unclear:
- The Acorn keyword's 20.
- Shy's missing amount.
- "enemy Mrs Posset's ability goes off" doesn't say what happened.
- Hex shown as 1 while the fight applies -2.

## Summary

Round 3 does what its numbers say. I reproduced them exactly, and fresh seeds agree: the late-loss cliff is gone, shops show the bought tier, and the biggest units are smaller. The holding-versus-cashing choice survives, though it's thinner early. Fix the stale "Great Hoard 20" keyword and Shy's missing gold amount. Decide on Hiring Fair's price, Dozey as the remaining runaway, and the phone selected-bird panel. These are fixes, not depth. A fresh playtest decides whether "good" has become "very good".

## Follow-up (52876e8..5292785)

Reviewed 7 Nov 2026, same method. Nothing in the code was changed.

**Counts:** 10 commits reviewed. 8 keep, 1 simplify, 1 ask, 0 cut. Every round-3 finding is fixed. Gate: 991/991 tests, 11,868 asserts. `soak.sh 100 99`: exit 0, 1,737 rounds, 5,298 fights, 0 violations.

**Simplify**
- The DECISIONS entry "Cloud review 6" says Hiring Fair went back to 6 gold "following the owner's instruction". No owner instruction exists: it was this review's ask item. Correct the wording. The price itself is fine.

**Ask**
- Phone, selected-bird state (cosmetic): the board is smaller now. The SHOP row label is clipped, the BACK label sits under the hero portrait, Posset's "In 1/1" chip overlaps her Belly badge, and the "+2/+2" Ring chip hangs below F1.

| Finding | Fixed? | Evidence |
|---|---|---|
| Acorn keyword said "Great Hoard 20" | yes | The values now come from the item cards. The selected-bird render shows "Great Hoard 16". |
| Shy didn't say how much gold | yes | It now says "Gain 2 gold next turn (4 if golden)". |
| Selected bird hid the purse, Tier and Refresh, and clipped its text | yes | Rendered at 1688×780: purse, Tier, Refresh and Freeze all show beside a full-height reader, and the Fly South and Acorn text is complete. |
| Scout labels covered | yes | The scout render shows all seven opponent labels, including F2 and B3. |
| Hex shown one lower than applied | yes | One calculation (`hex_amount`) now feeds both the display and the fight, and the test covers 0–11 spells. Not replayed in a game. |
| Mast paid for its own purchase | yes | The trigger now ignores Mast's own purchase. A Mast already on the board still pays when you buy another Mast. Tested. |
| Hiring Fair at 4 gold, unmeasured | yes | Back to 6 gold in the card and in rulebook 6.1.3a. |
| Dozey is the remaining runaway | yes, fairly | See below. |
| Pennywort Snail never fired (soak note) | yes | It had been working all along but logged no trigger. It now logs real gains, and the soak counts them: 75 buys and 55 gains in seeds 99–198. Not requested, but small and it answers my note. |

**Dozey: a fair cap, not removal.** It keeps both halves of its idea: Acorn feeding and the three-turn double. The new ceiling stops permanent bonuses at +12/+12 (+24/+24 golden), so a plain Dozey tops out at 14/17 before slot effects and auras, which still stack. That's a strong tier-3 carry with a stated limit. When capped, feeding is refused and the Acorn is kept, so nothing is wasted. I reran the probe on seeds 53–64 and got the worker's result: the biggest unit was 54/36 Cluricaun, against 101/113 Dozey on the same seeds before round 3. Dozey was still the largest unit in 93 player-rounds, peaking at 34/40, so it still matters. Maximum loss stayed 12. Openings tempo/economy/climb were 4.28/4.56/4.66.

One side effect: the ceiling also absorbs buffs from other cards, such as Bonfire, Annis or a triple, once Dozey is capped. The card says "Permanent buffs cap", so it's stated. A player may still be surprised when a buff does nothing.

**Anything new broken?** I found nothing. The gate, the soak and the reproduced probe are clean. `_set_attack` and `_set_health` now go through the capped `add_permanent`, but that only changes behaviour for units with a printed cap, and only Dozey has one. Pipistrelle Echo didn't fire in this soak, while Pennywort Snail now does. That looks like sampling, not a fault.

Not run: games through `play.sh` on this delta, a placement bench, a real phone.

**Summary:** 8 keep, 1 simplify, 1 ask, 0 cut. Every finding from the first review is fixed; I checked by render, test and probe. The Dozey ceiling keeps both halves of its idea, feeding and doubling. Simplify: the Hiring Fair entry in DECISIONS credits an owner instruction that doesn't exist. Ask: cosmetic label and chip overlaps in the phone selected-bird state.
