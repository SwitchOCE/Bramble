Cold reader on the final narrow packet (Bog fight, rival 025, combat_mid 045): score

No answer is wrong: who hit, every hit and every death are right in all seven strips. Pounce now reads. Mire's wait and all three Bog ports are "can't tell".

Truth: each manifest's events. Side 0 is the bottom. R right, ? can't tell, at every speed shot unless noted.

**Bog 017** (events 17–24)
- Who hit: Bridge Toad (bottom F1) → vole (top F3), 8 and 1 back: R.
- Bitter (the Prince → vole F2, Attack 2→1): source R, effect R.
- Toll (the Prince → its own hero, +1, total 3): source R, effect ?.
- Soak's queued gain (+2/+2 on the Prince itself): source ?, effect ?.
- Death (vole F3, from the toad's 8): R.

**Bog 025** (events 25–29)
- Who hit: vole F2 → the Prince, 1 and 3 back: R.
- Death (vole F2, from the Prince's 3): R.
- Kiss (the Prince's first of three, after its Mired vole dies): source ?, effect ?.

**Rival 025** (events 25–32)
- Who hit: Little Dollop (bottom F1) → Bridge Toad, 6 and 16 back: R.
- Belly release (Sleeping Partner, 1/2): R.
- Aura (Old Brock B1 → the partner, +1 Attack): source R, effect R.
- Pounce (Young Brock F2 attacks the toad out of turn): source R, effect R ("looks like the next attack's target").
- Death (the ooze, from the toad's 16): R.

**combat_mid 045** (events 45–53)
- Who hit: Little Nip (bottom F2) → Brother Wolf, 5 and 4: R.
- Both deaths: R.
- Take, then the dead fox's kept +1/+1 on its portrait: R.
- Mire wait (Gideon waits for the salamander it Mired): source ?, effect ?.

**Pass or fail**

| Run | ×1 | ×4 | Reduce |
|---|---|---|---|
| Bog | FAIL (Toll, queued gain, kiss) | PASS | FAIL (same) |
| rival | PASS | not reshot | PASS |
| combat_mid | FAIL (Mire wait) | not reshot | FAIL (Mire wait) |

With the batch 4 call on Mire's wait, combat_mid passes; Bog still fails.

**Unreadable moments: cause and smallest fix**
1. **Toll (017).** The hero pulses, but no amount shows and it stays 30. Fix: the splash carries "+1" and pops it briefly at the hero.
2. **Queued gain (017).** The spark hops to the Prince's own hourglass during the Toll, same green, same card, no amount. The toad's +4/+4 and the Prince's +2/+2 tags look the same. Fix: one beat after the Toll, land "+2/+2" on the tag briefly, as the dead-recipient portrait does (rulebook, pass 3: "A fight shows the amounts pending").
3. **Kiss (025).** At ×1 and ×4 the heart starts mid-gap: `_last_death` stores the dying card's centre mid-lunge (combat_screen.gd:734); under reduce, at the slot. The effect, one crown pip turning red, is a few pixels inside the crown art, under the source ring. Fix: start at the dead unit's slot, land on the pip, pulse it.
4. **Not misses.** No lunge is captured in rival 025 or combat_mid 045 (hit 32 ticks after the attack starts, samples 34–62 apart); the reader used the gold frame. Take's acorn still lands below the hero, changing nothing.

**The new cues**
- **Pounce: reads.** The gold frame moves to Young Brock, and a red sword line runs to the toad. Its lunge shows in no frame, even in 033 (attack and hit fall between ticks 1377 and 1396).
- **Mire wait: doesn't read.** The reader found both ends, but the line has no arrowhead, the crossed-circle stamp is unexplained, and it shows in one frame. Fix: the gold attacker frame on Gideon for the beat, so the skipped turn shows, and the arrival arrowhead other routes use.
- **Bog ports: none reads** (items 1–3). Toll has no standing badge; the hourglass shows that something is pending, not what; the kiss pips went unseen.
- **Kept-gain portrait:** lands and fades. The cut holds.

**Marks that stay after their moment (09e)**
- **Bleed into 025.** The Toll route, queued-gain spark and the Prince's source ring stay to frames 2–4 at ×1 and frame 5 at ×4. `gain_pending` and `bog_toll` set no effect barrier (combat_screen.gd:445–449), so the stats route-lifetime barrier misses them. Fix: give both that barrier.
- **Attacker frame** stays on the empty top F2 slot after the vole dies (025). Fix: clear it on the attacker's death.
- **Old pops.** At ×4, 017 frame 1 shows 014's pops; the reader excluded them.

**In one line:** batch 1 doesn't pass yet. Every hit and death is right, ×4 passes and Pounce now reads, but at ×1 and under reduce the three Bog ports don't show what they did, and two of them run into the next attack.
