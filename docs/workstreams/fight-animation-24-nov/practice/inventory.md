# Animation inventory (24 Nov 2026)

Every moving thing in the game, and every event that has no motion at all, checked against the code as it is now. Step 1 of `../PLAN-animation-practice.md`.

**Built from three earlier lists**, merged into one table and re-checked against the code:
- `docs/design/mockups/fix-round-20-nov/anim-recruit/NOTES.md`: 47 actions outside the fight (cited as **R1** to **R47**).
- `docs/design/mockups/fix-round-20-nov/anim-fight/NOTES.md`: 34 fight rows (cited by their ids, **F:enter** to **F:skip**).
- `../research/our-events.md`: the fight log's 29 event types (cited as **E:type**).

The owner accepted both 20 Nov proposals on 21 Nov ("I accept all changes", fix-round PLAN decision 13), to be built in batches. Only the recruit batch has been built (PR 250, merged 22 Nov). The fight batch was never started.

**Code checked:** this branch at `8a3b14db`. Its `src/` and `tests/` are dev at `ec669629`, which includes PR 250. This branch has changed no game code. The pass-2 rotation, depth and strike-speed treatments are on the clip branch, not here, so they are not in this table. Times are at fight speed 1. Frames are at 60 fps (f). "bez OUT/IN/INOUT" are `GlassMotion`'s CSS curves (`src/glass/glass_motion.gd:17`). Godot's `TRANS_x` plus an ease are Tween curves. A `tween_method` with neither is linear.

**Status:** BUILT means built as proposed. PART means part of the proposal is built. OLD means the motion from before 20 Nov is still in use, mostly stand-ins. **GAP** means the event has no animation at all (a snap, words only, or nothing). NONE means it can't happen today.

**Counts:** 82 rows: 17 BUILT, 4 PART, 19 OLD, **37 GAP**, 1 NONE, 3 idle (H1 to H3) and 1 static. Counting the bundled rows (F10 holds six events, F15 four), the gaps come to **45 events**. Four gap rows are not in the three sources (A9, E3, G3, G5, marked *new*).

## Table

### A. Start, menus and the game frame

| # | Event | Lists | Code | What moves today (property, time, easing) | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| A1 | Game opens, start screen | R1 | `src/main/main.gd:229` `_swap` | nothing; instant swap | – | – | – | – | – | **GAP** |
| A2 | Toggle a tribe / Only | R2 | `src/game/ui/start_screen.gd:118` | off pill alpha 0.4, instant | – | – | – | – | – | **GAP** |
| A3 | Play: into the first recruit turn | R3 | `main.gd:133`; `game_controller.gd:99` `_next_round` | instant swap; the first shop is the keeper's first commit, so it shows at once with no fade | – | – | – | – | – | **GAP** |
| A4 | Card browser open/close | R4 | `src/screens/browser/card_browser.gd` | instant | – | – | – | – | – | **GAP** |
| A5 | Pause and resume | R5 | `src/game/ui/pause_panel.gd:76` | instant | – | `fight.hit.medium` on a volume change | sound 21 Nov | – | – | **GAP** |
| A6 | Hover a card | R6 | `src/screens/glass_tips.gd:309` `set_hot`, `:287` `fade`; `src/screens/recruit/recruit_tips.gd:152` `stand` | the detail and the card's glow appear at once; a hand card **snaps** upright, its foot 8 px above the bottom; the detail fades out over 6 f (0.1 s, linear) only when a press becomes a drag, otherwise it goes at once | no hover while cards move (`recruit_motion.gd:88`) | – | hover waits only for moving cards (PR 250) | `keywords-hover` | detail on hover only (9 and 22 Nov) | PART |
| A7 | Leaderboard (Tab or portrait) | R7 | `src/screens/glass_screen.gd:121` | instant | – | – | – | – | – | **GAP** |
| A8 | Compost open/close; plate hover | R8 | `glass_screen.gd:593`; `src/screens/glass_counters.gd:73` | instant; plate hover brightens at once | – | – | – | – | – | **GAP** |
| A9 | Past boards *new* | – | `src/game/game_controller.gd:204` | instant, settled | – | – | – | – | – | **GAP** |

### B. Start of your turn

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| B1 | Turn number and income | R9 | `src/screens/recruit/recruit_counts.gd:77` | the numbers change at once | – | – | – | – | income coins go in the next batch (decision 16, 22 Nov) | **GAP** |
| B2 | A new shop | R10 | `src/screens/card_keeper.gd:351` (in), `:551` (out) | old cards fade out and new ones fade in, 0.18 s (10.8 f), linear, in place | – | – | – | – | next batch (decision 16) | OLD |
| B3 | A frozen shop thaws | R11 | `src/screens/glass_parts.gd:431` `add_frost` | the ice is gone at once | – | – | – | – | – | **GAP** |
| B4 | Grudge pays | R12 | `src/screens/recruit/recruit_turn_start.gd:155`; `_fire` `:123` | source: `.card.lunge` glow, lifts 14 px and warms; light 0.10 s in, 0.15 s out, linear; held 0.67 s. Grudge mark pops 1→1.6→1, 0.38 s (23 f), bez OUT. "+a/+h" pill keyframes 0.43 s (26 f), bez OUT, from the mark to mid-card, then drops 62 px and fades. Stats pop 1.6×→1, 0.26 s (16 f), cubic out, at +0.52 s. All units 0.05 s apart, one beat | none: a press finishes it | – | built 21 Nov (`29380847`) | `recruit-turn-start` | – | BUILT |
| B5 | Relic Seeker's gold | R13 | `recruit_turn_start.gd:189` | source fires 0.26 s. A coin with "+N" arcs 140 px to the gold coin in 0.42 s (25 f), "arrive" curve t²(1.6−0.6t); fade in 0.06 s, out 0.14 s. Ring 0.38 s, bez OUT. Gold counts up 0.26 s, cubic out. Gold button pops 1.07, 0.28 s | press finishes | – | built 21 Nov | `recruit-turn-start` | – | BUILT |
| B6 | Old Campaigner's Renown | R14 | `recruit_turn_start.gd:223` | star: four **linear** moves (0.14, 0.12, 0.14, 0.05 s), spins −30→0°; the slot's banner pops 1.7→1 in 0.32 s; ring; stats pop at +0.52 s | press finishes | – | star is the prototype's gold disc (22 Nov) | `recruit-turn-start` | – | BUILT |
| B7 | Horde Runner's Hopper | R15 | removed in `377ca27d` | the Hopper fades into the hand, 0.18 s | – | – | playback removed 21 Nov | – | – | **GAP** |
| B8 | Gold from the last fight (Cutpurse) | R16 | `game_controller.gd:126` `_notice` | static words on the transom | – | – | words kept (`b1ee206d`) | – | – | **GAP** |
| B9 | Start-of-turn queue | R17 | `recruit_turn_start.gd:43-58` | beats 0.42 s apart, each gap ×0.86, down to 0.26 s | press finishes | – | built 21 Nov | `recruit-turn-start` | grouping note (18 Nov) | BUILT |

### C. The shop

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| C1 | Buy into the hand (drag or click) | R18 | `card_keeper.gd:404` `_land`, `:458` `_fly`, `:433` hop; gold `src/screens/recruit/recruit_motion.gd:389` | carry (D1). Let go: a **flight** of 8 to 15 f (0.13 to 0.25 s), eased in (1−cos), leaning up to 16° (sin). Then a **hop** of 12 f (0.2 s): sine, rises 6.4 % of the card's height, swells to 1.06. Gold counts down 0.26 s (15.6 f); the gold button dips to 0.94 over 0.28 s, bez OUT. The tag hides at the press and returns on a drag. "Hand n/7" changes when the card lands | – | – | PR 250: gold count and dip; tag travels (owner, 22 Nov) | `drag-basics`, `double_click_buy` | carry calmed 17 Nov; tag 22 Nov | BUILT |
| C2 | Buy onto the board | R19 | `card_keeper.gd:421` drop; `recruit_board.gd:310` lit fade | empty slots light; the **drop** takes 4 to 6 f, cubic out (position, turn, scale 1.2→1), then the 12 f hop; lit rims fade out 0.15 s (9 f), bez IN; gold counts down | – | – | new in PR 250 (`0c792dbb`, `f465c707`) | `anim-buy-to-board`, `drag-basics` | – | BUILT |
| C3 | Sell (plain) | R20 | `card_keeper.gd:541` `_fade_out`; `recruit_counts.gd:77` | the card fades 0.18 s, linear, where it is let go; gold **jumps up**; the sell pane shows "Sell for N" while carried | – | – | – | `shop-sell`, `drag-basics`, `zone-moves` | – | **GAP** (coin and count-up not built) |
| C4 | Sell to an eater (Gorger) | R21 | `card_keeper.gd:557` `_fly_out` | flies to the eater 0.3 s (18 f), cubic out, shrinking to 0.35, fading over its last 30 %; the eater's numbers pop (K1) | gold waits for arrival | – | – | `zone-moves` | – | OLD (no light on the eater) |
| C5 | Sell a Seed to the Compost | R22 | `_fly_out`; plate pop `glass_counters.gd:141` | flies to the plate 0.3 s; the plate pops 1.25→1 over 0.35 s (21 f), `TRANS_BACK` with Godot's default ease (in-out); gold jumps | gold and plate wait for arrival | – | – | – | – | OLD (no coin) |
| C6 | Bury a shop unit (Hedge-layer) | R23 | `_fly_out` | flies to the plate 0.3 s; gold changes at once | – | – | – | – | – | OLD |
| C7 | Refresh | R24 | `recruit_motion.gd:174` | the button dips 0.93 and brightens 1.25 over 0.2 s; the "left at this price" counter flashes 1.15× gold, 0.3 s. Old cards sink 24 px to 0.94 and fade, 0.15 s (9 f), bez IN, 25 ms apart. New cards drop from 40 px above at 1.04, overshoot 4 px at 0.09 s, settle at 0.22 s (13 f), bez OUT, 50 ms apart, from 0.18 s. Each tag swings −28°→10°→0° over 0.26 s, 0.14 s after its card. About 0.65 s for six cards, 0.8 s with the tags. Gold counts down | press finishes | – | built in PR 250 | `anim-refresh` | – | BUILT |
| C8 | Freeze / unfreeze | R25 | `glass_parts.gd:431` | ice on or off at once | – | – | – | – | – | **GAP** |
| C9 | Tier up | R26 | `recruit_motion.gd:288` | the button flashes to 1.7 brightness at 1.06×, 0.42 s (25 f), bez OUT. "n → n+1" flips (scale.y cos) in 0.11 s (IN) and 0.18 s (OUT). A warm band sweeps across the shop, 0.48 s (29 f), bez INOUT, from 0.08 s. Gold counts down | press finishes | – | built in PR 250 | `anim-tier-up` | – | BUILT |
| C10 | Not enough gold | R27 | `card_keeper.gd:458` (the flight home) | the card flies home (as C1); the reason is words on the transom, at once | – | – | – | – | – | PART (no gold shake or red flash) |
| C11 | Duplicate and triple marks change | R28 | `src/glass/glass_duplicate_glow.gd:42` `_set_mark` | the rim **snaps** on and off at each redraw (the breath is H1) | – | – | `84c51f25` fix 21 Nov | `dupes-shop`, `dupes-candidates`, `shop-glow`, `recruit-marks` | – | **GAP** (no flare or fade) |
| C12 | Triple forms, and its reward | R29 | `src/screens/recruit/recruit_triple_motion.gd:9` (beats), `:353` `_pose`, `:442` `_draw_run` | its own `_process` clock, 135 f (2.25 s); the "ceremonial" pace is ×1.2. Lift 14 f: copies rise 28 px. Gather 22 f (t³): to staging, 0.8×. Charge 14 f (t²): into the hub, scale to 0.16, cream; an amber ring closes. Flash 8 f: cream hex flare 0.45→1.25 and 18 rays. Reveal 20 f: golden card at 1.22× with a sine swell. Land 20 f: smoothstep with a 90 px arc. Reward 27 f: it arrives through the keeper's flight and hop from below the hub. Tail 10 f: amber ring | none: a press finishes this layer | – | full-hand reward goes to the waiting pile (`a803ed79`) | `triple-brisk`, `-ceremonial`, `-discover`, `-full-hand`, `-interrupt`, `-reward` | **"Triples are great … I really like that one" (24 Nov)** | BUILT |
| C13 | Triple reward with a full hand | R30 | `recruit_triple_motion.gd:417`; `card_keeper.gd:262` | the reward flies to the waiting stack instead of the hand; its count pops (D9) | press finishes | – | built 21 Nov | `triple-full-hand` | – | BUILT |

### D. Hand and board

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| D1 | Pick up and carry | R31 | `src/screens/card_carry.gd:22` and `:81` | lift 9 f, cubic out: 1.2× and rises 14 % of the card's height. Leans 0.0075°/(px/s), up to 16°, on a spring (ω 30, damping 0.5). Pitches (draws shorter) up to 11 %. Narrows up to 25 % at 2500 px/s. Held glow is `HELD_SHADOWS` and 1.06 brightness, set at once. Valid slots light at once | – | – | spring sub-steps (`3e546e02`, 19 Nov) | `drag-basics`, `drag-middle` | 17 Nov: "a bit too bouncy … tilts a bit too much" (calmed) | BUILT |
| D2 | Play a unit from the hand | R32 | `card_keeper.gd:421`; `:395` (the hand closes) | drop 4 to 6 f, then the 12 f hop; the rest of the hand slides 0.2 s (12 f), cubic out; lit rims fade 0.15 s | – | – | lit fade (PR 250) | `drag-basics` | – | BUILT |
| D3 | A Recruit effect (Harvest Piper) | R33 | `card_keeper.gd:528` `_pop` | the targets' numbers pop 1.5→1, 0.24 s (14 f), `TRANS_BACK` out; no light, nothing flies | – | – | – | – | – | **GAP** |
| D4 | Choose a target (Master-at-Arms) | R34 | `recruit_board.gd:272` `light` | still lit rims; then numbers pop (K1) | – | – | – | – | – | **GAP** |
| D5 | Cast a spell on a unit | R35 | `card_keeper.gd:541`; `:528` | the spell fades 0.18 s; the target's numbers pop | – | – | – | – | – | **GAP** |
| D6 | Use an Active (Lance Corporal) | R36 | `recruit_motion.gd:389` | gold counts down and the button dips (C1); the slot pills redraw at once; numbers pop | – | – | gold count (PR 250) | – | – | **GAP** (beyond the gold) |
| D7 | Rearrange the board | R37 | `card_keeper.gd:421`; `:393` | the moved unit drops and hops; the other slides 0.2 s, cubic out | – | – | – | `drag-basics`, `drag-middle` | – | BUILT (keep) |
| D8 | Board unit back to the hand | R38 | `_land` | flight and hop (C1) | – | – | – | `zone-moves` | – | BUILT (keep) |
| D9 | Swap a hand card with a board unit | R39 | `recruit_board.gd:205` `_lift_swap`; `recruit_motion.gd:412` | over the slot, the unit there lifts 12 px to 0.94 and tints blue, 0.14 s (8 f), bez OUT; a pale copy waits in the hand gap; moving off **snaps** it back. Let go: it arcs 120 px into the hand, 0.28 s (17 f), "arrive" curve, leaning −6°, clearing its tint in 0.2 s, then hops 0.2 s (`GlassMotion.hop`). The new card drops and hops (D2) | press finishes | – | built in PR 250 | `anim-swap`, `drag-basics` | blue swap look approved (recruit/NOTES 3) | BUILT |
| D10 | A card arrives with a full hand: it waits | R40 | `card_keeper.gd:404`; `recruit_motion.gd:599` | it flies to the stack with the keeper's flight and hop; the stack's count pops in from 1.8×, 0.26 s, bez OUT, as it lands | – | – | built 21 Nov (`a803ed79`) | `triple-full-hand` | – | BUILT |
| D11 | Room frees: the waiting card slides in | R41 | `recruit_motion.gd:479` `_join` | leaves the stack 0.12 s after the let-go, arcs 40 px over 0.32 s (19 f), INOUT, greys 0.86→1, hops 0.2 s. The hand closes in 0.2 s and opens in 0.22 s. The count chip shrinks to 0.4 and fades, 0.16 s, bez IN | press finishes | – | built in PR 250 | `anim-waiting-slide` | – | BUILT |
| D12 | Discover opens | R42 | `src/screens/recruit/recruit_discover.gd:28` | the veil and options appear at once | – | – | – | `triple-discover` | – | **GAP** |
| D13 | Discover: pick one | R43 | `card_keeper.gd:351` | the options go at once; the picked card **fades in** at its hand place, 0.18 s | – | – | – | `triple-discover` | – | **GAP** |
| D14 | A number pops (any recruit change) *new* | – | `card_keeper.gd:528` | the changed number 1.5→1, 0.24 s, `TRANS_BACK` out; nothing for gains vs losses, no source | – | – | – | – | 24 Nov: "When Brock gets stats it's very hard to tell what happened" (fight, same pop) | OLD |

### E. End of turn and into the fight

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| E1 | End-of-turn effects | R44 | – | resolved unseen before the fight | – | – | – | – | – | **GAP** |
| E2 | End turn: into the fight | R45, F:enter, E:combat_start | `game_controller.gd:324` `_show_only`; `fight_screen.gd:110` `play` | instant screen swap (`visible`); `play` clears the keeper so both boards appear at once; held 0.7 s, static | 0.7 s (`fight_replay.gd:31`) | – | – | `fight-whole` | – | **GAP** |
| E3 | End turn button press *new* | – | `src/screens/recruit/recruit_buttons.gd` | no press motion (refresh's `_press` is used only by refresh) | – | – | – | – | – | **GAP** |

### F. The fight

Steps hold the screen: each replay step is held for its time, and the fight moves on by hold, never by motion (`fight_screen.gd:137`). Holds: start 0.7, lunge 0.22, home 0.14, splash 0.55, trigger 0.3, death 0.3, summon 0.35, change 0.3, end 1.5 s (`fight_replay.gd:31-39`).

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| F1 | Start-of-fight effects (Lancer, Grow, Wing Commander, Standard-bearer, Ballista, Lieutenant, Colour Ensign, Sky-darkener, Elder Mother) | F:lancer, F:grow, F:wingco, F:buffs, F:lieut | `fight_replay.gd:180` | each is a trigger step (F2) and then its effect's step, unit by unit; nothing grouped | 0.3 s + effect | `fight.trigger` | – | `fight-whole`, `pigeon-reserve` | grouping note (18 Nov) | OLD |
| F2 | Trigger (E:trigger) | E:trigger | `src/screens/fight/fight_screen.gd:39-40`, `:270`; glow `:358` | the unit lifts 14 px in 0.1 s (6 f), cubic out, through the keeper move. Its `.card.lunge` glow and z order are set **at once**. It stays lifted until the next attack, death or pass, then drops back in 0.2 s, cubic out. Never merged: one step per trigger | 0.3 s each | `fight.trigger` at step start | sound 21 Nov | `fight-whole`, `mouse-kin` | – | OLD |
| F3 | Attack: wind-up, travel, contact (E:attack) | F:attack | `src/screens/fight/fight_motion.gd:99` `_attack`; contact `fight_screen.gd:223` | wind-up 4 f, quad out: 12 px back, 6° lean, 1.04×. Travel 8 f, quad **in**: to centres 0.62 card heights apart, rotating to −3°. Contact at f12. The attacker's glow is set at once | 0.22 s lunge, plus 0.14 s home if the last lunge still shows | none (no wind-up or whoosh cue) | – | `fight-whole`, `fight-windup-long` | 24 Nov: "doesn't feel right yet"; wants the card to **rotate to aim**; shallower stop (A or B); liked the speed-up, "the constant, linear stuff … was very bad" | OLD (pass 2 treatments on the clip branch) |
| F4 | Return home | F:attack | `fight_motion.gd:123` | holds contact 2 f, then home 11 f, cubic out; scale and modulate reset | inside the splash hold | – | – | `fight-whole` | – | OLD |
| F5 | Hit: knock-back and light (E:damage) | F:damage | `fight_motion.gd:115` `_hit` | target: modulate `HIT_LIGHT` (1.6, 1.25, 1.1) **at once**; knocked 16 px and 4° in 3 f, **linear** (no trans set); back 11 f, cubic out | 0.55 s splash | `fight.hit.light`/`medium`/`heavy` at step start (3 f after contact) | sound 21 Nov | `fight-whole` | – | OLD |
| F6 | Damage number burst (E:damage) | F:damage | `fight_motion.gd:164` `burst`; `fight_screen.gd:413` `hit_splash` | an eight-point lead and red glass star with "−N", 0.55×→1.18× in 3 f, →1 in 5 f (linear lerps), read 0.29 s, then rises 16 px and fades 0.12 s: 0.54 s (33 f) in all. It follows the recipient's recoil. Health swaps with K1's pop. No red flash on the disc | splash | as F5 | – | `fight-whole` | 24 Nov: hit splat ideas for combos | OLD |
| F7 | Blocked hit / Divine Shield (E:prevented, E:status) | F:lancer | `fight_motion.gd:120`, `:122` | a "0" burst; knock-back at 30 %; a blue `BLOCK_LIGHT`. The shield's `status` is logged before the hit, so the attacker waits at contact for an extra 0.3 s change step; the pill just drops | splash, plus 0.3 s | `fight.hit.blocked` | – | `fight-whole` | – | OLD |
| F8 | Destroy (Venomous, Bitter Toad) (E:destroy) | missed by F | `fight_screen.gd:440` | a burst with no number | splash | `fight.destroy` | – | – | – | OLD |
| F9 | Pile on (E:hit) | F:pileon | `fight_motion.gd:83` `_jab`; `fight_screen.gd:319` | the attacker winds up at home. Each piler jabs 60 % along the lunge in 4 f, quad out, leaning 5°, at 1.04×; holds 3 f; settles its turn and scale in 10 f but stays out until the lunge. All bursts land in one splash. No 70 ms stagger, no ×N | extra lunge step | as F5 | built 19 Nov (before the proposal) | `mouse-kin` | – | PART |
| F10 | Cleave, Overrun, Thorns, Sortie, Guard, Oakfeller attacks again | F:cleave, F:overrun, F:thorns, F:sortie, F:guard, F:again | – | Cleave: the neighbour's burst shares the splash. Overrun: its own trigger and splash after the attacker is home. Thorns: its splash sends the attacker home before the exchange. Sortie: a straight lunge through the front row. Guard: nothing | as their steps | as F5 | – | – | – | **GAP** (×6) |
| F11 | Effect damage (Gleaner, Plague, Lieutenant) | F:strike, F:lieut | `fight_replay.gd:200` | trigger glow, then a burst on the target; no line from the source | 0.3 + 0.55 s | as F5 | – | – | – | **GAP** |
| F12 | Buff, stats, effect (Fury, Old Brock, Sword-heir, Lends, auras) (E:buff, E:stats, E:effect) | F:fury, F:buffs, F:lends | `fight_replay.gd:259`; `card_keeper.gd:528` | the numbers swap with a 1.5× pop, 0.24 s, BACK out; changes in a row merge into one step; the source has already glowed (F2) | 0.3 s change | none | – | `fight-whole`, `mouse-kin` | **24 Nov: "very hard to tell what happened" (Brock); "we need to do buff animations way better … clear and interesting"; not just Battlegrounds** | OLD (pass 2 thread 7) |
| F13 | Keyword, status, uses, counter (E:keyword, E:status, E:uses, E:counter) | F:renown | `fight_replay.gd:232-245`; `src/glass/keyword_mark.gd:51` | a pill appears, goes or dims (alpha 0.4) **at once**; pips change at once | 0.3 s change | none | – | – | – | **GAP** |
| F14 | Player counters and heaps: Tide, Compost (E:player_counter, E:heap_add, E:heap_remove) | F:tide, F:seed, F:root | `glass_counters.gd:78`, `:141` | your plate pops 1.25→1, 0.35 s, BACK in-out, **not divided by fight speed**; the opponent's plates are not shown | 0.3 s change | none | – | – | – | OLD |
| F15 | heap_use, renown, in-fight gold, summon_failed (E:heap_use, E:renown, E:gold, E:summon_failed) | missed by F (except renown) | – | nothing shown, no step | – | – | – | – | – | **GAP** (×4) |
| F16 | Several deaths at once (E:death) | F:deaths | `fight_motion.gd:138` `_fade_out` | a pass falls together: 15 f (0.25 s), quad **in**: drops 48 px along its death direction (an attacker falls back towards home), turns 16°, shrinks to 0.72; alpha fades from f4. The slots stay empty. No overlap with the burst; each pass waits for the 0.55 s splash | 0.3 s death | `fight.death`, at most 2 takes (0 and 55 ms) | sound 21 Nov | `fight-whole` | **24 Nov: "death animations in general might need work"; stagger several deaths "one at a time"** | OLD (pass 2 thread 6) |
| F17 | Death effects: Seed, Hopper, Hand-me-down | F:seed, F:hoppers, F:hmd | as F2, F14, F18 | trigger glow, then a plate pop or a fade-in; nothing flies | as their steps | trigger, summon | – | – | – | **GAP** |
| F18 | Summon, Reserve steps in (E:summon, E:reserve) | F:summon, F:reserve | `card_keeper.gd:351` | **fades in** at its slot, 0.18 s (11 f), linear, no motion. Summons in a row share one step; the Renown pill is on it from the start | 0.35 s summon | `fight.summon` | sound 21 Nov | `pigeon-reserve`, `fight-whole` | – | OLD |
| F19 | Molt or Root returns (E:return) | F:molt, F:root | `fight_replay.gd:349` | the death fall (F16), then the copy fades in (F18); the changes after it merge into its step | 0.35 s | `fight.summon` | – | – | – | OLD |
| F20 | The same trigger 10 times (combo) | F:combo | `fight_replay.gd:668` (triggers never merge) | 10 × (0.3 + 0.55) s, about 8.5 s; no ×N | – | `fight.trigger` per step (`min_gap_s` 0.08) | combo look art direction on this branch (`combo-look/`) | – | 18 Nov note: ×N, rising pace; 24 Nov: cumulative damage and hit splats | **GAP** (pass 2 thread 3) |
| F21 | Queue speed-up (more than 4 steps waiting) | F (owner choice) | – | none | – | – | – | – | 18 Nov note: Battlegrounds-style | **GAP** |
| F22 | Pass (E:pass) | – | `fight_replay.gd:161` | usually no step; 0.3 s if a lunge still shows | – | – | – | – | – | OLD |
| F23 | instead_of_attack, a fight `counter` | E | – | no card uses them | – | – | – | – | – | NONE (×2) |
| F24 | Skip | F:skip | `fight_screen.gd:125` `skip`; `game_controller.gd:314`; `src/screens/fight/fight_skip_button.gd:60` | jumps to the result and settles everything; the button brightens 1.18 at once on hover; no 6× fast-forward | first 0.4 s ignored | – | button 21 Nov (Space only) | – | 21 Nov: "Space only" | PART |

### G. After the fight

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| G1 | The result (E:combat_end) | F:result, F:tie | `fight_screen.gd:515` `_build_result`; `:158` settle | everything settles at once (no dead unit left fading); "Victory", "Defeat" or "Draw" is 72 px text, **appearing at once** | the result emits `result_shown` at once, so the screen stays 2.5 s (`game_controller.gd:23`), skippable after 0.4 s; the replay's 1.5 s end hold is overtaken | `fight.win`/`lose`/`tie` | sound 21 Nov | `fight-whole` | – | **GAP** |
| G2 | Damage to the loser's hero | F:herodmg | `fight_screen.gd:533`; `fight_replay.gd:562` | a **static** burst with "−N" on the loser's portrait; the Health badge is rebuilt with the new number (no count, no shake, no pop) | inside G1 | none of its own | – | `fight-whole` | **24 Nov: "the player taking damage after a fight as well" needs work** | **GAP** |
| G3 | Leaderboard after the round *new* | – | `game_controller.gd:144` | the leaderboard appears at once with everyone's Health; the rows don't move | inside G1 | – | – | – | – | **GAP** |
| G4 | Elimination | F:elim, R46 | `glass_parts.gd:161`; `game_controller.gd:247` | the next redraw shows a portrait dimmed to 0.5; the text "The others play on" appears | – | – | – | – | – | **GAP** |
| G5 | Back to the recruit turn *new* | – | `game_controller.gd:324` | instant swap; then B1 to B9 | – | – | – | `recruit-turn-start` | – | **GAP** |
| G6 | Game over: the result screen | R47 | `main.gd:145`; `src/game/ui/result_screen.gd` | instant swap | – | – | – | – | – | **GAP** |
| G7 | Health shown red below max *new* | – | `fight_screen.gd:17` | static colour | – | – | – | – | – | n/a (static) |

### H. Idle and continuous motion

| # | Event | Lists | Code | What moves today | Holds | Sound | Since 20 Nov | Films | Owner | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| H1 | Triple-candidate rim breath | R28 | `glass_duplicate_glow.gd:75` `set_phase`; `src/screens/recruit/recruit_screen.gd:120` | the shadow opacity breathes on a cosine, period **2.8 s**, floor 0.78 (candidate 0; the 1.4 s / 0.48 candidate is unused); matches and owned edges are steady | – | – | – | `dupes-candidates`, `shop-glow` | – | idle |
| H2 | Triple foil | – | `src/glass/glass_triple_foil.gd:6`, `:79` | diagonal light bands travel 0.66 on a cosine, period 3.2 s | – | – | – | `shop-glow` | – | idle |
| H3 | Carried card's spring settle | – | `card_carry.gd:97` | the lean and pitch springs keep moving after the pointer stops (about 12 f to rest) | – | – | – | `drag-basics` | – | idle |

## Notes

### Gaps, grouped (37 rows, 45 events)

- **The fight's ends are bare.** The move into the fight (E2), the fight's start, the result (G1), damage to the hero (G2), the round's leaderboard (G3), elimination (G4) and the way back (G5) have no motion. The owner named G2 on 24 Nov.
- **Screens and menus:** A1 to A5, A7 to A9 and G6 all swap at once.
- **Recruit actions that change numbers** (D3 to D6, C3) only pop a number. Nothing shows where the change came from. The fight has the same problem (F12, F13), and that is the one the owner named ("When Brock gets stats it's very hard to tell what happened").
- **Shop state:** freeze and thaw (C8, B3), Discover (D12, D13) and duplicate marks turning on (C11) snap.
- **Fight keywords and chains:** Cleave, Overrun, Thorns, Sortie, Guard, again (F10), effect damage (F11), keywords and status (F13), death effects (F17), the combo (F20) and the queue speed-up (F21) are all gaps. `heap_use`, `renown`, in-fight `gold` and `summon_failed` (F15) show nothing at all.
- **Missed by all three lists:** past boards (A9), the End turn button (E3), the round's leaderboard (G3) and the way back to recruit (G5), all gaps. Also missed: the result staying 2.5 s, not 1.5 (G1), and the generic number pop (D14).

### Inconsistencies

1. **Four motion systems with different curves for the same jobs.** Godot Tween transitions are used in the fight and `CardKeeper` (QUAD, CUBIC, BACK). The CSS-bezier copies in `GlassMotion`/`GlassTimeline` are used by the recruit batch. Hand-rolled curves are used at turn start (`_out` cubic, `_arrive`) and in the triple (t³, t², smoothstep on its own `_process` clock). `CardCarry` uses a spring. One "ease out" means four different curves.
2. **Number pops differ:**
   - card numbers: 1.5×, 0.24 s, BACK out (`card_keeper.gd:528`)
   - turn-start numbers: 1.6×, 0.26 s, cubic out (`recruit_turn_start.gd:272`)
   - counter plates: 1.25×, 0.35 s, BACK with Godot's default **in-out** ease, so it dips before it settles (probably unintended) (`glass_counters.gd:146`)
   - waiting count: 1.8×, 0.26 s, bez OUT

   Their sizes and timings all differ for the same meaning.
3. **Hops and flights to the hand differ:**
   - let-go flight: 8 to 15 f, 1−cos, and a 12 f sine hop
   - swap's leaving card: 0.28 s "arrive" curve and `GlassMotion.hop`
   - waiting slide: 0.32 s INOUT
   - Discover pick: no flight at all, a 0.18 s fade
4. **Arrivals are weaker than departures.** A death has a 15 f drop, turn and shrink. A summon, reserve or return, and a new shop at turn start, is a plain 0.18 s linear fade with no motion. The hit's 3 f knock-back is linear while everything around it is eased. The hit light and the attacker's glow switch on at once and fade out slowly.
5. **Speed and timing leaks.** The counter plate's pop and the sound delays (`delay_s`, wall-clock) are not divided by fight speed. The trigger's lift is 0.1 s, but its return and turn use `MOVE_TIME` 0.2 s. The "source lights up" look is the same in the fight (lift held until the next attack) and at turn start (0.10 s in, 0.15 s out, released by itself), with different timing. Gold counts down for every spend but jumps up for every gain except Relic Seeker.

### Other notes

- `anim-recruit/NOTES.md` R28 says the triple breath is "1.4 s, as now". The code uses candidate 0, so it is 2.8 s (H1).
- The lists' "Now" columns still hold except where PR 250 built a row (C1, C2, C7, C9, D9 to D11, B4 to B6, B9, C13). The fight rows are unchanged since 19 Nov. The only fight-screen changes since then are the Skip button, sound and the keyword column.
- Film fixtures: there is a fight film for the stand-in whole fight (`fight-whole`, `fight-windup-long`), Mouse pile-on (`mouse-kin`) and Pigeon reserve (`pigeon-reserve`). There is no fixture for the result, hero damage, elimination or screen moves, because they don't move.
