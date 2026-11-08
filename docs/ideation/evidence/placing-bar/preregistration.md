# Placing bar — pre-registration (8 Nov 2026)

Baseline: `3aac44bb8faee4a916d4e9f18c4cbb48b1f32aae`; current pool and
`GameConfig.full_game()`, bench suite `hard_lobby_hard`.

Before any probe run: generate 24 complete fresh games, seeds **11082001–11082024**.
Sampling RNG **12082001** shuffles actual non-ghost pairings and chooses one side
per fight (no mirrored duplicate). Require 5+ recruit units. Select 50 mid-game
(rounds 6–9) and 50 late-game (round 10+) boards, screening in shuffled order.
If either stratum is short, append games sequentially through seed 11082100.

Candidate index i (zero-based, including rejected candidates) uses screening
seeds **13082000000 + 1000i + [0,39]**, search RNG seed
**14082000000 + 1000i**, evaluation seeds **15082000000 + 1000i + [0,39]**,
and shuffle RNG seed **16082000000 + 1000i**. Search's internal fight seed is
drawn from its RNG; advance deterministically if its range overlaps any screening
or evaluation range. Both evaluated layouts share fresh evaluation seeds.
Draws count as half a win. Screen inclusively at 20–80%; budget 200.

Use the rule layout as the search starting board, existing recruit pins only,
no search bonuses/gates; retain fixed slot effects, Eggs, heroes and side rules.
Report paired mean percentage-point gain with Student t interval over 100 boards;
row changes follow unit identity. Score one shuffled layout on the same seeds.

Core 2 only, background log, hard timeout 50 minutes. If necessary retain all
100 boards and reduce only held-out fight count, recording the change before
rerunning. GUT smoke seeds: game **19982001**, sampling **19982002**, same seed
formulae above; excluded from the measurement.

Results pending. Parts (a) and (b) adopted regardless of outcome; (c) unmeasured.
