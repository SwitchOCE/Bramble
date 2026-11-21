#!/usr/bin/env python3
"""Placement, commitment, fight matchups and economy by tribe."""
from collections import Counter, defaultdict

from cards import values
from match_data import Match, Measures, NONE, SCOPES, Stat, band, nest, parser, publish, show, sides


def final_tribes(match):
    m = Measures()
    for g in match.games():
        pair = g["game"] // 2
        for s in g["seats"]:
            tribe = s["main_tribe"] or NONE
            for scope in (s["colour"], "both"):
                for t in (*match.tribes, NONE):
                    m.add((scope, t, "share"), pair, t == tribe, rate=True)
                key = (scope, tribe)
                m.add(key + ("placement",), pair, s["place"])
                m.add(key + ("win",), pair, s["place"] == 1, rate=True)
                m.add(key + ("top4",), pair, s["place"] <= 4, rate=True)
    result = m.result()
    for tribes in result.values():
        for data in tribes.values():
            for metric in ("placement", "win", "top4"):
                data.setdefault(metric, Stat().result(metric != "placement"))
    return result


def report_use(match):
    m = Measures()
    strategies = defaultdict(lambda: defaultdict(Counter))
    for report, shop in match.report_shops(include_discover=True):
        colour, _ = match.seat(report)
        pair = report["game"]//2
        strategies[colour][pair][report["strategy"]] += 1
        if report["kind"] != "shop":
            continue
        m.add((colour, "unambiguous_shop_match"), pair, shop is not None, rate=True)
        if shop is None:
            continue
        scores = values(report)
        if scores:
            top = max(scores.values())
            bought = shop["bought"]
            hit = any(scores.get(b["card"]) == top for b in bought)
            m.add((colour, "bought_highest_reported"), pair, hit, rate=True)
            if bought:
                m.add((colour, "bought_highest_when_buying"), pair, hit, rate=True)
    for colour, pairs in strategies.items():
        names = {name for counts in pairs.values() for name in counts}
        for pair, counts in sorted(pairs.items()):
            for name in sorted(names):
                m.add((colour, "strategy_report_share", name), pair, counts[name], rate=True, n=sum(counts.values()))
    return m.result()


def median(hist):
    n = sum(hist.values())
    positions = ((n-1)//2, n//2)
    index = result = 0
    for value, count in sorted(hist.items()):
        result += value * sum(index <= p < index + count for p in positions)
        index += count
    return {"median": result / 2, "count": n}


def tribe_stats(match):
    final = final_tribes(match)
    m = Measures()
    hist = defaultdict(Counter)
    for game in match.games():
        pair = game["game"]//2
        current = {}
        for seat in game["seats"]:
            tribe = seat["main_tribe"] or NONE
            place = seat["place"]
            pivot = bool(seat["pivots"])
            commit = seat["commit_round"]
            rounds = {r["round"]: r for r in seat["rounds"]}
            last = seat["rounds"][-1]
            mixed = tribe != NONE and len(last["board"]) - last["tribes"][tribe] >= 2
            for scope in (seat["colour"], "both"):
                for p in range(1, 9):
                    m.add((scope, "distribution", str(p)), pair, p == place, rate=True)
                for name, hit in (("top4", place <= 4), ("win", place == 1),
                                  ("mixed", mixed), ("pivot", pivot)):
                    m.add((scope, name), pair, hit, rate=True)
                if mixed:
                    m.add((scope, "mixed_placement"), pair, place)
                    m.add((scope, "mixed_win"), pair, place == 1, rate=True)
                if pivot:
                    m.add((scope, "pivot_placement"), pair, place)
                key = (scope, "commit", tribe)
                m.add(key + ("committed",), pair, commit is not None, rate=True)
                if commit is not None:
                    m.add(key + ("round",), pair, commit)
                    if commit-1 in rounds:
                        for event in ("triple", "golden_gained", "slot_buff"):
                            m.add(key + ("previous_" + event,), pair, rounds[commit-1][event], rate=True)
            for r in rounds.values():
                t = match.main(r)
                current[seat["seat"], r["round"]] = t
                for scope in (seat["colour"], "both"):
                    for group in (("rounds", r["round"]), ("tribe_rounds", t, r["round"])):
                        key = (scope,) + group
                        hist[key + ("board_stats",)][r["board_attack"] + r["board_health"]] += 1
                        hist[key + ("tier",)][r["tier"]] += 1
                        for field in ("gold_left", "gold_from_cards"):
                            m.add(key + (field,), pair, r[field])
        for seat, r, opp, fight, _ in sides(game):
            pid, rd = seat["seat"], r["round"]
            t = current[pid, rd]
            won = fight["winner"] == pid
            for scope in (seat["colour"], "both"):
                m.add((scope, "fight_win", t, band(rd)), pair, won, rate=True)
                if opp is not None:
                    enemy = fight["b"] if pid == fight["a"] else fight["a"]
                    other = current[enemy, rd]
                    if other != t and NONE not in (other, t):
                        m.add((scope, "fight_win_other_tribes", t, band(rd)), pair, won, rate=True)
                    if rd >= 7:
                        m.add((scope, "head_to_head", t, other), pair, won, rate=True)
    out = m.result()
    for key, h in hist.items():
        nest(out, key, median(h))
    reports = report_use(match)
    for scope in SCOPES:
        out[scope]["final"] = final[scope]
        if scope in reports:
            out[scope]["reports"] = reports[scope]
    return out


def main():
    args = parser(__doc__).parse_args()
    result = tribe_stats(Match(args.match))
    lines = ["# Final main tribes", "", "| Tribe | Share | Placement | Top four | Win |",
             "|---|---|---|---|---|"]
    for t, d in result["both"]["final"].items():
        lines.append("| " + " | ".join([t, *(show(d[k]) for k in ("share", "placement", "top4", "win"))]) + " |")
    lines += ["", "Intervals are 95%. Fight stages use the board at the fight. "
              "Commitment, mixed boards, team splits and economy are in `tribes.json`."]
    publish(args.out_dir or args.match, "tribes", result, "\n".join(lines))


if __name__ == "__main__":
    main()

