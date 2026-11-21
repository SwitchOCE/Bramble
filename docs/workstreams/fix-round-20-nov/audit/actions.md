# Actions and events: what animates now

Branch `plan/fix-round-20-nov` at 13f44dd9. Read-only audit. All paths are relative to the repo root.

## How motion works

The screens don't play events. Each action or fight step hands the screen a whole new view state, and the `CardKeeper` works out the difference between the old state and the new one. So any "animation" is one of a few generic tweens, never something made for that event:

| Generic motion | Where | What it looks like |
|---|---|---|
| Move | `src/screens/card_keeper.gd:18` MOVE_TIME 0.2 s, applied at :389-396 | A card whose key (uid) is in a new place slides there (cubic ease-out). |
| Fade in | `card_keeper.gd:345-349` FADE_TIME 0.18 s | A key that wasn't there before fades in where it stands. A new card with the same card id as one that just left starts from that card's pose instead (`_take_leaver` :321). |
| Fade out | `card_keeper.gd:538` | A key that is gone fades out in 0.18 s. |
| Fly out | `card_keeper.gd:554` FLY_TIME 0.3 s | A leaving card shrinks to 0.35 and fades while it flies to `leave_to` (only an eater unit or a heap plate, see `view_adapter.gd:137-155`). |
| Number pop | `card_keeper.gd:525` POP_SCALE 1.5, POP_TIME 0.24 s | When the card is rebuilt with different Attack or Health, the changed number starts at 1.5x and settles. Nothing says who caused it. |
| Land and hop | `card_keeper.gd:401`, `:455`, constants :35-53 | A card let go by the pointer drops in 4-6 frames, or flies 8-15 frames when it was let go somewhere else, then hops for 12 frames. Its numbers count up over 0.2 s (`_roll` :476). |
| Carry | `src/screens/card_carry.gd:3-35` | The picked-up card lifts 1.2x in 9 frames, then leans, pitches and springs with the pointer (Galaxy feel). |
| Counter plate pop | `src/screens/glass_counters.gd:141-148` PLATE_POP 1.25, 0.35 s | A counter or heap plate (Compost, Tide, Medals...) whose number changed scales back down from 1.25x. |

Gold number, Health badges, tier, turn, buttons, leaderboard, message text and slot-bonus pills have no tween. They redraw at once.

## 1. Menus and game frame

| Action or event | Animates? | How (file:line) |
|---|---|---|
| Boot to start screen | No | `src/main/main.gd:63-75`, `_swap` :178 frees the old screen and adds the new one at once |
| Toggle tribe in/out, "Only" | No | `src/game/ui/start_screen.gd:51`, `:72`. Rebuilds with an amber ring or a strike-through (:141, :158) |
| Play (start a game) | No | `main.gd:77` swaps to GameController. `game_controller.gd:60-81` builds the recruit screen |
| Card browser (Cards button) | No | `src/screens/browser/card_browser.gd`: static grid, filters, golden toggle (:91), search. Hover tip fades out (`glass_tips.gd:294`) |
| Pause (Esc or cog) / Resume / Quit to start / drop setting | No | `src/game/ui/pause_panel.gd`, `settings_cog.gd` (hover tint only, :108), `main.gd:139-176` |
| Hover a card (any screen) | Partly | Enlarged copy plus words pane, built at once. The tip fades out (`glass_tips.gd:294-296`). A hand card stands up (`recruit_tips.gd:138`). "Golden in place" preview for a hand card or Discover option (`recruit_tips.gd:36`) |
| Leaderboard (Tab or own portrait) | No | `glass_screen.gd:121`, `:634`. Drawn at once. An eliminated player gets a dimmed "out" portrait and no Health (`glass_screen.gd:520-540`) |
| Compost viewer (click the plate) | No | `src/screens/compost/compost_panel.gd`: static spread overlay. It works mid-fight too |
| Game over: result screen | No | `main.gd:89`, `src/game/ui/result_screen.gd:46`: places and Health, Play again, Quit. Instant swap |

## 2. Recruit phase (player actions)

| Action or event | Animates? | How (file:line) |
|---|---|---|
| Turn starts (new shop, income) | Partly | `game_controller.gd:96-102`. Shop cards with new keys fade in and old ones fade out. Gold and turn number redraw at once. No start-of-turn event is passed (`_show_recruit(_notice)` with `events=[]`, :101) |
| Start-of-turn effects (Horde Runner's Hopper to hand, start_turn_gold, others) | Generic only | A new hand card fades in. Stat changes are number pops. No trigger glow, no source shown |
| End-of-fight results on the recruit board (Grudge buffs, Medals, Relic Seeker gold, Old Campaigner, Adjutant) | Generic only | These run in `game_session.gd:264-270` (`_after_fight`), and their events are stored in `fight["after"]`, which no screen reads. When recruit opens next turn, changed numbers just pop (the keeper compares with the pre-fight state), mixed in with start-of-turn changes. Medal counters change on the pills at once. Gold from these is not in the notice (next row) |
| Notice "+N gold from the last fight" | Static text | `game_controller.gd:111-116`. It counts only fight-log `gold` events (`view_adapter.gd:197-204`, e.g. Shrew Cutpurse). Relic Seeker's after-fight gold (`relic.gd:35` gain_gold through RecruitContext) is not counted. Drawn on the transom (`glass_screen.gd` `_build_message`) |
| Press and drag a card | Yes | `recruit_input.gd:259-281`, CardCarry. Board slots it can go to are lit with an amber rim (`recruit_board.gd:122`). A carried spell lights its targets (:276-281) |
| Buy (drag shop to hand or empty slot) | Yes | `recruit_input.gd:333-336`, `:362-381`. The card lands and hops into the hand (the hand key takes the shop card's pose through `_take_leaver`). Bought onto an empty slot, it is played straight there. Gold redraws at once. The hand count waits for the card's flight (`recruit_counts.gd:104-134`). Shop tag hides while carried |
| Sell (drag to shop) | Yes | Sell value caption while carried (`recruit_shop.gd:182`). On drop: fades out, or flies to the eater (Gorger, Glutton) or the heap plate (a Seed into the Compost) (`card_keeper.gd:554`, `recruit_screen.gd:324-347`). Gold and counters wait until it arrives, then the plate pops (`recruit_counts.gd:32-65`) |
| Reorder board (drag board to slot) | Yes | `recruit_input.gd:349-350`. Lands where dropped. Other units move 0.2 s. The slot-bonus pill stays with the slot (`recruit_board.gd:99`) |
| Board unit back to hand | Yes | `recruit_input.gd:353-354`: lands or hops into the fan |
| Play unit from hand to slot | Yes | `recruit_input.gd:383-395`: lands in the slot. Its battlecry buffs pop the target's numbers. A token it summons fades in. Recruit triggers have no glow: the recruit screen reads `trigger` only to find an eater (`view_adapter.gd:147-150`) |
| Play needing a target (unit, slot, shop) | Partly | `_start_aim` `recruit_input.gd:416`: the card is held over the slot (or lifted 70 px for a spell, :22, :408), targets get amber rims (`recruit_board.gd:142`), message "Choose a target" (`recruit_screen.gd:25`, :297). The result is generic |
| Recruit choice ("recruit_target", e.g. Master-at-Arms) | Partly | `recruit_input.gd:64-70`: same aiming as above, hand units can be targets too |
| Cast spell | Partly | `recruit_input.gd:398-413`: aim or cast. The spell card fades out. Effect is generic |
| Order / ability button (Lance Corporal, Grenadier Guard) | Partly | Ability buttons on board cards (`recruit_buttons.gd:67-110`), dimmed when unusable. Click, then target aim, then the result: slot pill redraws, numbers pop. "Worked" mark on the card (`recruit_screen.gd:406-412`) |
| Refresh | Partly | `recruit_input.gd:474`. Shop keys hold the card id (`glass_screen.gd:253-256`): changed places fade out and new ones fade in, 0.18 s. A place that rolled the same id doesn't change |
| Freeze / unfreeze | No | Frost overlay on shop cards is redrawn at once (`recruit_screen.gd:395-404`, `glass_parts.gd` add_frost) |
| Upgrade tier | No | Button and gold redraw at once. Price-drop readout "−N" (`recruit_screen.gd:305-321`) |
| Duplicate and triple hint in shop | Yes (loop) | `glass_duplicate_glow.gd` rim light with a slow "triple breath", phase driven each frame (`recruit_screen.gd:109-115`, :447-454). Triple foil shader (`glass_triple_foil.gd`) |
| Triple forming | Yes (choreographed) | `recruit_triple_motion.gd:9-18` beats lift 14, gather 22, charge 14, flash 8, reveal 20, land 20, reward 27, tail 10 frames (2.25 s), amber rays, halo, flash. Pace "brisk" or "ceremonial" (:19). Several triples are spaced 430 px (:29). A press finishes it (:308) |
| Triple Reward card to hand | Yes | `recruit_triple_motion.gd:411-428`: comes out below the reveal, then `CardKeeper.arrive_from` (`card_keeper.gd:259`) flight and hop |
| Discover opens | No | `recruit_discover.gd:28-89`: veil, prompt "Discover a unit", options at 1.4x, "N more to pick". All built at once |
| Discover pick | Partly | `recruit_input.gd:460-461`. The veil goes at once. The picked card fades into the hand (the options aren't kept cards), unless it completes a triple, in which case triple motion captures the option's pose (`recruit_triple_motion.gd:3-5`) |
| Refused action | Static text | `game_controller.gd:93` reason drawn as the transom message |
| Card lost (hand full) | No | `recruit.gd:604` logs `card_lost`. No screen reads it |
| End turn (click next-opponent portrait) | No | `recruit_buttons.gd:26`, `game_controller.gd:90-91`, `:109-130`. Instant swap to the fight screen (`game_controller.gd:262-266`) |

## 3. Fight phase

How a fight plays: `FightReplay.build` turns the core's log into steps (`fight_replay.gd:73-81`). `FightScreen._process` shows each step for its hold at `speed` 1 (`fight_screen.gd:125-148`). No code sets `speed` (it is `@export` 1.0, `fight_screen.gd:44`). Skip (Space, Enter or click after 0.4 s) jumps to the result (`game_controller.gd:245-252`, `fight_screen.gd:113`).

Holds (`fight_replay.gd:28-36`): START 0.7, HOME 0.14, LUNGE 0.22, SPLASH 0.55, TRIGGER 0.3, DEATH 0.3, SUMMON 0.35, CHANGE 0.3, END 1.5 s.

| Event | Animates? | How (file:line) |
|---|---|---|
| Fight start | No transition | Instant screen swap. `combat_start` places both boards whole and holds 0.7 s (`fight_replay.gd:130-142`). The first state doesn't fade in (keeper cleared, `fight_screen.gd:100`). Outnumbered count is stored and shown only in the hover ("Outnumbered by N.", `fight_screen.gd:457-466`) |
| Trigger (any mechanic: Fury, Overrun, Pile on, Seed, deathrattles, start-of-fight effects, Medal earn...) | Yes | `fight_replay.gd:143-148`: the unit lifts 14 px in 0.1 s (`fight_screen.gd:234-236`) and glows with the lunge style (`fight_screen.gd:323-329`), 0.3 s step. Trigger steps are never merged (`fight_replay.gd:617`). A `trigger_side` with no unit (standing mechanic) is dropped (:144-146) |
| Attack | Yes | Wind-up of 4 frames (back 12 px, lean 6 degrees, 1.04x), then travel to contact at 0.62 card-heights overlap (`fight_motion.gd:73-86`, constants :7-14). 0.22 s hold. Then home in 11 frames on impact (`fight_motion.gd:97-109`). Two attacks in a row get a 0.14 s "home" step between them (`fight_replay.gd:150-152`) |
| Out-of-turn attacks (Hedge Lancer, Tourney Champion, Herald, Wing Commander, Oakfeller extra) | Yes | Same as attack. A `trigger` step comes first |
| Damage | Yes | `fight_replay.gd:160-172`: an eight-pointed red burst with "-N" on each damaged unit (`fight_screen.gd:336-403`). It pops in 3 frames, settles in 5, reads 0.29 s, rises 16 px and fades (`fight_motion.gd:138-163`). The recipient recoils 16 px and 4 degrees with a hit light (`fight_motion.gd:89-109`). All damage of one moment shares one splash step (0.55 s). Health below max is drawn red |
| Destroy (Venomous-like) | Yes | Burst with no number (`fight_replay.gd:166`, `fight_screen.gd:395`) |
| Prevented (Divine Shield, "takes no damage") | Yes | Burst with "0", blue block light, recoil at 30% (`fight_motion.gd:20-22`, :93-96) |
| Divine Shield / status lost | Generic | The `keyword` or `status` event removes or adds the pill at once (`fight_replay.gd:188-190`, :321-336). A spent Root or Molt pill dims to alpha 0.4 (`keyword_style.gd` SPENT_ALPHA) |
| Pile on | Yes | Pile-on hit damage carries `source_uid`, so piling units "join": they move 60% of the attacker's lunge and glow (`fight_replay.gd:353-365`, `fight_screen.gd:231-233`, :281-285). Their bursts share the splash step |
| Hit (Ballista, Catapult, Engines, Lieutenant) | Partly | The `hit` event goes to the default branch (`fight_replay.gd:218-223`) and makes no visible step. The trigger glow on the hitter, then a burst on the target. No projectile or line from hitter to target |
| Instead of attacking (Spoon Catapult) | No | `instead_of_attack` goes to the default branch: no visible step of its own. Only its trigger and hit bursts show |
| Cleave, Overrun, Thorns | Generic | Extra damage events land in the same splash step: bursts on the extra targets (Thorns: on the attacker, drawn at its lunge pose, `fight_screen.gd:347-353`). Overrun shows a trigger step first. Nothing shows the damage carrying over |
| Guard (taunt), Sortie, Stealth | No | Only targeting changes. Nothing shows why that target was chosen |
| Attacks twice | Generic | Two attack lunges with a 0.14 s home between |
| Death | Yes | `fight_motion.gd:112-133`: in 15 frames it drops 48 px, turns 16 degrees, shrinks to 0.72x and fades. The deaths of one pass share one step (`fight_replay.gd:173-180`, merged at :617). The slot stays empty |
| Death effects (deathrattles: Hoppers, damage, Tide, Seed, Old Stump...) | Generic, no source | The core logs `death` before running death effects (`fight_deaths.gd:46-58`). The replay drops the dead uid from `_where` (`fight_replay.gd:179`), so the dead unit's own `trigger` can't be found and is skipped (`:144-146`). Nothing marks which unit's death effect fired. Results show as summons, bursts and plate pops. A friend's "after a friendly unit dies" trigger (Gleaner, Padre, Old Brock) does glow |
| Summon / Reserve steps in | Yes | `fight_replay.gd:181-184`: fades in (0.18 s) in its slot, 0.35 s step. Changes right after a summon merge into its step (:620-624) |
| Return (Molt, Root, Reborn) | Yes | `fight_replay.gd:185-187`, :306-318: fades in again under the new uid, Health from the event. The Molt +2/+2 and dimmed pill merge into the same step |
| Summon waiting / failed | No | `summon_waiting`, `summon_failed` go to the default branch: nothing shown |
| Buff, stats (auras), effect (Fury given), counter (Medals), uses | Generic | 0.3 s change step, merged with any changes next to it. Numbers rebuild and pop (`card_keeper.gd:525`). Pills or counters update. The hover lists "<Source> +a/+h this fight." (`fight_replay.gd:257-279`) |
| Fury rage | Generic | Trigger glow, then an Attack number pop |
| Slot buff / Edgewright percent | No | `slot` and `slot_percent` redraw the slot pill at once (`fight_replay.gd:202-207`) |
| Your counters and heaps (Seed to Compost, Tide) | Yes (plate) | `player_counter`, `heap_add`, `heap_remove`: your plates only (`fight_replay.gd:470-509`). The plate pops (`glass_counters.gd:141`). The opponent's aren't shown |
| Heap use (Root paying Compost) | No | `heap_use` goes to the default branch. The plate isn't updated by it |
| Gold in fight (Shrew Cutpurse) | No | `gold` (`fight_side.gd:421`) goes to the default branch: nothing in the fight. It appears only as next turn's notice |
| Pass (a side has no attacker) | No | Default branch, usually removed as a duplicate step |
| Start-of-fight effects | Generic | Each is a trigger step (glow and lift) followed by its result (attack lunge, burst, summon fade-in, number pop). No "start of fight" banner or phase marker |
| End of fight (`combat_end`) | Static | `fight_replay.gd:214-217`: "Victory", "Defeat" or "Draw" in 72 px text on the transom (`fight_screen.gd:469-484`). 1.5 s hold. No motion |
| Damage to hero | Partly | A burst with the damage on the loser's portrait (`fight_screen.gd:485-494`). The Health badge and leaderboard drop in the same step with no tween (`fight_replay.gd:513-531`). The burst gets the pop and fade only if it is an impact start: it is built in `_build_result`, not `_build_moment`, so it is static |
| After-fight effects (Grudge, Relic Seeker, Campaigner, Adjutant medals) | No | They aren't in the fight log (`game_session.gd:264-270`). `fight["after"]` isn't sent to any screen. See section 2 |
| After the result | No | `game_controller.gd:133-153`: the leaderboard opens at once with everyone's new Health and your counters. It stays 2.5 s or until a click |
| Elimination | No | `eliminated` (`game_session.gd:402`) isn't read by any screen. The out player gets a dimmed portrait on the leaderboard. If you are out: hint "The others play on" while bots finish, leaderboard redrawn each frame (`game_controller.gd:156-178`, :206-212). Then the result screen swaps in |
| Game over | No | `game_end` isn't read. `game_controller.gd:181-186`, then `main.gd:89` |

## 4. Fight log event types

Emitted by the combat core (`src/core/combat/*.gd`):

combat_start, pass, instead_of_attack, attack, hit, trigger, damage, prevented, destroy, buff, uses, status, summon, reserve, summon_waiting, summon_failed, death, return, stats, slot, slot_percent, keyword, effect, counter, player_counter, heap_add, heap_use, heap_remove, gold, combat_end.

Sources: `combat.gd:128-739`, `:757` (summon/reserve), `fight_deaths.gd:49`, `:154`, `:197`, `fight_auras.gd:42`, `fight_side.gd:96-421`.

| Handled with its own step in `fight_replay.gd` | Default branch (numbers sync only; often no visible step) |
|---|---|
| combat_start, trigger, attack, damage, destroy, prevented, death, summon, reserve, return, keyword, status, counter, uses, slot, slot_percent, effect, player_counter, heap_add, heap_remove, combat_end | buff, stats (numbers pop: intended), hit, instead_of_attack, pass, summon_waiting, summon_failed, heap_use, gold |

Recruit-side event types (`recruit.gd`, `recruit_context.gd`, `game_session.gd`) that the screens read: only `triple`, `buy`, `pick`, `summon`, `gain` (triple arrivals, `view_adapter.gd:92-131`) and `sell`, `trigger` (eat), `heap_add` (leaving, `view_adapter.gd:137-155`). Not read: turn_start, turn_end, buff, gold, counter, player_counter, turn_counter, slot, keyword, effect, give_card, shop_take, cast, ability, refresh, freeze, upgrade, discover_queued, discover, card_lost, round_start, fight, eliminated, game_end.

## 5. Grouping and aggregation compared with the owner note (2026-11-18b)

What the code groups (`fight_replay.gd:594-628`):

- Consecutive steps of the same kind merge into one: all damage of one moment is a single splash step, the deaths of one pass are one step, and adjacent changes are one step (`:617`).
- A change right after a summon merges into the summon step (`:620-624`).
- A step that looks the same as the one before is dropped (`:625-627`).
- Pile-on joiners move together with the attacker (`:353-365`).
- Triggers are never merged: every trigger is its own 0.3 s step (`:617`).

What the note asks for and the code lacks:

- No aggregated animation for an effect firing many times. There is no ×N or combo counter, no rising hit-marker numbers, no speed-up when many steps are queued. Holds are fixed constants (`fight_replay.gd:28-36`), and `speed` is never changed in play.
- So a chain of N triggers costs N × 0.3 s plus its results. This is the long-queue problem the owner described (Pile on with four neighbours, Dirge-doubled death effects, Mother of Thousands summons, Sexton pays).
- The `fight_screen.gd:23-25` header still says "Replay grouping and holds are unchanged", the old rule. `fight_motion.gd:3-4` cites the note, but only the motion numbers changed.

## 6. Biggest gaps (no animation of their own)

1. After-fight effects (Grudge, Relic Seeker gold, Campaigner and Adjutant Medals) are never shown. They become silent number pops at the next recruit turn, and Relic Seeker's gold is missing from the "+N gold" notice.
2. Nothing in the fight reads `hit` or `instead_of_attack`: there is no line or projectile from hitter to target (Ballista, Catapult, Engines, Lieutenant).
3. A dead unit's own death effect has no glow: its trigger is dropped because `death` is logged first. Gold earned in a fight, `heap_use` (Root paying Compost), `summon_failed` and `summon_waiting` show nothing.
4. Nothing shows a keyword's reason or effect: Guard, Sortie, Stealth targeting, Cleave or Overrun carry-over, Thorns.
5. No transition into or out of a fight, no start-of-fight or end-of-fight phase marker, and a static result banner.
6. Recruit-phase triggers (battlecries, end-of-turn, start-of-turn effects) get no glow, only number pops and fade-ins. Freeze, upgrade and gold changes are instant.
7. Elimination and game over have no moment of their own.
8. No grouping or aggregation as the owner note asks: fixed holds, one step per trigger.
