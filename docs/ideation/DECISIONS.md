# Decisions the ideation agents made

The owner handed every open call on this branch to the agents (6 Nov 2026). Each entry: what was open, what was picked, why, and who agreed. Newest first.

Format: `### date — the question`, then **Picked**, **Why**, **Agreed by** (the reviews), **Source** (decision card, rulebook item or owner question it settles).


### 7 Nov 2026 — Round 3.6: a smaller savings threshold
Money Spider pays per 3 carried gold rather than per 5, keeping its 2-gold normal/4-gold golden ceiling. Holding one purchase now earns 1 next turn; holding two earns the maximum, instead of tying up more than three purchases. This makes an ordinary leftover bank useful and lets a player take the interest then spend, without adding interest to every hero or rewarding an indefinitely growing bank. Hob's Health-for-gold loan stays unchanged: borrowing is for buying power now, and banking a loan should not be a dominant strategy. This is one bounded card change, not a claim that every savings line now wins.

### 7 Nov 2026 — Round 3.5: hoarding has a useful ceiling
Great Hoard is worth 16 gold (from three 5-gold Stashes): combining still earns a bonus and frees hand space, but no longer creates 5 extra gold. Treasurer gains +1/+1 per 3 held gold, capped at +8/+8 (+2 and +16 golden). One Hoard still gives +5/+5 and asks whether to cash it; beyond 24 held gold the Treasurer stops rewarding idle accumulation. Cut-and-Come-Again keeps copying printed Treasurers; the same bounded aura applies to every copy, so no tribe-wide copy nerf is needed.

Mast already pays once per turn, not per buy. Keep its 1 versus 2 Acorn Hoard incentive, but share the two conditions' once-per-turn key: acquiring a Hoard mid-turn cannot collect both branches. Text now says first buy. Dozey eats at +1/+1 per 2 gold rounded up (golden +2), rather than per gold: a plain Acorn still matters, a 16-gold Hoard feeds +8 instead of the former +20. This closes the other direct route from a bank to one giant unit; no card is removed, and no general Ooze/Bird strength is changed. Compare largest units by round against the preceding damage-only build.

### 7 Nov 2026 — Round 3.4: losses matter from the first fight
For the playable game choose max(4, winner tier + ceil(surviving tiers / 2)), capped by round at 4/4/5/6/7/8/9/10/11/12, with 12 repeating through the final duel. Ties remain zero. The four-point floor charges early empty-board greed; halving surviving-tier weight keeps a crowded late board from multiplying the punishment. The permanent 12 cap removes the top-four cliff (baseline maximum 33) and leaves room for a response at 40 starting Health. The bare/default engine keeps its old formula. Compare identical seeded opening arms and damage per round in round3-fixes.md.

### 7 Nov 2026 — Round 3.3: the bought tier appears
Pick tier odds 100; 50/50; 20/30/50; 10/15/25/50; 5/10/15/25/45; 5/5/10/15/25/40. Current tier becomes the largest share, while older support pieces remain findable. No guaranteed slot: depletion, freeze and a shared pool still matter. At tier 4 this cuts the expected chance of a shop without tier 4 from 44.4% to 3.1%. The same table governs spell tiers as before; rules now say so.

Hiring Fair and a high-tier Triple Reward intentionally share the same eligible units; neither promises exclusive cards. The current four-tribe slice has eight tier-6 designs. Sampling advances and offers are distinct within each choice, so matching offers are possible but not fixed. Reduce Hiring Fair from 6 to 4 gold: paying one over a random shop unit buys selection and early tier-6 access, without pricing it like an entire triple. No extra Discover mechanic added.

### 7 Nov 2026 — Round 3.2: phone controls and geometry
Idle recruiting always shows the purse, Tier and Refresh even with Birds away. A Nest tap opens the full bird/countdown note; automatic passive details no longer occupy the economy column. Long help hints reserve their measured wrapped height. Nest captions get their own space and explicit slot labels, and Ring chips leave the slot/name/keyword labels visible. At phone width scouting uses the same column centers as the player's board and reserves space for the small shop. Keep the existing compact desktop arrangement where a full pitch would collide with the shop. Rendered and inspected held, selected-bird, Ooze, scout and Ring states at 1688×780; preserve two final phone shots in evidence. Rendering now checks Pillow up front and uses one software-render thread. This is a desktop phone-size render, not a real-device test.

### 7 Nov 2026 — Round 3.1: rules and automatic losses
Changeling firing twice is a bug: scanning the changed enemy board revisits it. Snapshot both Start of Combat queues before resolving either; each initial unit fires once in its original queue, using its current allegiance. The golden borrowed unit correctly keeps its one +4/+4 until combat ends, including after returning; friendly combat buffs likewise last for the fight. No recruit stats carry home.

Shy, Mired and Borrowed join the glossary; Shy walk-outs and Nest replacement now announce their losses. Replacement uses the new bird's Nest and Attack; the old bird still returns. Mother Goose continues arming all Nests while away, even after her own Nest is replaced. The initial notice incorrectly said her strikes were lost; a direct replacement regression caught the wording error, and the text is corrected without changing Bird strength. The guide spells out the staggered front/behind pairs and their row boundaries. Seven Whistlers counts board and away Birds, never hand Birds; the card now says so. Combat text names whose board emptied and its survivors, skips unchanged stat lines and translates no-room card ids. Pipkin warns on using the second buy and on a refused third. CLI hand cards gain stable `@iid` handles; numeric positions remain for old replay compatibility, with their shifting explicitly documented. This prevents a newly bought unit from redirecting a cash-out command.

### 7 Nov 2026 — Export build 2 after the UI time limit

**Picked:** Export build 2 with the fight callback fix at 39510b1. Do not rerun the deep UI check. Keep the completed evidence at dc7d005; do not replace it with a partial report.
**Why:** The detached run under load reached its 2700-second limit (exit 124), with nine games clean on 39510b1. There is no full UI run on that commit. The gate passes 954/954 tests, including the freed-card regression. README states both the full 0-of-22 failure result at dc7d005 and the limited result on the fix. The bench is on 2a12020, before the fix; it is not evidence for the fixed commit.
**Agreed by:** Owner, explicit instruction to export now after the time limit.
**Source:** Owner's 7 Nov 2026 build 2 export instruction and follow-up.

### 7 Nov 2026 — Oozes and Birds: review calls
**Picked:** Sixpenny Pie pays at most three times in that unit's life. Its `paid_pie` counter lives on the recruit unit and travels into fights, so moving it never refreshes the allowance. Golden still pays 2 gold each time, for three payments. As with Sleeping Partner, a newly bought unit or a newly combined golden has its own allowance.
**Cut-and-Come-Again's plain copies never Fly South.** They sell as ordinary Created units, with their normal on-sell text, and leave no Nest or returning bird. Both card texts say that selling is final; the sale button and note agree.
**A golden put straight on the board by a full-hand combine was played this round.** Set `played_round` at placement, so it cannot fly before fighting as a golden.
**Tempo's board assertion stays `assert_gte`, with a reason.** Restoring `assert_eq(board_count, 1)` failed: with four tribes, seed 11 buys Mrs Burdock and her on-play Kit makes two bodies. An additional exact assertion checks that one unit was bought.
**All four tribes stay in every lobby.** The thinner shops are for playtesters to judge; do not re-tune them now.
**Why:** bound repeatable economy and close the plain-copy flight loop while keeping the cards' intended payoffs. **Agreed by:** owner's requested review calls, implemented on `ideation/tribes2`. **Evidence:** the new Pie, bird-copy, sale-wording and full-hand golden tests failed before their fixes; the exact tempo board assertion failed 2 versus 1. Targeted suites pass after the fixes. Full gate, UI and soak results are recorded with the run evidence.

### 7 Nov 2026 — Oozes and Birds: calls the brief and the critics left open
**A Nest holds a 0/2 Egg in fights while nobody stands on it.** **Why:** critic 1 said an empty slot on turn 3 is a trap, and a body keeps Rings and Hexes working on the slot. It deviates from critic 2's "the slot stays empty". The Egg is a real fight unit and blocks summons there; Eggs add no hero damage.
**A flight pays base sale value** with no `sell_value` query, so Fly South can't stack with sale bonuses. A plain sale still gets them.
**Trip floor: a bird is never home the same turn.** Mrs Dunnock's floor is next turn. Mrs Stork brings the bird away longest, not one the player picks, and only one that has missed a fight. **Why:** costing-2. The player's choice was dropped for simplicity; it can come back.
**No nesting.** A unit holding others can't be swallowed, and a Belly inside stays sealed. **Why:** it keeps "last in, first out" readable.
**Swallowing from the shop counts as a buy, not a play.** On Buy text fires; When played doesn't. It's the price of keeping a unit safe, and it leaves a real choice with on-play cards.
**A full hand doesn't lose a bird.** It waits on a doorstep and lands when there's room; a landing that completes a triple goes over the limit. **Why:** the rules never destroy a unit by timing.
**Copies inside a Belly count for triples; birds away don't, until they land.** Plain copies from Cut-and-Come-Again never count.
**Stone Soup's gain** stays if you buy the unit; end of turn or a refresh washes it; freezing doesn't keep it.
**Hasty Pudding** gives the unit back when it dies, after 3 friendly deaths, or when its side is empty. **Granny** adds Attack only. **Frumenty** can't lend Belly, Fly South, Shy, or on-play, on-sell or on-home text. **Mag Pye** acts in its own "first of all" step, and a Belly isn't text. **Mother Goose** strikes for each Nest's Bird's card Attack, once a side, with no source. **The Ratchet:** a unit on a Nest dying lands that Bird, once per Nest. **The Whistlers** take a quarter, golden a half, once a side; the Sparrowhawk and Goldfinches stay in reserve.
**Tier moves: Aunt Aspic to 3, Figgy Duff to 6.** Costing's other outliers are applied in the unit files; Tom Tit's kill gold is rewritten to next turn.
**Scouting shows Nest slots, not who's away.** It does show what's inside a Belly, because the opponent fought with it on view. **Why:** the Passage's surprise is meant to be guessed at, and the Belly's is meant to be planned around.
**All four tribes are in every lobby**, because `tribes_per_lobby` is 5 and only four have enough units. Pool copies per tier stay the same, so shops are thinner in each tribe than before. Not re-tuned.
**Bots:** a new `BotHeld`. Hard and Normal fly a bird when a trip's hinted worth beats the stats it takes off the board, never below a floor of bodies (2, then 4 from round 8; `min_bodies` in a build), and Hard won't when already behind what it scouted. Easy flies at a coin toss when short of gold. All three swallow rather than sell on a full board. A build with `depth_first` buys into Bellies early. **Not done:** choosing which unit goes in last (the wall), and placing Oozes to touch Granny outside Hard's fight search. The search runs without Eggs on its own board; a small error, kept for speed.
**Agreed by:** nobody yet; the reviewers come after this step. **Source:** evidence/design-review-2.md, evidence/costing-2.md.

### 7 Nov 2026 — UI and wording pass
**Scouting takes the shop row's place.** Their tray goes where the shop was and the shop shrinks to small tiles beside it, so their board, what you'd buy, your board and your hand stay in view and usable at both sizes. Full text goes to the usual detail panel; hero or ghost through a Who? token. **Why:** a panel over the shop made you choose between looking and buying, and that choice is the point of scouting.
**A triple doesn't wipe a wait.** Cold Frame waits carry onto the golden and restart when it lands; turn counts (Dozey's) restart as on any move. Tapping a third copy warns of it, the shop outlines a third copy in gilt, and the reward note says the Triple Reward comes when the golden is played. A triple made with a full hand puts the golden straight on the board with no reward, and a toast says so (engine behaviour, unchanged). Playing a golden from the hand frees a space first, so its reward is lost only if the hand was already over its limit (rule 7.1.2), which no toast covers. **Why:** losing paid-for waits to a good thing felt like a trap. Orchestrator's call after scope review: keep it. **The balance bench must cover this** (bots holding Cold Frame waits through triples), because no run so far has measured it. It's one line in core (`_combine`), so balance can undo it.
**Bots in a lobby never share a hero.** Asked of `GameSession._deal_heroes`, bigger than the small core field this pass was allowed, because names by hero read as nonsense with two Dame Hoolets. The human's offer is untouched. **Trade:** deals shift, so seeded results differ.
**Board tags come from the rules text** (`CardView.chip_text`: keyword, else a known pattern, else its first two words), never "Ability". **Why:** text changes shouldn't need a table of cards.
**One word each:** gold is the currency, an Acorn is the hand card. The acorn glyph on the gold plaque stays, since the owner approved that look; only the words changed.
**A ghost wears its owner's plaque:** dashed, NEXT tag, no health, "Ghost of X". There's no extra seat.
**Discover keeps its reminders open on the slip** because a tap picks; there's no room for a tap to read them.
**Long names lose first words instead of being cut:** lobby, End turn note, fight plate. The desktop lobby's names drop to 26 on the 1920 canvas (the 31 minimum is for phones).
**Test data keeps Oozes and Birds as fixtures,** named `fixture_*` in renders; the player's guide only describes what's in the lobbies. **Source:** ideation build 1 playtest round.

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

### 7 Nov 2026 — Cloud and Sol
**Owner's direction:** Claude work moves to the cloud, local work to Sol, with a small rule set for ideation. Written as `CLOUD.md`. **Picked:** no issues or PRs on this track, because a PR's default base is `main`. Several workers at once. A cloud Claude session reviews Sol's work, so builder and reviewer differ. **Stopped:** the local review of Oozes and Birds, rerun in the cloud.
### 7 Nov 2026 — Balance step: the runaways
**Dozey:** the core stays (feed him Acorns, wait three turns, double), with a ceiling: doubling adds at most +8/+8 (golden +16). A golden Dozey wakes again after a triple, capped by his golden ceiling: that's the triple's reward (coordinator's call, 7 Nov, with a test). A triple keeps waiting prizes like Cold Frame's. **Hedge Witch:** Hex stops at -8 Attack. **Why:** Dozey sat on 70-96% of final boards at 96/94 by round 13, and the Witch took a unit to -45. A ceiling keeps the card's idea and stops the one-unit game. Dozey is on 28.2% of final boards after it (2000 games, 1d12de0), down from 82.8%.

### 7 Nov 2026 — Balance step: bodies against spells
**Picked:** cheap spells lose rate, and late units gain body. Elderflower +1/+2 or +2/+1; Cold Frame +3/+3; Bread +1/+1; Stand Behind +1/+2; Boundary Stone costs 2 for +3/+3. Tier 4-6 bodies raised: Spider 4/3, Treasurer 3/5, Wisp 3/6, Belladonna 4/8, Burner 5/7, Mast 6/8, Queen 8/8. **Why:** reviewers found 2 gold for +4/+4 beat a 3 gold 2/5, so buying units was the wrong play. **Rings stack as they did:** they are bound to a slot, which is the cost, and Rings is not winning.

### 7 Nov 2026 — Balance step: shop odds and pool (deviates from rulebook 6.1.3)
**Picked:** the slice uses tier odds per tavern tier, 5% tier 1 at tavern 6 up to 13% tier 6, replacing the flat draw across every tier, with fewer copies per unit (15/15/13/13/11/9). **Why:** with a flat pool a tavern 6 shop rarely showed a tier 6 unit, which is what reviewers called hollow. **Added cards from the next batch:** Reel-Mistress, Changeling, Cradle Fetch, Beadle Warrenby, Cluricaun, Dr Urchin, Sergeant-at-Conkers. **Beyond the brief's list, to fill the tiers and the economy:** Whirligig Beetle (T6), Pipistrelle Echo (T5), Ichneumon Wasp (T4), Pennywort Snail (T1), Money Spider (T2); spells Rainy Day, Squirrel Away, Market Day, Harvest Supper, Hiring Fair, Beltane Bonfire. **Not added:** Reynard, Tuppence and Aunt Dormer. The brief wanted loop tests first, and tier 6 now has three units with enough to choose from for this slice. **Discover** tops up from lower tiers, so it always offers 3.

### 7 Nov 2026 — Balance step: no base interest (follows the owner over the brief)
**Picked:** interest stays on cards (Dame Farthing, Money Spider), not a base rule. **Why:** the owner's words, `owner-notes/2026-10-27b`, line 39: "there is no cap on carried-over gold, and we will not have interest." The brief lists interest as one route to a saving line, but the owner's direction outranks it, and cards can pay interest without changing the base rule. Saving's other rewards are the late sinks: Hiring Fair, Market Day, Harvest Supper, Beltane Bonfire, Last Orders.

### 7 Nov 2026 — Balance step: hero fixes
**Jill:** dropping a tier pays 2 gold and climbing back costs only 2, so the power is a real tempo trade. **Hob:** borrows 3, repays 3 and 1 Health. **Farthing:** 1 per 4 carried, up to 5. **Why:** the old Jill paid back less than the climb cost, and the old Hob's debt was a plain loss.

### 7 Nov 2026 — Balance step: Acorns and the flat cards
**Picked:** Sleeping Partner pays every 3 turns, not once. Mast pays an Acorn every turn, 2 with a Hoard (first version, 2-3 Acorns at 3 Health more, ran away: Treasury won 44.6%, the Larder hit 37). Treasurer grows per 2 gold held. Rainbow Chaser has +1/+1 per band in fights and pays 1 gold per band sold, so it fights or cashes out. Sexton Beetle pays twice a fight. Charcoal Burner burns above 5 and pays +1/+1 per 2. Sergeant at Conkers throws Acorns for damage, a second payoff for holding them. **Why:** the Acorn plan was unreachable (a Stash held in 19 of 4,475 turns), and the owner likes it.

### 7 Nov 2026 — Balance step: Belladonna
**Picked:** she does something in both rows: at the back, Nightshade on the 2 front enemies facing her; at the front, on the enemy across. **Why:** the front row did nothing, a trap for a new player. Fixed by rule and text.

### 7 Nov 2026 — Balance step: Health and damage (deviates from rulebook 2.2.5 and 10.1.4)
**Picked:** 40 starting Health for the slice instead of 30 (rulebook 2.2.5), and a damage cap per round, 3 at the start up to 15 at round 14 and after, instead of 5/10/15 (10.1.4). The cap still comes off at top 4, as the rulebook says (`damage_cap_off_at_alive`). Both on `GameConfig.full_game()` only; the bare rules keep the rulebook's numbers. **Why:** at 30 Health the median seat was out at round 11, before any late game. Now round 14: `evidence/balance-1.md`.

### 7 Nov 2026 — Balance step: bots
**Placing:** bots keep a unit in its row and slot unless they have a reason, a small bonus for not moving a board, so scouting a board tells you something. **Queen:** stands in a corner with the cheapest unit behind. **Jill:** a triple-hunting plan drops a tier when it holds pairs below. **Shake the Tree:** no longer avoided. **New bot:** `neutrals_purse`, The Long Purse, saves on a schedule and spends late. **Pass landing:** a swap is now judged by where the Pass then lands, because a swap could move the Pass's own start.

### 7 Nov 2026 — Balance step: the ladder and Hard's choice of build
**Easy plays worse in ways a player can feel,** not just slower: climbs late and never early (curve 5/8/11/14/16), buys with a poor eye (a unit's worth swings ±60%), hardly ever replaces a unit on a full board, doesn't read the scouted board, and places units where they land. **Normal** refreshes at most twice, down from 4. **Why:** step 1 made Easy stronger, not weaker: Normal among Easy fell from 2.77 to 3.37. At 3b3b5c5: Normal among Easy 2.50 ±0.26, Hard among Easy 1.97 ±0.21, Hard among Normal 3.30 ±0.19. An earlier pass, never committed, showed Hard winning 5% among Easy, as Easy reached tier 6 by round 9 for lack of anything else to spend on. **Hard's prior:** a strategy's `power` falls from 25 to 6-8, spread over the four sound builds. **Why:** Hard took one build in 98% of seats. **Hag and Help climb sooner,** as tier 6 now pays. **Not done:** Rings and Help get no prior, so Hard rarely takes them, which is a limit of the bot rather than a verdict on the builds.

### 7 Nov 2026 — Balance step: where the slice stops
**Picked:** stop at the shape, not at fine numbers. Two tribes can't hold long-term balance, and every number here will move when tribes arrive. The tests of the shape: a game reaches tier 5-6, builds differ, none runs away. **Echo and Last Orders:** a spell that spends all your gold pays only its first target, since the gold is gone. Kept: rare, and honest to the words.

### 7 Nov 2026 — Scope review: the opening of rounds 1-2
**Picked:** the first shop of rounds 1 and 2 shows Rainy Day and a new spell, A Leg Up (1 gold, "Your next tavern upgrade costs 2 less"), in place of a drawn spell. Neither comes from the pool, and a refresh doesn't bring them back. So: a unit now, gold next turn, or a climb. **Why:** all three reviewers found rounds 1-2 scripted, and carrying gold alone wasn't enough to break that. Kept small: one new card and one rule. Heroes' powers weren't changed. **Measured:** Normal and Hard toss a coin. Over 300 games, tempo 4.52, economy 4.53, climb 4.44 average place, each ±0.16. A Leg Up at 3 off gave climb 4.19, so it went to 2. **Not measured:** whether a person finds it interesting. The next reviewers judge that.

### 7 Nov 2026 — Scope review: Mast, Partner, Chaser
**Old Mother Mast:** "After you buy a unit: get an Acorn, once a turn. 2 if you hold a Hoard." The owner wants economy tied to actions ("tying economy effects to specific actions", 02h); paying each turn for nothing wasn't, and buying a unit is what this step wants more of. **Sleeping Partner:** see its own entry below. **Rainbow Chaser:** 5 gold more for all seven, on top of 1 per band, restoring the card's creative core. Rainbow 15.8% wins at 400 games: not running away.

### 7 Nov 2026 — Scope review: the last climb (orchestrator's call: provisional)
**Picked:** tavern 5 to 6 costs 13 in the slice, not 11, for build 2. **Provisional:** it was tuned on one bot at 400 games (Spend Late, 29.2% ±5.5 wins to 22.2% ±4.3). Hand play decides.

### 7 Nov 2026 — Scope review: placing fails its bar (orchestrator's call: merge anyway)
**Result: FAIL.** Search over shuffled is 0.14 ±0.27 at 3b3b5c5 against a bar of 0.5, by the bench's paired method. **Tested:** `STAY_BONUS` 0 reads 0.14 ±0.28, Whirligig out 0.37 ±0.28, `ROW_STAY` 0 0.36 ±0.28, none near the old 0.91. None is shown to be the cause; the cause is unknown, so nothing was changed. **Merging:** yes, as it's a bar for the end, stated as failing. Placing is what all three reviewers praised, so this is the first thing to come back to.

### 7 Nov 2026 — Scope review: Sleeping Partner (orchestrator's call)
**Picked:** the bound lives on the unit: 3 payments in that unit's life. A move restarts the 3-turn wait but never the count. Selling and rebuying gets a new unit, and so does a triple. **Why:** the owner wants rewards for inaction time-bounded (02i). The first bound, 9 turns in a slot, cost nothing: a move on turn 9 missed no payment and started the count over, so it wasn't a bound at all. It hasn't been benched.

### 7 Nov 2026 — Scope review: Normal's refreshes (orchestrator's call)
**Picked:** Normal stays at 2 refreshes a turn, because a level below Hard should shop less. **Added:** a bench arm, `hard_lobby_normal4`, Normal at 4 refreshes, to show Hard's place both ways. It hasn't been run.


### 7 Nov 2026 — Tribes 5 and 6: lane foundation
**Picked:** implement design-review-3's bell after Mag Pye and before every other Start of Combat
(including Goose and heroes). Both boards bind from one snapshot; lenders cannot change a later
unit's snapshot stats. Mire owns the ground and inbound attacks. Quarry owns a marked animal.
One targeting table serves turn attacks and out-of-turn attacks; a live Mire maker restricts
joiners and immediate attacks as well. A maker changing sides breaks its existing locks for the
rest of the fight, even if it returns. Its mud remains Mired ground.

**Death timing:** capture witnesses before the whole simultaneous death batch leaves, then notify
`on_enemy_death` and `on_take` after removal. Hunters dying in that batch count; Hunters already
gone do not. Shared quarry gives one Take to the first Hunter in reading order. Swallowing and
side changes invalidate marks without paying. Summons never inherit a mark.

**Naming migration:** the old library's Mudwallow Toad keeps its damage-and-skip design under
**Pin**, with status **Stalled**. Scarecrow uses Stalled too. New Mire means only Bog folk's
patches. The old sandbox scenario keeps id `mire` so saved links still work; its displayed title
is Pin. This also updates the prototype spec and fixtures, so players never see two Mire rules.

**Costing calls accepted for the coming roster:** use the final numbers and caps in the two tribe
docs, including Bridge Toad 1/3 and highest-Attack-plus-attack payment, Bufo 1/4 plus halving,
Peat Cutter 1/1 once, Highness once per fight and the spell-discount frog Prince, Tiddy Mun 3/5
twice and maker-only growth, Prima Donna 2/8 and Bitter once per enemy, Peat King 5/9 and two
Peatlings. Hunters keep Lutra 2/4 and 1 gold, Brother Wolf 3/4 without counter-hit tax, Grizel
Attack-only growth, Old Brock 2/5, and golden Toll-Bard's 3-gold ceiling. The Laird's intentional
4/6 over-budget body (+29% estimated) stays, as the review explicitly ruled; his +1/+1 is only
for Hunters with quarry. Great beasts remain on file.


### 7 Nov 2026 — Bog folk implementation calls
**Bridge Toad:** once per fight, as its final Engine needs table specifies. The payment needs
both the bell's top-Attack snapshot (ties count) and the actual attack. Merely marking pays nothing.
**Bufo:** halving follows Bitter, and also works when she dies to her quarry's counter-damage.
It removes half the remaining Attack, rounded down. **Gideon:** his +2/+4 is for the immediate
reply alone, not lasting growth on every reply. **Jenny:** her -2/-4 is a live aura and ends with
her; the strongest living same-row neighbour can answer even if Jenny faints in that exchange.
**Peat King:** no room means no Peatling and no spent summon; at most two actually rise. No queued
summon is added. **Prince:** transforms during the third-kiss fight without laying a late patch,
keeps identity and buffs, and returns the Highness pool copies when he leaves. Princes triple
with Princes after fight rewards, never with Highness. The discount applies to the first spell
bought each turn; multiple Princes add before the floor of zero. It never pays for waiting.

**Progress limit:** these are engine/content changes. Hunter content, strategic bots, lane UI,
phone renders, portraits and six-tribe shop measurements still follow in the requested order.
`evidence/placing.md` is absent in this checkout; `evidence/position-test.md` and the binding review
supply the placement evidence. No Great beasts content is built.


**Art sequencing:** keep an explicit `content/portraits_pending.json` list while the requested
engine → content → bots → UI → art order is in flight. Tests require the established tribe fallback
for those cards until their own art exists; all other cards still require their own portrait.
Remove completed entries in the art step. This keeps art availability from blocking engine and
content validation, as the owner requested, without silently treating every fallback as complete.
### 7 Nov 2026 — Cloud review 1: Acorn reminder from item values
Resolve Acorn/Stash/Hoard values from their item JSON when the effect schema loads. The schema retains a readable template rather than another copy of 1/5/16. Reason: the review caught a stale 20 after the card changed to 16; all card and UI reminders already share this schema. A real-cast regression ties the displayed values to paid gold.

### 7 Nov 2026 — Cloud review 2: say Shy's payment
Restore 2 gold (4 golden) in the shared Shy reminder. Reason: replacing the number with “its gold” made a core economy effect impossible to evaluate without knowing the card's implementation. Normal/golden walk-out regressions verify the stated amounts.

### 7 Nov 2026 — Cloud review 3: keep a selected card beside the purse
Wide phones get a separate full-height reader beside persistent economy controls. A selected board uses 180×163 pockets, above the 122 canvas-unit tap minimum; actions sit in the economy column instead of consuming the reader. Reason: the prior idle-only fix missed actual selection, and stacked actions left 314 pixels for roughly 540 pixels of rules. Scout captions move below stat badges. Both specified states were rendered and inspected, with complete text and controls visible.

### 7 Nov 2026 — Cloud review 4: Hex's printed base counts
Keep the combat formula: the card explicitly has a base −1/−2 before spell growth. Display base + counter with the card's ceiling, using one calculation shared by recruit and combat. Reason: the former board/CLI labels exposed the growth counter instead of the actual debuff. No strength change.

### 7 Nov 2026 — Cloud review 5: no Mast payment from hand
Exclude the event's own unit from Mast's listener. Reason: its text is a board effect and does not grant an on-buy reward to itself in hand. Existing board Masts still hear a new Mast purchase, and the bought Mast retains its once-per-turn payment for use after being played. Both normal and Hoard cases are tested.

### 7 Nov 2026 — Cloud review 6: restore Hiring Fair's price
Return Hiring Fair to 6 gold, following the owner's instruction. Retract the earlier unmeasured 4-gold choice: the complaint was overlapping Triple Reward offers, not cost. Keep advancing offers and the shared tier-6 eligible pool; neither implies price parity with a Triple Reward. No price-balance claim is made.

### 7 Nov 2026 — Cloud review 7: Dozey is an early doubling carry, not an unlimited late bank
Give Dozey a +12/+12 permanent-bonus ceiling (+24/+24 golden), including all permanent sources and triples. Keep its three-turn double and Acorn conversion. Slot/aura and temporary combat buffs remain available, preserving placement choices. Reject fully capped feeding without consuming Acorns, and let bots cash or use them elsewhere. Reason: limiting only conversion rate left Dozey largest in every sample. With identical seeds 53–64 and all other fixes held constant, the largest unit changes from 67/90 Dozey to 54/36 Cluricaun. The ceiling fits early doubling, while a late board has reasons to replace it. No other card gets the ceiling.
