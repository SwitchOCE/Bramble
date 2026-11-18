# Reference sounds: attack hits, 18 Nov 2026

The sound a card or unit makes when it hits another in a fight, cut from ten other games. They are bars to compare Bramble's own attack sounds against, not sounds for the game. The owner listened to them and gave the verdicts below. The WAVs are in Cloudflare R2, not Git: `python tools/assets/assets.py pull docs/design/reference-sounds`.

## The owner's taste, in short

- **Aim for:** Super Auto Pets, Battlegrounds and Galaxy.
- **Also good:** Hearthstone, MTG Arena and Runeterra.
- **Too much:** Shadowverse is a little over the top; KARDS is far over the top. Gunfire and big theatrical impacts don't suit Bramble.

## By game

| Folder | Source video (all without commentary) | Owner's verdict |
|---|---|---|
| `super-auto-pets/` | Cat Ninja, "Super Auto Pets Gameplay (No Commentary)", https://www.youtube.com/watch?v=fIbQsRf5KUg | "Autopets is very good." *[Super Auto Pets]* |
| `battlegrounds/` | Lonely Longplays, "A Perfect 30-Health Victory! \| Hearthstone Battlegrounds (No Commentary)", https://www.youtube.com/watch?v=_pQNCXV0DfU | "Battlegrounds is excellent." |
| `galaxy/` | GogetaSuperx, "Once Upon A Galaxy gameplay", https://www.youtube.com/watch?v=HQ213K2O17w | "Galaxy is excellent." |
| `hearthstone/` | Mckoythebrave, "Hearthstone Standard \| Control Priest vs Warrior \| Game #1 (No Commentary)", https://www.youtube.com/watch?v=t4JGwT2mmT0, minion hit at 469 s, hero hit at 471 s | "Yeah, those are all good." *[said of the first set, with Arena and Runeterra]* |
| `mtg-arena/` | QuietPlayroom, "Magic: The Gathering Arena Ranked Gameplay #2 \| No Commentary", https://www.youtube.com/watch?v=keGCO9zLcRs, clashes at 655 s, player damage at 655.5 s | As Hearthstone |
| `runeterra/` | June, "Legends of Runeterra Gameplay (No Commentary)", https://www.youtube.com/watch?v=be_3gVA4HiM, clash at 502 s, blocker shatters at 503 s | As Hearthstone |
| `hs-mercenaries/` | No Commentary Casual Gaming, "Hearthstone - No Commentary - Casual Mercenaries - 1", https://www.youtube.com/watch?v=KMOqig27oN0 | "Mercenaries is decent, but there's audio in the background." |
| `shadowverse/` | "Shadowverse: Worlds Beyond Daily Matches \| No Commentary \| Evolve Dragon deck", https://www.youtube.com/watch?v=DJ3Yg8qG5uI | "Shadowverse is a little bit too over top as well." |
| `kards/` | The Trolldier, "KARDS Gameplay (No commentary, No music)", https://www.youtube.com/watch?v=edg3Y0fwEcQ | **Counter-example.** "Cards is too over the top. I think gunfire doesn't suit us ... it probably doesn't suit this game. can maybe be a reference of what far too over the top sounds like." *[“Cards” is KARDS.]* |
| `master-duel/` | PURE GAMING HD, "Yu-Gi-Oh! Master Duel [Gameplay] Ranked Duels Season 41 [Blue-Eyes] (No Commentary)", https://www.youtube.com/watch?v=xOhVqvjGY2E | Not judged yet. |

Each folder's `00-…-in-a-row.wav` plays its hits one after another. A file name's number of seconds is where the hit sits in the source video.

## How they were cut, and what to watch for

- Only commentary-free videos. An earlier Galaxy batch had a commentator's voice in it; the owner heard it, and an automatic talking check had missed it. Choose silent sources rather than trusting a detector.
- Each sound was found by onset detection, or, where a game reuses one hit sound (Battlegrounds), by matching that sound across the video. Every kept sound was checked against the video frame where the cards meet. Most loud, sharp sounds in these videos turned out to be shop, UI or spell sounds, not hits.
- Each cut starts 0.03 s before the hit and lasts 0.55 s (the first-round cuts run up to 0.85 s), with loudness evened to −18 LUFS. So loudness between games is not kept, and game music sits under most of them.
- Per game: Super Auto Pets' sound lags its picture by about 0.3 s in that recording. In 02–05 a pet also faints, so 01 is the purest bump. Master Duel's cuts start at the impact; a whoosh about 0.2 s before it is left out. KARDS's cuts keep only the impact, not the second of gunfire before it.
