#!/usr/bin/env python3
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import subprocess
import sys

# S8 soak: 50 seeds per tribe, all eight seats on that tribe's TribeBot.
# Usage: soak_tribes.py <repo root> <league binary> <output dir>   (output goes on /data, not in the repo)
repo, binary, output = (Path(a).resolve() for a in sys.argv[1:4])
tribes = ("badger", "mouse", "pigeon", "locust", "briar")
seeds = range(10001, 10051)

native_reserves = set()
for path in (repo / "src/content").glob("*/units.json"):
    for card in json.loads(path.read_text())["cards"]:
        ids = card.get("keywords", []) + [e["mechanic"] for e in card.get("effects", [])]
        if "pigeon_reserve" in ids:
            native_reserves.add(card["id"])

def was_held(player):
    if player["id"] < 0 or sum(u is not None for u in player["board"]) < 5:
        return False
    return any(
        u["def"] in native_reserves
        or any(
            e[0] == "pigeon_reserve"
            for field in ("grants", "aura_grants")
            for e in u.get(field, [])
        )
        for u in player["hand"]
    )

def play(case):
    tribe, seed = case
    run = output / tribe / str(seed)
    run.mkdir(parents=True, exist_ok=True)
    seed_file = run / "seed.txt"
    seed_file.write_text(f"{seed}\n")
    bot = f"tribe-{tribe}"
    with (run / "run.log").open("w") as log:
        subprocess.run(
            [
                str(binary), "match", "--red", bot, "--blue", bot,
                "--games", "1", "--seeds", str(seed_file), "--threads", "1",
                "--clock-ms", "1000", "--secret", "8", "--no-decisions",
                "--out", str(run),
            ],
            cwd=repo, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=120,
        )
    game = json.loads((run / "games.jsonl").read_text())
    assert int(game["seed"]) == seed and len(game["seats"]) == 8
    assert all(s["bot"] == bot for s in game["seats"])
    bad = {
        "clock_outs": sum(s["clock_out"] is not None for s in game["seats"]),
        "panics": sum(s["panic"] is not None for s in game["seats"]),
        "faults": sum(s["fault"] is not None for s in game["seats"]),
        "refused": sum(s["refused"] for s in game["seats"]),
    }
    held, held_open, actives = False, False, set()
    with (run / "records/game-00000.jsonl").open() as record:
        for row in map(json.loads, record):
            if row["op"] == "fight_boards":
                held |= any(was_held(p) for p in row["players"])
                held_open |= any(None in p["board"] and was_held(p) for p in row["players"])
            if row["op"] == "act" and row["action"]["type"] == "ability" and row["result"] == "":
                actives.add(row["action"]["mechanic"])
    return {"tribe": tribe, "seed": seed, "held": held, "held_open": held_open, "actives": sorted(actives), **bad}

with ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(play, ((tribe, seed) for seed in seeds for tribe in tribes)))
(output / "results.json").write_text(json.dumps(results, indent=2) + "\n")

print("tribe,games,reserve_held,active_used,clock_outs,panics,faults,refused")
for tribe in tribes:
    games = [r for r in results if r["tribe"] == tribe]
    assert len(games) == 50 and len({r["seed"] for r in games}) == 50
    print(
        tribe, len(games), sum(r["held"] for r in games), sum(bool(r["actives"]) for r in games),
        *(sum(r[k] for r in games) for k in ("clock_outs", "panics", "faults", "refused")),
        sep=",",
    )
pigeon = [r for r in results if r["tribe"] == "pigeon"]
for mechanic in ("pigeon_lance_corporal", "pigeon_grenadier"):
    print(f"{mechanic}: {sum(mechanic in r['actives'] for r in pigeon)} games")
print(f"pigeon Reserve held with space to play: {sum(r['held_open'] for r in pigeon)} games")
assert any(r["held_open"] for r in pigeon) and any(r["actives"] for r in pigeon)
assert not any(r[k] for r in results for k in ("clock_outs", "panics", "faults", "refused"))
