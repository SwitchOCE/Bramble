"""Archive layer: store the 200 replay records in SQLite several ways and prove byte-for-byte round trips.

usage: load_archive.py raw|zstd19|zstd19dict
  raw        - body BLOB as-is (SQLite default; SQLite has no built-in compression)
  zstd19     - app-level: body = zstd level 19 frame (Python compression.zstd)
  zstd19dict - app-level: zstd level 19 with a dictionary trained on the records, dictionary stored in the DB
"""
import hashlib, os, sqlite3, sys, time
from compression import zstd

R = '/data/dbtest/sample/records'
mode = sys.argv[1]
out = f'/data/dbtest/sqlite/archive_{mode}.db'
if os.path.exists(out):
    os.remove(out)
files = sorted(os.listdir(R))
data = {f: open(f'{R}/{f}', 'rb').read() for f in files}

db = sqlite3.connect(out)
db.executescript('''
CREATE TABLE records(game INTEGER PRIMARY KEY, name TEXT, sha256 TEXT, raw_len INT, codec TEXT, body BLOB);
CREATE TABLE dicts(id INTEGER PRIMARY KEY, dict BLOB);
''')
zd = None
t0 = time.time()
if mode == 'zstd19dict':
    # train on 64 KB chunks of every record
    samples = [b[i:i + 65536] for b in data.values() for i in range(0, len(b), 65536)]
    zd = zstd.train_dict(samples, 112640)
    db.execute('INSERT INTO dicts VALUES(1, ?)', (zd.dict_content,))
    print('dict trained', round(time.time() - t0, 1), 's', len(zd.dict_content), 'bytes')
t1 = time.time()
for f in files:
    raw = data[f]
    if mode == 'raw':
        body, codec = raw, 'none'
    elif mode == 'zstd19':
        body, codec = zstd.compress(raw, level=19), 'zstd19'
    else:
        body, codec = zstd.compress(raw, level=19, zstd_dict=zd), 'zstd19+dict1'
    db.execute('INSERT INTO records VALUES(?,?,?,?,?,?)',
               (int(f[5:10]), f, hashlib.sha256(raw).hexdigest(), len(raw), codec, body))
db.commit(); db.execute('VACUUM'); db.close()
t2 = time.time()

# read back every record, decompress, compare checksums with the files on disk
db = sqlite3.connect(out)
dd = None
row = db.execute('SELECT dict FROM dicts WHERE id=1').fetchone()
if row:
    dd = zstd.ZstdDict(row[0])
ok = 0
t3 = time.time()
for game, name, sha, codec, body in db.execute('SELECT game, name, sha256, codec, body FROM records ORDER BY game'):
    raw = body if codec == 'none' else zstd.decompress(body, zstd_dict=dd) if dd else zstd.decompress(body)
    if hashlib.sha256(raw).hexdigest() == sha == hashlib.sha256(data[name]).hexdigest():
        ok += 1
t4 = time.time()
print(f'{mode}: file {os.path.getsize(out)} bytes; bodies {db.execute("select sum(length(body)) from records").fetchone()[0]}; '
      f'write {t2 - t1:.1f}s; read+decompress+sha all {t4 - t3:.2f}s; byte-identical {ok}/200')
