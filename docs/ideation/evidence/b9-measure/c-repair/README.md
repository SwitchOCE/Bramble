# Build 9: C's single repair round

The fixed validator accepts all original A4 seats at B and C: 64 seeds / 512 seats each, 7,448 and
7,253 seat-rounds respectively. No rejected seed and no original A4 rerun. Original B/C results and
libraries remain in [A4](../a4/full/README.md); this folder contains the one authorized C repair and
its last 64-lobby confirmation. No B dial or game rule changes.

## Fits and frozen endpoints

Engine R12 A4 medians on the same 64 seeds, using the all-surviving R12 distribution per preset
(as briefed, not a cross-arm survivor intersection): Ooze 958 at t=0 and 18,322 at t=1 give
`ln(1800/958)/ln(18322/958) = 0.2137214583`, rounded up to **0.25**. These endpoints are frozen
from A4 source 31aa4273 in `ooze-endpoints.json`; this includes the later Soup B cut to 0.2, rather
than the obsolete 0.3 in run 1's source. All other Ooze endpoints match run 1.

Hunters 585 at original-path t=1.25 and 4,463 at t=2.25 give **1.8031248364**, rounded up to **2.0**.
Use the original run-1 endpoints, not the already fitted B/C map. `fit.json`, `rates.json` and
`tools/sim/b9_c_repair.gd` reproduce the selected values and audit every snap/limit. No value is
clipped after rounding; unchanged Ooze Elder and Hasty shares equal their 1.0 limits.

## Bog: one bounded triage

The sampled C Bog Court board at seed 2911045 / seat 4 is carried by Jenny Greenteeth: 389,030 of
389,796 active stats at R12 (99.8%), and 858,551 of 872,448 at R14 (98.4%). At R10 she faces an
Ooze Tempo board with 779,536 active stats and receives **+103,796/+103,796 from Soak**. That grant
alone is 83.0% of the next round's whole board total. B's same seed/seat has 134 stats at R10,
faces a 437-stat Ooze board, and reaches 578 at R12. The detailed native per-source ledger is in
`bog-native-ledger.json`; the original captures' hashes remain in A4's receipt.

On eight of the frozen C field opponents, the exact same fight seeds and both orientations give
native Jenny 100% at R12 and R14. Resetting only her stored attack/health to printed values gives
**12.5% at R12, 62.5% at R14** (`bog-ablation.json`, `tools/sim/b9_bog_triage.gd`). Slots, golden
state, tribe bonuses, other units and rules are held. Each treatment has 16 fights per round;
this is one carry attribution, not a new balance arm or lobby run.

Soak is the clear Bog source of the stored carry, amplified by the upstream Ooze high roll. Lower
the full Bog frozen path from **1.5 to 1.0** (one 0.5 step): normal/golden Soak 4/8 → 3/6;
Tiddy 1/2 → 0.75/1.5. The simultaneous first Ooze fit also cuts the upstream food source. This
triage cannot promise the late board will shrink in direct proportion, and no second candidate is tried.

## Confirmation

Pending the single 64-lobby C-only confirmation, seeds 2911001–2911064, local jobs 3. The fixed
validator must accept every declared seat trajectory before sealing or reading it. Fields at
R10/R12/R14 and the throwaway top4 C library reuse these same captures. The settled runaway
diagnostic checks the eventual winner's ≥10× size lead at R14 or the final round if earlier;
more than half of all completed lobbies is an extreme miss. No game is dropped for ending early.
