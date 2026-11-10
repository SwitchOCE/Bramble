# Blind test of the runaway-growth rule (11 Nov 2026)

Two fresh agents (Fable and Sonnet) got only the rule text and 18 cards in a fixed mixed order: no answer lists, no audit reports, no worked examples that name the test cards. The brief and rule copy were scratch files; this page records the result.

Answer key. Must catch: Mrs Mallow, Alderman Dozey, Standing Committee, Charcoal Burner, Squire Lollop, Fly South homecoming, Fairy Monarch, Stone Soup, The Cuckoo, His Highness. Must keep: Honorary Treasurer, Goodman Hayward, Mr Redbreast, Aunt Aspic, Sable, Cluricaun, Jack Daw, Golden Egg.

| Round | Fable | Sonnet | Misses |
|---|---|---|---|
| 1 | 16/18 | 16/18 | Both flagged Aunt Aspic (amplifies Stone Soup's loop) and Mr Redbreast (carries the Fly South keyword but can't fly). |
| 2 | 18/18 | 18/18 | None. |

Between rounds: added the "pin a loop on the card that closes it" and "an enemy's same card doesn't count" examples, and told testers to check behaviour in code, not keyword lines.

Wording both testers still found unclear (verdicts were right; consider these as worked examples, not clauses):
- Closing vs amplifying a loop: the Cuckoo is the edge case.
- "For any one unit" doesn't fit shared numbers (Ring size, Larder gold).
- A repeating "triple" is ×3 per firing, not a lifetime cap (Mallow, Dozey); "once per Bird" is (Golden Egg).
- Compounding gated by gold or by a period still counts (Charcoal Burner, His Highness).

Data mismatches found along the way:
- Rulebook 12.1.4 says homecoming ×2; preset B is ×2.5 (golden ×3).
- Rulebook 12.1.4c says the Golden Egg doubles; the card and preset B triple.
- Mr Redbreast and The Cuckoo show the Fly South keyword but have no `fly_south` mechanic.
- Chiffchaff's JSON effect is +1/+1; text and preset B say +3.
- `src/core/mechanics/jack_daw.gd` steals Attack for the fight only; text and rates say permanent.
- Golden Egg's once-per-Bird guard, like other guards, is off when `pass3_loop_guards` is false.
