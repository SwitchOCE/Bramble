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

## From the UI QA and architecture reviews (4 Nov, ~01:40)

9. **Card text that doesn't fit.** Small cards first move sentences that are only a keyword name ("Hunker.") to a chip above the name (question 13), so the trigger stays visible, then shrink the font, and only then cut with "…". Today nothing needs cutting at desktop sizes. The full text is always in the inspector. Would you rather small cards show keywords only, or the trigger only?
10. **Keyword reminders in the fight log.** Added during QA, not asked for: the first time a keyword shows up in a fight, its reminder text follows as a dim line. Keep it?
11. **Where the architecture lessons live.** `docs/architecture/prototype-lessons.md` grades architecture-notes' eight recommendations against the prototype code and lists Godot gotchas. It is written for real development, but `proto/*` never merges into `main`. Should it go to `main`, and where? Its closing list is a set of proposals for you (for example, scripts for new mechanics and data for numbers), not decisions.

## From the UI fixes and scenarios review (4 Nov, ~02:00)

12. **Card text on phone.** Rules text now shows in full on every card at desktop size. On a phone it is tiny: the smallest is about 7 px, and even unshrunk board-card text is about 9 px, against the usual 11–12 pt phone minimum. Tapping a card opens the inspector with full-size text. Does readable on-card text on phone matter yet, or is the inspector enough for now? Making it readable means bigger cards on phone, or less text on them.
13. **New keyword chip.** A sentence that is only a keyword ("Hunker.", "Peck 2.") moves to a small chip above the card's name, so the rest of the rules text fits. Cards had no chip before. Keep it?
14. **Smaller art for long text.** A card whose text is still too long after that gets a shorter portrait (art about 30% shorter). Keep it, or keep the art full and cut the text?
15. **Scenario replays.** A loaded scenario replays its own seed until you edit it, so what you see matches its "Watch" line. Once edited, each Fight uses a new seed. Is that what you'd expect?

## From the theme review (4 Nov, ~02:15)

16. **Design-lab looks in the playable build.** The gauntlet's top two looks are switchable from the main menu and the dev panel ("Look: Plain | Folk Print | Woodcraft"), so you can compare them in real play: Folk Print scored 226 and Woodcraft 225. Plain stays the default. They went in before you'd seen the gallery, so they decide nothing. Keep them, swap in another direction, or take them out?
