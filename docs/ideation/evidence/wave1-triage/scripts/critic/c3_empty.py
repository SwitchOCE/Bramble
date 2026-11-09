"""Critic lens: value of filling empty slots on Fairy boards; share of boards with every slot Ringed; Sally's rings."""
import glob, gzip, json, statistics, collections, math
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB))}
A = collections.defaultdict(lambda: collections.defaultdict(list))
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f)):
        line = labels.get((r["seed"], r["seat"]), r["line"]) or "?"
        if not line.startswith("line_"): continue
        rd = r["round"]
        board = [u for u in r["units"] if u["location"] == "board"]
        occ = {u["slot"] for u in board}
        ring = {}
        for i, s in enumerate(r.get("slots") or []):
            for m in s:
                if m.get("name") == "Ring": ring[i] = m.get("count", 0)
        size = r["ring_size"]
        bodies = sorted(u["attack"] + u["health"] - 2 * math.ceil(ring.get(u["slot"], 0) * size) for u in board)
        body = statistics.median(bodies) if bodies else 0
        gain = sum(body + 2 * math.ceil(ring.get(i, 0) * size) for i in range(7) if i not in occ)
        a = A[(line, rd)]
        a["stats"].append(r["stats"]); a["filled"].append(r["stats"] + gain)
        a["empty"].append(7 - len(occ))
        a["allring"].append(1 if all(ring.get(i, 0) > 0 for i in range(7)) else 0)
        a["queen"].append(1 if any(u["def_id"] == "queen_of_elfland" for u in board) else 0)
med = statistics.median
for k in sorted(A):
    if k[1] not in (8, 10, 12, 14): continue
    a = A[k]
    print(k, "p50", med(a["stats"]), "filled p50", med(a["filled"]), f"x{med(a['filled'])/med(a['stats']):.2f}",
          "empty", round(statistics.mean(a["empty"]), 2), "all7ringed", round(statistics.mean(a["allring"]), 2),
          "queen", round(statistics.mean(a["queen"]), 2))
