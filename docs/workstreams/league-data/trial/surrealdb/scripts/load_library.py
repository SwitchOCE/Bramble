import json, sys
from surrealdb import Surreal
port = sys.argv[1]
lib = json.load(open('/data/dbtest/sample/library.json'))
with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
    db.signin({"username": "root", "password": "root"}); db.use("bramble", "league")
    db.query("DEFINE TABLE IF NOT EXISTS card SCHEMALESS COMMENT 'card library: id = card id, tribes, tier, base stats';"
             "FOR $c IN $lib { UPSERT type::record('card', $c.id) CONTENT $c };", {"lib": lib}).execute()
    print(db.query("SELECT count() FROM card GROUP ALL").execute())
