#!/usr/bin/env python3
"""Stream full fight results, comparing state bytes before parsing mismatch diagnostics."""

import argparse
from contextlib import ExitStack
import hashlib
import itertools
import json
import sys
from pathlib import Path


def first_path(expected, actual, path="$", by_value=False):
    if by_value and {type(expected), type(actual)} == {int, float}:
        return None if expected == actual else (path, expected, actual)
    if type(expected) is not type(actual):
        return path, expected, actual
    if isinstance(expected, dict):
        for key in sorted(expected.keys() | actual.keys()):
            child = f"{path}[{json.dumps(key, ensure_ascii=False)}]"
            if key not in expected:
                return child, "<missing>", actual[key]
            if key not in actual:
                return child, expected[key], "<missing>"
            difference = first_path(expected[key], actual[key], child, by_value)
            if difference:
                return difference
    elif isinstance(expected, list):
        if len(expected) != len(actual):
            return path + ".length", len(expected), len(actual)
        for index, (left, right) in enumerate(zip(expected, actual)):
            difference = first_path(left, right, f"{path}[{index}]", by_value)
            if difference:
                return difference
    elif expected != actual:
        return path, expected, actual
    return None


def read_result(line, source, number, require_trace):
    result = json.loads(line)
    if not isinstance(result, dict):
        raise ValueError(f"{source}:{number}: result must be an object")
    if require_trace and not isinstance(result.get("trace"), list):
        raise ValueError(f"{source}:{number}: missing event trace")
    if "error" not in result:
        for key in ("id", "winner", "loser", "damage", "reason", "state", "hash"):
            if key not in result:
                raise ValueError(f"{source}:{number}: missing {key}")
        state = result["state"]
        if not isinstance(state, str):
            raise ValueError(f"{source}:{number}: state must be a string")
        digest = hashlib.sha256(state.encode("utf-8")).hexdigest()
        if digest != result["hash"]:
            raise ValueError(f"{source}:{number}: hash does not match state bytes")
    return result


def short(value):
    text = repr(value)
    return text if len(text) <= 240 else text[:237] + "..."


def compare(expected_path, actual_paths, require_trace=False, trace_values=False):
    count = 0
    state_bytes = 0
    events = 0
    with ExitStack() as stack:
        expected_file = stack.enter_context(expected_path.open(encoding="utf-8"))
        shards = (stack.enter_context(path.open(encoding="utf-8")) for path in actual_paths)
        actual_lines = itertools.chain.from_iterable(shards)
        for number, (left, right) in enumerate(itertools.zip_longest(expected_file, actual_lines), 1):
            if left is None or right is None:
                raise ValueError(f"line {number}: different result counts")
            expected = read_result(left, expected_path, number, require_trace)
            actual = read_result(right, "Rust results", number, require_trace)
            # Compare exact state strings and every other payload field. Parsing state is
            # diagnostic only; a parse/reserialize must never make unequal bytes pass.
            if trace_values:
                # GDScript prints a number restored from JSON as 1.0 where Rust prints 1.
                # The state string is still compared byte for byte.
                plain = lambda result: {k: v for k, v in result.items() if k != "trace"}
                difference = first_path(plain(expected), plain(actual)) or first_path(
                    expected.get("trace"), actual.get("trace"), '$["trace"]', True
                )
            else:
                difference = first_path(expected, actual)
            if difference:
                path, wanted, got = difference
                if expected.get("state") != actual.get("state") and "state" in expected:
                    before = expected["state"].encode("utf-8")
                    after = actual.get("state", "").encode("utf-8")
                    offset = next(
                        (i for i, pair in enumerate(zip(before, after)) if pair[0] != pair[1]),
                        min(len(before), len(after)),
                    )
                    nested = first_path(
                        json.loads(expected["state"]), json.loads(actual["state"])
                    )
                    if nested:
                        path, wanted, got = nested
                    else:
                        path, wanted, got = "state serialization", before[offset:offset + 80], after[offset:offset + 80]
                    print(f"state byte offset={offset}", file=sys.stderr)
                raise ValueError(
                    f"line {number} id={expected.get('id')}: {path}: "
                    f"expected {short(wanted)}, got {short(got)}"
                )
            count += 1
            state_bytes += len(expected.get("state", "").encode("utf-8"))
            events += len(expected.get("trace", []))
    print(f"fight_compare matched={count} state_bytes={state_bytes} events={events}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-trace", action="store_true", help="require an event array on every result")
    parser.add_argument(
        "--trace-values",
        action="store_true",
        help="compare event numbers by value, so 1.0 matches 1",
    )
    parser.add_argument("expected", type=Path)
    parser.add_argument("actual", type=Path, nargs="+")
    args = parser.parse_args()
    try:
        compare(
            args.expected,
            args.actual,
            require_trace=args.require_trace,
            trace_values=args.trace_values,
        )
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
