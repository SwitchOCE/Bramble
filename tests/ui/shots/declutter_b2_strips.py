#!/usr/bin/env python3
"""Native eight-frame recruit strips and assertions against captured state/reader reach."""

import argparse
import json
from pathlib import Path

from declutter_strips import write_sheet

from declutter_evidence import read_json

p = argparse.ArgumentParser(description=__doc__)
p.add_argument("frames", type=Path)
p.add_argument("output", type=Path)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)
runs = []
event_hashes = set()
for source in sorted(a.frames.glob("*/manifest.json")):
    m = read_json(source)
    assert len(m["frames"]) == 8
    assert [f["tick"] for f in m["frames"]] == m["sample_ticks"]
    gaps = [b - a for a, b in zip(m["sample_ticks"], m["sample_ticks"][1:], strict=False)]
    assert min(gaps) > 0 and max(gaps) - min(gaps) <= 1
    assert m["duration"] <= 1.5
    kind = "end-turn" if m["name"].startswith("end-turn") else "scout-reach"
    if kind == "end-turn":
        event_hashes.add(m["events_sha256"])
        assert any(e["type"] == "pass" for e in m["events"])
        assert any(e["type"] == "buff" and e.get("source") == "declutter_test_committee" for e in m["events"])
        expected = {i: (u["attack"], u["health"]) for i, u in enumerate(m["after_board"]) if u is not None}
        actual = {u["slot"]: (u["attack"], u["health"]) for u in m["frames"][-1]["board_stats"]}
        assert actual == expected, (m["name"], actual, expected)
        m["final_stats_equal_core"] = True
    else:
        values = [f["reach_values"] for f in m["frames"]]
        assert any(x["expected_target5"] > 0.5 for x in values), m["name"]
        assert all(x["straight_across2"] < 0.001 for x in values), m["name"]
        assert values[-1]["expected_target5"] < 0.05, m["name"]
        m["lent_quarry_target_only_and_then_clears"] = True
    frames = []
    for f in m["frames"]:
        f = dict(f)
        f["seconds"] = f["time"]
        frames.append(f)
    interval = {"kind": kind, "event_index": -1, "start_tick": 0, "sample_ticks": m["sample_ticks"], "frames": frames}
    destination = a.output / m["name"]
    destination.mkdir(parents=True, exist_ok=True)
    strip = write_sheet(source.parent, destination, m["pixels"], interval, m["fixed_step"])
    m["strip"] = strip
    m["method"] = (
        "Fixed1/120s explicit animation advance; eight evenly spaced native1688x780 frames, no image scaling, "
        "assembled6752x1640 as batch1. Actual core End-of-Turn events, or the real reader-open reach pulse "
        "with manually stepped native Tween."
    )
    (destination / "manifest.json").write_text(json.dumps(m, indent=2) + "\n")
    runs.append(
        {
            "run": m["name"],
            "strip": m["name"] + "/" + strip,
            "duration": m["duration"],
            "frames": 8,
            "labels": [
                min(f["visible_text_count"] for f in m["frames"]),
                max(f["visible_text_count"] for f in m["frames"]),
            ],
        }
    )
    print(m["name"], m["duration"], "8 native frames; state/reach assertions pass")
assert len(runs) == 6
assert len(event_hashes) == 1, "all three modes replay equal actual core events"
(a.output / "runs.json").write_text(json.dumps(runs, indent=2) + "\n")
