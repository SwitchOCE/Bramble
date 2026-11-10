#!/usr/bin/env python3
"""Matched label/pocket measurements and an auditable semantic free-surface mask."""

import argparse
import hashlib
import json
import math
import shutil
from pathlib import Path

from declutter_evidence import original_image, read_json
from PIL import Image, ImageDraw


def merge_baseline(packet, temporary):
    """Preserve original PNG bytes; add missing scenes and metadata from d400 replay."""
    report = []
    for manifest in sorted((temporary / "before").glob("manifest-*.json")):
        value = read_json(manifest)
        for capture in value["captures"]:
            source = temporary / "before" / capture["file"]
            target = packet / "before" / capture["file"]
            identical = True
            if target.exists() and capture["scenario"] not in {"lobby", "scout"}:
                with Image.open(source) as a, Image.open(original_image(target)) as b:
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
            manifest = read_json(path)
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
    "fallback_names": "Tile name labels whose unit lacks its own portrait; no shipped exceptions remain.",
    "costs_and_controls": (
        "Known card/item price fields, hero-power prices, gold and queued-income amounts, and "
        "rendered action-button text/cost descendants."
    ),
    "other": (
        "Every remaining visible text node, including tiers, Ring stacks, Belly/Hex counters, "
        "Midsummer, away text, turn labels, and reader identity/rules text."
    ),
}
CONFUSABLE_PORTRAITS = {}


def budget_breakdown(packet, classified_run, revision, output_stem="budget-breakdown", stage="current"):
    """Publish live ownership classifications; never infer roles from printed digits."""
    raw = read_json(classified_run)
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
            "Every shipped unit now has its own portrait, including the approved Grizel reroll. "
            "No shipped tile name exceptions remain. The former Brock/Old Brock/Sable/Russet and "
            "Brother Wolf/Grizel exceptions are no longer used. Synthetic "
            "missing-art test cards still count as fallback names; no name is excluded from the cap."
        ),
        "",
        (
            "The unchanged legacy slice fixture also contains legacy unit IDs without individual "
            "portraits: its recruit/scout fallback names remain visible and count toward the same cap."
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


TILE_ZONES = ("shop", "hand", "own_board", "scout_board")


def tile_word_breakdown(packet, classified_run, revision, output_stem="tile-words", stage="current"):
    """Publish lexical tile words without changing or substituting for the raw label budget."""
    raw = read_json(classified_run)
    captures = raw["captures"]
    seen = set()
    for capture in captures:
        words = capture["words"]
        zones = dict.fromkeys(TILE_ZONES, 0)
        legacy = 0
        for word in words:
            assert word["zone"] in zones
            assert all(key in word for key in ("word", "node", "path", "text", "tile_path", "def_id"))
            zones[word["zone"]] += 1
            legacy += int(word["allowed_legacy_fallback"])
        assert zones == capture["zone_counts"]
        assert sum(zones.values()) == capture["word_count"] == len(words)
        assert legacy == capture["legacy_fallback_word_count"]
        assert len(words) - legacy == capture["unexpected_word_count"]
        details = capture.get("raw_label_breakdown")
        if details is not None:
            nodes = details["visible_text_nodes"]
            assert details["raw_count"] == len(nodes) == capture["raw_visible_text_count"]
            counts = dict.fromkeys(LABEL_CATEGORIES, 0)
            for node in nodes:
                assert node["category"] in counts
                counts[node["category"]] += 1
            assert counts == details["counts"]
        capture["text_node_gate_pass"] = capture["unexpected_word_count"] == 0 and (
            capture.get("legacy_fixture", False) or capture["word_count"] == 0
        )
        key = (capture["scenario"], tuple(capture["pixels"]))
        assert key not in seen, key
        seen.add(key)
    required = {
        (scenario, pixels)
        for scenario in ("overview", "natural-birds", "lobby", "scout", "reader-reel_mistress-golden", "fan10")
        for pixels in ((1688, 780), (1920, 1080))
    }
    roster = raw.get("roster", {})
    above_forty = [
        {
            "scenario": capture["scenario"],
            "pixels": capture["pixels"],
            "raw_visible_text_count": capture["raw_visible_text_count"],
        }
        for capture in captures
        if not capture.get("reader_open", False) and capture["raw_visible_text_count"] > 40
    ]
    report = {
        "schema": 1,
        "source_revision": revision,
        "capture_stage": stage,
        "classification_input": str(classified_run),
        "method": (
            "Live visible Label, RichTextLabel and rendered Button text. Scope follows actual "
            "CardView zones, HandFan ownership and BoardView ancestry, including slot/name strips. "
            "HUD and CardDetail reader text are outside tile scope. Letter-containing tokens count "
            "as words, including F1; signed/fractional numbers and compact k/m/b stat numbers do not. "
            "Every word retains its node, full path, zone, tile path, source text and unit identity."
        ),
        "legacy_policy": (
            "The unchanged legacy slice uses unit IDs without individual art. Their fallback name "
            "words are explicitly listed and counted; only those missing-art names are allowed. "
            "No shipped portrait exceptions remain."
        ),
        "raw_budget_policy": (
            "The <=40 gate applies to its defined recruit/scout budget states and is unchanged. "
            "The user authorized fan10 as an edge case: it keeps every hand stat, reports all 61 "
            "raw text nodes, and passes the separate zero-tile-words check. Its 61 is not a failure "
            "of the defined budget-state test. No occlusion or focus-only exclusion is applied."
        ),
        "raster_policy": (
            "Raster lettering and text drawn directly by custom drawing are not discoverable from "
            "TextNodes. This automated count is not a claim of zero words in pixels: a native-size "
            "visual audit of tile art, stamps and custom drawing remains required."
        ),
        "native_visual_audit": "required separately; not performed by this counter",
        "above_forty_label_rows": above_forty,
        "raw_label_details_complete": all("raw_label_breakdown" in capture for capture in captures),
        "coverage": {
            "required_state_size_rows": len(required),
            "present_state_size_rows": len(required & seen),
            "complete_packet_and_fan10": required <= seen,
        },
        "roster": roster,
        "fan10_state": raw.get("fan10_state", {}),
        "captures": captures,
    }
    packet.mkdir(parents=True, exist_ok=True)
    if Path(output_stem).name != output_stem:
        raise ValueError("tile-word output stem must be a basename")
    (packet / (output_stem + ".json")).write_text(json.dumps(report, indent=2) + "\n")
    lines = [
        "# Tile words at rest: text-node audit",
        "",
        f"Revision: `{revision}`. Capture stage: {stage}.",
        "",
        (
            "| Scenario | Pixels | Shop | Hand | Own board | Scout board | All words | Legacy names | "
            "Unexpected words | Raw labels | Words check |"
        ),
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |",
    ]
    for capture in captures:
        counts = " | ".join(str(capture["zone_counts"][zone]) for zone in TILE_ZONES)
        pixels = "x".join(str(value) for value in capture["pixels"])
        lines.append(
            f"| {capture['scenario']} | {pixels} | {counts} | {capture['word_count']} | "
            f"{capture['legacy_fallback_word_count']} | {capture['unexpected_word_count']} | "
            f"{capture['raw_visible_text_count']} | {'PASS' if capture['text_node_gate_pass'] else 'FAIL'} |"
        )
    lines.extend(
        [
            "",
            report["method"],
            "",
            report["legacy_policy"],
            "",
            report["raw_budget_policy"],
            "",
            "**Native visual audit still required.** " + report["raster_policy"],
            "",
            (
                f"Packet and fan10 coverage: {len(required & seen)}/{len(required)} state/size rows. "
                f"Shipped roster: {roster.get('unit_count', 'not run')} units across "
                f"{roster.get('zone_count', 'not run')} tile zones and "
                f"{roster.get('variant_count', 'not run')} normal/golden variants, "
                f"{roster.get('word_count', 'not run')} text-node words."
            ),
        ]
    )
    if above_forty:
        lines.extend(["", "User-authorized full-hand edge case, outside the defined budget states:", ""])
        for capture in above_forty:
            pixels = "x".join(str(value) for value in capture["pixels"])
            lines.append(f"- {capture['scenario']} at {pixels}: {capture['raw_visible_text_count']} labels.")
    detailed = [capture for capture in captures if "raw_label_breakdown" in capture]
    lines.extend(["", "## Raw label categories", ""])
    if detailed:
        lines.extend(
            [
                "| Scenario | Pixels | Unit stats | Hero Health | Fallback names | Costs and controls | Other | All |",
                "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
            ]
        )
        for capture in detailed:
            details = capture["raw_label_breakdown"]
            pixels = "x".join(str(value) for value in capture["pixels"])
            fields = " | ".join(str(details["counts"][category]) for category in LABEL_CATEGORIES)
            lines.append(f"| {capture['scenario']} | {pixels} | {fields} | {details['raw_count']} |")
        fan = next((capture for capture in detailed if capture["scenario"] == "fan10"), None)
        if fan is not None:
            lines.extend(
                [
                    "",
                    "Every raw fan10 node at the first size is listed below; JSON retains both sizes.",
                    "",
                    "| Category | Text | Path | Owner field |",
                    "| --- | --- | --- | --- |",
                ]
            )
            for node in fan["raw_label_breakdown"]["visible_text_nodes"]:
                fields = [node["category"], node["text"], node["path"], node["classification_field"]]
                fields = [str(value).replace("|", "\\|").replace("\n", " / ") for value in fields]
                lines.append("| " + " | ".join(fields) + " |")
    else:
        lines.append("Per-node raw category metadata will be supplied by the final live captures.")
    lines.extend(
        [
            "",
            "## Every counted word",
            "",
            "| Scenario | Pixels | Zone | Word | Node | Path | Allowed missing-art name |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    for capture in captures:
        pixels = "x".join(str(value) for value in capture["pixels"])
        for word in capture["words"]:
            fields = [capture["scenario"], pixels, word["zone"], word["word"], word["node"], word["path"]]
            fields = [str(value).replace("|", "\\|").replace("\n", " / ") for value in fields]
            lines.append("| " + " | ".join(fields) + f" | {word['allowed_legacy_fallback']} |")
    if not any(capture["words"] for capture in captures):
        lines.extend(["", "No words were found in live tile text nodes."])
    (packet / (output_stem + ".md")).write_text("\n".join(lines) + "\n")
    print("Audited", len(captures), "tile-word rows; per-zone and exception sums verified")


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("packet", type=Path)
    p.add_argument("--merge-baseline", type=Path)
    p.add_argument("--measure", action="store_true")
    p.add_argument("--budget-breakdown-run", type=Path)
    p.add_argument("--revision", default="working tree; revision not supplied")
    p.add_argument("--budget-output-stem", default="budget-breakdown")
    p.add_argument("--budget-stage", default="current")
    p.add_argument("--tile-words-run", type=Path)
    p.add_argument("--tile-output-stem", default="tile-words")
    p.add_argument("--tile-stage", default="current")
    a = p.parse_args()
    if a.merge_baseline:
        merge_baseline(a.packet, a.merge_baseline)
    if a.measure:
        measure(a.packet)

    if a.budget_breakdown_run:
        budget_breakdown(a.packet, a.budget_breakdown_run, a.revision, a.budget_output_stem, a.budget_stage)
    if a.tile_words_run:
        tile_word_breakdown(a.packet, a.tile_words_run, a.revision, a.tile_output_stem, a.tile_stage)
