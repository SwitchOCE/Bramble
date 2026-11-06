# Ideation learnings

Gotchas, setup problems and what went wrong. Format as in `docs/prototype/LEARNINGS.md` (read that first: it covers this machine and the toolchain). Newest at the bottom.

### 6 Nov 18:00 — Position test: a scripted edit that didn't match left a mechanic inert

**What happened:** I patched `combat.gd` with Python `str.replace`. One pattern had the wrong indentation, so it silently changed nothing: `on_after_attacking` never fired, and Rotate did nothing through a full 1000-game batch. The numbers looked plausible. GUT tests written later caught it.
**Why:** `str.replace` doesn't complain when nothing matches, and the sim ran before the tests existed.
**Next time:** `assert s.count(old) == 1` on every scripted edit, and run a mechanic's test before running any sim that relies on it.

### 6 Nov 18:00 — Position test: placement modes changed what the bot bought

**What happened:** `Bot.buy_score` (`_row_fits`) and sell ties read the board's slots, so a different layout changes purchases. A placement arm would have tested buying too.
**Next time:** in any placement experiment, re-place the board by the heuristic before buying (`Bot.placement` does this) and test that arms own identical units until the first elimination (`test_placement_modes_buy_the_same_units`).

### 6 Nov 18:00 — Position test: a gain against "shuffled" can hide that a rule of thumb does it all

**What happened:** the bar (search beats shuffled by 0.5) passed at 0.77, but the crude heuristic alone got 0.68. And a split-half "adaptive" score still shows up to +4.6 win-rate points for plain units that can't react to anything.
**Next time:** always report against the best simple rule as well as against random, and use plain units as the noise floor.

### 6 Nov 18:00 — Sim runs: run from a snapshot, and put the time limit on each arm

**What happened:** running from an rsync snapshot let me keep editing the worktree during long batches. A single 3000 s limit around a whole batch killed the last probes; the shards had flushed their rows, so most data survived. Other sessions pushed load to 12 during the runs.
**Next time:** put the time limit on each arm, not the batch. A probe costs several times a search arm per game, so size it first.
