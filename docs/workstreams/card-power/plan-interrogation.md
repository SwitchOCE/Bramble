# Plan interrogation: card power measures (25 Nov 2026)

A fresh Opus agent that did not write the plan followed `~/.claude/skills/plan-interrogate/SKILL.md` on the first draft of [plan.md](plan.md), with the owner's words quoted. Its result is below, unchanged. The last section says what the session did with each verdict; `plan.md` is the plan after those changes.

## The reviewer's result

The plan answers the owner's question only at step 5, after a DuckDB loader, a report command and 16,000 games are built. Much of the answer is already on disk. Blue's 18 Nov table and the 22 Nov league flag together support the owner's view on Old Brock, Sword-heir and Badgers, and partly on Brock Cub.

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| Step 1: write the definitions before reading data | Yes. Honest ranking | Agent | keep | Cheap, and stops the lines being fitted to the answer. |
| Whole-unit swap | Yes. Catches Brock Cub | Measure: owner accepted. Variant: agent | keep | Blue's fresh-copy table puts Brock Cub 93rd of 95, yet it is on 88% of Badger final boards (batch-notes l.89). Only a swap of the unit as it stood can see what Grudge gathered. |
| Text-only swap | Partly. Explains why a card is strong | Agent | keep, label it diagnosis | Same run with a different swap. It is not needed for the ranking. |
| Stand-in at tier-average stats | Risk | Agent | shrink | Buffs from other cards get credited to whichever unit received them, so a unit in a buffed slot looks strong. Flag cards whose value is mostly gathered stats. |
| Score = win/draw/loss only | Risk | Agent | ask | Late fights are often lopsided, so a flip in the result understates damage and placing. Add a damage-dealt change. |
| Keyword off for every keyword, split by enemy Health | Yes, for Overrun | Agent | shrink | Overrun plus one or two other keywords for comparison answers "any low health board". Running all of them is for the standing report. |
| Bought against passed | Weak for the named cards | Measure: owner accepted | shrink | Sword-heir is bought 96%, Old Brock 92% of offers (old-brock.md), so there are too few "passed" turns to measure them. The "main tribe" group is fixed by what was bought, so it biases the result. Group by the seat's tribe at the time of the offer. |
| Pick rate against power chart | Yes. The owner's "easy to look at" | Owner accepted | keep | Pick rate already exists in `cards.py` (buy rate when buyable). |
| Flag line: two tiers up, median | Risk | Agent | keep, check | Late swap values are small, and cards still on the board late are survivors. Compare within each stage, not across stages. |
| Step 2: swap mode in refight | Yes | Agent | keep | `refight.rs` already has paired comparisons and intervals grouped by seed line (l.390–420). Extend those. |
| Step 3: DuckDB loader | No | Agent | cut | league-data README l.27: "A DuckDB file comes only when the balance session needs something [the Python reports] can't answer." `cards.py` and `deep/cardplay.py` already read shops and buys. |
| Step 3: `card_report.sh` with HTML | Later, for the standing step | Agent | defer | The first answer to the owner can be one table and one chart. |
| Step 4: blue-c17 Badger, 4,000 games | Yes | Agent | shrink | A few hundred games covers four Badger cards. Blue's table ran on 200 games. |
| Step 4: red-c14, 4,000 games | Little | Agent | defer | The ghost field already holds 15,000 runs of earlier bots' boards as opponents. |
| Step 4: blue-c17 held to each other tribe, 4 × 2,000 | Only for "every card" | Agent | defer | 22 Nov note: blue plays only Badger well, so these runs measure the bot as much as the cards. |
| Step 5: split-half check, planted card, compare with blue's table | Yes. Trust in the numbers | Agent | keep | Cheap. |
| Step 6: flags go out at once, without waiting for a bot to pass | Yes. This is the process gap | Agent | move first | The league did catch it. 22 Nov: "referee FLAG: blue-c13 ... places 1st in 84%", Badger "likely too strong", then "Not passed, so no change yet". old-brock.md (20 Nov) recommended a rework. The finding was blocked by the gate, not missed. |
| Step 6: changes to the `bramble-design` skill | Yes, at design time | Agent | keep, as a proposal | |
| Step 6: `trace.md` | Answers "the bot climb is useful, but the resulting processes afterwards aren't" | Agent | keep, short | Built from the notes above. |
| Step 7: clean up | Housekeeping | Agent | keep | |

**Fixed after step**
- In the plan as written: step 5 answers whether the owner's view is borne out. The "catch this in future" half is fixed only at step 6, and only if the owner says yes.
- In the reordered plan:
  - Step 0, today: show blue's existing table and the 22 Nov flag. The owner's view is partly borne out already: Old Brock is 1st from round 4, Sword-heir fights like a tier 5 card, and the Badger tribe is "far outside" its target.
  - The step after swap mode: whole-unit swap on one Badger match shows Brock Cub, which blue's table cannot see.
  - The process half: fixed when the owner accepts the rule change "a flag doesn't wait for a bot to pass".

**Smallest plan**
1. Report the existing evidence now: blue's table, batch-notes lines 86–104, old-brock.md. Say clearly that Brock Cub is unanswered.
2. Write the definitions: whole-unit swap, text-only swap, Overrun off split by enemy Health, plus the flag line.
3. Add swap mode to refight.
4. Run it on one blue-c17 Badger ghost match of about 500 games, plus the opponent boards in it. Answer the owner on the four cases.
5. Bought against passed and pick rate from the existing `cards.py` data, plus one chart.
6. Propose the process changes: flags go out at once, quote the card's line in design pitches, and the cost rule for effects that grow with the board.

**Deferred**
- DuckDB: until a question comes up that the Python reports can't answer.
- `card_report.sh` with HTML: when the owner accepts the report as a standing step.
- The red-c14 run, the per-tribe held runs, and every keyword switched off: when "every card" ranking matters, such as before the next tribe or after a bot passes.

**Checkpoints**
- After step 1 (existing evidence): the owner may already act on Old Brock and Sword-heir.
- After step 4 (first swap results).
- After step 6 (process proposals).

**Open questions**
1. Should a flag lead to a card change before any bot passes? The current rule says no change until one does. That rule, not a missing measure, held back the 22 Nov flag.
2. Should the swap score count damage dealt, or only win, draw or loss?
3. Is a first report on Badger only acceptable, with other tribes later?

## What the session did with it

- Accepted: existing evidence shown first; no DuckDB; the report command after the first answer; Overrun plus two keywords; bought against passed grouped by the tribe at the time of the offer; cards compared inside one stage; a mark on cards whose value is mostly gathered stats; no held-tribe runs.
- Open question 1 went to the owner as a decision.
- Open question 2, decided by the session: the change in damage is reported next to the win score; the flag line stays on the win score.
- Open question 3, decided by the session: the first match holds 1,000 red-c14 games as well as 1,000 blue-c17 games (ten minutes in all), and fights between the field's ghosts cover the other tribes, so the first report ranks every card with enough data.
- Not accepted: dropping the one-command report. The owner asked how to "make sure that our processes catch this in the future"; it is built after the first answer.
