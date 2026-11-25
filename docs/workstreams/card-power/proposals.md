# The balance process and the league: what changes

From the card power session, 25 Nov 2026. **The owner said yes to all of it on 26 Nov: "I was happy with all of the proposals so proceed".** The documents named at the end are changed to match. The evidence is in [trace.md](trace.md), [known-cases.md](known-cases.md) and the results page (https://claude.ai/artifact/EiM34sXPXawpkmDDHNocHr).

The owner: "there's missing pieces or there's waste or both", and "We need to build our processes to catch this kind of stuff."

## The path a card takes

The common path, cheap first (definitions and costs: [definitions.md](definitions.md)):

| Step | What | When | Cost | Who acts |
|---|---|---|---|---|
| 0 | First-sight read: the owner, or a fresh agent, marks any card that looks too strong or too weak on sight | When a card is designed or changed | Minutes | Design |
| 1–2 | The card report: `tools/league/card_report.sh <match>` | After every kept bot version, and on any balance match, before its records are deleted | 5 minutes | Referee, or whoever played the match |
| 3 | Left out of the shop, for cards the report marks, cards the owner names, and new or changed cards | Same day | 10 minutes a card | Balance |
| 4 | A read: one line that explains the mark, or a proposal to the owner with the card shown as in game | Same day | Minutes | Balance |

Edge cases, each with its own route:

| Case | Sign | Route |
|---|---|---|
| A card no bot buys | Bought on under 1 offer in 100 by every bot that sees it, with its tribe in play | A fight test that adds a fresh copy to recorded boards; then a forced-in whole-game test; then a design read. Unexplained after that: to the owner as "weak or unfound" |
| A card a bot is built around | Left out of the shop reads far above every other card | Treat the number as an upper bound. Compare with leaving out the card's whole tribe |
| A card whose worth is outside fights | Bought a lot, little fight text | Left out of the shop is the only measure; run it |
| A card that grows over turns | Marked on stat growth | Left out of the shop, alone and with the cards that share its mechanic |
| A tier the bots rarely reach | Under 100 offers to every bot | Say "not tested" in the report. Do not read it as weak or fine |
| Two stages disagree | A design estimate and a measurement point opposite ways | The measurement on a strong field wins; both are shown to the owner |
| A balanced game | Nothing clears a worth-a-look line | Expected. The report says "nothing marked" and stops |

## Decision 1: make the card step standing

1. **Run the card report after every kept bot version and on every balance match, before records are deleted.** Evidence: it marks Sword-heir and Old Brock on two different fields in 5 minutes; the 18 Nov data would have done the same. Today the league deletes records before any card reading.
2. **Left out of the shop for every marked card, the same day.** Evidence: Sword-heir reads +1.11 and +1.53 places; nothing else is over half a place.
3. **A marked card may be changed before a bot passes its stopping test.** The owner said yes to this on 25 Nov. Evidence: the 22 Nov Badger flag waited three days behind "tune only from passed bots". This rewrites step 3 of `docs/workstreams/balance/plan.md`.
4. **Teams hand their card measurements to balance.** Evidence: the blue team's 18 Nov table had Old Brock first; the league brief kept it private. The teams still keep their bots' value tables to themselves.
5. **Keep the known-cases list as a test set** ([known-cases.md](known-cases.md)). Any new measure or process change is run against it first. Evidence: it showed the weak field over-reading The Eighth Plague, and bought against passed catching none of the three cards.
6. **When two stages disagree, the measured result on a strong field wins, and the owner sees both.** Evidence: on 20 Nov the fix round and the pitch gave opposite answers on Old Brock and the owner saw one.

## Decision 2: the league

1. **Build the climbing field from recent strong versions only.** Today 8,000 of its 15,000 runs are from the two starting bots; blue-c17 comes first in 69% of games on it and red-c14 in 46%. A check to add: the candidate's average place on the field must be worse than about 3.5, or the field is rebuilt. Evidence that it matters: the weak field over-read The Eighth Plague and made Overrun look five times as deadly.
2. **Score generality by taking tribes away, in place of "locked to each tribe".** The balance target today reads "locked to each tribe, a bot averages between 3.8 and 5.2". The owner does not want one-tribe bots. Proposed: play the best bot with its most-played tribes left out of the shop, and report how far it falls and what it ends on. One match, 9 minutes. Evidence: red falls 0.79 places and plays three other tribes near the field's middle; blue falls 0.87 and wins 55 games in 1,000. A one-tribe bot cannot pass this.
3. **Rotate model families between runs, and run the two-strategy restarts before a bot counts as passed.** The owner asked for the rotation. The restarts are already in the third run's plan.
4. **The fight log records every body that joins a fight,** with its kind (summon, return, reserve) and the card that caused it; and the log's documentation says in each field's first line what the field leaves out. Evidence: the `summons` field leaves out returns and reserves, and a number forty times too low reached the owner.
5. **Look at tier pacing.** The shop stays at tier 3 until about round 11; red reaches tier 6 in 2% of games and blue in 38%. Tier 4 to 6 cards are barely tested. **The look, 26 Nov (on the strong-field match, 1,000 games a bot): it is the bots, not prices they cannot reach.** Each bot has the gold for the next tier at the start of a turn two to four rounds before it buys it (tier 3 affordable from round 5, bought at round 7 or 8; tier 4 from round 8 or 9, bought at 11 or 12). Blue tiers up on a fixed schedule: rounds 4, 8, 12, 13 and 14 in every game. The economy's target (rulebook 10, from the 12 Nov tier-price decision) is most players at tier 5 around turn 7 or 8; the bots are at tier 3 then, and the median game ends at round 12 or 13. Not known: whether staying low is right play today because the strongest cards are at tier 3 (Sword-heir, Gleaner), or a habit the climb never tested. Route: after Sword-heir is changed, each team tests "tier up two rounds earlier" as an idea in its next climb, and this look is repeated on the new field.

## Decision 3: the design stage, and what to drop

Add to the `bramble-design` skill's costing:
1. **A measured price for any effect that grows** (per turn, per death, per unit on the board): its stats at rounds 6, 10 and 14 on a real recorded board, not a made-up one. Evidence: the costing read Old Brock as "on target at round 11" on one made-up board; on recorded boards his text is first of all cards from round 13.
2. **The same effect at two tiers is compared.** Evidence: Sword-heir (tier 3) and Old Brock (tier 6) have nearly the same text; The Eighth Plague (tier 5) does Gleaner's job (tier 3) and does it worse.
3. **A first-sight read is asked for and recorded** (step 0 above). Evidence: the owner's was right "within two seconds".

Drop:
1. **Made-up-board fights as evidence in a pitch.** They can illustrate. Their scripts were not kept and the one that mattered was wrong.
2. **The generic power check** (21 Nov, about 1,300 fights of generic effects on plain boards). None of the four cases was in it. The card report replaces it.
3. **The stopping test as a gate on card changes.** Keep it as the test of a bot. Four chains of 27 to 37 matches, 6 to 8 hours each, held a flag that 15 minutes of card tests confirm.
4. **The league's nine per-card numbers** (section 9 of the league brief). None separates a strong card from a strong board, and none was run in the third run. The card report replaces them.
5. **Bought against passed as a measure.** It stays in the report as a hint. It caught none of the three cards.

## Documents that change

- `docs/workstreams/balance/plan.md`: step 3 (when a card may change), and "What counts as balanced" (tribes taken away in place of locked to each tribe).
- `docs/workstreams/third-run/ghost-plan.md` and `third-run-brief.md`: the climbing field's make-up and its strength check; the card report before records are deleted; what balance gets.
- `docs/workstreams/bot-league/brief.md`: section 9 (per-card numbers), and the hand-over of teams' card measurements.
- `docs/workstreams/league-data/README.md`: the card report runs before a match is pruned.
- `.claude/skills/bramble-design/SKILL.md`: the three costing additions.
- `tools/league/league/LOGS.md` and the fight log: a `joined` field holds every body that joins a fight, by kind and cause (harness code, which is the ghost orchestrator's; it hears before the change merges).

## Would this have caught the four cards?

- **Sword-heir and Old Brock:** yes, at step 1–2, on the first match with records after they were made. Both are marked by pick rate and by text off.
- **Brock Cub:** marked on stat growth. The single card then reads as no loss when left out; the Grudge cards together read 0.74 places. So the process finds the mechanic, which is where the strength is.
- **Overrun:** yes. Keyword off is in the report.

What it still cannot do: say anything about cards no bot buys beyond "refused", or about tier 6, until the edge-case routes above are built and the pacing question is answered.
