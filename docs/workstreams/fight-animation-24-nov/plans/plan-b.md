# Plan B: the fastest fight that still reads (24 Nov 2026)

Stance given: keep all four of the owner's points (full travel, varied speed, no mid-motion pause, a clear wind-up), and spend as little time as possible everywhere else by overlapping what can safely overlap, grouping repeats hard, and keeping long fights short.

All numbers are at 60 fps. h = one card height = 250 px on our 1920 × 1080 stage (card 140 × 250). On our board an attack spans 1.18 h centre to centre (front row straight across) to about 3.15 h (back row to the far back row, diagonally). C = the contact frame. Numbers come from R1–R3 unless marked **guess**. No agent can judge motion by eye (`docs/AGENT-BLIND-SPOTS.md`), so every "reads" below is a prediction.

**Where the stance is wrong, and I changed it:**
- **The wind-up is where a fast plan has to spend, not save.** The owner asked for a "very clearly visible" wind-up. Every game measured uses 12 to 33 frames for it (Battlegrounds 24–33, Galaxy 13–14 plus a ×1.4 scale-up, Runeterra ~12). Our 4 frames is the outlier. So Plan B lengthens it from 4 to 22 frames, and saves the time by making the wind-up do a second job: all waiting happens inside it.
- **Our stop point already goes "all the way".** We stop with centres 0.62 h apart. Battlegrounds stops 0.8–1.0 h apart for a target straight across, and we already go further than that. What reads as stopping short today is more likely the 4-frame wind-up, the ease-in (24 % of the path in the last frame) and the 5-frame wait at contact. I make the stop slightly shallower for near targets and deeper for far ones (Battlegrounds' rule: far attacks arrive at speed). That is a guess about what the owner sees.

## 1. The basic attack

| Phase | Frames | Motion | Curve | With distance |
|---|---|---|---|---|
| **Lift** (wind-up, part 1) | **8** | Scale 1.00 → 1.14. Pulls back 0.06 h (15 px) away from the target, so the aim shows. Leans ≤ 4°. The lead lights and the glass glows (our "red ring"). | quad ease-out | same at every distance |
| **Hold** (wind-up, part 2) | **14 base**; stretches to absorb anything queued (section 2); 8 at most queue speed-up | Dead still, raised and lit. No drift. | none | same |
| **Strike** | **clamp(round(4.5 + 1.4·d), 6, 9)**: 6 f near (1.18 h), 8 f diagonal (2.2 h), 9 f far back row (3.15 h) | Straight line, drawn above every other card. Scale stays 1.14. | **linear** (constant speed), as Battlegrounds | 22 px/f near, ~75 px/f far. The duration grows a little with distance and the speed grows a lot. Battlegrounds is 5 to 68 px/f |
| **Contact (C)** | 1 frame, **0 held** | Stops with centres **g = clamp(0.70 − 0.10·(d − 1.18), 0.50, 0.70) h** apart along the line: 0.70 h near (edges overlap 0.30 h), 0.60 diagonal, 0.50 far. Scale pops to 1.22 on C. A warm white flash on the target's glass from C to C+3. | — | far attacks bite deeper |
| **Return** | **12**, from C+1 | Straight home. Scale is back to 1.00 by C+6. 96 % home at C+8. | cubic ease-out (fast first) | same 12 f; speed scales with distance |
| **Target reaction** | C → C+3 knock, still to C+5, settle 10 → home C+15 | Knocked 0.10 h (25 px) along the attack line, turns 4°, lit warm and fading with the settle. A blocked hit moves 30 % as far and is lit blue. | linear knock, cubic ease-out settle | same |
| **Number pop** | appears C+1; pop 3 f to ×1.18, settle 4; readable to C+34; rises and fades over 8; gone C+42 | Today's lead-and-glass star with "−N", on every card damaged in the exchange (target, strike back, Cleave neighbour) | as today | same |
| **Health change** | C+1 | Digit swaps on both cards in the same frame as the star, with a ×1.5 pop that settles over 12 f. Disc tinted red C+1 to C+20. | — | same |
| **Death** (if lethal) | starts **C+14**, 15 f, gone C+29 | Today's fall: drops 48 px, turns 16°, shrinks to ×0.72, fades | quad ease-in | same |

The attacker's own motion: 8 + 14 + 6..9 + 12 = **40–43 frames** (today 28). Contact comes 28–31 frames after the first motion (today 12). The speed changes four times: a slow lift, a dead stop, a fast linear strike, a one-frame stop, then a fast-then-slow return. That is the owner's "they don't move at a consistent speed", as Battlegrounds actually does it (R1 claim b). Constant speed inside the strike follows Battlegrounds. Galaxy and today's build ease in instead (contested choice 4).

**The next attacker** starts its lift at **C+8**, while the previous attacker is 96 % home. A card that is still reacting to the hit waits until C+12. The lift happens in place, so it overlaps a return or a death without two things crossing the board at once. The next strike launches at the **launch gate**: `max(lift_start + 8 + hold, last blocking item's end + 6)`. Blocking items are anything that moves across the board or changes the board: deaths, arrivals, trigger flares, carriers in flight, a combo's final hold. Stars, number pops and settles never block.

## 2. Ordering rules

**Principle: once a card starts to move it never stops until it is home. What the strike causes lands at contact. What the outcome causes plays from C+14, while the next attacker is already lifting. Every wait happens in that attacker's raised hold.**

1. **Nothing pauses mid-motion.** The strike and return always run unbroken, at any queue length. Today's waits at contact (23 f for a shield, 41 f for a Rally gain) are removed.
2. **The screen may reorder what the rules log, but only inside a moment, and only so that each card's shown numbers stay true.** A moment runs from one strike's launch to the next. The rules core logs in resolution order (`combat.gd` `_attack_steps`: on_attacked, on_attack, joiners, exchange, after_attack, deaths). The replay groups the log into three windows:
   - **Before the hit** (logged between `attack` and the exchange's first `damage`): played **in the hold**, before the strike launches. The hold stretches to fit them, so the hit's numbers already include them.
   - **At the hit** (the exchange, its Cleave, its strike back, and what fires inside `_damage`: Venomous, Overrun): played **at contact**, all from C+1. The Cleave neighbour lands 2 f later and the Overrun target after its carrier.
   - **After the hit** (after_attack, deaths and everything they cause): the **after-queue**, from C+14.
3. **Within the after-queue:** a trigger whose effect touches a card that an earlier queued item also touches waits until that item **lands**, not until it finishes. Otherwise up to 3 run together, 4 f apart (contested choice 2). Death passes stay in rule order: a second pass starts when its cause lands.
4. **Nested and extra attacks** (Air Marshal, Needle Sister, Oakfeller, Windfury, Tourney Champion) take the "next attacker" slot. Each starts its lift when the blocking items ahead of it are within 8 f of done, so its hold absorbs the tail. The normal attack order resumes only after the nested attack's own after-queue.
5. **Queue speed-up.** When a moment has more than 6 blocking items still to come, flares, carriers, gaps and holds play at `min(1.5, 1 + 0.1·(n − 6))`× speed. This never applies to strike frames, never takes a death fall under 10 f, and never takes a combo gap under 4 f. The speed returns to 1× at the next launch. There is no fight-length ramp (contested choice 6).

## 3. The decision tree

Every one of R3's 29 event types appears once below. **Blocking** items push the launch gate; **riders** cost 0 frames and show on the frame their cause lands.

```
EVENT
├─ combat_start ─────────── boards rest 24 f, then the first attacker lifts (first contact ~0.9 s; today 0.7 s + 12 f)
├─ combat_end ───────────── result text when the last blocking item ends + 6 f; 1.5 s hold as today (its look is other work)
├─ pass ─────────────────── nothing, 0 f
├─ instead_of_attack, counter ── no branch: no card can produce them (R3)
│
├─ attack ───────────────── the basic attack (section 1)
│   ├─ takes_no_damage (Hedge Lancer, `attack_now` flag) → same motion, the lift lit blue; "0" on the attacker at C+1
│   ├─ out_of_turn, nested (Air Marshal reservist, Needle Sister, Tourney Champion) → takes the next-attacker slot (rule 4)
│   ├─ the same unit again (Windfury, Oakfeller after a kill) → second lift from mid-return at C+6, hold 8, "×2" by the card
│   └─ several in a row (Tourney Champion's N targets) → each after the last, hold 8, ×k by the card; strike frames unchanged
│
├─ logged BEFORE THE HIT (window 1: played in the hold)
│   ├─ trigger → buff | effect | keyword (Fury on attack or on being attacked, Gate Warden, Rally, Drum)
│   │        → source flare 6 f (lifts 0.04 h, glows), then the numbers or pill change 6 f; ripple 4 f apart if several
│   │        → the hold grows only past 14 f: 1 trigger free, 2 = +2 f, 3 = +6 f
│   ├─ trigger → damage to the attacker (Thorns)
│   │   ├─ not lethal → thorn burst on the attacker at C+1, together with the exchange; 0 f
│   │   └─ lethal (the core ends the attack: no exchange) → the attacker still strikes; at C only the thorn burst;
│   │            it returns and dies at C+14; the target shows no star
│   ├─ pile-on: uses → trigger → hit → damage (×up to 4)
│   │   ├─ pilers jab in the hold (60 % of their lunge in 4 f), staggered 3 f apart, each burst landing as it jabs; ×2…×4 on the target
│   │   │        → the hold grows to max(14, 4 + 3·(n−1) + 4): n = 4 is +3 f; then the attacker strikes last
│   │   ├─ Cutpurse's after-hit gold → rider: a coin flies to the portrait, 8 f, not blocking
│   │   └─ the target dies to the pilers (no exchange) → the attacker does not launch; it lowers in 6 f;
│   │            the target dies at the last jab + 14; then after_attack goes to the after-queue as usual
│   └─ status: Divine Shield logged before its `prevented` → moved to contact: the pill shatters at C, "0" star, blocked knock
│
├─ AT THE HIT (window 2: from C+1, one frame for all)
│   ├─ damage (exchange), damage (strike back) → stars and Health changes on both cards at C+1
│   ├─ prevented
│   │   ├─ absorbed (shield) or takes_no_damage → blue "0" star, blocked knock (30 %)
│   │   └─ only_attack_damage (Stag Beetle, against effect damage) → "0" where that effect lands
│   ├─ Cleave damage → neighbour's star C+3, knocked sideways 0.06 h; a red arc from target to neighbour 3 f
│   ├─ Venomous: trigger → destroy → status → the target flashes green at C+1, a star with no number; pill dims; dies at C+14
│   └─ Overrun: trigger → damage (repeats while damage is left)
│            → chevrons from the target to the next enemy, 6 f per hop, a star on arrival; 2+ hops: ×2, ×3; blocking
│
├─ AFTER THE HIT (window 3: the after-queue, from C+14)
│   ├─ death
│   │   ├─ one pass → all fall together at C+14 (15 f); a sound for each fall, at most 2
│   │   ├─ a later pass (deaths from effects) → when its killing effect lands + 14
│   │   └─ the attacker dies (strike back, Thorns) → the same: it is home at C+13 and falls at C+14
│   ├─ trigger (any: after_attack, kill, any death, death effect, after a friend dies, after_death_round)
│   │   → source flare 6 f; it may flare on a card that is still falling
│   │   ├─ its effect lands on other cards → carrier 8 f (a lead line with a lit core, or a glass shard) → lands
│   │   ├─ its effect is on the source itself → no carrier, lands at the end of the flare
│   │   ├─ the same mechanic N times, from one source or from several (Glean, Plague, Gleaners, Ballista "times", Lieutenant)
│   │   │   ├─ N ≤ 2 → each in full, the second 6 f after the first lands
│   │   │   ├─ N ≥ 3 → COMBO: gap k = max(4, 14·0.75^(k−1)) f; carriers may fly at once; one target hit again and again
│   │   │   │          keeps ONE star that re-pops with the running total; "×k" rises at the focus, growing 6 % a step;
│   │   │   │          "×N" holds 12 f at the end (blocking)
│   │   │   └─ N > 8 → 8 shown as above, then the rest land together in one beat; ×N with "!"
│   │   ├─ one effect on many cards (Standard-bearer, Avenge, Orchard Stripper, Lieutenant's row, Grow)
│   │   │        → one flare, then a wave in reading order, nearest first, 2 f apart; numbers change as it arrives
│   │   ├─ different triggers that touch no common card → together, 4 f apart, up to 3 (rule 3)
│   │   └─ one depends on the other (it touches a card the other changed) → waits for the first to land
│   ├─ effect payloads
│   │   ├─ damage (Glean, Plague, Lieutenant, Bumblebee, Orchard Stripper, death damage) → carrier, star, Health at landing
│   │   ├─ destroy (Bitter Toad) → carrier, star with no number, death 14 f later
│   │   ├─ buff → at landing: "+a/+h" rises from the card, digits pop
│   │   ├─ hit outside an attack (Weasel on an arriving enemy, Ballista) → the hitter jabs in place 0.08 h in 4 f, carrier 8 f, star
│   │   ├─ summon (death effects, Hoppers, Cousin, King Speck, Elder Mother, Old Stump)
│   │   │        → drops into its slot from 0.15 h above in 10 f, landing with a thump scale of 1.06; several 3 f apart, as one wave
│   │   ├─ reserve → rises from below the board 12 f; may start once the fall in its slot is 80 % done
│   │   ├─ return (Molt, Root) → regrows in its own slot 12 f, starting 3 f before its death fall ends; the buffs after it are riders
│   │   └─ an arrival answered (on_fight_enter: Weasel, Air Marshal) → after the drop lands; an attack goes by rule 4
│   └─ nested attack from a chain (Hand-me-down → Sister) → rule 4
│
└─ RIDERS (0 f, shown on their cause's frame; never a step of their own)
    ├─ stats (auras, Lends, the Swarm, Renown) → numbers change the frame their cause lands (a lender's death: at its fall)
    ├─ status → shield at contact; Venomous spent at contact; Stealth ends when its unit lifts; Reborn/Root/Molt used at the return
    ├─ uses → the pip dims during its trigger's flare
    ├─ keyword, effect → the pill appears or updates when the carrier lands
    ├─ player_counter (Tide) → the plate ticks at the landing (your side only, as today); the Locusts' stats ride with it
    ├─ heap_add → a seed flies to the Compost plate, 8 f, during the fall; heap_remove → the plate dips at the return;
    │   heap_use → the plate pulses as the summon starts
    ├─ slot (Colour Ensign) → the Renown pills update in the start-of-combat wave
    ├─ renown → a small star pulse on the pill (it counts from the next fight)
    ├─ gold → a coin to the portrait, 8 f
    └─ summon_failed → a puff at the source, and the Tide tick for a lost Hopper
```

**Start of Combat** uses the same tree: for each priority, in the rules' order, one side's effects play as one ripple (sources flaring 4 f apart, disjoint effects together), and the deaths after each effect go into the after-queue. The first attacker lifts as the last Start of Combat effect lands.

**Time cost per branch** (added to a plain attack's cycle; estimates):

| Branch | Added frames |
|---|---|
| One before-hit trigger / two / three | 0 / +2 / +6 |
| Pile-on ×4 | +3 |
| Thorns, shield, Venomous, Cleave, strike back | 0 |
| Overrun, per hop | +6 |
| A death pass (any size) | +5 (the gate waits for the fall + 6) |
| A trigger with a carrier, alone | +14 plus its payload |
| A summon wave | +10 + 3 per extra arrival |
| One effect on n cards | +14 + 2·(n−1) |
| A combo of N | about 79 f at N = 10; never above about 90 f |
| A rider | 0 |

## 4. Time budget

Contact to contact in a steady run (= the cycle), at 1× speed.

| Case | Plan B | Today (R3) | Battlegrounds (R1) |
|---|---|---|---|
| **Plain attack** | lift at C+8, launch C+30, next contact C+36..39: **36–39 f (0.60–0.65 s)** | 57 f (0.95 s) | 76–83 f (1.3 s); late in long fights 34–38 |
| **Attack with a death** | fall C+14..29, gate C+35: **41–44 f (0.68–0.73 s)** | 67 f (1.12 s) | 150–165 f (2.5–2.75 s) |
| **Venomous attack** (filmed today) | destroy and strike back at C+1, deaths C+14: **41–44 f** | 124–139 f | — |
| **A chain:** a kill → a death effect summons → a Weasel hits the summon → it dies | death effect flare C+14, carrier to C+28, drop to C+38, Weasel flare and shard to C+52, the summon falls C+66..81, gate C+87: **~93–96 f (1.6 s)** | from the step holds, not filmed: 14+34+19+19+22+19+34+19 = **180 f (3.0 s)** | — |
| **The same trigger 10 times** (with one death at the end) | 14 + 10.5 + 7.9 + 5.9 + 4.4 + 5·4 = 63 f to the last landing, ×10 hold 12, the death +21: **~96 f (1.6 s)** on top of the attack | 10 × (19 + 34) = **530 f (8.8 s)** | T3: cycles from 71 down to 32 f, 10 cycles ≈ 500 f (8 s), no counter |
| **A whole 8-attack fight** (4 plain, 3 with a death, 1 chain) | 42 + 4·38 + 3·43 + 94 ≈ **417 f (7.0 s)** to the result | 14.1 s (the filmed stand-in fight) | — |

Every plain cycle lands between today's and Battlegrounds' long-fight speed. A chain costs 2–3 plain cycles, not 6, and a 10-trigger combo costs about 2.5 plain cycles. That is the owner's 18 Nov request for "not wildly disparate". The open risk: a fight half as long as today's may feel hurried (section 7). The single knob for that is the base hold: 14 → 24 f makes a plain cycle 0.8 s and changes nothing else in the tree.

## 5. Sound: cues that would move (not retimed here)

| Cue | Today | Plan B | Moves by |
|---|---|---|---|
| `fight.hit.light/medium/heavy` | C+3, and C is 12 f after the first motion | at C (it must fire from the motion, not from a step start: R3) | relative to contact: −3 f (−50 ms). Relative to the first motion: from 15 to 28–31 f (+0.22–0.27 s) |
| the same, with a shield or Rally before the hit | C+22 / C+41 | C | −22 / −41 f (−0.37 / −0.68 s) |
| the 3+ hits stagger (0, 28, 58 ms) | all hits at once on screen | Cleave neighbour at +2 f (33 ms) | the picture now staggers; the cue's takes nearly match |
| `fight.hit.blocked` | in the splash step | at C | as `hit` |
| `fight.destroy` | splash step after Venomous's trigger step (~C+37 measured) | C+1 | about −36 f (−0.6 s) |
| `fight.death` | C+37 | C+14 | −23 f (−0.38 s) |
| `fight.summon` | after the death step and a trigger step, ~C+75 | ~C+28 | about −47 f (−0.8 s) |
| `fight.trigger` | a 0.3 s step each, one after another | at each flare; up to 3 at once 67 ms apart; combo gaps from 233 down to 67 ms | combos fire faster than its `min_gap_s` of 0.08 s, so some will drop until it changes |
| `fight.win/lose/tie` | after the last step | the last blocking item + 6 f | earlier in absolute time, about half the fight |
| none today: the lift, the hold, carriers, the ×N counter | — | new motions with no cue | a new cue would be needed (not proposed) |

## 6. Contested choices

1. **When the next attacker lifts.** (a) Only when everything has settled, as Galaxy does. (b) During the previous one's aftermath, as Battlegrounds does at times (T1, D1). **Pick (b) at C+8:** it is the main saving, and the lift happens in place, so nothing crosses the board twice at once.
2. **Independent triggers: together or one at a time.** (a) Strictly one at a time (Battlegrounds, Galaxy). (b) Together when they touch different cards, 4 f apart, at most 3. **Pick (b).** It is the risk most likely to blur cause and effect, so it is capped at 3 and needs the owner's eye.
3. **Where a buff that happens before the hit is shown.** (a) In the hold, before the strike. (b) At contact, as the 20 Nov proposal draws Fury. (c) After the return. **Pick (a):** the star's number then matches the Attack you see, and it costs nothing while it fits in the 14 f hold.
4. **The strike's speed curve.** (a) Linear (Battlegrounds measured). (b) Ease-in, fastest at contact (Galaxy and today). **Pick (a)**, a guess: with a dead-still hold before it, a constant fast strike gives the sharpest change of speed. (b) is the fallback if contact feels soft.
5. **How much a death costs.** (a) Nearly free: the next strike waits for the fall + 6 f (+5 f per pass). (b) Its own beat, as Battlegrounds does (+40 to 65 f, about 70 f per death in the cycle). **Pick (a).** If kills get missed, the fallback is +12 f.
6. **A fight-length speed-up.** (a) Queue speed-up only, inside a moment. (b) Also shorten the hold late in long fights, as Battlegrounds 2026 does (lift 6, hold 9). **Pick (a)**, because the base is already near Battlegrounds' fast mode. Use (b) only if the bot soak shows many fights over about 20 s.

## 7. What it gives up, and what only the owner's eyes can judge

**Gives up:** Battlegrounds' long, theatrical hold (31 f against our 22) and its 60 f star read (ours 42). Strict one-at-a-time readability in big chains, where up to 3 disjoint triggers overlap. A death as its own dramatic moment. Galaxy-style full-size pop-ups of the card that fired (about 1.2 s each, too slow for this stance). Today's exact replay of the log order: the screen reorders within a moment, which needs a careful replay rewrite and tests that every card's numbers stay true.

**Only the owner can judge:**
- Whether 8 + 14 f reads as "very clearly visible", or needs Battlegrounds' 31.
- Whether a linear strike after a dead hold reads as "not a consistent speed".
- Whether the next attacker lifting during a death splits the eye.
- Whether a 4 f combo gap, the running-total star and ×N are legible, or just a blur.
- Whether three triggers at once are clear.
- Whether a 0.6 s plain cycle and a 7 s fight feel brisk or hurried.
- On real hardware: at 75 px per frame, one dropped frame in a far strike is a visible jump. A film can't show this (blind spot).
