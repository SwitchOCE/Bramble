# Review: tribes 5 and 6 (Bog folk, Hunters)

Fresh cloud reviewer, 7 Nov 2026. Target `52876e8..b38b416` on `ideation/tribes56`, excluding what came in from `ideation/round3` (merge `4164d7f`). Nothing in the code was changed.

**Counts:** 9 keep, 1 cut, 0 simplify, 6 ask.

**Does it move the problem?** Yes. All three playtesters said the scout made placement "a real decision". Hard bots placed against the board they were about to fight: two Prima Donnas in B2/B3 bogged a whole back row, Bufo was set across a Russet, and Young Brock lent quarry to a Scarecrow. Two cautions. Nobody has measured a positional gain. And the scout often went stale because bots moved units between rounds.

- **Cut 1. Dr Urchin pricks Pack joiners.** `urchin.gd` bypasses the leader redirect added to `bristle.gd`. The test uses Hoglet Mother, which isn't in the slice, so the slice's only Bristle card breaks the Pack rule.
- **Ask 1.** The design's tray preview of the Prince's kiss count and of Bitter totals from auras was dropped without a note.
- **Ask 2.** Young Brock, Old Brock and the Laird show the keyword chip "At the" (the first two words of their text). Give lenders a real tag.
- **Ask 3.** Fight-log readability: no slot tags, so two units with the same name can't be told apart; borrowed Mire and Bitter show as "X's ability goes off"; "Snap" lines appear with no attack, or after the unit died; buffs are applied to dead units; the Peat King's no-room fizzle isn't shown in the play tool.
- **Ask 4.** Bot tribe rates, from my probe of unpinned lobbies (below):
  - Normal bots draft Bog folk most (31% of seats) but finish top 4 only 38% of the time.
  - Hard Hunters won 1 of 24 games.
  - Oozes fell from 20% of seats to 8%.
  - Watch these, don't tune yet.
- **Ask 5.** Bots moved their mirers and carries between rounds (Bridge Toad and Bufo between F3 and F4, and rebuilt boards in R7 and R9), so the scout lied. The designs require bots to hold carries still. Check how often a scouted unit is still in its slot.
- **Ask 6.** The soak's collector prints `trigger:on_take` as "not reached", even though the same run logged 666 Takes. This is the same alias gap the worker logged for keywords. Fix it or drop the line.

## Verdicts

| Change | Verdict |
|---|---|
| Bell step, one targeting table, patches on the ground, marks on the animal, Take witnesses | Keep. Matches design-review-3's binding calls. |
| 14 Bog folk cards plus Prince Restored and Peatling, 14 Hunters | Keep. The card text matches the design docs and their logged costing calls. The only reworded wording is in-spirit (Young Brock and Old Brock "with no quarry", Toll-Bard's "3 gold a fight"). |
| Old Mire renamed Pin / Stalled | Keep. One meaning for Mire. |
| Pack and Bristle | **Cut 1.** |
| Six bot strategies, scout-matching placer | Keep. Bots do field and aim the cards. Asks 4 and 5. |
| Lane overlay: mud strips, paw marks, reed/gold links, Poached badge | Keep. Readable at phone size (below). Ask 2. |
| Poach offers | Keep. Pool-backed, survive refreshes, expire even when frozen, explained on screen as "Poached from your last opponent. Costs 2 gold; kept through refreshes this turn." |
| Guide page "Mud holds a slot. A mark follows its quarry." | Keep. Pounce's trigger (a neighbour's quarry is hit) isn't on that page, and the in-game reminder covers it. |
| Fight log and play-tool event lines | Keep. Ask 3. |
| 30 portraits | Keep. In style beside Mag Pye, Mrs Burdock and Dr Urchin. They drift from the art direction only slightly: Bridge Toad has no TOLL sign, Tiddy Mun has no beard, Jenny shows her full face. |
| `tribes_per_lobby = 6` | Keep, provisionally. Asks 4 and 6. |
| Probe tool and focus JSON | Keep, as a reachability sample only. The worker says so too. |

## What I ran

**Gate.** `./scripts/check.sh` at `b38b416`: PASS on every step, 1,098 tests.

**Soak.** `tools/checks/soak.sh 100 111`: PASS. 100 games (seeds 111-210), 1,740 rounds, 5,303 fights, **0 violations**. Two fights ended with neither side able to attack, both old-library boards. Every slice card fired except `pipistrelle_echo`, which isn't part of this work. Counts include mire 2,288, take 666, pack 463, pounce 275, poach 61 and kiss 81.

**Mutations**, each run against `test_hunters`, `test_bog_folk`, `test_tribes56_bell` and `test_bot_lanes` (80 tests at baseline, 100 with the bot tests). Every effective mutation was caught by at least one failing test:
- Bitter floor removed
- Quarry beats the Mire lock
- Non-Hunters make Takes
- Prima Donna's once-per-enemy ignored
- Prince discounts every spell
- Ermeline's cap removed
- Tiddy Mun and Peat King unlimited
- Bridge Toad ignores the top-Attack check
- Poach never expires
- Toll-Bard's cap removed
- Laird buffs non-Hunters
- Snap picks the lowest Attack
- Joiners not flagged
- Eggs can be quarry
- The later mirer overwrites a patch
- Poach ignores tier

Two mutations survived alone, but only because each guard is duplicated: Pounce's per-cycle limit, and the Mired-joiner filter in `combat_hunt.gd` and `combat_lanes.gd`. Removing both copies of a guard fails a test.

**Cut 1, reproduced.** A directed fight: Little Nip 2/20 leads, Wick 2/20 joins, into Dr Urchin. Wick fell to 18 and Nip to 17.

**Lobby probe.** My own script: all seats unpinned, final board's tribe = 3 or more units of one tribe.

| Lobby | Bog seats / wins / top 4 / mean place | Hunter seats / wins / top 4 / mean place | Other |
|---|---|---|---|
| Normal, 40 games (seeds 91000+) | 31% / 8 / 38% / 4.95 | 13% / 7 / 55% / 4.26 | Fairies 13 wins, Hedgerow 10, Oozes 1, Birds 2 seats |
| Hard, 24 games (seeds 92000+) | 15% / 4 / 39% / 5.07 | 15% / 1 / 45% / 5.03 | Hedgerow and Fairies 9 wins each |
| Base `52876e8`, Normal, 40 games | n/a | n/a | Hedgerow 44%, Fairies 31%, Oozes 20%, Birds 3% of seats |

The samples are small. Birds were already rare before this work.

**Renders.** Inspected at 1688×780:
- the retained phone scout and combat images;
- fresh `scout_lanes_select`, `recruit_poached` and `guide_9` renders.

Mud strips ("F1 · MIRE"), paw badges, links and the Poach badge are legible. Dashed links do cross stat badges when several lanes bind. In one combat frame the Prima Donna's death prints after Nip's Pack line, with no cause shown.

**Play.** Three games, through subagents using `tools/play/play.sh`:

| Game | Result | Notes |
|---|---|---|
| Bog folk, seed 7101, Normal | 3rd | Bog cards were plentiful; three Bog players at the table. |
| Hunters, seed 7202, Normal | **1st** | Hunters were thin at tiers 3-4 (about 1 per shop in R6-8), with three Hunter players. Found Cut 1 ("enemy Dr Urchin: Bristle / Wick takes 2"). |
| Mixed, seed 7303, Hard | 4th | Hunters appeared in about 10 of 26 shops. Mire, Quarry and Pack reminders were clear. Pounce's "a unit next to this" needed two readings. |

The playtesters saw Takes, Poach and Pounce chains, Bufo's halving and the lock work as written.

**Not run:** a human playtest, a large Hard benchmark, a measured positional-gain test.

## Summary

Bog folk and Hunters are built faithfully, tested well (every effective mutation was caught), soak-clean, readable on a phone and in style. Scouting makes slots matter, and bots aim with it. One cut: Dr Urchin's Bristle hits Pack joiners, against the Pack rule. Asks: the dropped kiss and Bitter preview, the "At the" chip, log slot tags and generic lines, bot tribe rates (Bog overdrafted, Hard Hunters weak, Oozes squeezed), bots moving units so the scout goes stale, and the collector's on_take line. Keep six tribes for now.
