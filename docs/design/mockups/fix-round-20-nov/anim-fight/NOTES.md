# Item 11, fight half: every event in the fight, animated (PROPOSAL)

Fix round 20 Nov 2026. Drawn by an agent. **Nothing here is decided.** Page: `index.html` in this folder.

**Cards are the dev branch's** (the branch the owner plays): units, stats and card text from dev's `src/content` (origin/dev 5d697e07), in `dev-cards.js`, which replaces `kit/data.js`'s main cards on this page. So there are no Medals, Orders or Stiff Upper Lip; units carry their slot's Renown pill, and Charge and Supply show as pips. Dev cards with no art yet show a plain glass panel.

**I could not judge any motion by eye.** I checked only still key frames (PNGs) and the code and timings. Whether each animation reads clearly, feels too fast, too slow or too busy needs a person to watch it, at normal speed and then at quarter speed (the page has a button for both). See "Needs a person to judge" below.

## Every event covered

"Now" times are the build's step holds (`src/screens/fight/fight_replay.gd`) and motion frames (`fight_motion.gd`). Tag: new = no animation of its own now; changed; keep.

| Event | Tag | Now | Proposed | Timing |
|---|---|---|---|---|
| Moving into the fight | new | Instant screen swap, then 0.7 s hold | Shop lifts away, your board glides down, theirs deals in front row first, their portrait slides into the right light | 1.0 s (was 0.7) |
| Start of fight: Hedge Lancer's free attack | changed | 0.3 s glow, then a normal attack; "no damage" only as a 0 burst | Lifts with a gold ward light, attacks at once; blue 0 on the lancer, Fury flares | 0.25 s lift + 0.77 s attack (1.37 → 1.1) |
| Start of fight: Grow | changed | Each Grow unit its own 0.3 s glow + 0.3 s change, in turn | One moment: Compost plate lights, a sprout flies to each Grow unit, numbers count up together | 0.9 s for any number (1.8 → 0.9) |
| Start of fight: Wing Commander | changed | Glow, then each Sortie Pigeon a full 0.77 s attack step | Pulse along the row; Pigeons fly over the front row, each leaving as the one before strikes | 0.3 s, then 0.3 s apart (2.3 → 1.3) |
| An attack | keep | Wind-up 4f, travel 8f, hold 2f, home 11f; recoil 16 px | Unchanged | 0.77 s |
| Damage numbers | changed | Burst pops; Health changes at the next redraw | Same burst; Health changes at contact with a red flash on its disc | No extra time |
| Guard choosing the target | new | Nothing shows why that target | Guard mark flares and a gold ring pulses during the wind-up | No extra time |
| Attacks again: The Oakfeller | changed | After a kill, a second full attack after the death steps and a home step | Second strike leaves part-way home with a short wind-up; ×2 pops | 1.3 s for both (2.3 → 1.3) |
| Cleave | new | Neighbour just gets a burst | Red arc sweeps from target to neighbour, which bursts a moment later and recoils sideways | +0.08 s |
| Overrun | new | Extra burst; nothing shows it carrying on | Mark flares; red chevrons run from the dead target to the next enemy | +0.15 s |
| Pile on, four neighbours | changed | Attacker winds up and waits; pilers jab out and hold, then the attacker lunges; all bursts in one splash | Each piler darts in 70 ms apart; bursts stack with a rising ×2, ×3, ×4; then the attacker lands | +0.28 s however many |
| Sortie hitting the back row | new | Straight lunge through the front row | Mark flares; unit arcs up and over the front row onto its target | +0.07 s |
| Thorns | new | One more burst on the attacker, same moment | Green thorns jab out of the defender; Thorns burst lands first, then the trade | +0.05 s |
| Damage from an effect: Gleaner | new | Source glows, then a burst; no link | A friendly unit dies; Gleaner glows; a lead line with a lit core draws to the enemy with the most Health and a bolt flies along it; Gleaner never moves | 0.8 s (was 1.15) |
| Fury gains | changed | Separate 0.3 s glow step after the attack | At contact the flame mark flares, orange +3 rises, Attack counts up | No extra time (1.07 → 0.77) |
| Lends, and an aura ending | new | Units lose the numbers at the next redraw | Wing Commander's Sortie kills the lender (Sett Shield-bearer); gold threads snap back into it as it falls; Health counts down | 0.45 s inside the death |
| Buffs to many at once: Parish Standard-bearer | changed | 0.3 s glow, then a 0.3 s change step | Start of fight: pulse runs across your board; each Mouse shows +15 Attack as it is reached | 0.55 s for any number |
| Counters: the Tide | changed | Plate pops; Attack changes in a later step | Wave of glass to the Tide plate (3 → 5), ripple along your Locusts, Attack ticks up | 0.6 s inside the death |
| Counters: Renown earned in a fight (Flying Ace) | changed | Slot's Renown changes in a later step | After its kill, a Charge pip flashes and dims; a gold star flies from the kill to its Renown pill (3 → 4). Its numbers stay: Renown earned in a fight counts from the next fight | 0.45 s inside the death |
| Deaths | keep (motion) | Drop 48 px, turn 16°, shrink to 0.72, fade in 15f, own 0.3 s step | Same motion, started while the burst is read | 0.3 s less per death (1.07 → 0.77) |
| Death effect: Seed into the Compost | changed | No glow; plate pops on its own | Seed mark flares a beat, unit falls, a seed flies into the plate (4 → 5) | +0.16 s on that death |
| Death effect: Brood Mother's Hopper | changed | No glow; Hopper fades in, numbers pop | She glows as she falls; Hopper drops in with a violet ring; plate 1 → 2, every Hopper +1/+1 together | 1.0 s from the hit |
| Summons | changed | Each summon its own 0.35 s step (four: 1.4 s) | Both sources glow; four Hoppers drop in one wave 50 ms apart | 0.65 s for any number (1.7 → 0.65) |
| Reserve stepping in | changed | Fades into the empty slot, taking the slot's Renown | Slot empties and shows its Renown; unit rises from below the screen (your hand), Reserve mark flares, +2/+2 from the slot's Renown | 0.45 s after the death |
| Molt returning | changed | Death motion, then copy fades in | Pales into a husk that splits; the copy pushes out at 1 Health, then +2/+2 | 0.95 s from the hit |
| Root returning | changed | Death motion, then fades in; Compost not updated | Roots grow up the slot, Compost dips 6 → 5, unit regrows from the roots up | 1.1 s from the hit |
| Death effect: Hand-me-down | new | No glow; the Mouse's Attack changes in a later step | Cousin's mark flares as it falls; a gold shard carries its Attack to the nearest Mouse, +2 in green | 0.45 s inside the death |
| The same trigger 10 times | new | Ten 0.3 s glows + 0.55 s splashes | Gleaner fires two at full speed, then faster and faster; ×N counter grows; ×10 holds a beat | About 2 s (was 8.5) |
| Several strikes in one moment: Lieutenant | new | One glow, one merged splash, no lines | Start of fight, row full: each unit in the row draws its line to the enemy across, 90 ms after the one before | 0.85 s for the row (was 1.15) |
| A tie | changed | "Draw" text over the transom, 1.5 s, no motion | Last two trade and fall; slate-blue leaded plate "Draw" settles; no portrait hit | 1.4 s (1.2 s hold) |
| The result | changed | "Victory"/"Defeat" text, 1.5 s, no motion | Survivors hop in turn; amber leaded plate "Victory" drops with a light sweep; "Defeat" in dark red | 1.2 s, then hero damage |
| Damage to the loser's hero | changed | Static burst; Health changes at once | Bolt arcs from the winner's portrait: -2, shake; big loss adds a heavier bolt for +3 → -5; Health counts down | 1.1 s (was 1.5) |
| Elimination | new | Nothing in the fight | Lead cracks run across the portrait, the glass falls out in pieces, the name dims | 1.5 s |
| Skip | new | Any click jumps straight to the result | Skip button presses in and lights; rest of the fight plays at 6× ("6×" floats up); result at normal speed | Whatever was left at 6×; most fights under 0.7 s |

End-of-fight effects are not covered: they are moving to the start of the next turn.

## Needs a person to judge

- The feel of every motion: speed, easing, weight. Nothing on the page was watched moving.
- Pile on: dev already staggers pilers before the lunge; this proposal's 70 ms stagger and stacked ×N bursts. Busy in stills; may be clear or noisy in motion.
- The 10-trigger combo: how fast it should accelerate, and whether ×10 is readable at the end.
- Skip at 6×: whether you can still follow who killed whom, or it needs 4×.
- Result plates and the hero bolt: whether they feel weighty or slow the end of every fight.
- Elimination shatter: whether it lands as a moment or feels long at 1.5 s.
- Molt husk split and Root regrowth: whether they read as "came back" at a glance.

## Owner choices

- **Big-loss damage:** two bolts (-2, then +3 → -5) as drawn, or one bolt with the total.
- **Result:** leaded plate as drawn, or plain text as now with only motion added.
- **Opponent's counters:** their Tide/Compost plates are not shown in the fight now; show them or not.
- **Queue speed-up (rule, no prototype):** when more than 4 steps are waiting, play them up to 1.6× faster, as Battlegrounds does. Say yes or no.
- **Skip button look** here is a stand-in; its design belongs to another item.

## How to view

Serve the repo root (any static server) and open `docs/design/mockups/fix-round-20-nov/anim-fight/index.html`.

- `index.html` – all 34 events, grouped, each looping while on screen; timing chart at the top; Normal/Quarter speed and Pause for all or one.
- `index.html?event=<id>` – one event large. Add `&t=<ms>` to freeze a frame, `&shot=1` for the bare 1920 × 1080 stage.
- Ids: enter, lancer, grow, wingco, attack, damage, guard, again, cleave, overrun, pileon, sortie, thorns, strike, fury, lends, buffs, tide, renown, deaths, seed, hoppers, summon, reserve, molt, root, hmd, combo, lieut, tie, result, herodmg, elim, skip.

PNGs (1920 × 1080, `scratchpad/after/anim-fight/`), named `<id>-<ms>.png`, one to three per event, 61 in all, e.g. `enter-200`, `enter-600`, `pileon-380`, `combo-1200`, `combo-1900`, `herodmg-450`, `herodmg-1250`, `elim-1700`, `skip-1240`, `skip-1500`.

## Choices and why

- **Grouping.** The owner's 18 Nov note: timing may change but must not vary wildly, and repeats need a grouped version. So single actions stay near the 0.77 s attack, and anything that repeats (Grow, summons, Parish Standard-bearer, Wing Commander, Lieutenant, the 10-trigger combo) plays as one wave or an accelerating combo, none past about 2 s.
- **Keyword effects show the cause.** Guard, Sortie, Thorns, Overrun, Cleave and effect damage each get a mark flare plus one motion that says why (ring, arc over, thorns, chevrons, sweep, line). This follows the owner's rule that animation shows play, with no static reminders.
- **Numbers change at contact,** not at the next redraw, so hit and number read as one.
- **Deaths overlap the burst** to save 0.3 s per death without changing the death motion.
- **Real pieces:** cards from the glass card kit at game size (250 px), fight geometry from the glass `fight.html`, 4 front and 3 back slots. Shared files are linked, not copied.

Things I assumed from the code: Pile on's hits all land in one step in the rules core (`pile_on.gd`); the 70 ms stagger is only visual. Renown earned in a fight counts from the next fight (dev rulebook 11.7.6), so Flying Ace's numbers don't rise when its pill does. Fury is drawn as damage dealt first, then the gain.

Not covered (not asked, or not used by any card now): a summon with no room, in-fight gold, Divine Shield, Venomous, Stealth.

## In-game text used

"Victory", "Defeat", "Draw", "Skip", "6×", "×2" to "×10", "+2/+2", "+2", "+3", "+15", "-2", "-5", "Renown 2" to "Renown 6" (the pill), plate names Compost, Tide, Hopper. All short labels or numbers; no sentences on the fight screen.
