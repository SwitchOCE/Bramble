#!/usr/bin/env python3
"""Freeze portable sweep shards; merge all lobbies before selecting global fields.

No command submits cloud work. ``plan`` freezes the input plan, ``run`` executes
one shard, ``merge-lobbies`` builds the required field input bundle, and ``merge``
rebuilds the normal sweep metrics/report. Paths inside exchanged bundles are
relative. Set CLOUD_HARNESS_ROOT to use a different checkout. All merge commands
are Python only; run requires /opt/bramble/env.sh and the pinned Godot toolchain.
"""

from __future__ import annotations

import argparse
import copy
import csv
import gzip
import hashlib
import json
import math
import os
import re
import shlex
import sys
import tempfile
import time
from itertools import chain
from pathlib import Path

import upset_report
from check_lines import head_to_head, line_breakdown, line_outcome_rates
from field import boards_from_capture, field_report, sample_field
from lever_sweep import (
    CAPTURE_SUFFIXES,
    ROOT,
    Sweep,
    SweepError,
    atomic_json,
    canonical,
    combine_csv,
    digest,
    file_sha,
    git,
    jsonl,
    local_path,
    run_command,
    source_manifest,
    stage_plan,
    utc_now,
    validate_capture,
    validate_plan,
    validate_players,
)

SOURCE_PATHS = ["src", "content", "tools/sim/*.gd", "tools/sim/*.py", "project.godot", "tools/versions.env"]
IGNORED_PARTS = frozenset((".godot", "__pycache__", ".git", "build"))
GODOT_VERSION = "4.7.2"
LOCK_PATH = "/tmp/bramble-harness-godot.lock"
TABLES = ("players", "rounds", "cards", "turns", "profile")


def portable_sources(root, patterns):
    """Pin runtime bytes while ignoring generated UID/import/cache sidecars."""
    return {
        name: checksum
        for name, checksum in source_manifest(root, patterns).items()
        if not set(Path(name).parts) & IGNORED_PARTS and not name.endswith((".uid", ".import", ".pyc"))
    }


def fingerprints(root=ROOT, profiles="tools/sim/line_profiles.sweep.json"):
    patterns = list(dict.fromkeys([*SOURCE_PATHS, profiles]))
    return {
        "source_commit": git(root, "rev-parse", "HEAD"),
        "source_paths": patterns,
        "source_fingerprint": digest(portable_sources(root, patterns)),
        "profiles": profiles,
        "profiles_sha256": file_sha(local_path(profiles, root)),
    }


def seal(document, key):
    return {**document, key: digest(document)}


def check_seal(document, key):
    if document.get(key) != digest({name: value for name, value in document.items() if name != key}):
        raise SweepError(f"changed or incomplete document: {key}")


def shard_specs(plan):
    configs = {config["id"]: config for config in plan["configs"]}
    specs = []
    for stage in stage_plan(plan):
        if stage["kind"] not in ("lobbies", "field", "head"):
            continue
        stage = {**stage, "config_sha256": digest(configs[stage["config"]])}
        if stage["kind"] == "lobbies":
            stage["estimate_seconds"] = 135  # 50 * measured baseline 2.5 s/lobby + startup.
        elif stage["kind"] == "field":
            size = configs[stage["config"]]["field_size"]
            fights = size * (size - 1) // 2 * 16
            stage["estimate_seconds"] = math.ceil(fights * 0.0076 + 10)
        specs.append(stage)
    for config in plan["configs"]:
        diagnostic = config.get("upset_diagnostic")
        if diagnostic is not None:
            seeds = diagnostic.get("seeds") if isinstance(diagnostic, dict) else None
            if (
                not isinstance(seeds, list)
                or len(seeds) != 8
                or any(not isinstance(value, str) or not re.fullmatch(r"-?\d+", value) for value in seeds)
                or len({int(value) for value in seeds}) != 8
                or any(str(int(value)) != value for value in seeds)
                or any(not -(2**63) <= int(value) < 2**63 for value in seeds)
            ):
                raise SweepError("upset_diagnostic requires eight distinct signed-64-bit integer seed strings")
            specs.append(
                {
                    "id": f"{config['id']}/upset",
                    "config": config["id"],
                    "kind": "upset",
                    "seeds": seeds,
                    "estimate_seconds": 40,
                    "timeout_seconds": 180,
                    "config_sha256": digest(config),
                }
            )
        comparisons = config.get("head_comparisons", [])
        if not isinstance(comparisons, list):
            raise SweepError("head_comparisons must be an array of predeclared comparisons")
        names = set()
        for comparison in comparisons:
            name = comparison.get("id", "")
            if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", name) or name in names:
                raise SweepError("head comparison IDs must be unique safe names")
            names.add(name)
            temporary = {**plan, "configs": [{**config, "head_to_head": comparison}]}
            validate_plan(temporary)
            for stage in stage_plan(temporary):
                if stage["kind"] == "head":
                    offset = stage["first_seed"] - comparison["first_seed"]
                    specs.append(
                        {
                            **stage,
                            "id": f"{config['id']}/head-{name}-{offset:03}",
                            "comparison_id": name,
                            "config_sha256": digest(config),
                        }
                    )
    if len(specs) != len({spec["id"] for spec in specs}):
        raise SweepError("overlapping shard IDs")
    return specs


def freeze_plan(plan, root=ROOT):
    root = Path(root).resolve()
    validate_plan(plan)
    git(root, "merge-base", "--is-ancestor", plan["source_commit"], "HEAD")
    if file_sha(local_path(plan["profiles"], root)) != plan["profiles_sha256"]:
        raise SweepError("profile table differs from the input plan")
    # Accept both an existing sequential plan and a plan made with fingerprint.
    declared = portable_sources(root, plan["source_paths"])
    if digest(declared) != plan["source_fingerprint"] and (
        digest(source_manifest(root, plan["source_paths"])) != plan["source_fingerprint"]
    ):
        raise SweepError("source/content differs from the input plan; freeze current inputs first")
    frozen = copy.deepcopy(plan)
    frozen["source_paths"] = list(dict.fromkeys([*SOURCE_PATHS, *plan["source_paths"], plan["profiles"]]))
    files = portable_sources(root, frozen["source_paths"])
    frozen["source_fingerprint"] = digest(files)
    return seal(
        {
            "version": 1,
            "plan": frozen,
            "input_plan_sha256": digest(plan),
            "source_files": files,
            "profile_text": local_path(plan["profiles"], root).read_bytes().decode(),
            "shards": shard_specs(frozen),
            "toolchain": {
                "godot": GODOT_VERSION,
                "environment": "/opt/bramble/env.sh",
                "memory_max": "3G",
                "lock": LOCK_PATH,
            },
            "timing_basis": "2.5 s/lobby; 0.0076 s/field fight, plus startup; estimates, not cloud measurements",
        },
        "manifest_sha256",
    )


def validate_manifest(manifest):
    check_seal(manifest, "manifest_sha256")
    if manifest.get("version") != 1:
        raise SweepError("expected shard manifest version 1")
    plan = validate_plan(manifest["plan"])
    if manifest["shards"] != shard_specs(plan):
        raise SweepError("shard IDs, seeds, counts, replicates or configuration hashes differ from the frozen plan")
    if digest(manifest["source_files"]) != plan["source_fingerprint"]:
        raise SweepError("source file hashes differ from frozen fingerprint")
    for name, checksum in manifest["source_files"].items():
        if Path(name).is_absolute() or ".." in Path(name).parts or not re.fullmatch(r"[0-9a-f]{64}", checksum):
            raise SweepError("invalid portable source file entry")
    if hashlib.sha256(manifest["profile_text"].encode()).hexdigest() != plan["profiles_sha256"]:
        raise SweepError("frozen profile bytes differ from plan")
    if manifest["source_files"].get(plan["profiles"]) != plan["profiles_sha256"]:
        raise SweepError("profile is absent from frozen source files")
    if manifest["toolchain"] != {
        "godot": GODOT_VERSION,
        "environment": "/opt/bramble/env.sh",
        "memory_max": "3G",
        "lock": LOCK_PATH,
    }:
        raise SweepError("unsupported shard toolchain")
    return manifest


def verify_checkout(manifest, root=ROOT):
    validate_manifest(manifest)
    root = Path(root).resolve()
    plan = manifest["plan"]
    if portable_sources(root, plan["source_paths"]) != manifest["source_files"]:
        raise SweepError("checkout source/content/helper bytes differ from frozen manifest")
    git(root, "merge-base", "--is-ancestor", plan["source_commit"], "HEAD")


def config_for(manifest, spec):
    return next(config for config in manifest["plan"]["configs"] if config["id"] == spec["config"])


def comparison_for(config, spec):
    if "comparison_id" in spec:
        return next(value for value in config["head_comparisons"] if value["id"] == spec["comparison_id"])
    return config.get("head_to_head", {})


def gate_provenance(config, root=ROOT):
    gate = config.get("requires_gate")
    if not gate:
        return None
    spec = {"path": gate} if isinstance(gate, str) else gate
    path = local_path(spec["path"], root)
    if not path.is_file():
        raise SweepError(f"{config['id']}: required positive build gate is missing: {path}")
    text = path.read_bytes().decode()
    provenance = {
        "path": spec["path"],
        "condition": spec.get("key", "passes"),
        "sha256": hashlib.sha256(text.encode()).hexdigest(),
        "content": text,
    }
    validate_gate(config, provenance)
    return provenance


def validate_gate(config, provenance):
    gate = config.get("requires_gate")
    if not gate:
        if provenance is not None:
            raise SweepError("unexpected gate provenance")
        return
    spec = {"path": gate} if isinstance(gate, str) else gate
    if not isinstance(provenance, dict) or (
        provenance.get("path") != spec["path"] or provenance.get("condition") != spec.get("key", "passes")
    ):
        raise SweepError("missing or mismatched required gate provenance")
    if hashlib.sha256(provenance["content"].encode()).hexdigest() != provenance["sha256"]:
        raise SweepError("gate evidence changed")
    value = json.loads(provenance["content"])
    for key in provenance["condition"].split("."):
        if not isinstance(value, dict) or key not in value:
            raise SweepError("required gate condition is absent")
        value = value[key]
    if value is not True:
        raise SweepError("required build gate has not passed")


def godot_command(script, arguments, timeout_seconds, root=ROOT):
    """One bounded scope/lock, with version, fresh import and simulation serial."""
    root = Path(root).resolve()
    invoke = ["godot", "--headless", "--path", str(root)]
    shell = (
        ". /opt/bramble/env.sh && version=$(godot --version) && "
        f'[[ "$version" == {GODOT_VERSION}.* ]] && '
        + shlex.join([*invoke, "--editor", "--import"])
        + " && exec "
        + shlex.join([*invoke, "-s", f"res://tools/sim/{script}", "--", *arguments])
    )
    return [
        "flock",
        "-w",
        str(timeout_seconds),
        LOCK_PATH,
        "systemd-run",
        "--user",
        "--scope",
        "-p",
        "MemoryMax=3G",
        "--",
        "timeout",
        "--signal=TERM",
        "--kill-after=5s",
        f"{timeout_seconds}s",
        "bash",
        "-c",
        shell,
    ]


def archive_jsonl(path, records):
    """Canonical records in deterministic gzip; captures stay streamable."""
    with Path(path).open("wb") as raw, gzip.GzipFile(fileobj=raw, mode="wb", filename="", mtime=0) as stream:
        for record in records:
            stream.write(canonical(record) + b"\n")
    return {"path": Path(path).name, "sha256": file_sha(path)}


def artifact_path(folder, artifact):
    name = artifact["path"]
    if Path(name).name != name or name in (".", ".."):
        raise SweepError("artifact paths must be relative file names")
    path = Path(folder) / name
    if not path.is_file() or path.is_symlink() or file_sha(path) != artifact["sha256"]:
        raise SweepError(f"missing or changed artifact: {name}")
    return path


def archived_rows(folder, artifact):
    path = artifact_path(folder, artifact)
    with gzip.open(path, "rb") as stream:
        for raw in stream:
            value = json.loads(raw)
            if raw != canonical(value) + b"\n":
                raise SweepError(f"artifact record is not canonical JSON: {path.name}")
            yield value


def write_csv(path, records, columns=None):
    records = iter(records)
    first = next(records, None)
    if first is None and not columns:
        raise SweepError(f"empty CSV evidence: {path.name}")
    with path.open("w", newline="") as stream:
        columns = columns or sorted(first)
        if len(columns) != len(set(columns)) or any(not isinstance(value, str) or not value for value in columns):
            raise SweepError("invalid CSV evidence columns")
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        if first is not None:
            for record in chain((first,), records):
                if set(record) != set(columns):
                    raise SweepError("CSV evidence columns differ between records")
                writer.writerow(record)


def expected_artifacts(spec):
    if spec["kind"] == "upset":
        return {"trials", "diagnostic_plan"}
    if spec["kind"] == "field":
        return {"pairs"}
    return {*TABLES, *({"captures"} if spec["kind"] == "lobbies" else set())}


def materialize_result(result, source, folder):
    artifacts = result["artifacts"]
    if set(artifacts) != expected_artifacts(result["shard"]):
        raise SweepError("incomplete or unexpected result artifacts")
    folder.mkdir(parents=True, exist_ok=True)
    for name, artifact in artifacts.items():
        records = archived_rows(source, artifact)
        if name in TABLES:
            write_csv(folder / f"bench.{name}.csv", records, artifact.get("columns"))
        elif name == "diagnostic_plan":
            values = list(records)
            if len(values) != 1:
                raise SweepError("diagnostic plan artifact must contain exactly one object")
            (folder / "diagnostic-plan.json").write_bytes(canonical(values[0]) + b"\n")
        else:
            filename = {"captures": "bench.fights.jsonl", "pairs": "pairs.jsonl", "trials": "trials.jsonl"}[name]
            with (folder / filename).open("wb") as stream:
                for record in records:
                    stream.write(canonical(record) + b"\n")


def validate_lobby_result(manifest, result, folder):
    spec = result["shard"]
    config = config_for(manifest, spec)
    comparison = comparison_for(config, spec)
    validate_players(
        folder / "bench.players.csv",
        spec["first_seed"],
        spec["count"],
        spec["kind"] == "head",
        comparison.get("candidate"),
        comparison.get("incumbent", "hard"),
    )
    if spec["kind"] == "lobbies":
        validate_capture(
            folder / "bench.fights.jsonl",
            spec["first_seed"],
            spec["count"],
            folder / "bench.players.csv",
            config["overrides"],
        )


def validate_pairs(field, pairs, reps):
    expected = {
        (int(number), left["id"], right["id"])
        for number, data in field["rounds"].items()
        for index, left in enumerate(data["boards"])
        for right in data["boards"][index + 1 :]
    }
    seen = set()
    for row in pairs:
        identity = (row["round"], row["a"], row["b"])
        if identity not in expected or identity in seen:
            raise SweepError("duplicate or unexpected field pair/orientation")
        seen.add(identity)
        if any(type(row[key]) is not int or row[key] < 0 for key in ("wins_a", "wins_b", "draws", "trials")):
            raise SweepError("field outcomes must be nonnegative integer counts")
        if row["trials"] != 2 * reps or row["wins_a"] + row["wins_b"] + row["draws"] != row["trials"]:
            raise SweepError("incomplete field counts or replicate budget")
    if seen != expected:
        raise SweepError("missing field pairs; a full global round robin is required")


def result_paths(inputs):
    paths = []
    for item in inputs:
        item = Path(item)
        paths.extend(sorted(item.rglob("result.json")) if item.is_dir() else [item])
    if not paths:
        raise SweepError("no result.json files supplied")
    return paths


def load_results(manifest, inputs, kinds=None):
    expected = {spec["id"]: spec for spec in manifest["shards"]}
    found, gates = {}, {}
    for path in result_paths(inputs):
        result = json.loads(path.read_text())
        check_seal(result, "result_sha256")
        if result.get("version") != 1 or result.get("manifest_sha256") != manifest["manifest_sha256"]:
            raise SweepError("result belongs to a different frozen manifest/source/profile")
        name = result["shard"]["id"]
        if name in found:
            raise SweepError(f"duplicate/overlapping shard result: {name}")
        if result["shard"] != expected.get(name):
            raise SweepError("unknown shard or changed configuration/seeds/replicates")
        if kinds is not None and result["shard"]["kind"] not in kinds:
            raise SweepError("unexpected shard kind for this merge")
        config = config_for(manifest, result["shard"])
        validate_gate(config, result.get("gate"))
        if config["id"] in gates and gates[config["id"]] != result.get("gate"):
            raise SweepError("gate evidence differs between shards of one configuration")
        gates[config["id"]] = result.get("gate")
        if set(result["artifacts"]) != expected_artifacts(result["shard"]):
            raise SweepError("incomplete or unexpected result artifacts")
        for artifact in result["artifacts"].values():
            artifact_path(path.parent, artifact)
        found[name] = (result, path.parent)
    required = {name for name, spec in expected.items() if kinds is None or spec["kind"] in kinds}
    if set(found) != required:
        raise SweepError(f"missing shard results: {', '.join(sorted(required - found.keys()))}")
    return found


def field_input(manifest, bundle, spec):
    if bundle["manifest_sha256"] != manifest["manifest_sha256"]:
        raise SweepError("field inputs belong to a different frozen manifest")
    entry = bundle["fields"][spec["id"]]
    return entry


def load_field_bundle(manifest, path):
    path = Path(path)
    document = json.loads((path / "inputs.json").read_text())
    check_seal(document, "bundle_sha256")
    if document.get("version") != 1 or document.get("manifest_sha256") != manifest["manifest_sha256"]:
        raise SweepError("field inputs belong to a different frozen manifest")
    expected = {spec["id"] for spec in manifest["shards"] if spec["kind"] == "field"}
    if set(document["fields"]) != expected:
        raise SweepError("field bundle has missing/extra global round inputs")
    expected_lobbies = {spec["id"] for spec in manifest["shards"] if spec["kind"] == "lobbies"}
    if set(document["lobby_results"]) != expected_lobbies:
        raise SweepError("field bundle lacks complete 150-lobby provenance")
    for config in manifest["plan"]["configs"]:
        validate_gate(config, document["gates"].get(config["id"]))
    for entry in document["fields"].values():
        artifact_path(path, entry)
    return document


def diagnostic_field(manifest, bundle, inputs, spec):
    """The diagnostic sees exactly the same selected boards as the field fights."""
    config = config_for(manifest, spec)
    full = None
    for number in config["rounds"]:
        entry = bundle["fields"][f"{config['id']}/field-r{number:02}"]
        partial = json.loads(artifact_path(inputs, entry).read_text())
        metadata = {key: value for key, value in partial.items() if key != "rounds"}
        if full is None:
            full = {**metadata, "rounds": {}}
        elif metadata != {key: value for key, value in full.items() if key != "rounds"}:
            raise SweepError("diagnostic global field parts have different population provenance")
        if set(partial["rounds"]) != {str(number)}:
            raise SweepError("diagnostic field part has unexpected rounds")
        full["rounds"].update(partial["rounds"])
    return full


def diagnostic_plan(field, seeds):
    field_sha = hashlib.sha256(canonical(field) + b"\n").hexdigest()
    return upset_report.make_plan(field, field_sha, seeds)


def validate_upset(field, plan, rows):
    field_sha = hashlib.sha256(canonical(field) + b"\n").hexdigest()
    if plan != upset_report.make_plan(field, field_sha, plan["seeds"]):
        raise SweepError("diagnostic plan differs from deterministic global-field selection")
    indexed = {board["id"]: board for data in field["rounds"].values() for board in data["boards"]}
    expected = {
        (pair["a"], pair["b"], seed, orientation)
        for pair in plan["pairs"]
        for seed in plan["seeds"]
        for orientation in (0, 1)
    }
    identities = [(row["a"], row["b"], row["seed"], row["orientation"]) for row in rows]
    if len(identities) != 128 or len(set(identities)) != 128 or set(identities) != expected:
        raise SweepError("missing, duplicate or unexpected diagnostic trials; require all 128 frozen trials")
    if any(
        row["field_sha256"] != field_sha
        or row["plan_sha256"] != digest(plan)
        or row["round"] != indexed[row["a"]]["round"]
        or row["round"] != indexed[row["b"]]["round"]
        for row in rows
    ):
        raise SweepError("diagnostic trial plan/field/round provenance differs")
    report = upset_report.upset_report(rows, bootstrap_replicates=0)
    if not report["complete_frozen_design"] or report["fights"] != 1024:
        raise SweepError("incomplete frozen upset design or fight budget")
    return report


def run_shard(manifest, name, output, root=ROOT, inputs=None):
    verify_checkout(manifest, root)
    matches = [spec for spec in manifest["shards"] if spec["id"] == name]
    if not matches:
        raise SweepError(f"unknown frozen shard ID: {name}")
    spec = matches[0]
    config = config_for(manifest, spec)
    gate = gate_provenance(config, root)
    bundle, field, upset_plan = None, None, None
    if spec["kind"] in ("field", "upset"):
        if inputs is None:
            raise SweepError("field/upset shard requires --inputs from the complete merge-lobbies step")
        bundle = load_field_bundle(manifest, inputs)
        if gate != bundle["gates"][config["id"]]:
            raise SweepError("required gate differs from the lobby-stage gate")
        if spec["kind"] == "upset":
            field = diagnostic_field(manifest, bundle, inputs, spec)
            upset_plan = diagnostic_plan(field, spec["seeds"])
        else:
            field = json.loads(artifact_path(inputs, field_input(manifest, bundle, spec)).read_text())
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    artifacts = {}
    with tempfile.TemporaryDirectory(prefix="raw-", dir=output) as temporary:
        raw = Path(temporary)
        if spec["kind"] == "upset":
            (raw / "field.json").write_bytes(canonical(field) + b"\n")
            (raw / "diagnostic-plan.json").write_bytes(canonical(upset_plan) + b"\n")
            arguments = [str(raw / "field.json"), str(raw / "diagnostic-plan.json"), str(raw / "trials.jsonl")]
            script = "upset_probe.gd"
        elif spec["kind"] == "field":
            atomic_json(raw / "field.json", field)
            arguments = [str(raw / "field.json"), str(raw / "pairs.jsonl"), str(config["reps"])]
            script = "field_fights.gd"
        else:
            (raw / "profiles.json").write_bytes(manifest["profile_text"].encode())
            (raw / "config.json").write_bytes(canonical(config["overrides"]) + b"\n")
            arguments = [
                f"suite={'lines' if spec['kind'] == 'lobbies' else 'head_to_head'}",
                f"games={spec['count']}",
                f"first_seed={spec['first_seed']}",
                f"out={raw / 'bench'}",
                f"lines={raw / 'profiles.json'}",
                f"config={raw / 'config.json'}",
                f"capture={'on' if spec['kind'] == 'lobbies' else 'off'}",
            ]
            if spec["kind"] == "head":
                comparison = comparison_for(config, spec)
                arguments += [f"candidate={comparison['candidate']}", f"incumbent={comparison['incumbent']}"]
            script = "bench.gd"
        # Outer timeout also bounds time waiting for the per-machine lock.
        run_command(
            godot_command(script, arguments, spec["timeout_seconds"], root),
            output / "godot.log",
            spec["timeout_seconds"] + 7,
            root,
        )
        verify_checkout(manifest, root)
        if gate_provenance(config, root) != gate:
            raise SweepError("gate evidence changed during shard execution")
        if spec["kind"] == "upset":
            rows = list(jsonl(raw / "trials.jsonl"))
            validate_upset(field, upset_plan, rows)
            artifacts["trials"] = archive_jsonl(output / "trials.jsonl.gz", rows)
            artifacts["diagnostic_plan"] = archive_jsonl(output / "diagnostic-plan.jsonl.gz", [upset_plan])
        elif spec["kind"] == "field":
            validate_pairs(field, list(jsonl(raw / "pairs.jsonl")), config["reps"])
            artifacts["pairs"] = archive_jsonl(output / "pairs.jsonl.gz", jsonl(raw / "pairs.jsonl"))
        else:
            for suffix in CAPTURE_SUFFIXES:
                if (suffix != "fights.jsonl" or spec["kind"] == "lobbies") and not (raw / f"bench.{suffix}").is_file():
                    raise SweepError(f"missing bench output: {suffix}")
            validate_lobby_result(manifest, {"shard": spec}, raw)
            for name in TABLES:
                with (raw / f"bench.{name}.csv").open(newline="") as stream:
                    reader = csv.DictReader(stream)
                    artifacts[name] = archive_jsonl(output / f"{name}.jsonl.gz", reader)
                    artifacts[name]["columns"] = reader.fieldnames
            if spec["kind"] == "lobbies":
                artifacts["captures"] = archive_jsonl(output / "captures.jsonl.gz", jsonl(raw / "bench.fights.jsonl"))
    result = seal(
        {
            "version": 1,
            "manifest_sha256": manifest["manifest_sha256"],
            "shard": spec,
            "gate": gate,
            "field_bundle_sha256": bundle["bundle_sha256"] if bundle else None,
            "field_sha256": (
                upset_plan["field_sha256"]
                if upset_plan
                else field_input(manifest, bundle, spec)["sha256"]
                if bundle
                else None
            ),
            "diagnostic_plan_sha256": digest(upset_plan) if upset_plan else None,
            "artifacts": artifacts,
            "elapsed_seconds": time.monotonic() - started,
        },
        "result_sha256",
    )
    atomic_json(output / "result.json", result)
    return result


def build_fields(manifest, results, workspace):
    """Global sampling order matches Sweep: config, ascending 50-seed chunk."""
    fields, gates = {}, {}
    for config in manifest["plan"]["configs"]:
        captures = []
        for spec in manifest["shards"]:
            if spec["config"] != config["id"] or spec["kind"] != "lobbies":
                continue
            result, source = results[spec["id"]]
            folder = workspace / spec["id"]
            materialize_result(result, source, folder)
            validate_lobby_result(manifest, result, folder)
            captures.append(folder / "bench.fights.jsonl")
            gates[config["id"]] = result.get("gate")
        field = sample_field(
            boards_from_capture(captures),
            tuple(config["rounds"]),
            config["field_size"],
            config.get("field_seed", 91407),
        )
        field["sources"] = {
            name: result["result_sha256"]
            for name, (result, _) in results.items()
            if result["shard"]["config"] == config["id"] and result["shard"]["kind"] == "lobbies"
        }
        for number in config["rounds"]:
            fields[f"{config['id']}/field-r{number:02}"] = {
                **field,
                "rounds": {str(number): field["rounds"][str(number)]},
            }
    return fields, gates


def merge_lobbies(manifest, inputs, output):
    validate_manifest(manifest)
    results = load_results(manifest, inputs, {"lobbies"})
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    with tempfile.TemporaryDirectory(prefix="sweep-lobbies-") as temporary:
        fields, gates = build_fields(manifest, results, Path(temporary))
    entries = {}
    for name, field in fields.items():
        filename = name.replace("/", "--") + ".json"
        atomic_json(output / filename, field)
        entries[name] = {"path": filename, "sha256": file_sha(output / filename)}
    document = seal(
        {
            "version": 1,
            "manifest_sha256": manifest["manifest_sha256"],
            "lobby_results": {name: result["result_sha256"] for name, (result, _) in results.items()},
            "gates": gates,
            "fields": entries,
        },
        "bundle_sha256",
    )
    atomic_json(output / "inputs.json", document)
    return document


def finish_report(sweep, manifest, extra_reports, upset_reports):
    """Keep reproduction instructions when Sweep regenerates the base report."""
    first = next(spec for spec in manifest["shards"] if spec["kind"] == "lobbies")
    field = next(spec for spec in manifest["shards"] if spec["kind"] == "field")
    lines = [
        "",
        "## Portable cloud shards",
        "",
        "Run these commands from a checkout with the frozen simulation/helper bytes. "
        "The documented cloud toolchain setup must already have installed Godot 4.7.2, "
        "Python and /opt/bramble/env.sh. The runner sources that environment, verifies "
        "the Godot version and imports the fresh checkout before its simulation. "
        "CLOUD_HARNESS_ROOT may name another checkout; no home-directory variable is reassigned.",
        "",
        "```bash",
        "python3 tools/sim/sweep_shards.py plan PLAN.json --out manifest.json",
        f"python3 tools/sim/sweep_shards.py run manifest.json {first['id']} --out lobby-shard",
        "python3 tools/sim/sweep_shards.py merge-lobbies manifest.json --results collected-lobbies --out field-inputs",
        f"python3 tools/sim/sweep_shards.py run manifest.json {field['id']} --inputs field-inputs --out field-shard",
        "python3 tools/sim/sweep_shards.py merge manifest.json --inputs field-inputs "
        "--results collected-results --out merged",
        "```",
        "",
        "Run each frozen lobby ID once, then transfer its whole result directory. "
        "merge-lobbies requires every configuration's three 50-seed shards before "
        "sampling one global equal-line field per round from all 150 lobbies. "
        "Transfer manifest.json and the whole field-inputs directory to each fresh "
        "field worker. Run every frozen field/head ID once and collect all result "
        "directories, including the original lobby results, for the final merge. "
        "Both merge commands are pure Python. Individual seed-shard fields cannot "
        "be combined into the required global round robin.",
        "",
        "Measured baseline timing basis: 2.5 seconds/lobby and 0.0076 seconds/field fight. "
        "A 50-lobby shard is about 2.2 minutes plus any fresh import/lock wait; "
        "one 64-board round has 32,256 fights and is about 4.1 minutes plus startup "
        "(32 boards: 7,936 fights, about 1 minute). A complete 64-board configuration "
        "is about 31 minutes before separate head comparisons; a fresh import may "
        "add up to 30 seconds. These are planning estimates, not cloud measurements. "
        "Each manifest shard records its estimate and hard "
        "timeout; import, lock wait and simulation share that bound. Head estimates "
        "are listed per frozen chunk. One Godot process runs at a time per worker "
        "under /tmp/bramble-harness-godot.lock, systemd MemoryMax=3G and timeout.",
        "",
        "The manifest freezes all lobby seeds, field sampling seed, pair seed derivation "
        "in the hashed field driver, and eight replicates per orientation. Result "
        "JSON and deterministic gzip captures are portable across absolute checkout "
        "paths. Hash/completeness/configuration/profile/gate checks reject missing, "
        "duplicate, changed or incompatible artifacts; they do not attest remote execution. "
        "Protected runs require the real positive gate file in each checkout, and "
        "the final report retains its exact content/hash. Missing gates never count as passes.",
    ]
    if upset_reports:
        lines += [
            "",
            "### Controlled upset diagnostics",
            "",
            "The optional frozen CONFIG/upset shard requires the same field-inputs bundle: "
            "`python3 tools/sim/sweep_shards.py run manifest.json CONFIG/upset "
            "--inputs field-inputs --out cause-shard`. Its fixed 1,024 fights take "
            "about 10 seconds plus fresh import (up to 30 seconds); the manifest "
            "sets a 180-second hard timeout. Final merge requires this shard when declared.",
            "",
            "These flags describe reversals of all selected baseline wins under controlled "
            "interventions and can overlap. They are not disjoint cause shares, lower-stat "
            "upset frequencies, or population estimates. Pair selection uses frozen board "
            "IDs and line strata without outcome selection. The global field's empirical "
            "pair probabilities remain separate from visible statistics.",
        ]
        for name, path, report in upset_reports:
            lines += [
                "",
                f"#### {name}",
                "",
                sweep.link(path, "Complete cause diagnostics and controlled trial classifications"),
                "",
                f"{report['selected_pairs']} selected pairs; {report['selected_boards']} boards; "
                f"128 trials / 1,024 fights; {report['baseline_wins']} baseline wins and "
                f"{report['baseline_draws']} baseline draws.",
                "",
                "| Flag | Count / eligible baseline wins | Rate | Selected-board 95% interval |",
                "|---|---:|---:|---|",
            ]
            for flag, value in report["attribution"].items():
                rate = f"{value['rate']:.3f}" if value["rate"] is not None else "n/a"
                interval = value["selected_board_ci95"]
                bounds = " / ".join(f"{number:.3f}" for number in interval) if interval else "n/a"
                lines.append(
                    f"| {flag} | {value['count']} / {value['denominator_baseline_wins']} | {rate} | {bounds} |"
                )
            lines += [
                "",
                "| Interpretation limit | Scope |",
                "|---|---|",
                f"| Answer masking | {report['answer_scope']} |",
                f"| Other RNG | {report['other_rng_scope']} |",
                f"| Uncertainty | {report['uncertainty']['scope']} |",
                f"| Small sample | {report['uncertainty']['limitations']} |",
                f"| Unsupported masks | {report['unsupported_mask_trials']} trials; answer flags remain unknown |",
            ]
    contexts = manifest["plan"].get("context_links", [])
    if contexts:
        lines += ["", "### Existing strength evidence", ""]
        for context in contexts:
            path = local_path(context["path"], sweep.root)
            lines.append(f"- {sweep.link(path, context['label'])}")
    if extra_reports:
        lines += ["", "### Additional frozen head-to-head comparisons", ""]
        for path, report in extra_reports:
            lines.append(
                f"- {sweep.link(path, report['candidate'] + ' versus ' + report['incumbent'])}: "
                f"80 independent seeds, 160 seat-swapped lobbies; "
                f"mean place gain {report['mean_place_gain']:.3f}; "
                f"superiority test {'passes' if report['passes'] else 'does not pass'}."
            )
        lines += ["", "These are separate fixed comparisons; no result extends a sample or changes a configuration."]
    with sweep.report.open("a") as stream:
        stream.write("\n".join(lines) + "\n")


def merge(manifest, inputs, field_inputs, output, root=ROOT):
    """Validate complete evidence, then use the local sweep's analysis/report APIs."""
    verify_checkout(manifest, root)
    results = load_results(manifest, inputs)
    bundle = load_field_bundle(manifest, field_inputs)
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=False)
    # Recompute the sample, so a field cannot be replaced by disjoint per-seed fields.
    with tempfile.TemporaryDirectory(prefix="sweep-verify-") as temporary:
        fields, gates = build_fields(manifest, results, Path(temporary))
    if gates != bundle["gates"]:
        raise SweepError("field bundle gate provenance differs from lobby results")
    for name, expected in bundle["lobby_results"].items():
        if results[name][0]["result_sha256"] != expected:
            raise SweepError("lobby result changed since global field selection")
    for name, field in fields.items():
        actual = json.loads(artifact_path(field_inputs, bundle["fields"][name]).read_text())
        if actual != field:
            raise SweepError("global field sample differs from the complete frozen lobby population")
    plan_path = output / "plan.json"
    atomic_json(plan_path, manifest["plan"])
    sweep = Sweep(plan_path, root)
    sweep.output, sweep.report = output, output / "report.md"
    sweep.lock_path, sweep.status_path = output / "plan.lock.json", output / "status.json"
    sweep.status = {
        "version": 1,
        "plan_sha256": digest(sweep.plan),
        "state": "merging",
        "created_at": utc_now(),
        "gates": {name: gate for name, gate in gates.items() if gate is not None},
        "stages": {},
    }
    atomic_json(sweep.lock_path, {"manifest": manifest, "field_inputs": bundle})
    upset_reports = []
    for spec in manifest["shards"]:
        if spec["kind"] != "upset":
            continue
        result, source = results[spec["id"]]
        folder = output / "stages" / spec["id"]
        materialize_result(result, source, folder)
        full_field = diagnostic_field(manifest, bundle, field_inputs, spec)
        expected_plan = diagnostic_plan(full_field, spec["seeds"])
        actual_plan = json.loads((folder / "diagnostic-plan.json").read_text())
        if (
            actual_plan != expected_plan
            or result.get("field_bundle_sha256") != bundle["bundle_sha256"]
            or result.get("field_sha256") != expected_plan["field_sha256"]
            or result.get("diagnostic_plan_sha256") != digest(expected_plan)
        ):
            raise SweepError("diagnostic result plan/global field provenance differs from frozen inputs")
        rows = list(jsonl(folder / "trials.jsonl"))
        validate_upset(full_field, expected_plan, rows)
        report = upset_report.upset_report(rows)
        report["provenance"] = {"manifest_sha256": manifest["manifest_sha256"], "config": spec["config"]}
        report_path = folder / "upset-report.json"
        atomic_json(report_path, report)
        (folder / "field.json").write_bytes(canonical(full_field) + b"\n")
        upset_reports.append((spec["config"], report_path, report))
        sweep.status["stages"][spec["id"]] = {
            "state": "complete",
            "directory": str(folder.relative_to(output)),
            "stage": spec,
            "outputs": {
                str(path.relative_to(output)): file_sha(path) for path in sorted(folder.rglob("*")) if path.is_file()
            },
        }
    extra_specs = [spec for spec in manifest["shards"] if "comparison_id" in spec]
    for spec in extra_specs:
        folder = output / "stages" / spec["id"]
        result, source = results[spec["id"]]
        materialize_result(result, source, folder)
        validate_lobby_result(manifest, result, folder)
        sweep.status["stages"][spec["id"]] = {
            "state": "complete",
            "directory": str(folder.relative_to(output)),
            "stage": spec,
            "outputs": {
                str(path.relative_to(output)): file_sha(path) for path in sorted(folder.rglob("*")) if path.is_file()
            },
        }
    for spec in sweep.stages:
        name = spec["id"]
        folder = output / "stages" / name
        folder.mkdir(parents=True, exist_ok=True)
        kind = spec["kind"]
        if kind in ("lobbies", "head", "field"):
            result, source = results[name]
            materialize_result(result, source, folder)
            if kind == "field":
                if (
                    result.get("field_bundle_sha256") != bundle["bundle_sha256"]
                    or result.get("field_sha256") != bundle["fields"][name]["sha256"]
                ):
                    raise SweepError("field result ran a different global field input bundle")
                field = fields[name]
                pairs = list(jsonl(folder / "pairs.jsonl"))
                validate_pairs(field, pairs, config_for(manifest, result["shard"])["reps"])
                atomic_json(folder / "field.json", field)
                atomic_json(folder / "field-report.json", field_report(field, pairs))
            else:
                validate_lobby_result(manifest, result, folder)
        elif kind == "sample":
            for number in sweep.configs[spec["config"]]["rounds"]:
                atomic_json(folder / f"field-r{number:02}.json", fields[f"{spec['config']}/field-r{number:02}"])
        elif kind == "analysis":
            sweep.analyze(spec["config"], folder)
        sweep.status["stages"][name] = {
            "state": "complete",
            "directory": str(folder.relative_to(output)),
            "stage": spec,
            "outputs": {
                str(path.relative_to(output)): file_sha(path) for path in sorted(folder.rglob("*")) if path.is_file()
            },
        }
    sweep.status.update(state="complete", completed_at=utc_now())
    extra_reports = []
    for config in sweep.plan["configs"]:
        for comparison in config.get("head_comparisons", []):
            folder = sweep.stage_dir(f"{config['id']}/analysis")
            combined = folder / f"head-{comparison['id']}.players.csv"
            paths = [
                sweep.stage_dir(spec["id"]) / "bench.players.csv"
                for spec in extra_specs
                if spec["config"] == config["id"] and spec["comparison_id"] == comparison["id"]
            ]
            combine_csv(paths, combined)
            report = head_to_head(
                combined, {**comparison, "seed_range": [comparison["first_seed"], comparison["first_seed"] + 79]}
            )
            report["profiles_validated"] = True
            report["breakdown"] = line_breakdown(combined, json.loads(manifest["profile_text"]))
            report["outcome_rates"] = line_outcome_rates(combined)
            report["fixed_budget_note"] = (
                "A false superiority test is a finding; no extra seeds or tuning are permitted."
            )
            path = folder / f"head-to-head-{comparison['id']}.json"
            atomic_json(path, report)
            extra_reports.append((path, report))
        checkpoint = sweep.status["stages"][f"{config['id']}/analysis"]
        folder = sweep.stage_dir(f"{config['id']}/analysis")
        checkpoint["outputs"] = {
            str(path.relative_to(output)): file_sha(path) for path in sorted(folder.rglob("*")) if path.is_file()
        }
    sweep.save()
    sweep.write_report()
    finish_report(sweep, manifest, extra_reports, upset_reports)
    atomic_json(output / "manifest.json", manifest)
    atomic_json(output / "result-index.json", {name: result["result_sha256"] for name, (result, _) in results.items()})
    return sweep.status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(os.environ.get("CLOUD_HARNESS_ROOT", ROOT)))
    commands = parser.add_subparsers(dest="command", required=True)
    fingerprint = commands.add_parser("fingerprint")
    fingerprint.add_argument("--profiles", default="tools/sim/line_profiles.sweep.json")
    freeze = commands.add_parser("plan")
    freeze.add_argument("plan", type=Path)
    freeze.add_argument("--out", type=Path, required=True)
    run = commands.add_parser("run")
    run.add_argument("manifest", type=Path)
    run.add_argument("shard")
    run.add_argument("--inputs", type=Path)
    run.add_argument("--out", type=Path, required=True)
    for name in ("merge-lobbies", "merge"):
        command = commands.add_parser(name)
        command.add_argument("manifest", type=Path)
        command.add_argument("--results", type=Path, nargs="+", required=True)
        command.add_argument("--out", type=Path, required=True)
        if name == "merge":
            command.add_argument("--inputs", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.command == "fingerprint":
            print(json.dumps(fingerprints(args.root, args.profiles), indent=2))
            return
        if args.command == "plan":
            if args.out.exists():
                raise SweepError("manifest already exists; freeze to a new path")
            value = freeze_plan(json.loads(args.plan.read_text()), args.root)
            atomic_json(args.out, value)
        else:
            manifest = validate_manifest(json.loads(args.manifest.read_text()))
            if args.command == "run":
                value = run_shard(manifest, args.shard, args.out, args.root, args.inputs)
            elif args.command == "merge-lobbies":
                value = merge_lobbies(manifest, args.results, args.out)
            else:
                value = merge(manifest, args.results, args.inputs, args.out, args.root)
        print(
            json.dumps(
                {
                    key: value[key]
                    for key in ("manifest_sha256", "bundle_sha256", "result_sha256", "state")
                    if key in value
                }
            )
        )
    except (SweepError, OSError, ValueError, KeyError, TypeError) as error:
        print(f"sweep_shards: {error}", file=sys.stderr)
        raise SystemExit(2) from None


if __name__ == "__main__":
    main()
