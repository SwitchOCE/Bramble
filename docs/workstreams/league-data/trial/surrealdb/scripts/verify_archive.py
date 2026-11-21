import sys, os, time, hashlib, zstandard
from surrealdb import Surreal
port, mode = sys.argv[1], sys.argv[2]
SRC = '/data/dbtest/sample/records'
d = zstandard.ZstdDecompressor()
ok = bad = 0; t0 = time.time()
with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
    db.signin({"username": "root", "password": "root"}); db.use("bramble", "league")
    for name in sorted(os.listdir(SRC)):
        n = int(name[5:10])
        row = db.query("SELECT body FROM ONLY type::record('replay', $n)", {"n": n}).execute()[0]
        b = row['body']
        out = b.encode('utf-8') if mode == 'raw' else d.decompress(b)
        if hashlib.sha256(out).digest() == hashlib.sha256(open(os.path.join(SRC, name), 'rb').read()).digest(): ok += 1
        else: bad += 1
print(f"{mode}: {ok} match, {bad} differ, fetch+check all 200 in {time.time()-t0:.2f}s")
