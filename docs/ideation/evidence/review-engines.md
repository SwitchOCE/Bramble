# Review: engines adoption and build-5 delivery fixes

Fresh cloud reviewer, 8 Nov 2026. Targets: (a) `25c68bf..9bed45a` on `ideation/engines`, (b) `8c78def..788e6b5` on `ideation/main`. No code changed.

**Counts:** 11 keep, 1 cut, 2 simplify, 5 ask.

**Does it move the problem?** Partly. Last Blow ends the 0-damage late ties, and lifting the cap at four makes late losses count. Both help with "stalled" endings. Harvest Supper at tier 3 adds a capped reward for committing to a tribe. Nothing here touches the uncapped generic engines (Charcoal Burner, the Queen's split) that playtest 3 ranked #1. Last Stand as built makes games longer, not more dramatic. In 40 same-seed bot lobbies the game ran 1.8 rounds longer and comebacks did not rise. 77% of saves fired before the last four.

**Cut**
1. Last Blow gives the wrong side the win when Ichneumon Wasp's parasite finishes the wipe. The parasite kill goes through `lose_health` (`combat_moves.gd:232`), not `_land`, so the credit stays with the previous kill. Probe: the Wasp's side should win; side 0 wins, with `kind=attack`.

**Simplify**
1. Last Stand: make it active only once four or fewer heroes are left, which its name and design reason (the top-four cliff) imply. As built it's a spare life for everyone in the middle game.
2. `BoardUpkeep.ring_stats(_unit, …)` has an unused parameter, and `tools/sim/engines_probe.gd` / `summarize_engines.py` serve only the rejected Ring candidate.

**Ask**
1. Put Last Blow and Last Stand behind `GameConfig` keys, as the cap and floor already are. Right now `GameConfig.defaults()` (the BG baseline) has no ties either, and the [BG] 9.9.2 test was rewritten to match.
2. Add a session-level test that a ghost fight never spends Last Stand. That mutant survived.
3. Supper at tier 3 dilutes Stand Behind Me in the shared tier-3 spell draw. Over the same 100 soak seeds, Stand Behind Me casts fell from 599 to 331. Does the positional spell deserve that?
4. UI polish: no Last Stand marker in the lobby strip; "before cap" printed right above "Cap lifted"; the combat log has no Last Stand line.
5. Wording: DECISIONS' "Why" leans on bot numbers (comebacks 17→29.5%) that my rerun doesn't reproduce, and the build-5 delivery text calls the guide-checker change "reviewed" before any review ran.

## What I ran

- `./scripts/check.sh` on `9bed45a`: all steps passed. 375 files compiled, **1,268/1,268 tests, 16,173 asserts**, strict hook ok.
- Then `tools/checks/soak.sh 100 2301`: 100 games, 1,662 rounds, 5,323 fights, **0 violations**, 3 no-attack ties. Engines fired: Supper 267, Last Four 306, Last Stand 203, Last Blow 80. I ran the same soak on base `25c68bf` for comparison: 1,511 rounds and 4,809 fights. That is about 10% more rounds with the engines.
- **Mutations** (one at a time, full suite each): 12 valid mutants, 10 caught, 1 equivalent, 1 survived.
  - Caught: Supper back to tier 5; the cap never lifting; Last Stand from 1 Health; Last Stand reusable; Last Blow off; Last Blow on Start of Combat wipes; full survivor damage on a Last Blow; the 4-damage floor removed; owner side used for attack hits; a draw spending the save.
  - Equivalent: using `blow_side` whenever it is set.
  - Survived: a ghost fight spending the save in `game_session._fight`.
- **Last Blow probes** (scratch GDScript, not committed):
  - Posset's death effect wins both attack orders.
  - Hoglet Mother's death summon prevents the wipe, so the summoner wins normally.
  - Cradle Fetch copying Posset is credited normally.
  - Eggs are ordinary units here.
  - Only the parasite case is wrong.
- **Last four**: 40 bot-seat lobbies (Hard, seeds 5000–5039) on both commits. Bot evidence, so weak by the owner's 8 Nov note.

| | Base | Engines |
|---|---:|---:|
| Rounds per game | 15.4 | 17.2 |
| Rounds with ≤4 alive | 3.5 | 3.9 |
| Duel rounds | 1.55 | 1.55 |
| Health leader at four left won | 20/40 | 20/40 |
| Winner from the bottom two at four left | 12/40 | 10/40 |
| Last Stands per game | – | 6.6 (61 of 263 with ≤4 alive) |

- **Three `play.sh` games** (seeds 7201–7203, hero option 1). My own scripted buy/tier/sell policy drove `play.sh`, one command per call, with no injected state.
  - All three finished **8th in round 10**, so I never reached the last four. I watched it through the lobbies above instead.
  - In each game Last Stand fired in round 9 with all 8 heroes alive and bought exactly one round.
  - Last Blow decided two early fights for 4 damage and read correctly.
- **Phone:** I inspected the build's 1688×780 screenshots (result, Last Stand, hero panel, guide). They fit. I rendered nothing new.

## Gaming and edge cases

- The save can't be held back for later, since it fires automatically. PLAYTEST.md invites "sell out for one late turn and rely on the save". That's a real, once-only decision, and it adds rounds.
- No stalling route found. Draw tolls kill through a ready save, by the rule.
- Supper isn't always correct: once a turn, +3/+3 per tribe, 0.33 casts per player-game in the soak.

## Test changes

The rewritten tie tests (combat, Quick, empty Ring) now assert the new rule, and the empty-Ring test kept its point with a death count. The placement-fixture change (`end_turn` → `_eliminate`) is fair. It still tests ranking by Health, which was its subject. The fights only changed the starting Health, and no rule was weakened. The Nightshade fixture only gained fields.

## Range (b)

Keep all three fixes:
- Bots show "Choosing a hero" before they pick.
- The waiting panel text fits (the test now checks bounds).
- The whole-game guide still rejects bot numbers and raw ids (tested). Only the lobby-tribe filter was scoped out, which suits a whole-game guide.

## Summary

Gate and soak pass, and tests catch most broken rules. Last Blow and the lifted cap help with stalled endings. Supper rewards tribe commitment at a cost to Stand Behind Me. Fix the parasite credit (cut). Limit Last Stand to the last four: as built it lengthens games by about 1.8 rounds, without more comebacks. Gate both rules in config and add a session ghost test. The generic stat engines that playtest 3 ranked first remain untouched.

## Follow-up: fixes 9bed45a..6659bb2

**Counts:** 0 cut, 2 ask. Every earlier cut, simplify and ask item is done, except ask 3, which the orchestrator kept with a logged reason. I accept that call.

**Ask**
1. The lobby's Last Stand marker is cut off at the plaque edges, at both 1688×780 and 1920×1080 ("ast Stand: locked", "lockec"), and it shortens hero names. In most games it reads "locked" on all eight plaques. Show it only from four heroes left, and add a layout check that would catch the clipping.
2. Last Stand now makes the last four 1.4 rounds longer (bot data, below), but no more lead changes. Watch for this in the next human playtest: does that extra time feel tense or drawn out?

**Checks of each fix**
- **Cut 1, parasite credit: fixed.** My original probe (the Wasp's parasite finishing the wipe) now gives the win to the Wasp's side (`kind=effect`, source = the Wasp). With `GameConfig.defaults()` the same fight is a tie.
- **Last Stand only at four or fewer: confirmed.** In the soak, all 100 saves came with four or fewer heroes left. In the 40-lobby rerun, all 104 did. In my own game, the save stayed locked with eight heroes alive.
- **Battlegrounds baseline has both rules off: confirmed.** `defaults()` sets `last_blow` and `last_stand` to false, and the [BG] tie tests are back to their original assertions.
- **Mutations:** 10 valid mutants, all caught. One more was invalid (an unused-variable compile error) and I replaced it with a valid one.
  - Last Stand at any count, at five, at three, and ignoring its flag.
  - A ghost fight spending the save. This one survived the first review.
  - Last Blow ignoring its flag.
  - The baseline with Last Blow switched on.
  - The parasite not crediting the kill, or losing its owner.
- **The two fixtures (0203944) record the new format, not the old rule.**
  - The Nightshade health-loss event gained `source: null` and `owner_side: -1`. Nightshade never kills, so it gets no credit. The fixture matches what the code passes. Strictly, Nightshade has a unit behind it, but this hides no bug.
  - The state and standing contract lists gained the new Last Stand fields.
- **Gate:** `./scripts/check.sh` passed, with **1,278/1,278 tests and 16,254 asserts**.
- **Soak**, run after the gate: `tools/checks/soak.sh 100 2501`, 100 games, 1,584 rounds, 4,913 fights, **0 violations**. Engines fired: Supper 272, Last Four 371, Last Stand 100, Last Blow 65.

**40-lobby rerun (seeds 5000–5039, same probe as before; bot data, weak evidence)**

| | Base 25c68bf | First build | 6659bb2 |
|---|---:|---:|---:|
| Rounds per game | 15.40 | 17.18 | 16.45 |
| Rounds with ≤4 alive | 3.48 | 3.90 | 4.90 |
| Duel rounds | 1.55 | 1.55 | 1.75 |
| Winner from the bottom two at four left | 12/40 | 10/40 | 11/40 |
| Health leader at four left won | 20/40 | 20/40 | 20/40 |
| Last Stands per game | – | 6.6 | 2.6, all in the last four |

The orchestrator's 200-seed figures (16.7 rounds, 5.07 last-four rounds, 53/200 comebacks) agree with these.

**Full games** with `play.sh`: I played two, using the same scripted policy as before.
- Seed 7301 finished 8th in round 8. Seed 7302 finished 7th in round 9.
- Neither reached the last four, so the save correctly never fired.
- Last Blow decided two early fights, each correctly.

**UI:** I inspected the orchestrator's review screenshots at both sizes.
- The result plaque now reads "7 + 1 toll = 8", with no "before cap" line.
- The combat log has a Last Stand line.
- The guide page fits.
- The only problem is the lobby clipping above.

**Summary:** The parasite cut is fixed, Last Stand fires only at four or fewer, and the baseline has both rules off. Gate, soak and all ten mutants pass. Remaining asks: lobby Last Stand text clips on both sizes, and the last four now runs 1.4 rounds longer in bot lobbies without more lead changes. 0 cut, 2 ask.
