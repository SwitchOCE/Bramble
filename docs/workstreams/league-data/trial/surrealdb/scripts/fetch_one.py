"""Fetch one game's record back from the archive store, write it out, time it (median of 3)."""
import sys, time, statistics, hashlib, zstandard
from surrealdb import Surreal
port, mode, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
ms = []
with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
    db.signin({"username": "root", "password": "root"}); db.use("bramble", "league")
    for _ in range(3):
        t0 = time.perf_counter()
        b = db.query("SELECT VALUE body FROM ONLY type::record('replay', $n)", {"n": n}).execute()[0]
        out = b.encode() if mode == 'raw' else zstandard.ZstdDecompressor().decompress(b)
        ms.append((time.perf_counter() - t0) * 1000)
open(f'/data/dbtest/surrealdb/results/game-{n:05d}.{mode}.jsonl', 'wb').write(out)
src = open(f'/data/dbtest/sample/records/game-{n:05d}.jsonl', 'rb').read()
print(mode, f'game {n}: {len(out)} bytes, identical={out == src}, sha256={hashlib.sha256(out).hexdigest()[:16]}, median_ms={statistics.median(ms):.1f}, runs={[round(x,1) for x in ms]}')
