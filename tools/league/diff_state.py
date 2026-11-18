#!/usr/bin/env python3
"""Name the first differing JSON path in Godot/Rust state dumps."""
import argparse
import json
from pathlib import Path


def first_diff(left, right, path="$"):
    if type(left) is not type(right):
        if not isinstance(left, bool) and not isinstance(right, bool):
            if isinstance(left, (int, float)) and isinstance(right, (int, float)) and left == right:
                return None
        return path, left, right
    if isinstance(left, dict):
        for key in sorted(set(left) | set(right)):
            child = f"{path}[{json.dumps(key, ensure_ascii=False)}]"
            if key not in left:
                return child, "<missing>", right[key]
            if key not in right:
                return child, left[key], "<missing>"
            found = first_diff(left[key], right[key], child)
            if found:
                return found
    elif isinstance(left, list):
        for index in range(max(len(left), len(right))):
            child = f"{path}[{index}]"
            if index >= len(left):
                return child, "<missing>", right[index]
            if index >= len(right):
                return child, left[index], "<missing>"
            found = first_diff(left[index], right[index], child)
            if found:
                return found
    elif left != right:
        return path, left, right
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("godot", type=Path)
    parser.add_argument("rust", type=Path)
    opts = parser.parse_args()
    left, right = opts.godot.read_bytes(), opts.rust.read_bytes()
    if left == right:
        print(f"byte-identical: {len(left)} bytes")
        return 0
    found = first_diff(json.loads(left), json.loads(right))
    if found:
        path, a, b = found
        print(f"{path}\n  Godot: {a!r}\n  Rust:  {b!r}")
    else:
        offset = next((i for i, (a, b) in enumerate(zip(left, right)) if a != b), min(len(left), len(right)))
        print(f"JSON values agree; text first differs at byte {offset}: {left[offset:offset+40]!r} / {right[offset:offset+40]!r}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
