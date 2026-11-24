# Pilot 1: damage to the player after a fight (24 Nov 2026)

First subject of the animation-practice pilot ([PLAN-animation-practice.md](../PLAN-animation-practice.md)), run through [PROCESS.md](../practice/PROCESS.md) steps 1 to 3, plus pictures to ask for (step 4) and a filming plan. Nothing here is built or filmed. No agent has watched any of it move. What the process itself did well or badly is in [practice/pilot-notes.md](../practice/pilot-notes.md).

## 1. Brief

```
Moment:        After a fight, from the result to the loser's Health going down: one fight's loss
               damage landing on one portrait (inventory G2). Both cases: your portrait (you lost)
               and the opponent's (you won).
Owner's words: 24 Nov: "death animations in general might need work, and the player taking damage
               after a fight as well." On the pilot: "we're trying to measure how to improve them.
               We're also not trying to lock it in as final yet. We're just trying to experiment on it."
               21 Nov: "option 11, I accept all changes" (covers the 20 Nov proposal: "Bolt arcs from
               the winner's portrait: -2, shake; big loss adds a heavier bolt for +3 → -5; Health
               counts down", anim-fight NOTES). He never saw it move.
Bar:           Not given by the owner. Proposed, to confirm: "you feel the hit, and you can say how
               much and why" (a big loss hurts more and you can see it was big). Reference moment:
               Battlegrounds' hero hit after combat (below).
Ordering:      Plays after the last death has finished and the result is shown. Today the result
               step shows the banner, the burst and the new Health on one frame (f692 of the
               fixture film) and then nothing moves for 2.5 s. The damage must wait for the banner,
               and Health must change at the impact, not before. It hands over to elimination (G4)
               when Health reaches 0, and to the leaderboard (G3), which must not show the new
               Health before the count ends.
Limits:        (1) The after-fight screen holds 2.5 s (AFTER_FIGHT, game_controller.gd:23),
               skippable after 0.4 s. Squeezes: the whole beat. Kept: every option ends inside
               150 f. Reopen if the owner wants a longer ceremony.
               (2) The owner's 18 Nov rule: timings may vary, not wildly. Squeezes: big against
               small loss. Big losses get at most about 0.3 s more.
               (3) Fight speed: the beat scales with it (S4).
Rules it must  Rulebook 10.1.1–10.1.3: a loss deals round + 1 (up to 10), and 3 more when the
tell:          loser killed fewer than half of the winner's starting units. Damage does NOT come
               from the survivors (unlike Battlegrounds), so the survivors must not fire at the
               portrait. The split (base, +3) is worth showing: it is the rule's whole point.
New pieces:    Option A's bolt and its impact flare (pictures first, section 6).
Out of scope:  The result banner's own motion (G1), elimination (G4), the leaderboard rows (G3),
               the way back to recruit (G5), sound design (a new cue is listed, not made).
Done when:     This run: options with beat specs, pictures asked for, a filming plan. Later: film,
               log checks, a two-option compare clip, a Windows build, the owner's verdict.
Claims:        Frame counts and timings from footage; nothing about feel.
Disk report:   In the report back to the orchestrator.
```

## 2. Reference study

Three references of the same moment, or the nearest each game has, plus ours. Footage stays in `/data/fight-anim-ref/`; frame sheets in `/data/fight-anim-work/pilot/scratch/`. Frames at 60 fps from an anchor. **M** = counted or measured on frames; **G** = read by eye from a sheet, with the error given.

| Ref | Link | What it is | How it differs from ours |
|---|---|---|---|
| BG | [youtu.be/X3cr8nyi_-s?t=800](https://youtu.be/X3cr8nyi_-s?t=800), from 800.9 s (n = 0) | Battlegrounds 2026: after the last enemy dies, the winner's hero portrait hits the loser's, −10 | The real moment. Damage there comes from tier and survivors |
| GAL | [youtu.be/4_uOk8CZu0Y?t=375](https://youtu.be/4_uOk8CZu0Y?t=375), from 375.3 s | Once Upon a Galaxy: the loser loses a life, a heart | Lives, not an amount. No number. This one is the loser's last heart, so it is an elimination too |
| LoR | [youtu.be/FJCxXTedbTk?t=413](https://youtu.be/FJCxXTedbTk?t=413), from 413.4 s | Legends of Runeterra: an unblocked unit strikes our Nexus, 16 → 12 | Mid-combat, not after it. Same job: a hit takes the player's Health down by an amount |
| Super Auto Pets | [youtu.be/e-o1eG1C_bU?t=455](https://youtu.be/e-o1eG1C_bU?t=455) | Dropped: the battle fades to black and the shop shows the trophy count. Nothing hits the loser on screen | – |

### BG, per frame (n from 800.9 s)

Portrait positions from the template tracker (`scratch/bg_hd_track.tsv`, match ≥ 0.74 on n16–30), in 720p pixels; h = card height ≈ 110 px. Light = mean grey level of the loser's portrait region (baseline 108.6).

| n | Winner's portrait | Loser's portrait | Light (loser region) | Number | M/G |
|---|---|---|---|---|---|
| 0–15 | Glows at home; sparkles gather on it (charge, 16 f) | still | 108.6 | – | M |
| 16–20 | Rises out of its slot to a point right of the loser: (760,407) → (846,280); steps 70, 46, 25, 12 px/f: **fast, then slowing (ease out)**. Tilted about −20°, upright by n20 | still | 108.6 | – | M (tilt G ±5°) |
| 20–28 | **Hold**, 9 f, drifting away from the target (backing off): 4 → 8 → 4 px/f, 67 px in all | still | 108.6 | – | M |
| 29–31 | **Strike**, 3 f: 44, 70, ~150 px/f, **speeding up into contact**. Contact at n31, about 0.3 h past the loser's centre, overlapping it | light rises | 123 → 165 → 211 | – | M (n31 position G ±10 px) |
| 31–46 | Pressed on the loser | White, then pink flare over both, rays across the whole board (board +9 % light, n31–38) | peak **251 at n34** (×2.3), back to 108 at n46 | – | M |
| 47–71 | Returns home, back by about n60 | **Darkened** under a swirling ring | 64 → 40 | – | M (return G ±3 f) |
| 72–79 | Home | – | 50 → 133 | **"−10" star grows in, 72–77**; Health 30 → 21 with it | M (Health change G ±3 f) |
| 80–100+ | – | – | 93–118 | Star held past the end of the sheet (≥ 28 f) | M |

- No camera shake: the HUD stays on the same pixels through the impact (n29–34). M.
- **The number comes 41 f after the impact.** Impact, flash, darkening, then the amount. Start to number: 72 f (1.2 s).

### GAL (sheet at 2-frame steps, ±2 f; n from 375.3 s)

| n | What happens | M/G |
|---|---|---|
| 0–26 | Nothing on the loser's portrait. A treasure pop-up plays to the right (unrelated) | G |
| 28–30 | The red heart turns into an empty gold outline | G ±2 |
| 30–46 | A red particle spray bursts from the heart and spreads to about 2.5 portrait widths | G ±2 |
| 46–90 | Particles drift and fade; nothing else moves; no number | G ±2 |

No cause travels from the winner. The loss is shown where it lands, as a thing breaking.

### LoR (2-frame steps, ±1 f; n from 413.4 s)

| n | What happens | M/G |
|---|---|---|
| 30–44 | The enemy unit lifts and dives across the board | G ±1 |
| 46 | Contact at our board's edge, white flash line along it | G ±1 |
| 46–48 | Nexus Health 16 → 12 | G ±2 |
| 48–56 | A white shock runs along the board edge to the Nexus | G ±1 |
| 52–62 | Blue sparks burst on the Nexus | G ±1 |
| 66– | Red "−4" beside the Health (+18 f after contact), still there at n80 | G ±1 |

### Ours today (fixture film `/data/fight-anim-work/fixture/today.mp4`, seed 22, Victory)

- f692 (`result_shown`): "Victory", the static "−7" burst on Brother Bracken's portrait and Health 36 → 29 all appear on one frame. Mean grey level of the portrait region jumps 42.4 → 43.7 at f692, then **no pixel changes until the film ends at f816**. M.
- Sound: `fight.win` at f692. No cue of its own for the damage. M (markers).
- The portraits are 1888 px apart (centres (104, 994) and (1796, 160) at 1080p), about 7.7 card heights. An attack crosses 1 to 2.4. M.

### What the references say

1. Two of three show **a cause, then a landing, then the amount**, in that order (BG, LoR). Galaxy shows only the landing.
2. BG's strike has the same shape as its card attacks: a fast rise, a clear **9 f hold**, a **3 f strike that speeds up**. It treats the hero hit as an attack.
3. BG and LoR **delay the number** (41 f and 18 f after contact). Our guideline T5 (react within 3 f) covers the target's reaction, which both do at once (flash); the number itself waits.
4. None shakes the camera at this moment. The 20 Nov proposal's shake is ours.
5. The loser's Health changes with the number (BG) or at contact (LoR), never before the cause, as ours does today.

## 3. Ordering first

Today's fault is mostly **when**, not **how**: the new Health and the burst appear on the result's first frame, before any cause, and then the screen is still for 2.5 s. All options below share these ordering changes:

- The result step shows the **old** Health. The damage beat starts 12 f after the banner (so the banner reads first), and Health changes only from the impact.
- The leaderboard (Tab) shows the new Health only after the count ends.
- Skip (after 0.4 s) jumps to the settled end: final Health, no beat.
- If Health reaches 0, elimination (G4) starts when the count ends.
- The last death must finish before the result: `settle()` at the result cuts any card still moving (see [death.md](death.md), filming plan).

## 4. Options

Anchors: **R** = `result_shown` (banner on screen). **C** = impact. All frames at fight speed 1, 60 fps. Every number is a guess (G) unless the source column names a reference.

**Shared landing (L)**, the same in every option, built from existing pieces, so the options differ only in the cause:

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Impact light | C+0, back over 12 f | Lead: loser's portrait (modulate to `HIT_LIGHT` at once) | `ease.exit` back | `hero_contact` | `fight.hit.heavy` (stand-in; new `fight.hero_hit` for a sound pass) | Same | today's hit light |
| Knock | C+0 to C+3, back C+3 to C+15 | Loser's portrait, 14 px along the incoming direction | `ease.enter` out, `ease.return` back (not linear, unlike today's card hit) | – | – | None | G |
| Shake | C+0 to C+18 | Whole stage: offset along the incoming direction, 12 px (small loss) or 18 px (big), decay trauma² | `shake.dir` (new token, E4) | – | – | None | E4 (≤ 20 px, gone in 12–30 f) |
| Amount | C+2: pops ×0.55 → 1.18 in 3 f, → 1 in 5 f; held to R+130; fades 8 f | Support: the existing "−N" burst on the portrait (`hit_splash`) | `ease.pop` | `hero_burst` | – | Appears without the pop | today's burst; T5 |
| Count | C+2 to C+20 | Lead: the Health disc swells ×1.5 and settles in 14 f; digits roll old → new, one step at a time, spread over 18 f | `pop.emphasis`, `count.roll` (new token) | `health_count_start`, `health_count_end` | – | Digits roll, no swell | V4 |
| Big loss, second landing | C2 (option-specific), then as above with shake 18 px; the burst's number rolls to the total with a ×1.3 pop; Health counts the last 3 over 8 f | as above | as above | `hero_contact_2` | `fight.hit.heavy` again | Number changes, no shake | rulebook 10.1.1; 20 Nov proposal |

### A. Bolt (the 20 Nov proposal, accepted, never seen)

A drawn bolt of glass leaves the winner's portrait and arcs to the loser's.

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Banner reads | R+0 to R+11 | Still | – | `result_shown` | `fight.win`/`lose` (today, unchanged) | Same | – |
| Charge | R+12 to R+23 | Lead: winner's portrait ×1.0 → 1.08, light 1.3. Support: the bolt grows at the portrait's rim facing the loser, ×0 → 1 | `ease.enter`, `ease.pop` | `hero_windup` | – | Bolt appears at full size | BG charge 16 f, shortened |
| Hold | R+24 to R+31 (8 f) | Still | – | – | – | Same | BG hold 9 f; T3 |
| Flight | R+32 to R+45 (14 f) | Lead: the bolt, on an arc bowing 10 % of the distance away from the board's middle, aimed along its path; a two-frame afterimage (40 %, 15 %). Winner's portrait settles to 1.0 over 12 f | `ease.strike` | `hero_launch` | – | Cut: bolt shown at the loser for 4 f | BG strike speeds up; 1888 px in 14 f = 135 px/f average |
| Impact | C = R+46; the bolt holds 4 f, then becomes the impact flare (×0.6 → 1.2 in 3 f, gone by C+14) | Shared landing L | `stop.hit` (new token), `ease.pop` | `hero_contact` | as L | Flare without scale | G |
| Big loss | Second, heavier bolt: charge C+6 to C+17, flight C+18 to C+27 (10 f), C2 = C+28 | as above | as above | `hero_contact_2` | as L | as L | 20 Nov proposal |

Totals: Health final at **R+66** (1.1 s); big loss **R+84** (1.4 s). Screen still leaves at R+150 as today.

### B. The winner's portrait strikes (Battlegrounds' way, existing pieces only)

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Banner reads | R+0 to R+11 | Still | – | `result_shown` | as today | Same | – |
| Lift | R+12 to R+22 (11 f) | Lead: winner's portrait comes out of its window 30 px toward the board, ×1.15, light 1.3, tilts 8° toward the loser | `ease.enter` | `hero_windup` | – | No lift; light only | BG rise 5 f + T3 lift 9–11 |
| Hold | R+23 to R+36 (14 f) | Still | – | – | – | Same | BG 9 f; T3 14–22 |
| Strike | R+37 to R+46 (10 f) | Lead: the portrait flies to the loser's, stopping with the rims overlapping 0.2 diameter | `ease.strike` | `hero_launch` | – | Cut to contact | BG 3 f; see T4 below |
| Impact | C = R+47; striker holds 4 f | Shared landing L | `stop.hit` | `hero_contact` | as L | as L | – |
| Return | C+4 to C+19 (16 f) | Striker home, ×1.0, upright | `ease.return` | `hero_home` | – | Cut | BG ~13 f |
| Big loss | The striker doesn't go home: it pulls back 60 px in 6 f and strikes again in 5 f, C2 = C+15, then returns | as above | as above | `hero_contact_2` | as L | as L | G |

Totals: Health final at **R+67**; big loss **R+79**; the striker is home by R+82 (big R+94).

### C. In place, no travel (Galaxy's way, existing pieces only)

| Beat | Frames | Who moves | Token | Marker | Sound | Reduced motion | Source |
|---|---|---|---|---|---|---|---|
| Banner reads | R+0 to R+11 | Still | – | `result_shown` | as today | Same | – |
| Cause in place | R+12 to R+23 | Winner's portrait pulses ×1.06, light 1.3, back by R+23. Loser's portrait dims to 0.85 | `ease.pop`, `ease.exit` | `hero_windup` | – | Light only | V2 (a trigger acts in place) |
| Hold | R+24 to R+31 | Still | – | – | – | Same | T3 |
| Impact | C = R+32; knock goes into the loser's window (down), shake vertical | Shared landing L | – | `hero_contact` | as L | as L | GAL lands where it breaks |
| Big loss | Second pulse C+10 to C+15, C2 = C+16 | as above | – | `hero_contact_2` | as L | as L | G |

Totals: Health final at **R+52**; big loss **R+68**.

### Checked against GUIDELINES

| Rule | A | B | C |
|---|---|---|---|
| V1 travel only for an attack | Pass: nothing that is a card travels; the bolt is a drawn effect | **Unclear**: a portrait travels. It is the winner attacking, so it keeps V1's meaning, but V1 speaks of cards. Owner to judge | Pass |
| V2 trigger in place | n/a | n/a | Pass |
| V3/V7 new drawn piece, picture first | Bolt and flare: pictures first (section 6) | none | none |
| T3 visible wind-up then a still hold | Pass (12 + 8 f) | Pass (11 + 14 f) | Pass (12 + 8 f) |
| T4 strike 5–8 f whatever the distance | Broken on purpose: 14 f. T4 was set for card-to-card distances (1–2.4 h); this is 7.7 h. At 8 f the bolt would average 236 px/f and read as a cut. Average 135 px/f is close to BG's strike speed at 1080p | Broken on purpose: 10 f, same reason (189 px/f average) | n/a |
| T5 react within 3 f | Pass (light C+0, burst C+2) | Pass | Pass |
| T11 impact sound on the impact frame | Stand-in cue at C | at C | at C |
| E1 tier | 3 (damage to the player) | 3 | 3 |
| E2 emphasis budget | One shake per fight | same | same |
| E4 shake ≤ 20 px, gone in 12–30 f | 12/18 px, 18 f | same | same |
| E5 rigid pop, x = y | Pass | Pass (striker ×1.15) | Pass |
| E6 spectacle never hides the number | The flare is a ring with an empty middle (section 6) | Striker must not cover the Health disc: stop on the far side of the disc | Pass |
| E7 skippable once seen | Today's skip (after 0.4 s) | same | same |
| D3 cause from the winner's side, impact, count | Pass | Pass | **Broken on purpose**: the cause is only a pulse. Bramble's damage measures how the fight went (rulebook 10.1.1), not the winner's strength. It is the control for "does travel add anything?" |
| A1 flashing | One flash; check the film | same | same |
| A2 reduced motion | Column above | same | same |
| A3 no spin or big zoom on decoration | Pass | Pass | Pass |
| S1 tokens | Needs new tokens `shake.dir`, `count.roll`, `stop.hit` | same | same |
| S2 ends at rest | Check: portraits ×1, stage offset 0 | Check: striker home | Check |
| S4 game time | All beats on markers, scaled by fight speed | same | same |

Also considered and dropped: the survivors firing at the portrait. It reads well in other games but says the wrong thing here, because survivors don't set Bramble's damage. A crack across the loser's portrait was dropped too: the 20 Nov elimination proposal uses lead cracks across the portrait, and keeping cracks for elimination saves the strongest picture for the strongest event (E2).

## 5. Pick

**A, the bolt.** A cause that travels from the winner says who did it (BG, LoR, D3). A drawn bolt does it without making a portrait act like a card (V1), it can be made of lead and glass, and once per fight is rare enough for 1.1 s (E2). The owner accepted it on 21 Nov without seeing it move, so it still needs his eye.

**But film B against C first.** Both use existing pieces, so they can be built and filmed before any picture is approved. They differ in one thing: whether a cause travels. If C wins, travel isn't needed and the bolt picture can be skipped. If B wins, A's bolt replaces the flying portrait once the owner says yes to its picture. That pair is the cheapest real choice (PROCESS step 8, LB 4).

## 6. New drawn pieces (step 4)

Only A needs them: the bolt (two takes for the owner to pick from), a heavier big-loss bolt, and an impact flare. Art direction and the Codex prompt: [`tools/art/prompts/pilot-player-damage.md`](../../../../tools/art/prompts/pilot-player-damage.md). Base frames: `/data/fight-anim-work/pilot/base/base-today-f691.png` (just before the result, both portraits clear) and `base-today-f700.png` (the result with today's "−7" burst).

Art direction in short (the prompt has the full craft answers):
- **What it is:** a lance of glass thrown by the winner. A faceted spearhead of warm white-gold glass with a short tail of two or three tapering panes. Not lightning, not a fireball.
- **Reads at speed:** one bold silhouette, high contrast on the dark board, 70–90 px long at 1080p, tail extra. It points right; the engine rotates it.
- **Colour:** warm white-gold to amber, like the hit glass, never the burst's red. The big-loss bolt is deeper amber-orange with heavier lead.
- **Impact:** a ring of six to eight leaded shards with an **empty middle**, so the "−N" burst in the middle stays readable (E6).
- **Clarity first:** big simple pieces. The owner, on combo round 1: "someone's gone way too heavy … We need stuff that has good visual clarity."

## 7. Filming plan (for the builder)

**Fixtures.** No fixture reaches a lost fight today (inventory). Add to the fight compare fixture (`tests/screens/feel/fight_compare/` on `review/fight-animation-clips`) short fights that end fast, each starting at the last attack:
1. You lose, small loss (your portrait, bottom left, hit from top right).
2. You lose, big loss (the second landing).
3. You win (seed 22 already ends in Victory; its −7 lands top right).
4. You lose to 0 Health (the hand-over to elimination; G4 stays a stand-in).
The fixture needs knobs for the round number and the player's Health, like CB7's set unit Health.

**Code a builder would change** (one tuning file, tokens only, game time):
- `src/screens/fight/fight_replay.gd` `_take_damage` (line ~562): the result step must keep the **old** Health and carry the damage, its base and whether it was a big loss. Take the split from the session (`game_session.gd:317`, `big`), not by recomputing it in the screen: a rule modifier may change `loss_damage`.
- `src/screens/fight/fight_screen.gd` `_build_result` (line ~515, marked STAND-IN): replace the static burst with the beat, in a new `hero_damage_motion.gd` holding every number above.
- `src/game/game_controller.gd`: keep `AFTER_FIGHT` 2.5 s; skip settles the beat; the leaderboard waits for `health_count_end`.
- New tokens (S1): `shake.dir`, `count.roll`, `stop.hit`, in the shared motion module.
- Option A only, after the owner's yes: the bolt sprites.

**Sound cues that move.** `fight.win`, `fight.lose` and `fight.tie` stay at R. New: a cue at `hero_contact` (and `hero_contact_2`), stand-in `fight.hit.heavy`. Today cues fire at step start only (`sound_cues.gd` `for_fight_step`), so a cue on a marker inside a step needs a new path in `sound_player.gd`. Update `tests/sound/test_sound.gd`.

**The log must add:** both portraits (position, scale, rotation, modulate) and the stage offset per frame; the bolt's position and angle; the Health digits drawn per frame; markers `result_shown`, `hero_windup`, `hero_launch`, `hero_contact`, `hero_burst`, `health_count_start`, `health_count_end`, `hero_contact_2`, `hero_home`.

**Checks, each shown to fail on today's film first:**
- Health digits change only at or after `hero_contact`. Today they change at R. Fails today.
- Contact to the first change on the portrait ≤ 3 f (T5). Today there is no contact. Fails today.
- Shake ≤ 20 px, zero by C+30 (E4); nothing off rest at the end (S2).
- Flash count in the portrait region (A1).
- Everything inside 150 f after R.
- At speed 1 and the fastest speed: markers scale.

**Compare clips.** First B against C, aligned on R. Then A against whichever wins, once the bolt picture has the owner's yes. Then a Windows build.

**What no check will see:** whether the hit feels heavy, whether 1.1 s feels long at the end of every fight, whether the shake feels good or cheap, the sound landing on the hit, and whether a flying portrait suits lead and glass.
