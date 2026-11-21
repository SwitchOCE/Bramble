"""Fetch one game's replay record back from an archive DB and write it out. usage: fetch_record.py DB GAME OUTFILE"""
import sqlite3, sys, time, hashlib
from compression import zstd
db = sqlite3.connect(f'file:{sys.argv[1]}?mode=ro', uri=True)
t = time.perf_counter()
codec, sha, body = db.execute('SELECT codec, sha256, body FROM records WHERE game=?', (int(sys.argv[2]),)).fetchone()
if codec == 'zstd19+dict1':
    body = zstd.decompress(body, zstd_dict=zstd.ZstdDict(db.execute('SELECT dict FROM dicts WHERE id=1').fetchone()[0]))
elif codec == 'zstd19':
    body = zstd.decompress(body)
dt = time.perf_counter() - t
open(sys.argv[3], 'wb').write(body)
print(f'{codec}: {len(body)} bytes in {dt*1000:.1f} ms, sha256 ok={hashlib.sha256(body).hexdigest()==sha}')
