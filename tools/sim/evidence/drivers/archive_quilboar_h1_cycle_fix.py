#!/usr/bin/env python3
"""Archive and rebuild the complete one-off rerun report without Godot.

Run after progress reaches B150/uncut100. The canonical summary is compressed;
its progress paths point to committed evidence so the report can be rebuilt.
"""
import copy
import gzip
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools/sim'))
from checkpoint_quilboar_h1 import archive  # noqa: E402
from evidence_io import read_json, write_json  # noqa: E402
from quilboar_h1 import file_sha, load_lobbies  # noqa: E402
from quilboar_h1_report import summarize, write_report  # noqa: E402
from quilboar_h1_rerun_report import combine  # noqa: E402

plan_path = ROOT / 'tools/sim/evidence/quilboar-h1-cycle-fix-plan.json'
folder = ROOT / 'build/quilboar-h1-cycle-fix/run'
target = ROOT / 'tools/sim/evidence/quilboar-h1-cycle-fix'
progress = read_json(folder / 'progress.json')
if progress['state'] != 'complete' or progress['completed'] != {'B': 150, 'uncut': 100}:
    raise ValueError('both frozen arms must be complete')
if progress['plan_sha256'] != file_sha(plan_path):
    raise ValueError('changed frozen plan')
for arm in ('B', 'uncut'):
    archive(arm, plan_path, folder, target)
archived_progress = copy.deepcopy(progress)
archived_progress['chunks'] = [
    chunk
    for arm in ('B', 'uncut')
    for chunk in read_json(target / arm / 'receipt.json')['chunks']
]
for chunk in archived_progress['chunks']:
    if file_sha(ROOT / chunk['capture']) != chunk['capture_gzip_sha256']:
        raise ValueError('changed compressed capture')
    digest = hashlib.sha256()
    with gzip.open(ROOT / chunk['capture'], 'rb') as source:
        while block := source.read(1024 * 1024):
            digest.update(block)
    if digest.hexdigest() != chunk['capture_sha256']:
        raise ValueError('changed decompressed capture')
lobbies = load_lobbies(archived_progress)
first = read_json(plan_path)['first_seed']
for arm, count in archived_progress['completed'].items():
    seeds = [game['seed'] for game in lobbies if game['arm'] == arm]
    if len(seeds) != count or set(seeds) != set(range(first, first + count)):
        raise ValueError('missing or repeated seeds')
write_json(target / 'progress.json', archived_progress)
original = read_json(ROOT / 'tools/sim/evidence/quilboar-h1/summary.json.gz')
result = combine(original, summarize(lobbies))
result['rerun_progress'] = archived_progress
output = ROOT / 'docs/ideation/reference/quilboar/h1'
json_path, _ = write_report(result, output)
write_json(target / 'summary.json.gz', result)
json_path.unlink()
write_json(target / 'verification.json', {
    'completed': progress['completed'], 'lobbies': len(lobbies),
    'plan_sha256': progress['plan_sha256'],
    'godot_scope_seconds': sum(chunk['scope_seconds'] for chunk in progress['chunks']),
    'simulation_lock': '/tmp/bramble-harness-godot.lock',
    'godot_targeted_tests': 64, 'python_driver_report_tests': 22,
    'capture_hashes_verified': True, 'compact_hashes_verified': True,
    'seeds_verified': True,
    'first_chunk_wall_time': 'unavailable after recovered bookkeeping error; scope time recorded',
    'retained_pre_fix_arms': {'C': 150, 'uncut_frozen': 100},
    'superseded_original_arms': {'B': 150, 'uncut': 100},
})
print(json.dumps(result['criteria'], indent=2))
