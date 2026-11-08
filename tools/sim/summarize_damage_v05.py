#!/usr/bin/env python3
"""Reproduce the preregistered damage targets from complete per-game raw JSONL."""

import gzip
import json
import statistics
import sys
from pathlib import Path

ARMS = ("baseline", "A", "B", "C", "D", "E")
SEEDS = set(range(860001, 860201))


def qualifying(rounds):
    start = None
    length = 0
    for row in rounds:
        if row["result"] == "loss":
            if length == 0:
                start = row["round"]
            length += 1
            if length >= 5 and start <= 6:
                return True
        else:
            start = None
            length = 0
    return False


def summarize(games):
    streak_eliminations = []
    censored = 0
    first_eliminations = []
    comebacks = 0
    bottom_count = 0
    damage = performance = effective = effective_performance = 0
    for game in games:
        eliminations = []
        bottom = []
        for player in game["players"]:
            rounds = player["rounds"]
            eliminated = game["rounds"] + 1 if player["alive"] else rounds[-1]["round"]
            if not player["alive"]:
                eliminations.append(eliminated)
            if qualifying(rounds):
                streak_eliminations.append(eliminated)
                censored += bool(player["alive"])
            for row in rounds:
                if row["round"] == 8 and row["health"] > 0:
                    bottom.append((row["health"], player["seat"], player["place"]))
        if not eliminations:
            raise ValueError("game has no eliminations")
        first_eliminations.append(min(eliminations))
        bottom.sort()
        bottom_count += len(bottom[:2])
        comebacks += sum(place <= 4 for _, _, place in bottom[:2])
        for fight in game["fights"]:
            for charge in fight["charges"]:
                damage += charge["damage"]
                performance += charge["performance"]
                effective += charge["effective"]
                if charge["damage"]:
                    effective_performance += charge["effective"] * charge["performance"] / charge["damage"]
    schedule = games[0]["base_schedule"]
    return {
        "games": len(games),
        "qualifying_players": len(streak_eliminations),
        "qualifying_censored": censored,
        "streak_elimination_median": statistics.median(streak_eliminations) if streak_eliminations else None,
        "game_length_median": statistics.median(game["rounds"] for game in games),
        "first_elimination_median": statistics.median(first_eliminations),
        "performance_share": performance / damage if damage else None,
        "damage_total": damage,
        "performance_total": performance,
        "effective_damage_total": effective,
        "effective_performance_share": effective_performance / effective if effective else None,
        "comeback_rate": comebacks / bottom_count if bottom_count else None,
        "comebacks": comebacks,
        "bottom_two_players": bottom_count,
        "health": games[0]["starting_health"],
        "base_schedule": schedule,
        "base_changes": sum(a != b for a, b in zip(schedule, schedule[1:], strict=False)),
    }


def evaluate(metrics):
    base = metrics["baseline"]
    for arm in ARMS[1:]:
        item = metrics[arm]
        item["targets"] = {
            "T1": item["streak_elimination_median"] is not None
            and base["streak_elimination_median"] is not None
            and item["streak_elimination_median"] >= base["streak_elimination_median"] + 2,
            "T2": abs(item["game_length_median"] - base["game_length_median"]) <= 1,
            "T3": item["performance_share"] is not None and 0.25 <= item["performance_share"] <= 0.45,
            "T4": item["first_elimination_median"] >= base["first_elimination_median"] + 1,
            "T5": item["comeback_rate"] is not None
            and base["comeback_rate"] is not None
            and item["comeback_rate"] >= base["comeback_rate"],
        }
        item["targets_met"] = sum(item["targets"].values())
    return min(
        ARMS[1:],
        key=lambda arm: (
            -metrics[arm]["targets_met"],
            metrics[arm]["base_changes"],
            metrics[arm]["health"] != 40,
            arm,
        ),
    )


def main():
    folder = Path(sys.argv[1])
    metrics = {}
    for arm in ARMS:
        games = []
        paths = sorted(folder.glob(f"{arm}.[0-3].jsonl*"))
        for path in paths:
            if path.suffix == ".gz":
                with gzip.open(path, "rt") as source:
                    games.extend(json.loads(line) for line in source)
            else:
                games.extend(json.loads(line) for line in path.read_text().splitlines())
        seeds = [game["seed"] for game in games]
        if len(seeds) != 200 or set(seeds) != SEEDS:
            raise ValueError(f"{arm}: expected exactly 200 paired seeds; got {len(seeds)}")
        if any(not game["complete"] or game["arm"] != arm for game in games):
            raise ValueError(f"{arm}: incomplete or mislabeled games")
        if any(len(game["players"]) != 8 for game in games):
            raise ValueError(f"{arm}: expected eight players")
        metrics[arm] = summarize(games)
    winner = evaluate(metrics)
    result = {"winner": winner, "metrics": metrics}
    (folder / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    lines = [
        "|Arm|Streak out (n/censored)|Game end|First out|Performance|Effective performance|Comeback|Targets|",
        "|---|---:|---:|---:|---:|---:|---:|---|",
    ]
    for arm, item in metrics.items():
        targets = ",".join(name for name, passed in item.get("targets", {}).items() if passed) or "—"
        lines.append(
            f"|{arm}|{item['streak_elimination_median']} ({item['qualifying_players']}/"
            f"{item['qualifying_censored']})|{item['game_length_median']}|"
            f"{item['first_elimination_median']}|{item['performance_share']:.2%}|"
            f"{item['effective_performance_share']:.2%}|{item['comebacks']}/"
            f"{item['bottom_two_players']} ({item['comeback_rate']:.2%})|{targets}|"
        )
    lines.append(f"\nSelected {winner} by preregistered target count and tie-breaks.")
    text = "\n".join(lines) + "\n"
    (folder / "results.md").write_text(text)
    print(text)


if __name__ == "__main__":
    main()
