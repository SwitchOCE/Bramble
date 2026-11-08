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

Text differences, all fine because each is shorter and the wording guide sends caps to Details: Jack Daw's "buffs across", Goose's "Nests strike across", the Cuckoo's plural, the Whistlers' cap moved to Details, and Stork's Details naming the Bird away longest.

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

The Dunnock survivor wastes her trigger on an already-due first Nest instead of the next eligible one. That breaks her Details ("first eligible Nest"). One test would catch it: F1 due next turn, F3 later, expect F3 to shorten.

Read and correct per spec: Tom Tit applies after Redwing, strongest copy only, with a matching forecast. The Cuckoo's extension is set once when a Bird flies, and her growth is permanent. Goose strikes flat, and her buff reaches Birds away through `all_units()`. The Lump reads current stats before auras, with halves rounded up. Dunnock reaches a Nest beside her and the Egg stays. Whistlers' count resets before `land_due`, and Stork's returns count. The Ratchet lands in the Nest's slot only and leaves the trip alone. Old Tern Discovers Birds of your exact tier.

## 3. Other tribes

None of their card effects changed. Shared code: `support_number` generalises `redwing_factor`, with a missing-key default of 0 where it was 1, but every Redwing entry carries `factor`. Discover's change is gated on `exact_tier`. `CombatUnit.view` merges `egg_info`, which only Eggs carry. `test_oozes.gd` swaps a Tom Tit fixture for a Swallow, because of the tier move.

## 4. Bots

Fine. `cards.json` keeps and row hints were updated, and the three Bird strategies' unit weights were re-pointed to the new roles. Strategy `power`, tribe priors and curves are unchanged, and the tests assert the power values. `bot_lanes` scores the Cuckoo and Dunnock beside Nests, and `bot_eggs` and `bot_placer` stop pinning Dunnock onto a Nest. That teaches bots where positional text works. It doesn't steer them into Birds.

## 5. Wording

Fine. Normal text runs 7–20 words (Cuckoo 20, Goose 20), under the 22 maximum, but the Birds sit above the p90 of 17 on four cards. "Beside" is used correctly for `adjacent` everywhere. Triggers use the colon form. Durations are implied, and "permanent" sits only in Details. The one wording ask is the Lump's "lands" (above).

## 6. Out of scope or extra

All fine: the phone screenshot (629 KB) committed as evidence; the Cuckoo on the portrait fallback list; Barn Owl kept as a non-pool definition; two new rule tags; the stale test name `test_swallow_pays_when_played_next_to_a_bird`.

Not run: the soak, the full gate on this machine after mutations, and the UI tests under mutation.
