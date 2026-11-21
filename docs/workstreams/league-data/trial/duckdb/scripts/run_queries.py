"""Run each queries/*.sql 3 times on bramble.duckdb (2 threads), report median ms, save results as CSV."""
import duckdb, glob, os, statistics, time, csv, sys
DB = sys.argv[1] if len(sys.argv) > 1 else '/data/dbtest/duckdb/bramble.duckdb'
OUT = sys.argv[2] if len(sys.argv) > 2 else '/data/dbtest/duckdb/results'
c = duckdb.connect(DB, read_only=True, config={'threads': 2})
for path in sorted(glob.glob('/data/dbtest/duckdb/queries/*.sql')):
    stmts = [s.strip() for s in open(path).read().split(';\n') if s.strip().strip(';').strip() and not all(l.startswith('--') for l in s.strip().splitlines())]
    times = []
    for _ in range(3):
        t = time.perf_counter(); outs = []
        for s in stmts:
            r = c.execute(s); outs.append(([d[0] for d in r.description], r.fetchall()))
        times.append((time.perf_counter() - t) * 1000)
    name = os.path.basename(path)[:-4]
    for i, (cols, rows) in enumerate(outs):
        with open(f'{OUT}/{name}{"_"+chr(97+i) if len(outs)>1 else ""}.csv', 'w', newline='') as f:
            w = csv.writer(f); w.writerow(cols); [w.writerow([str(x)[:300] for x in row]) for row in rows]
    print(f'{name}: median {statistics.median(times):.1f} ms (runs {", ".join(f"{t:.1f}" for t in times)}), rows {[len(o[1]) for o in outs]}', flush=True)
