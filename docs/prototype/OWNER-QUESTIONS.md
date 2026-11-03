# Questions for the owner from the overnight prototype

Collected as reviews raise them. None of them blocked the night's work; the prototype picked something and carried on.

## From the spec's scope review (4 Nov, ~00:10)

1. **Filler units.** The pool has 16 library units and 24 plain stat-line filler units. Keep that, or cut filler so the 16 mechanics show up in shops more often? (Tier 4 has no library unit; Tier 6 has one.)
2. **Watching bot fights.** Is there any use for watching other players' fights (bot against bot)? Not built tonight.
3. **Live lobby.** The prototype fights each bot's board from the same round, live, instead of async snapshots (rulebook 2.1.4, a decided Bramble rule). Is that fine for playtesting?

## From the UI's scope review (4 Nov, ~00:35)

Settled as prototype picks for tonight; overturn either in the morning:

4. **Screenshots in git.** The UI's screenshots are committed in `docs/prototype/screens/` so you can browse them, re-rendered only at milestones (about 3 MB each time). Or keep them out of git?
5. **Portraits as placeholder card art.** Cards use the six Ink B folio portraits by tribe (so every Hedgerow unit has the same face), instead of the flat tribe colours the plan named. Keep, or go back to colours?

## From the integration's scope review (4 Nov, ~00:50)

6. **Seed.** Picked: every new game starts from a random seed, which the dev panel shows and lets you type in to replay a game. Seeds 1, 2, 3… per launch would be the alternative.

## From the core's milestone B scope review (4 Nov, ~01:00)

7. **Whistle-only boards.** Followed library entry 10: a side whose only units have Whistle can't attack, so a Marmot-only board ends the fight at once, and a waiting Dormouse wakes when only Marmots are beside it. The spec had worded it the other way (whistles keep the fight going until the 200-attack limit).

## From the QA soak (4 Nov, ~01:10)

8. **Marmot-only stalemates.** In 200 bot games, 21 of 8,667 fights ended with only Marmot Lookouts (Whistle) left on both sides. Today that's a draw (library entry 10, rulebook 9.9.1). Should a board with only Whistle units left count as a draw, or as a loss?
