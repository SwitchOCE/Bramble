# Placing bar — 8 Nov 2026

**Both measured parts pass.** The replacement bar remains adopted regardless of
outcome; part (c) awaits playtesters.

Measured unchanged pool, rules and bots at `3aac44b`, using
`GameConfig.full_game()` and bench suite `hard_lobby_hard`. Twenty-four fresh
complete games supplied actual non-ghost opponent pairs, captured before combat
rewards. Randomly choose one side per pair, require 5+ recruit units, shuffle,
and screen on 40 fights (20–80% win points, inclusive). Keep 100 boards:
50 rounds 6–9, 50 rounds 10+ (actual range 6–18); 353 candidates screened.

Compare rule layout against existing damage-weighted `BoardSearch`, budget 200,
starting from rule, retaining recruit pins, slot effects, Eggs, heroes and side
rules; no search gates or bonuses. Each layout and one shuffled layout receive
40 held-out fights with shared seeds. Wins score 1, draws ½. No sample or fight
count reduction.

Seeds were [pre-registered](placing-bar/preregistration.md) before running:
games **11082001–11082024**, sampling **12082001**. For screened candidate index
*i*, screening **13082000000+1000i+[0,39]**, search RNG **14082000000+1000i**,
evaluation **15082000000+1000i+[0,39]**, shuffle RNG **16082000000+1000i**.
Search internally draws uint32 seeds, disjoint from screening/evaluation.

| Measure | Result | Bar |
|---|---|---|
| (a) Search minus rule | **+23.775 points**, 95% t(99) CI **[+19.360, +28.190]** | **PASS** |
| (b) Some unit changes row | **65/100 (65%)** | **PASS** |
| Search minus shuffled smoke | **+26.750 points** | None |

Mean win points: rule **51.900%**, search **75.675%**, shuffled **48.925%**.
[Results](placing-bar/results.json), [background log](placing-bar/run.log.txt).
Core 2 only; 515.092 seconds, 50-minute timeout, exit 0, no logged errors.
Two-board/full GUT passed (1,280 tests). Single `check.sh` failed on read-only
`/opt` config; remaining stages passed using `/tmp` ([checks](placing-bar/checks.log.txt)).

Caveats: finite search and noisy 40-fight scores; sampled boards share games
(23 represented), so the requested interval over boards does not adjust for
clustering. Row changes alone do not establish opponent-specific counterplay.
Combat-only snapshots exclude recruit movement costs. No human evidence.
