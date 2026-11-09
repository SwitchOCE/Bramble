# Jeef and XQN, mainly on Quilboar: what I could find without video

I couldn't watch any video, and I couldn't read any transcript or stream recording (VOD). The usable evidence is Jeef's own written comp guides, reached through a public copy, plus video titles, descriptions and public final-board data. Quilboar is the tribe both streamers have played most in the last three weeks, so this report centres on it, in line with the owner's note 09g.

## Bottom line

1. **"Tier 7" and the Hearthstone Deck Tracker guides are Jeef's writing.** Tier 7 is HSReplay's paid Battlegrounds tier. The Deck Tracker source code fetches the comp guides with a method named `GetPremiumCompsGuides` that returns `BattlegroundsTier7CompsGuidesData`. HSReplay announced "FREE Composition Guides written by Jeef" on the overlay, and its comps page says it is powered by JeefHS. Jeef's old cheat sheet site, hsbgguide.com, now redirects to HSReplay's comps page. So the guides the owner pointed to and the streamer the owner named are the same source.
2. **The early game is played without the tribe.** In Jeef's comp guides, 129 of 141 core cards are Tavern tier 4 to 7, and only one is tier 1 or 2 (Eternal Knight). No current tier 1 or 2 Quilboar appears in any Quilboar comp, as core, addon or cycle card.
3. **Each comp has a named commit point, almost always a tier 4 to 6 card.** For Quilboar:
   - **Choose One:** "Gem Rat/Bramble Tunneler + Turbo Hogrider".
   - **APM Shop Buff:** "Early infinite gold + Felboar".
   - **Gem Barrage:** "Gem scaling/Spell Power + Razorfen Flapper + payoff".
   - **Gems from Hand:** "Gem scaling (Sanguine Refiner) + Hot-Air Surveyor".
4. **The strongest enablers belong to no tribe.** Of 33 HSReplay comps:
   - Brann appears in 17.
   - Balinda Stonehearth appears in 9.
   - Sky Admiral Rogers and Proud Privateer each appear in 7, across six tribes.
   - Titus appears in 6 and Drakkari Enchanter in 5.

   Each of these doubles a whole mechanic (battlecries, spells, deathrattles, bounties). This matches the takeaway viewers drew from the Jeef/Babbit/XQN minion ranking video in January 2025: "Get Brann, Titus, Enchanter or mechs".
5. **Quilboar does not dominate the current data.** This is a test of the owner's expectation that Quilboar "will obliterate almost all of our designs" (note 09g), on this patch.
   - **Final boards:** across 27 comps on Firestone's sampled high-rating final boards, Felboar Spam ranks 4th by median total stats, Choose One 13th and Gem Spam 16th. Mech APM, Pirate Discover and Elemental Azerite are bigger.
   - **Placement in the top 10% of ratings:** Choose One is 7th of 27, Felboar 23rd and Gem Spam 26th. This is after the 3 November nerf.
6. **Blizzard has just nerfed Quilboar on the gem-size and extra-cast axes.** Patch 37.0.2 (3 Nov) says its aim is to "bring down some of the stronger types, like Quillboar and Demons":
   - Sanguine Refiner's gem buff dropped from +1/+2 to +1/+1.
   - Hot-Air Surveyor ("Blood Gems played from your hand cast an extra time") moved from tier 4 to tier 5.
   - The Jar o' Gems trinket went from cost 0 to cost 3.
   - The Wand of Divination trinket is "Now banned in Quill lobbies."

## What I could and could not access

| Source | Result |
|---|---|
| YouTube video pages, descriptions, auto-transcripts | Video pages showed only navigation. The timedtext transcript API returned nothing. Third-party transcript sites returned 403 or a browser check. **No transcripts at all.** |
| YouTube channel feeds for JeefHS and XQN | **Worked.** 15 latest titles, dates and descriptions for each channel. The descriptions are mostly links. |
| YouTube oEmbed (title and uploader lookup) | Worked; used to confirm who uploaded each video. |
| HSReplay comps pages and Tier 7 | **403 on every page.** I didn't try to get around it: one plain download attempt was refused by the permission system as bot-check circumvention, and I left it there. |
| HSReplay comp data via a public GitHub copy (`mharrell/bobs-ledger`, `app/meta/comps.json`, refreshed 4 Nov) | **Worked.** Its scraped fields are tier, difficulty, summary, `when_to_commit`, common enablers, core and addon cards. Its `how_to_play` text is that project's own rewrite, so I didn't use it. I couldn't check the copy against HSReplay itself. |
| Firestone public data (static.zerotoheroes.com) | **Worked.** Comp definitions with tips by streamer **Slyders** (dated 17 Oct, before the nerf), placement statistics by rating bucket for the current patch (updated 9 Nov), and 40 real high-rating final boards per comp. |
| Reddit, X/Twitter, Liquipedia, streamscharts | Blocked (reddit.com unreachable; X 402; Liquipedia and streamscharts 403). Reddit came through only as search snippets. |
| bgknowhow.com | Shuts down: the main domain redirects to GitHub, and the sat. subdomain fails its secure connection (SSL error). |
| Blizzard 37.0.2 patch notes and forums | Worked. |
| Interviews | None found that cover strategy. |

## Who they are

- **Jeef (JeefHS).** American. HSReplay describes him as the best-ranked Battlegrounds player and streamer, and his YouTube channel says he is "consistently rank 1 NA". He won the Lobby Legends Fall Championship in 2023. He writes HSReplay's comp, hero, quest and trinket guides. He also made principle videos on "Direction", "Leveling", "Minion Quality" and "Positioning", plus "Jeef Curve Explained". I could read only their titles and second-hand summaries.
- **XQN (xqn_thesad).** Based in Belarus. His Twitch profile lists EU #1 in seasons 3 to 7 and season 12. He uploads daily English-titled game videos, and Shadybunny regularly posts commentary on his games.

## What they have played recently

**Jeef, 28 Oct to 8 Nov:**
- Quilboar in three titles:
  - "300k+ STATS Quilboars!" (1 Nov, before the nerf)
  - "The OP Beast and Quilboar Pivot!" (2 Nov, short)
  - "HUGE 7 Drop Quilboar Back to Back!" (8 Nov, after the nerf). My guess is that "7 Drop" means a tier 7 minion; Jailbird Juggernaut, the tier 7 Quilboar, was buffed from 6/15 to 13/17 in 37.0.2.
- Also a Sludge comp (Aberrations), quests, Brann, and wins on turns 6 to 7.

**XQN, 21 Oct to 8 Nov:**
- Quilboar in three videos:
  - "4 GOLDEN GEM RATS DESTROY THE LOBBY" (23 Oct)
  - "BEST TRINKET FOR HOGRIDER COMP" (1 Nov): Glass of Perspective with a golden Turbo Hogrider
  - "FELSTEEL CLEAVER WORKS WITH SURVEYOR" (3 Nov): with a golden Hot-Air Surveyor
- Also two Amalgam (Menagerie) games, two Demon games, Beatboxer Mechs, C'Thun Poet, Pirates (Escapee Portrait with Hooktusk), a Golem pivot, and "sold my board on turn 7 to golden the Brann on Gallywix".

Two years ago XQN's video "ALL Gems X5!?" was described as him trying out forcing Quilboar for MMR gains. Shadybunny's "This Quilboar Strategy is Free MMR!" tried tier 6 Quilboar on XQN's advice. Both claims come from search snippets of the descriptions.

## Quilboar as the top players build it now

### The comps

The HSReplay columns are Jeef's guide fields, from the 4 Nov copy. The Firestone column is Slyders.

| Comp | HSReplay tier / difficulty | Commit point | Core cards | Addons | Firestone tier and tip |
|---|---|---|---|---|---|
| **APM Shop Buff** ("Cast spells to consume buffed shop") | S / Easy | "Early infinite gold + Felboar". Enabler: Brann. | Felboar (T5), Balinda (T6), Brann (T5) | Twisted Wrathguard, Devilish Distractor, Gatekeeper Amalgam, Enterprising Escapee, Sky Admiral Rogers, Proud Privateer, Hot-Air Surveyor, Victorious Geomant | S, Hard: "You need a lot of economy, Then boost your shop with Blood Gem Barrage using Razorfen Flapper or with Devilish Distractor. Cycle spell with Balinda Stonehearth & Brann Bronzebeard to boost your Felboar" |
| **Choose One** ("Play Choose One cards to scale") | A / Hard | "Gem Rat/Bramble Tunneler + Turbo Hogrider". Enabler: gem scaling (Gem Rat). | Bramble Tunneler (T4), Trench Fighter (T3), Gem Rat (T3), Turbo Hogrider (T6), Sanguine Refiner (T5) | Sky-hatch Runaway, Thorned Trailblazer, Sanguine Champion | B: "Generate some economy and gem boost early with Bramble Tunneler, When you find Turbo Hogrider, Cycle all Choose One card. At the end, use Gem Confiscation on a carry minion" |
| **Gem Barrage** ("Make shop big with gems") | A / Medium | "Gem scaling/Spell Power + Razorfen Flapper + payoff (Trench Fighter/Felboar)" | Trench Fighter (T3), Razorfen Flapper (T4) | Drakkari Enchanter, Felboar, Titus | (no matching Firestone comp) |
| **Gems from Hand** ("Add buffed gems to hand") | B / Hard | "Gem scaling (Sanguine Refiner) + Hot-Air Surveyor" | Geomagus Roogug (T4), Hot-Air Surveyor (T4, now T5), Sanguine Refiner (T5), Victorious Geomant (T6) | Sanguine Champion, Blade Collector, Mangled Bandit, Balinda | "Gem Spam", C: "Generate Blood Gems with Bramble Tunneler, Mangled Bandit etc. Then play gem on Geomagus Roogug with Hot-air Surveyor & Balinda Stonehearth" |

The only S-tier Quilboar comp runs on Pirate gold engines and neutral doublers, and its carry, Felboar, is half Demon. The comp that is Quilboar all the way through is Choose One.

### Units by stage of the game

- **Early (tiers 1 to 3).** The comps list no Quilboar at tiers 1 or 2. The current ones are Razorfen Geomancer, Tusked Camper, Crater Miner, Prodigious Tusker and Roadboar. The earliest listed pieces are tier 3: Gem Rat and Trench Fighter (each gives a gem spell at end of turn), plus Mangled Bandit, Fearless Foodie, Sly Infiltrator and Thorned Trailblazer as addons or cycle cards.
- **Mid (tiers 4 and 5).** Bramble Tunneler, Razorfen Flapper, Geomagus Roogug, Hot-Air Surveyor, then Felboar, Sanguine Refiner and Brann.
- **Late (tiers 6 and 7).** Turbo Hogrider, Balinda, Victorious Geomant, Sanguine Champion and Veteran Brigand.

### Endgame boards

These are Firestone's real final boards: 40 per comp, current patch, player ratings about 7,700 to 17,000.

| Comp | Median total stats (Attack + Health) | Middle half of boards | Biggest unit's share of the board | Cards on most boards |
|---|---|---|---|---|
| Felboar Spam | 63,038 | 42,871 to 107,219 | 0.54 (tall) | Felboar on 40/40, Surveyor 29, Flapper 21, Balinda 21 |
| Choose One | 44,467 | 30,416 to 77,029 | 0.30 (wide; median 6 Quilboar on a board) | Turbo Hogrider on 40/40, Bramble Tunneler 39, Gem Rat 20, Sanguine Refiner 15 |
| Gem Spam | 37,408 | 23,396 to 71,273 | 0.39 | Bramble Tunneler 27, Roogug 25, Surveyor 25, Hogrider 24, Felboar 21, Balinda 20 |

Two example boards (an asterisk marks a golden copy):
- **Choose One, rating 16,980, Reno Jackson, 92,081 total:** Sanguine Refiner 7,143/10,049; Bramble Tunneler* 7,127/10,083; Gem Rat* 11,711/9,896; Turbo Hogrider 11,711/6,727; Sky-hatch Runaway* 109/189; Rodeo Performer 81/136; Turbo Hogrider* 7,097/10,022 with Taunt.
- **Felboar, rating 10,731, about 182,000 total:** Felboar* 58,869/62,709 with Divine Shield and Windfury; Felboar 22,505/23,865; Roogug 3,979/4,171; Surveyor 1,316/1,363; Geomant 919/973; Balinda 716/758; Flapper* 162/165.

Caveats on this data:
- The boards carry no turn number, so they can't be set against our R6/9/12/15 curve.
- In-combat summons aren't counted, which is why the Beetles and Leviathan comps look tiny.
- The placement averages only cover games Firestone recognised as that comp at the end, so every comp looks better than 4.5.

## Committing and pivoting

- **Enablers are not commit points.** Jeef's guides keep "common enablers" separate from "when to commit". The GitHub project's notes paraphrase his "Direction" video as "enablers are not commit points". That is second-hand.
- **Commits often name an early mid-tier piece:** "Early Sacrificial Wrathguard", "Early Eternal Knight", "Early Lurking Leviathan", "Early infinite gold + Felboar", "Early Hopebringer". You build the comp around one strong tier 4 to 5 card found early.
- **There is a written fallback.** Venom Scam's commit point is "When you have no future or are clearly getting outstatted."
- **The lobby changes the build.** Slyders' tip for Neutral Tea Set: "If quilboar are in, you need to play with Hot-Air Surveyor & Victorious Geomant."
- **Pivots show up in their videos:**
  - Jeef, "The OP Beast and Quilboar Pivot!"
  - XQN, "LUCKY HERO POWER GIVES US AN INSANE GOLEM PIVOT"
  - XQN, selling his whole board on turn 7 for a golden Brann
  - Shadybunny on an XQN game: "rough start … able to U-turn it into a crazy beast pop-off"
- **The game itself nudges a commit around turn 7.** Since 37.0.2, "From turn 7 onward, you're offered at least 2 minions of your most common type."

## The early game without the tribe

- **The Jeef Curve** (bgcurvesheet.com, from the 2021 to 2022 era):
  - Turns 1 and 2: stay on Tavern tier 1 and buy "premium 1-drops" or one economy card.
  - Turns 3 and 4: level up.
  - It suits tribes with strong tier 3 cards (Quilboar, Dragons, Mechs, Pirates) and is worse with token tribes (Murlocs, Beasts, Elementals).
  - Early buys are chosen for combat strength, not tribe.
- **Two Jeef principles, second-hand** (paraphrased in the GitHub project's code and tests):
  - "Tiers 1-2 are shop-driven: early losses don't gate levels."
  - From his 19 Sep 2026 guides: if you are not stabilised, the next buy should win a fight; once you are stabilised, scale.
- **Shadybunny, second-hand:** build a strong board, not a comp. Choosing a checklist comp from turn 1 is the mistake.

## Flexibility versus enabling

From the evidence, Battlegrounds settles the tension the owner described like this:
- Early buys are generic stats and economy.
- Tribal enablers start at tier 3 to 4.
- The biggest enablers are neutral or cross-tribe multipliers at tiers 5 and 6: Brann, Balinda, Titus, Drakkari Enchanter, and the Rogers + Privateer gold engine.

Blood Gems also work across tribes. Hot-Air Surveyor is a core or addon card in Mechs Magnetics/Spells, Menagerie and Demons Shop Buff. Felboar appears in Elementals Living Azerite, Demons and Menagerie.

My own reading, offered as judgement: most S and A comps have the owner's three axes, not just Quilboar.
- **Count:** gold, spells or triggers.
- **Repeat:** a doubler such as Brann, Balinda, Titus or Proud Privateer.
- **Size:** a lasting counter such as shop buffs, spell power or "your Blood Gems give an extra".

The gem-size counter is one instance of a common pattern. The 37.0.2 nerfs cut the size and repeat axes rather than the number of gems.

**For the reference tribe:** Choose One is the most "relatively straightforward" Quilboar line. It is mostly Quilboar, wide (the biggest unit holds about 30% of the board), has an in-tribe commit point, and ranks A or B on the current patch. Felboar is the tall, cross-tribe, gold-engine version.

## Sources

- HSReplay comps (403 to fetch; seen in search): https://hsreplay.net/battlegrounds/comps/ ; Tier 7: https://hsreplay.net/battlegrounds/tier7
- HSReplay on the Jeef-written overlay guides: https://x.com/HSReplayNet/status/1869107813760565459
- Deck Tracker source (`ApiWrapper.cs`, `GetPremiumCompsGuides`): https://github.com/HearthSim/Hearthstone-Deck-Tracker
- Scraped HSReplay comp copy: https://github.com/mharrell/bobs-ledger (`app/meta/comps.json`, `app/value.py`, `app/tests/test_live_updates.py`, `ROADMAP.md`)
- Firestone data: https://static.zerotoheroes.com/hearthstone/data/battlegrounds-strategies/bgs-comps-strategies.gz.json?v=37.0 ; https://static.zerotoheroes.com/api/bgs/comp-stats/last-patch/overview-v3.gz.json ; …/last-patch/boards/<comp>.json (the data path was found via https://github.com/Gallo13th/HSBRSIM `scripts/comp_lines_fetch.py`)
- Jeef's feed: https://www.youtube.com/feeds/videos.xml?channel_id=UCK3rJ7OXrXZIcnw-xYrSXOg ; channel: https://www.youtube.com/@JeefHS ; "Direction Explained By a Pro": https://www.youtube.com/watch?v=foZx60jbC74 ; "Jeef Curve Explained": https://www.youtube.com/watch?v=LaQzV0YZX4A
- XQN's feed: https://www.youtube.com/feeds/videos.xml?channel_id=UCc25vV0S7nAZ-9MxRLyOlkQ ; Twitch: https://www.twitch.tv/xqn_thesad/about ; "ALL Gems X5!?": https://www.youtube.com/watch?v=E7q9A9KMOi4
- Shadybunny on XQN and Jeef: https://www.youtube.com/watch?v=YsR2L8apHDM , https://www.youtube.com/watch?v=9ZiNkHef4ms , https://www.youtube.com/watch?v=08tFc8FYcsI , https://www.youtube.com/watch?v=hTImT10uV1M
- Jeef Curve: https://www.bgcurvesheet.com/curves/main-curves/jeef-curve ; https://acegameguides.wordpress.com/2021/10/06/what-you-need-to-know-about-battlegrounds-popular-jeef-curve/
- Jeef/Babbit/XQN minion ranking thread: https://us.forums.blizzard.com/en/hearthstone/t/bg-minion-tier-list-season-9-by-jeefbabbitxqn/140404 ; tribe tier list thread: https://us.forums.blizzard.com/en/hearthstone/t/jeef-provides-bgs-tier-list-for-spell-meta/118716
- 37.0.2 patch notes: https://hearthstone.blizzard.com/en-us/news/24307311/3702-patch-notes
- Low reliability (machine-translated aggregator): https://hstopdecks.com/en/battlegrounds/comps/quilboar
- Esports profiles: https://liquipedia.net/hearthstone/Jeef (403; seen in search), https://www.esportsearnings.com/players/86982-xqn-
- Local card data: /home/alex/code/Bramble-ideation/docs/research/battlegrounds/data/minions.json and spells.json (build 37.0.0)

Files are in the scratchpad (downloads are untrusted data and nothing in them was run):
- /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/bobs-ledger-comps/comps.json
- /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/firestone-strategies/comps-strategies.json
- /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/refs/firestone-compstats/ (overview.json and boards-*.json for 27 comps)
- /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/scripts/boards.py, allboards.py and hsr.py (the analysis scripts I wrote)