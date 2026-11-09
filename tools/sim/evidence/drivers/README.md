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

## Current wave-1 real-card smoke (128 fights)

This is separate from the pre-wave-1 first designed experiment above. Generate
recipes from the committed line files, then let Godot serialize the current
library's real recruit state. Commands run sequentially:

```sh
source /opt/bramble/env.sh
mkdir -p build/sim/wave1-followup
python3 tools/sim/designed_setups.py real --out build/sim/wave1-followup/real-recipes.json
flock /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout 90 godot --headless -s res://tools/sim/export_real_designed.gd -- build/sim/wave1-followup/real-recipes.json build/sim/wave1-followup/real-input.json
python3 tools/sim/evidence/drivers/real_designed_smoke.py prepare build/sim/wave1-followup/real-input.json build/sim/wave1-followup/real-field.json
flock /tmp/bramble-harness-godot.lock systemd-run --user --scope -q -p MemoryMax=3G timeout 90 godot --headless -s res://tools/sim/field_fights.gd -- build/sim/wave1-followup/real-field.json build/sim/wave1-followup/real-pairs.jsonl 8 per_seed
python3 tools/sim/evidence/drivers/real_designed_smoke.py report build/sim/wave1-followup/real-field.json build/sim/wave1-followup/real-pairs.jsonl build/sim/wave1-followup/real-report.json
```

On a fresh checkout, run the normal Godot import before the exporter to register
its new global class, also under the harness lock/3G scope/timeout. Only one
Godot runs at a time. The frozen smoke has two boards at R8, two at R10 and four
at R12, making eight pairs × eight seeds × two orientations = 128 fights.
The fight loop took 1.061 s; export/import startup is separate. Intervals use
whole orientation-pairs as independent seed observations and describe only the
fixed authored boards. No pass/fail gameplay bar is added.

To rebuild exactly the recorded report without any new fights, use the archived
input/pairs instead of the fresh generator:

```sh
python3 tools/sim/evidence/drivers/real_designed_smoke.py prepare tools/sim/evidence/wave1-real-input.json.gz build/sim/wave1-followup/rebuilt-field.json
python3 tools/sim/evidence/drivers/real_designed_smoke.py report build/sim/wave1-followup/rebuilt-field.json tools/sim/evidence/wave1-real-pairs.jsonl.gz build/sim/wave1-followup/rebuilt-report.json
```

This reproduces every pair count and interval. `wave1-real-smoke.json` adds
recorded runtime, archive integrity hashes and the exact runtime source hashes;
those provenance fields are not recomputed as if an offline rebuild were a run.


## Review 4 correction to the real-card smoke

The archived 128-fight real-card smoke ran the `109d404` inputs. Its all-home
Whistlers board was an exploratory omen, not the doc's R12 Tern-swap ablation;
its three Whistlers comparisons are withdrawn for that claim. The current
recipe keeps the Nest, away Birds, both Jays and tribe bonus, swaps only the
Tern, and sets Whistlers to 10/12 before Start of Combat. No field rerun is
implied. The generation commands above now produce this corrected input; use
the archived gzip input/pairs to reconstruct the original measurements.
Granny's archived rows use current pass 2 Oozes and three printed 1/1 Mice;
regeneration waits for W2b. Qualifications are recorded in
`../wave1-review4-smoke-qualifications.json` and HARNESS.md.
