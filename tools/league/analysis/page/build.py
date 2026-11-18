#!/usr/bin/env python3
"""Build the league results page for one match: one self-contained HTML file, data inlined.

usage: build.py MATCH [--naive NAIVE_MATCH] [--earlier MATCH ...] --out FILE.html
                [--cache DIR] [--status official|practice|test]

Reads what the analysis commands already wrote: MATCH/analysis.json, summary.json, games.jsonl,
events.json, library.json, MATCH/deep/*.json (deep/run.py) and the section 9 reports cards.json,
tribes.json, behaviours.json, agree.json (beside the match or in the cache). Any report that is
missing is run here, with its output in the cache folder (default: the checkout's .copies/league-page),
so the match folder is not touched. Python 3 standard library only. The charts are drawn in the page.
"""
import argparse
import base64
import datetime
import json
import math
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ANALYSIS = HERE.parent
REPO = ANALYSIS.parents[2]
sys.path.insert(0, str(ANALYSIS))
from winscore import score as winscore  # noqa: E402

TRIBES = ["Badger", "Briar", "Locust", "Mouse", "Pigeon"]
BANDS = ["1-3", "4-6", "7-9", "10-12", "13+"]
SCOPES = ["red", "blue", "both"]
THIN_COUNT, THIN_PAIRS = 30, 10
ART_DIRS = ["badger", "locust", "mouse", "pigeon", "thorn"]
MIN_LIFT_FIGHTS = 100   # a card's per-team fight lift is ranked only with this many fights behind it


def LIFT(table, cid, c):
    return next(r for r in table if r["id"] == cid)["s"][c]["lift"][0]


def pts(x):
    return f"{'+' if x >= 0 else '−'}{abs(100 * x):.0f} pts"


# ---------------------------------------------------------------- loading

def run(cmd):
    print("  running:", " ".join(str(c) for c in cmd), file=sys.stderr)
    subprocess.run([sys.executable, *map(str, cmd)], cwd=ANALYSIS, check=True,
                   stdout=subprocess.DEVNULL)


def fresh(path, *scripts):
    """A report counts only if it exists and is newer than every script (under the analysis folder) that makes it,
    so a page never shows numbers an older version of the analysis wrote."""
    if not path.exists():
        return False
    newest = max(((ANALYSIS / s).stat().st_mtime for s in (*scripts, "match_data.py") if (ANALYSIS / s).exists()), default=0)
    return path.stat().st_mtime >= newest


class M:
    """One match folder, with each report found beside it or made in the cache."""

    def __init__(self, path, cache):
        self.path = Path(path).resolve()
        self.name = self.path.name
        self.cache = Path(cache) / self.name
        self.summary = self.json(self.path / "summary.json")
        self.analysis = self.json(self.path / "analysis.json")
        self.library = {c["id"]: c for c in self.json(self.path / "library.json")}
        self.deep = {}
        for f in ("meta", "tempo", "cards", "fights", "synergy"):
            self.deep[f] = self.find_deep(f)
        self.sec9 = {f: self.find_sec9(f) for f in ("cards", "tribes", "behaviours", "agree")}
        ev = self.path / "events.json"
        if not fresh(ev, "events.py"):
            run(["events.py", self.path])
        self.events = self.json(ev)
        with open(self.path / "games.jsonl") as f:
            self.games = [json.loads(line) for line in f if line.strip()]
        self.played = datetime.datetime.fromtimestamp((self.path / "games.jsonl").stat().st_mtime)

    @staticmethod
    def json(p):
        with open(p) as f:
            return json.load(f)

    def find_deep(self, name):
        for d in (self.path / "deep", self.cache / "deep"):
            if fresh(d / f"{name}.json", *sorted(p.relative_to(ANALYSIS) for p in (ANALYSIS / "deep").glob("*.py"))):
                return self.json(d / f"{name}.json")
        run(["deep/run.py", self.path, "--out-dir", self.cache / "deep"])
        return self.json(self.cache / "deep" / f"{name}.json")

    def find_sec9(self, name):
        for d in (self.path, self.cache):
            if fresh(d / f"{name}.json", f"{name}.py"):
                return self.json(d / f"{name}.json")
        run([f"{name}.py", self.path, "--out-dir", self.cache])
        return self.json(self.cache / f"{name}.json")


# ---------------------------------------------------------------- stat helpers

def val(st):
    if not st:
        return None
    for k in ("rate", "mean", "value", "diff"):
        if k in st and st[k] is not None:
            return st[k]
    return None


def is_thin(st):
    if not st:
        return True
    if "thin" in st:
        return bool(st["thin"])
    return (st.get("count") or 0) < THIN_COUNT or (st.get("pairs") or 0) < THIN_PAIRS


def S(st, nd=4):
    """Compact stat for the page: [value, lo, hi, count, pairs, thin, hits]."""
    v = val(st)
    if v is None or not st.get("count", 1):
        return None
    ci = st.get("ci95")
    lo, hi = (ci if ci else (None, None))
    r = lambda x: None if x is None else round(x, nd)
    hits = st.get("hits")
    return [r(v), r(lo), r(hi), st.get("count"), st.get("pairs"), 1 if is_thin(st) else 0,
            None if hits is None else round(hits, 1)]


def rows(table, **match):
    return [r for r in table if all(r.get(k) == v for k, v in match.items())]


def one(table, **match):
    r = rows(table, **match)
    return r[0] if r else None


def pct(x, nd=0):
    return "—" if x is None else f"{100 * x:.{nd}f}%"


def num(x, nd=2):
    return "—" if x is None else f"{x:.{nd}f}"


def ok(st):
    return st is not None and val(st) is not None and not is_thin(st)


# ---------------------------------------------------------------- names

def status_of(m, override):
    if override:
        return override
    if re.match(r"^m\d", m.name):
        return "official"
    if re.match(r"^s\d", m.name):
        return "practice"
    return "test"


def team_names(m):
    out = {}
    for c in ("red", "blue"):
        label = m.summary.get(f"{c}_label", c)
        out[c] = c.capitalize() if label.lower().startswith(c) else f"{c.capitalize()} ({label})"
    return out


def card_name(m, cid):
    c = m.library.get(cid)
    return c["name"] if c else cid


def card_tag(m, cid):
    c = m.library.get(cid)
    if not c:
        return cid
    t = (c.get("tribes") or ["?"])[0]
    return f"{c['name']} ({t[0]}{c.get('tier', '')})"


def team_share(nr, nb):
    """[red share of the sample, total] for a pooled number; the page flags it when one team holds 90%+."""
    nr, nb = nr or 0, nb or 0
    return [round(nr / (nr + nb), 4), nr + nb] if nr + nb else None


def lobby_wins(m):
    """Games won by one of each team's seats. Teammates share one first place, so this, not a seat's
    win rate or its share of top fours converted, is how often a team wins a lobby. Clustered over seed pairs."""
    pairs = {}
    for g in m.games:
        win = next((s["colour"] for s in g["seats"] if s["place"] == 1), None)
        p = pairs.setdefault(g["game"] // 2, {"red": 0, "blue": 0, "n": 0})
        p["n"] += 1
        if win in ("red", "blue"):
            p[win] += 1
    out = {}
    k = len(pairs)
    n = sum(p["n"] for p in pairs.values())
    for c in ("red", "blue"):
        x = sum(p[c] for p in pairs.values())
        v = x / n if n else None
        ci = None
        if k >= 2 and n:
            h = 1.96 * math.sqrt(k / (k - 1) * sum((p[c] - v * p["n"]) ** 2 for p in pairs.values())) / n
            ci = [max(0.0, v - h), min(1.0, v + h)]
        out[c] = {"rate": v, "count": n, "pairs": k, "ci95": ci, "hits": x, "thin": n < THIN_COUNT or k < THIN_PAIRS}
    return out


def lift_table(m):
    """Fight lift against boards that don't hold the card (the corrected measure), else the first version."""
    dc = m.deep["cards"]
    return dc.get("fight_lift_vs_other_boards") or dc["fight_lift"]


def predicts_table(m):
    dc = m.deep["cards"]
    return dc.get("board_predicts_vs_other_boards") or dc["board_predicts"]


def pshare(row, n=None):
    """[red share, sample] from a pooled row's own red_share; None when the row has none."""
    if not row or row.get("red_share") is None:
        return None
    return [round(row["red_share"], 4), n if n is not None else row.get("count")]


def share9(ts):
    """[red share, sample] from a section 9 team_share object."""
    if not ts:
        return None
    r, b = (ts.get("red") or {}).get("count") or 0, (ts.get("blue") or {}).get("count") or 0
    return team_share(r, b)


def card_team_share(m):
    return {r["card"]: pshare(r) for r in lift_table(m) if r["scope"] == "both" and r["band"] == "all"}


def lobby_rows(m):
    """Lobbies won per team, the number expected if first place fell at random among the team's top-four
    seats, and the difference. From tempo.lobby; counted from games.jsonl when the analysis lacks it."""
    lob = m.deep["tempo"].get("lobby")
    out = {}
    for c in ("red", "blue"):
        if lob:
            g = lambda k: S(one(lob, scope=c, metric=k))
            out[c] = {"win": g("lobby_win"), "expected": g("lobby_win_expected_if_random_among_top4"),
                      "minus": g("lobby_win_minus_expected"), "top4": g("top4_seats_per_game")}
        else:
            out[c] = {"win": S(lobby_wins(m)[c]), "expected": None, "minus": None, "top4": None}
    return out


def finding_shares(m):
    """Each team's share of the sample behind each finding's pooled measure."""
    conv = m.deep["tempo"]["conversion"]
    fl = lift_table(m)
    tv = m.deep["fights"]["tribe_vs_tribe"]
    br = m.deep["tempo"]["by_round"]
    cnt = lambda st: (st or {}).get("count") or 0
    boards = lambda t: team_share(*(cnt(one(conv, scope=c, final_tribe=t, metric="place")) for c in ("red", "blue")))
    lift = lambda cid: pshare(one(fl, scope="both", band="all", card=cid))
    stage = lambda t, bands: team_share(*(sum(cnt(one(tv, scope=c, band=b, tribe=t, opponent="(other tribes)")) for b in bands)
                                          for c in ("red", "blue")))
    beh = lambda key, sub=None: team_share(*(sum(cnt((v or {}).get(sub) if sub else v)
                                                 for v in ((m.sec9["behaviours"].get(c) or {}).get(key) or {}).values())
                                             for c in ("red", "blue")))
    return [boards("Pigeon"), lift("colour-sergeant"), beh("colonel_win_by_hand_units"), beh("locust_gleaners", "fight_win"),
            boards("Mouse"), stage("Locust", ["7-9", "13+"]), lift("master-at-arms"), stage("Briar", ["13+"]),
            team_share(*(cnt(one(br, scope=c, final_tribe="all", round=12, metric="gold_left")) for c in ("red", "blue"))),
            lift("granary-glutton")]


def finding_extras(m):
    ev = m.events["scopes"]
    out = [None] * 10
    parts = []
    for c in ("red", "blue"):
        g = ((((ev.get(c) or {}).get("sergeants") or {}).get("colour-sergeant") or {}).get("growth_per_fight_round") or {}).get("combined")
        g = (g or {}).get("total")
        if g and g.get("mean") is not None:
            parts.append(f"{c} {g['mean']:.1f} (n={g['count']})")
    if parts:
        out[1] = "Exact growth from replayed events, stats added per fight round with a Colour Sergeant on board: " + ", ".join(parts) + "."
    parts = []
    for c in ("red", "blue"):
        e = (((ev.get(c) or {}).get("eaters") or {}).get("granary-glutton") or {}).get("eats_per_game")
        if e and e.get("mean") is not None:
            parts.append(f"{c} {e['mean']:.2f}")
    if parts:
        out[9] = "Exact Granary Glutton eats per game, from replayed events: " + ", ".join(parts) + "."
    return out


# ---------------------------------------------------------------- sections

def headline(m, status, names):
    sc = m.analysis["score"]
    ws = winscore(m.games)
    red, blue = sc["red_avg_place"], sc["blue_avg_place"]
    gap, gci = sc["gap_red_minus_blue"], sc["gap_ci95"]
    lead_place = None if abs(gap) <= gci else ("blue" if gap > 0 else "red")
    wg, wci = ws["gap_red_minus_blue"], ws["gap_ci95"]
    lead_win = None if (wci != wci or abs(wg) <= wci) else ("red" if wg > 0 else "blue")
    if lead_place and lead_place == lead_win:
        verdict = f"{names[lead_place]} is ahead on both scores."
    elif lead_place and lead_win:
        verdict = (f"The two scores disagree: {names[lead_place]} places better on average, "
                   f"{names[lead_win]} scores more win-weighted points.")
    elif lead_place:
        verdict = f"{names[lead_place]} places better; the win-weighted score is too close to call."
    elif lead_win:
        verdict = f"Average placement is too close to call; {names[lead_win]} scores more win-weighted points."
    else:
        verdict = "Too close to call on both scores."
    h = m.analysis["health"]
    trouble = {k: sum(h["by_colour"][c].get(k, 0) for c in ("red", "blue"))
               for k in ("faults", "clock_outs", "panics", "refused")}
    trouble_text = ("no faults, clock-outs, panics or refused moves" if not any(trouble.values()) else
                    ", ".join(f"{v} {k.replace('_', '-')}" for k, v in trouble.items() if v))
    status_text = {
        "official": "Official match: it counts towards the league.",
        "practice": "Practice match: it doesn't count towards the league.",
        "test": "Test match, not part of the league: shown to check the analysis.",
    }[status]
    pairs = m.analysis.get("seed_pairs") or len({g["game"] // 2 for g in m.games})
    trust = (f"{m.analysis['games']} games ({pairs} seeds, each played twice with the seats swapped) · "
             f"bots {m.summary['red_label']} and {m.summary['blue_label']} · "
             f"played {m.played:%d %b %H:%M} · {trouble_text}.")
    if pairs < 30:
        trust += f" With only {pairs} seeds, most numbers below are too thin to rely on."
    return {
        "status": status, "status_text": status_text, "verdict": verdict, "trust": trust,
        "place": {"red": [red, sc["red_ci95"]], "blue": [blue, sc["blue_ci95"]], "gap": [gap, gci]},
        "win": {"red": ws["red"], "blue": ws["blue"], "gap": [wg, None if wci != wci else wci]},
        "lobby": {c: lobby_rows(m)[c]["win"] for c in ("red", "blue")},
        "rounds_mean": h.get("rounds_mean"),
    }


def placements(m, names):
    conv = m.deep["tempo"]["conversion"]
    out = {}
    for c in ("red", "blue"):
        out[c] = [S(one(conv, scope=c, final_tribe="all", metric=f"place_{i}")) for i in range(1, 9)]
    # reading: most common finish per team and share of firsts
    parts = []
    for c in ("red", "blue"):
        d = [x[0] if x else 0 for x in out[c]]
        mode = max(range(8), key=lambda i: d[i]) + 1
        parts.append(f"{names[c]}'s most common finish is {ordinal(mode)} ({pct(d[mode - 1])} of seats)")
    reading = "; ".join(parts) + ". An even split would put 12.5% of seats in each place."
    return {"dist": out, "reading": reading}


def ordinal(n):
    return f"{n}{'th' if 10 <= n % 100 <= 20 else {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')}"


def conversion(m, names):
    conv = m.deep["tempo"]["conversion"]
    out = {}
    for c in SCOPES:
        out[c] = {k: S(one(conv, scope=c, final_tribe="all", metric=k)) for k in ("place", "win", "top4", "win_given_top4")}
    lob = lobby_rows(m)
    games = len(m.games)
    w = lambda c: lob[c]["win"] or [0, None, None, games, None, 1, 0]
    hi = max(("red", "blue"), key=lambda c: w(c)[0])
    lo = "blue" if hi == "red" else "red"
    first = (f"{names[hi]} wins more lobbies: {w(hi)[6]:.0f} of {w(hi)[3]} ({pct(w(hi)[0], 1)}), "
             f"against {w(lo)[6]:.0f} for {names[lo]}.")
    parts = []
    for c in (hi, lo):
        e, d = lob[c]["expected"], lob[c]["minus"]
        if not e or not d:
            continue
        exp, won = e[0] * games, w(c)[6]
        clear = d[1] is not None and (d[1] > 0 or d[2] < 0)
        if clear and d[0] < 0:
            parts.append(f"{names[c]} {'also ' if c == hi else ''}turns fewer of its top fours into wins than chance would: "
                         f"it won {won:.0f}, against {exp:.2f} expected if first place fell at random among the top four")
        elif clear:
            parts.append(f"{names[c]} {'also ' if c == hi else ''}wins more than its top fours alone would give it: "
                         f"{won:.0f} against {exp:.2f} expected")
        else:
            parts.append(f"{names[c]} wins about what its top fours would give it by chance ({won:.0f} against {exp:.2f})")
    second = ("; ".join(parts) + ". Both halves hold at once: one team can put more seats in the top four "
              "and still lose more of the races for first than chance.") if parts else ""
    a = max(("red", "blue"), key=lambda c: (out[c]["win_given_top4"] or [0])[0])
    b = "blue" if a == "red" else "red"
    conc_reading = ""
    if out[a]["win_given_top4"] and out[b]["win_given_top4"]:
        conc_reading = (f"{names[a]} turns {pct(out[a]['win_given_top4'][0])} of its seats' top-four finishes into first place, "
                        f"{names[b]} {pct(out[b]['win_given_top4'][0])}. If first place fell at random among the four "
                        f"top-four seats, either team would get 25%.")
    return {"teams": out, "lobby": lob, "games": games, "lobby_reading": (first + " " + second).strip(),
            "conc_reading": conc_reading}


def curves(m, names):
    """Levelling compared among seats still alive at a fixed round, so a curve never encodes an early death."""
    t = m.deep["tempo"]
    ot = t["outcome_by_tempo"]
    hz = t.get("curves_at_horizon") or []
    outc = lambda r: {"place": S(r.get("place")), "win": S(r.get("win")), "top4": S(r.get("top4"))}
    plans, reach = {}, {}
    for c in ("red", "blue"):
        plans[c] = {}
        for R in sorted({r["alive_at"] for r in hz}):
            rs = sorted(rows(hz, scope=c, alive_at=R), key=lambda r: -r["seats"])
            plans[c][R] = [{"curve": r["curve"], "rounds": r["rounds"], "seats": r["seats"], "alive": r["alive_seats"], **outc(r)}
                           for r in rs]
        reach[c] = {}
        for N in (3, 4, 5, 6):
            g = [r for r in ot if r["scope"] == c and r["grouping"].startswith(f"tier{N}_round_alive_at_")]
            if not g:
                continue
            R = int(g[0]["grouping"].rsplit("_", 1)[1])
            groups = sorted({r["group"] for r in g}, key=lambda x: (not x.isdigit(), int(x) if x.isdigit() else 0, x))
            alive = sum((one(g, group=x, metric="place") or {}).get("count", 0) for x in groups)
            reach[c][N] = {"at": R, "alive": alive, "groups": [
                {"group": x if x.isdigit() else f"later or never", "seats": (one(g, group=x, metric="place") or {}).get("count", 0),
                 "place": S(one(g, group=x, metric="place")), "win": S(one(g, group=x, metric="win")),
                 "top4": S(one(g, group=x, metric="top4"))} for x in groups]}
    parts = []
    for c in ("red", "blue"):
        p = plans[c].get(8) or []
        if not p:
            continue
        top = p[0]
        share = top["seats"] / (top["alive"] or 1)
        if share >= 0.9:
            parts.append(f"{names[c]} follows one curve, {top['curve']}, in {pct(share)} of its seats alive at round 8, "
                         f"so this match can't separate its tempo from the rest of its play")
        else:
            ok_ = [x for x in p if x["place"] and not x["place"][5]][:2]
            if len(ok_) == 2:
                parts.append(f"among {names[c]}'s seats alive at round 8, {ok_[0]['curve']} ({pct(ok_[0]['seats'] / (top['alive'] or 1))}) "
                             f"averages place {ok_[0]['place'][0]:.2f} and {ok_[1]['curve']} ({pct(ok_[1]['seats'] / (top['alive'] or 1))}) "
                             f"{ok_[1]['place'][0]:.2f}")
            else:
                parts.append(f"{names[c]}'s most common curve among seats alive at round 8 is {top['curve']} ({pct(share)})")
    reading = ("; ".join(parts) + ". " if parts else "") + (
        "Comparing tempo between the two teams compares two whole bots, not two tempos.")
    reading = reading[0].upper() + reading[1:]
    return {"plans": plans, "reach": reach, "reading": reading}


def by_round(m, names):
    br = m.deep["tempo"]["by_round"]
    hp = m.deep["tempo"]["hp_by_round"]
    rounds = sorted({r["round"] for r in br})
    out = {"rounds": rounds}
    for metric in ("tier", "gold_left", "board_stats", "refreshes"):
        out[metric] = {c: [S(one(br, scope=c, final_tribe="all", round=x, metric=metric)) for x in rounds]
                       for c in ("red", "blue")}
    out["alive"] = {c: [S(one(br, scope=c, final_tribe="all", round=x, metric="alive")) for x in rounds]
                    for c in ("red", "blue")}
    hrounds = sorted({r["round"] for r in hp})
    out["hp_rounds"] = hrounds
    out["hp"] = {c: [S(one(hp, scope=c, round=x, metric="hp_dead_as_zero")) for x in hrounds] for c in ("red", "blue")}
    out["alive_share"] = {c: [S(one(hp, scope=c, round=x, metric="alive_share")) for x in hrounds]
                          for c in ("red", "blue")}

    def first_round(c, at):
        for x, s in zip(rounds, out["tier"][c]):
            if s and s[0] >= at:
                return x
        return None
    tr = []
    for c in ("red", "blue"):
        r2, r6 = first_round(c, 1.5), first_round(c, 5.5)
        tr.append(f"{names[c]} averages tier 2 by round {r2 or '—'}" + (f" and tier 6 by round {r6}" if r6 else ""))
    gl = out["gold_left"]
    best = None
    for i, x in enumerate(rounds):
        a, b = gl["red"][i], gl["blue"][i]
        if a and b and not a[5] and not b[5]:
            d = abs(a[0] - b[0])
            if best is None or d > best[0]:
                best = (d, x, a[0], b[0])
    rl = lambda x: f"round {x}" if x < 15 else "round 15 and later"
    gold_reading = (f"The gap is widest in {rl(best[1])}: {names['red']} ends its turn with {best[2]:.1f} gold "
                    f"unspent, {names['blue']} with {best[3]:.1f}. Gold carries over, so unspent gold is saved, not lost."
                    if best else "Too few games to compare unspent gold.")
    hpr = None
    for i, x in enumerate(hrounds):
        if x == 10:
            hpr = i
    hp_reading = ""
    if hpr is not None and out["hp"]["red"][hpr] and out["hp"]["blue"][hpr]:
        hp_reading = (f"After round 10, {names['red']} seats average {out['hp']['red'][hpr][0]:.1f} health and "
                      f"{names['blue']} seats {out['hp']['blue'][hpr][0]:.1f}, counting the dead as zero.")
    return {**out, "tier_reading": "; ".join(tr) + ".", "gold_reading": gold_reading, "hp_reading": hp_reading}


def game_shape(m, names):
    """When games are decided, and how much an early health lead is worth."""
    f = m.deep["fights"]
    gs = f.get("game_shape") or []
    shape = {sc: {r["metric"]: S(r) for r in gs if r["scope"] == sc} for sc in ("all", "red", "blue")}
    hp = f.get("outcome_by_hp_rank") or []
    rounds = sorted({r["round"] for r in hp})
    by_rank = {R: {c: {k: [S(one(hp, scope=c, round=R, hp_rank=i, metric=k)) for i in range(1, 9)] for k in ("win", "top4")}
                   for c in ("red", "blue")} for R in rounds}
    a = shape["all"]
    reading = ""
    if a.get("decided_round") and a.get("rounds"):
        reading = (f"The eventual winner holds the most health from round {a['decided_round'][0]:.1f} on average, in games of "
                   f"{a['rounds'][0]:.1f} rounds")
        if a.get("winner_was_bottom_half"):
            reading += f"; {pct(a['winner_was_bottom_half'][0])} of winners were in the bottom half on health at some point"
        reading += "."
    R = 8 if 8 in by_rank else (rounds[-1] if rounds else None)
    hp_reading = ""
    if R is not None:
        bits = [f"{names[c]} {pct(by_rank[R][c]['win'][0][0])}" for c in ("red", "blue") if by_rank[R][c]["win"][0]]
        if bits:
            hp_reading = f"A seat with the most health after round {R} goes on to win: " + ", ".join(bits) + "."
    return {"shape": shape, "by_rank": by_rank, "rounds": rounds, "reading": reading, "hp_reading": hp_reading}


def seats(m, names):
    """Seat fairness: average place by seat id, and seats 0-2 against seats 5-7 over the same seed pairs."""
    f = m.deep["fights"]
    bs = f.get("by_seat") or []
    place = {c: [S(one(bs, scope=c, seat=i, metric="place")) for i in range(8)] for c in SCOPES}
    gap = {r["scope"]: S(r) for r in f.get("seat_gap") or []}
    g = gap.get("both")
    if g and g[1] is not None:
        clear = g[1] > 0 or g[2] < 0
        reading = (f"Seats 0-2 average {abs(g[0]):.2f} places {'better' if g[0] < 0 else 'worse'} than seats 5-7 "
                   f"[{g[1]:+.2f} to {g[2]:+.2f}]: " + ("a real seat effect, worth checking in the pairing rule." if clear else
                                                     "within the noise, so no sign the seat id matters."))
    else:
        reading = "Too few games to compare seats."
    return {"place": place, "gap": gap, "reading": reading}


def upgrades(m):
    up = m.deep["tempo"]["upgrade_prices"]
    lp = m.deep["tempo"]["list_price"]
    out = []
    for c in ("red", "blue"):
        for t in sorted({r["from_tier"] for r in up if r["scope"] == c}):
            g = {k: S(one(up, scope=c, from_tier=t, metric=k)) for k in ("paid", "turns_waited", "round")}
            out.append({"team": c, "from": t, "list": lp.get(str(t)), **g})
    return out


def tribe_rel(m, t):
    """A tribe's average place minus its own team's average place, weighted over the two teams by boards.
    Pooling raw placement would mix team strength into the tribe (a weak team's favourite tribe looks weak)."""
    conv = m.deep["tempo"]["conversion"]
    num = den = var = 0.0
    pairs = 0
    for c in ("red", "blue"):
        p, base = one(conv, scope=c, final_tribe=t, metric="place"), one(conv, scope=c, final_tribe="all", metric="place")
        if not p or not base or val(p) is None or not p.get("count"):
            continue
        n = p["count"]
        num += n * (val(p) - val(base))
        den += n
        pairs = max(pairs, p.get("pairs") or 0)
        h = (p["ci95"][1] - p["ci95"][0]) / 2 if p.get("ci95") else None
        var = None if h is None or var is None else var + (n * h) ** 2
    if not den:
        return None
    d = num / den
    h = None if var is None else math.sqrt(var) / den
    return {"mean": d, "ci95": None if h is None else [d - h, d + h], "count": int(den), "pairs": pairs,
            "thin": den < THIN_COUNT or pairs < THIN_PAIRS}


def tribes_section(m, names):
    conv = m.deep["tempo"]["conversion"]
    tv = m.deep["fights"]["tribe_vs_tribe"]
    per = {}
    for c in SCOPES:
        total = (one(conv, scope=c, final_tribe="all", metric="place") or {}).get("count") or 0
        per[c] = {}
        for t in TRIBES:
            p = one(conv, scope=c, final_tribe=t, metric="place")
            per[c][t] = {k: S(one(conv, scope=c, final_tribe=t, metric=k)) for k in ("place", "win", "top4", "win_given_top4")}
            n = (p or {}).get("count", 0)
            per[c][t]["share"] = [round(n / total, 4) if total else 0, None, None, n, None, 0, n]
            per[c][t]["team_place"] = S(one(conv, scope=c, final_tribe="all", metric="place"))
    matrix = {c: {t: {o: S(one(tv, scope=c, band="all", tribe=t, opponent=o)) for o in TRIBES} for t in TRIBES}
              for c in SCOPES}
    stage = {c: {t: [S(one(tv, scope=c, band=b, tribe=t, opponent="(other tribes)")) for b in BANDS] for t in TRIBES}
             for c in SCOPES}
    # each tribe's fights by team: the share behind any pooled tribe number
    fight_share = {}
    for t in TRIBES:
        n = {c: (one(tv, scope=c, band="all", tribe=t, opponent="(other tribes)") or {}).get("count", 0) for c in ("red", "blue")}
        fight_share[t] = team_share(n["red"], n["blue"])
    rel = {t: S(tribe_rel(m, t)) for t in TRIBES}
    rel_share = {t: team_share(per["red"][t]["share"][3], per["blue"][t]["share"][3]) for t in TRIBES}
    # placement within each team
    sg = lambda x: f"{'+' if x >= 0 else '−'}{abs(x):.2f}"
    parts = []
    for c in ("red", "blue"):
        ok_ = [(t, per[c][t]["place"]) for t in TRIBES if per[c][t]["place"] and not per[c][t]["place"][5]]
        base = per[c][TRIBES[0]]["team_place"]
        if len(ok_) >= 2 and base:
            ok_.sort(key=lambda x: x[1][0])
            parts.append(f"within {names[c]}, {ok_[0][0]} boards place best ({ok_[0][1][0]:.2f}, {sg(ok_[0][1][0] - base[0])} on the team's "
                         f"{base[0]:.2f}) and {ok_[-1][0]} worst ({ok_[-1][1][0]:.2f})")
        elif len(ok_) == 1:
            parts.append(f"{names[c]} has a real sample for {ok_[0][0]} only")
    place_reading = ("; ".join(parts) + ". Tribes with fewer than 30 boards are left out of this sentence."
                     if parts else "Too few boards per tribe to rank them.")
    place_reading = place_reading[0].upper() + place_reading[1:]
    shares = {c: max(TRIBES, key=lambda t: per[c][t]["share"][0]) for c in ("red", "blue")}
    share_reading = "; ".join(f"{names[c]} ends most often as {shares[c]} ({pct(per[c][shares[c]]['share'][0])} of its seats)"
                              for c in ("red", "blue")) + "."
    conv_ok = [(f"{names[c]}'s {t}", per[c][t]) for c in ("red", "blue") for t in TRIBES
               if per[c][t]["top4"] and not per[c][t]["top4"][5]]
    conv_reading = ""
    if len(conv_ok) >= 2:
        lo = min(conv_ok, key=lambda x: x[1]["top4"][0])
        hi = max(conv_ok, key=lambda x: x[1]["top4"][0])
        conv_reading = (f"{hi[0]} boards make the top four most often ({pct(hi[1]['top4'][0])}), {lo[0]} boards least "
                        f"({pct(lo[1]['top4'][0])}). Compare tribes within a team: the two teams' baselines differ.")
    # stage moves, per team
    sparts = []
    for c in ("red", "blue"):
        moves = []
        for t in TRIBES:
            a, b = stage[c][t][2], stage[c][t][4]
            if a and b and not a[5] and not b[5]:
                moves.append((b[0] - a[0], t, a[0], b[0]))
        if moves:
            moves.sort()
            dn, up_ = moves[0], moves[-1]
            if dn[0] < -0.05:
                sparts.append(f"{names[c]}'s {dn[1]} boards fall from {pct(dn[2])} of fights won in rounds 7-9 to {pct(dn[3])} from round 13")
            if up_[0] > 0.05:
                sparts.append(f"{names[c]}'s {up_[1]} boards rise from {pct(up_[2])} to {pct(up_[3])}")
    stage_reading = ("; ".join(sparts) + "." if sparts else "Too few late fights per team to compare stages.")
    # matrix reading per team
    mparts = []
    for c in ("red", "blue"):
        best = None
        for t in TRIBES:
            for o in TRIBES:
                s = matrix[c][t][o]
                if t != o and s and not s[5] and (best is None or abs(s[0] - .5) > abs(best[0] - .5)):
                    best = (s[0], t, o, s[3])
        if best:
            mparts.append(f"for {names[c]}, {best[1]} boards against {best[2]} win {pct(best[0])} of {best[3]} fights")
    matrix_reading = ("Most one-sided matchup with enough fights: " + "; ".join(mparts) + "."
                      if mparts else "Too few fights for a matchup table.")
    # commit and mixed boards, per team (section 9 tribes.json)
    commit, mixed = {}, {}
    for c in SCOPES:
        t9 = m.sec9["tribes"].get(c, {})
        commit[c] = {t: {"committed": S(((t9.get("commit") or {}).get(t) or {}).get("committed")),
                         "round": S(((t9.get("commit") or {}).get(t) or {}).get("round"))} for t in TRIBES}
        mixed[c] = {k: S(t9.get(k)) for k in ("mixed", "mixed_win", "mixed_placement", "pivot", "pivot_placement")}
    up = m.deep["fights"]["upsets"]
    upsets = {c: {t: S(one(up, scope=c, stat_ratio="any", band="all", weaker_tribe=t)) for t in TRIBES + ["all"]}
              for c in SCOPES}
    ratios = ["1-1.25x", "1.25-1.5x", "1.5-2x", "2-3x", "3x+"]
    ladder = {c: {r: S(one(up, scope=c, stat_ratio=r, band="all", weaker_tribe="all")) for r in ratios} for c in SCOPES}
    uparts = []
    for c in ("red", "blue"):
        ok_t = sorted([(t, upsets[c][t]) for t in TRIBES if upsets[c][t] and not upsets[c][t][5]], key=lambda x: -x[1][0])
        if upsets[c]["all"]:
            s_ = f"{names[c]} wins {pct(upsets[c]['all'][0])} of the fights it enters with fewer stats"
            if len(ok_t) >= 2:
                s_ += f" ({ok_t[0][0]} boards {pct(ok_t[0][1][0])}, {ok_t[-1][0]} boards {pct(ok_t[-1][1][0])})"
            uparts.append(s_)
    upset_reading = ("; ".join(uparts) + "." if uparts else "Too few fights to compare tribes as underdogs.")
    # how far apart a team's tribes are, with an interval (tempo.tribe_gap_within_team)
    gaps = {}
    for g in m.deep["tempo"].get("tribe_gap_within_team") or []:
        c = g["scope"]
        pl = {x: per[c][x]["place"][0] for x in (g.get("best"), g.get("worst")) if x in per.get(c, {}) and per[c][x]["place"]}
        if len(pl) == 2:
            # name the two tribes from their own average places, so the sentence can't contradict the chart
            gaps[c] = {"gap": S(g["gap"]), "better": min(pl, key=pl.get), "worse": max(pl, key=pl.get), "tribes": g.get("tribes")}
    gparts = [f"{names[c]}'s tribes are {abs(x['gap'][0]):.2f} places apart"
              + (f" [{abs(x['gap'][1]):.2f} to {abs(x['gap'][2]):.2f}]" if x["gap"][1] is not None and x["gap"][1] * x["gap"][2] > 0 else "")
              + f", {x['better']} best and {x['worse']} worst, over {x['tribes']} tribes with 30+ seats"
              for c, x in gaps.items() if x["gap"]]
    gap_reading = ("Within each team: " + "; ".join(gparts) + ". Picking the two ends after looking widens the gap a little."
                   if gparts else "")
    return {"per": per, "rel": rel, "rel_share": rel_share, "fight_share": fight_share, "matrix": matrix,
            "upsets": upsets, "ladder": ladder, "ratios": ratios, "upset_reading": upset_reading, "stage": stage,
            "gaps": gaps, "gap_reading": gap_reading,
            "commit": commit, "mixed": mixed, "place_reading": place_reading, "share_reading": share_reading,
            "conv_reading": conv_reading, "stage_reading": stage_reading, "matrix_reading": matrix_reading}


def cards_section(m, names):
    dc = m.deep["cards"]
    c9 = m.sec9["cards"]
    fl, bp, ten, rs, pr = lift_table(m), predicts_table(m), dc["tenure"], dc["resales"], dc["pick_rate"]
    sales = dc.get("sales") or []
    exact = bool(sales)
    ids = [cid for cid, c in m.library.items() if not c.get("spell") and not c.get("token")]
    ids += [cid for cid, c in m.library.items() if c.get("token") and any(r["card"] == cid for r in fl)]
    table = []
    for cid in ids:
        c = m.library[cid]
        row = {"id": cid, "name": c["name"], "tribe": (c.get("tribes") or ["—"])[0], "tier": c.get("tier"),
               "token": bool(c.get("token")), "s": {}}
        for sc in SCOPES:
            k9 = (c9.get(sc) or {}).get(cid) or {}
            r9 = {"win": None, "top4": None, "place": None}
            p9 = one(bp, scope=sc, round=9, card=cid)
            if p9:
                r9 = {k: S(p9[k]) for k in ("win", "top4", "place")}
            tn = {k: S(one(ten, scope=sc, card=cid, metric=k))
                  for k in ("fights_on_board", "kept_to_end", "left_after_one_fight", "tripled", "sold", "eaten",
                            "left_unexplained")}
            sl = {k: S(one(sales, scope=sc, card=cid, metric=k))
                  for k in ("rounds_on_board", "sold_in_entry_round", "sale_fed_something")}
            rr = one(rs, scope=sc, card=cid)
            row["s"][sc] = {
                "buy": S(k9.get("buy")),
                "band": [S((k9.get("by_band") or {}).get(b)) for b in BANDS],
                "lift": S(one(fl, scope=sc, band="all", card=cid)),
                "lift_band": [S(one(fl, scope=sc, band=b, card=cid)) for b in BANDS],
                "r9": r9,
                "final_lift": S(k9.get("lift_places")),
                "golden": S(k9.get("golden")),
                "discover": S(k9.get("discover")),
                "never": bool(k9.get("never_bought")),
                **tn, "sales": sl,
                "resale": None if not rr else [rr["buys"], rr["sells"], rr["sold_same_turn_as_a_buy"], 1 if rr.get("thin") else 0],
            }
        table.append(row)
    # band x final tribe matrix for the "bought whatever the tribe" view
    matrix = {}
    for sc in SCOPES:
        matrix[sc] = {}
        for b in BANDS:
            cells = {}
            for r in rows(pr, scope=sc, band=b):
                if r["final_tribe"] in TRIBES:
                    cells.setdefault(r["card"], {})[r["final_tribe"]] = S(r)
            matrix[sc][b] = cells
    # pooled numbers carry the team that played the card: record each team's share of the sample
    cnt = lambda st: st[3] if st else 0
    pooled = lambda table_, **k: {r["card"]: r for r in table_ if r["scope"] == "both" and all(r.get(a) == b for a, b in k.items())}
    pl, pt, ps = pooled(fl, band="all"), pooled(ten, metric="kept_to_end"), pooled(sales, metric="sold_in_entry_round")
    for r in table:
        sr, sb = r["s"]["red"], r["s"]["blue"]
        r["share"] = {"lift": pshare(pl.get(r["id"])) or team_share(cnt(sr["lift"]), cnt(sb["lift"])),
                      "buy": share9(((c9.get("both") or {}).get(r["id"]) or {}).get("team_share", {}).get("never_bought"))
                      or team_share(cnt(sr["buy"]), cnt(sb["buy"])),
                      "tenure": pshare(pt.get(r["id"])) or team_share(cnt(sr["fights_on_board"]), cnt(sb["fights_on_board"])),
                      "resale": pshare(ps.get(r["id"])) or team_share((sr["resale"] or [0])[0], (sb["resale"] or [0])[0])}
    one_team = sum(1 for r in table if r["share"]["lift"] and r["s"]["both"]["lift"] and (r["share"]["lift"][0] >= .9 or r["share"]["lift"][0] <= .1))
    pooled_n = sum(1 for r in table if r["s"]["both"]["lift"])
    # per-team lift, ranked within tier by the interval's near bound, with a minimum sample
    tiers = {}
    tparts = []
    for c in ("red", "blue"):
        tiers[c] = []
        for tier in range(1, 7):
            cand = [r for r in table if r["tier"] == tier and not r["token"] and r["s"][c]["lift"]
                    and not r["s"][c]["lift"][5] and r["s"][c]["lift"][3] >= MIN_LIFT_FIGHTS and r["s"][c]["lift"][1] is not None]
            best = max(cand, key=lambda r: r["s"][c]["lift"][1], default=None)
            rest = [r for r in cand if r is not best]
            worst = min(rest, key=lambda r: r["s"][c]["lift"][2], default=None)
            tiers[c].append({"tier": tier, "n": len(cand), "best": best["id"] if best else None,
                             "worst": worst["id"] if worst else None})
        spread = [(t["tier"], LIFT(table, t["best"], c) - LIFT(table, t["worst"], c), t) for t in tiers[c] if t["worst"]]
        if spread:
            sp = max(spread, key=lambda x: x[1])
            tparts.append(f"for {names[c]}, the widest gap inside one tier is tier {sp[0]}: {card_name(m, sp[2]['best'])} "
                          f"{pts(LIFT(table, sp[2]['best'], c))} against {card_name(m, sp[2]['worst'])} {pts(LIFT(table, sp[2]['worst'], c))}")
    tier_reading = (("; ".join(tparts) + ".").capitalize()[0] + ("; ".join(tparts) + ".")[1:] if tparts else f"No tier has two cards with {MIN_LIFT_FIGHTS}+ fights for one team.")
    never = []
    for r in table:
        b = r["s"]["both"]["buy"]
        if b and b[3] >= 30 and b[0] < 0.02:
            per_team = {c: r["s"][c]["buy"] for c in ("red", "blue")}
            both_teams = all(per_team[c] and per_team[c][3] >= 30 and per_team[c][0] < 0.02 for c in ("red", "blue"))
            never.append({"id": r["id"], "both_teams": both_teams})
    never.sort(key=lambda x: (not x["both_teams"], -next(r for r in table if r["id"] == x["id"])["s"]["both"]["buy"][3]))
    flips = []
    for r in table:
        if exact:
            e = r["s"]["both"]["sales"]["sold_in_entry_round"]
            if e and e[3] >= 30:
                flips.append((e[0], r["id"]))
        else:
            rr = r["s"]["both"]["resale"]
            if rr and rr[0] >= 30:
                flips.append((rr[2] / rr[0], r["id"]))
    flips.sort(reverse=True)
    # "bought by every final tribe" verdicts per band (cards.py), with the team share behind pooled ones
    always = {}
    for sc in SCOPES:
        always[sc] = {}
        for b in BANDS:
            ids_ = [cid for cid, d in (c9.get(sc) or {}).items() if (d.get("always_bought_in_band") or {}).get(b)]
            always[sc][b] = [{"id": cid, "share": share9(((c9[sc][cid].get("band_evidence") or {}).get(b) or {}).get("team_share"))
                              if sc == "both" else None} for cid in ids_ if cid in m.library]
    always_reading = {}
    for b in BANDS:
        pb = always["both"][b]
        ot = [x for x in pb if x["share"] and (x["share"][0] >= .9 or x["share"][0] <= .1)]
        txt = (f"Pooled, {len(pb)} cards count as bought by every final tribe in rounds {b}" if pb else
               f"Pooled, no card counts as bought by every final tribe in rounds {b}")
        if ot:
            who = {("red" if x["share"][0] >= .9 else "blue") for x in ot}
            txt += (f"; {'all' if len(ot) == len(pb) else len(ot)} of {'them' if len(ot) == len(pb) else len(pb)} rest 90% or more on "
                    + " or ".join(f"{names[w]}'s" for w in sorted(who)) + " shops, so they show how one bot buys, not two bots agreeing")
        txt += ". " + "; ".join(f"{names[c]} alone: {len(always[c][b])}" for c in ("red", "blue")) + "."
        always_reading[b] = txt
    matrix_share = {b: {r["card"]: pshare(r) for r in pr if r["scope"] == "both" and r["band"] == b and r["final_tribe"] == "all"}
                    for b in BANDS}
    stay = [r for r in table if r["s"]["both"]["kept_to_end"] and not r["s"]["both"]["kept_to_end"][5]]
    keep = sorted(stay, key=lambda r: -r["s"]["both"]["kept_to_end"][0])[:6]
    drop = sorted([r for r in table if r["s"]["both"]["left_after_one_fight"] and not r["s"]["both"]["left_after_one_fight"][5]],
                  key=lambda r: -r["s"]["both"]["left_after_one_fight"][0])[:6]
    nm = lambda rs_: ", ".join(card_tag(m, r["id"]) for r in rs_[:3])
    readings = {
        "tiers": tier_reading,
        "one_team": (f"{one_team} of {pooled_n} pooled fight lifts come 90% or more from one team's boards; "
                     "the table marks them." if pooled_n else ""),
        "never": (f"{sum(1 for x in never if x['both_teams'])} cards are bought in under 2% of the shops that offer them "
                  f"by both teams; {sum(1 for x in never if not x['both_teams'])} more by one team only." if never else
                  "Every card offered in 30+ shops is bought at least 2% of the time."),
        "flips": ((f"{card_tag(m, flips[0][1])} is sold in the round it reached the board {pct(flips[0][0])} of the times it is sold: "
                   "fuel, triple fodder or a stopgap. Exact, from replayed events." if exact else
                   f"{card_tag(m, flips[0][1])} is sold in the same turn a copy was bought {pct(flips[0][0])} of the times it is bought: "
                   "triple fodder or a stopgap.") if flips else ""),
        "tenure": (f"{card_tag(m, keep[0]['id'])} stays to the end {pct(keep[0]['s']['both']['kept_to_end'][0])} of the time; "
                   f"{card_tag(m, drop[0]['id'])} leaves after one fight {pct(drop[0]['s']['both']['left_after_one_fight'][0])} of the time."
                   if keep and drop else ""),
    }
    thin_rows = sum(1 for r in table if not r["s"]["both"]["lift"] or r["s"]["both"]["lift"][5])
    lift_kind = "vs_other" if m.deep["cards"].get("fight_lift_vs_other_boards") else "stratum"
    return {"table": table, "matrix": matrix, "matrix_share": matrix_share, "always": always, "always_reading": always_reading,
            "exact_sales": exact, "lift_kind": lift_kind, "tiers": tiers, "min_fights": MIN_LIFT_FIGHTS,
            "never": never, "flips": [[round(f, 4), cid] for f, cid in flips[:6]],
            "keep": [r["id"] for r in keep], "drop": [r["id"] for r in drop],
            "readings": readings, "thin_rows": thin_rows}


def synergy_section(m):
    sy = m.deep["synergy"]
    pairs = []
    for p in sy["pairs"]:
        it = p["interaction"]
        rs = p.get("red_share")
        tm = None if rs is None else "red" if rs >= .9 else "blue" if rs <= .1 else None
        pairs.append({"a": p["a"], "b": p["b"], "together": p["together"],
                      "i": [round(it["value"], 4), *(round(x, 4) for x in (it.get("ci95") or [None, None])),
                            p["together"], it.get("pairs"), 1 if p.get("thin") or it.get("thin") else 0],
                      "best": S(p.get("excess_over_best_single")),
                      "team": tm, "share": None if rs is None else [round(rs, 4), p["together"]]})
    pairs.sort(key=lambda p: -p["i"][0])
    good = [p for p in pairs if not p["i"][5]]
    clear = [p for p in good if p["i"][1] is not None and (p["i"][1] > 0 or p["i"][2] < 0)]
    n = len(pairs)
    ot = sum(1 for p in pairs if p["team"])
    reading = ((f"{len(clear)} of {n} pairs tested clear a 95% interval; about {round(n * 0.05)} would by chance alone. "
                f"Treat each as a lead to test with a constructed fight.")
               + (f" {ot} of the {n} pairs are 90% or more one team's fights." if ot else "")) if n else "No pair had enough fights together."
    return {"top": good[:8], "bottom": sorted(good, key=lambda p: p["i"][0])[:8], "n": n,
            "from_round": sy.get("from_round"), "reading": reading}


def binned(d, bins):
    """Pool keyed rates (heap size -> rate) into bins. Counts and hits add up; no interval (the clustering
    is lost when pooling), so each bin is marked thin unless it has 30+ observations."""
    out = {}
    for lo, hi in bins:
        hits = n = 0
        for k, st in d.items():
            if lo <= int(k) <= hi and st:
                hits += st.get("hits", 0)
                n += st.get("count", 0)
        if n:
            label = str(lo) if lo == hi else (f"{lo}+" if hi >= 10 ** 6 else f"{lo}-{hi}")
            out[label] = [round(hits / n, 4), None, None, n, None, 1 if n < THIN_COUNT else 0, round(hits, 1)]
    return out


def behaviours_section(m, names):
    ev = m.events["scopes"]
    out = {"eats": {}, "sergeants": {}}
    for c in SCOPES:
        e = ev.get(c) or {}
        out["eats"][c] = {
            "per_game": S(e.get("eats_per_game")), "fed": S(e.get("fed_sales")),
            "stats": S((e.get("stats_per_eat") or {}).get("total")),
            "eaters": {k: {"per_game": S(v.get("eats_per_game")), "per_unit_round": S(v.get("eats_per_unit_round")),
                           "stats": S((v.get("stats_per_eat") or {}).get("total"))}
                       for k, v in (e.get("eaters") or {}).items()},
        }
        sg = e.get("sergeants") or {}
        out["sergeants"][c] = {k: {kk: S(((v.get("growth_per_fight_round") or {}).get(kk) or {}).get("total"))
                                   for kk in (v.get("growth_per_fight_round") or {})}
                               for k, v in sg.items()}
    games = len(m.games)
    out["food"], out["eat_rounds"], out["sale_age"], out["slots"] = {}, {}, {}, {}
    for c in ("red", "blue"):
        e = ev.get(c) or {}
        ea = e.get("eaten") or {}
        out["food"][c] = {"by_tier": [S((ea.get("by_tier") or {}).get(str(t))) for t in range(1, 7)],
                          "top": [[cid, S((ea.get("by_card") or {}).get(cid))] for cid in (ea.get("top_15_cards") or [])[:8]
                                  if cid in m.library]}
        br_ = {int(k): (v.get("stats_per_eat") or {}).get("total") for k, v in (e.get("by_round") or {}).items()}
        er = {k: S(v) for k, v in br_.items() if k < 15 and v and v.get("count")}
        late = [v for k, v in br_.items() if k >= 15 and v and v.get("count")]
        if late:  # rounds 15 and later share one point, as elsewhere on the page; pooling loses the interval
            n = sum(v["count"] for v in late)
            er[15] = [round(sum(v["total"] for v in late) / n, 4), None, None, n, None, 1 if n < THIN_COUNT else 0, None]
        out["eat_rounds"][c] = er
        out["sale_age"][c] = {g: S(v) for g, v in (e.get("rounds_on_board_before_sale") or {}).items()}
        sl = []
        for cid, sides in (e.get("slot_growth_by_source") or {}).items():
            live = (sides.get("live") or {}).get("total")
            if live and live.get("total") and cid in m.library:
                sl.append({"id": cid, "per_game": round(live["total"] / games, 2) if games else None, "per_event": S(live),
                           "events": live.get("count")})
        sl.sort(key=lambda x: -(x["per_game"] or 0))
        out["slots"][c] = sl[:8]
    rr = sorted({k for c in ("red", "blue") for k in out["eat_rounds"][c]})
    out["eat_round_list"] = rr
    fparts = []
    for c in ("red", "blue"):
        bt = out["food"][c]["by_tier"]
        if any(bt):
            low = sum(x[0] for x in bt[:2] if x)
            fparts.append(f"{pct(low)} of what {names[c]}'s eaters eat is tier 1 or 2")
    out["food_reading"] = ("; ".join(fparts) + "." if fparts else "")
    sa = []
    for c in ("red", "blue"):
        g = out["sale_age"][c]
        if g.get("fed") and g.get("unfed"):
            sa.append(f"{names[c]}'s fed sales had been on the board {g['fed'][0]:.1f} rounds, unfed ones {g['unfed'][0]:.1f}")
    out["age_reading"] = "; ".join(sa) + "." if sa else ""
    out["keyed"] = {}
    for c in ("red", "blue"):
        b = m.sec9["behaviours"].get(c, {})
        out["keyed"][c] = {
            "compost": binned(b.get("briar_win_by_compost") or {}, [(0, 0), (1, 2), (3, 5), (6, 9), (10, 14), (15, 19), (20, 10 ** 6)]),
            "gleaners": {r: S((v or {}).get("fight_win")) for r, v in (b.get("locust_gleaners") or {}).items()},
            "outnumbered": {r: S(v) for r, v in (b.get("badger_win_by_outnumbered") or {}).items()},
            "colonel": {r: S(v) for r, v in (b.get("colonel_win_by_hand_units") or {}).items()},
        }
    parts = []
    for c in ("red", "blue"):
        e = out["eats"][c]
        if e["per_game"] and e["fed"]:
            parts.append(f"{names[c]}'s eaters ate {e['per_game'][0]:.1f} sold units a game ({pct(e['fed'][0])} of its sales)")
    out["reading"] = ("; ".join(parts) + ". Exact counts from replayed events." if parts else "No eats were logged.")
    return out


# ---------------------------------------------------------------- the ten findings

FINDINGS = [
    ("Pigeons are far ahead of the field", "Pigeon avg place 3.2, win 32% in 455 tribe-locked lobbies."),
    ("Colour Sergeant out-produces its tier", "Strongest card in lobby lift; two Sergeants stack."),
    ("The Colonel's Reserve is uncapped", "2+ units in hand turned 0% into 84-100% in constructed fights."),
    ("Gleaner: 5 damage per friendly death, unlimited", "0 Gleaners 0%, 1 → 49%, 2 → 99% in constructed fights."),
    ("Mice are the weakest tribe", "Avg place 6.2, top four 17%, win 1%."),
    ("Locusts fall off late", "54-66% fight win to round 9, then 36% and 16% from round 13."),
    ("Badger Fury supports underperform", "Master-at-Arms has the worst Badger lift."),
    ("Briars dominate late, through the Compost", "68-74% fight win from round 10."),
    ("Gold-making cards are weak: gold isn't scarce", "Bots end rounds 12-14 with 7-26 gold unspent."),
    ("Granary Glutton eats every Locust sold", "Unlimited eats; not tested."),
]


def evidence(m):
    """Per finding: (measure label, stat in claim direction or None, shown stat, shown format, direction note)."""
    conv = m.deep["tempo"]["conversion"]
    fl = lift_table(m)
    tv = m.deep["fights"]["tribe_vs_tribe"]
    br = m.deep["tempo"]["by_round"]
    b = m.sec9["behaviours"].get("both", {})
    c9 = m.sec9["cards"].get("both", {})

    def place(t):
        return one(conv, scope="both", final_tribe=t, metric="place")

    def lift(cid):
        return one(fl, scope="both", band="all", card=cid)

    def stage(t, band):
        return one(tv, scope="both", band=band, tribe=t, opponent="(other tribes)")

    def diff(a, b_, sign=1):
        if not a or not b_ or val(a) is None or val(b_) is None:
            return None
        ha = (a["ci95"][1] - a["ci95"][0]) / 2 if a.get("ci95") else None
        hb = (b_["ci95"][1] - b_["ci95"][0]) / 2 if b_.get("ci95") else None
        d = sign * (val(a) - val(b_))
        h = math.sqrt(ha ** 2 + hb ** 2) if ha is not None and hb is not None else None
        return {"mean": d, "ci95": None if h is None else [d - h, d + h],
                "count": min(a.get("count", 0), b_.get("count", 0)),
                "pairs": min(a.get("pairs") or 0, b_.get("pairs") or 0), "thin": is_thin(a) or is_thin(b_)}

    def shift(st, ref, sign=1):
        if not st or val(st) is None:
            return None
        d = sign * (val(st) - ref)
        ci = st.get("ci95")
        lo, hi = (sorted([sign * (ci[0] - ref), sign * (ci[1] - ref)]) if ci else (None, None))
        return {"mean": d, "ci95": None if ci is None else [lo, hi], "count": st.get("count"),
                "pairs": st.get("pairs"), "thin": is_thin(st)}

    def neg(st):
        return shift(st, 0, -1)

    gl = (b.get("locust_gleaners") or {})
    g0 = (gl.get("0") or {}).get("fight_win")
    g1 = (gl.get("1") or {}).get("fight_win")
    col = b.get("colonel_win_by_hand_units") or {}
    col2 = None
    tot = [col[k] for k in col if k.isdigit() and int(k) >= 2]
    if tot:
        hits = sum(x.get("hits", 0) for x in tot)
        n = sum(x["count"] for x in tot)
        col2 = {"rate": hits / n, "count": n, "pairs": max(x.get("pairs") or 0 for x in tot), "ci95": None,
                "thin": n < THIN_COUNT, "hits": hits}
    gold12 = one(br, scope="both", final_tribe="all", round=12, metric="gold_left")
    colonel_buy = (c9.get("the-colonel") or {}).get("buy")
    return [
        ("Pigeon boards' place against their own team's average (below 0 = ahead)", shift(tribe_rel(m, "Pigeon"), 0, -1),
         S(tribe_rel(m, "Pigeon")), "rel"),
        ("Colour Sergeant fight lift", lift("colour-sergeant"), S(lift("colour-sergeant")), "lift"),
        ("Colonel boards with 2+ units in hand: fights won", col2, S(col2) if col2 else S(colonel_buy), "rate" if col2 else "buy"),
        ("Locust fights won, 1 Gleaner minus none", diff(g1, g0), S(diff(g1, g0)), "lift"),
        ("Mouse boards' place against their own team's average (above 0 = behind)", tribe_rel(m, "Mouse"),
         S(tribe_rel(m, "Mouse")), "rel"),
        ("Locust fights won, rounds 7-9 minus 13+", diff(stage("Locust", "7-9"), stage("Locust", "13+")),
         S(diff(stage("Locust", "7-9"), stage("Locust", "13+"))), "lift"),
        ("Master-at-Arms fight lift (below 0 = weak)", neg(lift("master-at-arms")), S(lift("master-at-arms")), "lift"),
        ("Briar fights won from round 13, above 50% = dominant", shift(stage("Briar", "13+"), 0.5), S(stage("Briar", "13+")), "rate"),
        ("Gold left unspent at round 12", gold12, S(gold12), "gold"),
        ("Granary Glutton fight lift", lift("granary-glutton"), S(lift("granary-glutton")), "lift"),
    ]


def reading_of(effect, naive_effect):
    if not effect or val(effect) is None or effect.get("ci95") is None or is_thin(effect):
        return "can't tell"
    lo, hi = effect["ci95"]
    if hi < 0:
        return "reversed"
    if lo <= 0:
        return "can't tell"
    if naive_effect and val(naive_effect) is not None and not is_thin(naive_effect) and val(naive_effect) > 0:
        r = val(effect) / val(naive_effect)
        if r >= 1.33:
            return "stronger"
        if r <= 0.75:
            return "weaker"
    return "holds"


def findings_section(m, naive):
    me = evidence(m)
    ne = evidence(naive) if naive else [None] * 10
    sh = finding_shares(m)
    ex = finding_extras(m)
    out = []
    for i, ((title, claim), e) in enumerate(zip(FINDINGS, me)):
        n = ne[i]
        label, eff, shown, fmt = e
        neff, nshown = (n[1], n[2]) if n else (None, None)
        reading = reading_of(eff, neff)
        if i == 8 and shown and not shown[5]:  # gold: claim direction is "lots of gold left"
            reading = "holds" if shown[0] >= 5 else "weaker" if shown[0] >= 2 else "reversed"
            if nshown and not nshown[5] and nshown[0] > 0:
                if shown[0] >= 5 and shown[0] / nshown[0] >= 1.33:
                    reading = "stronger"
        out.append({"n": i + 1, "title": title, "claim": claim, "measure": label, "fmt": fmt,
                    "match": shown, "naive": nshown, "reading": reading, "share": sh[i], "extra": ex[i]})
    return out


# ---------------------------------------------------------------- across matches

ACROSS_METRICS = [("place", "Average place"), ("lobby_win", "Share of lobbies won"),
                  ("tier_round_6", "Tier at round 6"), ("gold_left_round_10", "Gold unspent, round 10"),
                  ("hp_round_10", "Health after round 10"), ("decided_round", "Round the game is decided")]


def across_section(m, earlier, cache):
    if not earlier:
        return None
    paths = [Path(p).resolve() for p in earlier] + [m.path]
    out = Path(cache) / m.name / "across"
    run(["deep/across.py", *paths, "--out-dir", out])
    a = M.json(out / "across.json")
    lib = m.library
    matches = []
    for x in a["matches"]:
        series = {}
        for r in x["series"]:
            if r["metric"] in dict(ACROSS_METRICS):
                ci = r.get("ci95")
                series.setdefault(r["metric"], {})[r["scope"]] = [r["value"], *(ci or [None, None]), r.get("count"), None,
                                                                   1 if r.get("thin") else 0]
            # older across output has no lobby wins: a team's four seats share one first place, so 4 x seat win rate
            if r["metric"] == "win" and r["scope"] in ("red", "blue") and not any(q["metric"] == "lobby_win" for q in x["series"]):
                ci = r.get("ci95")
                series.setdefault("lobby_win", {})[r["scope"]] = [4 * r["value"], *((4 * ci[0], 4 * ci[1]) if ci else (None, None)),
                                                                  r.get("count"), None, 1 if r.get("thin") else 0]
        matches.append({"name": Path(x["match"]).name, "labels": f"{x['red_label']} vs {x['blue_label']}",
                        "games": x["games"], "gap": {g["scope"]: S(g["gap"]) for g in x.get("tribe_gap_within_team") or []}, "series": series})
    movers = {}
    for sc, d in a["movers_first_to_last"].items():
        movers[sc] = {k: [{"card": r["card"], "name": lib.get(r["card"], {}).get("name", r["card"]),
                           "from": r["from"], "to": r["to"], "change": r["change"], "ci": r.get("ci95"),
                           "thin": r.get("thin")} for r in v[:8]] for k, v in d.items()}
    return {"matches": matches, "metrics": ACROSS_METRICS, "same_rules": a.get("same_rules"), "movers": movers}


# ---------------------------------------------------------------- limits

def limits(m, cards):
    cov = m.deep["meta"].get("coverage", {})
    missing = [k for k, v in cov.items() if not v]
    ag = m.sec9["agree"].get("both_never") or {}
    blind = [card_tag(m, cid) for cid in ag]
    return {"missing_logs": missing, "events": bool(cov.get("events", m.deep["cards"].get("sales"))),
            "both_never": blind[:12], "both_never_n": len(blind),
            "thin_rows": cards["thin_rows"], "cards_n": len(cards["table"])}


# ---------------------------------------------------------------- art

def art(ids):
    out = {}
    thumbs = HERE / "thumbs"
    for cid in ids:
        f = thumbs / f"{cid}.webp"
        if not f.exists():
            src = next((REPO / "assets" / "units" / d / f"{cid}.jpg" for d in ART_DIRS
                        if (REPO / "assets" / "units" / d / f"{cid}.jpg").exists()), None)
            if src is None:
                continue
            try:
                thumbs.mkdir(exist_ok=True)
                mask = thumbs / ".mask.png"
                if not mask.exists():
                    subprocess.run(["convert", "-size", "560x1000", "xc:black", "-fill", "white", "-draw",
                                    "polygon 280,47 535,192 535,810 280,955 25,810 25,192", str(mask)], check=True)
                subprocess.run(["convert", str(src), str(mask), "-alpha", "off", "-compose", "CopyOpacity", "-composite",
                                "-crop", "512x910+24+46", "+repage", "-resize", "96x171", "-quality", "62", str(f)], check=True)
            except (OSError, subprocess.CalledProcessError):
                continue
        out[cid] = "data:image/webp;base64," + base64.b64encode(f.read_bytes()).decode()
    return out


# ---------------------------------------------------------------- main

def build(args):
    m = M(args.match, args.cache)
    naive = M(args.naive, args.cache) if args.naive else None
    status = status_of(m, args.status)
    names = team_names(m)
    cards = cards_section(m, names)
    data = {
        "match": m.name, "names": names, "labels": {c: m.summary[f"{c}_label"] for c in ("red", "blue")},
        "rules": m.summary.get("rules_hash", "")[:12], "git": m.summary.get("git_sha", "")[:8],
        "naive": None if not naive else {"name": naive.name, "labels": f"{naive.summary['red_label']} vs {naive.summary['blue_label']}",
                                         "games": naive.analysis["games"],
                                         "same_rules": naive.summary.get("rules_hash") == m.summary.get("rules_hash")},
        "head": headline(m, status, names),
        "places": placements(m, names),
        "conv": conversion(m, names),
        "curves": curves(m, names),
        "rounds": by_round(m, names),
        "upgrades": upgrades(m),
        "shape": game_shape(m, names),
        "seats": seats(m, names),
        "tribes": tribes_section(m, names),
        "cards": cards,
        "synergy": synergy_section(m),
        "beh": behaviours_section(m, names),
        "findings": findings_section(m, naive),
        "across": across_section(m, args.earlier, args.cache),
        "built": f"{datetime.datetime.now():%d %b %Y %H:%M}",
    }
    data["limits"] = limits(m, cards)
    data["art"] = art([r["id"] for r in cards["table"]])
    data["tribes_list"], data["bands"] = TRIBES, BANDS
    tpl = (HERE / "template.html").read_text()
    blob = json.dumps(data, separators=(",", ":"), allow_nan=False).replace("</", "<\\/")
    title = f"League {m.name}" if status != "test" else f"League test {m.name}"
    html = tpl.replace("{{TITLE}}", title).replace("{{DATA}}", blob)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)
    print(f"wrote {out} ({out.stat().st_size / 1024:.0f} KB)", file=sys.stderr)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("match")
    p.add_argument("--naive")
    p.add_argument("--earlier", nargs="*", default=[])
    p.add_argument("--out", required=True)
    p.add_argument("--cache", default=str(REPO / ".copies" / "league-page"))
    p.add_argument("--status", choices=["official", "practice", "test"])
    build(p.parse_args())


if __name__ == "__main__":
    main()
