# Bounded build 9 A4 pipeline

**Full A4 completed on merged source `31aa4273`.** [Owner summary and full report](full/README.md); [library paths, hashes and capture receipt](full/receipt.json).
The original two-lobby smoke is retained below as pipeline validation.

```sh
source /opt/bramble/env.sh
GODOT_SLOT_CLASS=worker python3 tools/sim/b9_a4.py --out build/b9-a4/dry-run
# Full run executed after the orchestrator supplied the merged SHA:
GODOT_SLOT_CLASS=worker python3 tools/sim/b9_a4.py --full --source-commit 31aa4273 --out build/b9-a4/final
```

The checked-in full configs use a35_run1, 64 lobbies at each preset, seeds 2911001–2911064.
The dry configs use the first two seeds at each preset. Both invoke the local runner with `--jobs 3`;
the runner acquires shared slots and preserves the 3G per-process cap. No extra outer slot is taken.
The pipeline refuses dirty gameplay/tools, changed source revisions, nonempty destinations and full runs
without an explicit matching source commit.

Field fights use the existing `tools/sim/field_fights.gd` and `tools/sim/field.py` on captured complete states.
At R10, R12 and R14, uniformly sample one surviving board per committed line with fixed seed 91407.
Run every cross-line pair in both orientations, one replication: 22 fights per line per round with all
12 lines present, under the 40 cap. Equal line weights; draws count half. This first read does not
estimate within-line board variance. Missing surviving lines are recorded, never imputed.

`tools/sim/recapture_field.sh --reuse-captures --strength top4` builds throwaway B and C field libraries
from these same native captures, without additional lobby simulations. The reuse option checks a sealed
source-commit/hash receipt; native a35_run1 labels remain intact. Outputs are under the chosen build folder,
not shipped content. Libraries retain complete trajectories and the existing top-four/rotation policy.

The generated README follows the build 8 per-line table and adds R6–R11/R11–R15 total distributions,
survival shares, per-seat window growth, field rates and R14/R15 order-of-magnitude comparisons on
identical R15-surviving cohorts. The comparison is best line median divided by the median of other line
medians, firing at 10×; per-tribe best-line ratios also expose low outliers. `report.json` preserves every
cohort count, stat-ceiling hit, tail flag and source manifest. C8's method and assumptions are printed.

The deciding growth bar is median per-seat R8–R14 growth ≥1.3 on both presets. C engine R12 medians
must be 1,350–3,600. The three v3 extremes are a tribe's best line outside an order of magnitude of the
others; one line winning whatever the player chooses; and runaway snowballs in most lobbies.
The DM2 dominance diagnostic is ≥80% field points at both R12/R14, requiring all lines. The snowball
proxy (pending orchestrator interpretation) is a ≥10× R14 lead over the runner-up that eventually wins
in >50% of eligible lobbies; R8-leader win rate is also reported. These proxies need judgment.
No dry-run values decide balance. A miss in the full run is reported, never refitted.

## Two-lobby smoke, completed

[Dry report](dry-run/README.md) and [receipt](dry-run/receipt.json) record the completed pipeline at
`91d8b726`. Two lobbies per preset (seeds 2911001–2911002), requested jobs 3; two shards actually
needed at most two lobby slots. B: 298 field fights; C: 264. Every represented line stays under 22
fights per round. Both top4 libraries contain eight complete winning trajectories; the native Godot
loader validates each and creates a field session. Later-round missing lines are explicit. These
throwaway tiny-sample libraries are plumbing checks, not the final checkpoint bundles.

The first attempt stopped after B's two lobbies because a35_run1's blind layouts lacked their capture
label. Commit `91d8b726` adds that metadata without changing play. The successful smoke recaptured B
and captured C at the fixed revision. Afterwards, the pipeline gained the same independently verified
Godot library-load check and refuses to mark incomplete magnitude cohorts as a pass.

Validation: 148/148 tests across the 13 C-reader files, plus 32/32 bench/capture/field tests; 201 Python
tests; targeted Ruff, gdlint, gdformat --check, shellcheck and whitespace checks. The full 128-lobby
run subsequently completed on `31aa4273`; see the final report above. No balance changes or refits were made during preparation.

## Full run disposition

All 128 lobbies completed locally at jobs 3, with no dropped seeds. Each preset's field read ran 396
fights (22 per line per round, complete R10/R12/R14 coverage). Each throwaway top4 library contains
256 complete trajectories across all 12 lines and passes native Godot loading/session creation.
Growth passes on all lines at both presets. B's Fairy Ring and Hunters engine scale remain low;
C's Hunters and Ooze engine scales exceed the C band. C also triggers the R15 10× and field-dominance
diagnostics. These are reported, not refitted. No extra arms or Actions simulations ran.
