*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the birds critic.]*

## Birds check (A3.5 step 0)

**Confirmed.** These hold as the draft states them:
- The dial values for A, B and C, and the count of 7 moving dials against the plan's 10.
- Where the code reads each dial. The text renders from the rates.
- The limits. None binds by t = 3.
- The path arithmetic. I reran the analyst's scripts and got the same numbers.
- The 0.71 calibration. The replay used all six dials of the old C.
- The cited reads: 367, 359, 2,218, 311, 270 and 472. `birds_homecoming` is the engine line (`engine_flag`).

### Corrections
1. **"The homecoming multiplier carries most of the raise."** On the joint path the two dials share it.
   - Holding h at B loses 53% of paper's log-gain at t = 1 and 43% at t = 1.6.
   - Holding Chiffchaff at +1 loses 50% and 53%.
   - So at C's t, Chiffchaff carries more. The one-dial-alone table understates it, because its gain gets multiplied at every homecoming.
   - Source: `model2.py`, replayed with each dial held in turn.
2. **"It is the only Birds dial with a measured real response (the 4× arm)."** The old C moved six dials at once: h 4, golden h 4, Egg 4, Redbreast ¼, Cuckoo ⅕ and Jack Daw ½ (`wave1-rebase.md:262–285` @322a28cb).
   - No dial has a measured response on its own.
   - Chiffchaff stayed at +1, so the 0.71 has never been tested on the dial that carries half the path.
3. **"Clamp Chiffchaff at +4 and let homecoming carry C (t ≈ 2.8)."** The 2.8 is for Chiffchaff held at +1, where B lands at t ≈ 1.85.
   - Clamped at +4 instead, B lands at t ≈ 1.1 (934) and C at t ≈ 2.0 (1,800).
   - Source: `model2.py` path with the clamp, at elasticity 0.71.
4. **"B reaches 900 at t ≈ 1.0."** At t = 1.0 the estimate is 856. It crosses 900 at t ≈ 1.05, where Chiffchaff steps up to +5 (986).
   - Source: `grid.py`.
5. **The context list leaves out the Quilboar H1 reads.** Birds at B there were 309 [283.5, 328] in the B arm (`reference/quilboar/h1.md:174`) and 313.5 in the uncut arm (`h1.md:28`).
   - B reads run from 270 to 367, and 367 is the highest.
   - Starting from 309, t_B ≈ 1.1–1.2.
6. **"Human games at today's B reached 459 and 772."** There were three testers: 329, 459 and 772 (median 459), per DECISIONS 10 Nov, "Birds: no nerf". The 459 and 772 are "two selected wins, not a sample" (`wave1-skilled-birds.md:5`).
   - The comparable skilled read is the script: 472 against the bots' 328 (×1.44).
   - So a 900 bot median means about 1,300 for skilled play.
7. **"Only the Goose-egg key and the tempo line's flier list were added."** The run's harness overlay (`5c54cb5d`) already had today's `birds.json`, including the flier list and `base_strategy`.
   - What actually changed since: the Goose-egg key; Tom Tit's damage reduction now merges with the Ooze reduction (`pass3_bird_combat.gd` `sync_protection`); and `bot_pass3.gd` reads the fly policy natively.
   - The card files are byte-identical. The effect is likely small.
8. **Citations.**
   - The Redbreast and Cuckoo share is read at `pass3_birds.gd:108`, not 107.
   - `held_units.gd:500` is the display of where a Bird away will land, not the rule. The rule is `pass3_birds.gd:40`.
9. **Text side note.** `content/schema/effects.json:916` hard-codes "comes home to hand with double stats".
   - Each flier card replaces it with its own reminder (`pass3_text.gd` `_flight`), so card text stays true.
   - That glossary line is already false at today's C.

### Corrected verdict
**Plausible on today's dials: yes, with conditions.**
- At elasticity 0.71 with the full path: B at t ≈ 1.05 and C at t ≈ 1.55 (call it 1.6).
- With Chiffchaff held at +1: B at about 1.85 and C at about 2.8. Both are still inside the caps.
- The weak point is how far paper's gains carry into real boards. At elasticity 0.5:
  - the full path still reaches 1,800 at t ≈ 2 (1,843);
  - with Chiffchaff clamped at +4, C misses at t = 3 (1,660);
  - with Chiffchaff held at +1, B misses at t = 2 (787).
- So the verdict depends on Chiffchaff's gain reaching real boards, or the elasticity being about 0.6 or higher. Run 1's fit settles it.

### Extra dials
**None needed.**
- **Size axis:** `birds_homecoming_multiplier` (B 2, C 2.5, no limit in the card text) is already the size axis, and it is on the path. Its golden twin (B 2, C 3) has no paper weight, because the scripted lines play no golden fliers.
- **Don't add `birds_trip_turns`** (2 → 1), even though a shorter trip would be the biggest lever.
  - Mrs Dunnock only acts on Birds that are 2 or more turns from home (`pass3_birds.gd` `_dunnock`), so her text would go dead.
  - One Swallow's 1-turn trip would stop being special.
- **Log one fallback limit, as a call rather than a card limit:** `birds_chiffchaff_gain` stops at +4 (today's C) if A4 shows R4–R8 spikes. At t = 1.6 it is +10/+10, and paper's R6 board goes from 41 to 128.
  - Clamped there, C moves to t ≈ 2.0, still inside the cap.
  - B's value has to be written into preset B, because B has no such key today.

Replay scripts: `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/birdcheck/clamp.py` and `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/birdcheck/hold.py`.