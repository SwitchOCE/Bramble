# S3: contaminated trial drop — 10 Nov 2026

The native baseline continues after a contaminated seed and resets its failure flag
for the next seed. Raw `ban_violation` evidence remains in the compressed capture.
Python also detects contamination in acquisition/ownership/play audits, removes
all observations for the seed (including earlier fights), and stores dropped seeds
in compact analysis and progress. Missing audits and policy mismatches remain
integrity failures.

The per-run denominator is all trials attempted, across chunks. 1/100 and exactly
2/100 pass; 3/100 fails only after all 100 trials have been attempted. Progress and
JSON/Markdown summaries report attempted count, dropped count, fraction and seeds.
Reports remain available for runs failing the contamination limit and return a
failure after writing evidence. Analysis archives separate the original attempted
plan from the accepted seed population so subsequent growth reads and bootstraps
cannot accidentally count dropped seeds.

Validation: 11 line-ban Python tests, 10 baseline/comparison Python tests and 8
peat-reader tests; targeted GUT `tests/core/test_line_bans.gd`: 8/8 tests, 57 asserts.
The Python tests exercise multi-chunk run/report behavior and exclusion of earlier
high-valued boards from medians, growth, diagnostic and survival populations.
Required ruff and GDScript lint/format checks pass.

Outside S3 ownership: `tests/sim/test_line_bans.py` changes are necessary to update
and extend the existing policy regressions. Its old `line_hunters_engine` fixture
was changed to the current canonical `line_hunters_pack`.
