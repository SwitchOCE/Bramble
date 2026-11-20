#!/usr/bin/env python3
"""Check a `league ghost-match` output folder: pairs, runs, records and the paired score.

Usage: check_ghost_match.py <match out dir> <games>
Each pair (games 2p and 2p+1) must share its seed and its 7 runs, with red live in the
first game and blue in the second; no run is used twice; the summary's gap must be the
mean of the paired placement differences.
"""
import json
import pathlib
import statistics
import sys

directory = pathlib.Path(sys.argv[1])
expected = int(sys.argv[2])


def lines(path):
    return [json.loads(line) for line in path.read_text().splitlines()]


games = lines(directory / "games.jsonl")
assert len(games) == expected and expected % 2 == 0, (len(games), expected)
used = set()
gaps = []
for p in range(expected // 2):
    red, blue = games[2 * p : 2 * p + 2]
    assert red["seed"] == blue["seed"], p
    assert red["runs"] == blue["runs"], p
    assert [run["seat"] for run in red["runs"]] == list(range(1, 8)), p
    ids = {run["id"] for run in red["runs"]}
    assert len(ids) == 7 and not used & ids, p
    used |= ids
    gaps.append(red["seats"][0]["place"] - blue["seats"][0]["place"])
    for side, game, index in (("red", red, 2 * p), ("blue", blue, 2 * p + 1)):
        assert game["game"] == index and game["mode"] == "async" and game["live_team"] == side, index
        assert [seat["seat"] for seat in game["seats"]] == [0], index
        record = lines(directory / "records" / f"game-{index:05}.jsonl")
        header = record[0]
        assert header["format"] == 4 and header["mode"] == "async", index
        assert header["runs"] == game["runs"] and header["seed"] == game["seed"], index
        assert record[-1]["op"] == "finish" and record[-1]["over"], index
        for entry in record[1:]:
            if entry["op"] in ("act", "end"):
                assert entry["player"] == 0, index
            if entry["op"] == "fight_boards":
                assert "run_boards" in entry, index
summary = json.loads((directory / "summary.json").read_text())
assert summary["mode"] == "async"
assert abs(statistics.mean(gaps) - summary["gap_red_minus_blue"]) < 1e-9
print(f"ghost-match: PASS {expected // 2} pairs, {len(used)} distinct runs")
