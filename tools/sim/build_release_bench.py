#!/usr/bin/env python3
"""Pack the bench for an official Godot Linux release template, preserving game/search rules.

Usage: build_release_bench.py <linux_release.x86_64> <output-dir> [--godot godot] [--driver path]
The editor must already have imported this project. The release template cannot use --script;
only the driver lifecycle is adapted: SceneTree/_initialize/quit -> Node/_ready/get_tree().quit.
Core, content and registry scripts are copied unchanged into an immutable PCK. Run the output
with --headless -- suite=head_to_head ... (all usual bench user arguments).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--driver", type=Path, default=Path("tools/sim/bench.gd"))
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    out = args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    binary = out / "godot-release"
    shutil.copyfile(args.template, binary)
    binary.chmod(0o755)
    manifest = []
    for folder in ("src/core", "content", "tools/sim"):
        for path in sorted((root / folder).rglob("*")):
            if path.is_file() and path.suffix in {".gd", ".json"}:
                manifest.append({"dest": str(path.relative_to(root)), "src": str(path)})
    driver = (root / args.driver).read_text(encoding="utf-8")
    assert "extends SceneTree" in driver and "func _initialize()" in driver
    driver = driver.replace("extends SceneTree", "extends Node").replace("func _initialize()", "func _ready()")
    driver = "class_name BenchDriver\n" + re.sub(r"\bquit\(", "get_tree().quit(", driver)
    (out / "bench_driver.gd").write_text(driver, encoding="utf-8")
    cache = (root / ".godot/global_script_class_cache.cfg").read_text(encoding="utf-8")
    entry = (
        'list=[{\n"base": &"Node",\n"class": &"BenchDriver",\n"icon": "",\n'
        '"is_abstract": false,\n"is_tool": false,\n"language": &"GDScript",\n'
        '"path": "res://tools/sim/bench_driver.gd"\n}, {'
    )
    (out / "class_cache.cfg").write_text(cache.replace("list=[{", entry, 1), encoding="utf-8")
    (out / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="Bot bench release"\n'
        'run/main_scene="res://bench_driver.tscn"\n[debug]\nfile_logging/enable_file_logging=false\n',
        encoding="utf-8",
    )
    (out / "bench_driver.tscn").write_text(
        "[gd_scene load_steps=2 format=3]\n"
        '[ext_resource type="Script" path="res://tools/sim/bench_driver.gd" id="1"]\n'
        '[node name="Bench" type="Node"]\nscript = ExtResource("1")\n',
        encoding="utf-8",
    )
    for dest, source in (
        ("tools/sim/bench_driver.gd", "bench_driver.gd"),
        (".godot/global_script_class_cache.cfg", "class_cache.cfg"),
        ("project.godot", "project.godot"),
        ("bench_driver.tscn", "bench_driver.tscn"),
    ):
        manifest.append({"dest": dest, "src": str(out / source)})
    (out / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    source_hashes = {entry["dest"]: hashlib.sha256(Path(entry["src"]).read_bytes()).hexdigest() for entry in manifest}
    (out / "source-sha256.json").write_text(json.dumps(source_hashes, indent=2) + "\n", encoding="utf-8")
    # JSON string literals are also valid GDScript string literals here.
    script = f"""extends SceneTree
func _initialize() -> void:
	var pack := PCKPacker.new()
	assert(pack.pck_start({json.dumps(str(out / "godot-release.pck"))}) == OK)
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string({json.dumps(str(out / "manifest.json"))}))
	for item: Dictionary in entries:
		assert(pack.add_file(str(item["dest"]), str(item["src"])) == OK)
	assert(pack.flush() == OK)
	quit()
"""
    (out / "pack.gd").write_text(script, encoding="utf-8")
    subprocess.run([args.godot, "--headless", "--path", str(root), "-s", str(out / "pack.gd")], check=True, timeout=60)
    hashes = {
        name: hashlib.sha256((out / name).read_bytes()).hexdigest() for name in ("godot-release", "godot-release.pck")
    }
    (out / "runtime-sha256.json").write_text(json.dumps(hashes, indent=2) + "\n", encoding="utf-8")
    (out / "bench-godot").write_text(
        "#!/usr/bin/env bash\nset -euo pipefail\nargs=()\n"
        'while [ "$#" -gt 0 ]; do\n'
        '  case "$1" in\n'
        "    --path|-s|--script) shift 2 ;;\n"
        '    *) args+=("$1"); shift ;;\n'
        "  esac\ndone\n"
        'runtime_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\n'
        'exec "$runtime_dir/godot-release" "${args[@]}"\n',
        encoding="utf-8",
    )
    (out / "bench-godot").chmod(0o755)
    print(json.dumps(hashes))


if __name__ == "__main__":
    main()
