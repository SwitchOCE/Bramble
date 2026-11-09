# Review: shared mechanics (ideation/mechanics 04f5beb..902e4bf, Step 1 Track B)

A fresh scope reviewer, 9 Nov 2026. 23 items: 17 keep, 0 cut, 1 simplify, 5 ask. The defaults leave game logic unchanged (checked by reading the code; the gate passed at 1,632 tests; a 12-game soak was clean). It moves the problem only once step 2 sweeps the levers. The phone check shows that 4-digit stats fit, which covers the September 2025 target.

**Asks and the orchestrator's calls (all sent to the worker):**
1. **Caps-off also lifted one-shots and rate limits** (Dozey doubles every turn). Call: two switches, `card_size_caps` and `card_rate_limits`, and a warning that the overlay works by key name.
2. **The levers couldn't be switched on one at a time.** Call: `scale_levers` takes a list of ids.
3. **Lever texts left out their numbers, and the doubler's wording is wrong when copies add.** Call: show the numbers; reword the doubler.
4. **Compact k/m numbers were credited to the owner.** The request was the orchestrator's (9 Nov, after the first phone check). Call: keep the feature and fix the wording.
5. **Numerals could shrink below the phone minimum.** Call: never below the minimum. Use compact form whenever the full number won't fit, and remove the layout exception.

**Simplify, taken:** a "biggest" key on the existing `pick`, with the rulebook's tie rule for all "most" and "biggest" selection.

**Gaps, taken:**
- three opt-in cards that carry Shield, Damage Reduction, Cleave and the biggest-enemy answer;
- the percent-Hex display;
- a Shield status tag;
- displayed text matching the rules when an overlay is on;
- the overlaid library built once per game, not per fight.

## Follow-ups (same reviewer)
- **First (9b076c2): not clear, 2 cuts.**
  - A tie-breaking rewrite changed same-seed fights in the default game.
  - Card text still contradicted the rules under the overlays (Dozey, Pipkin, golden Money Spider).
- **Second (7053eaa): clear to merge.**
  - The tie rule and its RNG are restored. All 637 same-seed fight traces on seeds 93001–93012 match 04f5beb line for line.
  - `overlay_text` is added on five cards, and an 812-check test covers all 203 cards under all four overlay combinations.
  - The gate passes at 1,655 tests.
