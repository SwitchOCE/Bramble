*[Saved verbatim from the Soup triage workflow (wf_31f52e89-0d4: investigate, refute, synthesize), 10 Nov. Calls: DECISIONS (ideation/main) "Stone Soup triage: calls".]*

# Triage: Stone Soup is rare on Ooze engine boards

## Symptom

Engine line, preset B, 32 lobbies on c66a88e5 (`docs/ideation/evidence/wave2b/oozes-final.jsonl`; raw captures in `/home/alex/code/Bramble-ideation-balance/build/wave2b/ooze-lines-final.{rounds.csv,fights.jsonl,players.csv}`, uncommitted):

- Soup is on 6 of 26 engine boards at R12. 11 of 32 seats fielded it by R10.
- 5 of those 11 were out before R12, against 1 of the other 21 (p≈0.011). By R13 it is 7 of 11 against 3 of 21.
- Soup seats were smaller (42 vs 49 at R6, 76 vs 92 at R8, 82 vs 118 at R9) and lost more HP: median 15–16 at R10 against 26–30.5.
- The engine R12 median is 262, against targets of 900 (B) and 1,800 (C) (`oozes-summary.json`).

## Hypotheses

- **Card: kept, in part.** The text does nothing in its buy window. It gives +0 per shop unit in 17 of 24 R4–R6 Soup board-rounds and about +1/+2 at R8, against the designed +6/+6 at R9 (`oozes-pass3.md:118-126`). Each stat rounds down separately (`pass3_oozes.gd:327-328`). The body-tempo half is ruled out: there is no gap in the rounds Soup is bought. A bigger share can't reach the seats that die, because even a quarter of a 2/3 rounds to 0/0.
- **Journey: kept.** Soup lands R4–R6 (10 of 12) and is the line's first priority (`tools/sim/lines/oozes.json:6`), so it is neither late nor skipped. The break is R4–R9: Soup is bought four to six rounds before it pays.
- **Competition: ruled out.** The bot ranks Soup first (38.5 vs Nell's 28.1; `bot_ooze.gd:117-128`, `line_policies.gd:380-387`) and buys it whenever it sees it: 11 seats owned it against 12.2 expected sightings by R10. The premise that Soup is the worse buy survives through deaths, not passes: Soup seats placed 5.64 on average against 3.76 (p=0.015, engine line only, about 20 tests run).
- **Measurement: kept, in part.** The bot doesn't undervalue, sell or misplace Soup, but it overvalues it:
  - It adds +12 with no carry check, though Aspic and Elder score 0 without a carry (`bot_ooze.gd:131-144`).
  - A second plain Soup gets full value (4 seats, 2 of them dead).
  - The purchase pin refuses off-tribe bodies after R4 when there is no Digest Ooze (`committed_line_brain.gd` `_permits`). Seat 280030 bought nothing at R6–R7 with 2 empty slots (`rounds.csv`).
  - The summary's medians count survivors only, and offers are logged per tribe, not per card (`wave2b_lines.gd:143-156`).
- **System: ruled out.** The aura is recomputed on every fill, buffed units cost the same, Shy offers got the bonus in this run, and freezing only stops Nell (`pass3_oozes.gd:118-165`, `recruit_rules.gd:405-460`). Tier odds do cap reach: 25% of seats see Soup by R6 and 38% by R10. But the odds are the same for all 18 tier-2 cards, so this is the card's tier, not a system rule.
- **Payout: open.** Surviving Soup boards reach 331 against 258 at R12 (1.28×). The paper's ablation gives Soup +568, about 3×. Soup on every board would give about 330, 0.37× of the B target, so rarity is not the main reason the line misses.
- **Open:** in R4–R6 fights, Soup seats had the same stat ratio to their opponents as other seats (0.86 vs 0.89) but won 24% against 67%.

## Cards that fail their role

**Stone Soup** (Oozes, T2, 2/3). "Shop units gain an eighth of your biggest Ooze's stats." Golden (4/6): "Shop units gain an eighth of your two biggest Oozes' stats." Details: shown live, kept when bought, Shy units get none, only your best Soup counts, rounds down.

Its role is the engine enabler. It is bought in the only tier-2 shops the line sees (R4–R5) and meant to be "online on R6–7" (`oozes-pass3.md:382`). In that window it gives +0, and it takes the one 3-gold buy (18 of 32 seats end R4 on exactly 3 gold) that would otherwise get Nell, Posset or Moss. That makes it a trap in its window (triage step 3). Control: Dishwater Nell has the same tier, copies and bot code, and her seats win 70% of R5–R9 fights against 28% for Soup seats.

## Journey

- **R1–3:** Little Dollop and tier-1 bodies. No tier-2 shop appears before R4.
- **R4–6:** Soup's only window, and it is bought while it gives +0. The skip: the line ranks Soup above Little Dollop. That order was copied from the design doc's JSON (`oozes-pass3.md:567-573`), which contradicts the doc's own route, "Little Dollop… Stone Soup when you see it" (`:404`). Of the Soup seats with no Digest Ooze by R4, 4 of 6 died before R12 (0 of 8 for seats without Soup). With a Digest Ooze it was 1 of 5.
- **R7–9:** Soup gives about +1/+2 per unit. The paper engine (Soup, Bubble, Nell and Aspic down by R6–7) came together on 0 of 32 seats. Seats without a carry stall under the purchase pin.
- **R10+:** Soup pays, but too late. 3 of 6 Soup seats with a carry were dead by R13, two of them in the R12 fight.

## Process cause

The step that should have caught this is the design's paper model and journey check:

- The model puts Soup on the board by R3–R4 on every line (`oozes-pass3-model.py:138-143, 271-289`), "never misses a shop" (`oozes-pass3.md:388`), and adds the share without rounding.
- "Both are T2 cards with many copies" (`:457`) treated copies as reach. Triage step 3.4 was never run with the shop odds.
- The build audit saw the zero yield and kept it "as designed" (`wave2b-build.md:47`). Its "remove Stone Soup" low-roll row (`:46`) is actually the 62% case.
- Survivor-only medians hid the deaths.

Fix the step: each journey check should state, for every named piece, its chance of being seen by its round (from shop odds and the real climb) and its rounded yield on the board it lands on. The line JSON should follow the written route. The same cause applies to Nell, Moss, Aspic, Bubble, and every tribe's named tier-2 and tier-3 engine pieces.

## Proposed fix

The content change lands with the neutrals step (A3), before the pool settles. It adds no new A3.5 dial, because tier and rounding are fixed rules.

- **Before:** Stone Soup, Tier 2, 2/3, Oozes. "Shop units gain an eighth of your biggest Ooze's stats." Golden (4/6): "Shop units gain an eighth of your two biggest Oozes' stats." Details: shown live, and a unit keeps it when bought. Shy units get none. Only your best Stone Soup counts. Rounds down.
- **After:** Stone Soup, Tier 1, 2/3, Oozes. "Shop units gain an eighth of your biggest Ooze's stats, rounded up." Golden (4/6): "Shop units gain an eighth of your two biggest Oozes' stats, rounded up." Details: shown live, and a unit keeps it when bought. Shy units get none. Only your best Stone Soup counts. Rounds up.

Ranked by expected effect on engine seats that field Soup and are alive at R12:

1. **Tier 1 (content).** The share of seats that see Soup by R5 rises from 0.20–0.27 to 0.60–0.72, and the bot buys what it sees. A 2/3 is above the tier-1 median (4), and Soup no longer takes the buy that would get Nell. Slice Oozes go from 3/3 to 4/2 at tiers 1 and 2. Nell eats the lowest-tier offer, so check how often she eats Soup.
2. **Route (line and bot).** Put little_dollop ahead of stone_soup until a Digest Ooze is down (`oozes.json` and the design JSON). Give the +12 only with `carry(player)` (`bot_ooze.gd:117-128`). This must ship with item 1.
3. **Round up (content).** Add a Soup-only ceiling in `soup_bonus` (`pass3_oozes.gd:88-115`) and change rulebook 12.1.9 to "rounded-up" for Soup. Each shop unit then gets at least +1/+1 from the turn Soup lands, even off Soup's own body, and at most +1/+1 more at R12. This follows generous power first (09h). Risk: other tribes may buy it as a splash.
4. **Purchase pin (bot).** Let `_permits` allow off-tribe bodies after R4 for a seat with no Digest Ooze.
5. **Duplicate (bot).** Give a second plain Soup only its body value and PAIR_BONUS (`bot_eval.gd:94-98`).
6. **Harness.** Log offers, buys and Nell meals per card, and report eliminations next to the survivor medians.

None of this reaches 900. The payout gap is the next triage.

## Confirm

Rerun the same 32 seeds at B, on HEAD with dfdd20fe and the fix:

- Engine seats with Soup by R6: now 10 of 32, expect 20 or more.
- Soup seats alive at R12: now 6 of 11. Pass if Soup seats are out before R12 no more often than other seats (now 5 of 11 vs 1 of 21), and Soup is on at least half the R12 engine boards (now 6 of 26).
- Same-cohort growth from R8 to R14 for seats alive at R14, with and without Bellies, Soup seats against the rest.
- R4–R6 Soup board-rounds at +0 (now 17 of 24) and HP at R10 (now 15–16 vs 26–30.5).
- How often Nell eats Soup, where off-tribe seats that buy Soup place, and the engine R12 median against 262.
