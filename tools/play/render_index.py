"""Writes build/render/<save>/index.md from render.gd's per-size manifests.

Usage: render_index.py <out dir> <save> <commit> <picked turns>
"""

import json
import sys
from pathlib import Path

KIND_WORDS = {
    "start": "turn start",
    "end": "turn end",
    "fight": "fight",
    "over": "game over",
}


def main() -> int:
    out, save, commit, picked = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
    manifests = [json.loads(p.read_text()) for p in sorted(out.glob("manifest_*.json"))]
    if not manifests:
        print("no manifests in", out)
        return 1
    lines = [
        f"# Render of {Path(save).name}",
        "",
        f"- Commit: `{commit}`",
        f"- Save: `{save}`",
        f"- Turns: {picked}",
        f"- Sizes: {', '.join(m['size'] for m in manifests)}",
        "",
        "| Turn | Moment | State hash | Fight | Files |",
        "|---|---|---|---|---|",
    ]
    first = manifests[0]["moments"]
    for i, moment in enumerate(first):
        files = []
        for manifest in manifests:
            if i < len(manifest["moments"]):
                files += manifest["moments"][i]["files"]
            if manifest["moments"][i]["hash"] != moment["hash"]:
                print("sizes disagree on the state at moment", i)
                return 1
        fight = ""
        if "fight" in moment:
            f = moment["fight"]
            fight = f"R{f['round']} vs {f['opponent']}: {f['result']}, {f['damage']} damage"
        links = " ".join(f"[{name}]({name})" for name in files)
        lines.append(
            f"| {moment['round']} | {KIND_WORDS.get(moment['kind'], moment['kind'])} "
            f"| `{moment['hash'][:16]}` | {fight} | {links} |"
        )
    lines += ["", "Full hashes are in the manifest_<size>.json files beside this one."]
    (out / "index.md").write_text("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
