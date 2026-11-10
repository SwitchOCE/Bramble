*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the fairies critic.]*

## Fairies dial check: corrections

**Confirmed against the repo:**
- All 19 Fairies dials have the stated A, B and C values (rates.json @424b3c2a), are read at the stated lines and print the stated card text.
- The R12 medians and intervals match. I recomputed them from `wave1-rebase-{B,C}.boards.json.gz`: 306, 617, 401.5 and 969.5.
- The measured runs' B and C rates equal today's.
- The factors, path rounding, solved t values and R14 multiples all match the analyst's drivers when re-run.

**Corrections:**

1. **"Most of the raise comes from `ring_growth`" / "ring growth is already the size lever."** This comes from paper only.
   - Paper at B has the rainbow done by R7, Ring size 20 and 49–50 Rings at R12.
   - Measured play disagrees. Fairies "grow by Ring count, not Ring size": real Ring size is 2 at R12 against paper's 6 (`reference/quilboar/lessons.md` L2). Fairy growth dials pass "only x1.07-1.09 against x1.65" to real boards, and Cluricaun was a trap (`evidence/wave1-triage/report.md`).
   - Both were measured on the old tier-up Cluricaun, but the "every slot has a Ring" gate is the same today.
   - So only the six dials' combined response is measured. Which dial carries it is unknown.

2. **"Because the ratio holds, the paper's shape can be applied."** One B→C step can't check the shape dial by dial.
   - That step also doubled `scale_hero_spell_percent` (10→20), changed Bog's dials and put Fairies against 4× Birds.
   - Court's real-to-paper ratio doesn't hold: 0.138 at B, 0.173 at C. So the "implied real court" column is too low.
   - On court's own real slope, at the ring line's t values (1.54 and 2.53), court lands near 1,560 at B and 3,730 at C. That is 2.1× of 1,800.

3. **"The shipped run's rates match today's A."** The rates match, but the cards don't.
   - The shipped run's source (`f9c924b9`) ran the old tier-up Cluricaun (sha `0648b76b`).
   - So the A→B rise of ×2.15 mixes the card-text change with the dial change.

4. **`fairies_initial_ring_size` is treated as Fairy-only. It isn't.**
   - Every player starts with this Ring size (`recruit_rules.gd:57` → `pass3_birds.gd:181`).
   - Two pool spells open to every tribe add Rings at that size: Spore Cloud ("Ring a slot 2 times", tier 2) and Boundary Stone (3 times, tier 4). The hero/spell scaling skips Ring spells (`flat_stat_scaling.gd:38–41`).
   - At t = 2.5 the start size is 12, so a Bird player's Boundary Stone gives +36/+36 for 2 gold. The plan's shared-dial rule applies here, at least in part.
   - Two options: hold it at each preset's value, which costs little on paper (t for B 1.56→1.64, for C 2.49→2.54); or make it Fairy-only, as the triage first proposed ("for the Fairy player only").

5. **"At the pessimistic end the ring line would just hit both caps."** It goes past both caps (t = 2.12 and 3.49), so it would run at the caps.
   - At the caps, the pessimistic slope still gives about 846 at B (0.94×) and 1,406 at C (0.78×).
   - Both are inside the plan's 0.75–2× pass band, but C's margin is thin.

6. **"Court pessimistic: not computed."** `solve.py` prints 1.46 for B and 2.71 for C.

7. **"Monarch does nothing at R12."** That holds only on paper.
   - The line reaches tier 6 at R11, and the period is 2. So a Monarch bought on R11 doubles at R12's End of Turn, before the pre-start snapshot. That affects a minority of real boards.
   - Along the path, the golden Monarch almost catches up with the normal one: 7.5 against 7 at t = 3. That is one more reason to hold Monarch.

8. **Minor:**
   - `_n` is at `pass3_text.gd:112`, not 113.
   - The R14 ÷ R12 figures (2.7 and 5.4) compare different survivor groups (186 against 264 seats at B), not one cohort.

## Corrected verdict

**Plausible on today's dials: yes.** The case rests on the real B→C response, fitted on a log scale: t = 1.54 for B and 2.53 for C, both under the caps. Even the pessimistic slope stays inside the pass band at the caps. It does not rest on paper's dial ranking. One condition: settle correction 4 (the start size) first.

## Dials

No extra dials are needed.

| Dial | B | C | Limit from card text | Call |
|---|---|---|---|---|
| `fairies_ring_growth` | 2 | 4 | none (≥0) | path |
| `fairies_lob_growth` | 1 | 3 | none | path |
| `fairies_silky_growth` | 1 | 2 | none | path |
| `fairies_initial_ring_size` | 4 | 6 | none | ask: shared leak (correction 4) |
| `fairies_monarch_multiplier` / golden | 2 / 3 | 3 / 4 | ≥1; golden must stay above normal | off path, held at 3 / 4 (ask) |

- All of these are read as decimals, so `_n` prints the raw value on the card. Rounding up to whole numbers is an ask: the path rule rounds only integer dials.

**Could another dial do more at R12?** No extra dial is proposed, so nothing needs replacing. If run 1 misses:
- `fairies_annis_rings` (1 at both presets, card "Ring the slots behind this") is the strongest Fairy-only dial not yet on the path. On paper, 1→2 gives ×1.54, close to doubling ring growth (×1.58).
- But it adds Ring count, and the wave-1 lens measured raising Annis and Sally to 2 at under 10% (DECISIONS, 10 Nov).
- The better-supported backup is the size axis that doesn't wait for the rainbow: the start size, made Fairy-only.

My check scripts are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/check/` (`s0hold.py`, `count.py`).