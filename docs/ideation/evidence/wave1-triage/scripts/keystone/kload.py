"""Load wave-1 accounting captures into keystone/compact.json.gz. Run: python3 -I kload.py

Reads build/sim/wave1-accounting/run/chunk-*.boards.json.gz, players.csv, rounds.csv, cards.csv and
the seat labels; keeps only the fields the keystone analysis needs. Tempo seats are grouped by
STARTING line (field "start").
"""
import csv
import glob
import gzip
import json
import os

RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LABELS = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "compact.json.gz")

labels = {}
for row in json.load(gzip.open(LABELS, "rt")):
    labels[(row["seed"], row["seat"])] = (row["starting_line"], row["final_line"])

boards = []
for path in sorted(glob.glob(os.path.join(RUN, "chunk-*.boards.json.gz"))):
    for r in json.load(gzip.open(path, "rt")):
        units = []
        for u in r["units"]:
            units.append([
                u["def_id"], u["tier"], u["attack"], u["health"], int(bool(u["golden"])),
                u.get("slot"), u["location"], int(bool(u.get("active", True))),
                u.get("tribes", []),
            ])
        rings = []
        for s in r.get("slots") or []:
            rings.append(sum(e.get("count", 0) for e in s if e.get("name") == "Ring"))
        boards.append({
            "seed": r["seed"], "seat": r["seat"], "round": r["round"], "line": r["line"],
            "policy": r["actual_policy"], "stats": r["stats"], "post": r["post_start_stats"],
            "tier": r["tier"], "gold": r["gold_spent"], "ring_size": r.get("ring_size"),
            "rings": rings, "home": r.get("homecomings"), "share": r.get("largest_share"),
            "units": units,
            "start": labels.get((r["seed"], r["seat"]), (None, None))[0],
        })

players = []
for path in sorted(glob.glob(os.path.join(RUN, "chunk-*.players.csv"))):
    with open(path) as f:
        for row in csv.DictReader(f):
            row["start"] = labels.get((int(row["seed"]), int(row["seat"])), (None, None))[0]
            players.append(row)

rounds = []
for path in sorted(glob.glob(os.path.join(RUN, "chunk-*.rounds.csv"))):
    with open(path) as f:
        for row in csv.DictReader(f):
            rounds.append({k: row[k] for k in ("seed", "seat", "strategy", "round", "tier", "units", "attack", "health", "spent", "result", "gold_left", "bank")})

cards = []
for path in sorted(glob.glob(os.path.join(RUN, "chunk-*.cards.csv"))):
    with open(path) as f:
        for row in csv.DictReader(f):
            cards.append(row)

with gzip.open(OUT, "wt") as f:
    json.dump({"boards": boards, "players": players, "rounds": rounds, "cards": cards}, f)
print(len(boards), len(players), len(rounds), len(cards), OUT)
