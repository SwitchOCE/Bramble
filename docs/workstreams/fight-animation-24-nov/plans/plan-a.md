# Plan A: Battlegrounds' measured grammar, fitted to our board (24 Nov 2026)

Planner A of three. Stance: take R1's measured Battlegrounds numbers and rules as the starting point and adapt them to our distances and card size. Nothing here is decided or built.

**Units.** Frames at 60 fps, counted from **contact = frame 0**. h = one card height, 250 px on the 1920 × 1080 stage (card 140 × 250). Our distances, centre to centre, from `FightScreen.unit_xy`: front row straight across **1.18 h**, front-row diagonal neighbour **1.32 h**, front-row far corner **2.17 h**, front row to the enemy back row **2.06 h**, back row to the far enemy back slot **3.14 h** (the longest). Battlegrounds' straight-across distance is about 1.27 of its own card heights, so the near case maps almost one to one; our longest attack (3.1 h) is shorter than theirs (about 5 h).

**What is measured and what is a guess.** Phase lengths, curves, stop points, the contact pop, number timing, death delay and "waiting goes into the next attacker's hold" come from R1. Marked *guess*: anything R1 could not see (the target's reaction, the lift's easing, trigger visuals) and every number for events Battlegrounds has no equivalent of (pile-on, Overrun, back-row targets, the ×N counter). No agent has watched any of it move.

## 1. The basic attack

| Phase | Frames | What moves | Curve | Source |
|---|---|---|---|---|
| **Lift** | −35 to −26 (10 f) | Scale 1.00 → 1.15 in place. No pull-back, no tilt (today: 12 px pull, 6° lean, ×1.04). A warm light comes on in the lead as it peaks (stand-in: today's glow tint; a proper ring needs the art pass and the owner's yes, as a new card-face element). | Quad ease-out (*guess*: R1 measured the length, not the curve) | R1: 9 to 11 f, ×1.14 to 1.16 |
| **Hold** | −25 to −8 (**18 f minimum**) | Dead still, raised. Stretches when something must play first (section 2). | none | R1: 14 to 16 f in Nov 2026 footage, 21 f in 2020 to 2025; 18 splits them |
| **Strike** | −7 to 0 (7 f; **8 f when the target is over 1.6 h away**) | Straight line, the same number of frames at any distance, so speed scales with distance. | **Linear**, no ease in or out | R1: 5 to 8 f at 0.3 to 4.6 h, constant speed |
| **Contact** | 0 | Attacker scale jumps to **1.26** for this one frame. Both cards lit white-warm for 4 frames (stand-in: today's `HIT_LIGHT`). **0 frames held.** | step | R1: ×1.24 to 1.28, flash 3 to 6 f, reverses next frame |
| **Return** | from +1: **10 f** (up to 1.4 h), **14 f** (1.4 to 2.4 h), **16 f** (beyond) | Straight home; scale back to 1.0 by +5. | Quart ease-out (first frame covers ~23 % of the way; R1's A2 trace covers 20 %) | R1: 9 to 16 f, fast first |
| **Target reaction** | +1 to +3 push, settle by +14 | Knocked 16 px (0.064 h) along the attack line, turn 4°, then home (today's numbers, started 2 frames earlier). A blocked hit moves 30 %. | linear push, cubic-out settle | *Guess*: R1's flash hid it; Galaxy pushes 0.35 h |
| **Number pop** | +3 | Burst on every damaged card at once: ×0.55 → ×1.18 in 3 f, → 1.0 in 5 f, readable to **+45**, fades by +52 (today on screen 32 f). | today's | R1: star at +3 to +4, ~60 f on screen |
| **Health change** | +3 | Digit swaps with today's pop, plus the red flash on its disc the owner accepted on 21 Nov. | | R1: red number at +3 |
| **Death read** | fall starts **+33** | Today's 15-frame fall, unchanged. | | R1: +40 (2026) to +65 (2020) |
| **Next attacker lifts** | **+36** | See 2.3. | | R1: next ring at +41 to +46 |

**Where it stops.** Centres along the attack line end **0.78 h apart for targets up to 1.4 h away, 0.45 h for targets 2.2 h or more away, linear between; 0.35 h for any back-row target.** With the attacker at ×1.15, 0.78 h means its leading edge sits about 0.3 h inside the target's (R1: 0.15 to 0.3 h overlap, centres 0.8 to 1.0 h apart near, 0.4 to 0.65 h far). The back-row rule is ours: the enemy front row covers the bottom 34 px of the back-row card, so a shallow stop would look like hitting the front-row card in between.

| Case | Distance | Travel | Strike | Speed | Return | Lift to contact |
|---|---|---|---|---|---|---|
| Straight across | 1.18 h | 0.40 h (100 px) | 7 f | 14 px/f | 10 f | 35 f |
| Diagonal neighbour | 1.32 h | 0.54 h (135 px) | 7 f | 19 px/f | 10 f | 35 f |
| Far corner, front row | 2.17 h | 1.71 h (427 px) | 8 f | 53 px/f | 14 f | 36 f |
| Front row to back row | 2.06 h | 1.71 h (427 px) | 8 f | 53 px/f | 14 f | 36 f |
| Farthest, back to back | 3.14 h | 2.79 h (697 px) | 8 f | 87 px/f | 16 f | 36 f |

The attacker draws above everything from the start of its lift. A back-row attacker flies straight through its own front row (no arc; Battlegrounds has none).

**Where this stance is weak:** straight across, today's attack travels further (140 px, centres 0.62 h apart) than this plan (100 px). R3 shows ours already overlaps more than Battlegrounds near; what ours lacks is the hold and the abrupt stop. If the owner's eye still says "it doesn't reach", deepen the near stop to today's 0.62 h, keeping everything else (contested choice 1).

## 2. Ordering rules

**2.1 Principle: one thing moves into place at a time, nothing pauses once it moves, and all waiting goes into the next attacker's raised hold.** A strike, return, fall or arrival, once started, always runs to its end.

**2.2 Chain items.** Everything the core logs between one attack's exchange and the next attack is a queue of *items*, played in log order:
- An item's **landing** is the frame its change shows (number, pill, arrival).
- The next item starts **4 frames after the previous item lands**, not after it ends, so items overlap their tails (R1's T1: four triggers 5 to 8 frames apart).
- **One source acting on many targets is one item**: all targets land in the same frame (R1's T3: one burst on 4 cards). Exception: a source that draws separate lines (Lieutenant) staggers them 5 frames left to right, the timing the owner accepted on 21 Nov.
- Triggered effects of an attack start **no earlier than the attacker's return end** (+11 to +17), except those that are part of the hit itself (Cleave, Overrun, a shield, Venomous), which go at contact.
- A death falls **30 frames after the damage that killed it lands**; one death pass falls together. Its landing counts as its 8th frame, so later items overlap the second half of the fall. An item whose source has just died (a death effect) starts when the fall ends, from the empty slot.

**2.3 Where the waiting goes.** The next attacker lifts at **max(+36, queue end − 50)** and launches at **max(lift + 28, queue end + 8)**, where queue end is the last landing or fall end. So in a plain attack it lifts while the burst is still read, and in a long chain it holds raised for at most about 48 frames. Battlegrounds held 220 frames once (T2); I cap it, because a card sitting raised for 3 s draws the eye away from the chain it waits on.

**2.4 Before the strike.** Everything the core logs between `attack` and the exchange (on_attacked, on_attack, pile-ons) plays **in the hold**, attacker raised and still, then the strike goes 8 frames after the last of it lands. This replaces today's freeze at contact (23 to 41 frames). It matches the core: if Thorns or a piler kills someone in that window, the attack ends without an exchange (`combat.gd`, `_attack_steps`), and the picture shows it as a raised attacker that never strikes.

**2.5 Speed-up.** Two rules, both from R1:
- **Runs** (2 or more consecutive items of the same mechanic and effect, any source): items 1 and 2 at full cost; each later item costs 0.7× the one before, floor 8 frames; a ×N counter (section 3). R1 saw only 2× acceleration with no counter; the owner asked for steeper and for ×N, so this is where I leave Battlegrounds.
- **Long fights:** from the 13th attack, the fast set R1 measured late in long 2026 fights: lift 6, hold 10, strike 5 (6 far), return 8 to 12, next lift at +22, death read 20. Plain cycle 43 frames (Battlegrounds 34 to 38).
- **Cap:** if one queue between two attacks passes 3 s, every remaining item uses its run floor.

## 3. The decision tree

Shared looks (all *guess* in timing; their visuals need the art pass): **pulse** = the source card scales to ×1.08 and lights over 6 frames and settles over 6, with its effect leaving at frame 6; **streak** = a glass light from source to target, 10 frames, linear; **stack** = repeated bursts on one card merge into one burst whose number updates with a ×N under it.

```
next log event
├─ combat_start ─ boards in (fix-round entry, unchanged here); then Start of Combat items
├─ pass ─ nothing; 0 f
├─ instead_of_attack, counter (in a fight) ─ no branch: no card produces them
├─ attack
│  ├─ attacker just struck and attacks again now (Windfury, Tourney Champion, Oakfeller)?
│  │    yes → return ends still at ×1.15; hold 8; strike
│  │    no  → lift + hold (2.3; may start under the previous queue)
│  ├─ events before the exchange (2.4) → all in the hold
│  │    ├─ Thorns damage → defender pulses, burst on the raised attacker at frame 6
│  │    ├─ buff on being attacked / on attacking (Fury, Gate Warden, Rally, Drum) → pulse, numbers at frame 6
│  │    ├─ pile-on hits → each piler strikes 5 f to touching, returns 10 f; pilers 6 f apart; stack on target
│  │    │    └─ piler's after-hit effect (Cutpurse gold, Pikeman, Fencing Master) → lands with its hit
│  │    ├─ status: shield going off → no item; it belongs to contact
│  │    └─ anyone dead now?
│  │         attacker → it falls from its raised pose (after the death read); no strike
│  │         target   → attacker stands down (scale 1.0 over 8 f); after_attack still plays
│  ├─ exchange at contact (frame 0, numbers +3)
│  │    ├─ damage, both cards, plus Cleave's neighbour → bursts together at +3
│  │    ├─ prevented → "0" burst at +3, push 30 %; shield pill drops at +3
│  │    ├─ Overrun → streak from target to next enemy from +3, 8 f a hop, lands +11, +19 …
│  │    └─ Venomous destroy → numberless burst at +10 on the poisoned card
│  ├─ after_attack effects → chain items from the return's end
│  └─ death pass → falls at landing + 30
└─ chain items (after deaths, arrivals, Start of Combat), in log order, 2.2
   ├─ trigger with a source on the board → pulse (the item's own look starts at frame 6)
   ├─ trigger from a standing rule (uid −1) or a dead source → no pulse; effect starts from the slot or the plate
   ├─ effect damage (Glean, Plague, Lieutenant, Orchard Stripper, Bumblebee, Wheat Raider, Ballista, Weasel) → streak, burst on landing
   ├─ buff, effect, keyword to others (Old Brock, Sword-heir, Standard-bearer, Avenge, Hand-me-down, Sexton, Skin-shedder) → streak, numbers or pill on landing
   ├─ buff to itself (Grow, Molt gain, Veteran, Coppicer) → numbers at frame 6
   ├─ stats, uses, non-shield status, renown → no item; show on the landing of whatever caused them
   ├─ destroy (Bitter Toad) → streak, numberless burst
   ├─ death → 2.2
   ├─ summon, reserve, return, heap_use → arrival (below)
   ├─ summon_failed → shard flies to your Tide plate (opponent's side: nothing)
   ├─ player_counter, heap_add, heap_remove → your plate (opponent's: nothing)
   ├─ slot (Colour Ensign) → streaks to all slots at once
   ├─ gold → nothing in the fight (notice next turn, as today)
   ├─ out-of-turn attack (Air Marshal, Needle Sister, Oakfeller after a kill) → a full attack; its lift may start under the queue (2.3)
   ├─ same mechanic again (run)? → 2.5 acceleration, ×N
   └─ queue empty and the fight is over → combat_end
```

| Event(s) | Shown | Starts | What waits for it | Many in one moment | Cost (frames) |
|---|---|---|---|---|---|
| `combat_start` | boards in, as the accepted fix-round entry | 0 | Start of Combat | once | unchanged (today 42) |
| `attack` (in turn) | lift, hold, strike, contact, return (section 1) | 2.3 | its exchange | Windfury, Tourney: re-strike from raised, hold 8 | 35 to contact, 71 to the next contact |
| `attack` (out of turn) | same | as a chain item | the rest of the chain | each is an item; nested attacks queue in log order | 35 to 36 to contact |
| `trigger` | pulse on the source; none for uid −1 | as its item | its effect (from frame 6) | a run: pulses shorten with the run | 6 to landing of a self effect |
| on_attacked, on_attack buffs; Thorns `damage` | pulse; numbers or burst on landing | in the hold | the strike (+8 after landing) | each in turn, 4 f after the last lands | usually 0: fits inside the 18-frame hold |
| `hit` in an attack (pile-on) | piler strikes 5 f, returns 10 f | in the hold, 6 f apart | the strike | up to 4; target burst stacks ×2 … ×4 | 4 pilers +13 |
| `hit` outside an attack (Ballista, Weasel) | hitter pulses, streak, burst | chain item | next item | Ballista repeats: run | 20 |
| `damage`, `prevented` (exchange, Cleave) | bursts, Health digits, shield pill drops | +3 | death read | all at once | 0 beyond the attack |
| `damage` (Overrun carry) | streak to next enemy | +3, then 8 f per hop | death read | one per hop | 8 a hop |
| `destroy` (Venomous) | numberless burst | +10 | death read | rare | 0 |
| `damage`, `destroy` from effects | pulse, streak, burst | chain item | next item; its death | one source to many: together; many sources: run | 20 each, a run down to 8 |
| `death` | today's fall; a pass together | landing + 30 | death effects from its slot | one pass = one fall | 45 to fall end; 0 to the cycle when nothing else waits |
| `buff`, `effect`, `keyword` from a unit | pulse, streak, numbers or pill | chain item | next item | one source to many: together | 20 (self: 10) |
| `stats`, `uses`, `status` (not a shield), `renown` | numbers or pips change with a soft pop | with their cause's landing | nothing | whole side at once | 0 |
| `summon`, `reserve`, `return` | arrival: ×1.15 → 1.0 with fade, 12 f, landing at 8 (Molt and Root keep the accepted husk and roots looks); a reservist rises from below, 14 f | chain item; into a dead slot only after its fall ends | the unit's own effects (Weasel, Air Marshal) | one source: a wave, 4 f apart; Hoppers × multiplier as one wave | 12 + 4 per extra unit |
| `heap_use` | Compost plate pulses (your side) | as the trigger of its summon | the summon | once or a few | 6 |
| `summon_failed` | shard to your Tide plate, plate +1 | chain item | nothing | a run | 12 (yours), 0 (theirs) |
| `player_counter`, `heap_add`, `heap_remove` | your plate counts; a seed flies to the Compost (accepted fix-round) | with its cause | Sweetbriar's answer | each death: a run | 12 (yours), 0 (theirs) |
| `slot` | streaks to the slots, Renown pills change | Start of Combat item | aura `stats` | all slots together | 20 |
| `gold` | nothing | — | — | — | 0 |
| `pass` | nothing | — | — | — | 0 |
| `combat_end` | result (accepted fix-round), loser's damage | queue end + 24 | — | once | unchanged |

**×N counter (runs).** Appears at ×2 on the source when one source repeats, on the target when many sources hit one card; counts up with each item, its pop growing slightly with N; at N ≥ 4 the final count holds 16 frames. Its look is new and needs the art pass.

**Start of Combat** is a chain like any other, in the core's priority order: Hedge Lancer's trigger is its lift (no separate pulse); several Grow units, or the Standard-bearer's Mice, are one item each; Tourney Champion's N attacks re-strike from raised; Lieutenant's row staggers 5 frames.

## 4. Time budget

Frames from one attack's contact to the next attack's contact (equal to start-to-start). Today's numbers are R3's films.

| Case | Today | Plan A | Battlegrounds (R1) |
|---|---|---|---|
| Plain attack | 57 (0.95 s) | **71 (1.18 s)** | 73 to 83 |
| Attack with a death | 67 | **71**: the fall (+33 to +48) runs under the next lift | ~90 (D1); 150+ with effects |
| Shield popped | 76 to 86 | **71** | — |
| Pre-hit trigger (Rally, Thorns, Fury) | 124 to 139 | **71**: it fits in the hold | — |
| Death effect summon (Hopper into the dead slot) | 89 | **71**: it lands at +56, before the launch at +64 | — |
| Chain: a kill, its death effect summons a Hopper, a friend's Glean kills another | ~180 | **136** (death +33 to +48, Hopper lands +56, Glean lands +76, second fall +106 to +121, launch +129) | T1: ~72 |
| One trigger 10 times (Gleaner ×10) | 530 (8.8 s) | **~128 to the last landing (2.1 s)**: 20, 20, 14, 10, 8 × 6, plus 16 on ×10; deaths after | T3: ~470 for 10 cycles |
| 7-attack fight (R3's film) | 10.6 s | about 12 s (*estimate*) | — |

Plain attacks get 14 frames longer (+25 %); anything with triggers gets shorter, because pre-hit items move into the hold, items overlap their tails, and deaths run under the next lift.

## 5. Sound: cues that would move

Listed, not retimed. All cues fire at replay step starts today; in this plan most land inside a motion, so they would have to fire from the motion's frame.

| Cue | Today | Plan A | Moves by |
|---|---|---|---|
| `fight.hit.*` (plain) | contact + 3 = frame 15 of the attack | contact + 3 = frame 38 | same against contact; +23 f (0.38 s) against the attack's start |
| `fight.hit.*` after a shield or pre-hit trigger | contact + 22 or + 41 | contact + 3 | 19 to 38 f earlier |
| `fight.hit.*` for Thorns | its own splash, after the attacker waits at contact | in the hold, ~20 f before contact | moves before the strike |
| `fight.hit.*`, 3+ takes | all at step start | Cleave together; Lieutenant 5 f apart; Overrun 8 f per hop | spread over 83 ms or more |
| `fight.hit.blocked` | contact + 22 | contact + 3 | 19 f earlier |
| `fight.destroy` (Venomous) | ~contact + 56 | contact + 10 | ~46 f earlier |
| `fight.death` | contact + 37 | contact + 33; chain kills 30 f after their landing | 4 f earlier, more in chains |
| `fight.summon` | step start after the death step (~+56) | fall end (+48); waves 4 f apart | ~8 f earlier; several takes |
| `fight.trigger` | each 0.3 s step start | each pulse start; pre-hit ones in the hold; runs down to 8 f (133 ms) apart; none for standing rules | earlier, and denser in runs |
| `fight.win`, `.lose`, `.tie` | after the last step | queue end + 24 | earlier after chains |

New motions with no cue today: lift, launch, contact flash, ×N count. Also: `delay_s` is wall-clock, so it will not follow the long-fight tempo or a slow film.

## 6. Contested choices

1. **Stop point.** Options: Battlegrounds' edge overlap (0.78 h near); today's 0.62 h; Galaxy's 0.2 to 0.57 h past the target's centre. **Pick: Battlegrounds near, deeper far, 0.35 h on the back row.** Second choice: today's 0.62 h near if the owner says it doesn't reach.
2. **Strike curve.** Constant speed (Battlegrounds); ease-in, fastest at contact (today, Galaxy). **Pick: constant.** The weight comes from the still hold and the dead stop, not the curve. At 87 px a frame on the longest attack it may strobe; only the owner's eye can say.
3. **Effects before the hit** (Thorns, Fury, Rally, Gate Warden, pile-ons). In the raised hold; at contact (attacker frozen there, today); after the attacker is home. **Pick: in the hold.** It is the log's own order, it removes the mid-motion pause, and a Thorns or pile-on kill shows as an attack that never lands.
4. **The next attacker during a chain.** Lift at +36 and hold as long as needed (Battlegrounds, up to 220 f); wait until the queue clears, then do the whole wind-up; lift early but cap the hold. **Pick: early lift, hold capped near 48 f.**
5. **Repeats.** Battlegrounds: in sequence, ~2× acceleration, no counter (10 cycles ~7.8 s). Owner's 18 Nov ask: grouped, accelerating, ×N. **Pick: the owner's: 0.7× per item from the third, floor 8 f, ×N.** Here the stance is wrong: Battlegrounds' long chains are what the owner complained about.
6. **What speeds up.** A general queue rule (the fix-round's 1.6× when more than 4 steps wait); per-run acceleration plus a late-fight tempo; none. **Pick: per run plus the late-fight tempo from attack 13**, with a 3-second cap per queue. Most of our fights are 7 to 14 attacks, so the tempo rarely shows.

## 7. What it gives up, and what only the owner's eyes can judge

**Gives up:**
- Plain attacks take 25 % longer (0.95 → 1.18 s). Fights with few triggers run longer overall.
- Straight-across travel is shorter than today's (100 px against 140).
- No pull-back or tilt, so no anticipation along the line of attack. The wind-up is all scale and stillness.
- No Galaxy-style card pop-up and no Battlegrounds enlarged card beside the board for Start of Combat (R1's T6 took 120 f per trigger). Our openings can have 5 or more sources, so in-place pulses grouped by mechanic stay shorter.
- The ×N counter, the stop cap and the hold cap are not Battlegrounds.

**Only the owner's eyes:**
- Whether an 18-frame dead-still hold reads as "clearly visible" or as a stall.
- Whether ×1.15 reads as rising toward the camera on a flat glass board. It leaves 1.5 px to each neighbour.
- Whether a constant-speed strike feels heavy or mechanical, and whether 53 to 87 px a frame strobes on real hardware.
- Whether the 100-px straight-across hit reads as "all the way".
- Whether a death falling during the next attacker's lift reads as two things or as clutter.
- Whether a back-row hit through the front row reads as hitting the back-row card.
- How the warm ring, impact light, streaks and ×N look in lead and glass: all stand-ins until the art pass, and new card-face elements need the owner's yes first.
- The run curve (0.7×, floor 8): whether ×10 reads at the end.
