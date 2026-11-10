*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the hunters critic.]*

## Hunters dial check: corrections

**Corrections** (claim → what's true → source)

1. The copy reproduces "519 / 594" → the doc says 519 / **600**. The copy runs about 1% low on Open Season. Source: `hunters-pass3.md:401,407`.
2. "216–467, Hard bots, 7 seats" → the source says only "forced Hunter seats". The seat type is not stated, and only seats still alive are counted. So 0.43–0.92 is the spread of single seats, not a range for the ratio. Source: `review-wave2a-hunters.md:13–14`.
3. "The lobby's R12 median was about 291" → 291 comes from 8 different games at the head (`…-narrow.md:6–7`). The 270 used as today's field is from 4 games with the filter off (251 with it on): `review-wave2a-hunters.md:98`.
4. "Oozes realize 250" → engine 262, Pot Luck 200. Source: `DECISIONS.md:208`.
5. C needs ×2.9–6.4 → that assumes C is played against a field the size of B's. No C lobby exists on today's dials. At the wave 1 re-base, Fairies' C lines reached 617–970 against 306–402 at B (`wave1-rebase.md:24–31`). A field twice as big gives Hunters about ×1.57, so C needs about **×1.9–4.1**.
6. "Past t=1, each step adds ×1.07–1.16" → the rerun gives ×1.06–1.20 across fields 270–1,800.
7. "Field 532, today" → 532 is the paper's design median, not today's field.
8. "If the other tribes reach 900/1,800" → the field is the lobby median, and that sits below the engine-line targets. Using paper ×0.63, B reaches 675 (0.75×) at t=2 once the lobby's R12 median is about 450. C reaches 1,350 at t=3 once it is about 930.
9. "Text stays true on any path value" → it stays true but becomes unreadable. Takers would print "84.375%" at t=2 and "94.921875%" at t=3, and their golden copies "168.75%". `_portion` only prints halves to twelfths (text:227–247). Round to 7/8 and 1 instead; on paper the change is within noise.
10. "Each Pelt is a buff on the Glutton" → only while the Glutton holds under 35% of the board's stats. After that, Pelts go to the smallest Taker (`tools/sim/lines/hunters.json` placement; the model prints R12 Pelts "on nip").
11. "Hand limit of 10" as P3's limit → a full hand doesn't cap Pelts. Extra Pelts wait on the doorstep and "nothing is lost" (`held_units.gd:126`, `pass3_hunters.gd:86–89`). The card actually says "A full hand keeps it waiting on the doorstep" (`pelt.json`). A cap at 10 is a choice, so log it as one.
12. "Share limit 1" → the card text doesn't set it. Golden copies already print "four thirds" at B (combat:45–46), and the golden Glutton prints "twice" at C. P2 gets around the limit: at t=3 it pays 8× the quarry's stats.
13. P2's text changes miss the Laird's own details line, "'After each Take' listeners fire once" (text:189).
14. P1's and P2's R12 gains depend on the Laird fighting on R11 in every game. The committed line reaches tier 6 at R11 and "arrivals remain real draws" (`hunters.json`). Without the Laird, both add ×1.00 (rerun). So their ×0.63 realized estimates are too high.

**Checked and correct:**
- all 9 moving dials and their B and C values (rates.json:78–86, 260–268);
- A = B = base for every Hunters dial;
- every place the code reads a dial;
- the path values;
- ×1.9–4.2 and ×2.8;
- 446 and 473;
- the one-dial-at-a-time multipliers;
- the P1–P3 multipliers and the combined figures (1,244/784, 2,723/1,715, 1,356).

## Verdict

**Plausible on today's dials: no.** B at t=2 gives about 446 (0.50×), and C at t=3 about 473 (0.26×). Hunters reach their targets only if the lobby's R12 median grows to about 450 (B) and 930 (C). Neither has been measured.

## Extra dials, corrected

Paper R12 multipliers are at field 270, with the Laird / without it.

| Dial | B | C | Path t=0–3 | Limit | Paper R12 |
|---|---|---|---|---|---|
| **1. `ermeline_pelts`** (golden twin) | 1 (2) | 2 (4) | 1, 2, 4, 8 (golden 2, 4, 8, 16 → 10) | whole number, at least 1; the 10 is a choice | t=2: ×1.31 / ×1.34<br>t=3: ×2.00 / ×2.09 |
| **2. Lift the clamp on `glutton_share` and `lodger_share`** (replaces P2) | 2/3 | 1 | 0.67, 1, 1.5, 2.25 | none from text | alone: t=2 ×1.17 / ×1.19, t=3 ×1.40 / ×1.45<br>on top of dial 1: ×1.11–1.21 |
| **3. `laird_multiplier`** (P1, optional) | 2 (3) | 3 (4) | 2, 3, 5, 7 (golden 3, 4, 6, 8) | whole number, at least 1 | t=2: ×1.29 / ×1.00 |

- **Dial 1 first.** Ermeline is tier 4, on the board from R7, and fires about once a fight in real games (`review-wave2a-hunters.md:61`). It doesn't depend on the Laird.
- **Dial 2 is the size axis.** It is an existing dial, needs no code or bot change, and acts from the Glutton's R9 arrival. Its text reads "three halves" and "nine quarters". At golden, 3× would print "six halves", so add a "three times" wording.
- **Dial 3 grows R13–R15, not R12.** Leave it out of the R12 fit.
- **Drop P2.**

Dials 1 and 2 together at today's field: t=2 is 963–1,028 on paper, about 607–648 realized (0.67–0.72× of 900). t=3 is 1,709–1,781, about 1,077–1,122 (0.60–0.62× of 1,800).

The reruns are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/hcheck/cmp.py` and `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/hcheck/cmp2.py`.