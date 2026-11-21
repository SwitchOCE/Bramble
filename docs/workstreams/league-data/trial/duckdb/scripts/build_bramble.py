"""Combine analysis_latest.duckdb + both archive layouts into bramble.duckdb (STORAGE_VERSION latest)."""
import duckdb, os
P = '/data/dbtest/duckdb/'
if os.path.exists(P+'bramble.duckdb'): os.remove(P+'bramble.duckdb')
c = duckdb.connect(config={'threads': 2})
c.execute(f"ATTACH '{P}bramble.duckdb' AS b (STORAGE_VERSION 'latest')")
c.execute(f"ATTACH '{P}analysis_latest.duckdb' AS a (READ_ONLY)")
c.execute(f"ATTACH '{P}arch_file_latest.duckdb' AS f (READ_ONLY)")
c.execute(f"ATTACH '{P}arch_lines_latest_zstd.duckdb' AS l (READ_ONLY)")
c.execute("COPY FROM DATABASE a TO b")
c.execute("CREATE TABLE b.records AS SELECT * FROM f.records")
c.execute("CREATE TABLE b.record_lines (game INT, ln BIGINT, line VARCHAR USING COMPRESSION zstd, op VARCHAR, turn INT)")
c.execute("INSERT INTO b.record_lines SELECT game, ln, line, op, turn FROM l.records")
c.execute("CHECKPOINT b"); c.close()
print(os.path.getsize(P+'bramble.duckdb')/1e6, 'MB')
