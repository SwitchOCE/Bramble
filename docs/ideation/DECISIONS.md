# Decisions the ideation agents made

The owner handed every open call on this branch to the agents (6 Nov 2026). Each entry: what was open, what was picked, why, and who agreed. Newest first.

Format: `### date — the question`, then **Picked**, **Why**, **Agreed by** (the reviews), **Source** (decision card, rulebook item or owner question it settles).

### 6 Nov 2026 — Engine scope review
**Picked:** merges are out until Oozes need them; the `shop_size`, `sell_value` and `income` queries and the `rule` effect stay, overruling the review's cut. Lobbies draw only tribes with `lobby_tribe_min_units` (4) or more pool units. **Why:** merges have no card yet; the heroes designed on `ideation/d-neutrals` need those queries. **Agreed by:** coordinator, against the scope review on that one cut. **Source:** scope review of `ideation/engine`.

### 6 Nov 2026 — Engine calls the brief left open
**Picked:**
- `GameConfig.defaults()` stays the bare rules (no heroes, no spells, every tribe); `GameConfig.full_game()` turns them on (3 heroes offered, spells in shop, 5 tribes). The UI and bots flip when ready.
- `CorePort.manual_choices` defaults to false: the Triple Reward casts itself and options take the first, so today's screens keep working until the UI handles choices.
- Spells and hand items are one thing (a card with a play effect in `content/spells/`); only spells fire `on_spell_cast`. Both count against the hand limit. A cast spell's copy goes back to the pool (rulebook 5.3.7).
- The Triple Reward is now the spell the rulebook describes (7.3.6): Discover from the tier above. It replaces the prototype's direct draw (SPEC 9).
- The spell slot draws on its own random stream, so turning spells on can't shift which units a shop shows.
- The hero deal doesn't repeat a hero until the roster runs out (2.2.1). Three samples can't serve eight players, so with samples only, heroes repeat across players; the soak proves no repeats with a roster of 33.
- Heroes are offered 3, per the brief; rulebook 2.2.2 says 2.
- `tools/play` difficulties map to today's personalities until the strong bots land: easy = greedy, normal = the four mixed, hard = balanced and tribe. They aren't a measured ladder. *Replaced 7 Nov: difficulties are now naive, easy, normal and hard, the bench's levels.*
**Why:** compatibility by addition, as the brief asks: other workers keep running while this lands. **Agreed by:** engine worker; reviewed at merge. **Source:** engine brief.

### 6 Nov 2026 — Which look to build on
**Picked:** Woodcraft, the only look from now on; Plain, Folk Print and the switcher go. The target is the design-lab mock (`docs/design-lab/r2/woodcraft/shots/`, `r3/woodcraft/shots/`), not today's in-game version, which only recoloured Plain.
**Why:** the brick-shaped tray shows the rows at a glance, keyword chips and big stats survive phone size, and its "this hit" panel explains a fight best. Folk Print scored one point more but relies on more on-card text. Ink + flat B art sits well on it.
**Agreed by:** gauntlet (225 of 280, in all four judges' top 3); orchestrator on real screens. **Source:** `look-direction`, owner question 16.

### 6 Nov 2026 — Spells, heroes, lobby
**Picked:** tavern spells in the shop, as in Battlegrounds. Heroes in: small roster, one simple power each, 3 offered free with no rerolls and nothing paid. Live lobby of 7 bots, no timer, no async snapshots for this build. No TFT-style traits. No minimum front row.
**Why:** the owner said spells are certain and how they arrive (2 Nov). Heroes are Battlegrounds' main source of variety and part of its core, unlike trinkets and quests, which the owner ruled out. A third hero choice makes a weak offer rarer and costs nothing without a store. Async adds nothing for one person against bots.
**Source:** `hero-choices`, `live-lobby`, `tft-traits`, rulebook 2.1.5, 2.2.3, 5.2.8, 8.3.2.

### 6 Nov 2026 — What a tribe is, and how many
**Picked:** tribes are broad creature kinds, and card text may name species too (`which-types-are-tribes`, as suggested). Slice: Hedgerow folk and Fairies plus neutrals. Then Oozes and Birds. Then two of Hunters, Bog folk, Great beasts. Once there are 6 tribes, 5 are in each lobby (revisit by sim). Every tribe has some economy (owner, 02h).
**Why:** the owner aims at 10 and asked for at least 5. Hedgerow's acorns and Fairy position puzzles are the two ideas the owner responded to most warmly, and they play very differently. **Source:** rulebook 5.2.2, 5.2.5, `faction-seeds` (flavour source, drawn on per tribe).

### 6 Nov 2026 — Cards settled as suggested
**Picked the suggested answer:** `board-spells-late`, `engine-limit`, `economy-target`, `late-spell-strength`, `growth-caps`, `recurring-gold`, `multiply-consume-rule`, `max-gold`, `the-hand`, `tolerance-floor`, `rulebook-defaults`, `random-seed`, `whistle-only-boards`, `whistle-stalemates`, `late-gold`, `watch-other-fights`, `scaling-break-even`, `shared-economy`, `whole-game-bot`, `fight-log-reminders`, `keyword-chip`, `scenario-replays`.
**Why:** each carries evidence and none conflicts with the owner's direction. Budgets remain guidelines: designers are not briefed with them, and caps bend when a design earns it, logged here. **Source:** the cards named.

### 6 Nov 2026 — Cards settled differently
- `filler-units`: **cut the filler.** Plain bodies stay only where a tier needs a deliberate vanilla option. A finished game can't have 24 stand-ins.
- `placeholder-portraits`: **unique art per unit**, in the finish step, after balance. Shared portraits only until then.
- `phone-card-text`, `card-text-overflow`, `shorter-art-long-text`: **replaced by Woodcraft's card:** art, keyword chip, name, tribe; on-card rules text at desktop and where it fits at the phone minimum, full text one tap away. Nothing below the phone minimum.
- `lobby-pace`: **in between, about 13/13 by turn 12**, measured by the bench. The owner's "as the gameplay feel matters the most" outranks the model; adjust after reviewers play.
- `architecture-lessons`: **use its proposals here** where the slice needs them (stat layers, shared state queries, geometry leak). Moving the doc to `main` isn't this branch's call. It stays for the owner to pull.
- `screenshots-in-git`: **only at builds**, under `docs/ideation/evidence/`, compressed. Overwrite rather than accumulate.
- `tft-traits`: settled above.

### 6 Nov 2026 — The first slice's cards and keywords
**Picked:** `docs/ideation/content/SLICE.md`: 25 units, 10 spells, 9 heroes, 3 keywords per tribe plus 4 shared. Pass resolves at End of Turn; other recruit-phase position text stays instant.
**Why:** a smaller first set that still tests what the owner asked for: acorn hoarding, the buff-in-front and buff-behind puzzle, the rainbow pot, "don't move for 3 turns", and slot effects. The designs not in it stay for later batches.
**Agreed by:** three independent reviews (`evidence/design-review-1.md`). **Deviation logged:** Critic A wanted all recruit position text read at End of Turn, to end the move-cast-move-back tax. Declined except for Pass, on the owner's 02h note.

### 6 Nov 2026 — Do the rows stay, and how do they earn it?
**Picked:** keep the rows. Add **scouting**: everyone sees the next opponent's board as it fought last round, by slot. Rule flags (back row half damage, attack across) stay off. Across-from text goes into tribes. "Units in front of this" stays too, though it measured as one obvious answer, because the owner likes it and it's a buff-choice puzzle rather than a placement test.
**Why:** searching placement beat shuffled by 0.77 of a place (bar 0.5), but a crude rule gets 0.68 of that. Knowing the opponent's board is worth +0.85 over the rule, and last round's board +0.40, the largest usable gain tested. Evidence: `evidence/position-test.md`. Caveat: only one bot scouted, so the bench re-tests it with everyone scouting.
**Source:** owner's "if they're not working, we can just cut them", 2 Nov; rulebook 2.1.5.

### 6 Nov 2026 — Position branch's 12 test units
**Picked:** not merged as content. The placer and tournament are ported by the bench worker onto Engine v2; the units stay on `ideation/position-test` as test material.
**Why:** they were built on the old engine to answer a question, and the slice's cards have been through review.

### 6 Nov 2026 — How the slice's text was read in the engine
**Picked (plain readings where the text left room):**
- **Touching** is the unbroken run of the zigzag through this unit, itself included. A gap cuts it.
- **After N turns** fires once per unit, at End of Turn when its count reaches N. The turn it's played counts. A move restarts the count; a triple makes a new unit, which starts over.
- **Cold Frame** shares that counter: a move restarts its wait rather than losing the prize, because SLICE says a move resets the counter and `fairies.md`-era "loses it" wording predates that. A triple loses it. The turn it's cast counts.
- **End of Turn order:** counters and Cold Frames tick, Passes land, then End of Turn text runs in reading order.
- **Rainbow** paints only while a Rainbow unit is on the board (`fairies.md`'s reminder), with SLICE's fade rule. The Chaser's sale counts its own band, then washes all. A Created unit sells for 0 as usual.
- **Shy** counts a Ring as stats, including stepping onto one: a Shy unit played on a Ring leaves at once and pays. Combat buffs don't count.
- **Hex** can hold a unit at 0 Attack, not below, and it still attacks. It stays on the slot for the fight.
- **Queen of Elfland:** "others" excludes her. Stats are what the destroyed units show, Rings included. Odd points go to the first in reading order. Golden doubles the pool.
- **Sleeping Partner golden** gets 4 Acorns (numbers double), not the costing doc's 3. **Dozey** per SLICE: +1/+1 per gold, golden +2/+2.
- **Boundary Stone:** tier 4, cost 2, "Ring a slot +4/+4." from `evidence/costing-1.md`, as SLICE only said "a bigger Ring".
- **Belladonna** in the front row faces nothing, so she does nothing there; it's a back-row card. **Sexton Beetle** is tier 3, 1/3. **Mrs Sorrel** only spawns if she lives through her attack.
- **Heroes:** Bracken's "next to" is adjacent in the same row, at most +2. Wren reads the highest enemy Attack as she swings, even if lower than her own. Pipkin's limit is on units, not spells. Mousewife's Mouse fails if there's no room behind. Jill can't use her power at tier 1. Hob's debt is a plain field, not the next batch's Bargain; he can die of it at the next elimination.
- **Earwig Mother:** "behind" first, then the nearest empty slot, so the Nymphs aren't lost to a full back row. **Shake the Tree** refreshes the spell slot too and isn't a paid refresh.
**Why:** each is the reading a player would make from the card. They're for the bench and reviewers to overrule.

### 6 Nov 2026 — The slice's pool and what isn't on a card
**Picked:** `full_game()` has `pool_copies_by_tier` `[15, 15, 20, 16, 12, 10]`. The slice has 8/7/3/2/3/2 units per tier, so the usual copies would make a tier-6 shop almost all tier 1-2. These give about 32/28/16/9/10/5% per tier at tier 6, and no single card above about 5.4%. Old units and sample cards stay as files with no `set`, so scenarios and `defaults()` still work but no default game draws them. `full_game()` still asks for 5 lobby tribes and gets the 2 there are; thin tribes aren't drawn.
**Reported, not changed:** Bristle and Hunker are built and have reminders, but no slice card has them. Their tests use old units, and the soak lists them as never fired.

### 7 Nov 2026 — Bots and bench
**Picked:**
- **Hard's budget is 20 fights, and it searches contested boards only** (4+ units, stat ratio 0.6-1.7). Bigger budgets bought nothing measurable: 200 fights over 20 is +0.04 ±0.35 places. A turn of 7 Hard bots stays under about 1 s on an assumed phone-speed core on average; the 95th percentile is about 1.5 s.
- **Strategy curves were slowed by hand,** after the first spread showed tempo beating tiers. They are bot choices, not rules, and balance tuning should revisit them.
- **A `power` prior on `fairies_hag` (25) and `neutrals_low_roll` (20), used only by Hard,** weights its build pick by bench strength. It's hand-set from bench results. Raising low roll to 35 gave 3.90 ±0.20 among Normal, no better than 3.70 ±0.21, so it stays at 20.
- **`GameConfig.full_game()`'s default `bots` were still the old personalities.** *Replaced the same day: see the lobby entry below.*
**Reported, not fixed:** Hard among Normal (3.70, bar 3.5) and the win spread (4 of 8 in band, 1 above) fail. Reading: `evidence/bench-reading.md`. Card numbers are unchanged, as the brief asked.
**Why:** the curves and `power` priors above were set by hand after seeing bench results, so every number here is partly those choices. I stopped there rather than keep tuning bots until the bars passed, which would hide what the game does.

### 7 Nov 2026 — Scope review of bots and bench: the lobby and the rule
**Picked:**
- **Bots read only what a player can see.** The opponent's Larder is gone from what they read. Their hero effects and `back_row_first` stay, because the next opponent's hero and power text are now public: the scout panel and `tools/play` show them (state field `next_opponent_hero`).
- **Slots live in a sibling state field, `next_opponent_last_slot_effects`, not inside `next_opponent_last_board`.** The review asked for them in the board field, but a Ring can lie on an empty slot, which that field holds as null, and its shape is already what the UI reads. The scout panel and `tools/play` show them.
- **One function seats the lobby: `BotLobby.seats(difficulty)`,** used by `CorePort`, `tools/play`, the bench and `full_game()`'s default (Normal). A chosen difficulty now changes the seats.
- **Seat assignment, not a crowding penalty.** `GameSession` deals each Normal or Hard seat a build open in its lobby, seeded, with no repeats until the list runs out. Seats are pinned to it. Naive and Easy follow no builds, so `hard_naive` and `hard_easy` already are those lobbies. A bot's displayed name shows its level, not its build.
- **The `power` prior stays.** It now only affects unpinned Hard, which no player meets, but which is the bench's stand-in for a strong player.
**The trade, honestly:** the reviewer measured Hard among Normal falling from 3.70 to 4.26 without the prior. Seat assignment avoids that choice for this bar, as the focus keeps its prior. It moved the other way: 3.73 ±0.21 among free Normal, 3.49 ±0.20 among the varied lobby, which clears 3.5 by 0.01. That isn't a real pass: it's inside the noise, the focus ends on fairies_hag 97% of the time, and the lobby is easier because weak builds are dealt as often as strong ones. Among the varied Hard lobby it's 3.83 ±0.20. No further tuning for this bar now.
**The Normal-to-Hard step is too small:** Hard places 3.49 among varied Normal and 3.83 among varied Hard, a step of +0.34 ±0.25. It's the balance step's to fix. These suites ran on different commits from the spread, so the full bench reruns on one commit before any of it counts as final evidence.
**Reported, not fixed:** alderman_dozey is on 70-96% of final boards in all eight strategies. `neutrals_economy` has no save plan, so no economy line has been tested. Both are for the balance step. The no-scouting arms can't show the rule adds to placing: `evidence/bench-reading.md`.
**Why:** variety wins in the lobby the player meets, on the orchestrator's call: seven of one build is a worse game to play against.

### 6 Nov 2026 — Content review's ask items
**Acorn supply:** real gap. With natural play a Stash was held in 19 of 4,475 player-turns, and Great Hoard and Old Mother Mast almost never fired. First job of the balance step; a holding bot measures it. The owner's favourite idea can't be left unreachable.
**Bristle and Hunker:** listed in SLICE but on no card. They go on cards in the next batch (the owner singled out Hunker and hedgehog thorns).
**Queen of Elfland with a Ring:** a token on a Ring turns the Ring into permanent stats every 3rd turn while the Ring stays. Kept for the bench to measure; it's a real combo, and may be fine.
**Unit view `shy`, item view `combines_into`:** kept; fix the `engine.md` wording, since `shy` is a bool.
**Follow-ups (simplify):** narrow the text-test exemption to Dozey and Queen; report rigged and natural soak coverage separately.

### 6 Nov 2026 — Sound nobody has heard
**Picked:** ship synthesized sounds unheard, with the playtest guide saying so. The ooze squeak stays: the owner asked for "ludicrous high-pitched voices". Agents can only measure levels; loudness balance and pleasantness are the owner's to judge. **Why:** silence would read worse than rough sound, and redoing a sound is one script run.

### 6 Nov 2026 — Art review's ask items
**Fairy proportions:** Hedge Witch, Queen and Annis aren't chunky though take B says chunky. Kept: the folio's fairy brief is "slender", they read well at card size, and tribes looking different helps. Belladonna stays the round version.
**Nut fallback:** removed. **Triple Reward:** portrait added.

### 7 Nov 2026 — Balance step: the runaways
**Dozey:** the core stays (feed him Acorns, wait three turns, double), with a ceiling: doubling adds at most +8/+8 (golden +16). A triple keeps its timers, so tripling no longer re-arms him. **Hedge Witch:** Hex stops at -8 Attack. **Why:** Dozey sat on 70-96% of final boards at 96/94 by round 13, and the Witch took a unit to -45. A ceiling keeps the card's idea and stops the one-unit game. Dozey is on 29% of boards after it.

### 7 Nov 2026 — Balance step: bodies against spells
**Picked:** cheap spells lose rate, and late units gain body. Elderflower +1/+2 or +2/+1; Cold Frame +3/+3; Bread +1/+1; Stand Behind +1/+2; Boundary Stone costs 2 for +3/+3. Tier 4-6 bodies raised: Spider 4/3, Treasurer 3/5, Wisp 3/6, Belladonna 4/8, Burner 5/7, Mast 6/8, Queen 8/8. **Why:** reviewers found 2 gold for +4/+4 beat a 3 gold 2/5, so buying units was the wrong play. **Rings stack as they did:** they are bound to a slot, which is the cost, and Rings is not winning.

### 7 Nov 2026 — Balance step: shop odds and pool (deviates from rulebook 6.1.3)
**Picked:** the slice uses tier odds per tavern tier, 5% tier 1 at tavern 6 up to 13% tier 6, replacing the flat draw across every tier, with fewer copies per unit (15/15/13/13/11/9). **Why:** with a flat pool a tavern 6 shop rarely showed a tier 6 unit, which is what reviewers called hollow. **Added cards from the next batch:** Reel-Mistress, Changeling, Cradle Fetch, Beadle Warrenby, Cluricaun, Dr Urchin, Sergeant-at-Conkers. **Beyond the brief's list, to fill the tiers and the economy:** Whirligig Beetle (T6), Pipistrelle Echo (T5), Ichneumon Wasp (T4), Pennywort Snail (T1), Money Spider (T2); spells Rainy Day, Squirrel Away, Market Day, Harvest Supper, Hiring Fair, Beltane Bonfire. **Not added:** Reynard, Tuppence and Aunt Dormer. The brief wanted loop tests first, and tier 6 now has three units with enough to choose from for this slice. **Discover** tops up from lower tiers, so it always offers 3.

### 7 Nov 2026 — Balance step: no base interest (follows the owner over the brief)
**Picked:** interest stays on cards (Dame Farthing, Money Spider), not a base rule. **Why:** the owner's direction says "Unspent gold carries over. No cap, no interest". The brief lists interest as one route to a saving line, but the owner's direction outranks it, and cards can pay interest without changing the base rule. Saving's other rewards are the late sinks: Hiring Fair, Market Day, Harvest Supper, Beltane Bonfire, Last Orders.

### 7 Nov 2026 — Balance step: hero fixes
**Jill:** dropping a tier pays 2 gold and climbing back costs only 2, so the power is a real tempo trade. **Hob:** borrows 3, repays 3 and 1 Health. **Farthing:** 1 per 4 carried, up to 5. **Why:** the old Jill paid back less than the climb cost, and the old Hob's debt was a plain loss.

### 7 Nov 2026 — Balance step: Acorns and the flat cards
**Picked:** Sleeping Partner pays every 3 turns, not once. Mast pays an Acorn every turn, 2 with a Hoard (first version, 2-3 Acorns at 3 Health more, ran away: Treasury won 44.6%, the Larder hit 37). Treasurer grows per 2 gold held. Rainbow Chaser has +1/+1 per band in fights and pays 1 gold per band sold, so it fights or cashes out. Sexton Beetle pays twice a fight. Charcoal Burner burns above 5 and pays +1/+1 per 2. Sergeant at Conkers throws Acorns for damage, a second payoff for holding them. **Why:** the Acorn plan was unreachable (a Stash held in 19 of 4,475 turns), and the owner likes it.

### 7 Nov 2026 — Balance step: Belladonna
**Picked:** she does something in both rows: at the back, Nightshade on the 2 front enemies facing her; at the front, on the enemy across. **Why:** the front row did nothing, a trap for a new player. Fixed by rule and text.

### 7 Nov 2026 — Balance step: Health and damage (the game's length)
**Picked:** 40 starting Health for the slice and a damage cap per round, 3 at the start up to 15 at round 14 and after. **Why:** at 30 Health the median seat was out at round 11, before any late game. The final numbers are in `evidence/balance-1.md`.

### 7 Nov 2026 — Balance step: bots
**Placing:** bots keep a unit in its row and slot unless they have a reason, a small bonus for not moving a board, so scouting a board tells you something. **Queen:** stands in a corner with the cheapest unit behind. **Jill:** a triple-hunting plan drops a tier when it holds pairs below. **Shake the Tree:** no longer avoided. **New bot:** `neutrals_purse`, The Long Purse, saves on a schedule and spends late. **Pass landing:** a swap is now judged by where the Pass then lands, because a swap could move the Pass's own start.

### 7 Nov 2026 — Balance step: the ladder and Hard's choice of build
**Easy climbs late and never early** (curve 5/8/11/14/16). **Why:** Easy reached tier 6 by round 9 for lack of anything else to spend on, and big late bodies then beat better play: Hard among Easy won 5% of games. After the change it wins 53%, and Normal among Easy goes from 9% to 31%. **Hard's prior:** a strategy's `power` falls from 25 to 6-8, spread over the four sound builds. **Why:** Hard took one build in 98% of seats. **Hag and Help climb sooner,** as tier 6 now pays. **Not done:** Rings and Help get no prior, so Hard rarely takes them, which is a limit of the bot rather than a verdict on the builds.

### 7 Nov 2026 — Balance step: where the slice stops
**Picked:** stop at the shape, not at fine numbers. Two tribes can't hold long-term balance, and every number here will move when tribes arrive. The tests of the shape: a game reaches tier 5-6, builds differ, none runs away. **Echo and Last Orders:** a spell that spends all your gold pays only its first target, since the gold is gone. Kept: rare, and honest to the words.
