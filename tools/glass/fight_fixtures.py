#!/usr/bin/env python3
"""Writes fight.html's two moments as view states for the fight screen's compare scenes.

    python3 tools/glass/fight_fixtures.py

The units, numbers and the attack are copied from fight.html's YOURS, THEIRS and ATTACK (stand-ins
there, not decided units); the hero, the leaderboard and the turn from the recruit fixture.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECRUIT = ROOT / "tests" / "screens" / "fixtures" / "recruit_mockup.json"
OUT = ROOT / "tests" / "screens" / "fixtures"
TEXT = "Rules text goes here, in one or two short lines."
# The Renown slot in the view contract.
RENOWN_SLOT = {"renown": 4}


def unit(uid: str, tier: int, art: str, attack: int, health: int, name: str, hp=None, dead=False) -> dict:
    return {
        "id": uid,
        "tier": tier,
        "art": art,
        "attack": attack,
        "health": health,
        "name": name,
        "hp": hp,
        "dead": dead,
    }


YOURS = [
    unit("b0", 6, "stag-1", 25, 30, "Stag", hp=22),
    unit("b1", 4, "badger-1", 6, 12, "Badger shield-bearer", hp=7),
    unit("b2", 3, "otter-1", 7, 8, "Otter river guard"),
    unit("b3", 2, "hare-2", 4, 3, "Hare scout", dead=True),
    unit("b4", 5, "ooze-1", 12, 10, "Ooze"),
    None,
    unit("b6", 1, "stoat-1", 3, 2, "Stoat skirmisher"),
]
THEIRS = [
    unit("o0", 4, "fairy-1", 5, 4, "Fairy"),
    unit("o1", 3, "hedgehog-2", 5, 9, "Hedgehog pikeman", hp=3),
    unit("o2", 5, "boar-2", 10, 8, "Boar", hp=2),
    unit("o3", 2, "mouse-2", 3, 3, "Mouse", dead=True),
    unit("o4", 4, "owl-2", 6, 6, "Barn owl archer"),
    unit("o5", 3, "otter-2", 4, 6, "Otter river guard"),
    unit("o6", 1, "stoat-2", 2, 1, "Stoat skirmisher"),
]


def board(units: list, mid: bool) -> list:
    out: list = []
    for i, c in enumerate(units):
        if c is None or (mid and c["dead"]):
            out.append(None)
            continue
        view = {k: v for k, v in c.items() if k not in ("hp", "dead")}
        view["uid"] = i if c["id"].startswith("b") else 10 + i
        view["max_health"] = c["health"]
        view["text"] = TEXT
        if mid and c["hp"] is not None:
            view["health"] = c["hp"]
        out.append(view)
    return out


def main() -> None:
    recruit = json.loads(RECRUIT.read_text())
    for mid in (False, True):
        state = {
            "about": "fight.html's %s moment as a view state; its names and numbers are the mock-up's stand-ins"
            % ("mid-fight" if mid else "before-the-first-attack"),
            "turn": recruit["turn"],
            "health": recruit["health"],
            "hero": recruit["hero"],
            "counters": recruit["counters"],
            "display": recruit["display"],
            "players": recruit["players"],
            "opponent": {"name": "Brother Bracken", "portrait": "brother_bracken", "health": 36},
            "you_side": 0,
            "boards": [board(YOURS, mid), board(THEIRS, mid)],
            "slots": [[{}, {}, {}, {}, {}, RENOWN_SLOT, {}], [{}] * 7],
        }
        if mid:
            state["moment"] = {
                "lunge": {"side": 0, "slot": 1, "target_side": 1, "target_slot": 1},
                "splashes": [{"side": 1, "slot": 1, "amount": 6}, {"side": 0, "slot": 1, "amount": 5}],
            }
        name = "fight_mid.json" if mid else "fight_start.json"
        (OUT / name).write_text(json.dumps(state, indent=1, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
