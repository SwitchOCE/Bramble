#!/usr/bin/env bash
# After a climbing match is kept: cut the new version's runs into the climbing field, verify,
# print its tribe picks for the interim balance report, then prune the match.
# usage: keep_version.sh MATCH_DIR NEW_LABEL
# env: FIELD (default /data/third-run/field-fa1d51ec), CORES (default 2-5)
set -euo pipefail
[[ $# -eq 2 ]] || { echo "usage: keep_version.sh MATCH_DIR NEW_LABEL" >&2; exit 2; }
match=$(realpath "$1") label=$2
field=${FIELD:-/data/third-run/field-fa1d51ec}
cores=${CORES:-2-5}
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ghosts=$here/target/release/bramble-ghosts
rules=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['rules_hash'])" "$match/summary.json")
scratch=$(dirname "$field")/cut-$label
[[ ! -e $scratch ]] || { echo "$scratch exists" >&2; exit 1; }
grep -q "NEW BETTER" "$match/verdict.txt" || { echo "verdict is not NEW BETTER" >&2; exit 1; }

# The cut tool has no label filter: cut everything into a scratch store, copy only NEW_LABEL's runs.
timeout -k 10 1200 taskset -c "$cores" "$ghosts" cut --match "$match" --store "$scratch" --ghost-store "$field" \
  --repo-root /data/third-run/match-tree --made "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
"$ghosts" verify --store "$scratch" --rules-hash "$rules"
python3 - "$scratch" "$field" "$label" <<'EOF'
import json, sys, shutil, pathlib, collections
new, field, label = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
rows = [json.loads(l) for l in (new / "index.jsonl").read_text().splitlines()]
n = 0
for r in rows:
    if r["label"] != label:
        continue
    dst = field / "runs" / r["id"][:2] / f"{r['id']}.json"
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(new / "runs" / r["id"][:2] / f"{r['id']}.json", dst)
        n += 1
    rec = new / "records" / f"{r['record_sha256']}.jsonl.gz"
    if rec.exists() and not (field / "records" / rec.name).exists():
        shutil.copy2(rec, field / "records" / rec.name)
print(f"copied {n} {label} runs")
EOF
timeout -k 10 1800 "$ghosts" index --store "$field"
timeout -k 10 1800 "$ghosts" verify --store "$field" --rules-hash "$rules"
python3 "$here/tribe_picks.py" "$field" "$label"
rm -r "${scratch:?}"
python3 "$here/analysis/prune_match.py" "$match" --kind climb --verdict kept --cut-verified
