# Decisions the ideation agents made

The owner handed every open call on this branch to the agents (6 Nov 2026). Each entry: what was open, what was picked, why, and who agreed. Newest first.

Format: `### date — the question`, then **Picked**, **Why**, **Agreed by** (the reviews), **Source** (decision card, rulebook item or owner question it settles).

### 6 Nov 2026 — Engine calls the brief left open
**Picked:**
- `GameConfig.defaults()` stays the bare rules (no heroes, no spells, every tribe); `GameConfig.full_game()` turns them on (3 heroes offered, spells in shop, 5 tribes). The UI and bots flip when ready.
- `CorePort.manual_choices` defaults to false: the Triple Reward casts itself and options take the first, so today's screens keep working until the UI handles choices.
- Spells and hand items are one thing (a card with a play effect in `content/spells/`); only spells fire `on_spell_cast`. Both count against the hand limit. A cast spell's copy goes back to the pool (rulebook 5.3.7).
- The Triple Reward is now the spell the rulebook describes (7.3.6): Discover from the tier above. It replaces the prototype's direct draw (SPEC 9).
- The spell slot draws on its own random stream, so turning spells on can't shift which units a shop shows.
- The hero deal doesn't repeat a hero until the roster runs out (2.2.1). Three samples can't serve eight players, so with samples only, heroes repeat across players; the soak proves no repeats with a roster of 33.
- Heroes are offered 3, per the brief; rulebook 2.2.2 says 2.
- `tools/play` difficulties map to today's personalities until the strong bots land: easy = greedy, normal = the four mixed, hard = balanced and tribe. They aren't a measured ladder.
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
