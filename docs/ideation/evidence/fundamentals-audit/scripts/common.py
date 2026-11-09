import csv, collections, statistics, math, json, os, glob

D = "/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/free_choice_plain"
BASE = [0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 7, 9, 11, 13]


def base(r):
    return BASE[min(r, len(BASE)) - 1]


def load():
    P = list(csv.DictReader(open(D + ".players.csv")))
    R = list(csv.DictReader(open(D + ".rounds.csv")))
    C = list(csv.DictReader(open(D + ".cards.csv")))
    seeds = {p["seed"] for p in P}
    R = [r for r in R if r["seed"] in seeds]
    for p in P:
        for k in ("seed", "seat", "place", "rounds", "final_units", "final_attack", "final_health", "tier6_turn"):
            p[k] = int(p[k])
    for r in R:
        for k in ("seed", "seat", "round", "tier", "units", "attack", "health", "bank", "spent", "gold_left"):
            r[k] = int(r[k])
        r["stats"] = r["attack"] + r["health"]
    place = {(p["seed"], p["seat"]): p["place"] for p in P}
    for r in R:
        r["place"] = place[(r["seed"], r["seat"])]
    byp = collections.defaultdict(list)
    for r in R:
        byp[(r["seed"], r["seat"])].append(r)
    for v in byp.values():
        v.sort(key=lambda x: x["round"])
    return P, R, C, byp


def med(xs):
    return statistics.median(xs) if xs else float("nan")


def q(xs, f):
    if not xs:
        return float("nan")
    s = sorted(xs)
    i = f * (len(s) - 1)
    lo = int(math.floor(i))
    hi = min(lo + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (i - lo)


def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")


def table(head, rows, fmt=None):
    out = ["| " + " | ".join(head) + " |", "|" + "|".join("---:" for _ in head) + "|"]
    for row in rows:
        cells = []
        for c in row:
            if isinstance(c, float):
                cells.append("nan" if math.isnan(c) else ("%.2f" % c if abs(c) < 10 else "%.1f" % c))
            else:
                cells.append(str(c))
        out.append("| " + " | ".join(cells) + " |")
    return "\n".join(out)
