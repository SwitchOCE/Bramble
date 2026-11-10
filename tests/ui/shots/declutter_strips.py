#!/usr/bin/env python3
"""Assemble native eight-frame attack, opening cause-group and complete-result strips."""

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


def validate_interval_sampling(interval: dict, event: dict | None = None) -> None:
    """Old manifests remain uniform; explicit new manifests pin observed actor peaks."""
    ticks = interval["sample_ticks"]
    frames = interval["frames"]
    assert len(ticks) == len(frames) == 8
    assert ticks == sorted(set(ticks))
    assert [frame["tick"] for frame in frames] == ticks
    sampling = interval.get("sampling")
    if sampling is None:
        return
    assert sampling["mode"] == "uniform-with-observed-lunge-peaks"
    expected = [
        interval["start_tick"] + round(i * (interval["end_tick"] - interval["start_tick"]) / 7) for i in range(8)
    ]
    assert sampling["uniform_sample_ticks"] == expected
    peaks = sampling["lunge_peaks"]
    assert peaks
    uids = {peak["uid"] for peak in peaks}
    assert len(uids) == len(peaks)
    if event is not None:
        assert uids == {event["attacker"], *event.get("joiners", [])}
    reconstructed = list(expected)
    for replacement in sampling["replacements"]:
        reconstructed.remove(replacement["uniform_tick"])
        reconstructed.append(replacement["peak_tick"])
    assert sorted(reconstructed) == ticks
    for peak in peaks:
        assert peak["tick"] in ticks
        frame = next(frame for frame in frames if frame["tick"] == peak["tick"])
        actual = next(value for value in frame["attack_actor_positions"] if value["uid"] == peak["uid"])
        assert math.dist(actual["position"], peak["position"]) < 0.001
        if peak["kind"] in {"lunge", "held-pose"}:
            assert peak["distance_squared"] > 0


def write_sheet(source: Path, destination: Path, pixels: list, interval: dict, step: float) -> str:
    width, height = pixels
    frames = interval["frames"]
    validate_interval_sampling(interval)
    assert len(frames) == 8
    assert [frame["tick"] for frame in frames] == interval["sample_ticks"]
    strip = Image.new("RGB", (width * 4, (height + 40) * 2), "#eee4c6")
    draw = ImageDraw.Draw(strip)
    for index, frame in enumerate(frames):
        x = index % 4 * width
        y = index // 4 * (height + 40)
        with Image.open(source / frame["file"]) as image:
            assert image.size == (width, height)
            strip.paste(image.convert("RGB"), (x, y + 40))
        relative = frame["seconds"] - interval["start_tick"] * step
        draw.text((x + 12, y + 10), f"{index + 1}/8  +{relative:.3f} s", fill="#2d271c")
    kind = interval["kind"]
    filename = f"{kind}-{interval['event_index']:03}.jpg" if kind in {"attack", "opening-event"} else f"{kind}.jpg"
    strip.save(destination / filename, quality=70, optimize=True, progressive=True)
    return filename


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    summary = []
    for source in sorted(args.frames.glob("*/manifest.json")):
        manifest = json.loads(source.read_text())
        assert manifest["timing_passes_equal"]
        destination = args.output / source.parent.name
        destination.mkdir(parents=True, exist_ok=True)
        opening_effects = manifest.get("opening_effects", [])
        selected_mode = manifest.get("capture_mode") == "selected-attacks"
        if selected_mode:
            assert not any(key in manifest for key in ("opening", "opening_effects", "result"))
            assert {attack["event_index"] for attack in manifest["attacks"]} == set(
                manifest["selected_attack_event_indices"]
            )
            phases = []
            intervals = manifest["attacks"]
        else:
            phases = [manifest["opening"], manifest["result"]]
            intervals = [phases[0], *opening_effects, *manifest["attacks"], phases[1]]
        expected = set()
        for interval in intervals:
            event = manifest["events"][interval["event_index"]] if interval["kind"] == "attack" else None
            validate_interval_sampling(interval, event)
            filename = write_sheet(source.parent, destination, manifest["pixels"], interval, manifest["fixed_step"])
            interval["strip"] = filename
            expected.add(filename)
        # Remove only obsolete outputs of this generator, never unrelated evidence.
        for old in destination.glob("*.jpg"):
            generated = old.name.startswith(("attack-", "opening-event-")) or old.name in {"opening.jpg", "result.jpg"}
            if generated and old.name not in expected:
                old.unlink()
        (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        summary.append(
            {
                "run": source.parent.name,
                "attacks": len(manifest["attacks"]),
                "phase_sheets": len(phases),
                "opening_effect_sheets": len(opening_effects),
                "sheets": len(intervals),
                "frames": len(intervals) * 8,
                "speed": manifest["speed"],
                "reduce_motion": manifest["reduce_motion"],
                "final_health_text": manifest["final_health_text"],
            }
        )
        print(
            f"declutter strips: {source.parent.name} attacks={len(manifest['attacks'])} "
            f"opening/result={len(phases)} opening-effects={len(opening_effects)} sheets={len(intervals)} "
            f"Health={manifest['final_health_text']}"
        )
    (args.output / "runs.json").write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
