# Audit delta: main (13f44dd9) to dev (origin/dev 5d697e07)

Read in the detached worktree /data/worktrees/fix-round-dev. Paths are relative to it. "Same" means the file has no diff from main, so main's line numbers still hold.

## Changes across the codebase that touch every audit file

- **No shared pool.** `CardPool` is gone (`src/core/units/card_pool.gd` deleted). The shop and Discover draw from fixed weights, `ShopOdds` (`src/core/units/shop_odds.gd`; `recruit.gd:700-712`; weights at `game_config.gd:27-29`). Selling, casting and losing a card return nothing (`recruit.gd:592-596`, `:210-247`). Discover's other options just close (`recruit.gd:486-500`).
- **Slot buffs are now "Renown"** (`content_set.gd:17-26`: "The unit that starts the fight here, and any reservist who steps in, has +1/+1 for each."). Slots draw a Renown banner and slot keyword pills (`recruit_board.gd:53-93`). `Rules.slot_buff_percent` and Edgewright's percent query are removed.
- **Pigeons were reworked.** Medals, Decorated, Order, Stiff Upper Lip, Adjutant, Brigadier and Field Marshal are gone. In their place: Renown, Reserve with a limit of 2 a fight (`game_config.gd:49-51`; Quartermaster +1), Supply N (squares that are used up for good) and Charge N (circles that refill each fight), shown as pips over the stat discs (`src/screens/card_pips.gd`; `card_terms.gd` `pips()`). A paid ability is now an "Active", shown as a coin button with no name (`glass_parts.gd:478-517`; shared `active` entry, hidden).
- **Mice were reworked.** Hand-me-down (`mouse_hand_me_down`): "When this dies, the nearest friendly Mouse gains its Attack this fight." Pile on now has a number: "The first N times a neighbour attacks each fight…". Cousin is now "A 2/2 Mouse with Hand-me-down". Charge appears on Thimble Captain, Needle Sister, Grandmother Hob and Old Mother Needle.
- **Ghosts and async play** are in the core (`src/core/ghosts/`, `game_session.gd:292-336`, `game_content.gd:104-112` `new_async_session`). Only the harness calls it. The playable game (`game_flow.gd`, same) still plays 7 live bots, so the screens are unaffected.
- **Badger, Locust and Thorn** changed only in small fixes (lend_health, overrun, sword_heir, bury_base).

## interaction.md

1. **Hand full loses the Triple Reward: unchanged.** `_gain` is at `recruit.gd:592-602`. `_combine` is at `:757-811`. The golden goes to the hand if there is room or no copy was on the board (`:789-795`). The reward goes through `_gain` (`:796-800`) and logs `card_lost`. The event carries `reward_uid: -1` (`:808`). The test is still `tests/core/test_triples.gd:270`. Still no screen reads `card_lost` (no hits in `src/screens` or `src/game`). Proven again in shot b01b. **New ways to lose a card with a full hand:** Hayloft Aunt's Cousin (`mouse/mechanics/aunt.gd:9-12` → `recruit_context.gd:295-305` `give_card` → `_gain`), as well as Horde-runner's Hopper. Discover picks are still not checked against a full hand (`_pick` `recruit.gd:486-500`).
2. **Buying with a full hand: unchanged.** `_buy` refuses at `recruit.gd:183-184` ("hand is full"). The shop-to-board drop is still buy-then-play in the UI (`recruit_input.gd`, same). Shot b02/b02b shows the same result. **Cards with an effect when gained (on_recruited) on dev:**
   - Master-at-Arms (Badger T3), "Recruit: Give a unit +N Fury." Target FRIENDLY_UNIT, hand or board (`badger/mechanics/arms_master.gd:12-16`).
   - Harvest Piper (Mouse T2), "Recruit: Give your other Mice +N Attack." Board only (`mouse/mechanics/piper.gd:9`).
   - **Hayloft Aunt (Mouse T2, new)**, "Recruit: Add a Cousin to your hand." The Cousin is lost if the hand is full (`aunt.gd:9-12`).
   - **Quartermaster (Pigeon T4, new)**, "Recruit: Give a unit in your hand Reserve." It has a new target kind, `HAND_UNIT` (`mechanic.gd` enum; `quartermaster.gd:12-36`), never itself and never a unit that already has Reserve. With no target chosen it takes the leftmost (`recruit.gd:666-676`), and it asks for a target only when there is more than one candidate (`:671-674`). It also raises the reserve limit by 1 (`quartermaster.gd:39-48`).
   - Goldens of all four fire when the triple forms (`recruit.gd:594-602`, `:795`).

   **Effects that depend on where a unit sits (matters for buy-to-board):** Reserve now matters more. Territorial (T1) and Home Guard (T3) have Reserve, and The Colonel's "Reservists from your hand have double Renown" (`Q_HAND_RENOWN_TIMES`) applies only to units in the hand. The hand shows Reserve marks over "Hand N/7" for the reserve limit (`recruit_counts.gd:107-122`). Renown counts only for a unit on a slot, which lifting the unit shows (`recruit_board.gd:106-123`). Origin: `bought_copies` stays (`recruit.gd:202`). There is a new `copies` field, and sell value now counts every copy except on tokens (`rules.gd:100-104`). "Units in your hand have Reserve" (Colonel on main) is gone.
3. **No hand-to-board swap: unchanged.** `recruit_input.gd` is the same. The core refusal moved to `recruit.gd:292-294` ("choose an empty slot"). LegalActions lists plays only into empty slots (`legal_actions.gd:66-83`). Board-to-board still swaps (`_move` `recruit.gd:399`). Shots b03 and b03c show it.
4. **Triple highlight: unchanged.** `recruit_duplicates.gd` and `glass_duplicate_glow.gd` are the same. One owned and two in the shop light all three (b04). One owned and one in the shop gives MATCH on the shop copy only (b04b). New in b09: hand cubs glow strongly too, because a cub was still in the shop.
5. **Left-click skips the fight: unchanged.** `game_controller.gd` is the same (`:28-31`, `:239-241`).
6. **"Unit" type line: unchanged.** `glass_parts.gd:282-292` still reads "Tier %d · unit · costs N/sells for N". `types` is still not passed to the view (`view_adapter.gd:238` `printed_unit`; only `browser_catalog.gd:22` copies it). Shown in b07.
7. **Tooltips: mostly unchanged.** `glass_tips.gd` (+17) and `recruit_tips.gd` (same). New: a reminder line that starts with a cost ("1: …") draws the cost as a coin (`glass_parts.gd:349-378`). A pill with no number shows the term's general reminder instead of a bare "N" (`card_terms.gd` `reminder_for`). Charge uses-left counters show as pips instead of pills. **"Recruit:" still has no reminder box** (b11b: Hayloft Aunt shows boxes for Hand-me-down and Cousin, none for Recruit).
8. **Recruit screen controls:** the same layout (`recruit_shop.gd` is the same). Additions: Reserve-limit marks over the hand count (`recruit_counts.gd:107-122`), Renown banners on slots, and Active coin buttons. Numbers on dev: 5 gold on turn 1, units cost tier + 1 (2/3/…), refresh 1, and turn 2 upgrade 7, as on main.

## end_of_fight.md

- **after_fight implementations on dev: three, not four.**
  - Grudge (`badger/mechanics/grudge_pay.gd`, unchanged): pays alive or dead.
  - Relic Seeker (`badger/mechanics/relic.gd:17-35`, unchanged): gold right away through `ctx.gain_gold`, still left out of the "+N gold" notice (`view_adapter.gd:213-217` counts only fight `gold` events).
  - **Old Campaigner, rewritten:** "After each fight, give this slot N Renown, or M if this survived." (`pigeon/mechanics/campaigner.gd:8-14`, `ctx.add_renown(unit.slot, …)`). It now buffs the slot, not the unit, and still fires if it died.
  - **Adjutant is deleted.**
- Order and plumbing are the same. `game_session.gd:331-336` runs `_after_fight` for live players only (now `live_a`/`live_b`, so ghosts and recorded runs are skipped), and stores `fight["after"]`. `_after_fight` builds the report at `:351-363`, and `Recruit.after_fight` is at `recruit.gd:576-580`. **`fight["after"]` is still read by no screen** (no `"after"` reads in `src/game` or `src/screens`). Results still pop silently next turn.
- **In-fight effects that last (dev list):** Padre ("After a friendly unit dies, give its slot N Renown"), Flying Ace ("After this kills, give this slot N Renown"), Fencing Master and Needle Pikeman (Attack for good), Grandmother Hob ("give it +N Attack permanently"), Old Mother Needle ("Your Hand-me-downs are permanent"), Sett Sexton, Seed and Lone Hawthorn (Compost), Root (spends Compost), Molt, and Famine-caller/Swarm Lord (Tide). Shrew Cutpurse's gold now pays on every pile-on ("After this piles on, gain N gold"), into `gold_next_turn` (`mouse_rules.gd:135`). Medals no longer exist (`pigeon/lib/medals.gd` deleted).
- **End of turn (before the fight), Pigeon on dev:** Sentry (Supply N: slot Renown), Colour Sergeant (full row: Renown), Grenadier Guard (Guard post Renown), and Regimental Sergeant Major (every slot Renown). Dormouse Cook is unchanged.
- **Start of fight, new on dev:** Lieutenant (row full: deals half the slot's Renown), Colour Ensign (this slot copies your highest Renown), Wing Commander, and Parish Standard-bearer.

## keywords.md

**Terms dev shows** (from the display.json files; hidden entries left out):
- shared: Guard, Attacks twice, Cleave, Divine Shield, Reborn, Venomous, Stealth (the last four still unused), **Charge, Supply, Private**.
- core: **Renown**.
- Badger: Fury, Grudge, Lends, Overrun, Squire, Outnumbered (unchanged).
- Locust: Molt, Tide/Tide +N, Hopper bonus, Hopper, Eat (unchanged).
- Mouse: **Pile on (now numbered)**, **Hand-me-down**, Hit, Cousin, Left this fight.
- Pigeon: Reserve, Sortie, Guard post, Left this fight.
- Thorn: Thorns, Root, Grow, Seed, Bury, Compost, Pip, Copy from the Compost (unchanged).

**Removed since main:** Slot buff, Medal, Decorated, Order (N), Stiff Upper Lip, Joins the fight, Privates left, Gains left this fight. Order became the hidden "Active" coin.

**Card face:** up to 3 round marks (`glass_screen.gd`, `card_terms.gd`) as before, plus Charge and Supply pips above the stat discs. The golden Grudge reminder is still fixed at "+1" (b08b), and Charge and Supply only show where the text starts with "Charge N:" or "Supply N:".

## actions.md (what animates)

- **Unchanged:** `card_keeper.gd` (move, fade, fly, number pop, land and hop), `card_carry.gd` (+9, small), `recruit_triple_motion.gd`, `recruit_discover.gd`, `game_controller.gd`. Triple forming, Discover, after-fight, card lost, elimination and game over are the same as in the main audit.
- **Fight, new:** pile-on is drawn as a step. The attacker winds up and waits, each piler jabs out (`fight_motion.gd` `_jab`, JAB_IN 4f, HOLD 3f, SETTLE 10f) and holds, then the attacker lunges (`fight_replay.gd` `mark_pile_ons`, `_lunge_after_pile_on`). Summon, reserve and return now carry the arrival's Renown into the same step. The `slot_percent` event is gone, and `renown` is synced on units.
- **Recruit, new:** Charge pips dim when used in a fight and light again (`card_pips.gd`). Active buttons show a red coin when you can't afford them (`recruit_actions.gd` `poor`/`used`). Nothing new animates on the recruit screen.
- Still no ×N aggregation and no speed control. Hold constants and `speed` are the same.

## Spells and the Triple Reward on dev

- **Shop spells:** still the three stand-in spells, because no tribe has a spell (`game_content.gd:74-87`, now `drawable_cards(true)`). They are Sharpen ("Give a friendly unit +2/+2.", `stand_in_units.json:368-382`, art `spell-1`), Seek ("Discover a unit.", `:385-396`, art `spell-2`) and Forage ("Discover two units.", `:399-413`, art `spell-1`). `stand_in_units.json` is the same as on main.
- **Triple Reward:** `unit_library.gd:10-20` (`triple_reward`, "Discover a unit from the tier above yours.", `game_content.gd:26`), drawn with the stand-in spell art `spell-1` (`game_content.gd:21`, `:238`). Every spell art is a crown of thorns under a storm. Seen in shots b06, b12 and b01.
- **No art on dev (plain lattice stand-in panel, `game_content.gd:15-18`):** Mouse: Hayloft Aunt (T2), Bell-ringer, Needle Sister (T3), Grandmother Hob, Thimble Sentinel, Drill-sergeant (T4), Widow Thimble (T5), Old Mother Needle (T6). Pigeon: Home Guard (T3), Quartermaster (T4), Group Captain (T5), Air Marshal (T6). Badger, Locust and Thorn have art for every card.
