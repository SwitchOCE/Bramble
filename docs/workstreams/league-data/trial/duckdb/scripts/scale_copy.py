"""Make scale10.duckdb: every table of bramble.duckdb repeated K times with game offset by 200*k."""
import duckdb, os, sys, time
K = int(sys.argv[1]) if len(sys.argv) > 1 else 10
P = '/data/dbtest/duckdb/'; out = P + f'scale{K}.duckdb'
if os.path.exists(out): os.remove(out)
c = duckdb.connect(config={'threads': 2, 'preserve_insertion_order': False})
c.execute(f"ATTACH '{P}bramble.duckdb' AS b (READ_ONLY)"); c.execute(f"ATTACH '{out}' AS s (STORAGE_VERSION 'latest')")
t = time.time()
for (tbl,) in c.sql("SELECT table_name FROM duckdb_tables() WHERE database_name='b'").fetchall():
    cols = [r[0] for r in c.sql(f"SELECT column_name FROM duckdb_columns() WHERE database_name='b' AND table_name='{tbl}' ORDER BY column_index").fetchall()]
    if 'game' not in cols:
        c.execute(f"CREATE TABLE s.{tbl} AS SELECT * FROM b.{tbl}"); continue
    sel = ', '.join('(game + 200*k)::INT AS game' if x == 'game' else ('view_id + 200000*k AS view_id' if x == 'view_id' else f'"{x}"') for x in cols)
    if tbl == 'record_lines':
        c.execute(f"CREATE TABLE s.record_lines (game INT, ln BIGINT, line VARCHAR USING COMPRESSION zstd, op VARCHAR, turn INT)")
        c.execute(f"INSERT INTO s.record_lines SELECT {sel} FROM b.record_lines, range({K}) r(k)")
    else:
        c.execute(f"CREATE TABLE s.{tbl} AS SELECT {sel} FROM b.{tbl}, range({K}) r(k)")
c.execute('CHECKPOINT s'); c.close()
print(f'{out}: {os.path.getsize(out)/1e6:.1f} MB in {time.time()-t:.0f}s')
