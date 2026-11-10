#!/usr/bin/env python3
"""New focus-followup packet; immutable parent before evidence is referenced, never rewritten."""

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from declutter_b2_report import LABEL_CATEGORIES, budget_breakdown, mask_capture
from PIL import Image

from declutter_evidence import original_image, read_json


def file_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(packet: Path) -> None:
    parent = packet.parent
    packet.mkdir(parents=True, exist_ok=True)
    source = parent / "states.json"
    destination = packet / "states.json"
    if destination.exists():
        assert destination.read_bytes() == source.read_bytes(), "follow-up input differs from pinned parent input"
    else:
        shutil.copy2(source, destination)
    guarded = [source, *sorted((parent / "before").rglob("*"))]
    hashes = {str(path.relative_to(parent)): file_hash(path) for path in guarded if path.is_file()}
    path = packet / "input-provenance.json"
    record = {
        "parent_packet": "..",
        "state_source": "../states.json",
        "states_sha256": file_hash(source),
        "parent_before_policy": "Reference ../before images and manifests; no baseline rerender or rewrite.",
        "guarded_parent_sha256": hashes,
    }
    if path.exists():
        assert read_json(path) == record, "parent baseline evidence changed"
    else:
        path.write_text(json.dumps(record, indent=2) + "\n")
    print("Pinned identical states and", len(hashes), "immutable parent inputs/before artifacts")


def verify_parent(packet: Path) -> None:
    record = read_json(packet / "input-provenance.json")
    assert file_hash(packet / "states.json") == record["states_sha256"]
    for relative, expected in record["guarded_parent_sha256"].items():
        assert file_hash(packet.parent / relative) == expected, relative


def stills(packet: Path, revision: str) -> None:
    verify_parent(packet)
    pairs = []
    classified = []
    for dimensions in ["1688x780", "1920x1080"]:
        before_path = packet.parent / "before" / ("manifest-" + dimensions + ".json")
        after_path = packet / "after" / ("manifest-" + dimensions + ".json")
        before = read_json(before_path)
        after = read_json(after_path)
        old = {capture["scenario"]: capture for capture in before["captures"]}
        for capture in after["captures"]:
            scenario = capture["scenario"]
            original = old[scenario]
            assert capture["state_sha256"] == original["state_sha256"], scenario
            mask_capture(packet / "after", capture, after["pixels"])
            nodes = capture["visible_text_nodes"]
            assert capture["visible_text_count"] == len(nodes)
            counts = dict.fromkeys(LABEL_CATEGORIES, 0)
            for node in nodes:
                assert node["category"] in counts
                counts[node["category"]] += 1
            assert sum(counts.values()) == len(nodes)
            reader_open = scenario.startswith("reader-")
            classified.append(
                {
                    "scenario": scenario,
                    "pixels": after["pixels"],
                    "reader_open": reader_open,
                    "raw_count": len(nodes),
                    "counts": counts,
                    "visible_text_nodes": nodes,
                    "image": "after/" + capture["file"],
                }
            )
            pairs.append(
                {
                    "scenario": scenario,
                    "pixels": after["pixels"],
                    "same_serialized_state": True,
                    "state_sha256": capture["state_sha256"],
                    "source": capture["source"],
                    "reader_open": reader_open,
                    "resting_budget_pass": None if reader_open else len(nodes) <= 40,
                    "before": {
                        "image": "../before/" + original["file"],
                        "manifest": "../before/" + before_path.name,
                        "labels": original["visible_text_count"],
                        "pocket_canvas": original["pocket_canvas"],
                        "calm_space_share": original["calm_space_share"],
                        "mask": "../before/" + original["calm_space_mask"],
                    },
                    "after": {
                        "image": "after/" + capture["file"],
                        "labels": len(nodes),
                        "category_counts": counts,
                        "pocket_canvas": capture["pocket_canvas"],
                        "calm_space_share": capture["calm_space_share"],
                        "mask": "after/" + capture["calm_space_mask"],
                    },
                }
            )
            print(dimensions, scenario, original["visible_text_count"], "->", len(nodes), counts)
        after["production_revision"] = revision
        after_path.write_text(json.dumps(after, indent=2) + "\n")
    assert len(pairs) == 10
    raw = packet / "classified-stills.json"
    raw.write_text(json.dumps({"captures": classified}, indent=2) + "\n")
    budget_breakdown(packet, raw, revision, stage="focus-followup")
    report = {
        "production_revision": revision,
        "parent_baseline_unchanged": True,
        "all_resting_budgets_pass": all(pair["resting_budget_pass"] is not False for pair in pairs),
        "calm_space_method": (
            "Identical semantic free-surface proxy as the parent packet: union visible nonempty text bounds, "
            "card faces, action buttons, art frames, stat/cost badges and gold plaque. Remaining native pixels "
            "are white in the mask. "
            "It measures free surface rather than perceptual complexity; floor carving and grain are not subtracted."
        ),
        "historical_category_policy": (
            "Parent before raw counts and node lists are referenced unchanged; their category split is not guessed. "
            "Current categories come from live owning widget/field metadata and sum to every raw visible text node."
        ),
        "pairs": pairs,
    }
    (packet / "pairs.json").write_text(json.dumps(report, indent=2) + "\n")


def finish(packet: Path, revision: str) -> None:
    verify_parent(packet)
    runs = read_json(packet / "strips" / "runs.json")
    assert len(runs) == 6 and sum(run["frames"] for run in runs) == 48
    hashes = set()
    for path in sorted((packet / "strips").glob("*/manifest.json")):
        value = read_json(path)
        value["production_revision"] = revision
        if value["name"].startswith("end-turn"):
            assert value["final_stats_equal_core"]
            hashes.add(value["events_sha256"])
        else:
            assert value["lent_quarry_target_only_and_then_clears"]
        path.write_text(json.dumps(value, indent=2) + "\n")
    assert len(hashes) == 1
    faces_path = packet / "all-unit-board-faces.json"
    faces = read_json(faces_path)
    faces["production_revision"] = revision
    faces_path.write_text(json.dumps(faces, indent=2) + "\n")
    # Repack rendered cells without rerendering or changing any actual card pixels.
    root = Path(__file__).resolve().parents[3]
    definitions = {
        value["id"]: value
        for path in (root / "content" / "units").glob("*.json")
        for value in [read_json(path)]
    }
    config_source = (root / "src" / "core" / "game_config.gd").read_text()
    assert 'const SLICE: String = "slice"' in config_source
    shipped = [entry for entry in faces["entries"] if definitions[entry["def_id"]].get("set", "") == "slice"]
    assert shipped and not any(entry["fallback_name_shown"] for entry in shipped)
    with Image.open(original_image(packet / "all-unit-board-faces.jpg")) as source:
        cell_width = source.width // faces["columns"]
        cell_height = source.height // ((faces["unit_count"] + faces["columns"] - 1) // faces["columns"])
        sheet = Image.new(source.mode, (source.width, cell_height * ((len(shipped) + 9) // 10)))
        for index, entry in enumerate(shipped):
            left, top = entry["column"] * cell_width, entry["row"] * cell_height
            sheet.paste(
                source.crop((left, top, left + cell_width, top + cell_height)),
                ((index % 10) * cell_width, (index // 10) * cell_height),
            )
        sheet.save(packet / "shipped-unit-board-faces.jpg", quality=85, optimize=True)
    (packet / "shipped-unit-board-faces.json").write_text(
        json.dumps(
            {
                "production_revision": revision,
                "card_set": "slice",
                "unit_count": len(shipped),
                "fallback_names": [],
                "method": (
                    "Exact rendered cells from all-unit-board-faces.jpg, "
                    "filtered by full_game card_set and repacked offline."
                ),
                "source_entries": shipped,
            },
            indent=2,
        )
        + "\n"
    )
    report = {
        "production_revision": revision,
        "parent_baseline_unchanged": True,
        "stills": "pairs.json",
        "budget_breakdown": "budget-breakdown.json",
        "motion_runs": runs,
        "end_turn_events_sha256": next(iter(hashes)),
        "face_unit_count": faces["unit_count"],
        "shipped_face_unit_count": len(shipped),
        "shipped_contact_sheet": "shipped-unit-board-faces.jpg",
        "shipped_fallback_names": [],
        "legacy_unit_count": faces["unit_count"] - len(shipped),
        "fallback_names": [entry["def_id"] for entry in faces["entries"] if entry["fallback_name_shown"]],
        "fresh_cold_reader_run": False,
    }
    (packet / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Final packet:", faces["unit_count"], "faces; six strips/48 frames; parent inputs unchanged")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["prepare", "stills", "finish", "verify"])
    parser.add_argument("packet", type=Path)
    parser.add_argument("revision", nargs="?", default="working tree; no revision supplied")
    args = parser.parse_args()
    {"prepare": prepare, "stills": stills, "finish": finish, "verify": verify_parent}[args.stage](
        *([args.packet, args.revision] if args.stage in {"stills", "finish"} else [args.packet])
    )
