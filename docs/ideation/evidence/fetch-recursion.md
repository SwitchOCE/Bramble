# Fetch recursion found by the full bench — 7 Nov 2026

## Failure and cause

The full default bench on 2a12020 stopped with exit 1 after `hard_lobby_normal`. Its second shard (`first_seed=251`, 250 games) logged 21 stack overflows, followed by engine stack-underflow noise. Godot still completed all 250 games, so its ordinary exit status alone could not prove the games were sound. The bench wrapper correctly rejected the log.

After the requested fetch/merge, `ideation/tribes2` fast-forwarded to b67a204 from `origin/ideation/main`. Those incoming changes were docs and combat UI; the failing fight rules were unchanged.

**Reproduced seed: `hard_lobby_normal`, 371; round 12, seats 3 versus 4.** A scan marked seeds before each game, then a single-seed run against frozen unfixed b67a204 source reproduced all 21 overflows. The exact triggering sequence:

1. Mag Pye (combat uid12) takes the standing Cradle Fetch's text (uid5, recruit iid234).
2. Sixpenny Pie releases Mr Syllabub (uid15) first, then another Fetch (uid16, iid966) into F1.
3. Syllabub fires the released Fetch's Start of Combat text. It chooses the stripped Fetch behind it.
4. Eligibility checks only the target's **current** mechanics, which no longer include Fetch. `CombatMoves.become_copy` constructs the target **as printed**, restoring Fetch, then fires its Start of Combat text. Each replacement chooses the same stripped target again.

The repeating stack is `cradle_fetch.on_start_of_combat -> CombatMoves.become_copy -> cradle_fetch.on_start_of_combat`. `_back_row_first`, `golden_factor` and `_raw_health` are where stack exhaustion surfaced, not the cause. The recursive path can exhaust the engine stack before the 10,000-trigger combat limit, and the old path does not unwind when that limit is reached.

## Fix and regression proof

Fetch's existing exclusion of another Fetch now checks both its current mechanics and its printed definition, using the same mechanic registry as copy construction. A card with stolen Fetch text remains a printed Fetch and cannot be a copy target. The current-mechanic exclusion remains in place for borrowed/granted Fetch text. No recursion-depth cap or changed card numbers are used to hide the loop.

The reduced real-card case is two friendly Fetches, F1 and B1, against Mag Pye on enemy B1. The new GUT regression without the fix logs stack overflows and aborts Godot (exit 134). With the fix, all four added tests pass: ordinary and golden stripped Fetches, a differently named card with printed Fetch mechanics (avoiding a card-id special case), and the soak's directed checks.

The soak shell wrapper already rejects script errors even when Godot exits zero; random boards had missed this interaction. Every soak now starts with both ordinary and golden versions of the directed text-transfer case. Adding those cases to unfixed source makes `tools/checks/soak.sh 1 1001` fail with exit 1 and stack overflows. They pass after the fix.

`godot --headless -s addons/gut/gut_cmdln.gd -gselect=test_copy_text`: **4/4 tests, 10 assertions**, green after the fix.

`scripts/check.sh`: **all steps pass**, 257 files compile, **958/958 tests, 10,397 assertions**, no risky/pending tests or log problems.

Fixed full-game reproduction (after sourcing `/opt/bramble/env.sh` and writable temporary XDG paths):

```sh
taskset -c 1 timeout 60 godot --headless -s res://tools/sim/bench.gd -- \
  suite=hard_lobby_normal games=1 first_seed=371 \
  out=build/sim/recursion-fixed/seed371
```

**Exit 0**, one game in 3.2 seconds, no script/engine errors. An additional local read-only reviewer found no material issue; this does not replace the orchestrator's separate cloud review.

Unfixed diagnostic artifacts remain under `build/sim/recursion-probe/`: `REPRODUCTION.txt`, frozen source, the first backtrace, round-12 boards/rules/heroes/slots, and the initiating events. Red regression logs: `/tmp/bramble-fetch-red.log` and `build/check/soak-copy-red.log`. Fixed seed log and CSVs: `build/sim/recursion-fixed/`.

## New 500-game soak

`timeout 1800 tools/checks/soak.sh 500 1001`, on fixed source after the green gate: **exit 0**, no Godot log problems. Seeds 1001–1500 differ from the previous soak's 1–200 and the failed lobby suite's 1–500. Directed ordinary/golden copy checks run first, then the usual real/synthetic/old-library mix. The detached supervisor recorded completion independently of this turn.

```text
soak: directed copy/text-transfer checks complete
soak: games 500 (seeds 1001-1500)
soak: rounds 8237, fights 26113, reasons { "board_empty": 26102, "no_attacks": 11 }
soak: max events per fight 171 (seed 1372 round 16 fight 3 v 5)
soak: time 291.0 s, 582 ms per game, slowest 1822 ms
soak: not reached this run (report only) ["trigger:on_home", "trigger:on_swallow"]
soak: slice cards never fired []
soak: slice keywords never fired ["Bristle", "Hunker"]
soak: violations 0
```

Started 09:56:21 UTC, finished 10:01:13 UTC on 7 Nov 2026. Eleven no-attacks draws are valid results, not trigger/attack-limit stalls. Coverage gaps remain visible above; this does not claim all triggers were reached by the random games. Logs and recorded status: `build/check/soak-copy500.log`, `soak-copy500-runner.log`, and `soak-copy500.exit`.

## Bench restart

The full default 17-suite, 9,000-game bench is restarted after committing/pushing this fix, under two-core affinity and a hard five-hour whole-run timeout. It uses a fresh `build/sim/bench-<fix-commit>-<UTC-start>/` directory; its `run.json` records the exact source commit, command, start, estimate and deadline. The previous failed `build/sim/bench/` artifacts are preserved. No suite sizes or balance bars are changed. The prior run took 2h24m through `hard_lobby_normal`; a complete run may reach the five-hour cap, so its detached status must be checked before claiming completion.
