"""Run each question block in queries.surql 3 times through the Python SDK; record median wall ms and save the results."""
import sys, re, json, time, statistics
from surrealdb import Surreal
port = sys.argv[1] if len(sys.argv) > 1 else '18603'
text = open('/data/dbtest/surrealdb/queries.surql').read()
blocks = re.split(r'^-- @(Q\d) .*$', text, flags=re.M)[1:]
blocks = dict(zip(blocks[0::2], blocks[1::2]))
timing = {}; results = {}
with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
    db.signin({"username": "root", "password": "root"}); db.use("bramble", "league")
    for q, sql in blocks.items():
        ms = []
        for _ in range(3):
            t0 = time.perf_counter(); res = db.query(sql).execute(); ms.append((time.perf_counter() - t0) * 1000)
        timing[q] = {'runs_ms': [round(x, 1) for x in ms], 'median_ms': round(statistics.median(ms), 1)}
        results[q] = [r for r in res if r is not None]
        print(q, timing[q], flush=True)
def default(o): return str(o)
json.dump(results, open('/data/dbtest/surrealdb/results/query_results.json', 'w'), default=default)
json.dump(timing, open('/data/dbtest/surrealdb/results/query_timing.json', 'w'), indent=1)
