# Pot Luck route experiment

Source `dfdd20fe`, preset B, four arms on the same 32 seeds. `results.json` records the decision, constructed matchups and route mismatch; `growth-intervals.json` provides every reported growth estimate with cohort size and a deterministic 20,000-draw bootstrap 90% interval. The compact `*-endpoints.jsonl` files preserve the Pot Luck endpoints, gold, tier and Belly contents without fight captures. Recompute intervals with `python3 tools/sim/wave2b_growth_report.py --bootstrap-only --dataset control=.../control-endpoints.jsonl` (and likewise the other arms). Archived Hedgerow intervals use its retained `hedgerow-lines.jsonl`.

Full captures/CSVs and detached-job logs stay locally in `build/wave2b/potluck-arms/`; none are committed. The constructed R8/R10 recipes are explicitly native phase-guide stand-ins, not exact paper snapshots. They prove combat outcomes at those planted states, not route attainment. See the gold and Belly comparison in `results.json`.
