Batch 1 fails the cold-reader test. No answer about an attack was wrong. Every hitter and every death is right at every speed, so x4 passes in all three fights. At x1 and under reduce motion, the reader missed 8 trigger moments: it saw the cue but could not tell the source or what the effect did.

Ground truth comes from the manifests. Each fight's x1, x4 and reduce runs share one event stream, with the same hash. In rival and combat_mid, side 0 is the bottom; in homecoming it is the top. Slots 0–3 are F1–F4 and slots 4–6 are B1–B3.

Marks below use R for right, W for wrong and ? for can't tell. The reader's x1 and x4 answers are the same unless noted.

**Rival** (attacks 025, 033, 039, 043, 047, 054, 058, 062)
- Who hit: R in all 8. Every death: R. Result −7, 30→23, with sparks from 4 survivors plus the hero: R.
- 025 Belly release (top-hat 1/2 comes out of the ooze): R.
- 025 Aura (Old Brock at B1 gives the top-hat +1 Attack): effect R, source ?. The reader said "can't tell which way."
- 025 Pounce (F2 → toad) and 033 Pounce (weasel → toad): the glow and the gold line are R. The effect, an attack out of turn, is ?. The reader: "I can't see why the weasel attacked now."
- 047 Take (F3 Young Brock claims the toad, acorn): R.
- Opening, from the overview only:
  - Hero +4/+4: R. Mire link to F2: R.
  - "Line from top B1 to bottom **B2** weasel": W. Belladonna's Nightshade went to bottom **B1**, Old Brock.
  - "Bottom B1 raised the weasel's Attack": W. The weasel raised its own Attack; a loop sits on its own card.
  - The 5 quarry marks and the +1 Attack buffs went unread.

**Homecoming** (attacks 020, 026, 030, 033)
- Who hit and every death: R. Result −6: R.
- 020 Pill Bug trigger (fairy +1 Attack before the hit): R. Saying what set it off is rule text, so it isn't required.
- Opening: Hedge Witch −2 and the Cradle Fetch copy: R. The Ring +4/+4, Hob's Shield and the quarry marks went unread.

**combat_mid** (attacks 021–080)
- Who hit: R in all 11, including both joint attacks: hag+wolf at 026, badger+wolf at 036. Every death: R. Result −3: R.
- 021 Bitter (leprechaun −1 on the frog): R.
- Take at 036, 045 and 062, and the fox's own +1/+1 at 036: R.
- 021 and 031 Pack (the wolf's own trigger): source ?. The reader: "no line shows a source."
- 045 kept +1/+1 on the dead fox: ?. The reader: "lands nowhere visible."
- 045 Mire wait on Gideon (sleepy toad): ?. The reader saw no source and only guessed at the skip in 054 ("possibly").
- 069 Counter: the self +2 is R. The immediate counter-attack that becomes 075 is ?. The reader reads 075 and 080 as an unexplained double turn.
- 075 Attack back down by 2: R.
- Reduce motion: the same answers and the same five gaps. Who hit and every death hold.

**Pass or fail by run**

| Run | Result |
|---|---|
| rival x1 | FAIL (3 ?) |
| rival x4 | PASS |
| homecoming x1 | PASS on the attack strips (opening partly unread) |
| homecoming x4 | PASS |
| combat_mid x1 | FAIL (5 ?) |
| combat_mid x4 | PASS |
| combat_mid reduce | FAIL (same 5 ?) |

**Wrong or unreadable moments, with the visual cause where the image shows it**
1. **Rival 025 and 033, Pounce:** the glow and the gold line are drawn. Nothing marks the line as "this unit attacks now," so 039 reads as a broken turn order.
2. **Rival 025, Aura:** the line between the top-hat and B1 has no arrowhead or travel. The ring sits on the source (B1), so B1 reads as the one receiving it.
3. **combat_mid 021 and 031, Pack:** the wolf glows and its Attack turns yellow, with no link to the partner it will join.
4. **combat_mid 036:** in frame 2 (0.37 s) only the joining wolf is shown lunging onto the fox. The badger never visibly moves, yet it takes the −5, so it looks hit by something unseen.
5. **combat_mid 045, kept +1/+1:** the badges land on the dead fox's shrunken card, which then vanishes. Nothing says the gain is kept.
6. **combat_mid 045, Mire wait:** the crossed-sword stamp on Gideon reads as something done to it. Its skipped turn only shows at 054.
7. **combat_mid 069, Counter:** checkpoint `28c873e3` removed the gold link between cards. Only the self loop remains, so 075 has no visible cause.
8. **Rival opening:** two W answers, from the overview only. In the focus sheet 022, the Belladonna line ends on bottom B1 and the weasel has a loop on its own card.

**Readability notes outside the criterion**
- At x4 the last death of each fight fades after the strip ends. The capture stops at result_tick−1.
- Under reduce motion, both 062 deaths vanish between sampled frames.
- Damage pops hide the new Health at x4.
- In homecoming there are 7 survivors, against the "about six sparks" the reader counted.
- The reader's turn-order, back-row and forced-target complaints come from Pounce, Snap/Mire and Quarry. The README lists those as Rules-page input for Batch 4.

The event dumps and my image crops are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/`.