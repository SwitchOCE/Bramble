"""Critic lens: Cluricaun on End of Turn (condition kept) vs report's tier-up +1. Re-prices captured boards; no fights."""
import glob, gzip, json, statistics, collections, math
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
LAB = "/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-seat-labels.json.gz"
labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LAB))}
seats = collections.defaultdict(dict)
for f in sorted(glob.glob(RUN + "/chunk-*.boards.json.gz")):
    for r in json.load(gzip.open(f)):
        line = labels.get((r["seed"], r["seat"]), r["line"]) or "?"
        if "fairies" not in line: continue
        seats[(line, r["seed"], r["seat"])][r["round"]] = r
rounds = sorted({rd for s in seats.values() for rd in s})
print("rounds captured", rounds)
def price(r, newsize):
    board = [u for u in r["units"] if u["location"] == "board"]
    ring = {i: m.get("count", 0) for i, s in enumerate(r.get("slots") or []) for m in s if m.get("name") == "Ring"}
    size = r["ring_size"]
    return sum(u["attack"] + u["health"] + 2 * (math.ceil(ring.get(u["slot"], 0) * newsize) - math.ceil(ring.get(u["slot"], 0) * size)) for u in board)
def allring(r):
    ring = {i for i, s in enumerate(r.get("slots") or []) for m in s if m.get("name") == "Ring" and m.get("count", 0) > 0}
    return len(ring) == 7
def has(r, d): return any(u["def_id"] == d and u["location"] == "board" for u in r["units"])
out = collections.defaultdict(lambda: collections.defaultdict(list))
for (line, seed, seat), byr in seats.items():
    fires = 0
    for rd in rounds:
        r = byr.get(rd)
        if r is None: break
        # board captured at pre-start after this round's End of Turn: fire if Cluricaun present and all ringed
        if has(r, "cluricaun") and allring(r): fires += 1
        if rd in (8, 10, 12, 14):
            o = out[(line, rd)]
            o["now"].append(r["stats"])
            o["eot"].append(price(r, r["ring_size"] + fires))
            o["fires"].append(fires)
            o["s3"].append(price(r, r["ring_size"] + 2))
            o["s3eot"].append(price(r, r["ring_size"] + 2 + fires))
med = statistics.median
for k in sorted(out):
    o = out[k]
    print(k, "n", len(o["now"]), "now", med(o["now"]), "clur EoT", med(o["eot"]), "s0=3", med(o["s3"]), "s0=3+clurEoT", med(o["s3eot"]),
          "mean fires", round(statistics.mean(o["fires"]), 2), "share fired", round(sum(1 for x in o["fires"] if x) / len(o["fires"]), 2))
for line in ("line_fairies_ring", "line_fairies_court"):
    for tag in ("now", "eot", "s3", "s3eot"):
        a, b = med(out[(line, 8)][tag]), med(out[(line, 14)][tag])
        print(line, tag, "growth R8-R14", round((b / a) ** (1 / 6), 3))
