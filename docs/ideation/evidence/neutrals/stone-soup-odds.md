# Stone Soup R6 availability audit

The observer-only replay of the original 32 native routes from `a2504fee` passed **1,536/1,536 pre-start board checks**: active Attack+Health and ordered card IDs match every original seat in R1–R6. No policy or content changes were made.

| R6 engine-seat measure | Count | Share |
|---|---:|---:|
| Soup offered | 18/32 | 56.25% |
| Soup bought | 17/32 | 53.125% |
| Soup fielded | 17/32 | 53.125% |
| Requested fielding bar | 20/32 | 62.5% |

**Buying every observed Soup opportunity can cover at most 18 of these 32 fixed traces, below the 20-seat bar.** This is an opportunity cap on the recorded traces, not a true ex-ante probability bound: changing an earlier purchase or freeze can change subsequent offers, spending, survival and the shared pool. It does not establish that another route cannot reach 20/32.

## Actual shops and shared-pool depletion

Each lobby has 19 eligible tier-1 definitions with 15 copies each: initially 285 tier-1 copies, including 15 Soup. Full-game ordinary unit shops have four slots at tiers 1–3. Tier-1 draw weights at shop tiers 1/2/3 are 100%/50%/20%, renormalized if a tier is empty. A climb does not refill the current shop. The probe records the actual draw tier, so its reference does not infer shop tiers from end-of-round climbs.

The engine seats received **696 native shop-stream draws, mean 21.75**, and made **two paid refreshes through R6** (seeds 280012 and 280019). Freezes, hero modifiers and the actual climbs produce fewer/different opportunities than assuming six fresh four-slot shops.

Before each unchanged native draw, the probe logs the exact current-state hazard:

`q(tier 1 among nonempty weighted tiers) × Soup copies left / tier-1 copies left`.

At engine draws, Soup copies remaining ranged **10–15**, total tier-1 copies **241–285**, and other seats owned up to **three Soup pool copies**. Other displayed shops also remove copies, so owned copies alone cannot reconstruct the denominator. Within-shop sampling is without replacement.

Averaging each route's `1 − product(1 − hazard)` gives a **51.052% realized-stock route reference**. Applying the same actual draw tiers to an undepleted 19-definition pool gives **50.658%**. These products follow realized histories; they are **not exact ex-ante odds** of this adaptive policy. Earlier hits can change buying, freezing and later pool states. Extra shop offers outside the unit-shop RNG remain included in the exact observed-exposure count, while the reference describes native unit-shop-stream draws.

## Single missed R6 opportunity; proposal only

Seed **280023** saw Soup beside Little Dollop in R1. The Mousewife hero’s Rainy Day spent one gold, leaving two, so neither three-gold body was bought then. R2 bought Little Dollop for three, leaving four gold. The save-three reserve then prevented buying Soup; Soup was not frozen for a later turn. This accounts for the one-seat gap between exposure (18) and buying (17).

**Proposed change, not implemented:** freeze the first unowned Soup while banking when the reserve blocks buying it. Keep Dollop's priority and the bank reserve unchanged. This targets the observed missed retention decision; it cannot make the unchanged 18-exposure trace reach a 20-seat threshold. A new counterfactual run would be needed to measure the changed route.

## Exact per-seed R6 table

“Seen R” is the first observed Soup offer; “field R” is first fielding, restricted to R6. Copy ranges are the actual pre-draw Soup stocks; held is the maximum owned Soup copies among other seats. The raw report also contains every round's end tier, paid refreshes and gold, full tier-1 stock ranges, and missed-offer actions.

| Seed | Seen R | Bought | Field R | Native draws | Soup left | Other held |
|---|---:|---:|---:|---:|---:|---:|
| 280001 | — | 0 | — | 20 | 12–14 | 1 |
| 280002 | 4 | 1 | 4 | 30 | 14–15 | 0 |
| 280005 | 5 | 1 | 5 | 20 | 12–14 | 2 |
| 280006 | 3 | 1 | 3 | 24 | 12–15 | 1 |
| 280009 | 1 | 1 | 2 | 20 | 12–13 | 1 |
| 280010 | — | 0 | — | 23 | 14–15 | 0 |
| 280011 | 5 | 1 | 5 | 20 | 14–15 | 0 |
| 280012 | — | 0 | — | 24 | 13–15 | 0 |
| 280013 | 5 | 1 | 5 | 20 | 11–15 | 3 |
| 280014 | — | 0 | — | 20 | 12–14 | 1 |
| 280015 | 1 | 1 | 2 | 20 | 10–12 | 2 |
| 280016 | 3 | 1 | 3 | 20 | 12–15 | 2 |
| 280017 | — | 0 | — | 27 | 13–15 | 0 |
| 280019 | — | 0 | — | 24 | 14–15 | 0 |
| 280021 | — | 0 | — | 20 | 13–15 | 2 |
| 280022 | — | 0 | — | 20 | 14–15 | 1 |
| 280023 | 1 | 0 | — | 20 | 12–14 | 1 |
| 280024 | — | 0 | — | 20 | 13–15 | 1 |
| 280026 | 5 | 1 | 5 | 20 | 13–15 | 1 |
| 280027 | — | 0 | — | 16 | 14–15 | 0 |
| 280028 | 3 | 1 | 3 | 30 | 13–15 | 0 |
| 280029 | — | 0 | — | 20 | 14–15 | 1 |
| 280030 | 5 | 1 | 5 | 23 | 12–14 | 2 |
| 280031 | 2 | 1 | 2 | 24 | 12–15 | 2 |
| 280032 | 2 | 1 | 2 | 24 | 11–15 | 2 |
| 280033 | — | 0 | — | 23 | 14–15 | 0 |
| 280034 | — | 0 | — | 17 | 13–15 | 1 |
| 280035 | 3 | 1 | 3 | 20 | 13–15 | 0 |
| 280037 | — | 0 | — | 20 | 14–15 | 1 |
| 280040 | 5 | 1 | 5 | 23 | 13–15 | 1 |
| 280041 | 1 | 1 | 2 | 20 | 12–13 | 1 |
| 280042 | 2 | 1 | 2 | 24 | 13–15 | 1 |

## Reproduction and limits

```
godot --headless --path . --script tools/sim/stone_soup_odds_probe.gd -- metrics=build/neutrals/soup-confirm.line-metrics.jsonl out=build/neutrals/soup-odds-probe.json
python3 tools/sim/stone_soup_odds.py build/neutrals/soup-odds-probe.json --out build/neutrals/soup-odds-report.json
```

The probe copies the live pool before initial shops and delegates to the original draw implementation without extra random calls. Its observers only read game state. Raw probe JSON and reports remain under `build/neutrals/`; the report seals their SHA-256 sources. A cleanup-only observer-binding fix after measurement removes self-references and releases the session on exit; root coordinates its parity rerun. Three Python known-answer tests cover exposure-versus-purchase denominators, changing-stock hazard products, R6 cutoff and malformed cohort rejection.

Sources: `build/neutrals/soup-confirm.{line-metrics.jsonl,rounds.csv,fights.jsonl}`, `build/neutrals/soup-odds-{probe,report}.json`; `src/core/game_config.gd:10`, `src/core/recruit_rules.gd:76`, `src/core/recruit_rules.gd:450`, `src/core/recruit_rules.gd:939`, `src/core/unit_pool.gd:126`.

## First-arrival estimate

The stopped-hazard estimate is **53.22%**, with a deterministic 10,000-resample
whole-lobby bootstrap 90% interval of **46.91–59.31%**. For each route, sum the
exact pre-draw Soup hazards only while it has not seen Soup, including the first
hit draw; then average across 32 routes. This counting-process compensator
estimates the first-arrival chance under the observed adaptive policy. It avoids
interpreting post-hit spending/freezing decisions as a no-hit counterfactual.
It is a finite-sample estimate, not a universal mathematical cap. Both the estimate
and the exact **18/32** exposed seats are below the bar's **62.5%** requirement.
Even perfect buying on this exact route can yield only 18/32; a selection fix can
recover the single missed opportunity, not the two remaining unavailable seats.

Validation: the clean probe repeats all 1,536 parity assertions and exits without
runtime diagnostics. Six pool GUT tests, four calculation tests, and
`check.sh --no-tests` pass. The latter covers ruff, gdformat, gdlint, content,
import and compilation. Compact numeric evidence is in `stone-soup-odds.json`;
raw per-draw stock states and action traces stay in `build/neutrals/`.
