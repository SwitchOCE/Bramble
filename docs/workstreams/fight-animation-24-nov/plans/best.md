# The best proposal: fight animation (24 Nov 2026)

Written after reading R1–R3 and plans A, B and C, and checking their claims against `fight_motion.gd`, `fight_screen.gd`, `combat.gd` and `assets/glass/layout.json`. Nothing here is decided or built. No agent has watched any of it move.

**Units.** Frames (f) at 60 fps. h = card height, 250 px on the 1920 × 1080 stage. **C** = contact, the first frame the attacker is at its stop. **M** = rests on measurement (R1 Battlegrounds, R2 Galaxy, R3 ours); **G** = a guess.

## 1. The proposal in five lines

1. **A wind-up you can see:** the attacker lifts toward the camera (×1.14 over 10 f, with today's small 12 px pull-back), then holds dead still for 16 f. All waiting happens in that raised hold.
2. **One straight strike:** constant speed, 7–9 f at any distance, so far attacks fly fast. It stops overlapping the target (today's 0.62 h near, deeper far), pops ×1.24 on contact, holds 0 f, and returns fast then slow.
3. **A moving card never pauses.** What the rules resolve before the hit plays in the hold. The exchange (both hits, Cleave, shield, Venomous) lands at contact. Everything after waits until the attacker is home.
4. **After the hit, one beat at a time, tails overlapping.** A death falls 30 f after the hit, so its number reads first. The next attacker lifts in place at C+28, under the aftermath.
5. **Repeats become a combo that speeds up** (gaps shrink ×0.75 down to 5 f, and everything after the 8th lands in one beat), so any chain is capped at about 1.6 s. A plain attack stays near today's length: 61 f against 57.

**Why this beats each plan:**
- **A** copies Battlegrounds: every plain attack gets 25 % longer (71 f), and Battlegrounds' long chains are what the owner complained about on 18 Nov.
- **B** is fastest, but drops a dead card at C+14 while its own number is still being read (B's star is readable to C+34), and its 36–39 f cycle is Battlegrounds' sped-up late-fight mode.
- **C** puts the waiting in the right place, but its weight comes from new art (cracks, shards, rim glow, husk), each needing an art pass and the owner's yes. Its 0.50 h stop covers the target's Health just as it changes.
- **This proposal** takes A's attack, C's rule for when the next attacker lifts, and B's grouping and riders, using only pieces the build already has.

**Plan claims checked against the code:**
- **B is wrong about lethal Thorns.** It shows the attacker still striking. The rules say it never attacks (`combat.gd` 419–422; `thorns.gd`: "An attacker it kills doesn't attack").
- **Stop point.** Today's near stop (centres 0.62 h apart) already goes deeper than Battlegrounds' (0.8–1.0 h; R1, R3). "Not reaching" more likely comes from the 4 f wind-up, the ease-in (24 % of the path in the last frame) and the ×1.04 scale. Battlegrounds' strike itself is constant speed; the speed changes between phases (R1).
- **Distances.** A's and C's match `unit_xy`. C's "rows 8 px apart" is the gap setting; rows are 0.86 h apart, and the enemy front row covers the back-row card's bottom 34 px.
- **No new damage field is needed (C's worry).** Strike back is the damage whose `source_uid` is the defender. Cleave is attack damage on a unit other than the target.
- **Showing the strike back at contact is safe** (B, C), ahead of Overrun and Venomous, which the log writes first: `_exchange` reads both amounts before dealing either.

## 2. The basic attack

| Phase | Frames | Motion | Curve | Basis |
|---|---|---|---|---|
| **Lift** | 10 (C−33 … C−24 near) | Scale 1.00 → 1.14. Pulls back 12 px (0.05 h) straight away from the target. Leans ≤4° toward it. Today's attacker glow (`.card.lunge`) and draw order (on top) come on at the first frame. | quad ease-out | length and scale M (Battlegrounds 9–11 f, ×1.14–1.16); pull-back, lean and curve G |
| **Hold** | 16 at least; stretches for anything before the hit; never under 8 for a re-strike | Dead still, raised | — | M (Battlegrounds 14–16 f in 2026, 21 f in 2020–25) |
| **Strike** | 7 f up to 1.4 h; 8 f up to 2.4 h; 9 f beyond | Straight line, above every card, through its own front row on a back-row attack. Scale stays 1.14. | **linear** | M (Battlegrounds 5–8 f, constant, any distance); 9 f for our longest is G |
| **Contact** | 1 f, **0 held** | Attacker at ×1.24 on C, back to ×1.14 at C+1. Today's hit light on the target from C. | step | M (Battlegrounds ×1.24–1.28, 0 f; Galaxy 0 f) |
| **Return** | 12 / 14 / 16 f (same distance bands), from C+1 | Straight home. Scale 1.0 by C+6. Glow off at home. | quart ease-out | M (Battlegrounds 9–16 f, fast first) |
| **Target** | from C | Knocked 20 px (0.08 h) along the line in 3 f, turns 4°, settles over 11 f. A blocked hit moves 30 % as far. | linear, then cubic out | G (Battlegrounds' flash hides it; Galaxy 0.35 h; ours 16 px) |
| **Numbers** | C+2 | Today's burst on every card the exchange damaged, with Health digits swapping (today's pop). Readable to C+30, gone by C+40 (today 32 f on screen). | today's | timing M (Battlegrounds +3 to +4, Galaxy +2 to +3); length G |
| **Death** | fall from C+30, 15 f | Today's fall | today's | G (Battlegrounds +40 to +68, today +37) |

**Where it stops.** The gap between centres, along the attack line, is **0.62 h for targets up to 1.4 h away, shrinking evenly to 0.45 h at 2.4 h and beyond**. Any back-row target gets **0.40 h**. Battlegrounds' far attacks also bite deeper (centres 0.4–0.65 h apart; M). The near number is today's, unchanged.

| Case (our board) | Distance | Travel | Strike | Speed | Return | Lift to contact |
|---|---|---|---|---|---|---|
| Straight across | 1.18 h | 0.56 h (140 px) | 7 f | 20 px/f | 12 | 33 f |
| Diagonal neighbour | 1.32 h | 0.70 h | 7 f | 25 px/f | 12 | 33 f |
| Two slots over | 1.69 h | 1.12 h | 8 f | 35 px/f | 14 | 34 f |
| Far corner, front row | 2.17 h | 1.68 h | 8 f | 53 px/f | 14 | 34 f |
| Front row to back row | 2.06 h | 1.66 h | 8 f | 52 px/f | 14 | 34 f |
| Back row to far back row | 3.14 h | 2.74 h | 9 f | 76 px/f | 16 | 35 f |

For comparison: Battlegrounds strikes at 5 px/f near and 68 px/f across its board, Galaxy takes 30 f from lift to contact, and today takes 12 f.

## 3. Ordering rules

1. **Nothing pauses once it moves.** A strike, return, fall or arrival always runs to its end.
2. **Each attack's log splits into three windows.** The screen reorders only inside a window, and only where every number shown stays true.
   - **Before the hit** (from `attack` to the exchange's first `damage`): plays **in the hold**. The hold becomes max(16, the last item's landing + 8).
   - **At the hit:** the exchange, Cleave, strike back, the shield's `status` and `prevented`, and Venomous. All land at C+2. Overrun hops start at C+8, 6 f each.
   - **After the hit** (after_attack, deaths and everything they cause): starts at C+14. Near, the attacker is home at C+13.
3. **A beat** (one trigger and its effect): the source pulses (today's trigger lift and glow, 6 f), jabs 0.08 h toward its target from f6 to f10 (today's jab motion, standing in for a drawn link, which needs art), and the effect lands at f12 (f6 on itself). The next beat starts at that landing + 6. One source on many cards is one beat, landing on all at once (M: Battlegrounds T3). Different mechanics play one at a time, in log order.
4. **Deaths.** A pass falls together: at C+30 when killed in the exchange, 20 f after the killing landing otherwise. A dead unit's effects start from its empty slot when the fall ends.
5. **Combo** (3+ back-to-back items with the same mechanic and effect, any sources): first item full (18 f to the next), each later gap 0.75 × the last, floor 5 f. From the 9th, the rest land together. A card hit again and again keeps one burst, which re-pops with the running total. The count holds 16 f at the end.
6. **The next attacker** lifts at max(C+28, queue end − 16) and launches at max(lift + 26, queue end + 4). Queue end is the last landing, fall end or arrival end. So it never sits raised for more than about 20 f during a chain (as in plan C).
7. **Speed-up.** If a moment's after-hit queue would pass 120 f, beats after the first 60 f play faster, rising to 1.5×. Strikes keep their frames; falls stay ≥10 f. No attack-count ramp: our fights are short, and lengths "shouldn't vary too much" (owner, 18 Nov). G.
8. **Extra attacks.** The same unit again (Windfury, Oakfeller, Tourney Champion) re-lifts from mid-return at C+8 in 6 f, holds 8 f and strikes. Another unit out of turn: a full lift once its cause lands. A nested attack finishes its own aftermath before the order resumes.

## 4. The decision tree

The full tree as data is `tree.json`; each node is one row here. **CB** marks a contested branch (section 6). A **rider** costs 0 f and shows on the frame its cause lands. Costs are frames added to a plain 61 f cycle.

**Fight frame**

| If… | Shows | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|
| `combat_start` | Boards as today (the accepted fix-round entry is separate work) | 0 | Start of Combat | once | 30 f rest before the first lift |
| Start of Combat | Beats in the rules' order. Same-mechanic units (Grow, Standard-bearer) form a combo or a single beat. Tourney Champion uses the re-strike. Lieutenant's row lands 5 f apart (accepted 21 Nov). Colour Ensign's `slot` is a rider. | after the rest | the first lift | rules 3, 5 | per beat |
| `pass` | nothing | — | — | — | 0 |
| `combat_end` | Result as today | queue end + 24 | — | once | 90 (1.5 s, as today) |

**Attacks**

| If… | Shows | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|
| `attack`, in turn | Section 2 (CB1, CB2, CB3) | rule 6 (CB6) | its three windows | — | 33–35 to contact |
| `trigger` logged before `attack` (Hedge Lancer) | Its pulse merges into the lift. `takes_no_damage` shows today's "0" burst on the attacker at C+2. | with the lift | — | — | 0 |
| Same unit again (Windfury, Oakfeller, Tourney) | Re-lift 6 + hold 8 + strike | C+8 | — | Tourney: hold −2 f per repeat, never under 4 | about −20 against a fresh attack |
| Out of turn, another unit (Air Marshal's reservist, Needle Sister, Hand-me-down → Sister) | Full lift, hold 8 base | its cause's landing | the rest of the chain | in log order, nested | 31–33 to contact |

**Before the hit: played in the hold (CB4)**

| If… | Shows | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|
| `trigger` → `buff` / `effect` / `keyword` (Fury, Gate Warden, Rally, Drum) | Pulse on the source, numbers pop at the landing | hold f0 | the strike | each a beat | 0–4 (fits in 16) |
| Thorns `damage`, not lethal | Defender pulses; burst on the raised attacker | hold f0 | the strike | — | 0–4 |
| Thorns kills the attacker | Burst, then it falls from its raised pose. **No strike** (the rules' outcome) | as above | its death effects | — | the hold + fall |
| `hit` (pile-on) with its `uses` and `trigger` | Pilers jab in reading order, 5 f apart (today's jab); target's burst re-pops with the total | hold f0 | the strike | up to 4 | +3 to +11 |
| Pilers kill the target | Attacker settles back unstruck (8 f); after_attack still plays | last jab + 20 | — | — | +8 |
| Shield `status` logged before its `prevented` | Moved to contact | C | — | — | 0 |

**At the hit**

| If… | Shows | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|
| `damage` (exchange, strike back, Cleave) | Bursts and Health on all, same frame | C+2 | death check | all at once | 0 |
| `prevented` (shield, takes_no_damage, Stag Beetle) | Today's "0" burst, blocked knock-back; the pill drops (`status` rider) | C+2, or where the effect lands | — | with the hit | 0 |
| Venomous `trigger` → `destroy` → `status` | Today's numberless burst | C+2 | death at C+30 | rare | 0 |
| Overrun `trigger` → `damage` | Burst on the next enemy (stand-in: no line) | C+8, then +6 per hop | death check | per hop | +6 per hop |

**After the hit, and any chain**

| If… | Shows | Starts | Waits for it | Repeats | Cost |
|---|---|---|---|---|---|
| `death`, killed in the exchange | Today's fall, whole pass together (CB5) | C+30 | its death effects; the next launch | one pass | 0 (hidden under the next lift) |
| `death`, killed by an effect | Same | its killer's landing + 20 | same | per pass | +35 |
| `trigger`, source on the board | Pulse 6 f | the previous landing + 6 | its effect | rule 5 | — |
| `trigger` from a standing rule (uid −1) or a dead source | No pulse; the effect starts from the slot or plate | same | — | — | — |
| `damage`, `destroy` from effects (Glean, Plague, Lieutenant, Orchard Stripper, Bumblebee, Wheat Raider, Bitter Toad) | Beat, then burst (numberless for `destroy`) | beat | the next beat; its death | combo (CB7) | 18 |
| `hit` outside an attack (Ballista, Weasel on an arrival) | Beat; the jab toward the target is the hit | beat; Weasel after the arrival lands | same | Ballista: combo | 18 |
| `buff`, `effect`, `keyword` to others (Old Brock, Sword-heir, Standard-bearer, Avenge, Sexton, Skin-shedder, Hand-me-down) | Beat; numbers or pill pop on all targets together | beat | — | combo | 18 |
| `buff` to itself (Grow, Molt gain, Veteran, Coppicer) | Pulse; numbers pop at f6 | beat | — | combo | 12 |
| Two different mechanics at the same moment | One at a time, the second at the first's landing + 6 | — | — | — | +18 each |
| The same mechanic ×N (N ≥ 3) | Combo, rule 5 (CB7) | beat | the next beat | — | ~98 for any N ≥ 9 |
| `summon` (death effects, Hoppers, Cousin, King Speck, Elder Mother, Old Stump) | Drops in from 0.15 h above with today's fade, 12 f, landing at f9 | when the fall in its slot ends, or its beat's landing | its `on_fight_enter` | one source: a wave 4 f apart | 12 + 4 per extra |
| `reserve` | Rises from below its slot, 14 f, with the slot's Renown | the fall end | Weasel, Air Marshal | up to 2 | 14 |
| `return` (Molt, Root) | Today's fade-in in its own slot. Stand-in for the accepted husk and roots looks, which aren't built | the fall end | after_friendly_return | one per death | 12 |
| `heap_use` | Your Compost plate pops | with its summon | the summon | — | 0 |
| `summon_failed` | nothing; a lost Hopper's +1 Tide rides | — | — | — | 0 |
| Riders: `stats`, `status` (not a shield), `uses`, `player_counter`, `heap_add`, `heap_remove`, `slot` | Numbers, pips, pills or your plates change on their cause's landing (a lender's aura at its fall). Stealth ends at the lift; Molt or Root used at the return. Opponent's plates: nothing. | cause | — | all at once | 0 |
| `renown`, `gold` | Nothing (they count next fight, as today) | — | — | — | 0 |

**Not in the tree:** `instead_of_attack` and an in-fight `counter`. No card produces them (R3). Divine Shield, Reborn and Stealth exist only on stand-in units; they are covered by the shield and `status` rows.

## 5. Time budget

Contact to the next contact, in frames. The best proposal's numbers are worked out from section 3; today's are R3's films; none of the best's are filmed.

| Case | Today | **Best** | A | B | C | Battlegrounds |
|---|---|---|---|---|---|---|
| Plain attack | 57 | **61–63** | 71 | 36–39 | 59–62 | 73–83 (M) |
| With a death | 67 | **61–63** | 71 | 41–44 | 77–80 | 150–165 (M) |
| Shield popped | 76–86 | **61** | 71 | 36–39 | 59–62 | — |
| Trigger before the hit (Rally) | 124–139 | **65** | 71 | 38–45 | 75 | — |
| Venomous | 124–139 | **61** | 71 | 41–44 | ~77 | — |
| Kill → its death effect summons into the slot | 89 | **74** | 71 | — | — | — |
| Kill → summon → Weasel hits it → it dies | ~180 | **~123** | — | 93–96 | — | — |
| One trigger ×10 | 530 | **~98** | ~128 | ~75 | ~137 | ~470–500 (M) |
| 8-attack fight (start, 4 plain, 3 with a death, 1 chain) | ~650 (10.9 s) | **~613 (10.2 s)** | ~690 | ~417 | ~620 | — |

Plain attacks cost 4–6 f more than today. Anything with triggers costs much less. No moment runs past about 2 s, except chains that loop through several death passes; rule 7 trims those.

## 6. Contested branches

All clips use the fixed comparison fight, panes side by side, looped 3× at 1×. Everything except the named variable follows the best proposal. "Needs art" = needs an art pass and the owner's yes first.

| ID | Branch | Options (plan) | Pick, and why | Clip: moment, and the only thing that differs |
|---|---|---|---|---|
| CB1 | Wind-up | Today: 4 f, 12 px pull, ×1.04 · A: 10 f lift to ×1.15, no pull, 18 f hold · B: 8 f to ×1.14, 15 px pull, 14 f hold · C: 10 f to ×1.18, 20 px pull, 14 f hold, amber rim glow (needs art; stand-in: today's lunge glow) · Best: 10 f to ×1.14, 12 px pull, 16 f hold | **Best.** The lift and hold are measured on Battlegrounds; the small pull shows the aim on a flat board full of diagonal and back-row targets. | Plain attack straight across, 5 panes. Lift length, scale, pull-back and hold. |
| CB2 | Stop point | A: 0.78 h near · B: 0.70 near, 0.50 far · Today: 0.62 everywhere · Best: 0.62 near → 0.45 far, 0.40 back row · C: 0.50 near, 0.42 far | **Best.** Today's near stop already goes deeper than Battlegrounds'; C's covers the target's Health just as it changes. | (a) Plain attack straight across, 4 panes; (b) attack to a far target, 4 panes. The centre gap only. |
| CB3 | Strike curve | A, B, best: linear · C: mild ease-in (power 1.6) · Today: quad ease-in | **Linear.** It is measured (R1), and after a dead-still hold it gives the sharpest change of speed. | Attack to a far target, 3 panes, all 8 f; then once at 0.25× with a position trail. The curve only. |
| CB4 | Trigger before the hit (the owner's own point) | Today: freeze at contact (41 f for Rally) · A, B, C, best: in the raised hold · After the return, with the gain already in the hit's numbers (listed by A and C, not picked; the most literal reading of "then the other animation goes off") | **The hold.** Cause shows before effect, and nothing pauses. | Attack whose trigger fires before the hit, 3 panes. Where the trigger plays. |
| CB5 | When a dead card falls | B: C+14 · C: crack C+18, shatter C+24 (needs art; stand-in: today's fall at C+24) · Best: C+30 (A's C+33 is too close to film apart) · Battlegrounds 2020–25: C+60 | **C+30.** Its number gets ~28 f to read, and the fall still hides under the next lift. | Kill whose death effect summons, 4 panes. The fall's start only; the summon follows the fall in all. |
| CB6 | When the next attacker lifts | B: C+8 · Best and C: C+28; during a chain, when ≤16 f of queue are left · A: C+36, then holds up to ~48 f · Battlegrounds: early, held as long as needed (220 f seen) | **C+28 with the queue gate.** "Who's next" shows in the aftermath, but no raised card competes with a chain for the eye. | (a) Two plain attacks in a row; (b) the kill with a summon; 4 panes each. The lift rule only. |
| CB7 | One trigger many times | Battlegrounds: one at a time, ~2× faster by the end, no count · A: 2 full, then ×0.7, floor 8 f, ×N · B: ×0.75 from the 2nd, floor 4 f, one re-popping running-total burst, rest together after the 8th, ×N · C: ×1.3 tempo per repeat to ×3.5, ×N lozenge · Best: B's shape, floor 5 f (the trigger cue's 80 ms gap still fits) | **Best.** The ×N counter needs art; stand-in: the re-popping running-total burst. The owner asked for the counter, so what's needed is a picture and his yes. | Trigger repeated many times, 4 panes (Battlegrounds-style, A, C, best), none with ×N; plus 1 pane of best with a plain-text "×N" marked as a placeholder. Gap sequence and burst handling. |

**Decided without a clip:** B's "up to 3 different triggers at once". A, C and both measured games play triggers one at a time. Film it only if the owner finds chains slow.

## 7. Sound cues that would move (not retimed)

| Cue | Today | Best |
|---|---|---|
| `fight.hit.*`, `fight.hit.blocked` | step start, C+3 (C+22 / C+41 after a shield / Rally) | **at C, fired from the motion** (contact now falls inside a beat); frame 33–35 from the first motion, not 15 |
| the same, 3+ hits | 0 / 28 / 58 ms takes | Cleave: unchanged; Lieutenant: 5 f apart |
| `fight.destroy` | ≥ C+37 | C+2 |
| `fight.death` | C+37 | C+30; chain kills at landing + 20 |
| `fight.summon` | step start after the death step | the fall end (C+45); waves 4 f apart |
| `fight.trigger` | each 0.3 s step | each pulse, also inside the hold; combo gaps down to 5 f (83 ms), just above `min_gap_s` 0.08 |
| `fight.win/lose/tie` | after the last step | queue end + 24 |

No cue today for the lift, the launch or the combo's final count. `delay_s` is wall-clock time, so it won't follow rule 7's speed-up.

## 8. What only the owner's eyes can judge

- Whether 10 + 16 f reads as "very clearly visible", or as a stall.
- Whether ×1.14 reads as rising toward the camera on a flat glass board.
- Whether a 140 px strike straight across reads as "all the way", and whether a linear strike feels heavy or mechanical.
- Whether 76 px a frame on the longest attack strobes. That needs real hardware at full frame rate; a film can't show it.
- Whether a card falling while the next attacker lifts reads as two things or as clutter.
- Whether a back-row hit through the front row reads as hitting the back-row card.
- Whether the jab stand-in shows cause and effect well enough, or a drawn link is needed (art pass).
- Whether the combo's pace reads as "rising at increasing pace" or as a blur, and whether the running-total burst is enough before a ×N exists.
- Whether a 61 f cycle feels brisk or slow over a whole fight.
