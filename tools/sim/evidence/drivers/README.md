# Recorded local screening drivers

These are the exact three programs used for the completed caps screening and
lever-build strength comparisons. `manifest.json` maps their original `/tmp`
paths to committed copies. Every copy matches the SHA-256 sealed in
`../scale-run-execution.json`; the files have not been reformatted or migrated.
They are historical execution evidence, not the supported cloud-shard interface.

The programs contain the original absolute checkout, temporary-worktree and log
paths. They write checkpoint files and make local commits after validated stages.
**Do not run them on a new tree as a general-purpose command.** Reproduction must
use the runtime source and helper APIs recorded by
`../caps-screen-manifest.json` and `../lever-build-strength-plan.json`, together
with the recorded profile/configuration hashes. Subsequent simplification can
change those helper APIs without changing these archived bytes. The supported
portable entry point is `tools/sim/sweep_shards.py`.

The original order was all nine lobby shards, one global field-input merge, the
first field shard on a fresh checkout, the remaining fields and metric merge,
then the four fixed best-line/mixture comparisons. The supervisor kept Godot runs
sequential under the harness lock and bounded timeouts. The archive preserves
how the `.run.json` provenance inputs to `strength_gate.py` were written.

Verify the committed copies without executing them:

```sh
python3 - <<'PY'
import hashlib
import json
from pathlib import Path
manifest = json.loads(Path('tools/sim/evidence/drivers/manifest.json').read_text())
for entry in manifest['drivers']:
    data = Path(entry['archive_path']).read_bytes()
    assert len(data) == entry['bytes']
    assert hashlib.sha256(data).hexdigest() == entry['sha256']
print('all recorded driver bytes match')
PY
```

## Rebuild the three analysis-only follow-up artifacts

`rebuild_followup_evidence.py` records the previously one-off analyses. It runs no
Godot process, makes no commits, and requires an explicit output path. The raw
baseline and null/control captures remain in `build/`; the archived null field
and qualification player CSVs are tracked. Use the recorded historical data:

```sh
python3 tools/sim/evidence/drivers/rebuild_followup_evidence.py real-null --out build/sim/followup2-rebuild/real-null.json --verify-against tools/sim/evidence/real-null-dominance-result.json
python3 tools/sim/evidence/drivers/rebuild_followup_evidence.py baseline-curvature --out build/sim/followup2-rebuild/baseline-curvature.json --verify-against tools/sim/evidence/baseline-curvature.json
python3 tools/sim/evidence/drivers/rebuild_followup_evidence.py lever-reads --out build/sim/followup2-rebuild/lever-reads.json --verify-against tools/sim/evidence/lever-read-qualifications.json
```

All three reconstructions match their committed artifacts; only freshly measured
`elapsed_seconds` is excluded from comparison. Baseline captures are checked
against `baseline-progress.json`, and qualification CSV/profile hashes against
the recorded run/plan. The null command reuses the archived 1,984 fights; it does
not silently re-fight them with wave-1 rules. Historical phase/interpretation
wording is retained for reproducibility, not asserted as the current checkpoint
contract. These reconstructed commands are not claimed to be archived original
script bytes (unlike the three supervisor drivers above).

## Compressed designed evidence and the shared field driver

`run_designed_first.py` now uses `field_fights.gd ... 64 per_seed`. Default
aggregate field output retains its original seed family; the optional per-seed
mode retains the former designed driver's seed family and paired rows.
The old `designed_fights.gd` implementation is preserved in Git history.

`run_designed_first.py` changed after the first experiment ran (including the
shared-driver and archive-reader updates). The exact bytes that ran are at
**`1206ae0:tools/sim/evidence/drivers/run_designed_first.py`**; the current file is
not claimed to reproduce those original driver bytes. Retrieve them with
`git show 1206ae0:tools/sim/evidence/drivers/run_designed_first.py`.

The baseline, caps screen, lever builds, first designed field and real-null
results used pre-wave-1 combat and are not comparable with step 5's numbers.
`full_game()` now enables `pass3_content`; a pool holding pass 3 cards enables
`Pass3Combat` timing. Source-pinned old results are retained without re-fighting
them on the changed backend.

The first experiment remains historical and source-pinned. Its input checksum is
of the original JSON bytes, resolved through the verified archive pointer by
`evidence_io.json_sha`; compression does not change the frozen data checksum.
The screen result is written compressed on future runs. Existing plan source
fingerprints have not been rewritten to permit execution on a changed tree.

## Field-loop compatibility fixture

The runtime check used the original scripts at `06c918b` against the same merged
backend as the folded driver. This isolates the refactor from changes to game
rules since the historical experiment. Inputs were
`build/sim/designed-first/boundary-field.json`; both output modes matched exact
bytes (384 paired-seed rows / 6 aggregate rows). To reconstruct the old scripts:

```sh
mkdir -p build/sim/followup2-compat
git show 06c918b:tools/sim/designed_fights.gd > build/sim/followup2-compat/old_designed_fights.gd
git show 06c918b:tools/sim/field_fights.gd > build/sim/followup2-compat/old_field_fights.gd
```

Run the original and folded scripts sequentially with the normal harness lock,
3G scope and timeout. The original designed script takes `FIELD OUTPUT 64`; the
folded script takes `FIELD OUTPUT 64 per_seed`. Original/default aggregate scripts
both take `FIELD OUTPUT 2`. Compare each pair of output files byte-for-byte.
Do not compare cross-version fight winners as evidence of a driver-only change:
the older archive predates the merged combat backend. No new v3 bar was run.
