# Per-game slowdown: profile of one full Hard lobby (step 3 of the test-suite plan)

**Branch:** `ideation/c-gameprofile`, from `ideation/main` 4936633. **Machine:** cloud session, 4 cores, Godot 4.7.2, one Godot process at a time for every timing quoted.

**Lobby:** `GameConfig.full_game()` with `human_bot = "hard:varied"`: 8 Hard seats, 19 rounds, fixed seeds. Probes: `probe/lobby.gd.txt` (phase timers plus the existing `BotProfile` counters), `probe/hashes.gd.txt` (12-seed hash and timing check), `probe/top.py` (sorts the output of `godot -d --profiling`, which works headless and gives per-function self and total time with call counts).

## Time breakdown (base commit, before the fix)

| Phase | Seed 1 | Seed 2 | Share |
|---|---|---|---|
| **Bot board search: quiet rehearsal fights** (`BoardSearch` → `Combat.run`) | 13.96 s (1,380 fights) | 14.33 s (1,404 fights) | **75–78%** |
| Bot lane scoring (`BotLanes.score`/`arrange`) | 1.38 s | 1.03 s | 6–7% |
| Bot card evaluation (`BotEval`) | 0.80 s | 0.59 s | 3–4% |
| Other bot logic (shop loop, held units, search setup) | 1.44 s | 1.38 s | 8% |
| Everything outside the bots: shop and recruit rules, the 63 real logged fights, damage, game log | 0.97 s | 0.96 s | 5% |
| Library load (once per process) | 24 ms | 26 ms | <0.2% |
| Capture and hashing | 0 (no capture observer in a game) | 0 | 0% |
| **Lobby total** | 18.55 s | 18.29 s | |

Source: `raw/breakdown-before.txt`. Bot turns are 95% of a lobby (17.6 s of 18.6 s, 120 turns). Library loading, copying, logging and event building are not where the time goes: the search's fights already run with `log_events = false`.

**The hot path:** the Hard bot's placement search (`BotPlacer._searched` → `BoardSearch.best_layout` → `_Search.top_up`) plays 20 quiet fights per search, about 69 searches per lobby, at about 10 ms per fight. The budget is a bot-choice setting and was left alone. Inside those fights (`raw/script-profile-before-seed1.txt`, script time):

- death resolution (`_resolve_deaths`, 81k calls, ~56 per fight), including the aura rebuild after every death pass: ~44%;
- aura recalculation (`CombatAuras.recalc`, 24.5k calls, ~17 per fight): ~26%, mostly inside death resolution;
- `Combat.units_of`, which allocates a fresh array: 691k calls, ~15%;
- the health getter (1.48M reads), `_anyone_dying` (96k), a Hex-percent note key formatted 195k times for fights with no proportional Hex, and `BoardGeometry` tables re-typed 550k times.

No single re-parse, deep copy or quadratic scan explains the jump. The cost is a fight engine that grew with pass 3 (auras, Rings, Hexes, Birds' protection, bellies) being run about 1,400 times a lobby by the Hard search. The 7 Nov 381 ms figure was the soak, which seats half its players on random `SoakBot`s and ran the 53-card slice, so it isn't a like-for-like baseline; no bisect was run because the profile named the path.

## The fix (behaviour-preserving)

1. `BoardUnit._get_health` and `_raw_health` compute the golden factor inline (one call fewer per health read).
2. `CombatScale.hex_loss` returns 0 until a proportional Hex has been noted (`Combat.hex_percents_used`, set in `add_hex`, the only writer of those notes). `StatFraction.part(x, 0)` is 0, so the result is the same.
3. `CombatRings.bonus` returns zero for a slot with no slot effects, which is what the full path computed.
4. `BoardGeometry.adjacent`, `in_front_of` and `behind` copy typed tables built once instead of re-typing the constants each call.

No rules, numbers, budgets or bot choices changed.

## Results

**Hashes:** for 12 seeds, the hash of every real fight (round, players, winner, damage, full event list) and the hash of the game log are identical before and after (`raw/hashes-before.txt`, `raw/hashes-after.txt`). Since the search's fights decide bot placements, identical logs also show that search results didn't change.

**Per-lobby time (12 seeds, sequential, nothing else running):** 198.8 s → 176.2 s, **−11.4%** (16.6 s → 14.7 s a lobby). Script self-time on seed 1 under the profiler fell by 19% (16.1 → 13.1; the before-run also carried temporary timers).

**Gate (not a criterion):** full `./scripts/check.sh`, 1,910 tests passing both times. Tests step **418 s at 4936633 → 390 s on the branch (−7%)**. Wall time 8m02s → 7m30s. (`raw/check-*.txt`.)

## What would move it further (not done: they change bot behaviour or need a bigger refactor)

- The search budget (20 fights × ~69 searches) is the lever: halving it would roughly halve a lobby, but it changes Hard's choices.
- Caching `units_of` per side needs every writer of `Combat.sides` to invalidate it; there are about 66 call sites across the combat files.
- Running the aura rebuild once per death pass instead of on every pass with nothing new to rebuild would need a proof that no mechanic reads intermediate aura states.
- For the test suite, step 4's shared read-only Hard lobby removes repeated lobbies outright, which beats any per-fight gain.
