"""Archive layer variants for the 200 replay records. usage: load_archive.py <db> <layout:lines|file> [storage_version] [force_compression]"""
import duckdb, os, sys, time
DB, LAYOUT = sys.argv[1], sys.argv[2]
STORAGE = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != '-' else None
FORCE = sys.argv[4] if len(sys.argv) > 4 else None
if os.path.exists(DB): os.remove(DB)
c = duckdb.connect(config={'threads': 2})
c.execute(f"ATTACH '{DB}' AS a" + (f" (STORAGE_VERSION '{STORAGE}')" if STORAGE else '')); c.execute('USE a')
if FORCE: c.execute(f"SET force_compression='{FORCE}'")
t = time.time()
SRC = "read_text('/data/dbtest/sample/records/game-*.jsonl')"
if LAYOUT == 'file':
    c.execute(f"CREATE TABLE records AS SELECT parse_filename(filename, true)[6:]::INT AS game, content AS data FROM {SRC} ORDER BY game")
else:
    # one row per line; the last element after the final newline is '' so string_agg restores the file exactly
    c.execute(f"""CREATE TABLE records AS
      SELECT game, ln, line, json_extract_string(NULLIF(line,''), '$.op') AS op, TRY_CAST(json_extract(NULLIF(line,''), '$.turn') AS INT) AS turn FROM (
        SELECT parse_filename(filename, true)[6:]::INT AS game, unnest(string_split(content, chr(10))) AS line,
               generate_subscripts(string_split(content, chr(10)), 1) AS ln FROM {SRC}) ORDER BY game, ln""")
c.execute('CHECKPOINT'); c.close()
print(f'{os.path.basename(DB)} layout={LAYOUT} storage={STORAGE} force={FORCE} load_s={time.time()-t:.1f} bytes={os.path.getsize(DB)}')
