#!/usr/bin/env python3
"""Play one `league ghost-match --without <card>` per card, paired with a baseline match.

    python3 card_without_run.py BASELINE OUT_ROOT --field STORE --seeds FILE
        [--league BIN] [--threads 4] [--timeout SECONDS] [--repo-root DIR] CARD [CARD ...]

Each card's match goes to OUT_ROOT/<card>, with the baseline's bots, labels, games, clock,
content and secret, `--no-records` and `--no-decisions`, one after another. `--seeds` must be
the file the baseline read (its SHA-256 is checked) and `--field` the store it drew runs from
(each finished match's lobbies are checked against the baseline's). A card whose folder
already holds a finished match that pairs with the baseline is skipped. Stops at the first
failure or time-out. Then: `python3 card_without.py BASELINE OUT_ROOT/*`.
"""
import argparse
import hashlib
import subprocess
import sys
from pathlib import Path

from card_without import Refused, compare, live_games, secret
from match_data import Match

DEFAULT_LEAGUE = Path(__file__).resolve().parents[1] / "target/release/league"


def done(base, base_games, folder, card):
    if not (folder / "summary.json").is_file():
        return False
    other = Match(folder)
    if other.summary.get("without") != [card]:
        raise Refused(f"{folder}: a finished match without {other.summary.get('without')}")
    compare(base, base_games, other)
    return True


def command(a, base, card, out):
    s = base.summary
    cmd = [str(a.league), "ghost-match", "--red", s["red"], "--blue", s["blue"],
           "--red-label", s["red_label"], "--blue-label", s["blue_label"],
           "--field", str(a.field), "--games", str(s["games"]), "--seeds", str(a.seeds),
           "--secret", secret(base), "--clock-ms", str(s["clock_ms"]),
           "--content", s["content"], "--threads", str(a.threads), "--out", str(out),
           "--without", card, "--no-records", "--no-decisions"]
    if a.repo_root:
        cmd += ["--repo-root", str(a.repo_root)]
    return cmd


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("baseline")
    p.add_argument("out_root")
    p.add_argument("cards", nargs="+")
    p.add_argument("--field", required=True)
    p.add_argument("--seeds", required=True)
    p.add_argument("--league", default=DEFAULT_LEAGUE, type=Path)
    p.add_argument("--threads", type=int, default=4)
    p.add_argument("--timeout", type=float, default=1200, help="seconds per match")
    p.add_argument("--repo-root")
    a = p.parse_args(argv)
    try:
        base = Match(a.baseline)
        if "without" in base.summary or base.summary.get("mode") != "async":
            raise Refused(f"{a.baseline}: not a ghost-match baseline with every card")
        seeds_sha = hashlib.sha256(Path(a.seeds).read_bytes()).hexdigest()
        if seeds_sha != base.summary["seeds_sha256"]:
            raise Refused(f"{a.seeds}: not the seeds file the baseline read")
        if not a.league.is_file():
            raise Refused(f"{a.league}: no league binary")
        base_games = live_games(base)
        root = Path(a.out_root)
        root.mkdir(parents=True, exist_ok=True)
        for card in dict.fromkeys(a.cards):
            folder = root / card
            if done(base, base_games, folder, card):
                print(f"card_without_run: {card}: done, skipped", file=sys.stderr)
                continue
            print(f"card_without_run: {card}: playing", file=sys.stderr)
            log = root / f"{card}.log"
            with log.open("wb") as out:
                try:
                    run = subprocess.run(command(a, base, card, folder), stdout=out,
                                         stderr=subprocess.STDOUT, timeout=a.timeout)
                except subprocess.TimeoutExpired:
                    print(f"card_without_run: {card}: timed out after {a.timeout:.0f} s; "
                          f"see {log}", file=sys.stderr)
                    return 1
            if run.returncode != 0:
                tail = log.read_text(errors="replace").strip().splitlines()[-1:]
                print(f"card_without_run: {card}: league exited {run.returncode}: "
                      f"{tail[0] if tail else ''}", file=sys.stderr)
                return 1
            compare(base, base_games, Match(folder))
    except Refused as e:
        print(f"card_without_run: refused: {e}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
