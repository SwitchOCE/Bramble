import sys, os, time, hashlib, zstandard
from surrealdb import Surreal
port, mode = sys.argv[1], sys.argv[2]   # mode: raw | zstd19
SRC = '/data/dbtest/sample/records'
cctx = zstandard.ZstdCompressor(level=19)
t0 = time.time()
with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
    db.signin({"username": "root", "password": "root"})
    db.use("bramble", "league")
    db.query("DEFINE TABLE IF NOT EXISTS replay SCHEMAFULL COMMENT 'one row per game: the replay record file, byte for byte';"
             "DEFINE FIELD IF NOT EXISTS game ON replay TYPE int;"
             "DEFINE FIELD IF NOT EXISTS sha256 ON replay TYPE string;"
             "DEFINE FIELD IF NOT EXISTS size ON replay TYPE int;"
             + ("DEFINE FIELD IF NOT EXISTS body ON replay TYPE string COMMENT 'the file text, unchanged';" if mode == 'raw' else
                "DEFINE FIELD IF NOT EXISTS body ON replay TYPE bytes COMMENT 'zstd -19 of the file';")).execute()
    for name in sorted(os.listdir(SRC)):
        n = int(name[5:10])
        raw = open(os.path.join(SRC, name), 'rb').read()
        body = raw.decode('utf-8') if mode == 'raw' else cctx.compress(raw)
        db.query("UPSERT type::record('replay', $n) CONTENT {game: $n, sha256: $h, size: $s, body: $b}",
                 {"n": n, "h": hashlib.sha256(raw).hexdigest(), "s": len(raw), "b": body}).execute()
    print("rows", db.query("RETURN count(SELECT id FROM replay)").execute())
print("load_s", round(time.time() - t0, 2))
