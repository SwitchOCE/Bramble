"""Schema 1 match streams, seat joins and seed-pair statistics."""
import argparse
from collections import defaultdict
from contextlib import contextmanager
import gzip
from itertools import groupby
import json
import math
import os
from pathlib import Path
from tempfile import NamedTemporaryFile

TEAMS = ("red", "blue")
SCOPES = (*TEAMS, "both")
BANDS = ("1-3", "4-6", "7-9", "10-12", "13+")
NONE = "(none)"


def band(round_no):
    if round_no < 1:
        raise ValueError("invalid round")
    return BANDS[min((round_no - 1) // 3, 4)]


def turn(row):
    return row["game"], row["round"], row["seat"]


def chosen_action(row):
    return row["action"] if "action" in row else row["legal"][row["chosen"]]


def aligned(reports, shops):
    """Optional reports form an ordered subsequence. Only uniquely located rows can be joined."""
    def positions(rows, start, step):
        found = []
        i = start
        for row in rows:
            while 0 <= i < len(shops) and shops[i] != row["offered"]:
                i += step
            if not 0 <= i < len(shops):
                raise ValueError("shop report does not match logged offers")
            found.append(i)
            i += step
        return found
    first = positions(reports, 0, 1)
    last = positions(reversed(reports), len(shops)-1, -1)[::-1]
    return [a if a == b else None for a, b in zip(first, last)]


class Match:
    def __init__(self, directory):
        self.path = Path(directory)
        self.summary = self.read("summary")
        if self.summary["schema"] != 1 or self.summary["complete"] is not True:
            raise ValueError(f"{self.path}: expected completed schema 1 match")
        self.library = {c["id"]: c for c in self.read("library")}
        self.tribes = sorted({t for c in self.library.values() for t in c["tribes"]} - {"All"})
        self.units = [k for k, c in self.library.items() if not c["spell"]]
        self._seats = None

    def read(self, name):
        with self.open(f"{name}.json") as f:
            return json.load(f)

    def open(self, name):
        path = self.path / name
        compressed = path.with_name(path.name + ".gz")
        return gzip.open(compressed, "rb") if compressed.is_file() else path.open("rb")

    def has_log(self, name):
        return any((self.path / (name + suffix)).is_file() for suffix in (".jsonl.gz", ".jsonl"))

    def score(self):
        a = self.read("analysis")
        # On an odd run the harness weights the last singleton pair as one pair,
        # while the manifest weights every game equally.
        wrong_score = self.summary["games"] % 2 == 0 and any(
            not math.isclose(a["score"][k], self.summary[k], abs_tol=1e-9)
            for k in ("red_avg_place", "blue_avg_place", "gap_red_minus_blue")
        )
        if (wrong_score or a["games"] != self.summary["games"] or a["seed_pairs"] != (a["games"]+1)//2
                or any(a.get("bots", {}).get(c, self.summary[c]) != self.summary[c] for c in TEAMS)):
            raise ValueError(f"{self.path}: stale analysis.json; rerun league analyze")
        keys = ("red_avg_place", "blue_avg_place", "red_ci95", "blue_ci95",
                "gap_red_minus_blue", "gap_ci95", "winner")
        return {"games": a["games"], "seed_pairs": a["seed_pairs"],
                **{k: a["score"][k] for k in keys}}

    def lines(self, name):
        with self.open(f"{name}.jsonl") as stream:
            yield from stream

    def rows(self, name):
        for raw in self.lines(name):
            yield json.loads(raw)

    def games(self):
        count = 0
        previous_red = set()
        for g in self.rows("games"):
            if g["game"] != count:
                raise ValueError("games out of order or incomplete")
            seats = g["seats"]
            red = {s["seat"] for s in seats if s["colour"] == "red"}
            blue = {s["seat"] for s in seats if s["colour"] == "blue"}
            if self.summary.get("mode") == "async":
                expected = (set(), {0}) if count % 2 else ({0}, set())
                valid = len(seats) == 1 and (red, blue) == expected
            else:
                valid = (len(seats) == 8 and len(red) == 4 and len(blue) == 4
                         and red | blue == set(range(8)) and (not count % 2 or blue == previous_red))
            if not valid or red != set(g["red_seats"]) or g["swapped"] != bool(count % 2):
                raise ValueError(f"game {count}: inconsistent seat colours")
            previous_red = red
            count += 1
            yield g
        if count != self.summary["games"]:
            raise ValueError("game count differs from manifest")

    def seat(self, row):
        if self._seats is None:
            self._seats = {(g["game"], s["seat"]): (s["colour"], s["main_tribe"] or NONE, s["bot"])
                           for g in self.games() for s in g["seats"]}
        colour, tribe, bot = self._seats[row["game"], row["seat"]]
        if row["colour"] != colour or row["bot"] != bot or colour not in TEAMS:
            raise ValueError("log identity disagrees with games.jsonl")
        return colour, tribe

    def discovers(self):
        """Yield choices in game order with their original offers and selected card."""
        if self.summary.get("inline_reports") and self.has_log("decisions"):
            for row in self.rows("decisions"):
                action = chosen_action(row)
                if action["type"] == "pick":
                    yield dict(row, options=row["discover_options"], card=action["card"])
        elif self.has_log("discovers"):
            yield from self.rows("discovers")

    def report_shops(self, *, include_discover=False):
        """Yield scored shop reports and, when requested, Discover strategy labels."""
        if self.summary.get("inline_reports"):
            for shop in self.rows("shops"):
                if "values" in shop:
                    offered = [offer["card"] for offer in shop["offers"]]
                    yield dict(shop, kind="shop", offered=offered), shop
            if include_discover:
                if self.has_log("decisions"):
                    for row in self.rows("decisions"):
                        if "strategy" in row and "discover_options" in row:
                            yield dict(row, kind="discover"), None
                elif self.has_log("reports"):
                    for row in self.rows("reports"):
                        if row["kind"] == "discover":
                            yield row, None
        elif self.has_log("reports"):
            yield from self.legacy_reports(include_discover)

    def legacy_reports(self, include_discover):
        """Locate older standalone reports by their ordered offer lists."""
        groups = groupby(self.rows("shops"), turn)
        current = None
        for key, rows in groupby(self.rows("reports"), turn):
            reports = list(rows)
            shop_reports = [r for r in reports if r["kind"] == "shop"]
            matches = iter(())
            if shop_reports:
                while current is None or current[0] < key:
                    current = next(groups, None)
                    if current is None:
                        raise ValueError("missing shop for report")
                if current[0] != key:
                    raise ValueError("missing shop for report")
                shops = list(current[1])
                signatures = [[o["card"] for o in s["offers"]] for s in shops]
                matches = iter(aligned(shop_reports, signatures))
            for report in reports:
                if report["kind"] == "shop":
                    i = next(matches)
                    yield report, shops[i] if i is not None else None
                elif include_discover:
                    yield report, None

    def main(self, snapshot):
        counts = snapshot["tribes"]
        if not counts:
            return NONE
        most = max(counts.values())
        tied = [t for t, n in counts.items() if n == most]
        if len(tied) == 1:
            return tied[0]
        stats = dict.fromkeys(tied, 0)
        for u in snapshot["board"]:
            tribes = self.library[u["card"]]["tribes"]
            for t in tied:
                if t in tribes or "All" in tribes:
                    stats[t] += u["attack"] + u["health"]
        return min(tied, key=lambda t: (-stats[t], t))


class Stat:
    """Streaming ratio of sums, retaining second moments of seed-pair totals."""
    __slots__ = ("pair", "x", "n", "sx", "sn", "xx", "xn", "nn", "pairs")

    def __init__(self):
        self.pair = -1
        self.x = self.n = self.sx = self.sn = self.xx = self.xn = self.nn = self.pairs = 0

    def add(self, pair, x, n=1):
        if pair != self.pair:
            if pair < self.pair:
                raise ValueError("expected observations in seed-pair order")
            if self.n:
                self.pairs += 1
                self.sx += self.x
                self.sn += self.n
                self.xx += self.x ** 2
                self.xn += self.x * self.n
                self.nn += self.n ** 2
            self.pair, self.x, self.n = pair, 0, 0
        self.x += x
        self.n += n

    def result(self, rate=False):
        x, n = self.sx + self.x, self.sn + self.n
        k = self.pairs + bool(self.n)
        v = x / n if n else None
        ci = None
        if k > 1:
            residual = (self.xx + self.x**2 - 2*v*(self.xn + self.x*self.n)
                        + v*v*(self.nn + self.n**2))
            half = 1.96 * math.sqrt(k/(k-1) * max(0, residual)) / n
            ci = [v - half, v + half]
            if rate:
                ci = [max(0, ci[0]), min(1, ci[1])]
                if x in (0, n):
                    # Boundary Wilson interval with independent pair weights.
                    effective_pairs = n*n / (self.nn + self.n**2)
                    edge = 1.96**2 / (effective_pairs + 1.96**2)
                    ci = [0, edge] if x == 0 else [1-edge, 1]
        return {("rate" if rate else "mean"): v, "count": n, "pairs": k, "ci95": ci,
                **({"hits": x} if rate else {})}


def nest(table, key, value):
    for part in key[:-1]:
        table = table.setdefault(str(part), {})
    table[str(key[-1])] = value


class Measures:
    def __init__(self):
        self.stats = defaultdict(Stat)

    def add(self, key, pair, value, *, rate=False, n=1):
        self.stats[(key, rate)].add(pair, value, n)

    def result(self):
        out = {}
        for (key, rate), stat in self.stats.items():
            nest(out, key, stat.result(rate))
        return out


def sides(game):
    """Live seat fight perspectives. A ghost has no current recruit snapshot."""
    seats = {s["seat"]: s for s in game["seats"]}
    snaps = {(s["seat"], r["round"]): r for s in seats.values() for r in s["rounds"]}
    for fr in game["fights"]:
        r = fr["round"]
        for fight in fr["fights"]:
            for side, (pid, opp) in enumerate(((fight["a"], fight["b"]), (fight["b"], fight["a"]))):
                if pid in seats:
                    yield seats[pid], snaps[pid, r], snaps.get((opp, r)), fight, side


def parser(description):
    p = argparse.ArgumentParser(description=description)
    p.add_argument("match", type=Path)
    p.add_argument("--out-dir", type=Path, help="report directory (default: match directory)")
    return p


@contextmanager
def atomic_file(path):
    with NamedTemporaryFile(dir=path.parent, mode="w", encoding="utf-8", delete=False) as f:
        try:
            yield f
            f.close()
            os.replace(f.name, path)
        finally:
            Path(f.name).unlink(missing_ok=True)


def publish(directory, name, data, markdown):
    directory.mkdir(parents=True, exist_ok=True)
    with atomic_file(directory / (name + ".json")) as f:
        json.dump(data, f, allow_nan=False, separators=(",", ":"))
        f.write("\n")
    with atomic_file(directory / (name + ".md")) as f:
        f.write(markdown.rstrip() + "\n")
    print(markdown.rstrip())


def show(stat):
    if not stat or not stat["count"]:
        return "— (0)"
    is_rate = "rate" in stat
    def fmt(value):
        return f"{value:.1%}" if is_rate else f"{value:.2f}"
    value = fmt(stat["rate" if is_rate else "mean"])
    ci = stat["ci95"]
    interval = f"[{fmt(ci[0])}, {fmt(ci[1])}]" if ci else "[CI unavailable]"
    count = f"{stat['hits']}/{stat['count']}" if is_rate else str(stat["count"])
    return f"{value} {interval} ({count})"

