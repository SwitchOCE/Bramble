# Several units dying at once, measured (R5, 24 Nov 2026)

The owner, 24 Nov (dictated): "In number six, where a bunch of units die… all six cards play their dying animations at once, which is fine I guess, but … if we had some way of staggering them a little bit … it would feel more realistic if they dropped off kind of like one at a time and it'd feel more impactful. I don't know how does Battlegrounds handle multiple units dying at the same time … that's another thing I'd like to investigate." On repeated triggers: "they start off slower, then speed up more as the sequence continues to trigger." And: "These aren't a firm steering... they are something you should look into."

Frames are at 60 fps unless marked. A 30 fps source is converted (1 source frame = 2 frames). Footage and frame sheets stay in `/data/fight-anim-ref/r5/`. Nothing from them is in the repo.

## Findings

1. **Hearthstone Battlegrounds (2021) uses a fast ripple, not true one-at-a-time.** An Unstable Ghoul blast put "-1" on all 13 units on the board in **one frame**. The dying units got their death mark (a red burst, then a skull) **in reading order, left to right**: first the enemy's leftmost unit, then ours from the left. The marks came **2 to 4 frames apart, about 10 frames from first to last**. Their removal was close to **together**: every skull faded within 12 frames of the others, and the later units' deaths ran shorter so the ends lined up. Each unit's death summon was already showing under its fading skull. To the eye it reads as one blast with a quick wave across it, not as six separate falls.
2. **The deaths waited for the blast effect.** The fire covered the board for about 150 frames (2.5 s), and the death marks started only about 8 to 14 frames after it cleared. From the numbers to the last card gone took about 233 frames (3.9 s). From the first death mark to the last card gone took about 70 frames (1.2 s).
3. **Once Upon a Galaxy staggers by queue, about 12 to 16 frames.** Two enemy units died in the same moment: the attacker (Despicable Sneak) and a unit that a start-of-fight spell had already set to 0 Health (Scorn). They did not fall together. The Sneak flipped and fell first. Scorn's "20" number appeared about as the Sneak began to fall, and Scorn began its fall 10 to 12 frames after that. The falls overlap, and each takes about 30 frames or more. The number stars stay on screen after the cards have gone. Two units is a small sample; I found no Galaxy footage with three or more deaths at once.
4. **Modern Battlegrounds (2025 to 2026): no clean case found.** The 2026 Shadybunny chain (`cRVjjXEnd0I` about 1617 s) has several cards break and get swapped for summons within a few frames of each other, under heavy effects. I could not tell deaths from transforms, so it is **not counted**. Single deaths in 2026 shatter 40 frames after the hit (R1, D3). Whether the 2021 ripple still exists is **unknown**.
5. **Hearthstone's constructed Twisting Nether** (`VNcgH8cH3iw`, 2013) hides the deaths under a full-screen effect, and only two minions were in play, so it was **not measured**.
6. **Our build today:** all seven "5"s show on frame 441. All six cards start their fall on frame 461, 20 frames later, and run the same 15-frame fall (dip 48 px, turn 16°, shrink to 0.72, fade from the fifth frame). The six slots are empty at 476. Old Brock's six gains ("After a friendly unit dies, gain its Attack and Health this fight") then play as the combo at 481, 497, 506, 514, 519 and 524, and the next attack lifts at 524. The fall itself takes 35 frames from the numbers to the empty slots, then 48 more for the gains.
7. **What this means for us:** none of the references shows a slow "one at a time" drop-off. Battlegrounds uses a ripple of a few frames per unit, and Galaxy staggers by its event queue (about 0.2 s). The owner's idea, a stagger that starts slower and speeds up, has no direct precedent in this footage. It is our own call, and it fits our combo look. Our rules already give the order: rulebook 9.7.3 resolves the active side's deaths first, then the other side's, each side in reading order. Rulebook 1.2.3 says this reading order is the "left to right" Battlegrounds uses. A stagger in that order shows the order in which death effects actually resolve.

## Measurement table

| Case | Link, time | Died | Start together or staggered | Order | Gaps (60 fps frames) | Each death | What the deaths' own effects wait for | Numbers vs falls | Total |
|---|---|---|---|---|---|---|---|---|---|
| HS-1 Battlegrounds, Ghoul board blast | World of Hearthstone, 20 Mar 2021, 30 fps. [youtu.be/iKxxoxUg2Qs?t=529](https://youtu.be/iKxxoxUg2Qs?t=529), 529.6–534.6 s | At least 4 marked with skulls, probably 6: 1 enemy and up to 5 of ours. The bottom-row cards overlap, so the count is ±1. Plus the Ghoul itself, earlier | **Staggered marks, near-together removal** | Reading order: the enemy's leftmost (532.70 s), then ours left to right (532.77, 532.80, 532.84, 532.87 s) | 4, 2, 2, 2: **about constant, 2 to 4 frames** (±2, because the source is 30 fps) | Mark to gone: 60 frames (enemy) to 66 frames (ours). Red burst about 24 frames, skull held about 28, fade about 12 | Death summons appear in the same slots under the fading skulls (from 533.57 s). The next effects (a stat gain on an enemy at 533.90 s, a glow at bottom left at 534.07 s) start as the last skull fades | Every "-1" in one frame (530.00 s). Death marks only 2.7 s later, after the fire clears | Numbers to last card gone: about 233 frames. First mark to last gone: about 70 |
| G-1 Galaxy, two deaths after an exchange | LSV, 17 May 2026, 60 fps. [youtu.be/4_uOk8CZu0Y?t=369](https://youtu.be/4_uOk8CZu0Y?t=369), 369.3–370.6 s | 2 (Despicable Sneak, Scorn) | **Staggered** | The attacker that died in the exchange first, then the unit whose damage was shown late (Scorn's Health fell to 0 at 368.8 s, but its "20" star only appeared at 369.77 s) | **About 12 to 16** between fall starts | Flip to the card back and a spinning drop, about 30 frames or more. Scorn's card back is still visible about 38 frames after its fall starts | Not seen: no death effects fired here | Sneak's "35" at contact (369.15 s), its fall about 35 frames later. Scorn's "20" at 369.77 s, its fall 10 to 12 frames later. The stars outlast the cards (until about 370.5 s) | First fall start to last card gone: about 50 frames |
| HS-2 Battlegrounds 2026, chain end | Shadybunny, Jun 2026. [youtu.be/cRVjjXEnd0I?t=1617](https://youtu.be/cRVjjXEnd0I?t=1617), 1617.0–1618.0 s | About 4 cards swapped for others | Within about 6 frames of each other | Unclear | n/m | Cross-fades and crumbles, under heavy effects | Not readable | n/m | **Not counted:** deaths can't be told from transforms |
| HS-3 Hearthstone Twisting Nether | TakeYourTIme Blizzard, 2013. [youtu.be/VNcgH8cH3iw](https://youtu.be/VNcgH8cH3iw) | 2 | Hidden under a full-screen effect | – | – | – | – | – | **Not counted** |
| Ours, best treatment | `/data/fight-anim-work/treatments/films/best.mp4`, film 7.35–8.73 s. Logs in `best.markers.csv` and `best.cards.csv` | 6 of ours (Orchard Stripper's last words deal 5 to every unit on our side) | **Together** | – | 0 | Fall 15 frames (461–475) | Old Brock's six gains wait for the last fall: first gain at 481, five frames after the slots are empty. Combo gaps 16, 9, 8, 5, 5 | All "5"s on frame 441. Falls start 20 frames later | Numbers to empty slots: 35 frames. To the next attack's lift: 83 |

Super Auto Pets and Legends of Runeterra: the footage on disk has no case of several units dying at once. LoR resolves its strikes one at a time (`galaxy-and-others.md`), so it never has a board-wide death to show.

## Doubts

- **What the red burst and skull mean in Battlegrounds.** I read them as the death mark, because the units removed are the ones that had them. It could instead be how the game showed lethal damage in that patch. Their timing and order hold either way.
- **The stagger in HS-1 is 2 to 4 frames in a 30 fps capture.** It is real (5 distinct onsets over 10 frames), but each gap has an error of ±2 frames. It could also be the explosion's wave moving across the board rather than a deliberate stagger. The leftmost unit went first on both rows, which fits reading order.
- **The count in HS-1.** Overlapping cards on our bottom row hide whether 4 or 5 of ours died.
- **Galaxy's order** may come from the order of its log (the attacker's death first) rather than from a design choice. It is one case.
- No 2025 or 2026 Battlegrounds board wipe could be read cleanly, so the 2021 ripple may have changed since.

## Options for us

All three keep today's numbers (frame 441), the 20-frame wait before the first fall (461) and the 15-frame fall itself. Frame numbers are those of the best film. The order rule in B and C is **rulebook 9.7.3**: the active side's dying units first, then the other side's, each side in reading order (F1–F4, then B1–B3). In this moment that is Sentry F1, Horde Runner F2, Hopper F3, Sentry B1, Horde Runner B2, Private B3. Old Brock, at F4, lives. For the owner's 18 Nov rule ("we need to make sure we don't have wildly disparate stuff"), B and C put a **hard cap on the spread** whatever the number of deaths. A wipe of 14 units then costs no more than one of 6.

### A. All at once (today)

- Falls: 461 for all six. Slots empty at 476.
- What waits: Old Brock's gains start at 481.
- Time against today: 0.
- Feel: one blast. This is the owner's "fine I guess".

### B. Fixed small ripple in board order: 4 frames

- Fall starts: **461, 465, 469, 473, 477, 481**. The last fall ends at 495, and the last slot is empty at 496.
- Gap: 4 frames, about twice Battlegrounds' 2 to 3, so it reads at 60 fps. Cap: the whole spread stays within **24 frames**, so with n deaths the gap is min(4, 24 / (n − 1)). Two deaths are 4 frames apart.
- What waits: Old Brock's gains wait for the last fall, starting at 501.
- Time against today: **+20 frames (0.33 s)**, at most +24 for any count.
- Feel: closest to Battlegrounds. It reads as a wave across the board, not as one-by-one.

### C. Speeding-up stagger, each death bringing its own effect: 10 → 7 → 5 → 4 → 4

- Fall starts: **461, 471, 478, 483, 487, 491**. Gaps of 10, 7, 5, 4, 4, with 4 as the floor. The last fall ends at 505, and the last slot is empty at 506.
- Cap: the whole spread stays within **30 frames**. With more deaths, the extra gaps stay at the 4-frame floor until the cap. If the cap would be passed, all gaps shrink by the same factor.
- What waits: **each death's own effects play as its fall lands, not after the last one.** Rulebook 9.7.2 step 2 resolves each dying unit's death effects and death counters in turn, in the 9.7.3 order, so each fall can carry its own result.
- Old Brock is a different case. "After a friendly unit dies, gain its Attack and Health this fight" is a step 3 effect, and the rules resolve step 3 only after every unit's step 2.
  - Here none of the six has a death effect (step 2 is empty), so showing each gain as its fall lands keeps the true order. The six gains would land at about 476, 486, 493, 498, 502 and 506, and replace today's separate combo (481–524).
  - When some dying units do have death effects, step 3 effects like Old Brock's wait for the last fall and then play as today's combo. Return effects (step 4) always wait for the last fall.
- Time against today: **+30 frames (0.5 s)** when the deaths trigger nothing. In this moment it is about **−18 frames**, because the gains overlap the falls instead of following them (the next lift could move from 524 to about 512, keeping today's 6-frame lead-in).
- Feel: this is what the owner described, "start off slower, then speed up". It uses the same curve as our combo, so a death chain and a combo feel alike. No reference game does this. It is our own idea.

**Lean:** C, because it is what the owner asked to explore, and pairing each fall with its result makes moments like this one shorter, not longer. B is the fallback if C feels too slow on a plain wipe. Both should be filmed on this moment and on a 2-death moment before choosing, because the motion has to be judged on the film. Neither changes the rules: the deaths still resolve at one moment. Only the screen spreads them out.

## Files

- Frame sheets (not in the repo): `/data/fight-anim-ref/r5/`: `ik_pre.png`, `ik_s36.png`, `ik_z49.png`, `ik_s72.png` and `ik_fade.png` (HS-1); `gal/g369c.png` (G-1); `crv_bottom.png` (HS-2); `ours/best_7.2_sheet.png` (ours).
- Downloaded clips: `/data/fight-anim-ref/r5/dl/iKxxoxUg2Qs.mp4` (119 MB, 720p, 30 fps) and `VNcgH8cH3iw.mp4` (6 MB).
