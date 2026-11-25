"""One row per card: every card-power measure side by side, and why a card has no fight data.

Definitions: docs/workstreams/card-power/definitions.md. Reads a ghost match and the tables that
`card_report.sh` wrote for it (bought_passed.csv always; text_cards.csv and stat_growth.csv when
the match kept its records). Every mark is "worth a look": where to look, never "too strong".

usage: card_summary.py <match dir> <report dir> [--left-out <left_out.csv>] [--out <cards.csv>]
"""
import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

from bought_passed import read_lines

STAGES = ("1-4", "5-8", "9-12", "13+")
PICK_LINE = 0.9       # worth a look: a bot buys the card on nine offers in ten or more
PICK_OFFERS = 100     # offers a bot needs before its pick rate is read
PLAYED_SHARE = 0.05   # a bot plays a tribe when it ends on it in at least this share of its games
REFUSED = 0.01        # bought on under one offer in a hundred


def stage(round_no):
    return STAGES[min((round_no - 1) // 4, 3)]


def table(path):
    if not path.exists():
        return []
    with open(path, newline="") as stream:
        return list(csv.DictReader(stream))


def number(text):
    return float(text) if text not in ("", None) else None


def boards(match):
    """held[bot][stage][card] = live boards holding the card; seen[bot][stage] = live boards;
    ends[bot][tribe] = share of the bot's games that end on the tribe; colour[bot] = its seat colour."""
    held = defaultdict(lambda: defaultdict(Counter))
    seen = defaultdict(Counter)
    ends = defaultdict(Counter)
    games, colour = Counter(), {}
    for game in read_lines(match / "games.jsonl"):
        seat = game["seats"][0]
        bot = seat.get("label") or seat["bot"]
        games[bot] += 1
        colour[bot] = seat["colour"]
        ends[bot][seat.get("main_tribe") or "none"] += 1
        for row in seat["rounds"]:
            name = stage(row["round"])
            seen[bot][name] += 1
            for card in {unit["card"] for unit in row["board"] if unit}:
                held[bot][name][card] += 1
    shares = {bot: {tribe: n / games[bot] for tribe, n in tribes.items()} for bot, tribes in ends.items()}
    return held, seen, shares, colour


def no_data_reason(tribes, picks, plays):
    """Why no bot put the card on enough boards to test. Only "offered and refused" is a sign."""
    if all(offers < PICK_OFFERS for offers, _ in picks.values()):
        return "seldom offered"
    playing = [bot for bot, (offers, _) in picks.items() if offers >= PICK_OFFERS
               and (not tribes or any(plays.get(bot, {}).get(t, 0) >= PLAYED_SHARE for t in tribes))]
    if not playing:
        return "tribe not played"
    if all(picks[bot][1] < REFUSED for bot in playing):
        return "offered and refused"
    return "bought, held too briefly"


def summary(match, report, left_out=None):
    match, report = Path(match), Path(report)
    library = {c["id"]: c for c in json.loads((match / "library.json").read_text())
               if not c["spell"] and not c["token"]}
    held, seen, plays, colour = boards(match)
    bots = sorted(seen)
    bought = [r for r in table(report / "bought_passed.csv") if r["bot"] != "all"]
    text = {(r["card"], r["stage"]): r for r in table(report / "text_cards.csv")}
    growth = {(r["card"], r["stage"]): r for r in table(report / "stat_growth.csv")}
    left = defaultdict(dict)
    for r in table(Path(left_out)) if left_out else []:
        left[r["card"]][r["colour"]] = r
    fights = bool(text)
    out = []
    for card, info in sorted(library.items(), key=lambda kv: (kv[1]["tier"], kv[0])):
        row = {"card": card, "name": info["name"], "tier": info["tier"],
               "tribe": "/".join(info["tribes"]) or "none"}
        marks = []
        picks = {}
        for bot in bots:
            mine = next((r for r in bought if r["card"] == card and r["bot"] == bot), None)
            offers = int(mine["offered"]) if mine else 0
            rate = number(mine["pick_rate"]) if mine else None
            picks[bot] = (offers, rate or 0.0)
            row[f"offers {bot}"] = offers
            row[f"pick {bot}"] = "" if rate is None else rate
            if offers >= PICK_OFFERS and rate is not None and rate >= PICK_LINE:
                marks.append(f"pick rate ({bot})")
            for name in STAGES:
                boards_seen = seen[bot][name]
                row[f"held {bot} {name}"] = round(held[bot][name][card] / boards_seen, 3) if boards_seen else ""
            difference, typical = (number(mine["difference"]), number(mine["typical"])) if mine else (None, None)
            row[f"bought-passed {bot}"] = "" if difference is None or typical is None else round(difference - typical, 3)
            if mine and mine["flag"]:
                marks.append(f"bought against passed ({bot}: {mine['flag'].split(': ')[1]})")
        tested = False
        for name in STAGES:
            cell = text.get((card, name))
            ok = bool(cell) and cell["status"] == "ok"
            tested = tested or ok
            row[f"text {name}"] = cell["text_value"] if ok else ""
            row[f"text spreads {name}"] = cell["spreads"] if ok else ""
            if ok and cell["pointer"]:
                marks.append(f"text ({name})")
        for name in STAGES:
            cell = growth.get((card, name))
            ok = bool(cell) and cell["status"] == "ok"
            row[f"growth {name}"] = cell["stats_per_turn"] if ok else ""
            if ok and cell["look"]:
                marks.append(f"growth ({name})")
        for bot in bots:
            cell = left.get(card, {}).get(colour[bot])
            row[f"left out {bot}"] = round(float(cell["diff_mean"]), 2) if cell else ""
        row["fight data"] = ("yes" if tested else no_data_reason(info["tribes"], picks, plays)) if fights else "no records"
        row["worth a look"] = "; ".join(marks)
        out.append(row)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("match")
    parser.add_argument("report")
    parser.add_argument("--left-out")
    parser.add_argument("--out")
    args = parser.parse_args()
    rows = summary(args.match, args.report, args.left_out)
    path = Path(args.out) if args.out else Path(args.report) / "cards.csv"
    with open(path, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    marked = [r for r in rows if r["worth a look"]]
    reasons = Counter(r["fight data"] for r in rows)
    print(f"{len(rows)} cards, {len(marked)} worth a look -> {path}")
    print("fight data: " + ", ".join(f"{reason} {n}" for reason, n in reasons.most_common()))
    for r in marked:
        print(f"  tier {r['tier']} {r['name']}: {r['worth a look']}")


if __name__ == "__main__":
    main()
