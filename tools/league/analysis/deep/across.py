#!/usr/bin/env python3
"""What changed across matches, in the order given.

    python3 across.py MATCH [MATCH ...] [--out-dir DIR] [--rerun]

Reads each MATCH/deep/*.json, recomputing it with run.py when it is missing,
was made by different code (meta.json `code.source_sha256`), or --rerun is
given; then writes DIR/across.json and DIR/across.md,
where DIR defaults to the last match's deep folder."""
import argparse
import json
import math
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import write_json, write_text, code_stamp  # noqa: E402
import run as run_one  # noqa: E402

SERIES_ROUNDS = (4, 6, 8, 10, 12)
MOVERS = 15


def stale(deep, current):
    meta = deep / "meta.json"
    if not meta.exists():
        return True
    saved = json.loads(meta.read_text()).get("code") or {}
    return saved.get("source_sha256") != current["source_sha256"]


def load(match, rerun):
    deep = Path(match) / "deep"
    if rerun or stale(deep, code_stamp()):
        run_one.run(match)
    return {name: json.loads((deep / f"{name}.json").read_text())
            for name in ("meta", "tempo", "cards", "fights")}


def pick(rows, metric=None, **k):
    for r in rows:
        if (metric is None or r.get("metric") == metric) and all(r.get(a) == b for a, b in k.items()):
            return r
    return None


def stat_value(s):
    if s is None:
        return None
    for key in ("rate", "mean", "diff", "value"):
        if key in s:
            return s[key]
    return None


def series(data):
    """Flat rows: (match index, scope, metric, value, ci95, count, thin)."""
    out = []
    tempo, fights = data["tempo"], data["fights"]
    for scope in ("red", "blue", "both"):
        def add(metric, s):
            if s is not None:
                row = {"scope": scope, "metric": metric, "value": stat_value(s), "ci95": s.get("ci95"),
                       "count": s.get("count"), "thin": s.get("thin")}
                if "red_share" in s:
                    row["red_share"], row["one_team"] = s["red_share"], s["one_team"]
                out.append(row)
        for m in ("place", "win", "top4", "win_given_top4"):
            add(m, pick(tempo["conversion"], m, scope=scope, final_tribe="all"))
        for m in ("lobby_win", "lobby_win_expected_if_random_among_top4", "lobby_win_minus_expected"):
            add(m, pick(tempo.get("lobby", []), m, scope=scope))
        for R in SERIES_ROUNDS:
            for m in ("tier", "board_stats", "gold_left", "refreshes", "buys", "sells"):
                add(f"{m}_round_{R}", pick(tempo["by_round"], m, scope=scope, final_tribe="all", round=R))
            add(f"hp_round_{R}", pick(tempo["hp_by_round"], "hp_dead_as_zero", scope=scope, round=R))
        for t in range(1, 6):
            add(f"upgrade_from_{t}_round", pick(tempo["upgrade_prices"], "round", scope=scope, from_tier=t))
            add(f"upgrade_from_{t}_paid", pick(tempo["upgrade_prices"], "paid", scope=scope, from_tier=t))
        tribes = data["meta"]["tribes"] + ["(none)"]
        total = sum((pick(tempo["conversion"], "place", scope=scope, final_tribe=t) or {"count": 0})["count"]
                    for t in tribes)
        for t in tribes:
            p = pick(tempo["conversion"], "place", scope=scope, final_tribe=t)
            if p:
                out.append({"scope": scope, "metric": f"share_{t}", "value": p["count"] / total if total else None,
                            "ci95": None, "count": p["count"], "thin": False})
                add(f"place_{t}", p)
                add(f"win_given_top4_{t}", pick(tempo["conversion"], "win_given_top4", scope=scope, final_tribe=t))
    for m in ("decided_round", "rounds", "winner_was_bottom_half"):
        s = pick(fights["game_shape"], m, scope="all")
        if s:
            out.append({"scope": "both", "metric": m, "value": stat_value(s), "ci95": s.get("ci95"),
                        "count": s.get("count"), "thin": s.get("thin")})
    return out


def tribe_gaps(data):
    """Within-team worst minus best final tribe, with its interval (tempo.json)."""
    return data["tempo"].get("tribe_gap_within_team")


def change(a, b, key):
    """b minus a for two independent matches; interval from the two halves."""
    va, vb = a.get(key), b.get(key)
    if va is None or vb is None:
        return None
    half = None
    if a.get("ci95") and b.get("ci95"):
        ha, hb = (a["ci95"][1] - a["ci95"][0]) / 2, (b["ci95"][1] - b["ci95"][0]) / 2
        half = math.sqrt(ha * ha + hb * hb)
    return {"from": va, "to": vb, "change": vb - va, "ci95": [vb - va - half, vb - va + half] if half else None,
            "count_from": a.get("count"), "count_to": b.get("count"),
            "thin": bool(a.get("thin") or b.get("thin"))}


def movers(first, last):
    out = {}
    for scope in ("red", "blue", "both"):
        buys = []
        if "pick_rate" in first["cards"] and "pick_rate" in last["cards"]:
            index = {r["card"]: r for r in first["cards"]["pick_rate"]
                     if r["scope"] == scope and r["band"] == "all" and r["final_tribe"] == "all"}
            for r in last["cards"]["pick_rate"]:
                if r["scope"] == scope and r["band"] == "all" and r["final_tribe"] == "all" and r["card"] in index:
                    c = change(index[r["card"]], r, "rate")
                    if c and not c["thin"]:
                        buys.append({"card": r["card"], **c})
        buys.sort(key=lambda r: -abs(r["change"]))
        lifts = []
        lk = "fight_lift_vs_other_boards"
        lk = lk if lk in first["cards"] and lk in last["cards"] else "fight_lift"
        index = {r["card"]: r for r in first["cards"][lk] if r["scope"] == scope and r["band"] == "all"}
        for r in last["cards"][lk]:
            if r["scope"] == scope and r["band"] == "all" and r["card"] in index:
                c = change(index[r["card"]], r, "mean")
                if c and not c["thin"]:
                    lifts.append({"card": r["card"], **c})
        lifts.sort(key=lambda r: -abs(r["change"]))
        out[scope] = {"buy_rate": buys[:MOVERS], "fight_lift": lifts[:MOVERS]}
    return out


def analyse(datas):
    matches = []
    for i, d in enumerate(datas):
        m = d["meta"]
        matches.append({"index": i, "match": m["match"], "red_label": m["red_label"], "blue_label": m["blue_label"],
                        "games": m["games"], "rules_hash": m.get("rules_hash"),
                        "code": m.get("code"), "tribe_gap_within_team": tribe_gaps(d), "series": series(d)})
    same_rules = len({m["rules_hash"] for m in matches}) == 1
    return {"matches": matches, "same_rules": same_rules,
            "movers_first_to_last": movers(datas[0], datas[-1]) if len(datas) > 1 else None}


def markdown(data, names):
    ms = data["matches"]
    L = ["# Across matches", "",
         "Matches in the order given: " + ", ".join(f"{i}. {m['red_label']} vs {m['blue_label']} ({m['games']} games)"
                                                     for i, m in enumerate(ms)) + ".",
         "" if data["same_rules"] else "**The rules fingerprint differs between matches: a change can be the "
                                       "rules, not the bots.**", ""]
    head = "| Metric | Seats | " + " | ".join(str(i) for i in range(len(ms))) + " |"
    L += [head, "|---|---|" + "---|" * len(ms)]
    show = ("place", "win", "win_given_top4", "lobby_win", "lobby_win_minus_expected", "tier_round_6", "tier_round_10", "board_stats_round_10",
            "gold_left_round_10", "hp_round_10", "upgrade_from_1_round", "decided_round")
    for metric in show:
        for scope in ("red", "blue", "both"):
            cells = []
            for m in ms:
                r = next((s for s in m["series"] if s["scope"] == scope and s["metric"] == metric), None)
                v = r["value"] if r else None
                pct = metric in ("win", "win_given_top4", "lobby_win", "lobby_win_minus_expected")
                cells.append("—" if v is None else (f"{100*v:.1f}%" if pct else f"{v:.2f}")
                             + (" ⚠" if r and r["thin"] else ""))
            if scope == "both" and metric in ("place", "win", "win_given_top4", "lobby_win", "lobby_win_minus_expected"):
                continue      # pooled over both teams these are fixed by arithmetic
            if any(c != "—" for c in cells):
                L.append(f"| {metric} | {scope} | " + " | ".join(cells) + " |")
    L += ["", "**Tribe gap within each team** (worst minus best average place over final tribes with 30+ seats, "
          "with its interval; a gap that shrinks as a team's bot improves means its earlier version overstated it).",
          "", "| Match | Team | Best | Worst | Gap |", "|---|---|---|---|---|"]
    for i, m in enumerate(ms):
        for g in m["tribe_gap_within_team"] or []:
            gap = g.get("gap")
            if gap and gap.get("diff") is not None:
                ci = gap["ci95"]
                L.append(f"| {i} | {g['scope']} | {g['best']} | {g['worst']} | {gap['diff']:.2f}"
                         + (f" [{ci[0]:.2f}, {ci[1]:.2f}]" if ci else "") + " |")
            else:
                L.append(f"| {i} | {g['scope']} | — | — | — |")
    mv = data["movers_first_to_last"]
    if mv:
        for title, key, pct in (("Buy rates that moved most", "buy_rate", True),
                                ("Per-fight lifts that moved most", "fight_lift", False)):
            L += ["", f"**{title}, first to last match, all seats** (buy rates as counted by `cards.py`).", "",
                  "| Card | From | To | Change |", "|---|---|---|---|"]
            for r in mv["both"][key][:10]:
                f = (lambda x: f"{100*x:.1f}%") if pct else (lambda x: f"{x:+.2f}")
                ci = r["ci95"]
                L.append(f"| {names.get(r['card'], r['card'])} | {f(r['from'])} | {f(r['to'])} | "
                         f"{f(r['change'])}" + (f" [{f(ci[0])}, {f(ci[1])}]" if ci else "") + " |")
    return "\n".join(L)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("matches", nargs="+", type=Path)
    p.add_argument("--out-dir", type=Path)
    p.add_argument("--rerun", action="store_true")
    a = p.parse_args()
    datas = [load(m, a.rerun) for m in a.matches]
    data = analyse(datas)
    out = a.out_dir or a.matches[-1] / "deep"
    lib = json.loads((a.matches[-1] / "library.json").read_text())
    names = {c["id"]: c.get("name", c["id"]) for c in lib}
    write_json(out, "across", data)
    md = markdown(data, names)
    write_text(out, "across.md", md)
    print(md)


if __name__ == "__main__":
    main()
