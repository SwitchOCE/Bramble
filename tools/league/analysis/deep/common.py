"""Shared pieces for the deep analyses: one pass over each log into a compact
in-memory match, plus order-free seed-pair statistics with a `thin` flag.

Everything here builds on `match_data.py` (the section 9 loader); nothing in it
is changed.
"""
from collections import defaultdict
import json
import math
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from match_data import BANDS, NONE, TEAMS, Match, band  # noqa: E402,F401

SCOPES = ("red", "blue", "both")
# A number is flagged `thin` when it rests on fewer than this many observations
# or seed pairs. Thin numbers are kept (so charts can grey them out) but never
# headlined.
THIN_COUNT = 30
THIN_PAIRS = 10
Z = 1.96


def thin(count, pairs):
    return count < THIN_COUNT or pairs < THIN_PAIRS


class Acc:
    """Ratio of sums v = sum(x)/sum(n) with a 95% interval clustered on seed
    pairs. Same formula as match_data.Stat, but observations may arrive in any
    order (each pair keeps its own running totals)."""
    __slots__ = ("cells",)

    def __init__(self):
        self.cells = {}

    def add(self, pair, x, n=1):
        cell = self.cells.get(pair)
        if cell is None:
            self.cells[pair] = [x, n]
        else:
            cell[0] += x
            cell[1] += n

    def result(self, rate=False):
        x = sum(c[0] for c in self.cells.values())
        n = sum(c[1] for c in self.cells.values())
        k = sum(1 for c in self.cells.values() if c[1])
        v = x / n if n else None
        ci = None
        if k > 1:
            residual = sum((cx - v * cn) ** 2 for cx, cn in self.cells.values())
            half = Z * math.sqrt(k / (k - 1) * residual) / n
            ci = [v - half, v + half]
            if rate:
                ci = [max(0.0, ci[0]), min(1.0, ci[1])]
                if x in (0, n):
                    nn = sum(c[1] ** 2 for c in self.cells.values())
                    edge = Z ** 2 / (n * n / nn + Z ** 2)
                    ci = [0.0, edge] if x == 0 else [1 - edge, 1.0]
        out = {("rate" if rate else "mean"): v, "count": n, "pairs": k, "ci95": ci,
               "thin": thin(n, k)}
        if rate:
            out["hits"] = x
        return out


class Combo:
    """A weighted sum of group ratios measured over the same seed pairs,
    sum_g w_g * x_g/n_g, with a clustered (linearised) 95% interval: each
    pair's influence is sum_g w_g (x_gp - v_g n_gp) / n_g. Because the groups
    share pairs, this is more honest than combining separate intervals."""
    __slots__ = ("cells", "weights")

    def __init__(self, weights):
        self.weights = tuple(weights)
        self.cells = {}

    def add(self, pair, group, x, n=1):
        cell = self.cells.setdefault(pair, [0] * (2 * len(self.weights)))
        cell[2 * group] += x
        cell[2 * group + 1] += n

    def estimate(self):
        G = len(self.weights)
        X = [sum(c[2 * g] for c in self.cells.values()) for g in range(G)]
        N = [sum(c[2 * g + 1] for c in self.cells.values()) for g in range(G)]
        out = {"value": None, "groups": [None] * G, "counts": N, "pairs": len(self.cells), "ci95": None}
        if not all(N):
            out["thin"] = True
            return out
        v = [x / n for x, n in zip(X, N)]
        est = sum(w * vg for w, vg in zip(self.weights, v))
        out.update(value=est, groups=v)
        k = len(self.cells)
        if k > 1:
            infl = [sum(w * (c[2 * g] - v[g] * c[2 * g + 1]) / N[g] for g, w in enumerate(self.weights))
                    for c in self.cells.values()]
            half = Z * math.sqrt(k / (k - 1) * sum(i * i for i in infl))
            out["ci95"] = [est - half, est + half]
        out["thin"] = thin(min(N), k)
        return out


class Contrast(Combo):
    """Difference of two ratios over the same seed pairs: x1/n1 - x2/n2."""
    __slots__ = ()

    def __init__(self):
        super().__init__((1, -1))

    def result(self):
        e = self.estimate()
        return {"diff": e["value"], "a": e["groups"][0], "b": e["groups"][1], "count_a": e["counts"][0],
                "count_b": e["counts"][1], "pairs": e["pairs"], "ci95": e["ci95"], "thin": e["thin"]}


class Table:
    """Named accumulators. `rows()` turns them into a flat list of dicts, which
    is the shape every deep JSON file uses for its tables."""

    def __init__(self):
        self.accs = defaultdict(Acc)
        self.kinds = {}

    def add(self, key, pair, x, n=1, rate=False):
        self.accs[key].add(pair, x, n)
        self.kinds[key] = rate

    def get(self, key):
        acc = self.accs.get(key)
        return acc.result(self.kinds[key]) if acc else None

    def rows(self, names):
        out = []
        for key in sorted(self.accs, key=sort_key):
            row = dict(zip(names, key[:-1]))
            row["metric"] = key[-1]
            row.update(self.accs[key].result(self.kinds[key]))
            out.append(row)
        return out


def sort_key(key):
    return tuple((0, k, "") if isinstance(k, (int, float)) else (1, 0, str(k)) for k in key)


def scopes_of(colour):
    return (colour, "both")


def round_bucket(r, cap=15):
    """Rounds are kept exact up to `cap`; later rounds share the `cap` bucket."""
    return min(r, cap)


# ---------------------------------------------------------------------------
# The compact match.

class Seat:
    __slots__ = ("game", "pair", "seat", "colour", "bot", "place", "tribe", "died",
                 "rounds", "commit", "last_round")


class Rnd:
    __slots__ = ("round", "tier", "tribe", "cards", "golden", "stats", "gold_start",
                 "gold_left", "gold_from_cards", "hand", "hand_units", "board_n", "hp")


class Side:
    """One live seat's view of one fight."""
    __slots__ = ("game", "pair", "round", "seat", "colour", "tribe", "cards", "stats",
                 "opp", "opp_tribe", "opp_stats", "score", "damage", "board_n", "opp_n")


class Turn:
    """What one seat did in one recruit turn, from the decision log."""
    __slots__ = ("buys", "spell_buys", "sells", "refreshes", "upgrades", "upgrade_paid",
                 "plays", "abilities", "freezes", "decisions", "buy_gold", "fallback")

    def __init__(self):
        self.buys = self.spell_buys = self.sells = self.refreshes = self.upgrades = 0
        self.plays = self.abilities = self.freezes = self.decisions = self.buy_gold = 0
        self.upgrade_paid = []
        self.fallback = False


class Deep:
    """Everything the analyses read, kept small enough for a 1,000-game match.

    seats[(game, seat)] -> Seat; sides: list of Side in game order;
    turns[(game, seat, round)] -> Turn (absent without a decision log);
    buys/sells per card; tenure rows from replay records (absent without them);
    shops: buy opportunities aggregated by the shop pass.
    """

    def __init__(self, match):
        self.match = match
        self.library = match.library
        self.tribes = match.tribes
        self.seats = {}
        self.games = []          # per game: dict(game, pair, rounds, winner, hp[(round, seat)])
        self.sides = []
        self.turns = {}
        self.card_moves = []     # (pair, colour, seat_key, round, card, kind) kind in buy/sell
        self.tenure = []         # dict rows, see cardplay.tenure_rows
        self.shop = None
        self.coverage = {}

    def unit(self, card):
        c = self.library.get(card, {})
        return not c.get("spell", False)

    def card_tribes(self, card):
        return self.library.get(card, {}).get("tribes", [])


def load(path, records=True, decisions=True, shops=True):
    match = Match(path)
    deep = Deep(match)
    read_games(deep)
    if decisions and any((match.path / n).exists() for n in ("decisions.jsonl.gz", "decisions.jsonl")):
        read_decisions(deep)
        deep.coverage["decisions"] = True
    else:
        deep.coverage["decisions"] = False
    if shops and any((match.path / n).exists() for n in ("shops.jsonl.gz", "shops.jsonl")):
        from cardplay import read_shops
        read_shops(deep)
        deep.coverage["shops"] = True
    else:
        deep.coverage["shops"] = False
    if records and (match.path / "records").is_dir():
        from cardplay import read_records
        read_records(deep)
        deep.coverage["records"] = True
    else:
        deep.coverage["records"] = False
    return deep


def read_games(deep):
    match = deep.match
    for g in match.games():
        gi, pair = g["game"], g["game"] // 2
        hp = {}
        for fr in g["fights"]:
            for p in fr["players"]:
                hp[fr["round"], p["seat"]] = (p["hp"] + p["armor"]) if p["alive"] else 0
        info = {"game": gi, "pair": pair, "rounds": g["rounds"], "hp": hp,
                "places": {s["seat"]: s["place"] for s in g["seats"]},
                "colours": {s["seat"]: s["colour"] for s in g["seats"]}}
        deep.games.append(info)
        for s in g["seats"]:
            seat = Seat()
            seat.game, seat.pair, seat.seat = gi, pair, s["seat"]
            seat.colour, seat.bot, seat.place = s["colour"], s["bot"], s["place"]
            seat.tribe = s["main_tribe"] or NONE
            seat.died = s.get("died_round")
            seat.commit = s.get("commit_round")
            seat.rounds = {}
            for r in s["rounds"]:
                rd = Rnd()
                rd.round, rd.tier = r["round"], r["tier"]
                rd.tribe = match.main(r)
                rd.cards = tuple(u["card"] for u in r["board"])
                rd.golden = sum(1 for u in r["board"] if u["golden"])
                rd.stats = r["board_attack"] + r["board_health"]
                rd.gold_start, rd.gold_left = r.get("gold_start"), r["gold_left"]
                rd.gold_from_cards = r.get("gold_from_cards", 0)
                rd.hand = len(r["hand"])
                rd.hand_units = sum(1 for c in r["hand"] if deep.unit(c))
                rd.board_n = len(r["board"])
                rd.hp = hp.get((r["round"], s["seat"]))
                seat.rounds[rd.round] = rd
            seat.last_round = max(seat.rounds) if seat.rounds else 0
            deep.seats[gi, s["seat"]] = seat
        for fr in g["fights"]:
            r = fr["round"]
            for f in fr["fights"]:
                for pid, opp in ((f["a"], f["b"]), (f["b"], f["a"])):
                    if pid < 0:
                        continue
                    seat = deep.seats[gi, pid]
                    snap = seat.rounds.get(r)
                    if snap is None:
                        continue
                    side = Side()
                    side.game, side.pair, side.round, side.seat = gi, pair, r, pid
                    side.colour, side.tribe = seat.colour, snap.tribe
                    side.cards, side.stats, side.board_n = snap.cards, snap.stats, snap.board_n
                    o = deep.seats[gi, opp].rounds.get(r) if opp >= 0 else None
                    side.opp = opp
                    side.opp_tribe = o.tribe if o else None
                    side.opp_stats = o.stats if o else None
                    side.opp_n = o.board_n if o else None
                    if f["winner"] is None:
                        side.score = 0.5
                    else:
                        side.score = 1.0 if f["winner"] == pid else 0.0
                    side.damage = f["damage"] if f["loser"] == pid else 0
                    deep.sides.append(side)


def read_decisions(deep):
    match = deep.match
    prev = None
    upgrade_gold = None
    for raw in match.lines("decisions"):
        d = json.loads(raw)
        key = (d["game"], d["seat"], d["round"])
        turn = deep.turns.get(key)
        if turn is None:
            turn = deep.turns[key] = Turn()
        # Price paid for a tier-up: gold before it minus gold at the next
        # decision of the same turn (the logs carry no upgrade price).
        if upgrade_gold is not None:
            if prev == key:
                deep.turns[prev].upgrade_paid.append((upgrade_gold[0], upgrade_gold[1] - d["gold"]))
            upgrade_gold = None
        prev = key
        turn.decisions += 1
        if d.get("by") == "fallback":
            turn.fallback = True
        if d["result"]:
            continue
        a = d["legal"][d["chosen"]]
        t = a["type"]
        seat = deep.seats[d["game"], d["seat"]]
        if t == "buy":
            if a.get("spell"):
                turn.spell_buys += 1
            else:
                turn.buys += 1
                deep.card_moves.append((seat.pair, seat.colour, (d["game"], d["seat"]), d["round"], a["card"], "buy"))
            turn.buy_gold += a.get("price", 0)
        elif t == "sell":
            turn.sells += 1
            deep.card_moves.append((seat.pair, seat.colour, (d["game"], d["seat"]), d["round"], a["card"], "sell"))
        elif t == "refresh":
            turn.refreshes += 1
        elif t == "upgrade":
            turn.upgrades += 1
            upgrade_gold = (d["tier"], d["gold"])
        elif t == "play":
            turn.plays += 1
        elif t == "ability":
            turn.abilities += 1
        elif t == "freeze":
            turn.freezes += 1


# ---------------------------------------------------------------------------
# Output helpers.

def fmt(stat, pct=None):
    """A stat as 'value [lo, hi] (n)' with a ⚠ when thin."""
    if not stat:
        return "—"
    if "diff" in stat:
        v, ci, n = stat["diff"], stat["ci95"], min(stat["count_a"], stat["count_b"])
        pct = True if pct is None else pct
    else:
        is_rate = "rate" in stat
        v = stat["rate"] if is_rate else stat["mean"]
        ci, n = stat["ci95"], stat["count"]
        pct = is_rate if pct is None else pct
    if v is None:
        return "— (0)"
    f = (lambda x: f"{100 * x:.1f}%") if pct else (lambda x: f"{x:.2f}")
    if "diff" in stat:
        f = (lambda x: f"{100 * x:+.1f} pts") if pct else (lambda x: f"{x:+.2f}")
    interval = f" [{f(ci[0])}, {f(ci[1])}]" if ci else " [no CI]"
    flag = " ⚠thin" if stat.get("thin") else ""
    count = f"{stat['hits']:g}/{n:g}" if "hits" in stat else f"n={n:g}"
    return f"{f(v)}{interval} ({count}){flag}"


def write_json(directory, name, data):
    from match_data import atomic_file
    directory.mkdir(parents=True, exist_ok=True)
    with atomic_file(directory / (name + ".json")) as f:
        json.dump(data, f, allow_nan=False, separators=(",", ":"))
        f.write("\n")


def write_text(directory, name, text):
    from match_data import atomic_file
    directory.mkdir(parents=True, exist_ok=True)
    with atomic_file(directory / name) as f:
        f.write(text.rstrip() + "\n")


def card_name(deep, card):
    return deep.library.get(card, {}).get("name", card)


def card_label(deep, card):
    c = deep.library.get(card, {})
    tribes = "/".join(t for t in c.get("tribes", []))
    tier = c.get("tier")
    return f"{c.get('name', card)} ({tribes[:1] if tribes else '?'}{tier if tier else ''})"
