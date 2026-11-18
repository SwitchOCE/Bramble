#!/usr/bin/env python3
"""Referee-only comparison of the teams' independent choices."""
from cards import card_stats
from match_data import Match, TEAMS, parser, publish, show
from tribes import tribe_stats


def agreement(match):
    cards = card_stats(match, TEAMS)
    tribes = tribe_stats(match)
    verdicts = {}
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
    d = agreement(Match(args.match))
    lines = ["# Team agreement", "", "Both never bought: " + (", ".join(d["both_never"]) or "none") + ".",
             "Both always bought: " + (", ".join(d["both_always"]) or "none") + ".",
             "", "| Largest absolute gap | Red buys | Blue buys | Red − blue |", "|---|---|---|---|"]
    for row in d["buy_rate_gaps"][:5]:
        lines.append(f"| {row['card']} | {show(row['red'])} | {show(row['blue'])} | {row['red_minus_blue']:+.1%} |")
    lines += ["", "| Final tribe | Red share | Blue share |", "|---|---|---|"]
    for name, row in d["tribes"].items():
        lines.append(f"| {name} | {show(row['red']['share'])} | {show(row['blue']['share'])} |")
    publish(args.out_dir or args.match, "agree", d, "\n".join(lines))


if __name__ == "__main__":
    main()

