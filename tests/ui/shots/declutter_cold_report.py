#!/usr/bin/env python3
"""Keep neutral reader artifacts separate from technical action/state evidence."""

import argparse
import csv
import json
import statistics
from pathlib import Path

from declutter_b2_report import tile_word_breakdown
from declutter_strips import write_sheet
from PIL import Image

from declutter_evidence import read_json


def assemble(packet: Path, raw: Path, revision: str) -> None:
    reader = packet / "reader"
    technical = packet / "technical"
    reader.mkdir(parents=True, exist_ok=True)
    technical.mkdir(parents=True, exist_ok=True)
    manifests = []
    same_modes = {}
    for source in sorted(raw.glob("*/manifest.json")):
        data = read_json(source)
        assert data["production_revision"] == revision
        assert len(data["frames"]) == 8
        assert data["duration"] <= 1.5
        assert data["frames"][0]["tick"] == 0
        assert data["settled_ticks"] == 2
        assert data["capture_duration"] >= data["duration"] + data["fixed_step"]
        assert not data["frames"][-1]["action_active"]
        assert data["frames"][-1]["visible_action_overlays"] == 0
        assert [frame["tick"] for frame in data["frames"]] == data["sample_ticks"]
        label, mode = data["reader_label"], data["mode"]
        equality = {key: data[key] for key in ["action", "before", "after", "events", "events_sha256"]}
        if label in same_modes:
            assert same_modes[label] == equality, f"{label}: real core state/events must match both modes"
        else:
            same_modes[label] = equality
        required = {
            "play": "play",
            "ooze": "swallow",
            "buy": "buy",
            "triple": "triple",
            "bird": "fly_south",
            "sell": "sell",
        }
        if data["action"] in required:
            assert any(event["type"] == required[data["action"]] for event in data["events"]), data["action"]
        if data["action"] == "tier-up":
            assert data["after"]["tier"] == data["before"]["tier"] + 1
            assert data["after"]["gold"] == data["before"]["gold"] - data["before"]["tier_up_cost"]
        if data["action"] == "scout":
            reach = [frame["reach_values"] for frame in data["frames"]]
            assert any(row["expected_target5"] > 0.5 for row in reach)
            assert all(row["straight_across2"] < 0.001 for row in reach)
            assert reach[-1]["expected_target5"] < 0.05
            assert any(row["target_quarry_visible"] for row in reach)
            assert not any(row["straight_across_quarry_visible"] for row in reach)
            assert not reach[-1]["target_quarry_visible"]
        for card in data["frames"][-1]["shown_beads"]:
            if card["visible"] and card["zone"] in {"board", "shop", "hand"}:
                assert int(card["attack"] or 0) == int(card["view_attack"]), (label, card)
                assert int(card["health"] or 0) == int(card["view_health"]), (label, card)
        interval = {
            "kind": label + "-" + mode,
            "event_index": -1,
            "start_tick": 0,
            "sample_ticks": data["sample_ticks"],
            "frames": data["frames"],
        }
        data["reader_sheet"] = write_sheet(source.parent, reader, data["pixels"], interval, data["fixed_step"])
        data["method"] = (
            "Eight native 1688x780 frames: a genuine pre-action frame, then seven evenly spaced samples "
            "through the production helper duration plus two fixed settling ticks. "
            "Helpers and native Tweens advance explicitly at120Hz. "
            "Opaque reader label and timing only appear in the reader sheet. "
            "Designed legal state; no fake definitions, triggers, core events or cue timing."
        )
        (technical / (label + "-" + mode + ".json")).write_text(json.dumps(data, indent=2) + "\n")
        manifests.append(
            {
                key: data[key]
                for key in ["reader_label", "action", "mode", "duration", "reader_sheet", "production_revision"]
            }
        )
    assert len(manifests) == 16 and len(same_modes) == 8
    assert {(row["reader_label"], row["mode"]) for row in manifests} == {
        (label, mode) for label in "ABCDEFGH" for mode in ["x1", "reduce"]
    }
    rest = read_json(technical / "resting-words.json")
    assert len(rest["captures"]) == 44
    for capture in rest["captures"]:
        assert capture["visible_text_count"] == len(capture["visible_text_nodes"])
        assert capture["tile_words"]["unexpected_word_count"] == 0, capture["reader_label"]
    classified = []
    for row in rest["captures"]:
        scenario = row["reader_label"].removeprefix("spec-")
        if len(scenario) == 1:
            scenario += "/" + row["stage"]
        classified.append(
            row["tile_words"]
            | {
                "scenario": scenario,
                "pixels": row["pixels"],
                "reader_open": row["reader_open"],
                "image": row["image"],
                "state_sha256": row["state_sha256"],
                "raw_visible_text_count": row["visible_text_count"],
            }
        )
    tile_run = technical / "tile-words-run.json"
    tile_run.write_text(json.dumps({"captures": classified}, indent=2) + "\n")
    tile_word_breakdown(technical, tile_run, revision, stage=packet.name)
    pairs = []
    for row in rest["captures"]:
        if not row["reader_label"].startswith("spec-"):
            continue
        scenario = row["reader_label"].removeprefix("spec-")
        dimensions = "x".join(map(str, row["pixels"]))
        baseline = read_json(packet.parent / "before" / ("manifest-" + dimensions + ".json"))
        original = next(item for item in baseline["captures"] if item["scenario"] == scenario)
        assert original["state_sha256"] == row["state_sha256"]
        pairs.append(
            {
                "scenario": scenario,
                "pixels": row["pixels"],
                "same_state_sha256": row["state_sha256"],
                "before": "../../before/" + original["file"],
                "before_raw_text_count": original["visible_text_count"],
                "after": row["image"].removeprefix("technical/"),
                "after_raw_text_count": row["visible_text_count"],
                "reader_open": row["reader_open"],
            }
        )
    assert len(pairs) == 10
    (technical / "paired-stills.json").write_text(json.dumps(pairs, indent=2) + "\n")
    table = [
        "# Technical evidence — contains scenario meanings",
        "",
        f"Production: `{revision}`. Reader participants receive only the sibling `reader/` directory.",
        "",
        "All eight designed states execute unchanged shipped cards through actual production callbacks and core rules.",
        "The older Committee End-of-Turn variant remains in its original packet and is not used here.",
        "No cold-reader result is claimed by capture or validation.",
        "Every final frame is captured two fixed ticks beyond the cue duration, with the helper inactive "
        "and no visible action overlay remaining (asserted in capture and report).",
        "Tier-up emits no recruit-log event in the current core; its actual empty stream is preserved, "
        "and tier/gold are checked directly.",
        "",
        "| Case | Action | Mode | Cue duration |",
        "| --- | --- | --- | --- |",
    ]
    table.extend(
        f"| {row['reader_label']} | {row['action']} | {row['mode']} | {row['duration']:.3f}s |" for row in manifests
    )
    table += [
        "",
        "## Words and labels at rest",
        "",
        "Every live visible text node remains counted, including numeric stats and hero Health.",
        "The separate tile-word classifier scopes shop, hand and both boards by actual widget ownership.",
        "The original <=40 recruit/scout gate remains on its defined states. The full ten-card fan is a separate "
        "stress edge case: all hand stats remain, its full raw count is reported, and no occlusion exemption is used.",
        "An open-reader row is reported separately from the resting-view gate.",
        "It cannot detect lettering inside raster art; the report requires a separate native visual audit.",
        "The ten spec rows link unchanged historical before images to fresh matching afters in paired-stills.json.",
        "",
        "| State | Stage | Size | All text nodes | Tile words | Legacy-name words |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for row in rest["captures"]:
        words = row["tile_words"]
        table.append(
            f"| {row['reader_label']} | {row['stage']} | {'x'.join(map(str, row['pixels']))} | "
            f"{row['visible_text_count']} | {words['word_count']} | {words['legacy_fallback_word_count']} |"
        )
    (technical / "README.md").write_text("\n".join(table) + "\n")
    neutral = [
        "# Bramble",
        "",
        "Read the Rules pages first. Then view each sequence from left to right, top row first.",
        "For each sequence, describe what you think happened and anything you could not tell.",
        "",
        "## Rules",
        "",
    ]
    neutral += [f"[Page {index}](rules/{index:02d}.jpg)" for index in range(1, 15)]
    neutral += ["", "## Sequences", "", "| Sequence | x1 | Reduce motion |", "| --- | --- | --- |"]
    neutral += [f"| {label} | [x1]({label}-x1.jpg) | [Reduce]({label}-reduce.jpg) |" for label in "ABCDEFGH"]
    (reader / "README.md").write_text("\n".join(neutral) + "\n")
    report = {
        "production_revision": revision,
        "sheets": manifests,
        "native_frames": 128,
        "same_actual_core_events_and_states_across_modes": True,
        "resting_rows": len(rest["captures"]),
        "zero_unexpected_tile_words_all_rows": True,
        "all_last_frames_action_helper_inactive_and_no_visible_action_overlay": True,
        "cold_reader_performed": False,
        "reader_packet": "reader/",
        "technical_answer_key": "technical/",
    }
    (technical / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Sixteen neutral sheets;128 frames;44 resting rows; core/visual bead assertions pass")


def faces(packet: Path, revision: str) -> None:
    technical = packet / "technical"
    path = technical / "all-unit-board-faces.json"
    data = read_json(path)
    root = Path(__file__).resolve().parents[3]
    definitions = {
        value["id"]: value
        for item in (root / "content/units").glob("*.json")
        for value in [read_json(item)]
    }
    assert 'const SLICE: String = "slice"' in (root / "src/core/game_config.gd").read_text()
    shipped = [entry for entry in data["entries"] if definitions[entry["def_id"]].get("set", "") == "slice"]
    assert len(shipped) >= 120 and not any(entry["fallback_name_shown"] for entry in shipped)
    with Image.open(technical / "all-unit-board-faces.jpg") as image:
        width = image.width // data["columns"]
        height = image.height // ((data["unit_count"] + data["columns"] - 1) // data["columns"])
        sheet = Image.new(image.mode, (image.width, height * ((len(shipped) + 9) // 10)))
        for index, entry in enumerate(shipped):
            x, y = entry["column"] * width, entry["row"] * height
            sheet.paste(image.crop((x, y, x + width, y + height)), (index % 10 * width, index // 10 * height))
        sheet.save(technical / "shipped-unit-board-faces.jpg", quality=85, optimize=True)
    shares = [entry["art_rect_share"] for entry in shipped]
    result = {
        "production_revision": revision,
        "card_set": "slice",
        "shipped_count": len(shipped),
        "shipped_fallback_names": [],
        "legacy_count": data["unit_count"] - len(shipped),
        "tile_canvas": data["tile_canvas"],
        "art_rect_share": {"minimum": min(shares), "mean": statistics.mean(shares), "maximum": max(shares)},
        "method": (
            "Exact actual CardView pixels, shipped-set cells repacked offline. "
            "Art rectangle share includes any lettering baked into art; native visual audit remains necessary."
        ),
        "entries": shipped,
    }
    (technical / "shipped-unit-board-faces.json").write_text(json.dumps(result, indent=2) + "\n")
    print("Shipped faces", len(shipped), "art rectangle shares", result["art_rect_share"])


def history(packet: Path, revision: str, slot_log: Path) -> None:
    with slot_log.open(newline="") as stream:
        runs = list(csv.DictReader(stream))
    assert len(runs) >= 2 and all(row["exit"] == "0" for row in runs[-2:]), runs
    result = {
        "production_revision": revision,
        "capture_runs_sequential": True,
        "all_capture_exit_zero": all(row["exit"] == "0" for row in runs),
        "failed_capture_attempts": sum(row["exit"] != "0" for row in runs),
        "runs": runs,
        "source": str(slot_log),
        "scope": "This fresh packet capture and face audit only; targeted tests are reported separately.",
    }
    (packet / "technical/process-history.json").write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["assemble", "faces", "history"])
    parser.add_argument("packet", type=Path)
    parser.add_argument("revision")
    parser.add_argument("--raw", type=Path)
    parser.add_argument("--slot-log", type=Path)
    arguments = parser.parse_args()
    if arguments.stage == "assemble":
        assert arguments.raw is not None
        assemble(arguments.packet, arguments.raw, arguments.revision)
    elif arguments.stage == "faces":
        faces(arguments.packet, arguments.revision)
    else:
        assert arguments.slot_log is not None
        history(arguments.packet, arguments.revision, arguments.slot_log)
