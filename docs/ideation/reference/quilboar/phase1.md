# Quilboar reference: Phase 1 build

Built only on `ideation/quilboar`, from `ideation/main` at `cc6d26d5`.
This branch must not be merged, cherry-picked or copied toward a player release.
The harness branch was not checked out or changed.

## Content and isolation

`content/reference/quilboar/` contains thirteen units and three spells. B is the
reference default; `quilboar_ref_preset` selects B, C or `uncut` (and the specified
A fallback). Uncut restores the Phase 1 cards' Battlegrounds numbers: whole size
steps, Hogrider's two Gems on all Quilboar, Tunneler every attack and Brigand's
three Gems. The authored source faces describe B; runtime effects use the
selected dials.

`reference_quilboar` is false in both `defaults()` and `full_game()`. Loading
requires that flag **and an editor executable**, so a saved true flag cannot
activate reference resources in an exported player executable. The configured
library is private; switching the flag off restores the original library.
Every player export explicitly excludes `content/reference/*`. Normal pool
parity still reports 109 shop units, with the original six tribes.

## Implementation and scope notes

- Gem size is two integer half-stat counters, initially 2/2. Each future Gem
  rounds Attack and Health up independently. Increasing size never rewrites
  an earlier Gem. The test UI displays the rounded current Gem value.
- Gem effects are not casts. Hand Blood Gems and Gem Days are actual spells;
  all reference spells are exempt from proportional hero/spell scaling.
- Choose One uses the existing pending-choice action, independently of
  `on_play`. Its selected modes resolve before `on_choose_one_played`.
  Trailblazer has its own per-turn budget, preserved with caps off.
- Separate permanent and temporary Gem ledgers survive capture, triples and
  combat copies. Confiscation applies three Gems first, then transfers only
  adjacent Gem-ledger stats, preserving their duration.
- Existing combat rewards use the combat stat layer plus carry-back. The Gem
  ledger measures both stat layers and records the reward's duration; combat
  rules and `combat.gd` were not changed.
- `quilboar_choose_one` is a dedicated blind Hard-brain policy: early flex,
  scheduled climbs, engine retention, an open cycling slot, mode picks,
  Created-card cycling at sell value zero, hand Gems and a late Confiscation.
  Ordinary Hard also resolves reference choices safely in mixed lobbies.
- The tree has no Click Beetle/When-played doubler. Its requested interaction
  is checked by delivering an additional `on_play` event: neither the pending
  choice, its mode nor Hogrider repeats. This is a timing-contract test, not
  a test of a nonexistent card implementation.
- Later-phase cards remain unavailable. Brigand's Gem mode works, while its
  Barrage mode is explicitly unavailable until Phase 2. The paper Choose One
  line selects the Gem mode. Early Roadboar income is also absent in Phase 1;
  this accounting limitation is recorded in the content README.
- Snare Trapper uses the income query, the reference-only rule 4.1.4 exception
  already recorded in DECISIONS.md.

## Validation

The five reference suites pass **48/48 tests**, including a three-round,
eight-seat reference-plus-Hard lobby and preservation of normal capture/state
contracts. The Python checks pass **77 tests**, including seven new
content-validator tests.

The full detached `./scripts/check.sh` passes on implementation commit
`0d465d06`: **1,942/1,942 Godot tests, 185 scripts, 43,801 assertions**; no risky or
pending tests. Compilation loads 544 files with zero failures. GUT takes
353.779 seconds (the gate's test step takes 360 seconds). All eleven gate steps
pass. The existing historical complete-game fixture passes without re-pinning.
The final documentation-only commit follows this validated implementation.

The detached driver is committed at
`tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh`. It sources
`/opt/bramble/env.sh`, uses `/tmp/bramble-godot-slot`, and keeps the systemd scope's
3 GB memory cap and timeout. The `focused` arm rejects log errors and skipped
scripts even if Godot returns zero.

```sh
systemd-run --user --collect --unit=bramble-quilboar-phase1-check \
  -p WorkingDirectory="$PWD" \
  bash tools/sim/evidence/drivers/run_quilboar_phase1_gate.sh
# Add focused as the final argument for the five reference suites only.
```

Logs and exit/status files are under `build/quilboar/`; the full gate also writes
its standard `build/check/` logs. No H1 lobbies have run at this checkpoint.
The next checkpoint measures paper accounting at B/C first, then the uncut
fidelity criterion. These reference runs remain separate from checkpoint 1.

Gate log SHA-256: `117155fd9ed26888730e983ad851420ce324b76097454b4b18edaed6fbaf9974`.
