# Wave 1 fun probe: checking the testers' moments, and the tally (10 Nov 2026)

The brief is `../../briefs/wave1-fun-probe.md`. Its one criterion: at least two of the three testers each name a moment that their game log confirms and that beats their control game.

**Result: go. All three moments check out.**

Board totals are the Attack + Health of the tester's own board in `play.sh log`, taken before and after the moment.

| Tester | Moment | Log, before → after | Control game's best | Verdict |
|---|---|---|---|---|
| A | Fairies, R16: the golden Fairy Monarch triples Ring size 5 → 15, with the Queen of Elfland | 262 → 660, +398 (`tester-a/game2-fairies-log.txt:19-20`) | Hedgerow, +22 in a round | confirmed |
| B | Fairies, R16: the golden Queen eats two units, then the golden Monarch triples Ring size | 293 → 1,249 (`tester-b/g1-fairies-log.txt`, R15–R16) | Hunters, never above +20 in a round | confirmed |
| C | Birds, R10: a golden Great Lump on Chiffchaff's Nest reaches 59/81 | 181 → 272. The Lump alone (140) is bigger than the whole control board until R12 (`tester-c/game1-birds.log:13-14`) | Hunters, peak board 114 | confirmed |

## What came up in more than one report

Counted across the three reports, and held to the step's two criteria (09i). Everything below is reported, not deciding.

1. **The rebuilt tribes leave the flat tribes far behind (3 of 3).** End boards reach 2,000–4,000, against about 100–120 for the flat tribes, so every control game felt hopeless. This is expected while four of the six tribes are still pass 2; wave 2 rebuilds them. Between the two rebuilt tribes the gap is small: tester A ended at 2,759 with Birds and 3,906 with Fairies.
2. **Birds' homecoming keeps doubling (A and C; B saw one huge Swallow decide late fights).**
   - Tester A: Old Tern went 19 → 38 → 86 → 208.
   - Tester C: the Lump reached 820/1,082 by R18.
   - Skilled Birds boards were 459–772 at R12. The bots' committed median is 270.
   - Proposed fixes: a fixed gain per homecoming (A), doubling only base stats or capping each trip's gain (C).
3. **Early game is slow for the rebuilt tribes:**
   - Fairies (A, C): Ring sources were scarce until T6, and Cluricaun needs every slot Ringed at a tier-up.
   - Birds (B): early flights emptied the board, and B lost 5 of the first 7 fights. B proposes that a Bird leaves a half-stat Egg by default.
4. **One-off reports:**
   - Whirligig Beetle (Hunters) moved enemy units onto their own bigger Rings (B).
   - A Discover that completes a triple pulls both board copies into hand. This is the Battlegrounds rule, but it cost B their two Queens mid-plan.
   - How to thank a Shy unit isn't shown (A).

## Calls

The calls are logged in `../../DECISIONS.md`, "Wave 1 fun probe: go, and what the testers raised".
