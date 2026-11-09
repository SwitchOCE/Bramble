"""Critic lens: empty slots at pre-start with vs without Queen of Elfland on board; value of refilling with s0=3."""
import glob, gzip, json, statistics, collections, math
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB))}
A = collections.defaultdict(lambda: collections.defaultdict(list))
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f)):
        line = labels.get((r["seed"], r["seat"]), r["line"]) or "?"
        if "fairies" not in line or r["round"] not in (12, 14): continue
        board = [u for u in r["units"] if u["location"] == "board"]
        q = any(u["def_id"] == "queen_of_elfland" for u in board)
        occ = {u["slot"] for u in board}
        ring = {i: m.get("count", 0) for i, s in enumerate(r.get("slots") or []) for m in s if m.get("name") == "Ring"}
        size = r["ring_size"] + 2
        bodies = sorted(u["attack"] + u["health"] - 2 * math.ceil(ring.get(u["slot"], 0) * r["ring_size"]) for u in board)
        body = statistics.median(bodies) if bodies else 0
        s3 = sum(u["attack"] + u["health"] + 2 * (math.ceil(ring.get(u["slot"], 0) * size) - math.ceil(ring.get(u["slot"], 0) * r["ring_size"])) for u in board)
        fill = s3 + sum(body + 2 * math.ceil(ring.get(i, 0) * size) for i in range(7) if i not in occ)
        k = (line, r["round"], "queen" if q else "no queen")
        A[k]["empty"].append(7 - len(occ)); A[k]["stats"].append(r["stats"]); A[k]["s3"].append(s3); A[k]["s3fill"].append(fill)
        A[k]["benchedunits"].append(sum(1 for u in r["units"] if u["location"] != "board"))
for k in sorted(A):
    a = A[k]
    print(k, "n", len(a["empty"]), "empty", round(statistics.mean(a["empty"]), 2), "p50", statistics.median(a["stats"]),
          "s0=3", statistics.median(a["s3"]), "s0=3+refill", statistics.median(a["s3fill"]), "units in hand", round(statistics.mean(a["benchedunits"]), 2))
