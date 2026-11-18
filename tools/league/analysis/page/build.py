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


# ---------------------------------------------------------------- loading

def run(cmd):
    print("  running:", " ".join(str(c) for c in cmd), file=sys.stderr)
    subprocess.run([sys.executable, *map(str, cmd)], cwd=ANALYSIS, check=True,
                   stdout=subprocess.DEVNULL)


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
        if not ev.exists():
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
            if (d / f"{name}.json").exists():
                return self.json(d / f"{name}.json")
        run(["deep/run.py", self.path, "--out-dir", self.cache / "deep"])
        return self.json(self.cache / "deep" / f"{name}.json")

    def find_sec9(self, name):
        for d in (self.path, self.cache):
            if (d / f"{name}.json").exists():
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
    r, b = out["red"], out["blue"]
    hi = max(("red", "blue"), key=lambda c: out[c]["top4"][0])
    lo = "blue" if hi == "red" else "red"
    reading = (f"{names[hi]} makes the top four {pct(out[hi]['top4'][0])} of the time and turns "
               f"{pct(out[hi]['win_given_top4'][0])} of those into wins; {names[lo]} makes the top four "
               f"{pct(out[lo]['top4'][0])} of the time and wins {pct(out[lo]['win_given_top4'][0])} of those. "
               f"An even bot converts 25%.")
    return {"teams": out, "reading": reading}


def curves(m, names):
    t = m.deep["tempo"]
    cc = t["common_curves"]
    out = {}
    lines = []
    for c in ("red", "blue"):
        rs = sorted(rows(cc, scope=c), key=lambda r: -r["seats"])
        out[c] = [{"curve": r["curve"], "seats": r["seats"], "place": S(r["place"]), "win": S(r["win"]),
                   "top4": S(r["top4"]), "wgt4": S(r.get("win_given_top4"))} for r in rs]
        reach = [r for r in rs if not r["curve"].endswith("x")]
        never = [r for r in rs if r["curve"].endswith("x")]
        ws = lambda g: (sum(r["win"].get("hits", 0) for r in g), sum(r["seats"] for r in g))
        (wr, nr), (wn, nn) = ws(reach), ws(never)
        if nr and nn and nr + nn >= 60:
            lines.append(f"{names[c]} seats that reach tier 6 win {pct(wr / nr)} ({wr:.0f} of {nr}); "
                         f"those that never do win {wn:.0f} of {nn}")
    common = {c: out[c][0]["curve"] if out[c] else None for c in ("red", "blue")}
    reading = ("Most common plan (round reaching tiers 2-3-4-5-6, x = never): "
               + ", ".join(f"{names[c]} {common[c]}" for c in ("red", "blue") if common[c]) + ". ")
    if lines:
        reading += "; ".join(lines) + ". Only the eight commonest curves per team are listed."
    return {"teams": out, "reading": reading}


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
    # matrix: tribe vs opponent, band all
    matrix = {c: {t: {o: S(one(tv, scope=c, band="all", tribe=t, opponent=o)) for o in TRIBES} for t in TRIBES}
              for c in SCOPES}
    stage = {c: {t: [S(one(tv, scope=c, band=b, tribe=t, opponent="(other tribes)")) for b in BANDS] for t in TRIBES}
             for c in SCOPES}
    # readings
    rel = {t: S(tribe_rel(m, t)) for t in TRIBES}
    good = [(t, rel[t]) for t in TRIBES if rel[t] and not rel[t][5]]
    place_reading = "Too few boards per tribe to rank them."
    if len(good) >= 2:
        good.sort(key=lambda x: x[1][0])
        sg = lambda x: f"{'+' if x >= 0 else '−'}{abs(x):.2f}"
        place_reading = (f"Against their own team's average, {good[0][0]} boards place best ({sg(good[0][1][0])} places) and "
                         f"{good[-1][0]} worst ({sg(good[-1][1][0])}). Raw pooled placement would mix team strength into "
                         f"each tribe, so the chart shows each team separately.")
    shares = {c: max(TRIBES, key=lambda t: per[c][t]["share"][0]) for c in ("red", "blue")}
    share_reading = "; ".join(f"{names[c]} ends most often as {shares[c]} ({pct(per[c][shares[c]]['share'][0])} of its seats)"
                              for c in ("red", "blue")) + "."
    conv_ok = [(f"{names[c]}'s {t}", per[c][t]) for c in ("red", "blue") for t in TRIBES
               if per[c][t]["win_given_top4"] and not per[c][t]["win_given_top4"][5]]
    conv_reading = ""
    if len(conv_ok) >= 2:
        lo = min(conv_ok, key=lambda x: x[1]["win_given_top4"][0])
        hi = max(conv_ok, key=lambda x: x[1]["win_given_top4"][0])
        conv_reading = (f"{hi[0]} boards turn {pct(hi[1]['win_given_top4'][0])} of their top fours into wins; "
                        f"{lo[0]} boards only {pct(lo[1]['win_given_top4'][0])}. Even is 25%. Only boards with 30+ top fours compared.")
    # stage reading: biggest move between 7-9 and 13+ pooled
    moves = []
    for t in TRIBES:
        a, b = stage["both"][t][2], stage["both"][t][4]
        if a and b and not a[5] and not b[5]:
            moves.append((b[0] - a[0], t, a[0], b[0]))
    stage_reading = "Too few late fights to compare stages."
    if moves:
        moves.sort()
        dn, up = moves[0], moves[-1]
        parts = []
        if dn[0] < -0.05:
            parts.append(f"{dn[1]} boards fall from {pct(dn[2])} of fights won in rounds 7-9 to {pct(dn[3])} from round 13")
        if up[0] > 0.05:
            parts.append(f"{up[1]} boards rise from {pct(up[2])} to {pct(up[3])}")
        stage_reading = ("; ".join(parts) + "." if parts else "No tribe moves by more than five points from rounds 7-9 to 13+.")
        stage_reading += " Pooled lines mix the two bots' strength into each tribe; the team lines separate them."
    # matrix reading
    best = None
    for t in TRIBES:
        for o in TRIBES:
            s = matrix["both"][t][o]
            if t != o and s and not s[5] and (best is None or s[0] > best[0]):
                best = (s[0], t, o, s[3])
    matrix_reading = (f"The most one-sided matchup with enough fights: {best[1]} against {best[2]}, "
                      f"{pct(best[0])} of {best[3]} fights won." if best else "Too few fights for a matchup table.")
    # commit and mixed boards (section 9 tribes.json)
    t9 = m.sec9["tribes"].get("both", {})
    commit = {}
    for t in TRIBES:
        cm = (t9.get("commit") or {}).get(t) or {}
        commit[t] = {"committed": S(cm.get("committed")), "round": S(cm.get("round"))}
    mixed = {k: S(t9.get(k)) for k in ("mixed", "mixed_win", "mixed_placement", "pivot", "pivot_placement")}
    up = m.deep["fights"]["upsets"]
    upsets = {t: S(one(up, scope="both", stat_ratio="any", band="all", weaker_tribe=t)) for t in TRIBES + ["all"]}
    ratios = ["1-1.25x", "1.25-1.5x", "1.5-2x", "2-3x", "3x+"]
    ladder = {r: S(one(up, scope="both", stat_ratio=r, band="all", weaker_tribe="all")) for r in ratios}
    ok_t = [(t, upsets[t]) for t in TRIBES if upsets[t] and not upsets[t][5]]
    upset_reading = "Too few fights to compare tribes as underdogs."
    if len(ok_t) >= 2 and upsets["all"]:
        ok_t.sort(key=lambda x: -x[1][0])
        upset_reading = (f"When a board has fewer total stats than its opponent, {ok_t[0][0]} boards still win "
                         f"{pct(ok_t[0][1][0])} of those fights and {ok_t[-1][0]} boards {pct(ok_t[-1][1][0])} "
                         f"(all tribes: {pct(upsets['all'][0])}). A tribe high here wins through effects that don't show as stats.")
    return {"per": per, "rel": rel, "matrix": matrix, "upsets": upsets, "ladder": ladder, "ratios": ratios,
            "upset_reading": upset_reading, "stage": stage, "commit": commit, "mixed": mixed,
            "place_reading": place_reading, "share_reading": share_reading, "conv_reading": conv_reading,
            "stage_reading": stage_reading, "matrix_reading": matrix_reading}


def cards_section(m, names):
    dc = m.deep["cards"]
    c9 = m.sec9["cards"]
    fl, bp, ten, rs, pr = dc["fight_lift"], dc["board_predicts"], dc["tenure"], dc["resales"], dc["pick_rate"]
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
                  for k in ("fights_on_board", "kept_to_end", "left_after_one_fight", "tripled")}
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
                **tn,
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
    # standouts (pooled, non-thin)
    def lift_of(r):
        return r["s"]["both"]["lift"]
    lifted = [r for r in table if lift_of(r) and not lift_of(r)[5]]
    sig = [r for r in lifted if lift_of(r)[1] is not None and (lift_of(r)[1] > 0 or lift_of(r)[2] < 0)]
    pool = sig if len(sig) >= 6 else lifted
    top = sorted([r for r in pool if lift_of(r)[0] > 0], key=lambda r: -lift_of(r)[0])[:6]
    bottom = sorted([r for r in pool if lift_of(r)[0] < 0], key=lambda r: lift_of(r)[0])[:6]
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
        rr = r["s"]["both"]["resale"]
        if rr and rr[0] >= 30:
            flips.append((rr[2] / rr[0], r["id"]))
    flips.sort(reverse=True)
    stay = [r for r in table if r["s"]["both"]["kept_to_end"] and not r["s"]["both"]["kept_to_end"][5]]
    keep = sorted(stay, key=lambda r: -r["s"]["both"]["kept_to_end"][0])[:6]
    drop = sorted([r for r in table if r["s"]["both"]["left_after_one_fight"] and not r["s"]["both"]["left_after_one_fight"][5]],
                  key=lambda r: -r["s"]["both"]["left_after_one_fight"][0])[:6]
    nm = lambda rs_: ", ".join(card_tag(m, r["id"]) for r in rs_[:3])
    readings = {
        "top": (f"Boards holding {nm(top)} win the most fights over their own team, tribe and round."
                if top else "No card has enough fights to call."),
        "bottom": (f"Boards holding {nm(bottom)} win the fewest. Cheap cards still on a late board often mark an "
                   "undeveloped board, so compare cards of the same tier." if bottom else ""),
        "never": (f"{sum(1 for x in never if x['both_teams'])} cards are bought in under 2% of the shops that offer them "
                  f"by both teams; {sum(1 for x in never if not x['both_teams'])} more by one team only." if never else
                  "Every card offered in 30+ shops is bought at least 2% of the time."),
        "flips": (f"{card_tag(m, flips[0][1])} is sold in the same turn a copy was bought {pct(flips[0][0])} of the times it is bought: "
                  "triple fodder or a stopgap." if flips else ""),
        "tenure": (f"{card_tag(m, keep[0]['id'])} stays to the end {pct(keep[0]['s']['both']['kept_to_end'][0])} of the time; "
                   f"{card_tag(m, drop[0]['id'])} leaves after one fight {pct(drop[0]['s']['both']['left_after_one_fight'][0])} of the time."
                   if keep and drop else ""),
    }
    thin_rows = sum(1 for r in table if not r["s"]["both"]["lift"] or r["s"]["both"]["lift"][5])
    return {"table": table, "matrix": matrix, "top": [r["id"] for r in top], "bottom": [r["id"] for r in bottom],
            "never": never, "flips": [[round(f, 4), cid] for f, cid in flips[:6]],
            "keep": [r["id"] for r in keep], "drop": [r["id"] for r in drop],
            "readings": readings, "thin_rows": thin_rows}


def synergy_section(m):
    sy = m.deep["synergy"]
    pairs = []
    for p in sy["pairs"]:
        it = p["interaction"]
        pairs.append({"a": p["a"], "b": p["b"], "together": p["together"],
                      "i": [round(it["value"], 4), *(round(x, 4) for x in (it.get("ci95") or [None, None])),
                            p["together"], it.get("pairs"), 1 if p.get("thin") or it.get("thin") else 0],
                      "best": S(p.get("excess_over_best_single"))})
    pairs.sort(key=lambda p: -p["i"][0])
    good = [p for p in pairs if not p["i"][5]]
    clear = [p for p in good if p["i"][1] is not None and (p["i"][1] > 0 or p["i"][2] < 0)]
    n = len(pairs)
    reading = (f"{len(clear)} of {n} pairs tested clear a 95% interval; about {round(n * 0.05)} would by chance alone. "
               f"Treat each as a lead to test with a constructed fight.") if n else "No pair had enough fights together."
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
        out["sergeants"][c] = {k: {kk: S(((v.get("growth_per_fight_round") or {}).get(kk) or {}).get("total")
                                     or ((v.get("growth_per_fight_round") or {}).get(kk) or {}).get("attack"))
                                   for kk in (v.get("growth_per_fight_round") or {})}
                               for k, v in sg.items()}
    b = m.sec9["behaviours"].get("both", {})
    out["compost_by_round"] = {r: S(v) for r, v in sorted((b.get("briar_compost_by_round") or {}).items(), key=lambda x: int(x[0]))}
    out["win_by_compost"] = binned(b.get("briar_win_by_compost") or {}, [(0, 0), (1, 2), (3, 5), (6, 9), (10, 14), (15, 19), (20, 10 ** 6)])
    out["gleaners"] = {r: S((v or {}).get("fight_win")) for r, v in (b.get("locust_gleaners") or {}).items()}
    out["badger_out"] = {r: S(v) for r, v in sorted((b.get("badger_win_by_outnumbered") or {}).items(), key=lambda x: int(x[0]))}
    out["colonel"] = {r: S(v) for r, v in sorted((b.get("colonel_win_by_hand_units") or {}).items(), key=lambda x: int(x[0]))}
    out["colonel_hand"] = S(b.get("colonel_hand_units"))
    e = out["eats"]["both"]
    out["reading"] = (f"Eaters ate {e['per_game'][0]:.1f} sold units per game, {pct(e['fed'][0])} of all sales; "
                      f"each meal added {e['stats'][0]:.1f} stats on average." if e["per_game"] and e["fed"] and e["stats"] else
                      "No eats were logged.")
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
    fl = m.deep["cards"]["fight_lift"]
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
    out = []
    for i, ((title, claim), e) in enumerate(zip(FINDINGS, me)):
        n = ne[i]
        label, eff, shown, fmt = e
        neff, nshown = (n[1], n[2]) if n else (None, None)
        reading = reading_of(eff, neff)
        if i == 8 and shown and not shown[5]:  # gold: claim direction is "lots of gold left"
            reading = "holds" if shown[0] >= 5 else "weaker" if shown[0] >= 2 else "reversed"
            if nshown and not nshown[5] and nshown[0] > 0:
                ratio = shown[0] / nshown[0]
                if shown[0] >= 5 and ratio >= 1.33:
                    reading = "stronger"
        out.append({"n": i + 1, "title": title, "claim": claim, "measure": label, "fmt": fmt,
                    "match": shown, "naive": nshown, "reading": reading})
    return out


# ---------------------------------------------------------------- across matches

ACROSS_METRICS = [("place", "Average place"), ("win_given_top4", "Wins per top-four finish"),
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
        matches.append({"name": Path(x["match"]).name, "labels": f"{x['red_label']} vs {x['blue_label']}",
                        "games": x["games"], "spread": x.get("tribe_spread"), "series": series})
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
    return {"missing_logs": missing, "both_never": blind[:12], "both_never_n": len(blind),
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
