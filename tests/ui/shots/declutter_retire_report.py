#!/usr/bin/env python3
"""Reader follow-up sheets plus the isolated cleanup-only whole-fight timing comparison."""

import argparse
import json
from pathlib import Path

from declutter_strips import validate_interval_sampling, write_sheet
from PIL import Image


def assemble(packet: Path, frames: Path, revision: str) -> None:
    before = json.loads((packet / "before-timings.json").read_text())
    cleanup = json.loads((packet / "after-cleanup-timings.json").read_text())
    final = json.loads((packet / "after-final-timings.json").read_text())
    old_runs = {(x["scenario"], x["speed"]): x for x in before["runs"]}
    cleanup_runs = {(x["scenario"], x["speed"]): x for x in cleanup["runs"]}
    final_runs = {(x["scenario"], x["speed"]): x for x in final["runs"]}
    assert old_runs.keys() == cleanup_runs.keys() == final_runs.keys()
    pairs = []
    for key, old in old_runs.items():
        new = cleanup_runs[key]
        last = final_runs[key]
        for other in [new, last]:
            assert old["events"] == other["events"]
            assert old["events_sha256"] == other["events_sha256"]
            assert old["final_state"] == other["final_state"]
            assert old["final_state_sha256"] == other["final_state_sha256"]
            assert old["final_health_text"] == other["final_health_text"]
            old_order = [(x["event_index"], x["type"]) for x in old["event_ticks"]]
            new_order = [(x["event_index"], x["type"]) for x in other["event_ticks"]]
            assert old_order == new_order
            assert len(old_order) == len(old["events"])
        pairs.append(
            {
                "scenario": key[0],
                "speed": key[1],
                "before_seconds": old["duration_seconds"],
                "cleanup_after_seconds": new["duration_seconds"],
                "cleanup_saved_seconds": old["duration_seconds"] - new["duration_seconds"],
                "final_source_seconds": last["duration_seconds"],
                "same_events_and_event_order": True,
                "same_final_model_state_and_hero_health": True,
                "events_sha256": new["events_sha256"],
                "final_state_sha256": new["final_state_sha256"],
            }
        )
    sheets = []
    for source in sorted(frames.glob("*/manifest.json")):
        manifest = json.loads(source.read_text())
        scenario = manifest["scenario"]
        selected = [17, 25] if scenario == "bog" else [45]
        assert manifest["speed"] in {1.0, 4.0}
        assert not manifest["reduce_motion"] or manifest["speed"] == 1.0
        assert manifest["selected_attack_event_indices"] == selected
        assert len(manifest["attacks"]) == len(selected)
        assert manifest["timing_passes_equal"]
        timing = final_runs[(scenario, manifest["speed"])]
        assert manifest["source_events_sha256"] == timing["events_sha256"]
        assert manifest["events"] == timing["events"]
        if not manifest["reduce_motion"]:
            assert manifest["event_ticks"] == timing["event_ticks"]
            assert manifest["automatic_return_tick"] == timing["automatic_return_tick"]
        assert manifest["final_health_text"] == timing["final_health_text"]
        destination = packet / "after" / source.parent.name
        destination.mkdir(parents=True, exist_ok=True)
        for interval in manifest["attacks"]:
            assert interval["event_index"] in selected
            validate_interval_sampling(interval, manifest["events"][interval["event_index"]])
            assert all(x["ancillary_text_nodes"] <= 10 for x in interval["frames"])
            interval["strip"] = write_sheet(
                source.parent, destination, manifest["pixels"], interval, manifest["fixed_step"]
            )
            with Image.open(destination / interval["strip"]) as picture:
                assert picture.size == (6752, 1640)
            sheets.append(
                {
                    "run": source.parent.name,
                    "strip": str((destination / interval["strip"]).relative_to(packet)),
                    "attack_event_index": interval["event_index"],
                    "frames": 8,
                    "peak_actor_uids": [p["uid"] for p in interval["sampling"]["lunge_peaks"]],
                    "ancillary_labels": [
                        min(x["ancillary_text_nodes"] for x in interval["frames"]),
                        max(x["ancillary_text_nodes"] for x in interval["frames"]),
                    ],
                }
            )
        manifest["production_revision"] = revision
        manifest["whole_fight_seconds"] = manifest["ticks"] * manifest["fixed_step"]
        manifest["final_model_state_sha256"] = timing["final_state_sha256"]
        (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    assert len(sheets) == 9
    report = {
        "before_revision": before["production_revision"],
        "cleanup_after_revision": cleanup["production_revision"],
        "final_after_revision": revision,
        "before_images_captured": 0,
        "new_after_sheets": 9,
        "new_after_frames": 72,
        "method": (
            "Whole-fight durations count fixed120Hz advances through automatic return, with two identical "
            "timing passes. "
            "Cleanup-only comparison is isolated at its own source revision. Final sheets sample Bog017/025 and "
            "combat_mid045 at x1/x4/reduce: eight native1688x780 frames, initially uniform then adjusted to "
            "include each "
            "actor's observed lunge peak or reduced-motion held-pose/source-flash peak. Full events/order/model/Health "
            "match all heads. Within-head discovery and render replay match event ticks and return. Historical packets "
            "and accepted d400831e Bog before images are unchanged."
        ),
        "duration_pairs": pairs,
        "sheets": sheets,
    }
    (packet / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    for pair in pairs:
        print(
            pair["scenario"],
            pair["speed"],
            pair["before_seconds"],
            "->",
            pair["cleanup_after_seconds"],
            "saved",
            pair["cleanup_saved_seconds"],
            "final",
            pair["final_source_seconds"],
        )
    print("Nine after sheets / 72 native frames; peaks, full events, order, model and playback checks pass")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet", type=Path)
    parser.add_argument("frames", type=Path)
    parser.add_argument("revision")
    args = parser.parse_args()
    assemble(args.packet, args.frames, args.revision)
