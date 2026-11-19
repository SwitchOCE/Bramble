#!/usr/bin/env python3
"""Bounded integration checks for the fight restoration contract (stdlib only)."""

import copy
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from make_cases import ROOT, dump


def player(seat):
    return {
        "id": seat,
        "tier": 1,
        "board": [None] * 7,
        "hand": [],
        "counters": {},
        "heaps": {},
        "slots": [{"attack": 0, "health": 0, "keywords": []} for _ in range(7)],
        "standing": [],
    }


def case(case_id):
    return {
        "id": case_id,
        "game_seed": "-9223372036854775808",
        "round": 9,
        "a": player(3),
        "b": player(6),
        "mutations": [],
    }


def run(cases, directory, stem, extra=()):
    target = directory / f"{stem}.jsonl"
    command = [
        "timeout",
        "-k",
        "10",
        "90",
        "godot",
        "--headless",
        "--log-file",
        str(directory / f"{stem}.godot.log"),
        "-s",
        "res://tools/league/gd/fight_run.gd",
        "--",
        f"cases={cases}",
        f"out={target}",
        *extra,
    ]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not any(marker in result.stdout + result.stderr for marker in ("ERROR:", "WARNING:")), result
    return [json.loads(line) for line in target.read_text().splitlines()]


def main():
    checks = ROOT / "build/league-fights"
    checks.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="contract-", dir=checks) as temporary:
        directory = Path(temporary)
        empty = case(10)
        empty["a"]["tier"] = 6
        empty["a"]["counters"] = {"locust_tide": 7}
        empty["a"]["heaps"] = {"thorn_compost": {"entries": [{"id": "brock-cub", "tier": 1, "n": 2}], "_next_n": 19}}
        empty["a"]["slots"][2] = {"attack": 8, "health": 9, "keywords": ["taunt"]}
        empty["a"]["hand"] = [{"def": "sentry", "uid": 901, "golden": False}]
        empty["a"]["standing"] = [
            {
                "id": "pigeon_guard_post",
                "granted": True,
                "params": {
                    "golden": True,
                    "_ints": {"unused": 5},
                    "_texts": {"unused_text": "saved"},
                    "_kinds": {"unused": 0},
                    "_golden_ints": {"unused": 11},
                },
            }
        ]
        win = case(20)
        win["game_seed"] = "9223372036854775807"
        # Sentry has an End of Turn slot buff. Direct _fight must never run it.
        win["a"]["board"][0] = {
            "def": "sentry",
            "uid": 42,
            "golden": True,
            "stats": {"base_health": 31, "set_attack": 0, "perm_health": 5},
            "bought_copies": 3,
            "grants": [["taunt"]],
            "aura_grants": [["windfury"]],
            "counters": {"pigeon_medals": 4},
            "turn_counters": {"core_check": 2},
        }
        loss = case(30)
        loss["b"]["board"][5] = {"def": "sentry", "uid": 18, "golden": False}
        # Each invalid case has a valid follower, proving rejection does not abort the stream.
        invalid = []

        def bad(label, mutate):
            saved = copy.deepcopy(win)
            saved["id"] = 100 + len(invalid)
            mutate(saved)
            invalid.append((label, saved))

        bad("duplicate uid", lambda x: x["b"]["hand"].append(copy.deepcopy(x["a"]["board"][0])))
        bad("unknown card", lambda x: x["a"]["board"][0].update({"def": "not-a-card"}))
        bad("same seat", lambda x: x["b"].update({"id": 3}))
        bad("ghost", lambda x: x["a"].update({"id": -1}))
        bad("bad seed", lambda x: x.update({"game_seed": "9223372036854775808"}))
        bad("missing field", lambda x: x["a"].pop("standing"))
        bad(
            "bad heap n",
            lambda x: x["a"].update(
                {"heaps": {"thorn_compost": {"entries": [{"id": "brock-cub", "tier": 1, "n": 2}], "_next_n": 2}}}
            ),
        )
        bad(
            "bad heap tier",
            lambda x: x["a"].update(
                {"heaps": {"thorn_compost": {"entries": [{"id": "brock-cub", "tier": 6, "n": 1}], "_next_n": 2}}}
            ),
        )
        bad("parameterized slot keyword", lambda x: x["a"]["slots"][0].update({"keywords": ["badger_fury"]}))
        bad("bad grants", lambda x: x["a"]["board"][0].update({"aura_grants": [["badger_fury"]]}))
        fixtures = [empty, win, loss, *(saved for _, saved in invalid), empty]
        source = directory / "cases.jsonl"
        source.write_text("".join(dump(saved) + "\n" for saved in fixtures) + "{bad json}\n[]\n" + dump(win))
        out = run(source, directory, "all")
        assert len(out) == len(fixtures) + 3
        for saved, result in zip(fixtures[:3], out[:3], strict=True):
            assert result["id"] == saved["id"] and "error" not in result
            assert hashlib.sha256(result["state"].encode()).hexdigest() == result["hash"]
            state = json.loads(result["state"])
            assert state["seed_value"] == int(saved["game_seed"])
            assert state["round_number"] == 9 and state["pairings"] == [[3, 6]]
            assert len(state["players"]) == 8 and state["_rr_index"] == 0
            assert not state["_any_eliminated"] and not state["over"]
            rng = state["recruit_rng"]
            assert rng["_shop_rng"] == {} and rng["_discover_rng"] == {}
            # Each after_fight RecruitContext eagerly creates its owner's effect stream.
            assert set(rng["_effect_rng"]) == {"3", "6"}
            assert all(len(stream["_s"]) == 4 for stream in rng["_effect_rng"].values())
            assert all(p["gold"] == 0 and not p["turn_ended"] and p["opponents"] == [] for p in state["players"])
            assert state["players"][0]["standing"]
            assert state["players"][3]["standing"] == saved["a"]["standing"]
        state = json.loads(out[0]["state"])
        assert (out[0]["winner"], out[0]["loser"], out[0]["damage"]) == (-1, -2, 0)
        assert state["_next_uid"] == 902
        assert state["players"][3]["tier"] == 6
        assert state["players"][3]["heaps"] == empty["a"]["heaps"]
        assert state["players"][3]["slots"] == empty["a"]["slots"]
        assert state["players"][3]["counters"] == empty["a"]["counters"]
        assert (out[1]["winner"], out[1]["loser"], out[1]["damage"]) == (0, 6, 13)
        state = json.loads(out[1]["state"])
        unit = state["players"][3]["board"][0]
        assert state["_next_uid"] == 43 and state["players"][6]["health"] == 27
        assert unit["stats"]["base_attack"] == 4 and unit["stats"]["base_health"] == 31
        assert unit["stats"]["set_attack"] == 0 and unit["stats"]["set_health"] == -1
        assert unit["stats"]["perm_health"] == 5 and unit["slot"] == 0
        assert unit["bought_copies"] == 3
        assert unit["counters"] == {"pigeon_medals": 4} and unit["turn_counters"] == {"core_check": 2}
        assert state["players"][3]["slots"][0] == {"attack": 0, "health": 0, "keywords": []}
        assert unit["mechanics"][-1]["id"] == "taunt" and unit["mechanics"][-1]["params"]["golden"]
        assert (out[2]["winner"], out[2]["loser"], out[2]["damage"]) == (1, 3, 13)
        for (label, _), result in zip(invalid, out[3 : 3 + len(invalid)], strict=True):
            assert "error" in result, (label, result)
        assert out[len(fixtures) - 1] == out[0]
        assert out[-3]["id"] == -1 and "error" in out[-3]
        assert out[-2]["id"] == -1 and "error" in out[-2]
        assert out[-1] == out[1]  # Last line deliberately has no trailing newline.
        selected = run(source, directory, "selected", ("first=1", "count=1"))
        assert selected == [out[1]]
        assert run(source, directory, "past-eof", ("first=500",)) == []
        large = directory / "large-prefix.jsonl"
        padding = copy.deepcopy(empty)
        padding["mutations"] = ["é" * 1048600]
        large.write_text(dump(padding) + "\n" + dump(win) + "\n")
        assert run(large, directory, "large-selected", ("first=1", "count=1")) == [out[1]]
        print(
            f"PASS: restoration/defaults, side-vs-seat winners, damage, UID bounds, no End of Turn; "
            f"{len(invalid) + 2} rejection cases; first/count and unterminated final line"
        )


if __name__ == "__main__":
    main()
