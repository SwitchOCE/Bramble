# Ooze tail: triage and frozen change

Baseline: Soup 0.2, suite `a35_run1`, B, seeds 2911001–2911032. The resumed owner-provided distributions exactly match the archived Soup-fifth compact captures: engine 789.4 / 1,554 / 59,334; tempo 685 / 993 / 5,474. These captures are read-only evidence from `ideation/ooze-cut`; no baseline simulation is repeated.

| Hypothesis | Prediction / falsifier | Evidence and call |
|---|---|---|
| Native Soup→meal→Aspic→Elder→Soup feedback | Outliers' permanent gains are mostly eating and Elder; no large foreign body | True for seed 2911007 seat 4 from R8; at original Soup .3, R12 eating 66,089 plus Elder 125,040 accounts for the entire 191,129 increase. Soup is already .2; do not cut the whole Ooze engine again. |
| Cross-tribe Mallow multiplication | Foreign Hedgerow bodies dominate totals, eat/Elder gains tiny | Tempo 2911018 seat 6: two Mallows grow ×9 from R7; R12 90,226,872 visible Mallow grants versus 140 eating. Engine 2911024 seat 3: lone Mallow ×3 from R6, 72,195 of 83,910 R12 stats on original .3. Legal under the old text and its explicit “Can pick this” ruling. |
| Soak duplicates or banks unremoved power | Own/lent sources stack, wrong Mire maker, or credited loss exceeds strike decrease | The traced R10 Bridge Toad +127,941/+127,941 is legal (42,647×3), imported from the Mallow seat. Its R12 engine board is 255,910 Toad of 256,782. No duplication. The separate above-ceiling bug is fixed and tested in `soak.md`. |
| Ceiling is missing | Unit can display above 1B or wrap | Getter ceiling exists; Hedgerow's own-stat vector read wraps beyond 2.147B. Fixed and tested in `ceiling.md`. A ceiling is a numeric backstop, not a tail-shape remedy. |

**One balance change, fixed before the run:** Mrs Mallow feeds the smallest **other** Hedgerow units. B normal: “End of Turn: triple your two smallest other Hedgerow units' stats.” Golden feeds four. All multipliers and target counts stay unchanged; no rate values change. Excluding self removes the lone-Mallow splash and reduces a two-Mallow loop to ×3, preserving its intended runt-feeding role. Both authored/configured faces and bot target predictions follow this rule. A normal/golden lone-source counterexample and a two-copy two-turn known answer pin it.

Journey/competition: a tier-3 2/5 is a Hedgerow payoff, useful from R4–6 once Crumb/Sorrel/Kit/Partner bodies exist. It keeps feeding runts at full strength. An empty/non-Hedgerow board is intentionally a bad buy; previously that was its safest multiplying home. Soup/Aspic/Elder remain the Ooze route. This is a content targeting change, not a claim that the old rule was buggy.

Process cause: paper mono-tribe boards made “two smallest” sound self-limiting. Mixed-board sims plus per-source attribution should have caught that a splash strips away the smaller recipients and makes the support its own carrier. Future tail triage must name the largest bodies' tribes and the source of their gains, and distinguish cap safety from balance. Relevant neighbors: Clover shares, Committee/Lollop copies, combat Soak imports.

Confirmation is one local 32-seed run, no overrides, config `configs/ooze-other-mallow.json`. Decisions: engine R12 p90 ≤10×median; both Ooze medians ≥675. A miss will be recorded without another fit.
