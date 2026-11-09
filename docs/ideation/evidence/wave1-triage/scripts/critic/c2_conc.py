"""Critic lens: concentration (largest unit share, top-3 share) by line, and re-priced Fairy boards with initial size 3."""
import glob, gzip, json, statistics, collections, math
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB))}
A = collections.defaultdict(lambda: collections.defaultdict(list))
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f)):
        line = labels.get((r["seed"], r["seat"]), r["line"]) or "?"
        key = line if line.startswith("line_") else "field"
        rd = r["round"]
        if rd not in (8, 12, 14): continue
        board = [u for u in r["units"] if u["location"] == "board"]
        ring = {}
        for i, s in enumerate(r.get("slots") or []):
            for m in s:
                if m.get("name") == "Ring": ring[i] = m.get("count", 0)
        size = r["ring_size"]
        def price(newsize):
            vals = []
            for u in board:
                c = ring.get(u["slot"], 0)
                old = math.ceil(c * size); new = math.ceil(c * newsize)
                vals.append(u["attack"] + u["health"] + 2 * (new - old))
            return vals
        for tag, vals in (("now", [u["attack"] + u["health"] for u in board]),
                          ("size+2", price(size + 2)), ("size*3", price(size * 3))):
            if tag != "now" and "fairies" not in key: continue
            tot = sum(vals) or 1
            s = sorted(vals, reverse=True)
            A[(key, rd, tag)]["tot"].append(tot)
            A[(key, rd, tag)]["top1"].append(s[0] / tot if s else 0)
            A[(key, rd, tag)]["top3"].append(sum(s[:3]) / tot if s else 0)
            A[(key, rd, tag)]["big"].append(s[0] if s else 0)
med = statistics.median
for k in sorted(A):
    a = A[k]
    print(k, "n", len(a["tot"]), "p50", med(a["tot"]), "p90", sorted(a["tot"])[int(.9*len(a["tot"]))],
          "top1", round(med(a["top1"]), 2), "top3", round(med(a["top3"]), 2), "biggest", med(a["big"]))
