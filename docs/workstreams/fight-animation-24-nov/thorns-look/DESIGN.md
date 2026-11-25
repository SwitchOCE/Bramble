# Thorns look: design (thread 9, 24 Nov 2026)

Nothing here is decided, drawn or built. Every new piece below needs pictures and the owner's yes before anything is filmed with it. The art direction for the pieces is [ART-DIRECTION.md](ART-DIRECTION.md); the image prompt is [`tools/art/prompts/thorns-look.md`](../../../../tools/art/prompts/thorns-look.md).

**Units.** Frames (f) at 60 fps. h = card height, 250 px on the 1920 × 1080 stage. **C** = contact, as in [`plans/best.md`](../plans/best.md). The best proposal's plain attack: lift 10 f (C−33 … C−24), raised hold at least 16 f (C−23 … C−8), strike 7 f, contact C. What happens before the hit plays in the hold, and the hold becomes max(16, last landing + 8).

## 1. The owner's words, and what they ask for

> "I think what this has shown is that things like Thorns need their own specific animation. The card hitting feels wrong. It needs to be some sort of thorn effect that just hits them, and looks like a thorny vine whipping out and striking them. Or the unit hitting and then flinching, having a different animation when it takes damage from Thorns, to show that it takes damage back. Thorns doesn't feel understandable right now. I think it's because we're trying to communicate it using the same language as an attack, when it's not an attack; it's something else. Same with the hits. We need alternate animations for other effects that don't just use movement, but also use additional assets, I think." (24 Nov, dictated)

He called his suggestions ideas, so they are judged by his reason: **a card moving toward another card means "attack"; Thorns is not an attack, so it must not be shown that way.** The look has to say four things:

1. the damage comes from the defender,
2. because it was attacked,
3. before the attacker's hit lands,
4. and how much.

## 2. Today

### What Thorns does in the rules

- `src/content/thorn/mechanics/thorns.gd`: "Thorns N: whenever this is attacked, deal N damage to the attacker first … Not an attack and not a Hit." Thorns from several sources add up, and the first Thorns on the unit deals the total.
- It runs in `on_attacked`, which is step 1 of an attack (`src/core/combat/combat.gd` 414–421). If either unit dies there, the attack ends: no `on_attack`, no exchange, no after-attack. **An attacker killed by Thorns never strikes.**
- It is logged as `trigger` then `damage`, with the defender as `source_uid` and `from_attack` false (`research/our-events.md`).
- Who has it: Nettle Sprout (T1, Thorns 2 in the comparison fight), Nettle Skirmisher (T3), and Lone Hawthorn (T5, which has **Guard**, so it is attacked often; enemies its side's Thorns kill go into the Compost). Holly Knight (T4) gives front-row Briars +Thorns for every 3 units in the Compost, so the amount can grow large.
- It fires once per attack. "Attacks twice" units (Shrew Harrier, Hornet Queen) take it twice. Pile-on hits, Overrun and Cleave don't trigger it.
- An attacker can take none of it. Hedge Lancer's first attack and Tourney Champion's attacks take no damage, Stag Beetle takes damage only from attacks, and Divine Shield exists only on stand-in units. Each logs `prevented`.

### How it shows

- **Today's game** (`fight_screen.gd` and `fight_replay.gd`): the attacker lunges to contact and waits there. The Nettle Sprout lifts and glows (the trigger step, 0.3 s), then a splash shows Thorns' damage. Comparison-fight moment (c): contact 3.00 s, first burst 3.37 s. In the fixture's film, Thorns' damage lands in the same burst step as the exchange (`tests/screens/feel/fight_compare/README.md`, `origin/review/fight-animation-clips`). This is CB4 "freeze".
- **The best proposal's stand-in** (`best.mp4`, measured from `best.cards.csv`). The attacker, Horde-runner, lifts at f157–166 and holds raised. The Nettle Sprout's beat is the generic trigger: it moves 14 px (f174–179), then **jabs 34 px toward the attacker** (f180–184). The red "−2" burst lands on the raised attacker at f185, which is C−15. The strike runs f194–199, with C at f200. The hold stretched to 27 f, because the beat waited for the previous death to fall.
- **Lethal**, moment (d): Green Recruit attacks diagonally. Lift f289–299, then the Sprout jabs f300–310. The burst lands at f311 and Health goes to 0. The Recruit falls raised from about f331, and a Hopper arrives at f346.

**Why it reads as an attack.** The only thing that moves is the Nettle Sprout, and it moves *at* the attacker: the jab is the attack's own verb, done smaller. The damage arrives as the attack's red burst. Nothing on screen says "thorns". In today's game it's worse: the attacker sits at contact, and the damage seems to come out of its own hit.

## 3. References

How other games show damage that comes back at an attacker, or damage that isn't an attack. A **[memory]** row is from general knowledge of the game; no agent re-checked the footage. Treat those rows as leads, not measurements. No other studio's frames were copied anywhere.

| Game | What happens | How it is shown | What we take |
|---|---|---|---|
| **Slay the Spire**: Thorns ([wiki](https://slay-the-spire.fandom.com/wiki/Thorns?oldid=6873); [Bronze Scales](https://slay-the-spire.fandom.com/wiki/Bronze_Scales)) | An attacker that hits a creature with Thorns takes N damage, from attacks only | [memory] The Thorns icon in the defender's power row flashes. A small slash effect and a damage number play on the attacker. The defender doesn't move. In code, its damage type is "thorns", not an attack | The defender stays still. The source is marked by its own sign, and the damage lands on the attacker |
| **League of Legends**: Thornmail ([official wiki, named item effects](https://wiki.leagueoflegends.com/en-us/Named_item_effect); [Leaguepedia](https://lol.fandom.com/wiki/Thornmail)) | When hit by a basic attack, the wearer reflects magic damage at the attacker. The wiki calls it "reactive" damage | [memory] Spiky green flashes burst on the wearer, and a number shows on the attacker | Thorns is its own class of damage and gets its own colour |
| **Teamfight Tactics**: Bramble Vest ([METAsrc](https://www.metasrc.com/tft/choncc/item/bramblevest)) | When struck, it damages adjacent enemies (2 s cooldown) | [memory] A ring of thorny spikes bursts out around the wearer | **Thorns come out of the defender**, as a drawn shape, with no movement of the unit |
| **Monster Train**: Spikes ([Trainworks status-effect docs](https://github.com/Monster-Train-2-Modding-Group/Trainworks-Reloaded/wiki/Custom-Status-Effects)) | When attacked, the attacker takes damage equal to the stacks | The modding example plays its own Spikes damage sound. [memory] The spike icon pulses, and the number shows on the attacker | A cue of its own (sound included) |
| **Darkest Dungeon**: Riposte ([wiki](https://darkestdungeon.wiki.gg/wiki/Riposte)) | When attacked, the user counter-attacks | A full counter-attack animation, because it *is* an attack | The opposite case. It shows why Thorns must not look like Riposte: a riposte is an attack, Thorns is not |
| **Hades**: Athena's Deflect ([boons](https://hades.wiki.fextralife.com/Boons)); spike traps | Deflect sends attacks back. Floor spikes hurt whoever stands on them | [memory] Deflect: a gold flash and the projectile visibly turning round. Spikes: a short warning, then they shoot up from the floor | A reversal is shown by a thing that travels back. A trap is shown by a warning and then an eruption |
| **Street Fighter 6**: counter and punish counter ([Twinfinite](https://twinfinite.net/guides/how-to-punish-counter-in-street-fighter-6/); hitstop is a "visual performance" choice, [Capcom SF Seminar](https://game.capcom.com/cfn/sfv/column/131545?lang=en)) | The same contact, but special | A different hit spark and colour, a caption, extra hitstop and its own sound | **A special hit keeps the contact but changes the spark, the pause and the victim's reaction.** That is the owner's "flinch" |
| **Hearthstone Battlegrounds** (our [research](../research/battlegrounds.md) T1, T6) | No minion damages its attacker on being attacked ([wiki search: none found](https://hearthstone.wiki.gg/wiki/Combat)). Triggered damage is common | Triggered effects fly as **projectiles** from their source after the attacker is home. Start of Combat shows the source card enlarged | Effect damage travels from its source |
| **Super Auto Pets** (our [research](../research/galaxy-and-others.md)) | Ability damage | "Triggered abilities throw visible projectiles (a rock arcing from its source to its target in about 10 frames), so you see what caused the damage" | Same: a drawn link from cause to effect |
| **Legends of Runeterra** (our research, L-T2, [youtu.be/FJCxXTedbTk?t=158](https://youtu.be/FJCxXTedbTk?t=158)) | Spells and skills | A line is drawn from the source to its target. Units lunge only to attack | Attack = a unit moving; an effect = a line |
| **Once Upon a Galaxy** (our research, G-T1 to G-T6) | Treasures and spells | A pop-up grows out of the source's slot, about 1.2 s. Buffs get coloured sparkles. No reflected damage was seen | Too slow for something that fires on every attack into a Thorns unit |
| **Marvel Snap** | On Reveal effects | [memory] Particles and projectiles fly from the card; cards never lunge | Same split |

**What this tells us.**
- Every game that has Thorns keeps the defender still. It shows the source with its own mark, and the damage on the attacker, in its own colour or sound.
- Games that show effect damage clearly draw something that travels from cause to target: a projectile or a line. Card movement is kept for attacks.
- Fighting games mark a special hit by changing the spark, the pause and the victim's reaction, not the attacker's motion.
- No game we found draws Thorns as a whip. That is the owner's idea. It fits a briar tribe in leaded glass better than a generic projectile.

## 4. Options

Each option is drawn against the best proposal's attack straight across (Horde-runner on the Nettle Sprout, Thorns 2). Hold f0 = C−23 when nothing else is queued. "Burst" means today's red damage burst, unchanged: the number stays the one red burst whatever caused it (see the family map). "Flinch" is a new motion, defined once here and shared by all damage that isn't an attack:

> **Flinch (hurt by an effect).** f0: an 8 px jolt away from the source in 1 f, turned 4° away, scale ×0.97. f1–f8: three shrinking side-to-side shakes (±3, ±2, ±1 px, 2–3 f each, never a 1-frame flip, so it doesn't strobe). f8–f14: settles back, cubic out. **The card doesn't travel.** Compare the target of an attack, which is knocked 20 px *along the line* (best.md section 2). Motion only, no new art. It would be the shared token `react.flinch` (GUIDELINES S1), beside a `react.knock` for the attacked target.

### A. Lash: a briar whips out of the defender (the owner's first idea)

Beat spec in the format of [practice/PROCESS.md](../practice/PROCESS.md) step 3. Frames count from hold f0. Every number is a guess (G); nothing like it was measured.

| Beat | Frames | Who moves | Token | Marker | Sound cue | Reduced motion |
|---|---|---|---|---|---|---|
| **Bud.** A briar knot breaks out of the defender's point that faces the attacker (the bottom point of theirs, the top of yours) and scales 0 → 1.1 → 1.0. The defender **pulses in place** (GUIDELINES V2: today's glow and a scale pulse, **no lift toward the attacker, no jab**) | f0–f2 | bud leads; defender is support, in place; attacker still, raised | `ease.pop` | `thorns_start` | `fight.trigger` | bud appears at full size |
| **Anticipation.** The vine's tip curls back against the bud | f3–f4 | tip | `ease.move` | – | – | skipped |
| **Lash.** The tip runs along a curved path from the bud to the attacker's upper face, speeding up, with the vine unrolling behind it segment by segment. The curve bulges to the side with more empty board, so it reads as a whip and not a spear. 5 f up to 1.4 h, 6 f up to 2.4 h, 7 f beyond | f5–f10 | tip leads, vine follows | `ease.strike` (speeds up, never constant) | – | new `fight.thorns` (a rustle into a crack) | vine appears whole at f5, no travel |
| **Bite.** A thorn-pierce impact under the tip. The attacker starts its **flinch** (T5: it reacts on the impact frame) | f10 | attacker reacts; vine still | new `react.flinch` | `thorns_land` | the crack of `fight.thorns` | no flinch; impact frame only |
| **Number.** Burst "−2" on the attacker, Health 5 → 3 (+2, like every hit) | f12 | burst | `pop.number` | `burst` | – | same |
| **Recoil.** The vine withdraws into the bud from the tip back; the bud closes over f17–f20 | f12–f19 | vine | `ease.exit` | – | – | fades out over 6 f |
| **Launch.** The hold ends (12 + 8). Strike f20–f26, contact at hold f27 | f20 | attacker | best.md | `contact` | `fight.hit.*` | – |

The landing comes at f12, inside GUIDELINES T10's 12 f limit for a frequent beat; the recoil overlaps the end of the hold. Thorns is a tier-1 event (GUIDELINES E1): no shake, no hit-stop beyond the flinch.

- **Against C:** the lash lands at C−15 and the burst at C−13. The plain 16 f hold becomes 20 f, the same as today's stand-in.
- **Lethal:** the vine stays latched while the attacker flinches. At landing + 20 (best.md's rule for a death by effect) it falls from its raised pose, and the vine lets go and recoils over the first 8 f of the fall. There is no strike.
- **Prevented** (takes no damage, Stag Beetle, a shield): the tip glances off at f10 and recoils at once. Today's "0" burst shows, and the attacker doesn't flinch.
- **Attacks twice:** each re-lift gets its own lash, and the re-strike's 8 f hold becomes 20.

**New pieces:** the bud; three vine segments (chained along the curve, each its own glass piece with a lead joint, as a real leaded vine is built); the tip; two impact frames. The **flinch** is motion only. Building it: segments placed along a Bézier and revealed by index. That is more work than any other option, but nothing exotic for Godot 2D.

**At speed** (expected; only the owner can judge it): a line from the cause to the effect is the clearest way to say "it came from there" (Runeterra, Super Auto Pets, Battlegrounds' projectiles). A curved, whipping line is a different verb from a card flying straight. The tip moves 25–110 px a frame, so it's whip-fast. Whether it strobes on the longest lash needs real hardware (blind spot 3).

**Time:** +4 f per attack into Thorns, against a plain attack (the same as the stand-in it replaces). Lethal: 57 f from lift to the attacker gone, the same as the stand-in.

**Risks:** a back-row attacker is up to about 2.7 h away, so the vine crosses other cards. It is drawn above them for about 20 f. Lone Hawthorn is a Guard, so the lash will be seen often: it must stay small and quick, or it gets tiresome.

### B. Prick: the attacker strikes into thorns, flinches, then lands its blow (the owner's second idea)

The owner's "the unit hitting and then flinching", kept true to the rules order (Thorns comes first).

| Frame | What happens |
|---|---|
| hold f0–f3 | **Telegraph:** a row of glass thorns (the **bristle**) grows out along the defender's two edges that face the attacker. They stay out. The defender doesn't move. |
| C−7 … C−1 | Strike as normal, but it stops 0.10 h short of the plain stop, on the thorn tips. |
| C | **Prick:** a thorn flare where the attacker's point meets the thorns. The attacker jolts back 10 px in 2 f and flinches (C+2 … C+8). |
| C+2 | Burst "−2" on the attacker. |
| C+9 … C+11 | The attacker drives through the last 0.10 h. |
| C+12 = C′ | The real contact: pop, the target is knocked, and the exchange's bursts at C′+2. The bristle withdraws over C′ … C′+6. Then the return, as normal. |

- **Lethal:** no drive. It dies on the thorns and falls from the thorn line at C+22. This shows a strike that never connects, where the rules say the attacker doesn't attack, so the owner would have to accept that reading.
- **The literal version** (hit first, flinch after) is CB4 "after", which is already filmed as `cb4-after.mp4`, though without a flinch or thorns. It can't play lethal Thorns at all, because the attacker would hit when the rules say it doesn't.

**New pieces:** the bristle (two growth frames) and the prick flare. Drawn once per edge and rotated to the edge. It is the same at any distance.

**At speed:** the metaphor reads well (punch a bramble and it hurts). Everything happens where the eye already is. But the source and the hit sit on the same spot, a 12 f two-step contact can read as a stutter or as two hits, and the cause (Thorns) is drawn inside the attack's own motion, which is the owner's complaint.

**Time:** +12 f per attack into Thorns. Lethal: 70 f from lift to gone.

**Order check, if chosen.** What the rules log between Thorns and the exchange (Fury's Attack gain, Drum's death effects, pile-ons) would play in the hold, *before* the prick. That keeps every number true only while those changes touch different numbers from the attacker's Health. Today they do; a future card might not.

### C. Volley: the defender flings thorns

| Frame of the hold | What happens |
|---|---|
| f0–f3 | The bristle grows along the facing edges, as in B. |
| f4–f5 | Flick: three thorns break off the bristle. |
| f5–f11 | They fly to the attacker in a narrowing fan, 1 f apart, in 6 f. |
| f11–f13 | Impacts. The thorns stick in the attacker's upper face for 12 f, then drop and fade. |
| f13 | Burst, and the flinch. |
| f21 | The hold ends. |

**New pieces:** the bristle, one thorn dart, a stuck thorn, and an impact. Cheap, and the same at any distance.

**At speed:** clear cause and effect. But throwing is a ranged *attack*, and a projectile is what the family map gives all trigger damage (Gleaner, Plague), so Thorns would lose a look of its own.

**Time:** +5 f.

### D. Snare: the hedge itself bites the attacker

| Frame of the hold | What happens |
|---|---|
| f0–f3 | The defender's glow, and a small bud at its facing point. |
| f4–f8 | Thorny briars grow out of the **window's own lead lines** round the attacker's slot and close over its upper edges. They stay clear of its roundels. |
| f10 | Impact. |
| f12 | Burst, and the flinch. |
| f14–f22 | The briars withdraw into the lead. |
| f22 | The hold ends. |

**New pieces:** two or three briar clusters, and the bud.

**At speed:** very "stained glass", because the window takes part. But nothing travels from the defender, so where the damage came from is weakest of the four. It reads as a trap (Hades spikes, Hearthstone's Secrets), and a Thorns unit isn't a trap.

**Time:** +6 f.

### Pick: A, the Lash, with the flinch

- It answers the owner's reason directly. The card never moves; a drawn piece of briar does the work, along a curved path no attack takes.
- It is the only option that draws a line from the source to the victim, which every reference uses for "this came from there".
- It plays inside the hold the best proposal already has, for the same +4 f as today's stand-in. It handles lethal Thorns without inventing a strike.
- His second idea is kept as the attacker's **flinch**, the hurt reaction every effect-damage case will share (see the family map). His two ideas become cause (the lash) and effect (the flinch).

**Runner-up: B.** Use it if the lash proves busy on repeat (a Guard Lone Hawthorn), or if a long vine across a back-row attack looks wrong. It costs 8 f more per Thorns attack and blurs cause with the hit.

**After the owner's yes on pictures,** film moments (c) and (d) on the comparison fight: A against B against today's stand-in, through the compare-any-two viewer. Add one back-row case: Holly Knight's Thorns on a back-row Sortie attacker. Sound needs a cue of its own (a rustle and crack); today the build would play `fight.hit.*`.

## 5. Family map: effects that need their own language

From `src/content`. The rule underneath: **a card moving toward another card means it attacks (or Hits). Everything else is carried by a drawn piece from its source, and the victim's reaction says which kind of harm it was.**

| Effect (cards) | Today | Its own language (proposal) | Status |
|---|---|---|---|
| **Attack**: the exchange, strike back, Cleave and Overrun (Flying Ace, Ironhide Berserker, Oakfeller) | The card lunges; the target is knocked 16 px | Kept. The target is **knocked along the line**. Cleave and Overrun are part of the attack: a short glass streak from the contact to the next target, which is knocked too | best.md; streak needs art |
| **Hit**: Pile on (Needle Page, Cutpurse, Fencing Master, Bodkin, Pikeman), Ballista, Weasel | The hitter jabs 60 % of a lunge | A Hit is a unit striking, so a little motion is right, but smaller than an attack. The hitter only cocks; a weapon glint travels (a Mouse's needle, the Ballista's bolt, the Weasel's bite). The owner's "Same with the hits" is to be confirmed | Ask the owner what he meant |
| **Thorns**: Nettle Sprout, Nettle Skirmisher, Lone Hawthorn, Holly Knight | The defender jabs | **The lash** (this page); the attacker **flinches** | Pictures next |
| **Death damage**: Orchard Stripper (all enemies), Wheat Raider (a random enemy), Bumblebee (its killer) | A beat with the jab stand-in, then bursts | The dying card's own glass breaks out of its empty slot, and the shards fly to the targets (its last act, in its own colours). The victims **flinch** | Needs art; ties to R5 (mass deaths) |
| **Trigger damage**: Gleaner, Eighth Plague, Lieutenant (Start of Combat) | The source pulses and jabs | A small glass mote in the source's tribe colour arcs from the source (Super Auto Pets' and Battlegrounds' projectile). The victims **flinch**. Repeats use the combo tally | Needs art; combo-look |
| **Venomous and destroy**: Heath Adder, Hornet Queen, Bitter Toad | A burst with no number | A venom drop in ink-black and bile-yellow glass at the hit, then the card cracks along a lead line and falls. No darkening laid over the art | Needs art |
| **Prevented**: Divine Shield on stand-ins, takes no damage (Hedge Lancer, Tourney Champion), Stag Beetle against effects | A "0" burst, knock-back at 30 % | The incoming piece **glances off** a pale clear-glass gleam. A shield is a clear pane that breaks away on use. No flinch | Needs art |
| **Gains**: buffs, Fury, Grow, Old Brock, Standard-bearer, Compost entries | A number pop | The changed stat swells, and a green-glass "+N" tag flies from its cause and pins above the stat; a gold tag is an option for lasting gains ([buff-look](../buff-look/DESIGN.md), pick C) | Pictures pending |
| **Repeats** of one trigger | One burst re-popping | Gold ×N tally on the red burst, plus a warm white-gold splat ([combo-look](../combo-look/ART-DIRECTION.md)) | Pictures pending |

**What keeps it one family:**

1. **Numbers never change colour.** Every loss of Health is the one red burst; gains are green (buff-look). The *delivery* says where it came from, the number only says how much. Losses and gains look like a pair (GUIDELINES V8).
2. **The victim's reaction says what kind of harm it was.** Attacked: knocked along the line. Hurt by an effect: flinch in place. Prevented: no reaction, a glance.
3. **Colour lanes.**
   - Red: Health lost (the number).
   - Green: gains (buff-look's tag and up digits).
   - Gold silver-stain: the combo count, and lasting gains if the owner wants them marked.
   - Warm white-gold: the combo's hit splat.
   - Russet cane with bone thorns: Thorns. It is **not green**, so a vine is never read as a gain and stays clear of the green tier-2 frame.
   - Clear and pale: prevention.
   - Ink and bile yellow: venom.
   - A tribe's own glass: its death and trigger damage.
4. **Size and life.** Every delivery piece is smaller than a card, stays off the Attack and Health roundels, is gone within about 20 f, and sits where the eye already is or along the line it follows.
5. **Built the same way.** Each piece is chunky leaded glass with thick outer lead, few pieces, and a back-lit glow (the combo-look's rules).

## 6. Open for the owner (with the pictures)

- Lash (A) or prick (B), or both as the two clips to compare?
- Does the vine leave from the defender's point that faces the attacker, the rule just settled for which point of an attacking card leads, or from the whole card?
- On a lethal lash, should the vine hold the dying card until it falls?
- With Lone Hawthorn, should the vine later drag a Thorns kill toward the Compost plate? (The Compost has no fight look yet.)
- "Same with the hits": did he mean Pile on and the other Hits, or effect damage in general?

## 7. What no agent can check

- Whether the lash reads as "the bramble defends itself" or as clutter.
- Whether a 6 f whip feels sharp, and whether the longest one strobes. Strobing needs real hardware at full frame rate; a film can't show it.
- Whether the flinch looks hurt or just jittery.
- Whether it stays pleasant the tenth time in one fight.

Pictures check what is drawn. Feel is the owner's call.
