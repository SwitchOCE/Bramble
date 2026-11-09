"""Extract committed-seat state per round from the wave 1 accounting captures (python3 only, no Godot).

Writes seats.json: {line: {"seed:seat": {round: {...}}}} for the four committed lines, grouped by
STARTING line (tempo seats switch to homecoming at R7), plus rounds.csv economy for R1-R14.
"""
import csv, glob, gzip, json, os, sys, collections

RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "seats.json")
LINES = ("line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court")

labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB, "rt"))}
data = {l: {} for l in LINES}
lobby_tribes = collections.Counter()
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f, "rt")):
        line = labels.get((r["seed"], r["seat"]))
        if line not in LINES:
            continue
        key = "%d:%d" % (r["seed"], r["seat"])
        units = []
        for u in r["units"]:
            units.append(dict(id=u["def_id"], loc=u["location"], g=bool(u["golden"]), a=u["attack"], h=u["health"],
                              t=u["tier"], tr=(u.get("tribes") or ["-"])[0], act=u.get("active", True), slot=u.get("slot")))
        rings = None
        if r.get("slots") is not None:
            rings = []
            for s in r["slots"]:
                rings.append(sum(int(e.get("count", 0)) for e in (s or []) if e.get("name") == "Ring"))
        data[line].setdefault(key, {})[r["round"]] = dict(
            stats=r["stats"], tier=r["tier"], spent=r["gold_spent"], S=r.get("ring_size"), rings=rings,
            hc=r.get("homecomings"), pol=r["actual_policy"], units=units)

# economy for every round from rounds.csv
econ = {l: {} for l in LINES}
for f in sorted(glob.glob(RUN + "/chunk-*.rounds.csv")):
    for row in csv.DictReader(open(f)):
        line = labels.get((int(row["seed"]), int(row["seat"])))
        if line not in LINES:
            continue
        key = "%s:%s" % (row["seed"], row["seat"])
        econ[line].setdefault(key, {})[int(row["round"])] = dict(
            tier=int(row["tier"]), units=int(row["units"]), bank=int(row["bank"]), spent=int(row["spent"]),
            refresh=int(row["paid_refreshes"]), result=row["result"], left=int(row["gold_left"]),
            atk=int(row["attack"]), hp=int(row["health"]))
json.dump(dict(boards=data, econ=econ), open(OUT, "w"))
print({l: len(v) for l, v in data.items()}, {l: len(v) for l, v in econ.items()})
