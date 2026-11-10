#!/usr/bin/env python3
"""Reader follow-up sheets plus the isolated cleanup-only whole-fight timing comparison."""

import argparse
import json
from pathlib import Path

from declutter_strips import validate_interval_sampling, write_sheet
from PIL import Image

from declutter_evidence import read_json


def assemble(packet: Path, frames: Path, revision: str) -> None:
    before = read_json(packet / "before-timings.json")
    cleanup = read_json(packet / "after-cleanup-timings.json")
    final = read_json(packet / "after-final-timings.json")
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
    content_audits = []
    for source in sorted(frames.glob("*/manifest.json")):
        manifest = read_json(source)
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
            assert interval["sampling"]["mode"] == "uniform-plus-observed-lunge-peaks"
            assert all(x["ancillary_text_nodes"] <= 10 for x in interval["frames"])
            interval["strip"] = write_sheet(
                source.parent, destination, manifest["pixels"], interval, manifest["fixed_step"]
            )
            with Image.open(destination / interval["strip"]) as picture:
                assert picture.size == (6752, 820 * ((len(interval["frames"]) + 3) // 4))
            if scenario == "combat_mid" and interval["event_index"] == 45:
                receipts = [
                    {"frame": frame["file"], "tick": frame["tick"], **receipt}
                    for frame in interval["frames"]
                    for receipt in frame.get("damage_receipts", [])
                    if (receipt["recipient_uid"], receipt["text"]) in {(9, "\u22125"), (2, "\u22124")}
                ]
                if manifest["speed"] == 1.0:
                    assert receipts, "combat_mid045 x1/reduce must retain a sampled post-hit damage number"
                content_audits.append({"run": source.parent.name, "post_hit_damage_number_witnesses": receipts})
            sheets.append(
                {
                    "run": source.parent.name,
                    "strip": str((destination / interval["strip"]).relative_to(packet)),
                    "attack_event_index": interval["event_index"],
                    "frames": len(interval["frames"]),
                    "uniform_frames_preserved": 8,
                    "appended_peak_ticks": interval["sampling"]["appended_peak_ticks"],
                    "peak_actor_uids": [p["uid"] for p in interval["sampling"]["lunge_peaks"]],
                    "ancillary_labels": [
                        min(x["ancillary_text_nodes"] for x in interval["frames"]),
                        max(x["ancillary_text_nodes"] for x in interval["frames"]),
                    ],
                }
            )
        manifest["production_revision"] = revision
        manifest["render_provenance"] = "Fresh uniform-plus-peak render on the stated production revision."
        manifest["whole_fight_seconds"] = manifest["ticks"] * manifest["fixed_step"]
        manifest["final_model_state_sha256"] = timing["final_state_sha256"]
        (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    assert len(sheets) == 9
    report = {
        "before_revision": before["production_revision"],
        "cleanup_after_revision": cleanup["production_revision"],
        "final_after_revision": revision,
        "render_sources": {"bog": revision, "combat_mid": revision},
        "before_images_captured": 0,
        "new_after_sheets": 9,
        "new_after_frames": sum(sheet["frames"] for sheet in sheets),
        "method": (
            "Whole-fight durations count fixed120Hz advances through automatic return, with two identical "
            "timing passes. "
            "Cleanup-only comparison is isolated at its own source revision. Final sheets sample Bog017/025 and "
            "combat_mid045 at x1/x4/reduce: preserve all eight uniform native1688x780 samples and append "
            "each distinct actor peak, including each Pack actor. No original sample is replaced. "
            "Reduced motion appends held-pose/source-flash peaks. Full events/order/model/Health "
            "match all heads. Within-head discovery and render replay match event ticks and return. Historical packets "
            "and accepted d400831e Bog before images are unchanged."
        ),
        "duration_pairs": pairs,
        "content_audits": content_audits,
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
    print("Nine after sheets; all uniform and peak frames, full events, order, model and playback checks pass")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("packet", type=Path)
    parser.add_argument("frames", type=Path)
    parser.add_argument("revision")
    args = parser.parse_args()
    assemble(args.packet, args.frames, args.revision)
