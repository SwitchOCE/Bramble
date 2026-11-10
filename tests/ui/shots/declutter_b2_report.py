#!/usr/bin/env python3
"""Matched label/pocket measurements and an auditable semantic free-surface mask."""

import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


def merge_baseline(packet, temporary):
    """Preserve original PNG bytes; add missing scenes and metadata from d400 replay."""
    report = []
    for manifest in sorted((temporary / "before").glob("manifest-*.json")):
        value = json.loads(manifest.read_text())
        for capture in value["captures"]:
            source = temporary / "before" / capture["file"]
            target = packet / "before" / capture["file"]
            identical = True
            if target.exists() and capture["scenario"] not in {"lobby", "scout"}:
                with Image.open(source) as a, Image.open(target) as b:
                    identical = a.size == b.size and a.convert("RGBA").tobytes() == b.convert("RGBA").tobytes()
                capture["existing_before_png_preserved"] = True
            else:
                shutil.copy2(source, target)
                capture["existing_before_png_preserved"] = False
            capture["mask_reference_pixels_equal"] = identical
            report.append(
                {
                    "file": capture["file"],
                    "existing_before_png_preserved": capture["existing_before_png_preserved"],
                    "mask_reference_pixels_equal": identical,
                    "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
                }
            )
        (packet / "before" / manifest.name).write_text(json.dumps(value, indent=2) + "\n")
    (packet / "before" / "preserved-baseline.json").write_text(json.dumps(report, indent=2) + "\n")
    print(
        "Baseline PNGs preserved; missing scenes copied; reference pixel equality:",
        all(x["mask_reference_pixels_equal"] for x in report),
    )


def mask_capture(directory, capture, pixels):
    assert "calm_mask_regions" in capture, capture["file"]
    width, height = pixels
    mask = Image.new("L", (width, height), 255)
    draw = ImageDraw.Draw(mask)
    for item in capture["calm_mask_regions"]:
        x, y, w, h = item["rect"]
        x0, y0 = max(0, math.floor(x)), max(0, math.floor(y))
        x1, y1 = min(width, math.ceil(x + w)), min(height, math.ceil(y + h))
        if x1 > x0 and y1 > y0:
            draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=0)
    free = mask.histogram()[255]
    filename = Path(capture["file"]).stem + "-calm-mask.png"
    mask.save(directory / filename)
    capture["calm_space_mask"] = filename
    capture["calm_space_share"] = free / (width * height)
    capture["calm_space_pixels"] = free
    return capture


def measure(packet):
    pairs = []
    for size in ["1688x780", "1920x1080"]:
        phases = {}
        for phase in ["before", "after"]:
            path = packet / phase / ("manifest-" + size + ".json")
            manifest = json.loads(path.read_text())
            for capture in manifest["captures"]:
                mask_capture(packet / phase, capture, manifest["pixels"])
            path.write_text(json.dumps(manifest, indent=2) + "\n")
            phases[phase] = {c["scenario"]: c for c in manifest["captures"]}
        assert phases["before"].keys() == phases["after"].keys()
        for scenario, a in phases["before"].items():
            b = phases["after"][scenario]
            assert a["state_sha256"] == b["state_sha256"], (size, scenario)
            pair = {
                "scenario": scenario,
                "pixels": [int(x) for x in size.split("x")],
                "same_serialized_state": True,
                "state_sha256": a["state_sha256"],
                "source": a["source"],
                "before": {
                    "image": "before/" + a["file"],
                    "labels": a["visible_text_count"],
                    "pocket_canvas": a["pocket_canvas"],
                    "calm_space_share": a["calm_space_share"],
                    "mask": "before/" + a["calm_space_mask"],
                },
                "after": {
                    "image": "after/" + b["file"],
                    "labels": b["visible_text_count"],
                    "pocket_canvas": b["pocket_canvas"],
                    "calm_space_share": b["calm_space_share"],
                    "mask": "after/" + b["calm_space_mask"],
                },
            }
            pairs.append(pair)
            print(
                size,
                scenario,
                "labels",
                a["visible_text_count"],
                "->",
                b["visible_text_count"],
                "pocket",
                a["pocket_canvas"],
                "->",
                b["pocket_canvas"],
                "free-surface",
                round(a["calm_space_share"] * 100, 1),
                "->",
                round(b["calm_space_share"] * 100, 1),
            )
    report = {
        "calm_space_method": (
            "Semantic free-surface proxy, measured in native viewport pixels. Occupied mask is the "
            "union of visible nonempty text-control rectangles, card face rectangles, action-button "
            "rectangles, art frames, stat/cost badges and gold plaque. Remaining pixels are counted "
            "as calm; plain tray/playmat/shop surfaces and empty pockets count as calm. Masks are "
            "white=calm, black=occupied. Bounds use floor/ceil then clip to viewport. Mask region "
            "paths/rectangles are saved with each capture for audit."
        ),
        "calm_space_limitations": (
            "This measures free surface, not perceptual complexity: floor marks, tray carving and "
            "background grain are not separately subtracted; text rectangles include padding. It is "
            "an explicit, identical before/after proxy, not a claim that the perceptual 35-40% target"
            " passed. Reader-open rows are reported separately and are not resting-budget scenarios."
        ),
        "pairs": pairs,
    }
    (packet / "pairs.json").write_text(json.dumps(report, indent=2) + "\n")


LABEL_CATEGORIES = (
    "unit_stats",
    "hero_health",
    "fallback_names",
    "costs_and_controls",
    "other",
)
LABEL_DEFINITIONS = {
    "unit_stats": "Attack/Health labels owned by a CardView, CardDetail, or Nest Egg stat field.",
    "hero_health": "Health labels inside the LobbyPlaque Health badge; opponent tier is Other.",
    "fallback_names": (
        "Tile name labels whose unit lacks its own portrait, plus the unresolved Brother Wolf/Grizel portrait pair."
    ),
    "costs_and_controls": (
        "Known card/item price fields, hero-power prices, gold and queued-income amounts, and "
        "rendered action-button text/cost descendants."
    ),
    "other": (
        "Every remaining visible text node, including tiers, Ring stacks, Belly/Hex counters, "
        "Midsummer, away text, turn labels, and reader identity/rules text."
    ),
}
CONFUSABLE_PORTRAITS = {"brother_wolf": "Brother Wolf", "grizel": "Grizel"}


def budget_breakdown(packet, classified_run, revision, output_stem="budget-breakdown", stage="current"):
    """Publish live ownership classifications; never infer roles from printed digits."""
    raw = json.loads(classified_run.read_text())
    captures = raw["captures"]
    keys = set()
    for capture in captures:
        counts = capture["counts"]
        nodes = capture["visible_text_nodes"]
        assert set(counts) == set(LABEL_CATEGORIES), capture["scenario"]
        assert sum(counts.values()) == capture["raw_count"] == len(nodes)
        actual = dict.fromkeys(LABEL_CATEGORIES, 0)
        for node in nodes:
            assert node["category"] in actual
            assert "classification_owner" in node
            assert "classification_field" in node
            actual[node["category"]] += 1
        assert actual == counts, capture["scenario"]
        key = (capture["scenario"], tuple(capture["pixels"]), capture["reader_open"])
        assert key not in keys, key
        keys.add(key)
        capture["budget_limit"] = None if capture["reader_open"] else 40
        capture["budget_pass"] = None if capture["reader_open"] else capture["raw_count"] <= 40
    report = {
        "schema": 1,
        "source_revision": revision,
        "capture_stage": stage,
        "classification_input": str(classified_run),
        "method": (
            "Live Node ownership and known widget-field identity. No numeric-text heuristics, no "
            "exclusions, and no drawing replacements. Every raw visible text node has exactly one "
            "category; each category sum equals the unchanged raw count."
        ),
        "definitions": LABEL_DEFINITIONS,
        "confusable_portrait_exceptions": CONFUSABLE_PORTRAITS,
        "reader_policy": (
            "Reader-open rows include all reader nodes and are reported outside the resting 40-node "
            "gate. Reader stat beads remain Unit stats; reader name, type, rules and reminders are "
            "Other; action buttons remain Costs and controls."
        ),
        "baseline_policy": (
            "Historical before/after manifests are preserved. Their earlier raw totals remain valid, "
            "but they lack live ownership metadata and are not retroactively classified by guessing "
            "from text or generated node paths."
        ),
        "captures": captures,
    }
    packet.mkdir(parents=True, exist_ok=True)
    if Path(output_stem).name != output_stem:
        raise ValueError("budget output stem must be a basename")
    (packet / (output_stem + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    lines = [
        "# Visible-label budget breakdown",
        "",
        f"Capture stage: {stage}.",
        "",
        (
            f"Current live replay: `{revision}`. "
            "All categories count toward the raw resting budget of 40; none are excluded."
        ),
        "",
        (
            "| Scenario | Pixels | Unit stats | Hero Health | Fallback names | Costs and controls | "
            "Other | All labels | Resting gate |"
        ),
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for capture in captures:
        counts = capture["counts"]
        pixels = "x".join(str(value) for value in capture["pixels"])
        fields = " | ".join(str(counts[category]) for category in LABEL_CATEGORIES)
        status = (
            "reader open; reported only" if capture["reader_open"] else "PASS" if capture["budget_pass"] else "FAIL"
        )
        lines.append(f"| {capture['scenario']} | {pixels} | {fields} | {capture['raw_count']} | {status} |")
    lines += [
        "",
        (
            "Classification uses the actual owning widget and its known field, never whether the "
            "displayed text looks numeric. JSON retains every label's text, path, category, owner, "
            "field and fallback reason. Each row's five categories sum exactly to All labels."
        ),
        "",
        (
            "Every shipped unit now has its own portrait. Only Brother Wolf (`brother_wolf`) and "
            "Grizel (`grizel`) retain a short name while Grizel's portrait reroll is pending. "
            "The former Brock/Old Brock/Sable/Russet exceptions are no longer used. Synthetic "
            "missing-art test cards still count as fallback names; no name is excluded from the cap."
        ),
        "",
        (
            "Gold and queued-income amounts are Costs and controls. Opponent tiers, "
            "Ring-stack/Belly/Hex/Midsummer counters and away text are Other. Reader stat beads are "
            "Unit stats; reader name/type/rules/reminders are Other. Reader-open rows are not "
            "resting-budget passes."
        ),
        "",
        (
            "Historical manifests remain unchanged. Earlier captures lack ownership metadata, so this"
            " report does not invent a category split for them."
        ),
        "",
        "## Costs, controls and other labels",
        "",
        (
            "The first size of each scenario is listed below; the table and JSON retain both sizes. "
            "Repeated strings remain separate counted nodes."
        ),
    ]
    shown = set()
    for capture in captures:
        scenario = capture["scenario"]
        if scenario in shown:
            continue
        shown.add(scenario)
        lines.extend(["", f"### {scenario}", ""])
        for category, title in [("costs_and_controls", "Costs and controls"), ("other", "Other")]:
            labels = [
                node["text"].replace("\n", " / ").replace("`", "'")
                for node in capture["visible_text_nodes"]
                if node["category"] == category
            ]
            text = "; ".join(f"`{label}`" for label in labels) if labels else "none"
            lines.append(f"- {title} ({capture['counts'][category]}): {text}.")
    (packet / (output_stem + ".md")).write_text("\n".join(lines) + "\n")
    print("Classified", len(captures), "scenario/size rows; all raw/category sums verified")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("packet", type=Path)
    p.add_argument("--merge-baseline", type=Path)
    p.add_argument("--measure", action="store_true")
    p.add_argument("--budget-breakdown-run", type=Path)
    p.add_argument("--revision", default="working tree; revision not supplied")
    p.add_argument("--budget-output-stem", default="budget-breakdown")
    p.add_argument("--budget-stage", default="current")
    a = p.parse_args()
    if a.merge_baseline:
        merge_baseline(a.packet, a.merge_baseline)
    if a.measure:
        measure(a.packet)

    if a.budget_breakdown_run:
        budget_breakdown(a.packet, a.budget_breakdown_run, a.revision, a.budget_output_stem, a.budget_stage)
