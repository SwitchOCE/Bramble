# The runaway-growth rule on Battlegrounds cards (11 Nov 2026)

Owner's ask: "test it on some Battlegrounds cards... only tier 4 units and above... and see what it thinks." 24 tier 4+ minions picked for edge value (doublers, trigger doublers, stat eaters and copiers, permanence converters, linear scalers, removed cards). Fable and Sonnet applied the rule blind, from card text, without patch history; a third agent looked up what Blizzard did (hearthstone.wiki.gg patch sections, official notes, forums). Blizzard rarely gave reasons, and the pool rotates every season, so "removed" alone is weak evidence.

| Card | Fable | Sonnet | What Blizzard did |
|---|---|---|---|
| Stone Age Slab | pass (guess) | pass | Buffed twice; in pool |
| Corrupted Myrmidon | pass | pass | Tuned by base stats many times; removed Feb 2026 |
| Banana Slamma | pass | pass | Called "the most broken minion ever added" on forums; tier and cost raised, removed, returned doubling Attack only |
| Mirage Conjurer | BREAKS | pass (guess) | Removed after 3.5 months |
| Flaming Enforcer | pass | pass | Unchanged; in pool |
| Chronormu | BREAKS (guess) | pass (guess) | Raised a tier, then removed after 9 weeks ("clearly overperforming", press) |
| Arcane Behemoth | pass | pass | Nerfed, reverted, removed |
| Ball of Minions | pass | pass (guess) | Removed after a season |
| Brann Bronzebeard | pass | pass | In pool almost always; bug fixes only |
| Drakkari Enchanter | pass | pass | In pool; bug fixes only |
| Argent Braggart | BREAKS (guess) | pass (guess) | Removed Apr 2024 |
| Persistent Poet | BREAKS (with Glyph Guardian) | BREAKS (guess) | Reworded, bug fixes; in pool |
| Lieutenant Garr | pass | pass | Tuned, removed twice |
| Upbeat Duo | BREAKS (guess) | BREAKS (guess) | Tuned, removed twice |
| Archlich Kel'Thuzad | pass | pass | Removed three times |
| Utility Drone | pass | pass | Per-Magnetization bonus retuned many times |
| Amalgadon | pass | pass | Removed: endgame boards "very similar" |
| Choral Mrrrglr | pass | pass | Rotated in and out |
| Tidemistress Athissa | pass | pass | With Stormscale Siren, Naga "scaled too large, too quickly" (Blizzard, via press); Siren pulled |
| Living Prison | pass | pass | New; in pool |
| Famished Felbat | pass | pass | Nerfed late, removed |
| Lantern Lava | pass | pass | Removed 8 days after returning |
| Maritime Extortionist | pass | pass | Nerfed after 14 days |
| Thieving Rascal | BREAKS (guess) | pass (guess) | Raised a tier, removed twice |

What it shows:
- **No healthy staple was killed.** Brann, Drakkari, Slab and Enforcer all pass. The flags are cards Blizzard removed or that a top player calls loops on paper; Poet is the one flag Blizzard tolerates.
- **The biggest real problem in the set slipped through by design:** Banana Slamma multiplies inside one fight and resets, so a rule about growth across turns can't see it. Athissa with Siren is steep polynomial growth, which the rule leaves to judgement.
- **Wording gaps:** whether the board and hand size count as a cap (Upbeat Duo, Thieving Rascal); whether a loop that needs a fresh copy each hop counts (Chronormu, Ball, Braggart); whether freezing the shop to re-double is "turn after turn" (Conjurer).
- **Testers' view:** the rule fits Bramble's one-board design better than Battlegrounds', where most problem cards are amplifiers and steep polynomials.
