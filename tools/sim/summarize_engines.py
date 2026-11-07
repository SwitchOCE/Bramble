"""Compare completed matched seeds from engines_probe.gd; stdout is reviewable JSON."""

import json
import random
import statistics
import sys
from pathlib import Path


def load(path):
    return {
        row["seed"]: row
        for line in Path(path).read_text().splitlines()
        if line.startswith("eng_game: ")
        for row in [json.loads(line[10:])]
    }


def metrics(game):
    out = {"rounds": game["rounds"]}
    picks = [p["picks"] for p in game["players"]]
    total = sum(p[0] for p in picks)
    out["fairy_pick_pct"] = 100 * sum(p[1] for p in picks) / max(1, total)
    for turn in [10, 15]:
        rows = [r for r in game["rows"] if r["round"] == turn and len(r["board"]) >= 6]
        if not rows:
            continue
        biggest = [max(r["board"], key=lambda u: u["stats"]) for r in rows]
        out[f"r{turn}_biggest_ring_pct"] = statistics.mean(100 * u["rings"] / u["stats"] for u in biggest)
        out[f"r{turn}_tier12_pct"] = 100 * statistics.mean(u["tier"] <= 2 for u in biggest)
        fairy = [r for r in rows if sum(u["fairy"] for u in r["board"]) >= 4]
        out[f"r{turn}_fairy_boards"] = len(fairy)
        if fairy:
            out[f"r{turn}_fairy_place"] = statistics.mean(r["place"] for r in fairy)
    return out


def main():
    base, trial = map(load, sys.argv[1:3])
    seeds = sorted(base.keys() & trial.keys())
    output = {"paired_seeds": seeds, "games": len(seeds), "metrics": {}}
    rng = random.Random(86100)
    values = {s: (metrics(base[s]), metrics(trial[s])) for s in seeds}
    keys = sorted({k for pair in values.values() for m in pair for k in m})
    for key in keys:
        paired = [(a[key], b[key]) for a, b in values.values() if key in a and key in b]
        if not paired:
            continue
        differences = [b - a for a, b in paired]
        boots = sorted(statistics.mean(rng.choices(differences, k=len(differences))) for _ in range(1000))
        output["metrics"][key] = {
            "seed_pairs": len(paired),
            "base": statistics.mean(a for a, _ in paired),
            "ring": statistics.mean(b for _, b in paired),
            "change": statistics.mean(differences),
            "paired_95_interval": [boots[24], boots[974]],
        }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
