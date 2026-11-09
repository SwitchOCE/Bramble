# H1 complete

The original 500-lobby report was finished and committed at `0f86f4e3` before
changing the cycle policy. Its canonical metrics remain in
`tools/sim/evidence/quilboar-h1/summary.json.gz`.

The one authorized shop-cycle correction rerun is complete: B150 and uncut100,
on frozen fresh seeds starting at 2921001. C150 and frozen100 retain their
pre-fix results. Both deciding criteria fail after the correction, so no more
tuning was done. All new lobbies used the harness lock only and a 3 GB scope.
Their total Godot scope time was 887.07 seconds (14.8 minutes); lock contention
added wall time. No completed lobby was repeated after the bookkeeping failure.

The final measurements, paper cost correction, method-gap interpretation and
R6–R15 medians beside every native line are in [h1.md](h1.md). New evidence and
rebuild instructions are under `tools/sim/evidence/quilboar-h1-cycle-fix/`.
Targeted checks passed: 64 Godot tests and 22 Python tests. No new full gate.
