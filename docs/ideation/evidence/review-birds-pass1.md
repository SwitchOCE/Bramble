# Review: Birds pass 1 (`ideation/birds-pass1`)

8 Nov 2026, a fresh cloud reviewer. Target: `git diff origin/ideation/main...origin/ideation/birds-pass1` (67 files). Scope: the owner's words in `owner-notes/2026-11-08f-birds-case-study.md`, plan step 3, and `content/birds-pass1.md` (pass 1b).

**Counts:** 1 cut, 3 ask, the rest fine.
**Moves the problem: yes, on paper.** Every T1 Bird now pays on turn 1 (Swallow's gold, Chiffchaff lands as a 2/3, Dunnock is a 2/3), Redbreast is a par 2/4 alone, and two routes run T1 to T6 with no empty tier. That answers "why would I play the early-game Birds" and "synergy… along the entire journey". It's unmeasured: the soak proves rules hold, not that Birds win more. A bot or playtest win-rate read is the real test.

- **Cut:** rulebook 12.1.4 and `engine.md` (lines 262, 390) still say Mother Goose's Egg is 0/2. The code, card Details and spec say it follows the normal rule. The rulebook wins over cards, so it must be updated.
- **Ask:** enemy Eggs now show their Bird's current stats and trip countdown in a live fight (`game_session.gd:748` passes both live `combat_board()`s; `card_detail.gd:274` has no side check). Scouts hide the same data. Decide whether that's intended; the spec's Egg UI line doesn't say.
- **Ask:** Dunnock's skip of an already-due Nest is untested (mutation survived, below).
- **Ask:** the Lump's Details say it loses stats "when its Bird lands"; the golden Details say "comes home". "Lands" is the Ratchet's word. Use "comes home" in both.

## 1. Content against the spec

Checked all 16 unit files field by field. **Stats and tiers match every card.** Slice Birds in the pool: T1 Swallow, Chiffchaff, Dunnock; T2 Redbreast, Redwing, Jay; T3 Tom Tit, Jack Daw, Old Tern; T4 Stork, Cuckoo, Mag Pye; T5 Goose, Lump; T6 Ratchet, Whistlers: **3/3/3/3/2/2**. Barn Owl is `pool: false`. The other Bird-tagged files (Buzzard, Fieldfare and so on) are fillers without `set: slice`, so they're not in the game. Golden numbers come from schema doubling and match each *G* line.

Text differences, all fine: they're shorter, and the wording guide sends caps to Details.
- Jack Daw "steal a quarter of buffs across" (spec: "…of the buffs on the enemy across"); the +4/+4 cap is in Details.
- Goose "Nests strike across for 2" (spec: "each Nest strikes the enemy across").
- Cuckoo uses the plural ("Birds flying from beside this…", "Birds away with Nests beside this").
- The Whistlers' "(up to -3/-3)" moved to Details. Guide rule 2 allows it.
- Stork's Details add "The one away longest first." That's existing behaviour, now stated.

## 2. Mechanics and tests

GUT runs here. Baseline: `test_birds.gd` and `test_birds_pass1_content.gd` gave 73/73 passing, and a full run gave 1,469/1,469, matching the build notes. Mutations, one at a time, then reverted:

| Mutation | Caught by |
|---|---|
| Whistlers cap 3 → 99 | `caps_three_homecomings…` |
| Whistlers counts Eggs again | `does_not_target_an_away_birds_egg` |
| Lump combat aura full, not half | `lump_has_the_same_stats_in_a_fight` |
| Tom Tit sums copies instead of taking the strongest | `only_strongest_tom_tit…` |
| Goose buffs owned units only, not Birds away | `goose_homecoming_permanently_buffs…away` |
| Ratchet once-per-Nest note removed | 5 Ratchet tests |
| Cuckoo departure extension removed | 3 tests |
| Old Tern `exact_tier` ignored | 3 content tests |
| **Dunnock no longer skips a Nest already due next turn** | **none: survived** |

The Dunnock gap: `shorten_trip` clamps on its own, so the survivor's only effect is that Dunnock wastes her trigger on the first Nest instead of moving to the second. That breaks the stated reading-order rule ("first eligible Nest"). It needs one test: Nest F1 due next turn, F3 due later, so F3 should shorten.

Read and correct per spec:
- **Tom Tit:** applies after Redwing in `combat_auras`, strongest copy only, and the forecast matches.
- **Cuckoo:** the extension is set once at `send_south`, from each Cuckoo beside the Bird. Growth is permanent and reaches covered Nests.
- **Goose:** flat damage, with golden 4 from doubling. The homecoming buff goes through `all_units()`, which includes Birds away.
- **Lump:** reads current stats before auras, with odd halves rounded up.
- **Dunnock:** reaches a Nest beside her, and the Egg stays.
- **Whistlers:** `homecomings_this_turn` resets in `start_phase` before `land_due`, so natural homecomings count, and so do Stork's.
- **Ratchet:** lands in the Nest's slot only, with current stats (golden doubles Attack). The away entry isn't touched. A filled slot uses up that Nest's single landing; that's a reasonable reading of "once per Nest".
- **Old Tern:** Birds only, from your exact tier, with no lower-tier fill. Rulebook 6.2.3 already allows fewer offers.

## 3. Other tribes

No other tribe's card effects changed. Shared code changes:
- `support_number` generalises `redwing_factor`; its missing-key default is now 0 instead of 1, but every Redwing entry carries `factor`.
- Discover's change is gated on the new `exact_tier` flag.
- `CombatUnit.view` merges `egg_info`, which only Egg specs carry.
- The Ratchet no longer falls back to `summon_slot`, which affects only Ratchet landings.
- `test_oozes.gd` swapped a Tom Tit shop filler for a Swallow, because Tom Tit moved tier. That's a fixture change, not a behaviour change.

## 4. Bots

Fine. `cards.json` keeps and row hints were updated for the new roles. Barn Owl was removed and the Cuckoo added. Within-strategy unit weights were re-pointed to the new roles: Stork 5 → 10 and Goose 12 in Summer and Winter; Cuckoo 8/10/2. Strategy `power`, tribe priors and curves are unchanged, and `test_content5_bots` asserts the power values. In code, `bot_lanes` adds placement scoring for the Cuckoo and Dunnock beside Nests. `bot_eggs` and `bot_placer` stop pinning Dunnock onto Nests, which the new text requires. That's teaching bots where positional text works. It doesn't steer bots into Birds or hide weakness.

## 5. Wording

Fine. Normal text runs 7–20 words (Cuckoo 20, Goose 20), under the 22 maximum, but the Birds sit above the p90 of 17 on four cards. "Beside" is used correctly for `adjacent` everywhere. Triggers use the colon form. Durations are implied, and "permanent" sits only in Details. The one wording ask is the Lump's "lands" (above).

## 6. Out of scope or extra

All fine:
- The committed phone screenshot (629 KB), as evidence.
- The Cuckoo registered in `portraits_pending.json` with the tribe fallback.
- Barn Owl kept as a non-pool definition.
- The new rule tags "Eggs grow" and "Longer trips".
- The stale test name `test_swallow_pays_when_played_next_to_a_bird`: cosmetic.

Not run: the soak, the full gate on this machine after mutations, and the UI tests under mutation.
