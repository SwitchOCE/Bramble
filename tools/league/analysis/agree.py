#!/usr/bin/env python3
"""Referee-only comparison of the teams' independent choices."""
from cards import card_stats, rate_count, table
from match_data import BANDS, Match, TEAMS, parser, publish, show
from tribes import tribe_stats


def agreement(match):
    cards = card_stats(match, TEAMS)
    tribes = tribe_stats(match)
    verdicts = {"both_always_in_band": {stage: {} for stage in BANDS}}
    gaps = []
    for card in match.units:
        r, b = (cards[t][card] for t in TEAMS)
        rates = {"red": r["buy"], "blue": b["buy"]}
        for key, condition in (("both_never", r["never_bought"] and b["never_bought"]),
                               ("both_always", r["always_bought"] and b["always_bought"]),
                               ("both_always_among_buying", r["always_among_buying_shops"] and b["always_among_buying_shops"])):
            bucket = verdicts.setdefault(key, {})
            if condition:
                bucket[card] = rates
                if key.startswith("both_always"):
                    metric = "by_final_tribe" if key == "both_always" else "among_buying_shops"
                    bucket[card] = {t: cards[t][card][metric] for t in TEAMS}
        for stage in BANDS:
            if r["always_bought_in_band"][stage] and b["always_bought_in_band"][stage]:
                verdicts["both_always_in_band"][stage][card] = {
                    team: {"buy": d["by_band"][stage], **d["band_evidence"][stage]}
                    for team, d in (("red", r), ("blue", b))}
        if all(stat["count"] for stat in rates.values()):
            gaps.append({"card": card, **rates, "red_minus_blue": r["buy"]["rate"] - b["buy"]["rate"]})
    gaps.sort(key=lambda x: (-abs(x["red_minus_blue"]), x["card"]))
    by_tribe = {}
    for name in tribes["red"]["final"]:
        by_tribe[name] = {team: {"share": tribes[team]["final"][name]["share"],
                                 "commit": tribes[team].get("commit", {}).get(name, {})} for team in TEAMS}
        by_tribe[name]["red_minus_blue"] = by_tribe[name]["red"]["share"]["rate"] - by_tribe[name]["blue"]["share"]["rate"]
    return {**verdicts, "buy_rate_gaps": gaps, "tribes": by_tribe}


def main():
    args = parser(__doc__).parse_args()
    match = Match(args.match)
    d = agreement(match)
    lines = ["# Team agreement", "", "## All-round verdicts"]
    rows = [[card, rate_count(v["red"]), rate_count(v["blue"])] for card, v in sorted(d["both_never"].items())]
    if rows:
        lines.extend(["", "### Both never bought"])
        table(lines, ["Card", "Red", "Blue"], rows)
    else:
        lines.extend(["", "Both never bought — none."])
    for key, label in (("both_always", "Both always bought"), ("both_always_among_buying", "Both always among buying shops")):
        lines.extend(["", "### " + label])
        rows = [[card, team, *(rate_count(v[team][t]) for t in match.tribes)]
                for card, v in sorted(d[key].items()) for team in TEAMS]
        if rows:
            table(lines, ["Card", "Team", *match.tribes], rows)
        else:
            lines.extend(["", "None."])
    for stage in BANDS:
        lines.extend(["", f"## Rounds {stage}"])
        rows = []
        for card, values in sorted(d["both_always_in_band"][stage].items()):
            for team, v in values.items():
                rows.append([card, "Both always", team, rate_count(v["buy"]),
                             *(rate_count(v["by_final_tribe"][t]) for t in match.tribes),
                             ", ".join(v["excluded_tribes"]) or "—"])
        if rows:
            table(lines, ["Card", "Verdict", "Team", "Band rate", *match.tribes, "Below sample minimum"], rows)
        else:
            lines.extend(["", "No shared verdicts."])
    lines.extend(["", "## Buy-rate gaps and tribe shares",
                  "", "| Largest absolute gap | Red buys | Blue buys | Red − blue |", "|---|---|---|---|"])
    for row in d["buy_rate_gaps"][:5]:
        lines.append(f"| {row['card']} | {show(row['red'])} | {show(row['blue'])} | {row['red_minus_blue']:+.1%} |")
    lines += ["", "| Final tribe | Red share | Blue share |", "|---|---|---|"]
    for name, row in d["tribes"].items():
        lines.append(f"| {name} | {show(row['red']['share'])} | {show(row['blue']['share'])} |")
    publish(args.out_dir or args.match, "agree", d, "\n".join(lines))


if __name__ == "__main__":
    main()

