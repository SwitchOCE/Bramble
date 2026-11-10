# Single shop-cycle correction rerun

The orchestrator authorized one rerun, B150 and uncut100, after clarifying that
four shop-bought cycles do not include Created Tunneler cards. C150 and frozen100
remain pre-fix in `../quilboar-h1/`; the original B/uncut measurements there are
superseded, not pooled with the new measurements. This is a test-only reference.

The frozen plan is `../quilboar-h1-cycle-fix-plan.json`, committed at `01963473`.
Its runtime source is `edfe1ed1`, including the policy fix at `4cf1a219`. Seeds
start at 2921001: B through 2921150, uncut through 2921100. No (arm, seed) lobby was repeated.
The first five completed lobbies were recovered from their existing compressed
outputs after a relative-path bookkeeping error; the recovery command is
`../drivers/recover_quilboar_h1_cycle_fix.py`. Their scope time is known, but
wall time including the lock wait was not retained. Later chunks use absolute
output paths. Lock waits are excluded from the reported seconds per lobby.

The game keeps its T6 upgrade cost of 13. The declared paper denominators use 11
and still decide accounting. The report also recomputes paper at 13, labelled
as a correction found after the original run. There is no further tuning after
an accounting failure. Roadboar is absent in Phase 1 and may depress early Gems.

Run the frozen budget on the frozen runtime tree, detached (source the standard
environment first). The controller obtains only the harness lock and gives
every Godot process a 3 GB systemd scope:

```bash
source /opt/bramble/env.sh
systemd-run --user --collect --unit=bramble-quilboar-h1-cycle-fix \
  -p WorkingDirectory="$PWD" timeout 5400 \
  bash tools/sim/evidence/drivers/run_quilboar_h1.sh run \
  --plan "$PWD/tools/sim/evidence/quilboar-h1-cycle-fix-plan.json" \
  --folder "$PWD/build/quilboar-h1-cycle-fix/run"
```

Read `build/quilboar-h1-cycle-fix/run/progress.json` with short commands. The
controller resumes recorded chunks, never resampling finished seeds. Do not
repeat the experiment from scratch after seeing its outcome.

Archive and rebuild offline after both arms complete:

```bash
python3 tools/sim/evidence/drivers/archive_quilboar_h1_cycle_fix.py
```

Each arm keeps compact captures, players, logs, receipts and accounting
checkpoints in git. Full fight captures live only under
`build/quilboar-h1-captures/quilboar-h1-cycle-fix/` (gitignored). Both compressed
and raw hashes remain in progress and receipts. A fresh checkout can rebuild
metrics without these captures; available local bytes still undergo hash checks. `progress.json` uses these archived paths;
`verification.json` records hash/seed checks, distinguishing verified local
captures from absent captures whose hashes are recorded. `summary.json.gz` is the canonical
combined metrics (new B/uncut plus retained C/frozen); the readable rendering is
`docs/ideation/reference/quilboar/h1.md`. To reproduce that rendering on a fresh
checkout from committed evidence alone:

```bash
python3 tools/sim/quilboar_h1_rerun_report.py \
  --folder tools/sim/evidence/quilboar-h1-cycle-fix \
  --out build/quilboar-h1-cycle-fix/rebuilt-h1
```

Native comparison seats use the committed wave-1 Birds/Fairies and four legacy
engine profiles. C changes only reference dials; native rates are fixed. The
post-fix uncut and pre-fix frozen arms are not a controlled size-only ablation.
Use the archived pre-fix uncut for that original comparison.
