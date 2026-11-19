#!/usr/bin/env python3
"""Publish the score, own card results and decisions, and pooled tribe share/place."""
import argparse
import gzip
import json
import os
from pathlib import Path
from tempfile import TemporaryDirectory

from match_data import Match, TEAMS, publish


def split(match, colour, out):
    from cards import card_stats
    from tribes import final_tribes

    out = out.resolve()
    if out.exists() and (not out.is_dir() or any(out.iterdir())):
        raise ValueError("use a new or empty team output directory")
    out.parent.mkdir(parents=True, exist_ok=True)
    with TemporaryDirectory(dir=out.parent) as temporary:
        stage = Path(temporary) / "team"
        stage.mkdir(mode=0o700)
        count = 0
        with gzip.open(stage / "decisions.jsonl.gz", "wb", compresslevel=1) as decisions:
            for line in match.lines("decisions"):
                row = json.loads(line)
                if match.seat(row)[0] == colour:
                    decisions.write(line)
                    count += 1
        pooled = final_tribes(match)["both"]
        score = match.score()
        data = {"team": colour, "score": score, "decision_lines": count,
                "cards": card_stats(match, (colour,))[colour],
                "pooled_tribes": {t: {k: v[k] for k in ("share", "placement")}
                                 for t, v in pooled.items()}}
        md = (f"# {colour.title()} team match report\n\n"
              f"{score['games']} games in {score['seed_pairs']} seed pairs. "
              f"Red minus blue placement {score['gap_red_minus_blue']:+.3f} "
              f"± {score['gap_ci95']:.3f} (95%).\n\n"
              f"{count} team decision lines in `decisions.jsonl.gz`. "
              "See `team.json` for your card statistics and pooled tribe share and placement.")
        publish(stage, "team", data, md)
        os.replace(stage, out)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("match", type=Path)
    p.add_argument("colour", choices=TEAMS)
    p.add_argument("out", type=Path)
    args = p.parse_args()
    split(Match(args.match), args.colour, args.out)

