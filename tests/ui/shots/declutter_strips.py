#!/usr/bin/env python3
"""Build eight-native-frame contact strips from declutter_frames.gd manifests."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("frames", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    summary = []
    for source in sorted(args.frames.glob("*/manifest.json")):
        manifest = json.loads(source.read_text())
        destination = args.output / source.parent.name
        destination.mkdir(parents=True, exist_ok=True)
        width, height = manifest["pixels"]
        for attack in manifest["attacks"]:
            assert len(attack["frames"]) == 8
            strip = Image.new("RGB", (width * 4, (height + 40) * 2), "#eee4c6")
            draw = ImageDraw.Draw(strip)
            for index, frame in enumerate(attack["frames"]):
                x = index % 4 * width
                y = index // 4 * (height + 40)
                with Image.open(source.parent / frame["file"]) as image:
                    assert image.size == (width, height)
                    strip.paste(image.convert("RGB"), (x, y + 40))
                relative = frame["seconds"] - attack["start_tick"] * manifest["fixed_step"]
                draw.text((x + 12, y + 10), f"{index + 1}/8  +{relative:.3f} s", fill="#2d271c")
            filename = f"attack-{attack['event_index']:03}.jpg"
            strip.save(destination / filename, quality=70, optimize=True, progressive=True)
            attack["strip"] = filename
        # Keep rerun timing and source events with the sheets; reviewer receives sheets only.
        (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        summary.append(
            {
                "run": source.parent.name,
                "attacks": len(manifest["attacks"]),
                "speed": manifest["speed"],
                "reduce_motion": manifest["reduce_motion"],
            }
        )
        print(f"declutter strips: {source.parent.name} attacks={len(manifest['attacks'])}")
    (args.output / "runs.json").write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
