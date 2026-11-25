# Pilot 2: how a single card dies (24 Nov 2026)

Second subject of the animation-practice pilot ([PLAN-animation-practice.md](../PLAN-animation-practice.md)), run through [PROCESS.md](../practice/PROCESS.md) steps 1 to 3, plus pictures to ask for (step 4) and a filming plan. One card dying on its own. Several deaths at once and their stagger are pass 2's CB8 ([research/mass-deaths.md](../research/mass-deaths.md)) and are not touched here. Nothing here is built or filmed. No agent has watched any of it move. Notes on the process: [practice/pilot-notes.md](../practice/pilot-notes.md).

## 1. Brief

```
Moment:        One unit's Health reaches 0 from a hit, and it leaves the board (inventory F16, one card).
Owner's words: 24 Nov: "death animations in general might need work, and the player taking damage
               after a fight as well." On the pilot: "we're trying to measure how to improve them.
               We're also not trying to lock it in as final yet. We're just trying to experiment on it."
Bar:           Not given by the owner. Proposed, to confirm: "you see that it died, and how, at a
               glance; it looks like nothing else on the board" (GUIDELINES D1: unlike a hit or a
               fade). Reference moment: Legends of Runeterra's card breaking into shards (below).
Ordering:      Plays after the hit that kills it. Today: the hit shows at H, the "−N" burst is gone
               at H+33, the death starts at H+34 in its own 0.3 s step, the card is gone at H+49.
               So the number has gone before the card starts to die. The next step waits for the
               death step. The last death of a fight runs into the result, whose settle() stops any
               card still moving.
Limits:        (1) The death step's 0.3 s (18 f) hold, from brief 10's frozen budget (LB 2). It
               squeezed today's 15 f fall. The owner lifted that limit on 18 Nov: reopened here.
               (2) The owner's 18 Nov rule: timings may vary, not wildly. Squeezes the length:
               the main beat stays near 18 f; a trace may run on under the next step (T7).
               (3) Fight speed (S4).
New pieces:    Option A's crack overlay, shard map and glints (pictures first, section 6).
Out of scope:  Several deaths at once and their order (CB8); death effects and summons into the
               slot (F17, F18); the attack and hit motion (pass 2); sound design.
Done when:     This run: options with beat specs, pictures asked for, a filming plan. Later: film,
               log checks, a two-option compare clip, a Windows build, the owner's verdict.
Claims:        Frame counts and timings from footage and logs; nothing about feel.
Disk report:   In the report back to the orchestrator.
```

## 2. Reference study

Three references of the same moment, one unit dying after a hit, plus ours. Footage stays in `/data/fight-anim-ref/`; frame sheets in `/data/fight-anim-work/pilot/scratch/`. **M** = counted or measured on frames; **G** = read by eye, error given. h = card height.

| Ref | Link | What it is |
|---|---|---|
| BG | [youtu.be/X3cr8nyi_-s?t=786](https://youtu.be/X3cr8nyi_-s?t=786), from 786.4 s (n = 0); R1's D3 | Battlegrounds 2026: a minion shatters, 40 f after its hit (R1) |
| GAL | [youtu.be/4_uOk8CZu0Y?t=331](https://youtu.be/4_uOk8CZu0Y?t=331), G-A3 (Jack); sheet `galaxy/work/L_jackdeath.png`, 30 fps | Once Upon a Galaxy: the card is flung off, turning |
| LoR | [youtu.be/FJCxXTedbTk?t=414](https://youtu.be/FJCxXTedbTk?t=414), from 413.4 s, L-T1 | Legends of Runeterra: the card breaks into angular shards |

### BG (60 fps, every frame, n from 786.4 s)

| n | Card | Pieces, light | Number | M/G |
|---|---|---|---|---|
| ≤ 36 | Still, whole | – | "−6" star on it since the hit | M |
| 37–42 | **Breaks**, 5–6 f: cracks into about 8–12 tan shards; the card's outline is gone by n42 | Shards move out ≤ 0.5 h; white dust blooms to about 1.3× the card, n38–48 | Star stays on top | M (shard count G ±2) |
| 43–64 | Gone | Dust and shards drift and fade, gone about n64 (about 20 f) | Star still on | M |
| 65– | The neighbour slides into the gap | – | Star still on at n77 | M |

Hit to break: **+40 f** (R1 D3; 2020–22 footage +65 to +68).

### GAL (30 fps sheet, steps of 2 f, ±2 f; frames after the killing contact)

| f | Card | Number | M/G |
|---|---|---|---|
| +6 to +54 | Still | "15" star on it | G ±2 |
| +54 to +60 | Still | Star shrinks away | G ±2 |
| +60 to +86 | **Tips and drifts away**: turns 0 → about 60°, moves up-left about 0.5 h, stays opaque, size about the same | – | G ±2 (angle ±10°) |
| +86 to +92 | Flips to its card back and leaves; a small burst of pink stars | – | G ±2 |

About 30 f from first move to gone. The number goes first, then the card.

### LoR (60 fps, every frame, n from 413.4 s)

| n | Card | Pieces, light | Number | M/G |
|---|---|---|---|---|
| 58–61 | Whole | **White-lavender flash** over the whole card, 4 f | – | M |
| 62–64 | Whole, normal light | – | Health shows red | M |
| 65–70 | **Breaks**, 5 f, into many angular dark shards with purple glow | – | Red Health stays on | M |
| 70–80 | – | Shards drift up and apart | stays | M |
| 80–83 | – | Last shards fade; gone by n83 (about 18 f after the break) | stays | M |

### Ours today (fixture film, seed 22; log `/data/fight-anim-work/fixture/today.cards.csv`, Prophet of the Dust, u8)

| f | Card | Number | M/G |
|---|---|---|---|
| 116 (H) | Hit: Health 5 → 0, burst "−2" pops | Burst on, 33 f | M |
| 117–149 | Back home, still | Burst gone at f149 | M |
| 150–164 (H+34 to H+48) | Drops 48 px along its death direction (here back towards home, up-left), turns −16°, shrinks to 0.72, `ease.fall` (quad in). Opacity 1 until f153, then to 0 at f164 | – | M |
| 165 | Gone; slot empty at once, no trace | – | M |

`fight.death` plays at f150. The step holds 18 f; the next step starts at f168.

### What the references say

1. **The number outlasts the card**, or goes just before it (GAL). Ours is the one case where the number is gone **before** the card starts to die.
2. **Two of three break.** BG and LoR split the card into pieces in **5–6 f**, then a trace of about **18–20 f** (dust, drifting shards). It's the fastest way to show "gone" and looks like no hit.
3. LoR **flashes the card 4 f** before it breaks: a beat that says "this one is dying" before the break.
4. Galaxy keeps the card whole and **throws it** (about 30 f, turning to 60°). It is the slowest of the three.
5. None of them fades the whole card as one piece, as ours does from its fifth frame.

## 3. Ordering first

For one death the order of steps is mostly fine (H+34 is inside D1's 30–68 f). Three ordering changes, shared by every option:
- **The killing burst stays on until the death's trace ends**, instead of going at H+33. Only on a lethal hit. Every reference keeps the number (E6).
- **The trace runs under the next step** (T7): the main beat fits today's 18 f step where it can, and the rest overlaps the next wind-up.
- **The last death of a fight must finish before the result.** Today the last death (f673) has 4 f to spare before the result (f692); a 30 f trace would be cut by `settle()`. Either the result waits for the trace or `settle()` lets it run.

## 4. Options

Anchor: **D** = the death's first frame (H+34, unchanged). Frames at fight speed 1. Every number is a guess (G) unless the source column names a reference. All three are tier 1 (E1). For a big unit (tier 2, not yet defined in GUIDELINES) each adds a 4 f hold on the dying card at D and a 6 px shake along the hit.

### A. Shatter: the glass breaks along its lead (new pieces)

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Flare and crack | D+0 to D+5 (6 f) | Lead: the card, still. Its light jumps to 1.5 and eases to 1.2; lead cracks spread from the side it was hit on (crack stage 1 at D, stage 2 at D+3) | `ease.pop` | `death_crack` | – | Crack stage 2 shown at once | LoR flash 4 f |
| Break | D+6 to D+11 (6 f) | Lead: 7–9 shards cut from the card's own picture along the stage-2 cracks. Each flies away from the crack's origin at 3–8 px/f, biased along the death direction, spinning ±2–6°/f, with gravity 0.9 px/f². The card is gone from D+6 | `fall.gravity` (new token) | `death_break` | `fight.death` moves here, from D | Cross-fade to the empty slot over 8 f | BG 5–6 f, LoR 5 f; D1 5–10 |
| Trace | D+12 to D+29 (18 f) | Shards keep falling; they fade from D+18 to 0 at D+29 and shrink to 0.9. Support: 2–3 glints on shard edges, D+8 to D+20 | `fall.gravity`, `ease.exit` | `death_gone` (D+29) | – | – | BG ~20 f, LoR ~18 f; D1 ~20 |
| Number | H to D+24, fades 8 f | The killing burst, on top of the shards | – | – | – | Same | All refs |

Main beat 12 f: the card is gone inside today's 18 f step. The trace runs 11 f into the next step.

### B. Tip and fall (existing pieces only)

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Tip | D+0 to D+7 (8 f) | Lead: the card turns 0 → 14° round its bottom corner on the far side from the attacker, like a pane coming loose; light dims to 0.85 | `ease.fall` | `death_tip` | `fight.death` at D (today) | No turn; dim only | GAL tips first |
| Drop | D+8 to D+21 (14 f) | Falls 120 px along its death direction under gravity, turns 14 → 36°, ×1 → 0.88; opaque until D+14, then to 0 at D+21 | `fall.gravity`, `ease.exit` | `death_gone` (D+21) | – | Fade 8 f in place | GAL ~30 f, shortened |
| Number | H to D+16, fades 8 f | Killing burst on top | – | – | – | Same | All refs |

22 f: 4 f past today's step. No trace (D1 not met).

### C. The light goes out (existing pieces only)

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Darken | D+0 to D+7 (8 f) | Lead: the card's glass goes dark, modulate 1 → 0.25, so only the lead pattern reads, like a window after dusk. Still | `ease.exit` | `death_dark` | `fight.death` at D | Same | Our own idea; no reference |
| Hold | D+8 to D+11 (4 f) | Still, dark | – | – | – | Same | – |
| Sink | D+12 to D+23 (12 f) | Sinks 24 px along its death direction, ×0.9, fades to 0 | `ease.fall` | `death_gone` (D+23) | – | Fade 8 f | – |
| Number | H to D+18, fades 8 f | Killing burst on top | – | – | – | Same | – |

24 f. No trace (D1 not met), unless the dark pane counts as one.

### Checked against GUIDELINES

| Rule | A | B | C |
|---|---|---|---|
| V1 travel only for an attack | Pass: shards fly away from everything | Pass: falls away from the attacker | Pass |
| V3/V7 new drawn piece, picture first | Crack overlay, shard map, glints: pictures first | none | none |
| D1 starts 30–68 f after the hit | Pass (H+34) | Pass | Pass |
| D1 breaks fast, 5–10 f | Pass (6 f) | No break: the drop is 14 f | No break |
| D1 short trace, ~20 f | Pass (18 f) | **Fail**: none | **Fail**, unless the dark pane counts |
| D1 unlike a hit or a fade | Breaks: unlike both | Moves like a heavier version of today's drop | Risk: may read as a slow fade. It is the test of whether darkening reads as death |
| T7 overlap the seams | Trace under the next step | 4 f over | 6 f over |
| T10 frequent beats short | Main beat 12 f | 22 f | 24 f |
| E5 rigid, x = y | Shards rigid | Pass | Pass |
| E6 number never hidden | Burst kept on top | same | same |
| A1 flashing | One flare per death; several deaths in a second could pass 3 flashes in a region: check with CB8 | No flash | No flash |
| A2 reduced motion | Column above | same | same |
| S1 tokens | Needs `fall.gravity` | Needs `fall.gravity` | Pass |
| S2 ends at rest | Shards freed; check nothing is left | Check | Check |
| S4 game time | Markers, scaled | same | same |
| E5's open question: may glass crack? | **Depends on it**: art direction has not decided (GUIDELINES E5) | n/a | n/a |

## 5. Pick

**A, shatter.** Glass that dies should break: it is the material's own death, and two of the three references break in 5–6 f. It is the only option that meets all of D1 (fast break, short trace, unlike a hit or a fade), and its main beat fits inside today's step. It needs two yeses first: that glass may crack at all (art direction, E5) and the pictures.

**Film B against C first.** They use existing pieces, so they can be built now. They differ in one thing: the card moves away or stays and goes dark. The winner is the fallback if the owner says no to cracking glass, and the comparison tells whether a card that stays put reads as dead. Then A against the winner.

## 6. New drawn pieces (step 4)

Only A needs them: crack overlays in two stages, a shard map (the break pattern), and a small glint. Art direction and the Codex prompt: [`tools/art/prompts/pilot-death.md`](../../../../tools/art/prompts/pilot-death.md). Base frames: `/data/fight-anim-work/pilot/base/base-today-f149.png` (the Prophet of the Dust one frame before it dies, Health 0) and `base-today-f166.png` (its slot just after, empty).

Art direction in short:
- **What breaks:** the dying card's own picture, split along new lead lines. The pieces are the card, not new art; the drawn pieces are the cracks and the pattern. Whether splitting the live card counts as "cropping existing assets" (owner rule, 22 Nov) is a question for the owner; it is the card itself breaking, not a new element made from old art.
- **Big pieces, few of them:** 7–9 shards, each at least a fifth of the card's width, so the break reads in 6 frames.
- **Cracks are lead**, dark #16120e with a thin warm edge of light, starting from the side the card was hit on.
- **The glint:** one small four-point glint of white-gold glass, 24–36 px.
- **Clarity first** (the owner on combo round 1). Nothing over the "−N" burst.

## 7. Filming plan (for the builder)

**Fixture.** The fight compare fixture (seed 22) already has single deaths: the attacker dies (Prophet of the Dust, f150, falls back toward home), a target dies (Nettle Sprout, f673, the last kill, into the result), plus f369 and f496. Use f150 (attacker) and f673 (target, and the result's cut). The six-at-once death (f549) belongs to CB8. Leave it on today's motion, or film it only to check nothing breaks.

**Code a builder would change** (one tuning file, tokens only, game time):
- `src/screens/fight/fight_motion.gd` `_fade_out` (line ~138): call a death motion from a new `death_motion.gd` that holds every number above.
- Option A: a `DeathShards` node that takes the card's drawn picture and draws 7–9 `Polygon2D` pieces with UVs from the shard map; the crack overlay drawn on the card for 6 f; glints. Only after the owner's yes.
- `fight_motion.gd` `burst()`: on a lethal hit, hold the burst until the death's trace ends.
- `src/screens/fight/fight_replay.gd`: `HOLD_DEATH` 0.3 s can stay for A. For B and C, the next step overlaps the last 4–6 f (T7) rather than waiting.
- `src/screens/fight/fight_screen.gd` `settle()` at the result: don't cut a death in progress, or start the result after it.
- New token `fall.gravity` in the shared motion module.

**Sound cues that move.** `fight.death` moves from the death step's start to `death_break` (A only; D+6). Cues fire at step start today (`sound_cues.gd`), so a marker cue needs a new path. B and C keep it at D. Update `tests/sound/test_sound.gd`.

**The log must add:** per-shard rows (key, x, y, rotation, alpha) for A; the burst's alpha per frame; markers `death_crack`, `death_break`, `death_tip`, `death_dark`, `death_gone`.

**Checks, each shown to fail on today's film first:**
- The killing number is drawn on every frame from H to `death_gone` (pixel check on the burst region). Today it is gone at H+33, before the death. Fails today.
- Break: card outline gone within 5–10 f of D (A).
- Some pixels change in the slot for ≥ 15 f after the card is gone (trace). Today none. Fails today.
- No card's centre moves toward another card outside an attack (V1).
- Nothing left at the end (S2); the last death isn't cut by the result.
- Speed 1 and the fastest speed.

**Compare clips.** B against C, aligned on D, on the attacker's death (f150). Then A against the winner. Then a Windows build.

**What no check will see:** whether the break feels satisfying or busy, whether a dark card reads as dead, whether 7–9 shards suit lead and glass at speed, and how it all feels when several single deaths come one after another in a real fight.
