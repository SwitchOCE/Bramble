# Review: content5 wording (`origin/ideation/main...c5f8594`)

**Counts: cut 0, ask 2, note 3.** Focus: `7f71af9` (fixes from `review-content5.md`) and `c5f8594` (wording for Horseshoe, Barn Owl, Redwing, Market Stall). Scope: the owner's "clear and concise… if it's implied, let it be implied" (8 Nov), `wording-guide.md`, and "existing designs stay as they are".

**Does it move the problem?** Yes. All four card texts are 9–11 words (guide median ≤ 11), the card-name reminders are gone, and the edge cases moved to Details. `git diff 45f719a c5f8594 -- content` changes only `text`, `golden_text`, `details`, `keywords` and reminders. No effect data, numbers or existing cards changed.

## Ask

- **ask** `content/schema/effects.json:774`: the Egg reminder "A textless stand-in with half its Bird's stats" no longer says where Eggs come from: an empty Nest whose Bird is flying south. Redwing's only listed keywords are Fly South and Egg, and the UI doesn't link Egg to Nest, so a reader could expect any Bird that flies south to leave an Egg beside Redwing. Possible fix in about 12 words: "Fills an empty Nest while its Bird flies south, at half stats."
- **ask** `content/units/barn_owl.json:35`: "Never takes quarry" moved to Details. In code (`combat_lanes.gd:113`) this also refuses a lender's quarry and its Attack buff, so placing Owl beside a quarry lender gains nothing. Guide rule 2 keeps conditions that change how you play. On the other side, it is rare and fits the owner's "let it be implied". The orchestrator decides.

## Note

- Horseshoe, "halve the Ring across from a slot": "across" in the guide's vocabulary signals the enemy, and the targeting UI limits the choice to your own slots. Clear enough.
- Market Stall Details, "Adds units up to 7; Pipkin gets spells instead": correct (`market_stalls.gd:31-41`), but terse. The third-Stall cap sits in Details correctly, because `remove_unavailable` stops a dead third Stall from being offered.
- Redwing Details, "even for Mother Goose": cryptic to anyone who doesn't know Goose's Egg is 0/2. It's acceptable as a ruling.

## Earlier review's items: fixed?

- **cut (ghost Horseshoe):** fixed. `game_session.gd:810-815` filters Horseshoe out of `_ghost_slots`. **Probed:** with the filter set to `return true`, `test_eliminated_casters_ghost_does_not_keep_a_spent_horseshoe` fails (8/9 pass). Restored afterwards.
- **ask (7-unit ceiling):** resolved by the owner's call. `shop_size` now adds only `MarketStalls.unit_bonus`, which is capped at 7 minus the ordinary size. `HunterRecruit.start_turn` and its order after `_fill_shop` match `c11e55d` exactly (diffed).
- **ask (Owl immunity):** kept, as the owner called it. Now stated in Details.
- **simplify (Redwing plumbing):** done. The `redwing_eggs` rules are gone and the aura reads `egg_full_*` counters.
- **simplify (portraits):** re-rolled. Not re-inspected here.

## Per card

Each text matches its code (`combat_rings.gd`, `back_row_immunity.gd`, `redwing.gd`, `market_stalls.gd`). A player reading only the card gets it right apart from the two ask items. Vocabulary follows the guide.

## Out of scope

Nothing found.

## Ran

`./scripts/check.sh` at `c5f8594`: all ten steps passed, 1,392/1,392 tests. One mutation probe (above). I viewed the PC Details render. I didn't run soak or play.sh, and didn't check the phone render.
