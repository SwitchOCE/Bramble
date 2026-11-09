# Declutter batch 1: independent cold reader (10 Nov 2026)

A fresh agent saw only `cold-reader-packet.md` and the frame strips on `ideation/declutter` at 4f50d944, then a second agent scored its answers against the strips' recorded events. Criterion: spec §6 item 7, judged on source and effect attribution (the orchestrator's call for batch 1).

## Score

**Verdict: batch 1 fails the cold-reader test.** All three fights pass at x4. Rival-fight and combat_mid fail at x1, and combat_mid fails under reduce motion. This contradicts the README's "PASS".

Ground truth comes from `strips/<run>/manifest.json` → `events`. Side 0 is the bottom in all three fights. The x1, x4 and reduce event streams are identical.

R = right, C = can't tell, W = wrong. Each line gives who hit / triggers / why it died.

**rival-fight (x1 and x4 gave the same answers)**
- 025: R / Belly summon R, Old Brock's +1 aura R, Young Brock #2's Pounce trigger (a hop on bottom F2) not noticed: C / R
- 033: R / Sable's Pounce hop (x1: "stoat lifts, no reason") C / R
- 039: R / – / R
- 043: R / – / R
- 047: R / Take acorn (Young Brock #3's quarry, the toad, died) C / both deaths R
- 054: R / – / R
- 058: R / – / R
- 062: R / – / R. Hero damage (7) C.

**homecoming**
- 020: R / Pill Bug's on-attacked trigger gives the fairy +1 Attack: R / R
- 026: R / – / R
- 030: R / – / R
- 033: R / Early Spoils acorn to the bottom side C / R. Hero damage 6: R at x1, C at x4.

**combat_mid x1 and x4**
- 021: R / – / R. Why the frog reached the back row (it is Mired by the gnome) C.
- 026: R, including the wolf's Pack join / – / R
- 031: R / – / R
- 036: R / Take acorn C, with its start misplaced at x4 (it flies from the dead top F3 badger, not bottom F1). F3 fox's Take +1/+1: effect R, source C. / R
- 045: R / the "X" is the bones mark for dead fox #2's Take growth: C. Top B1 toad lift is Gideon's mire wait: C. / R
- 054: R / – / R
- 058: R / – / R
- 062: R / Take acorn (Sable's quarry died) C / R
- 069: R / Gideon's answer gives it +2 Attack and an immediate attack back: effect R, source C / –
- 075: R / the +2 expiring (4 to 2) C / R
- 080: R / – / R. Hero damage (3) C.

**combat_mid reduce**
- R: 021, 026, 031, 054, 058, 075, 080
- 036: C, and W in effect: it reads as a one-on-one trade, and the wolf's 4 is invisible.
- 045: C. 062: C.
- 069: W. The salamander attacked, but the toad reads as the actor.
- Damage and deaths are R in every attack.

**Pass or fail**

| Run | x1 | x4 | reduce |
|---|---|---|---|
| rival-fight | FAIL (Pounce ×2, Take) | PASS | – |
| homecoming | PASS* | PASS | – |
| combat_mid | FAIL (Take ×2, Take growth ×2, mire wait, Gideon's +2 gain and expiry) | PASS | FAIL (036, 045, 062, 069) |

*Early Spoils has no card source by design. I flagged it but did not count it.

**Wrong or unreadable moments, with visual causes**
1. **Reduce motion has no reliable attacker cue.** The attacker's only cue is one 0.15 s flash at a 20% tint (`combat_motion.gd` `_lunge`). Frame spacing is 0.21 to 0.30 s in 036, 045 and 062, so the flash falls between frames. In 069, frame 1 (+0.125 s) lands after the peak. Frames 0 to 3 of reduce 036 and 069 confirm no visible flash. The defender's flash is the only cue left, which is why 069 reads backwards. Joiner damage merges into one pop, which hides the wolf in 036.
2. **Take shows no source.** The acorn flies from the dead quarry to the hunter's hero, and the hunter never pulses. This affects rival 047 and combat_mid 036 and 062.
3. **Self-triggers don't link to their effect.** Pounce, mire wait, Take growth and Gideon's answer show only a glyph pulse and a hop. Nothing ties the hop to the out-of-turn attack or the stat change. This affects rival 033 and 039 and combat_mid 045, 069 and 075.
4. **Dead-unit triggers show only as bones.** The "X" in combat_mid 045 is the bones mark, with no visible effect.
5. **Counter-damage pops land where the attacker was mid-lunge.** The pop is placed at the attacker's Health mark during the lunge and stays after the card returns. Rival 025 x1, frames 3 and 4, show −16 over bottom F2. The reader's answers were still right, but this is a misattribution risk.
6. **The death drift toward the enemy reads as a second hit.** Answers stayed right.
7. **Hero damage isn't readable in the strips.** The strips end before the result phase. The rival-fight bottom hero has no Health number because the capture recorded it as −1. This is outside the criterion.
8. **The back-row hit in combat_mid 021 has no explanation.** The cause is Mire, which is a Rules-page item.

Every "who hit" and "why it died" answer is right at x1 and x4. The failures are triggers at x1 and the attacker under reduce motion.

Files are in /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/score:
- dump.py prints each run's events per attack.
- crop.py cuts single frames out of a strip.
## The reader's answers

RUN: rival-fight-x4

Starting boards. Slots are counted from the left.
- Top hero: badger, 40.
  - Back: B1 purple witch 12/16.
  - Front: F1 grasshopper with violin 9/11 (gold border); F2 toad with mug 16/20 (dotted border, reeds, paw mark); F3 dark-haired girl 7/11; F4 old goblin 6/7.
- Bottom hero: mouse, with no Health number shown in this run.
  - Front: F1 yellow ooze 6/5 with a "1" chip; F2 badger 6/6 (dotted border, a stick across its stats); F3 badger 3/4; F4 fox 5/6.
  - Back: B1 badger with key 3/6; B2 stoat 7/4; B3 fox 4/4.

025
(a) Bottom F1 ooze lunges.
(b) It hits top F2 toad: -6, so 20 to 14. The ooze takes -16.
- A top-hat creature 1/2 appears in bottom F1, where the ooze was. This matches the packet's Belly rule; the "1" chip hints that the ooze held one unit.
- Bottom B1 badger-with-key flashes and sends a gold star to the top-hat, which goes 1/2 to 2/2.
- A dark green blob appears under the toad; its cause can't be told.
- The -16 pop stays floating over bottom F2, not on the ooze.
(c) The ooze died from the toad's 16 counter-damage.

033
(a) Bottom F2 badger 6/6.
(b) It hits top F2 toad: 14 to 8. The badger takes -16.
(c) The badger died from the toad's counter-damage.

039
(a) Bottom B2 stoat 7/4.
(b) It hits top F2 toad. The pop covers the toad's Health, so 8 to 1 can't be read in x4. The stoat takes -16.
- As it dies, the stoat's card drifts back up toward the toad, which looks like a second hit.
(c) The stoat died from the toad's counter-damage.

043
(a) Top F1 grasshopper.
(b) It hits bottom F4 fox: -9. The grasshopper takes -5, so 11 to 6.
- The grasshopper's -5 pop is left on the fox.
- A green blob appears on the fox; cause can't be told.
(c) The fox died from the grasshopper's 9.

047
(a) Bottom F1 top-hat 2/2.
(b) It hits top F2 toad, which is at 16/1: the toad takes -2 and the top-hat takes -16.
- An acorn moves from near the toad toward bottom F1 or the bottom hero. Why can't be told.
(c) The toad died from the top-hat's 2. The top-hat died from the toad's 16 counter-damage.

054
(a) Top F3 girl 7/11.
(b) It hits bottom F3 badger 3/4: -7. The girl goes 11 to 8, but her -3 pop sits on the badger.
(c) The badger died from the girl's 7.

058
(a) Bottom B1 badger-with-key 3/6. The bottom front row is empty by now.
(b) It hits top F1 grasshopper 9/6. The pop hides the grasshopper going 6 to 3. The badger takes -9.
- As it dies, the badger drifts toward the top board.
(c) The badger died from the grasshopper's counter-damage.

062
(a) Top F4 goblin 6/7.
(b) It hits bottom B3 fox 4/4, the last bottom unit: -6. The goblin takes -4, so 7 to 3.
- About 5 sparks fly from the top hero and its 4 surviving units to the bottom hero.
- How much damage the bottom hero took can't be told: it has no Health number, and no pop shows.
(c) The fox died from the goblin's 6.

RUN: rival-fight-x1

The events are the same as x4. Differences:
- 025: The same answers. The order reads more clearly: bottom B1 flashes first, then the top-hat's Attack pulses 1 to 2.
- 033: The same answers. Bottom B2 stoat lifts slightly in frame 4, with no visible reason. The green blob shows again at the toad. The dying badger drifts up toward the toad.
- 039: The same answers. The toad's final 16/1 is readable.
- 043: The same answers.
- 047: The same answers.
- 054: The same answers.
- 058: The same answers. The grasshopper's 9/3 is readable.
- 062: The same answers. The sparks are only seen mid-flight. The bottom hero's damage still can't be told.

RUN: homecoming-following-combat-x4

Starting boards.
- Top hero: hare, 40.
  - Back: B1 red-haired fairy 0/1.
  - Front: F1 pangolin 3/6; F2 badger 0/3; F3 badger 2/3.
- Bottom hero: badger, 40. Every bottom unit has a dotted border.
  - Front: F1 moth-woman 6/8; F2 goblin 43/44; F3 striped bird 9/12; F4 swallow 18/20 (a ring overlay hides the Attack).
  - Back: B1 goblin 77/79 (pale blue outline); B2 robin 8/10; B3 bearded man 2/5.

020
(a) Bottom F1 moth-woman.
(b) It hits top F1 pangolin: -6. The moth takes -3, so 8 to 5.
- The pangolin brightens and sends a gold star to top B1 fairy, whose Attack goes 0 to 1. The source is the pangolin, as it dies.
(c) The pangolin died from the moth's 6.

026
(a) Top F3 badger 2/3. Top F2 badger 0/3 does not attack; why can't be told.
(b) It hits bottom F4 swallow. The pop hides the swallow going 20 to 18. The badger takes -18.
- As it dies, the badger drifts down over bottom F3.
(c) The badger died from the swallow's counter-damage.

030
(a) Bottom F2 goblin 43/44.
(b) It hits top F2 badger 0/3: -43. The goblin takes nothing.
(c) The badger died from the goblin's 43.

033
(a) Top B1 fairy 1/1. The top front row is empty.
(b) It hits bottom F2 goblin: 44 to 43. The fairy takes -43 and drifts down as it dies.
- About 6 sparks fly from the bottom units to the top hero.
- The bottom hero is now holding an acorn; why can't be told.
- The x4 strip ends with the top hero still at 40, so the damage can't be told.
(c) The fairy died from the goblin's counter-damage.

RUN: homecoming-following-combat-x1

The events are the same as x4. Differences:
- 020: The same answers. The star is seen first on the pangolin, then on the fairy.
- 026: The same answers. The swallow's 18/18 is readable.
- 030: The same answers.
- 033: The same answers. The goblin's 43/43 is readable. The top hero shows a -6 pop, and its Health counts down 40, 39, 35 within the strip.

RUN: combat_mid-x4

Starting boards.
- Top hero: hare, 34.
  - Back: B1 toad 2/6; B2 rainbow gnome 3/5; B3 toad 3/4 (paw mark).
  - Front: F1 goblin 1/3; F2 wolf 4/4; F3 badger 1/3; F4 empty.
- Bottom hero: mouse, 38.
  - Front: F1 mouse in a red hat 2/4; F2 fox 5/6; F3 fox 4/5 (paw mark); F4 badger 1/3.
  - Back: B1 salamander 1/3 (a bar over its stats); B2 frog 4/1 (a bar over its stats); B3 stoat 5/3.

021
(a) Bottom B2 frog.
(b) It hits top B2 gnome, in the back row, although the top front row is full. Why it could reach the back row can't be told: no mark or motion explains it.
- The gnome goes 5 to 1. The frog takes -3.
- The frog's -3 pop lands on the corner of top F3 badger, which stays 1/3.
- The dying frog drifts up over the wolf and badger.
(c) The frog died from the gnome's counter-damage.

026
(a) Top F1 goblin and F2 wolf lunge together. In x4 the goblin is hidden behind the wolf.
(b) They hit bottom F4 badger 1/3: -5. The goblin goes 3 to 2; the wolf takes nothing.
- The goblin's -1 pop is misplaced.
(c) The badger died from the joint hit, 1 plus 4.

031
(a) Bottom F1 mouse 2/4.
(b) It hits top F2 wolf: 4 to 2. The mouse takes -4.
- The -4 pop is left over bottom F2.
(c) The mouse died from the wolf's counter-damage.

036
(a) Top F2 wolf 4/2 and F3 badger 1/3 lunge together.
(b) They hit bottom F2 fox 5/6: -5, to 1. The wolf takes nothing.
- The fox shows two -5 pops. One is the fox's own damage; the other looks like the badger's damage taken, misplaced.
- An acorn moves from bottom F1 to the bottom hero; why can't be told.
- Bottom F3 fox pulses with a star and goes 4/5 to 5/6. No source is visible.
(c) Top F3 badger died from the fox's 5 counter-damage.

045
(a) Bottom F2 fox 5/1.
(b) It hits top F2 wolf 4/2. Both take damage: wolf -5, fox -4.
- An X token appears in bottom F2.
- Top B1 toad lifts.
- The meaning of both can't be told.
(c) The wolf died from the fox's 5. The fox died from the wolf's 4.

054
(a) Top B2 gnome 3/1.
(b) It hits bottom F3 fox 5/6: 6 to 3. The gnome takes -5.
(c) The gnome died from the fox's counter-damage.

058
(a) Bottom F3 fox 5/3.
(b) It hits top F1 goblin 1/2: -5. The fox goes 3 to 2.
- The fox's -1 pop is left over the empty bottom F1 slot.
(c) The goblin died from the fox's 5.

062
(a) Top B3 toad 3/4.
(b) It hits bottom F3 fox 5/2. Both take damage.
- An acorn moves to the bottom hero; why can't be told.
(c) The fox died from the toad's 3. The toad died from the fox's 5.

069
(a) Bottom B1 salamander 1/3.
(b) It hits top B1 toad 2/6: 6 to 5. The salamander goes 3 to 1.
- The salamander's -2 pop sits in the empty top F2 slot.
- The toad's Attack then rises 2 to 3 to 4. The cause can't be told.
(c) No deaths.

075
(a) Top B1 toad 4/5.
(b) It hits bottom B1 salamander: -4. The toad goes 5 to 4.
- Then the toad's Attack drops 4 to 3 to 2. The cause can't be told.
(c) The salamander died from the toad's 4.

080
(a) Top B1 toad 2/4.
(b) It hits bottom B3 stoat 5/3: 3 to 1. The toad takes -5.
- 2 sparks, from the bottom hero and the stoat, fly to the top hero.
- The top hero still reads 34 when the strip ends, so the damage can't be told.
(c) The toad died from the stoat's counter-damage.

RUN: combat_mid-x1

The events and answers are the same as x4. Differences:
- 021: The same answers.
- 026: Clearer. Both the goblin and the wolf are visible in the lunge.
- 031: The same answers.
- 036: The same answers.
- 045: The same answers.
- 054: The same answers.
- 058: The same answers.
- 062: The same answers.
- 069: The toad flashes, and its 4/5 is readable at the end.
- 075: The same answers.
- 080: The stoat's 5/1 is readable. The top hero's damage still can't be told.

RUN: combat_mid-x1-reduce

There are no lunges. The attacker is shown only by a flash, and the pops land on the correct units.

021
(a) Bottom B2 frog. It flashes.
(b) The top B2 gnome takes -4 and the frog takes -3.
- There is still no visible reason the back row could be hit.
(c) The frog died from the gnome's counter-damage.

026
(a) Top F1 goblin and F2 wolf. Both flash.
(b) The goblin takes -1 and bottom F4 badger takes -5.
(c) The badger died from the joint hit.

031
(a) Bottom F1 mouse. It flashes.
(b) Top F2 wolf takes -2 and the mouse takes -4.
(c) The mouse died from the wolf's counter-damage.

036
(a) Can't tell. No flash was captured. The wolf's part in the hit is invisible.
(b) Top F3 badger takes -5 and bottom F2 fox takes -5.
- A faint acorn appears in the top F3 slot.
- Bottom F3 fox flashes, gets a star and goes to 5/6. No source is visible.
(c) The badger died from the fox's 5. It looks like a one-on-one trade with the fox.

045
(a) Can't tell. There is no flash, and both pops appear at once.
(b) Top F2 wolf takes -5 and bottom F2 fox takes -4.
- An X token appears in bottom F2.
(c) The wolf and the fox killed each other.

054
(a) Top B2 gnome. It flashes.
(b) The gnome takes -5 and bottom F3 fox takes -3.
(c) The gnome died from the fox's counter-damage.

058
(a) Bottom F3 fox. It flashes.
(b) Top F1 goblin takes -5 and the fox takes -1.
(c) The goblin died from the fox's 5.

062
(a) Can't tell. No flash was seen.
(b) Top B3 toad takes -5 and bottom F3 fox takes -3, at the same time. Both fade.
(c) Both died in a mutual trade; which unit attacked can't be told.

069
(a) Can't tell. Only top B1 toad flashes: once when the pops appear, and again when its Attack rises. The salamander shows no sign at all, so the toad reads as the actor.
(b) The toad takes -1, so 6 to 5. Bottom B1 salamander takes -2.
- The toad's Attack goes 2 to 3, highlighted in yellow, and then a star covers the chip.
- The source of the Attack gain can't be told.
(c) No deaths.

075
(a) Top B1 toad. It flashes before the pops; at the start its Attack chip shows a star and then 4.
(b) The toad takes -1, so 5 to 4. The salamander takes -4.
- The toad's Attack then drops 4 to 3 to 2. The cause can't be told.
- A thin dark bar stays under the empty bottom B1 slot after the salamander has gone.
(c) The salamander died from the toad's 4.

080
(a) Top B1 toad. It flashes in frame 2.
(b) The toad takes -5 and bottom B3 stoat takes -2, ending at 5/1.
- A single star shows on the bottom hero, then on the top hero. How many sparks there were can't be told.
- The top hero still reads 34.
(c) The toad died from the stoat's counter-damage.

HARD TO READ

1. Counter-damage pops land in the wrong place (x4 and x1).
   - The attacker's own damage pop is left at the contact point of the lunge, on a bystander, the defender or an empty slot.
   - Examples:
     - rival-fight 025: the -16 pop floats over F2.
     - rival-fight 043 and 054: the attacker's pop sits on the defender.
     - combat_mid 021: the -3 pop is on the top F3 badger.
     - combat_mid 031: the -4 pop is over bottom F2.
     - combat_mid 058: the -1 pop is on an empty slot.
     - combat_mid 069: the -2 pop is in the empty top F2 slot.
   - The result: it is unclear which unit took the damage.

2. In x4, pops cover the Health number, and the strip ends before the new value shows.
   - Examples: the toad at 1 in rival-fight 039, the grasshopper at 3 in 058, the swallow in homecoming 026.
   - Hero Health also counts down after the strip ends, and out of step with the pop.

3. The death drift looks like a second attack.
   - A dying card moves toward or onto the enemy board.
   - Examples: rival-fight 033, 039 and 058; homecoming 026 and 033; combat_mid 021.

4. Joint attacks (combat_mid 026 and 036) are hard to follow.
   - In x4 the second unit is hidden behind the first.
   - The damage total doesn't match either attacker's Attack.
   - In 036 the fox shows two -5 pops.
   - In reduce motion, the wolf's part in 036 is invisible.

5. A back-row unit is hit while the front row is full (combat_mid 021). Nothing visible explains it, which contradicts the packet's front-row rule.

6. Marks and tokens appear without explanation:
   - the dark green blob (rival-fight 025, 033, 043);
   - acorns moving to heroes (rival-fight 047, homecoming 033, combat_mid 036 and 062);
   - the X token (combat_mid 045);
   - the stoat and toad lifting (rival-fight 033, combat_mid 045);
   - dotted borders, the stick or bar across stats, the reeds, the ring overlay and the blue outline.

7. Stat changes have no visible source:
   - the bottom F3 fox going to 5/6 (combat_mid 036);
   - the toad's Attack rising 2 to 4, then falling 4 to 2 (combat_mid 069 and 075).

8. Hero damage is hard to read.
   - In x4 the sparks are seen, but the damage never lands within the strip.
   - The rival-fight bottom hero has no Health number at all.
   - In reduce motion the sparks become a single star, so they can't be counted.

9. Reduce motion has no cue for direction.
   - When no flash is captured (036, 045, 062), the attacker can't be told.
   - In 069 the only flash is on the defender (the toad), so it reads as the toad acting.

10. At x1, the whole action is squeezed into frames 2 to 5, and the result frames show little.

11. The strips are not consecutive, so I couldn't check the attack order against the F1-to-F4-then-B1-to-B3 rule.
    - For example, in rival-fight the bottom B2 stoat attacks while bottom F3 and F4 haven't been seen to attack.
    - In homecoming, top F2 badger 0/3 never attacks, with no visible reason.

Files used:
- /home/alex/code/Bramble-ideation-tribes2/docs/ideation/evidence/declutter/batch1/cold-reader-packet.md
- the strips in /home/alex/code/Bramble-ideation-tribes2/docs/ideation/evidence/declutter/batch1/strips/
- crops I made from those strips, in /tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/grid/