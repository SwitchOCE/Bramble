import gzip
import json
import math
import os
import statistics as st

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(gzip.open(os.path.join(HERE, "compact.json.gz"), "rt"))
BOARDS = D["boards"]
LINES = ["line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court"]
PAPER12 = {"line_birds_homecoming": 615, "line_birds_tempo": 361, "line_fairies_ring": 530, "line_fairies_court": 945}

# index: (seed, seat) -> {round: board}
BY_SEAT = {}
for b in BOARDS:
    BY_SEAT.setdefault((b["seed"], b["seat"]), {})[b["round"]] = b


def on_board(b, ids):
    """def_ids present on the board (location board) at this pre-start snapshot."""
    s = set()
    for u in b["units"]:
        if u[6] == "board":
            s.add(u[0])
    return s & set(ids) if ids else s


def owned(b):
    """def_ids owned anywhere: board, hand, away (sky), belly."""
    return {u[0] for u in b["units"] if u[6] in ("board", "hand", "away", "belly")}


def med(xs):
    return st.median(xs) if xs else float("nan")


def q(xs, p):
    if not xs:
        return float("nan")
    xs = sorted(xs)
    k = (len(xs) - 1) * p
    lo = math.floor(k)
    hi = math.ceil(k)
    return xs[lo] + (xs[hi] - xs[lo]) * (k - lo)


def committed(line, rnd):
    """Committed seat boards of this STARTING line at this round."""
    return [b for b in BOARDS if b["start"] == line and b["round"] == rnd]


def seen(seat_rounds, ids, r0, r1, where=("board",)):
    """Was any of ids on the board in any pre-start snapshot r0..r1?"""
    for r in range(r0, r1 + 1):
        b = seat_rounds.get(r)
        if not b:
            continue
        for u in b["units"]:
            if u[0] in ids and u[6] in where:
                return True
    return False
