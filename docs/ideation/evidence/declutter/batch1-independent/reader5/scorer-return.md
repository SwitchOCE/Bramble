*[The scorer's return value, saved verbatim from the workflow journal (wf_1c7d0562-094).]*

Batch 1 does not pass yet. Every "who hit", hit and death answer is right in all seven strips, ×4 passes, and the Pounce cue now reads. The new Mire wait cue and the three Bog ports don't read at ×1 or under reduce motion.

| Run | ×1 | ×4 | Reduce |
|---|---|---|---|
| Bog | FAIL (Toll, queued gain, kiss) | PASS | FAIL (same) |
| rival | PASS | not reshot | PASS |
| combat_mid | FAIL (Mire wait) | not reshot | FAIL (Mire wait) |

With the batch 4 call applied to Mire's wait, combat_mid passes; Bog still fails.

**Wrong or unreadable moments:**
- **Toll (017):** source right, effect "can't tell". No amount shows and the hero stays at 30. Fix: the splash carries "+1" and pops it briefly at the hero.
- **Queued gain (017):** source and effect "can't tell". It fires during the Toll in the same green from the same card, with no amount. The toad's +4/+4 tag looks the same as the Prince's +2/+2 tag. Fix: one beat after the Toll, land "+2/+2" on the tag briefly, as the dead-unit portrait already does. The rulebook says "A fight shows the amounts pending".
- **Kiss (025):** source and effect "can't tell". At ×1 and ×4 the heart starts in the gap between the boards, because the death point is stored while the dying card is mid-lunge (combat_screen.gd:734). Its effect, one crown pip turning red, is a few pixels inside the crown art. Fix: start at the dead unit's slot, land on the pip, and pulse it.
- **Mire wait (045):** the reader found both ends, but the line has no arrowhead, the crossed-circle stamp is unexplained, and it shows in one frame only. Fix: put the gold attacker frame on Gideon for the beat and add the arrowhead the other routes use.
- **No lunge is captured** at rival 025 or combat_mid 045, because it falls between samples. The reader went by the gold frame and was right.

**The new cues:**
- **Pounce: reads.** The frame handoff and the red sword line are right. Its lunge shows in no frame, even in the next attack's strip (033), because the snap falls between two samples there too.
- **Mire wait: doesn't read** (fix above).
- **Bog ports: none reads.** The Toll has no standing badge, the hourglass shows that something is pending but not what, and the reader never saw the kiss pips.
- **Kept-gain portrait:** lands and fades, so the cut holds.

**Marks that stay after their moment:**
- The Toll line, the queued-gain spark and the Prince's ring carry into attack 025: to frames 2–4 at ×1 and frame 5 at ×4. `gain_pending` and `bog_toll` set no wait-for-cue barrier (combat_screen.gd:445–449), so the one added for stat routes misses them. Fix: give both that barrier.
- The gold attacker frame stays on the empty slot after its vole dies in 025. Fix: clear it when the attacker dies.

To view frames I made crops in the scratchpad, then deleted them; only the two requested files remain.

Files are in /tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/declutter-b1-final:
- score.md
- answers.md