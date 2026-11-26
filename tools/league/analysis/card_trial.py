#!/usr/bin/env python3
"""Trial rules: what a proposed card change does to each bot's places, before proposing it.

    python3 card_trial.py BASELINE TRIAL [TRIAL ...] [--control RERUN] [--out FILE.csv]

BASELINE is a `league ghost-match` folder on the game's card data. Each TRIAL is the same match
played with `--trial-rules --repo-root <changed card data>`: same seeds, secret, games, bots and
field runs, with the field cut at the baseline's rules. Writes one CSV row per trial per bot
(stdout without `--out`): the live seat's place with the change minus its place without it, with
a 95% interval over seed lines. Positive means the bot finishes worse with the change.
`--control` takes a second run of the baseline. A trial pairs only with a baseline whose rules
are the trial's field rules, and never stands in for a normal match. The definition is fixed in
docs/workstreams/card-power/definitions.md, "Trial rules".
"""
import argparse
import csv
import sys
from pathlib import Path

from card_without import CONTROL, SAME, Refused, live_games, refuse_trial, secret
from match_data import Match, Stat

COLUMNS = ("trial", "changes", "bot", "colour", "games", "place_base", "place_trial",
           "diff_mean", "ci95_low", "ci95_high", "seed_lines")


def describe(trial):
    """The changed cards as `card field was->now; ...`, from summary.json."""
    changes = (trial.get("changes") or {})
    parts = []
    for card in changes.get("cards") or []:
        for field, change in sorted(card["changed"].items()):
            parts.append(f"{card['id']} {field} {change['was']}->{change['now']}")
    if not parts and changes.get("files"):
        parts = [f"files: {', '.join(changes['files'])}"]
    return "; ".join(parts) or "unknown"


def check(base, other, control=False):
    for match in (base, other):
        if match.summary.get("mode") != "async":
            raise Refused(f"{match.path}: not a ghost-match")
        if "without" in match.summary:
            raise Refused(f"{match.path}: has `without`; a trial pairs only plain matches")
    refuse_trial(base)
    trial = other.summary.get("trial_rules")
    if control:
        refuse_trial(other)
        if other.path.resolve() == base.path.resolve():
            raise Refused(f"{other.path}: a control must be a second run, not the baseline")
    else:
        if not trial:
            raise Refused(f"{other.path}: summary.json has no `trial_rules`; not a trial match")
        if trial.get("field_rules_hash") != base.summary.get("rules_hash"):
            raise Refused(f"{other.path}: its field was cut at rules "
                          f"{trial.get('field_rules_hash')}, the baseline plays "
                          f"{base.summary.get('rules_hash')}")
        if other.summary.get("rules_hash") == base.summary.get("rules_hash"):
            raise Refused(f"{other.path}: a trial with the baseline's own rules")
    for key in SAME:
        if key == "rules_hash" and not control:
            continue
        if base.summary.get(key) != other.summary.get(key):
            raise Refused(f"{other.path}: {key} is {other.summary.get(key)!r}, "
                          f"the baseline has {base.summary.get(key)!r}")
    if secret(base) != secret(other):
        raise Refused(f"{other.path}: a different match secret")
    return trial


def rows_for(base_games, other, label, changes):
    games = live_games(other)
    if len(games) != len(base_games):
        raise Refused(f"{other.path}: {len(games)} games, the baseline has {len(base_games)}")
    stats = {}
    for index, (b, o) in enumerate(zip(base_games, games)):
        if b[:4] != o[:4]:
            raise Refused(f"{other.path}: game {index} has a different seed, runs or live bot")
        base_s, trial_s, diff = stats.setdefault((b[2], b[3]), (Stat(), Stat(), Stat()))
        pair = index // 2
        base_s.add(pair, b[4])
        trial_s.add(pair, o[4])
        diff.add(pair, o[4] - b[4])
    out = []
    for (colour, bot), (base_s, trial_s, diff) in sorted(stats.items()):
        d = diff.result()
        ci = d["ci95"] or [None, None]
        out.append(dict(trial=label, changes=changes, bot=bot, colour=colour, games=d["count"],
                        place_base=base_s.result()["mean"], place_trial=trial_s.result()["mean"],
                        diff_mean=d["mean"], ci95_low=ci[0], ci95_high=ci[1],
                        seed_lines=d["pairs"]))
    return out


def table(baseline, trials, controls=()):
    base = Match(baseline)
    base_games = live_games(base)
    rows = []
    for path in trials:
        other = Match(path)
        trial = check(base, other)
        rows.extend(rows_for(base_games, other, other.path.name, describe(trial)))
    for path in controls:
        other = Match(path)
        check(base, other, control=True)
        rows.extend(rows_for(base_games, other, CONTROL, ""))
    return rows


def write(rows, stream):
    out = csv.DictWriter(stream, fieldnames=COLUMNS, lineterminator="\n")
    out.writeheader()
    for row in rows:
        out.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in row.items()})


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("baseline")
    p.add_argument("trials", nargs="*")
    p.add_argument("--control", action="append", default=[])
    p.add_argument("--out", help="CSV file to write (default: stdout)")
    a = p.parse_args(argv)
    try:
        if not a.trials and not a.control:
            raise Refused("no TRIAL match or --control given")
        rows = table(a.baseline, a.trials, a.control)
    except Refused as e:
        print(f"card_trial: refused: {e}", file=sys.stderr)
        return 2
    if a.out:
        tmp = Path(a.out).with_suffix(".tmp")
        with tmp.open("w", encoding="utf-8") as f:
            write(rows, f)
        tmp.replace(a.out)
    else:
        write(rows, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
