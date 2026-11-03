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
