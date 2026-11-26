# How a stat gain is shown in a fight (24 Nov 2026)

Proposal only: nothing decided, built or filmed. f = a frame at 60 fps; h = card height (250 px).

## The problem, measured

The owner (24 Nov): "When Brock gets stats it's very hard to tell what happened. I should at least get something numerical … I should be focused on the part of the card that's changed … How many stats did Brock gain from the card dying?"

In the comparison fight, six of your units die at once. Old Brock ("After a friendly unit dies, gain its Attack and Health this fight") gains +2/+5, +3/+5, +2/+2, +2/+5, +3/+5 and +2/+2. Today that is one trigger glow and one change step: **10/9 becomes 24/33 in a single frame** (fixture frame 587). Brock's discs are about 36 px across, with digits about 9 px tall (frame 566). No amount, no repeats, no cause. The best proposal only retimes this (rule 3).

## 1. Reference study

Frames in `/data/fight-anim-ref/buff/`. TFT: nothing found. "Unverified": not checked on a source.

| Game | Eye drawn by | Amount shown? | Cause to target | Lasting vs temporary | Many gains |
|---|---|---|---|---|---|
| Marvel Snap ([clip](https://www.youtube.com/watch?v=PEQouIJ_5pA)) | The power badge pops to about 3× in ≤1 f, holds 8 f, shrinks 8 f; turns green | Result only | The source pulses; an arc sweeps to the target in about 20 f | Green above base | One target at a time, about 1.2 s each |
| Legends of Runeterra ([clip, 4:20](https://youtu.be/FJCxXTedbTk?t=260)) | Gold wash over the card, about 40 f | **Green "+2" over the stat**, 2× the digit, about 42 f | A gold orb flies in about 12 f | Two kinds exist ([Riot](https://support-legendsofruneterra.riotgames.com/hc/en-us/articles/360035562114-Granting-and-Giving)); same look, unverified | Not seen |
| Hearthstone ([clip](https://www.youtube.com/watch?v=404ucy_-Ffs), [wiki](https://hearthstone.wiki.gg/wiki/Enchantment)) | Gold flare whites out the minion, **hiding the number** | Result only (4/3 → 8/7, green) | Shaft of light from the cause | Hover only (unverified) | Each in full, 0.45–0.8 s |
| Once Upon a Galaxy ([clip, 5:30](https://youtu.be/4_uOk8CZu0Y?t=330)) | Sparkle ring round the whole card, about 36 f | Result only (2/2 → 9/10) | Not visible | Not seen | One after another |
| Super Auto Pets | Unverified: the stat bounces | Unverified: no | Projectiles for damage | **This-battle stats underlined** ([guide](https://www.twoaveragegamers.com/ultimate-guide-to-super-auto-pets-game-mechanics/)) | Same-moment triggers hard to follow ([Steam](https://steamcommunity.com/app/1714040/discussions/0/3198118348349750330)) |
| Slay the Spire ([code](https://github.com/aeubanks/sts)) | Power number jumps to 8× and shrinks in about 30 f | **"+2 Strength" floats up**, 2 s | A relic cause flashes | Buff green, debuff red | One 15 f step each, never summed |
| Balatro ([code](https://github.com/balatro-src/balatro-src-reverse-engineering), [clip](https://www.youtube.com/watch?v=S3kUbN_zaLw)) | The triggering card wobbles 24 f; the total flashes white and big | **"+4 Mult" on a coloured blob**, bigger than the number, about 42 f | **Timing:** the cause wobbles on the popup's frame | Lasting gains say "Upgrade!" | 45 f apart early, 16 f late; **pitch up 1.6 % per trigger** |
| Backpack Battles ([trailer](https://www.youtube.com/watch?v=bJc5yvIXNUc)) | Green "+1" over the character | Yes | None | Not seen | **4–6 numbers overlap: unreadable** |
| Fighting and action games | Combo counter grows and pops ([GG Strive](https://www.dustloop.com/w/GGST/HUD)); a lagging bar shows the whole combo ([Daniels](https://derek-daniels.squarespace.com/blog/2013/3/1/damage-presentation)); one source's hits merge ([Hades](https://gameplay.tips/guides/hades-guide-to-damage.html)); rising notes ([Peggle](https://blog.audiokinetic.com/en/peggle-blast-peg-hits-and-the-music-system)) | Running total | — | — | Summed, rising |

**What carries over:** enlarge the stat, not the card (whole-card effects pull the eye off the number); show the amount next to its stat, as the readable games do; show the cause, by something travelling (Snap, LoR) or the cause moving on the same frame (Balatro), where Battlegrounds does neither; sum repeats into one running total (fighting games, Hades), since separate numbers pile up (Backpack Battles); lasting versus temporary is drawn by only two games; a pitch rising per gain makes a chain build.

## 2. Three treatments

All three keep the best proposal's beat (source pulse 6 f; 18 f to the next beat; combo gaps ×0.75, floor 5 f). Only the changed disc moves.

### A. Swell and count (existing pieces only)

- **f0–6:** the source pulses (today's 14 px lift and glow).
- **f6–10:** it jabs 0.08 h at its target (today's jab). A gain to itself has no jab.
- **L = f12 (f6 for a gain to itself):** the changed disc and its digits jump to ×2.0. This is today's `number_pop`, which is 1.5 now; the disc setting is scaled with the digits.
- **L to L+8:** the digits count from old to new, in today's green "up" colour.
- **L+3 to L+14:** the disc eases back to ×1.0.

**Brock ×6:** Brock lights once and stays lit. Gains land at f6, 24, 38, 48, 56 and 62. Each re-swells the disc and carries the count on (10 → 12 → 15 … 24). Settled by f76 (1.3 s).

**Standard-bearer, +15 Attack to seven Mice:** after the pulse, the Attack discs swell in reading order, 3 f apart, from f12. Done at f44.

**Weakness:** no amount; the cause is only the jab.

### B. Pinned tally (A plus a tag)

As A, plus a **gain tag**: "+N" in green glass, with figures about 22 px tall (2.4× the disc's digits). It is pinned 38 px above the disc it changes, one tag per stat. So +2/+5 shows "+2" over Attack and "+5" over Health.

- **Timing:** it appears at L−2 at ×0.5, overshoots to ×1.25 at L+2 and settles by L+6. At L+30 it sinks into its disc (0.1 h down, shrinking to ×0.4, fading over 6 f).
- **Repeats:** the tag stays and shows the **running total**, popping from ×1.35 at each gain ("+2/+5" → "+5/+10" → … → "+14/+24"). It holds 24 f after the last gain. This is the combo's cumulative number the owner liked, applied to gains.
- **Standard-bearer:** each Mouse gets a "+15" as the wave reaches it. The tags are 152 px apart, so they never overlap.

**Weakness:** the dead friends still aren't linked to Brock's gain.

### C. Carried tally (B, with the gain flying from its cause) — **my pick**

The tag is born at the cause, flies into the disc, then pins there as B's tally. Where it is born:
- a unit giving the gain: the top of that unit;
- a death (Brock, Hand-me-down): the dead unit's empty slot, at disc height, when its fall ends (rule 4);
- a gain to itself: its keyword mark (Fury), as the recruit screen's Grudge gain already does, else the card's middle.

Frame by frame:
- **f0–6:** the source pulses.
- **f4:** the tag appears at the cause, growing from ×0.5 to ×0.9 in 3 f. When both stats change, it is a pair 85 px apart, the discs' own spacing.
- **f4–14:** it flies 10 f on a low arc (at most 0.15 h high), setting off gently and **arriving at speed**, like the hand's card flight. A gain to itself rises in 8 f instead.
- **f14 (L):** the disc flares for 8 f, then swells and counts as in A. The tag pins and sinks at L+30.

It replaces the jab; 2 f more per beat.

**Brock ×6:** Brock lights at the fall end F. Tag pairs rise from the six empty slots at F+0, 18, 32, 42, 50 and 56, and land at F+10, 28, 40, 50, 58 and 64. Each landing merges into Brock's tally ("+2/+5" … "+14/+24"), re-swells the discs and carries the count on. The tally holds to F+88, then sinks; Brock's light ends at F+96. That is 1.6 s, within the combo cap. If deaths are staggered (the R5 thread), each pair leaves as its own card's fall ends. **This answers the owner's question: +2/+5 from that card, +14/+24 in all.**

**Standard-bearer:** at f4, seven "+15" tags fan out together at one speed (10–14 f by distance), so the nearest land first. They sink at the last landing + 20 (about f52; the fix round accepted 0.55 s here).

**One gain** (Hand-me-down's +2): it lands at f14 and sinks by f50. The next beat starts at f20, under the tag's tail.

### Lasting versus this-fight gains

All three treatments show them the same. Players know their cards, and the hover lists each gain by its source. If the owner wants a difference, the tag's glass could carry it: green for this fight, gold silver-stain for lasting. The prompt includes a gold tag so this can be judged.

### Existing and new pieces

| Piece | Used by | Status |
|---|---|---|
| Trigger pulse; jab | A, B (C: pulse only) | Drawn today |
| `number_pop` at ×2.0, disc setting scaled with it | all | Exists; new size and scaling are code, not art |
| Digit count-up; green "up" digits | all | Count-up exists for gold and cards landing (fight needs the code); green is drawn today |
| Gain tag | B, C | **New in the fight.** Stand-in: the recruit screen's green glass pill (`recruit_turn_start.gd` `_gain_tag`) |
| Tag flight from the cause | C | **New.** Stand-ins: the recruit's `_arc` and the Grudge rise |
| Disc flare | C | **New.** Stand-in: the recruit's amber `_ring` |
| Rising pitch per gain | all | Sound, on today's `fight.trigger` cue |

**Can be filmed now:** all of A. B and C can be filmed with the stand-ins once the owner has said yes to a still of the recruit pill on a fight card. The glass tag and flare need the art in `tools/art/prompts/buff-look.md`, then a picture, then a yes.

## 3. My pick: C

- **It answers all three of the owner's points:** a number (the tag), the eye on the part that changed (only that disc swells, and the tag pins there), and the cause (the gain leaves the dead card or the giver).
- **It is interesting, not only clear.** Six gains rising from six empty slots into one badger, with the total climbing faster each time, is a fighting-game combo applied to gains. Battlegrounds has nothing like it.
- **It is the rule the owner accepted for the recruit screen** (21 Nov): "every gain starts at its source … the gain flying to the target". Fight and shop would match.
- **Risk:** seven tags at once may clutter; then B for one-to-many.

## 4. Decision tree rows (`plans/tree.json`, not edited)

| Node | New wording |
|---|---|
| `pre.buff` (shows) | Gain to itself (Fury, Gate Warden, Rally): the keyword mark flares (today's mark pop); the gain tag rises 8 f to the changed disc; the disc flares, swells ×2.0 and counts 8 f; the tag sinks as the attacker launches. Drum's gain to others: `beat.buff_other` inside the hold. Cost 4 (fits the hold) |
| `beat.buff_other` (shows) | Source pulses 6 f. At f4 a gain tag per changed stat leaves the source, or the dead unit's empty slot if a death caused it, and flies 10 f, arriving at speed. At f14 the disc flares, swells ×2.0 and counts 8 f. The tag pins 38 px above its disc and sinks 30 f later. Many targets: tags fan out at one speed, nearest landing first. Cost 20 |
| `beat.buff_self` (shows) | Pulse; the tag rises 8 f from the cause (keyword mark, else the card's middle) to the disc; at f12 flare, swell, count; tag pins, sinks 30 f later. Cost 14 |
| `beat.combo` (add) | Gains on one card: one tally per stat shows the running total and pops ×1.35 at each landing; the disc re-swells and keeps counting; the source stays lit; the tally holds 24 f after the last gain |
| `soc` (add) | Standard-bearer uses `beat.buff_other` (fan-out); Grow units use `beat.buff_self` as one beat |
| `rider.stats` (shows) | No tag: the changed disc swells ×1.5 and counts in 4 f; a loss (an aura ending) counts down in the hurt red |
| new `beat.buff_lasting` | `permanent` true: same as this fight's (owner option: gold tag) |

## 5. Art for the new pieces

`tools/art/prompts/buff-look.md` (format of `combo-look.md`): two tag looks (green-glass figures alone; cream figures on a green leaded plaque), a gold plaque for lasting gains, a two-frame disc flare that leaves the digits clear, and three mock-ups on today's frame of Brock (`/data/fight-anim-work/buff-look/base/base-brock-f566.png`): a pair in flight, the flare, the final tally. The mock-ups judge look, size and place; only a film shows the count.

## For the owner's eyes

Whether a ×2.0 disc with a tag above it reads as focused or covers too much art; whether tags from empty slots read as "from the cards that died"; whether seven "+15" tags are exciting or clutter; figures alone or on a plaque; whether lasting gains should look different.
