#!/usr/bin/env python3
"""Recover the completed first chunk after the relative-output-path recording error.

No simulation is repeated. Resume the frozen run with an absolute --folder path.
"""
import gzip
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools/sim'))
from quilboar_h1 import atomic_json, file_sha, read_json

folder = ROOT / 'build/quilboar-h1-cycle-fix/run'
path = folder / 'progress.json'
progress = read_json(path)
if progress['completed'] != {'B': 0, 'uncut': 0} or progress['chunks']:
    raise ValueError('recovery only applies to the unrecorded first chunk')
if "is not in the subpath" not in progress.get('error', ''):
    raise ValueError('unexpected failure')
prefix = folder / 'B-2921001'
compact = prefix.with_suffix('.lobbies.json.gz')
lobbies = read_json(compact)
if len(lobbies) != 5 or {lobby['seed'] for lobby in lobbies} != set(range(2921001, 2921006)):
    raise ValueError('unexpected completed seeds')
archive = prefix.with_suffix('.fights.jsonl.gz')
digest = hashlib.sha256()
with gzip.open(archive, 'rb') as source:
    while block := source.read(1024 * 1024):
        digest.update(block)
log = prefix.with_suffix('.log')
elapsed = float(re.search(r'h1_scope_seconds=([0-9.]+)', log.read_text())[1])
progress['chunks'].append({
    'arm': 'B', 'first_seed': 2921001, 'lobbies': 5,
    'scope_seconds': elapsed, 'wall_seconds_including_lock_wait': None,
    'recovery_note': 'Completed outputs recovered after relative-path bookkeeping failure; lock-wait wall time unavailable. No lobby rerun.',
    'compact': str(compact.relative_to(ROOT)), 'compact_sha256': file_sha(compact),
    'capture': str(archive.relative_to(ROOT)), 'capture_sha256': digest.hexdigest(),
    'capture_gzip_sha256': file_sha(archive),
    'players': str(prefix.with_suffix('.players.csv').relative_to(ROOT)),
    'log': str(log.relative_to(ROOT)),
})
progress['completed']['B'] = 5
progress['recovered_error'] = progress.pop('error')
progress['state'] = 'running'
atomic_json(path, progress)
print(json.dumps(progress['completed']))
