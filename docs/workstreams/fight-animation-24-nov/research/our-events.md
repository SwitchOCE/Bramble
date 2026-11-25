# Our fight's events, and how the build shows them (R3, 24 Nov 2026)

Read from `src/core/combat/` (`combat.gd`, `fight_deaths.gd`, `fight_arrivals.gd`, `fight_auras.gd`, `fight_side.gd`), every fight hook in `src/content/*/mechanics` and `src/core/mechanics`, `src/screens/fight/fight_replay.gd`, `fight_screen.gd`, `fight_motion.gd`, and `src/sound/`. The core's own field list is `src/core/README.md`, "Fight log". Branch `ideation/fight-animation` at `ec669629`. "Filmed" means seen in R3's films of the stand-in fights (`our-attack-measured.md`); the rest is read from the code.

**29 event types.** The rules core decides the whole fight first and writes one flat list of events; the screen replays the list. The screen never sees "this event caused that one" except by order (and `source_uid`). Events are written in the order the rules resolve them, which is what the replay plays.

## 1. Inventory

"Shown today": the replay step it makes (kind, hold at speed 1) and the motion. Steps of the same kind in a row **merge** into one step (several damages, several deaths, several summons, several changes), except `trigger`, which never merges. A change right after a summon merges into the summon. A step that would look the same as the one before is not made. Holds: start 0.7, lunge 0.22, home 0.14, splash 0.55, trigger 0.3, death 0.3, summon 0.35, change 0.3, end 1.5 s.

Fix-round rows refer to `docs/design/mockups/fix-round-20-nov/anim-fight/NOTES.md` (section 2 below has all 34).

| Event | Fields | Caused by | Can cause | Cards today | Repeats in one moment | Shown today (step, hold, motion) | Fix-round row; built? |
|---|---|---|---|---|---|---|---|
| `combat_start` | players, first, boards, slots, counters, heaps, reserve, outnumbered_by | the fight beginning | Start of Combat triggers | all | once | start step, 0.7 s; boards appear at once (no entry motion) | enter: not built |
| `trigger` | side, slot, uid (−1 for a standing rule), mechanic | any mechanic acting (`combat.trigger` before it acts); a return | whatever the mechanic does next: buff, damage, hit, summon, attack, destroy, keyword, uses, counter, heap, renown, gold | every card with an effect; standing rules (Badger Grudge pay) | **yes, many**: one per unit per cause (Glean, Plague, Padre, Old Brock, Sword-heir, Swarm-lord, Lone Hawthorn for each death; Pile on for each neighbour; Sexton per Fury) | trigger step, **0.3 s each, never merged**; unit lifts 14 px in 0.1 s and glows, stays lifted until the next attack/death/pass/end | combo, strike, fury, seed, hoppers, hmd: not built |
| `attack` | side, slot, uid, target_side, target_slot, target_uid, out_of_turn, takes_no_damage | the attack order; `attack_now` (out of turn) | on_attacked (Thorns, Gate Warden, Fury), on_attack (Fury, Drum, Rally), pile-ons, the exchange, after_attack, deaths | all units; out of turn: Oakfeller, Tourney Champion, Air Marshal (a reservist), Needle Sister | back to back: Windfury (Shrew Harrier, Hornet Queen) 2; Tourney N targets; Oakfeller extra after a kill; attacks can nest 4 deep | lunge step 0.22 s (a 0.14 s home step first if the last attack's lunge is still showing): wind-up 4 frames, travel 8, stop 0.62 card heights short; out-of-turn looks the same | attack: keep, unchanged; again, sortie, lancer: not built |
| `instead_of_attack` | side, slot, uid, mechanic | a mechanic taking the turn | its own effects | **none** (no shipped or stand-in card implements it) | no | default: a change step if the picture changed | not in the proposal; can't happen today |
| `hit` | side, slot, uid, target_side, target_slot, target_uid | Pile on (during an attack, queued until all friends heard it); Ballista (Start of Combat); Weasel (an enemy summon) | its `damage`, then after-hit effects (Cutpurse gold, Pikeman/Fencing Master buffs) | Needle Page, Shrew Cutpurse, Fencing Master, Dame Bodkin, Needle Pikeman, Toothpick Ballista, Weasel | yes: up to 4 pilers per attack; Ballista "times" hits | no step of its own; its damage's splash. During an attack the hitter **jabs** 60 % of the lunge in 4 frames and holds; the attacker winds up at home and lunges only at the exchange (an extra lunge step). Outside an attack (Ballista, Weasel) the hitter doesn't move | pileon: partly (jab built 19 Nov; 70 ms stagger and ×N not) |
| `damage` | side, slot, uid, amount, health (after), source_uid, from_attack | the exchange (attacker's hit, Cleave, strike back), Thorns, Overrun, death damage, Glean, Plague, Lieutenant, Bumblebee sting, hits | Overrun (more damage), Venomous (destroy), on_damage_dealt; deaths at the next death check; aura changes when lethal | all; effect damage: Thorns (Nettle Sprout, Nettle Skirmisher, Lone Hawthorn), Overrun (Ironhide Berserker, Oakfeller), Orchard Stripper (all enemies), Wheat Raider, Gleaner, Eighth Plague, Lieutenant (row), Bumblebee | **yes**: 2 per exchange, 3 with Cleave, up to 7 from Orchard Stripper, a row from Lieutenant | splash step 0.55 s, all damages in a row in one step: a burst "−N" on each, Health swaps with a pop, target knocked 16 px; the attacker leaves contact 2 frames later | damage: not built (no red flash; Health already changes at the hit); cleave, overrun, thorns, strike, lieut: not built |
| `prevented` | side, slot, uid, amount, reason (`takes_no_damage`, `only_attack_damage`, `absorbed`), source_uid | Divine Shield, an attack that takes no damage, damage-from-attacks-only | nothing more | Hedge Lancer, Stag Beetle; Divine Shield only on stand-in/test units | with the exchange | in the splash step: a burst with "0", knock-back at 30 % | lancer: not built |
| `destroy` | side, slot, uid, source_uid | Venomous, Bitter Toad's death effect | death at the next check | Heath Adder, Hornet Queen, Bitter Toad | rarely more than one | in the splash step: a burst with no number | not in the proposal (Venomous left out) |
| `buff` | side, slot, uid, attack, health (new), source_uid, permanent | Fury, Gate Warden, Rally, Old Brock, Sword-heir, Hand-me-down, Hob, Standard-bearer, Grow, Molt, Sapling, Coppicer, Veteran, Sweetbriar, Sexton, Avenge, Elder Mother | aura recalculation (`stats`) | Badger Fury cards, Gate Warden, Old Brock, Sword-heir, Mouse heirs, Parish Standard-bearer, Blackberry Sprawl, Husk Sentry, Sweetbriar … | **yes**: Standard-bearer buffs every Mouse; Avenge buffs the board | change step 0.3 s; consecutive buffs merge; numbers swap with a pop | fury, buffs, hmd: not built |
| `stats` | a unit view + aura_attack, aura_health, after | an aura, slot effect or Renown changing what a unit shows (after any board, buff, counter, heap, slot change or death) | nothing | Lends (Armsbearer, Shield-bearer), the Swarm (Locust standing rule), Group Captain, Squadron Leader, Renown | **yes**: one per unit whose numbers moved, often the whole side | change step 0.3 s (merged with other changes; merged into a summon) | lends, tide: not built |
| `effect` | side, slot, uid, mechanic, params, permanent, source_uid | a mechanic with numbers given mid-fight | aura refresh | Sword-heir (gives Fury) | rarely | change step 0.3 s; the pill's number updates | not built |
| `keyword` | side, slot, uid, keyword, on, source_uid | a keyword given mid-fight | — | Molt re-given on a return, Skin-shedder (Molt) | Skin-shedder: several units | change step 0.3 s; pill appears | not built |
| `status` | side, slot, uid, status, on, source_uid | a one-use keyword used up (shield popped, Venomous spent, Stealth ends, Reborn/Root/Molt used) | — | Root, Molt cards; Venomous cards; shield/stealth/reborn on stand-ins | with each use | change step 0.3 s; the pill drops or dims. **Logged before the hit it blocks**, so a shield costs the attacker 0.3 s at contact | not built |
| `uses` | side, slot, uid, key, left, source_uid | a limited ability spending a charge | — | Pile on counts, Mouse charges (Old Mother, Hob, Sister), Weasel, Flying Ace, Padre, Wing Commander, Bugler, Recruiting Sergeant, Air Marshal, Molt, Skin-shedder | yes (each piler) | change step 0.3 s; the pips change; at 0 the pill dims | renown (pip flash): not built |
| `counter` | side, slot, uid, key, value, permanent, source_uid | a unit's lasting number | — | **none in a fight today** (no fight hook calls it) | — | change step 0.3 s | can't happen today |
| `player_counter` | side, key, value, source_uid | a player number (the Tide) | Swarm aura (`stats` on every Locust) | Brood Mother, Swarm-lord, Famine-caller; a Hopper with no room (+1 Tide each) | yes (each death or lost Hopper) | change step 0.3 s for **your** plates only; the opponent's: no step | tide: not built |
| `heap_add` | side, heap, id, size, source_uid | a card going into the Compost | `on_heap_added_in_fight` (Sweetbriar buff) | Seed cards (Pip, Bramble Runner, Crab-apple), Lone Hawthorn | yes (each death) | change step 0.3 s, your plate only | seed: not built |
| `heap_remove` | side, heap, ids, size, source_uid | Root paying for a return | aura refresh | Root cards (Blackthorn Sapling, Nettle Skirmisher, Hawthorn Warden) | once per return | change step 0.3 s, your plate only | root: not built |
| `heap_use` | side, heap, count, ids, entries, unused, source_uid | Old Stump, Elder Mother copying the best Compost entry | the `summon` that follows | Old Stump, Elder Mother | once or a few | **nothing shown** (no step) | not in the proposal |
| `slot` | side, slot, total, permanent, source_uid | Colour Ensign copying Renown onto slots (Start of Combat) | aura refresh (`stats`) | Colour Ensign | several slots | change step 0.3 s; slot's Renown | not built |
| `renown` | side, slot, amount, next_fight, permanent, source_uid | a slot gaining Renown for the next fight | — | Flying Ace, Padre, Wing Commander | each kill/death | **nothing shown** (counts from the next fight) | renown: not built |
| `gold` | side, amount, next_turn | gold earned in the fight | — | Shrew Cutpurse (after its pile-on) | each pile-on | **nothing shown** (a notice next turn) | not in the proposal |
| `death` | side, slot, uid, killer_uid | death resolution after an attack, an effect, or each Start of Combat effect | on_kill, on_friendly_kill, on_any_death, death effects, on_friendly_death, after_friendly_death, returns, Reserve stepping in, after_death_round; then another pass if more die | all | **yes**: a whole pass (cleave, Orchard Stripper, mutual kills) | death step 0.3 s, a pass falls together: 15 frames, drop 48 px, turn 16°, shrink, fade | deaths: keep motion; overlap with the burst not built |
| `summon` | a unit view + source_uid | death effects, Start of Combat, a friendly attack, after a friendly death | on_fight_enter: Weasel hits it, Air Marshal, Compost (Elder Mother bonus); aura refresh | Brood Mother, Green Recruit, Sky-darkener (Hoppers), Thimble Captain (Cousin), King Speck, Elder Mother, Old Stump, Crab-apple | **yes**: Hoppers × multiplier (Mother of Thousands), up to the board's room | summon step 0.35 s, fades in over 11 frames; **summons in a row share one step** | summon, hoppers: not built |
| `summon_failed` | side, id, source_uid | no room | Tide +1 for a Hopper | Hopper makers | yes | nothing shown | not in the proposal |
| `reserve` | a unit view + source_uid, from_hand | a Reserve unit stepping in from the hand after a death; a Private (Bugler, Recruiting Sergeant) | on_fight_enter (Air Marshal attacks at once, Weasel hits) | Territorial, Home Guard; Privates | up to the reserve limit (2) per fight, plus Privates | summon step 0.35 s, fades in its slot with the slot's Renown | reserve: not built |
| `return` | the new unit's view + from_uid, mechanic, source_uid; what pay_return/on_returned logged follows it | a dying unit's return offer (Molt, Root, Reborn) | after_friendly_return (Coppicer, Veteran), heap_remove, buff, uses, status, keyword | Husk Sentry, Wheat Raider (Molt); Blackthorn Sapling, Nettle Skirmisher, Hawthorn Warden (Root) | one per dying unit (up to 5 a fight per unit) | summon step 0.35 s; the changes after it merge into it | molt, root: not built |
| `pass` | side | a side that can't attack | — | — | — | usually no step (picture unchanged); a 0.3 s change step if a lunge was still showing | — |
| `combat_end` | winner, reason, starting, killed, attacks, triggers, survivors, … | the end or a limit (200 attacks, 10 000 triggers) | — | — | once | end step 1.5 s: "Victory", "Defeat" or "Draw" text, a static burst on the loser's portrait | tie, result, herodmg, elim: not built |

### Chains that matter for a decision tree

1. **Plain attack:** attack → damage (target) → damage (attacker, strike back) → death(s). Today: lunge 0.22, splash 0.55, death 0.3.
2. **Something before the hit:** attack → [trigger → buff/status/damage] … → damage, damage. Thorns (trigger, damage to the attacker, before the exchange), Fury and Gate Warden (on being attacked), Rally and Drum (on attacking), Divine Shield (status logged before its `prevented`), Hedge Lancer (trigger logged before the attack event). Today each adds 0.3 s steps **while the attacker waits at contact** (filmed: shield, Rally). Read from the code, not filmed: Thorns' damage is its own splash, which starts the attacker's return, so the exchange lands with the attacker already home.
3. **Pile on:** attack (marked `piled`) → uses → trigger → (more pilers) → hit → damage → after-hit effects … → damage, damage (exchange). Today the attacker winds up at home, pilers jab and hold, then the attacker lunges.
4. **Something during the hit:** damage → Overrun (trigger, damage to the next enemy, repeating while damage is left) or Venomous (trigger, destroy, status); Cleave damage is in the same splash. Today Overrun/Venomous come **after** the splash, the attacker already home, and the strike back's own splash follows them (measured: strike back 75 frames after contact).
5. **After the hit:** after_attack → death pass → kills (Flying Ace, Wing Commander: renown, uses) → "whenever a unit dies" (Lone Hawthorn) → death effects (summon, Hoppers, Seed → Compost → Sweetbriar buff, Hand-me-down → buff → Sister attacks at once, Bitter Toad destroy, Orchard Stripper damage) → "after a friend dies" (Glean, Plague, Old Brock, Sword-heir, Padre, King Speck) → returns (Molt, Root) → Reserve steps in → after_death_round (Privates, Oakfeller's extra attack) → another death pass if anything died. **Every level can loop.**
6. **Arrivals answered:** summon/reserve → on_fight_enter → Weasel hit (→ damage → death …), Air Marshal makes the reservist attack at once (→ chain 1–5, nested).
7. **Start of Combat:** for each priority, one random side's units in reading order, the other side's, deaths after each effect: Ballista hits, Lieutenant row damage, Tourney Champion attacks, Grow, Standard-bearer, Colour Ensign, Sky-darkener Hoppers, Skin-shedder, Elder Mother. Today: trigger step, then its effect's step, unit after unit; no lunge for effect damage.

### What our game can't produce today (so no branch is needed yet)

`instead_of_attack` and a fight `counter` (no card uses them). Divine Shield, Reborn, Stealth and plain death summons exist only on the stand-in and test units (the shipped pool uses Molt, Root and tribe summons instead). Nothing heals in a fight. Nothing moves a unit to another slot in a fight (the `move` event was removed 17 Nov). Nothing hits a hero mid-fight. The opponent's counters and Compost are not on screen.

## 2. The 20 Nov fix-round proposal (34 rows): built?

The owner accepted all of it on 21 Nov (fix-round plan, decision 13), to be built in batches with the recruit batch first. The recruit batch merged (PR 250). **The fight batch was never started**: since 19 Nov the only commits under `src/screens/fight` are the Skip button (`8625a096`, 21 Nov), sound (`bfeaa73a`, `9308a3dd`) and the keyword column (`68388d52`). Checked against the code, not only the log.

| Row | Built? | Note |
|---|---|---|
| Moving into the fight | no | instant swap, 0.7 s hold |
| Hedge Lancer's free attack | no | trigger glow 0.3 s, then a normal attack, "0" burst |
| Grow | no | each Grow its own trigger + change step |
| Wing Commander (Sortie at start) | no | |
| An attack (keep) | yes, as before | unchanged since 17 Nov (measured: `our-attack-measured.md`) |
| Damage numbers (Health at contact, red flash) | no | Health already swaps at the hit (3 frames after contact) with a ×1.5 pop; no red flash |
| Guard choosing the target | no | |
| Attacks again (Oakfeller) | no | |
| Cleave | no | neighbour's burst in the same splash |
| Overrun | no | |
| Pile on, four neighbours | partly | jab, hold and late lunge built 19 Nov (before the proposal); the 70 ms stagger and ×2…×4 not |
| Sortie over the front row | no | straight lunge through the front row |
| Thorns | no | |
| Effect damage line (Gleaner) | no | |
| Fury gains | no | separate trigger and change steps, attacker held at contact |
| Lends, an aura ending | no | |
| Buffs to many (Standard-bearer) | no | one trigger + one merged change step |
| Counters: the Tide | no | |
| Renown earned in a fight | no | the `renown` event shows nothing |
| Deaths (motion kept, overlap the burst) | no | motion kept; still its own step after the 0.55 s splash |
| Seed into the Compost | no | |
| Brood Mother's Hopper | no | |
| Summons (wave) | no | but the proposal's "Now" is wrong for one source: summons in a row already share one 0.35 s step; separate sources (each with its trigger) do take a step each |
| Reserve stepping in | no | fades in |
| Molt returning | no | |
| Root returning | no | Compost plate does update (your side) |
| Hand-me-down | no | |
| The same trigger 10 times (combo) | no | 10 × (0.3 + 0.55) s |
| Lieutenant (several strikes) | no | |
| A tie | no | |
| The result | no | |
| Damage to the loser's hero | no | |
| Elimination | no | |
| Skip | partly | a Skip button and Space jump straight to the result (21 Nov, owner: Space only); no 6× fast-forward (the fix-round plan left it out until asked) |

Owner choice in the proposal, also not built: the queue speed-up (play up to 1.6× faster when more than 4 steps wait).

**Events the proposal missed:** Venomous `destroy` and its `status` (two cards ship with it); Divine Shield and the shield-before-hit pause (stand-in units only); `heap_use` (Old Stump, Elder Mother); in-fight `gold` (Cutpurse); `summon_failed` (a Hopper with no room turns into Tide); `effect` (Sword-heir gives Fury); Skin-shedder's `keyword`; Air Marshal's at-once attack by a reservist; Weasel hitting an arriving unit; Tourney Champion's start-of-fight attacks; Drum (death effects run without a death); Windfury's second attack; Old Brock and Sword-heir after a death; Sweetbriar answering a Seed.

**Proposal rows our game can't produce as drawn:** none of the 34 is impossible, but three need care: "Wing Commander" at the start of a fight (in the code it gives Renown after a friend's kill; Sortie is a targeting rule, so a Sortie unit attacks when its turn comes, not as a start-of-fight wave); "Renown earned … Charge pip flashes" (Flying Ace's `uses` exists, but Renown has no visible change this fight by rule); "Elimination" (the fight log has no elimination; it comes from the game log after the fight).

## 3. Today's ordering, as a flow

```
combat_start ── 0.7 s, boards appear
  └─ Start of Combat, unit by unit:  [trigger 0.3: lift+glow] → [its effect: splash 0.55 | change 0.3 | summon 0.35] → [death 0.3] …
each attack:
  [home 0.14, only if the last lunge is still showing]
  [lunge 0.22] wind-up 4f → travel 8f → contact (frame 12)
     ├─ anything logged before the damage (Thorns, Fury, Rally, Drum, shield status, pile-ons):
     │     [trigger 0.3] [change 0.3] [splash 0.55] …   ← attacker waits at contact the whole time
     │     (from the code, not filmed: a Thorns splash sends the attacker home before the exchange's own splash)
  [splash 0.55] all damage of the exchange at once: bursts, Health swaps, target knocked,
     │           attacker leaves contact 2f later, home 11f later
     ├─ anything logged after the damage (Overrun, Venomous, status): [trigger 0.3] [change/splash] …
     │     ← attacker already home; the strike back's splash is merged or comes after these
  [death 0.3] the pass falls together (15f), slots stay empty
     └─ per death, in order: [trigger 0.3] [effect step] … ; [summon 0.35] arrivals fade in (in-a-row summons share it);
        returns [summon 0.35]; Reserve [summon 0.35]; more deaths → another [death 0.3] …
  next attack
combat_end ── 1.5 s, result text, static burst on the loser
```

Nothing plays at the same time as anything else except inside one merged step. Nothing waits for a motion to finish: the replay moves on by hold time only, and a new step restarts any card whose look changed.

## 4. Sound cues and the motion they sit on

All fight cues fire from `Sound.fight_step` (`src/sound/sound_player.gd`), called by `FightScreen._next_step` **at the start of each replay step**; `SoundCues.for_fight_step` (`src/sound/sound_cues.gd`) picks them from the step's kind, using `assets/audio/cues.json`. Sound reads only the steps, never the core. The audio spec (`docs/workstreams/sound/audio-spec.md`) says the cues have a 1.6–2.9 ms onset and should fire "directly on the visual contact/event frame".

| Cue | Fired on | The motion it lands on today | Moves if… |
|---|---|---|---|
| `fight.hit.light` / `.medium` / `.heavy` (damage ≤ 4, ≤ 13, ≥ 14; heaviest of 1–2 hits played once) | start of a splash step | the burst pop and the target's knock-back, **3 frames after contact** in a plain attack (22 or 41 frames after contact when a trigger or shield sits between); for effect damage, the burst | contact time, the lunge hold, or anything that reorders hits vs triggers |
| the same, 3+ hits (Cleave, area) | splash step start | up to 3 takes at 0, 28 and 58 ms, −0, −4.5, −7 dB | hits are staggered visually |
| `fight.hit.blocked` | splash step with a `prevented` | the "0" burst; with a normal hit it plays 15 ms later at −3 dB | as above; a shield pop shown at contact |
| `fight.destroy` | splash step with a destroy | the numberless burst | as above |
| `fight.death` | start of a death step (count = units gone since the step before) | frame 1 of the 15-frame fall; 2 takes at most (0 and 55 ms, −4.5 dB) | deaths overlap the burst, or are staggered |
| `fight.summon` | start of a summon step (summon, reserve, return) | frame 1 of the 11-frame fade-in | arrivals get their own motion or a wave |
| `fight.trigger` | start of a trigger step | frame 1 of the 6-frame lift and glow | triggers are grouped, overlapped or sped up (a ×N combo would fire it once per step, with `min_gap_s` 0.08) |
| `fight.win` / `.lose` / `.tie` | the step where the result first shows | the result text appearing (1.5 s hold) | the result gets motion |
| none | wind-up, travel, contact, return, change steps (buffs, stats, status, uses, counters), start of fight, the Skip | — | a new motion that wants a sound needs a new cue |

Two timing facts for whoever retimes: a cue's delay (`delay_s`) is counted in wall-clock milliseconds, not game time, so it does not scale with playback speed and runs ahead of the picture in a slow film; and because cues fire at step starts, any change that makes contact happen inside a step (rather than at a step boundary) has to fire the hit cue from the motion instead.
