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
