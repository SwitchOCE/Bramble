"""Kill and summon totals from the combat events summarized in games.jsonl."""
import csv
from collections import Counter
import sys

from match_data import Match, NONE, atomic_file, parser


ORIGINS = ("start", "summon", "reserve")


def write_tsv(directory, name, header, rows):
    with atomic_file(directory / f"{name}.tsv") as output:
        writer = csv.writer(output, delimiter="\t", lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def summarize(match, directory):
    fights_present = Counter()
    card_kills = Counter()
    summons = Counter()
    origin_kills = Counter()
    source_kills = Counter()
    for game in match.games():
        for round_data in game["fights"]:
            for fight in round_data["fights"]:
                if "kills" not in fight or "summons" not in fight:
                    return False
                present = set()
                for side in fight["kills"]:
                    for unit in side:
                        if "origin" not in unit:
                            return False
                        key = unit["card"], unit["golden"]
                        present.add(key)
                        kills = unit["kills"]
                        card_kills[key] += kills
                        origin_kills[unit["origin"]] += kills
                        if unit["origin"] == "summon":
                            source_kills[unit["source"] or NONE] += kills
                fights_present.update(present)
                for side in fight["summons"]:
                    for unit in side:
                        summons[unit["source"] or NONE, unit["card"]] += unit["count"]

    directory.mkdir(parents=True, exist_ok=True)
    by_tier = sorted((match.library[card]["tier"], card, golden)
                     for card, golden in fights_present)
    write_tsv(directory, "kills_by_card",
              ("tier", "card", "golden", "fights_present", "total_kills", "kills_per_fight"),
              ((tier, card, str(golden).lower(), fights_present[card, golden],
                card_kills[card, golden], card_kills[card, golden] / fights_present[card, golden])
               for tier, card, golden in by_tier))
    games = match.summary["games"]
    write_tsv(directory, "summons_by_source",
              ("source", "card", "total_summoned", "games", "summoned_per_game"),
              ((source, card, count, games, count / games)
               for (source, card), count in sorted(summons.items())))
    total_kills = sum(origin_kills.values())
    shares = [("overall", origin, None, origin_kills[origin]) for origin in ORIGINS]
    shares.extend(("source", "summon", source, count)
                  for source, count in sorted(source_kills.items()))
    write_tsv(directory, "kill_shares",
              ("scope", "origin", "source", "kills", "all_kills", "share"),
              ((*row, total_kills, row[-1] / total_kills if total_kills else None) for row in shares))
    return True


def main():
    args = parser(__doc__).parse_args()
    if not summarize(Match(args.match), args.out_dir or args.match):
        print("Combat TSVs require origin-aware kill and summon logs. Skipping.", file=sys.stderr)


if __name__ == "__main__":
    main()
