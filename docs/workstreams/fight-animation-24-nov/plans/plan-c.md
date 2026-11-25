# Plan C: weight and drama for lead and glass (24 Nov 2026)

One of three independent plans. Stance: cards are heavy leaded glass panels. Give the motion weight (anticipation, impact, follow-through), use Galaxy's big wind-up and deep overlap where they help, give hits and deaths a glass character (light, crack, ring), and keep fights from dragging. **Nothing here is decided, and no motion in it has been watched.** Numbers come from R1 (Battlegrounds), R2 (Galaxy and others) and R3 (ours); where a number is my guess, it says so.

Units: frames at 60 fps (f). H = our card height, 250 px (card 140 × 250). Our board: straight across front to front is **1.18 H**, a front-row diagonal two slots over is **1.69 H**, back row to their back row is **2.90 H**, and the farthest diagonal is **3.14 H**. C = the contact frame. All times are at tempo 1; the speed-up rules in section 2 scale them.

**Where my stance is wrong, and why.** Galaxy's 0.58 H pull-back does not fit: our rows are 8 px apart, so a front-row card pulling back 145 px covers its own back row. Galaxy's past-centre stop does not fit either: our tall hexagon would cover the target's art and Health completely at the moment the number changes. So the weight here comes from Battlegrounds' raised hold and from scale and light, not from Galaxy's distances. Drama also has to stay cheap: a 2026 Battlegrounds fight gets faster as it goes on, and the owner's 18 Nov rule warns against "wildly disparate" lengths.

## 1. The basic attack

| Phase | Frames | Motion | Easing | Near (1.18 H) / straight / far (2.9–3.14 H) |
|---|---|---|---|---|
| **Lift** (wind-up) | **10** | Scale 1.00 → **1.18** (toward the camera). Pulls back **0.08 H (20 px)** away from the target. Lean: on a straight attack, 3° with the top away from the target; on a diagonal, it turns to aim at the target, up to 10° (a guess). The glass brightens ×1.0 → ×1.3 and the lead outline gets an amber rim glow, the "ready" mark (our version of Battlegrounds' red ring). The target's lead pulses faintly once, so a back-row or diagonal target is clear before the strike. | cubic ease-out | same at every distance |
| **Hold** | **14** (at least 8 when something plays in it) | Dead still, raised. The glow keeps rising slowly. Things the rules resolve before the hit play here, and the hold stretches to fit them (section 2). | — | same |
| **Strike** | **7 / 8 / 9 / 10** for ≤1.3 / ≤2.0 / ≤2.6 / >2.6 H | Straight line to the stop point. Scale stays 1.18, and the lean springs back to 0. It passes over the front row on a back-row target: the lift already reads as "above the board". | power 1.6 ease-in: first frame ≈0.3× the average speed, last frame ≈1.5× | near: 170 px in 7 f (avg 24 px/f); far: 620 px in 10 f (avg 62 px/f) |
| **Stop point** | — | Centres **0.50 H** apart near and **0.42 H** apart far (straight line between them). That is a 50–58 % overlap on a vertical attack. Today's is 0.62 H (38 %); Battlegrounds' edges overlap 15–30 % of its portrait. The attacker is drawn on top. | — | gap shrinks linearly from 0.50 H at 1.3 H to 0.42 H at 2.6 H |
| **Contact** | **2** on screen (C, C+1) | On frame C the attacker pops 1.18 → **1.24** (Battlegrounds measured 1.24–1.28). The target's glass flashes white-gold (×1.8 brightness, decaying over 8 f). A **lead crack** (a starburst of lead lines) appears at the point of contact on the target, sized by damage ÷ maximum Health. It stays to C+12 and fades by C+24; on a lethal hit it stays and spreads (see deaths). No hit-stop: R2 found none in any game. | — | same |
| **Return** | **12** near, **15** far, from C+2 | Straight home. Scale is back to 1.0 by C+8 and the glow fades over the return. Then a 2-frame "seat" (scale 1.0 → 0.98 → 1.0), the panel settling into its came. A guess for weight. | quart ease-out (≈25 % of the way on the first frame, like Battlegrounds' 30, 23, 19 … px) | home at C+14 near, C+17 far |
| **Target reaction** | **18**, from C+1 | Knocked **0.14 H (35 px)** along the attack line in 3 f, held 3 f, back over 12 f, with a damped "ring" of ±1.5° (2 cycles) while it returns. Today: 16 px. Galaxy: 0.35 H. A blocked hit moves 30 % as far and flashes blue. | ease-out out, cubic in-out back | same |
| **Number pop** | **44** on screen, from C+2 | Today's lead-and-red glass star with "−N": ×0.55 → ×1.25 in 3 f, settles in 5 f, readable 28 f, rises 16 px and fades in 8 f. Today it is on screen 32 f; Battlegrounds' stays about 60. | — | same |
| **Health change** | at **C+3** | Both units' Health swaps (the strike back too). The digit pops ×1.5 and settles over 14 f; the Health roundel's glass goes deep red for 10 f. At C+3 the target's roundel is still partly under the attacker, so it shows as the attacker pulls away. | — | same |

**From lift to contact:** 31 f near (0.52 s), 34 f far. Battlegrounds: 31–41. Galaxy: 30. Ours today: 12.

## 2. Ordering rules

**Principle: the swing never stops, and nothing waits mid-flight.** The rules' log splits each attack into three phases, and each phase has one place on screen:

1. **Before the hit** (everything logged after `attack` up to the exchange's first damage: Thorns, Fury and Gate Warden on being attacked, Rally and Drum on attacking, pile-ons, Hedge Lancer's flare) plays **in the attacker's raised hold**, in log order. The hold stretches to 8 + (those beats) + 6 frames. That keeps cause before effect: a Rally gain shows before the bigger hit lands, and Thorns that kill the attacker shatter it while it is still raised, which is the rule (an attacker killed first doesn't attack).
2. **The hit** (the exchange's damage, Cleave, strike back, `prevented`, a shield's `status`, and the Overrun and Venomous triggers between them) lands **on contact, together**. Cleave's neighbour lands at C+3, Overrun's spill at C+8. The strike back is never shown after Overrun or Venomous, even when the log writes it later (today it shows at +75 f). This is display order only; the end state is the same.
3. **After the hit** (after_attack, death passes, everything deaths cause, arrivals, out-of-turn attacks) starts at **C+14**, with the attacker home. It is a chain of **beats**. A beat is a cause flare (6 f), then a carrier (light or a lead line, 6–10 f), then a landing. Each beat has a **read point**: the frame its news is readable, about 8 f after it lands. The next beat in the chain starts at the previous beat's read point, not at its end, so the joins overlap a little (Galaxy G-T2).

**Where waiting goes.** Always in a still, raised pose: the current attacker's hold before it launches, or the next attacker's hold. The next attacker lifts **10 f before the after-hit queue reaches its last read point** (a plain hit's read point is C+38, a death's C+56). If something is still playing, it holds raised. But it never starts lifting while more than 20 f of queue are left. That is my change from Battlegrounds (T2 held 220 f): a raised card waiting that long competes with the chain for the eye.

**Speed-up.**
- **S1, per moment:** if one hit's after-hit queue is longer than 90 f, the beats after the first 60 f run at a tempo that rises linearly from ×1 to ×2 over the next 90 f, with a cap of ×2.
- **S2, combos** (the same source repeating) have their own acceleration (tree, node T2). The combined tempo is capped at ×3.5.
- **S3, long fights:** the lift, hold, strike and return scale ×1 for attacks 1–12, ×0.8 for attacks 13–20 and ×0.65 from attack 21. Battlegrounds' long 2026 fights shrink lift, hold and strike from 10/21/7 to 6/9–12/4–5 f. Basing this on the attack count is a guess: the footage can't show what causes it.
- Skip stays as it is.

## 3. The decision tree

Read each row as "if this event (in this case), then…". "Rides" means it costs no time of its own: it plays inside the beat that caused it. The **fight frame**, **attacks** and **the exchange** come first, because every other branch hangs off them.

### F. Fight frame

| Node | If… | Shown | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|---|
| F1 `combat_start` | always | Boards settle in: the enemy front row drops into place, then the back row, 4 f apart, with a glint along the lead | fight start | the first Start of Combat beat or the first lift | once | 0.8 s (today 0.7) |
| F2 `pass` | a side can't attack | nothing | — | — | — | 0 (no step even if a lunge is showing: the attacker is already home) |
| F3 `combat_end` | always | The result as today (the fix-round proposal's plates are a separate choice) | after the last read point + 10 f | — | once | 1.5 s |
| F4 `instead_of_attack`, fight `counter` | can't happen today (no card uses them) | no branch. If one ever appears, it falls back to node U1. | | | | |

### A. Attacks

| Node | If… | Shown | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|---|
| A1 `attack`, in turn | always | Section 1 | after the last attack's queue (section 2) | the after-hit queue | — | 31–34 f to contact |
| A2 the same unit attacks again (Windfury, Oakfeller after a kill, Tourney Champion's next target) | its previous attack's after-hit queue is empty or done | Its return stops halfway; it re-lifts in 6 f, holds 8 f and strikes. A "×2" lozenge (lead frame, amber glass) pops on it. | at C+8 of the previous attack, or at the queue's last read point | — | Tourney N targets: each repeat's hold shrinks by 2 f (to 4 f at the least), and the lozenge counts up | about 20 f less than a fresh attack |
| A3 a different unit attacks out of turn (Air Marshal's reservist, Needle Sister, Hand-me-down → Sister) | always | Its cause's beat flares first, then a full lift with an 8 f hold | at the cause beat's read point | the rest of the chain | nested attacks run in log order, each with its own three phases | 29–32 f to contact |
| A4 `trigger` from the next attacker, just before its `attack` (Hedge Lancer, Guard or Sortie marks) | always | The flare becomes the lift's glow (gold ward light for Lancer); the mark flares during the hold | with the lift | — | — | rides |
| A5 `hit`, a pile-on during an attack | always | In the attacker's hold, each piler jabs 0.35 H toward the target in 4 f, in reading order **5 f apart**; its hit lands with its own small star; "×2 … ×4" counts on the target. The attacker launches 6 f after the last piler lands. The pilers slide home as the attacker strikes. | the hold | the attacker's launch | up to 4 | hold + 5 × (N−1) + 6 f |
| A6 `hit`, outside an attack (Ballista at Start of Combat, Weasel on an arrival) | always | A beat: the source flares, a lead line with a lit core draws to the target (8 f), and a small spike of light lands | as a beat | the chain | Ballista's "times": combo T2 | about 26 f to the read point |

### X. The exchange (the hit itself)

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| X1 `damage` from the attack | lands | Section 1 (crack, flash, knock-back, star, Health) | C | — | Cleave: neighbour at C+3, knocked sideways | 0 |
| X2 `prevented` + shield `status` | blocked | At C a small pane over the card breaks into 5–6 shards, with a blue flash, a "0" star and a 30 % knock-back. Takes-no-damage (Lancer) shows the "0" only. | C | — | with the hit | 0 (today +23 f) |
| X3 `destroy` (Venomous) and its `status` | lands | At C the target's glass darkens from the contact point outward, green-black, over 10 f; a star with no number. The death follows in the pass. | C+2 | the death pass | rarely more than one | 0 |
| X4 effect `damage` during the hit (Overrun) | lands | A chevron of light runs out of the target to the next enemy (6 f), which gets crack, star and Health change | C+8 | — | Overrun repeats while damage is left: each hop 6 f after the last | 6 f per hop |

### T. Triggers and effect damage (after the hit, or at Start of Combat)

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| T1 `trigger` + its effect, once | — | One beat: the source lifts 0.05 H toward the camera (scale 1.06), its glass lights from behind in the tribe's tint (6 f), the effect's carrier leaves it (a lead line with a lit core for damage, a gold light running down the lead for buffs), it lands, and the flare ends at landing. The trigger never has a step of its own. | the previous beat's read point | the next beat | — | about 26 f to the read point (today 19 + 34 f) |
| T2 the **same source** fires the same mechanic again in a row (combo: Ballista times, the same Gleaner for each death) | 2nd repeat and after | Each repeat comes at ×1.3 the tempo of the last, up to ×3.5. A "×N" lozenge over the source pops with each landing; the last one holds 18 f. | at the last repeat's landing (not its read point) | the next beat | 10 repeats: 26, 20, 15, 12, 9, then 7.4 × 5 f, plus the 18 f hold | ≈137 f for 10 (today 530) |
| T3 **different sources**, the same kind at the same moment (N Gleaners or Plagues after one death, Standard-bearer's Mice, Grow at Start of Combat) | 2 or more | A wave: sources flare in reading order 4 f apart and their carriers fly together | one beat | the next beat | stagger capped at 24 f in all | one beat + 4 × (N−1) f |
| T4 one source, **many targets** (Orchard Stripper, Lieutenant's row, Avenge) | 2 or more | One flare, then landings ripple in reading order 3 f apart | one beat | — | — | one beat + 3 × (N−1) f |
| T5 Start of Combat | always | The same beats, in rules order; T3 groups same-mechanic units (Grow, Standard-bearer, Colour Ensign). Tourney Champion attacks by A1 or A2. | after F1 | the first lift | — | per beat |

### U. Changes on a unit

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| U1 `buff` | — | Gold light runs down the lead into the card (6 f); the Attack and Health roundels swap with a pop and a gold flash; a small gold "+N" rises | the carrier's landing | — | T3 or T4 | rides on its trigger, or 12 f alone |
| U2 `stats` (auras, Lends, the Swarm, Renown) | — | Numbers tick over with a soft pulse in the roundel; no flare | the frame of the cause | nothing | all at once | rides (0) |
| U3 `effect`, `keyword`, a non-shield `status` (Molt or Root used, Stealth ending) | — | The pill appears, changes or dims with a glint | with its cause | — | all at once | rides |
| U4 `uses` | — | One pip dims as the ability fires | with its trigger's flare | — | — | rides |

### P. Player numbers (your plates only; the opponent's aren't on screen, so they get nothing)

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| P1 `player_counter` (Tide) | your side | A glass bead flies from its source to the Tide plate (8 f); the plate pops; the Locusts' `stats` (U2) ride on its landing | with its cause | — | beads 3 f apart; the plate counts up | rides |
| P2 `heap_add` (a Seed into the Compost) | your side | A seed-shaped shard leaves the shattering card and drops into the plate | at the shatter | — | with the shards | rides |
| P3 `heap_remove` (Root pays) | your side | A shard leaves the plate for the returning slot | starts the Root return (I3) | I3 | once per return | rides |
| P4 `heap_use` (Old Stump, Elder Mother) | your side | The plate glows; a ghost pane flies to the slot where the summon appears | right before its summon | the summon | — | 8 f |
| P5 `slot` (Colour Ensign) | — | The slots' Renown banners glint in reading order, 3 f apart | its Start of Combat beat | — | wave | rides |
| P6 `renown` (earned for the next fight) | — | A gold mote flies from the kill to the slot's Renown pill, which glints. Its number doesn't change (the rule: it counts from the next fight). | at the shatter | — | with deaths | rides |
| P7 `gold` (Cutpurse) | your side | A small gold "+1" coin glint rises off the Cutpurse | with its hit | — | — | rides |
| P8 `summon_failed` | Hopper with no room | A faint ghost Hopper flickers over the source and becomes a P1 bead | with its cause | — | wave | rides |

### D. Deaths

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| D1 `death`, one unit | killed in the exchange or by a beat | **The glass breaks.** The lead crack spreads across the card's lead (6 f), with a bright flash through it, then the card splits into 6–8 shards that fall away from the killer's line, turning, and fade (24 f). The slot stays empty, as today. A killed attacker shatters at home. | crack at C+18 (killed in the exchange), or at its beat's landing + 10 f | death effects start at the shatter (C+24) | — | next lift at C+46 (today C+37 + 19) |
| D2 several in one pass | 2 or more | Shatter in reading order, 3 f apart, capped at 12 f in all | as D1 | as D1 | one `fight.death` sound per pair | D1 + ≤12 f |
| D3 the dying unit's own effect (Seed, Brood Mother, Hand-me-down, Bitter Toad, Orchard Stripper) | — | Its shards glow in its tint as they fall; the carrier leaves from the shards | at the shatter | the chain | T2–T4 | one beat, starting at the shatter |
| D4 another death in a later pass | — | D1 again from its beat's landing | — | — | loops through the tree | per pass |

### I. Arrivals

| Node | If… | Shown | Starts | Waits | Repeats | Cost |
|---|---|---|---|---|---|---|
| I1 `summon` | — | The card drops in from 0.3 H above at scale 1.1, lands with a glint along the lead and a light seat (14 f) | its cause's read point | its on_fight_enter (Weasel → A6, Air Marshal → A3) | **wave: 4 f apart**, any number | 14 + 4 × (N−1) f |
| I2 `reserve` | — | It rises from below the screen (from your hand; the opponent's comes down from above) into the slot and picks up the slot's Renown with a glint (16 f) | 10 f after the shatter | as I1 | up to 2 | 16 f |
| I3 `return` | Molt | The broken pieces hold together as a husk, light grows inside, and they fall away to show the copy (18 f); its `buff`, `uses` and `keyword` ride | instead of D1's falling shards | after_friendly_return (T1) | one per dying unit | 18 f |
| I3 `return` | Root | Green lead lines grow up the empty slot and the card regrows from the bottom up (20 f); P3 rides | instead of D1's falling shards | as above | | 20 f |

## 4. Time budget

From one lift to the next (R3's measure). Today's numbers are R3's films; Battlegrounds' are R1's.

| Case | Today | Plan C | Battlegrounds |
|---|---|---|---|
| Plain attack | 57 f (0.95 s) | **59 f near, 62 far** (1.0 s): contact at 31–34, next lift at C+28 | 76–83 f |
| Attack with a death | 67 f | **77–80 f** (1.3 s): next lift at C+46 | 150–165 f |
| Attack with a pre-hit trigger (Rally) | 124–139 f | **75 f**: the hold is 30 f, and there is no pause at contact | — |
| Divine Shield | 76–86 f | **59–62 f** | — |
| A chain: the kill summons a Hopper (+1 Tide), then a Gleaner answers the death | about 161 f (lunge 14, splash 34, death 19, trigger 19, summon 22, trigger 19, splash 34) | **about 95 f** (1.6 s): shatter C+24, Hopper lands C+44, Gleaner flares at C+52 and lands C+66, next lift C+64 | 200+ f |
| A trigger repeated 10 times | 530 f (8.8 s) | **about 137 f** (2.3 s) for the combo | ~71 → 32 f per cycle (×2) |

Plain attacks get slightly slower (+2 to +5 f). Every case with something in it gets faster, because triggers overlap their cause instead of taking a step each. A fight of 8 attacks with 3 deaths and 2 chains goes from about 14 s to about 11 s (an estimate).

## 5. Sound: cues that would move (not retimed here)

- `fight.hit.light / medium / heavy`: today they play at C+3 (the start of the splash step). They would play at **C**, fired from the motion, since contact now falls inside a beat. Measured from the start of the attack, contact moves from frame 12 to frame **31–34**. With a shield or Rally, the hit moves **22–41 f earlier** relative to contact, because nothing pauses there now.
- 3+ hits (Cleave, area): the visual stagger becomes 3 f (50 ms) per landing, close to today's takes at 0, 28 and 58 ms.
- `fight.hit.blocked`: to C (today C+3, or C+22 with a shield step).
- `fight.destroy`: to C+2.
- `fight.death`: today at the start of the fall (C+37). It would sit on the **shatter frame, C+24**: 13 f earlier, and 6 f after the crack starts. Deaths stagger 3 f apart, close to today's 55 ms second take.
- `fight.summon`: today frame 1 of the fade. It would belong on the landing, **about 10 f** into the 14 f drop. Waves are 4 f (67 ms) apart.
- `fight.trigger`: moves from step starts to each flare. Waves are 4 f apart, which is under the cue's `min_gap_s` of 0.08 s, so some flares in a wave would be silent. Combo repeats come at 26 down to 7.4 f, so the last ones are faster than one cue per repeat allows.
- `fight.win / lose / tie`: unchanged.
- New moments with no cue today: the lift, the shield break, the crack spreading and the glint on landing. Retiming or adding cues is for the sound workstream.

## 6. Contested choices

1. **Stop point.** Battlegrounds stops shallow (edges overlap 15–30 %); Galaxy goes past the centre; today's gap is 0.62 H. **Pick: 0.50 H near, 0.42 H far.** It clearly "goes all the way", the cards are covered for only 2–4 frames, and the target's Health shows as the attacker leaves.
2. **Strike speed curve.** Battlegrounds is constant speed with a scale pop; Galaxy and today ease in hard. **Pick: a mild ease-in (power 1.6) plus the pop:** a heavy panel gathers speed, but a hard ease-in spends half the strike nearly still.
3. **Triggers before the hit.** Pause at contact (today; the owner rejects it), or move them all to contact, or play them **in the raised hold (pick)**. The hold keeps the rules' order, including a Thorns kill before the attack. Contact-only is faster but shows the Rally gain at the same moment as the hit it changes.
4. **The next attacker during a long queue.** Battlegrounds lifts it and holds it raised for as long as needed (220 f seen). **Pick: lift only when ≤20 f of queue are left.** Cost: the "who's next" signal comes later.
5. **What speeds up.** A global tempo from queue length only, attack count only, or **both, split by scope (pick: S1 per moment, S2 combos, S3 attack count)**. The attack-count rule is a guess, and it makes late attacks feel different from early ones.
6. **Deaths.** Today's quick fall from C+37, Battlegrounds' late shatter (C+40 to C+68), or **a glass break with a crack at C+18 and the shatter at C+24 (pick)**. It is the most "glass" moment in the fight, but it is a new visual element that needs an art pass.

## 7. What it gives up, and what only the owner's eyes can judge

**Gives up:**
- About 5 % on plain attacks against today.
- Strict log order for the strike back (shown at contact, before Overrun and Venomous). The replay must sort the exchange out of the log, and may need a damage `kind` field (own attack, cleave, strike back) if `from_attack` isn't enough. That is to be checked.
- Fixed timing: tempo varies by queue and by attack count.
- Build cost. Cracks, shards, light flashes, the husk and the root regrowth are **new visual elements**. Each needs a reference study, art direction and the owner's yes, and the shards need a shard mask per card frame. A cheaper fallback for any of them is today's motion with only the timing rules above.

**Only the owner can judge:**
- Whether the 14 f raised hold reads as weight or as lag.
- Whether a ×1.18 lift looks heavy or floaty on a 250 px card.
- Whether the 1.6 ease-in hits harder than Battlegrounds' constant speed.
- Whether 50 % overlap reads as "all the way" or as hiding the target.
- Whether the knock-back and ring read as struck glass or as wobble.
- Whether the shatter reads clearly at a glance or is noisy in a pass of three.
- The combo's pace, and whether ×10 is readable.
- Whether the light and glint effects feel like glass or like generic effects.
- Whether lifting late (choice 4) loses the "who's next" read.
- The whole fight's rhythm at full frame rate on real hardware, which no film here shows (`docs/AGENT-BLIND-SPOTS.md`, items 1 and 3).
