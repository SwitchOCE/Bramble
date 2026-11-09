"""Portable shard evidence and global-field completeness; never launches Godot."""

import copy
import json
import shlex
import shutil
import sys
import tempfile
import unittest
from itertools import combinations
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from lever_sweep import ROUNDS, SweepError, atomic_json, canonical, digest, file_sha, jsonl
from sweep_shards import (
    SOURCE_PATHS,
    TABLES,
    archive_jsonl,
    archived_rows,
    artifact_path,
    diagnostic_field,
    diagnostic_plan,
    fingerprints,
    freeze_plan,
    gate_provenance,
    godot_command,
    load_field_bundle,
    load_results,
    materialize_result,
    merge,
    merge_lobbies,
    run_shard,
    seal,
    shard_specs,
    validate_gate,
    validate_lobby_result,
    validate_manifest,
    validate_pairs,
    validate_upset,
    verify_checkout,
    write_csv,
)


def configuration():
    return {
        "id": "caps",
        "first_seed": 1001,
        "lobbies": 150,
        "rounds": ROUNDS,
        "reps": 8,
        "field_size": 32,
        "overrides": {"card_size_caps": False},
    }


def players(spec):
    for seed in range(spec["first_seed"], spec["first_seed"] + spec["count"]):
        for seat in range(8):
            yield {"seed": str(seed), "leg": "0", "seat": str(seat), "place": str(seat + 1), "rounds": "16"}


def captures(spec):
    for seed in range(spec["first_seed"], spec["first_seed"] + spec["count"]):
        for number in range(1, 17):
            for pair in ([0, 1], [2, 3], [4, 5], [6, 7]):
                snapshots = []
                for seat in pair:
                    snapshots.append(
                        {
                            "layout": "blind",
                            "policy": "hard" if seat < 4 else "tribal",
                            "active_stats": number * 10 + seat,
                            "health": 40,
                            "largest_share": 1,
                            "gold_spent_game": number * 3,
                            "gold_spent_turn": 3,
                            "units": [
                                {
                                    "active": True,
                                    "slot": 0,
                                    "attack": 5 * number,
                                    "health": 5 * number + seat,
                                    "tier": 1,
                                    "golden": False,
                                    "def_id": "plain",
                                }
                            ],
                        }
                    )
                yield {
                    "seed": seed,
                    "leg": 0,
                    "round": number,
                    "players": pair,
                    "alive_before": 8,
                    "health_after": [40 if number < 16 or pair[0] == 0 else 0, 40 if number < 16 else 0],
                    "test_cards": [],
                    "combat_start": snapshots,
                    "input": {
                        "round": number,
                        "player_ids": pair,
                        "boards": [[{"iid": seat + 1}] for seat in pair],
                        "slots": [[], []],
                        "fight_rules": [{}, {}],
                        "hero_effects": [[], []],
                        "tiers": [1, 1],
                        "config": {"card_size_caps": False},
                    },
                }


def pairs(field):
    for number, data in field["rounds"].items():
        for left, right in combinations(data["boards"], 2):
            yield {
                "round": int(number),
                "a": left["id"],
                "b": right["id"],
                "wins_a": 0,
                "wins_b": 0,
                "draws": 16,
                "trials": 16,
            }


def diagnostic_trials(field, plan):
    indexed = {board["id"]: board for data in field["rounds"].values() for board in data["boards"]}
    for pair in plan["pairs"]:
        a, b = pair["a"], pair["b"]
        for seed in plan["seeds"]:
            for orientation in (0, 1):
                outcomes = {}
                for mask in ("intact", "masked"):
                    for layout in ("original", "a_alternate", "b_alternate", "coin_flipped"):
                        winner = int(mask == "masked" or layout in ("a_alternate", "coin_flipped"))
                        outcomes[f"{mask}.{layout}"] = {
                            "winner": winner,
                            "result": {"winner": winner if orientation == 0 else 1 - winner},
                            "first_side_original": 0,
                            "first_side_used": int(layout == "coin_flipped"),
                            "first_coin_eligible": True,
                        }
                yield {
                    "version": 1,
                    "fights": 8,
                    "a": a,
                    "b": b,
                    "round": indexed[a]["round"],
                    "seed": seed,
                    "orientation": orientation,
                    "side_board_ids": [a, b] if orientation == 0 else [b, a],
                    "field_sha256": plan["field_sha256"],
                    "plan_sha256": digest(plan),
                    "baseline_input_sha256": "3" * 64,
                    "mask_supported": True,
                    "mask_unsupported": [],
                    "mask_manifest": [],
                    "layouts": {name: {"old_to_new": list(range(7)), "pinned_slots": []} for name in (a, b)},
                    "outcomes": outcomes,
                }


class SweepShardTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / "checkout"
        for directory in ("src", "content/units", "tools/sim/lines"):
            (self.root / directory).mkdir(parents=True)
        for name, content in {
            "src/core.gd": "# simulation\n",
            "src/core.gd.uid": "generated UID\n",
            "content/units/plain.json": '{"id":"plain","attack":2,"health":3}\n',
            "tools/sim/bench.gd": "# bench\n",
            "tools/sim/helper.py": "# analysis\n",
            "tools/sim/lines/birds.json": '{"birds_tempo":{"tribe":"birds","buy_priority":["plain"]}}\n',
            "tools/sim/profiles.json": '{"hard":{"tribe":""},"tribal":{"tribe":"Test"}}\n',
            "project.godot": "config_version=5\n",
            "tools/versions.env": "GODOT_VERSION=4.7.2\n",
        }.items():
            (self.root / name).write_text(content)
        git_patch = patch("sweep_shards.git", return_value="a" * 40)
        git_patch.start()
        self.addCleanup(git_patch.stop)
        self.plan = {
            "version": 1,
            "configs": [configuration()],
            **fingerprints(self.root, "tools/sim/profiles.json"),
        }
        self.manifest = freeze_plan(self.plan, self.root)
        self.results = self.root.parent / "results"
        self.results.mkdir()

    def result(self, spec, artifacts, folder, **extra):
        result = seal(
            {
                "version": 1,
                "manifest_sha256": self.manifest["manifest_sha256"],
                "shard": spec,
                "gate": None,
                "artifacts": artifacts,
                "field_bundle_sha256": None,
                "field_sha256": None,
                **extra,
            },
            "result_sha256",
        )
        atomic_json(folder / "result.json", result)
        return result

    def lobby_results(self):
        for spec in self.manifest["shards"]:
            if spec["kind"] != "lobbies":
                continue
            folder = self.results / spec["id"]
            folder.mkdir(parents=True)
            artifacts = {}
            for name in TABLES:
                rows = list(players(spec)) if name == "players" else []
                artifacts[name] = archive_jsonl(folder / f"{name}.jsonl.gz", rows)
                artifacts[name]["columns"] = sorted(rows[0]) if rows else ["seed", "card"]
            artifacts["captures"] = archive_jsonl(folder / "captures.jsonl.gz", captures(spec))
            self.result(spec, artifacts, folder)

    def field_results(self, bundle, field_folder):
        for spec in self.manifest["shards"]:
            if spec["kind"] != "field":
                continue
            folder = self.results / spec["id"]
            folder.mkdir(parents=True)
            entry = bundle["fields"][spec["id"]]
            field = json.loads((field_folder / entry["path"]).read_text())
            self.result(
                spec,
                {"pairs": archive_jsonl(folder / "pairs.jsonl.gz", pairs(field))},
                folder,
                field_bundle_sha256=bundle["bundle_sha256"],
                field_sha256=entry["sha256"],
            )

    def head_results(self):
        for spec in self.manifest["shards"]:
            if spec["kind"] != "head":
                continue
            config = self.manifest["plan"]["configs"][0]
            comparison = next(row for row in config["head_comparisons"] if row["id"] == spec["comparison_id"])
            folder = self.results / spec["id"]
            folder.mkdir(parents=True)
            rows = [
                {
                    **row,
                    "leg": str(leg),
                    "candidate": comparison["candidate"],
                    "incumbent": comparison["incumbent"],
                    "side": "candidate" if (int(row["seat"]) < 4) == (leg == 0) else "incumbent",
                    "strategy": "hard",
                }
                for row in players(spec)
                for leg in range(2)
            ]
            artifacts = {}
            for name in TABLES:
                artifacts[name] = archive_jsonl(folder / f"{name}.jsonl.gz", rows if name == "players" else [])
                artifacts[name]["columns"] = sorted(rows[0]) if name == "players" else ["seed", "card"]
            self.result(spec, artifacts, folder)

    def test_manifest_expands_fixed_budgets_and_freezes_profile_and_helpers(self):
        validate_manifest(self.manifest)
        lobbies = [spec for spec in self.manifest["shards"] if spec["kind"] == "lobbies"]
        self.assertEqual(
            [(spec["first_seed"], spec["count"]) for spec in lobbies], [(1001, 50), (1051, 50), (1101, 50)]
        )
        self.assertEqual(len({spec["id"] for spec in self.manifest["shards"]}), 9)
        self.assertEqual(lobbies[0]["config_sha256"], digest(configuration()))
        self.assertIn("tools/sim/helper.py", self.manifest["source_files"])
        self.assertNotIn("src/core.gd.uid", self.manifest["source_files"])
        self.assertTrue(set(SOURCE_PATHS).issubset(self.manifest["plan"]["source_paths"]))
        broken = copy.deepcopy(self.manifest)
        broken["shards"][0]["first_seed"] += 1
        with self.assertRaisesRegex(SweepError, "document"):
            validate_manifest(broken)
        broken = seal({key: value for key, value in broken.items() if key != "manifest_sha256"}, "manifest_sha256")
        with self.assertRaisesRegex(SweepError, "shard IDs"):
            validate_manifest(broken)

    def test_fresh_checkout_ignores_generated_files_but_rejects_changed_runtime_bytes(self):
        other = self.root.parent / "fresh-checkout"
        shutil.copytree(self.root, other, ignore=shutil.ignore_patterns("*.uid"))
        (other / "src/core.gd.uid").write_text("different generated UID\n")
        (other / "src/.godot").mkdir()
        (other / "src/.godot/import.cache").write_text("different cache\n")
        verify_checkout(self.manifest, other)
        for name in ("src/core.gd", "tools/sim/helper.py", "tools/sim/profiles.json", "content/units/plain.json"):
            path = other / name
            original = path.read_bytes()
            path.write_bytes(original + b"\n")
            with self.assertRaisesRegex(SweepError, "bytes differ"):
                verify_checkout(self.manifest, other)
            path.write_bytes(original)
        (other / "src/addition.gd").write_text("# unplanned\n")
        with self.assertRaisesRegex(SweepError, "bytes differ"):
            verify_checkout(self.manifest, other)

    def test_wave1_line_edits_change_fingerprint_and_reject_frozen_checkout(self):
        line = self.root / "tools/sim/lines/birds.json"
        self.assertIn("tools/sim/lines/birds.json", self.manifest["source_files"])
        before = fingerprints(self.root, "tools/sim/profiles.json")
        line.write_text('{"birds_tempo":{"tribe":"birds","buy_priority":["changed"]}}\n')
        after = fingerprints(self.root, "tools/sim/profiles.json")
        self.assertNotEqual(before["source_fingerprint"], after["source_fingerprint"])
        self.assertEqual(before["profiles_sha256"], after["profiles_sha256"])
        with self.assertRaisesRegex(SweepError, "bytes differ"):
            verify_checkout(self.manifest, self.root)

    def test_gate_requires_real_positive_file_and_preserves_exact_evidence(self):
        config = {**configuration(), "requires_gate": {"path": "gate.json", "key": "build.passes"}}
        with self.assertRaisesRegex(SweepError, "missing"):
            gate_provenance(config, self.root)
        (self.root / "gate.json").write_text('{"build":{"passes":false}}\n')
        with self.assertRaisesRegex(SweepError, "not passed"):
            gate_provenance(config, self.root)
        (self.root / "gate.json").write_bytes(b'{"build":{"passes":true}}\r\n')
        gate = gate_provenance(config, self.root)
        self.assertEqual(gate["sha256"], file_sha(self.root / "gate.json"))
        validate_gate(config, gate)
        with self.assertRaisesRegex(SweepError, "missing or mismatched"):
            validate_gate(config, None)
        gate["content"] += " "
        with self.assertRaisesRegex(SweepError, "changed"):
            validate_gate(config, gate)

    def test_protected_shards_stop_before_command_when_gate_is_absent(self):
        plan = copy.deepcopy(self.plan)
        plan["configs"][0]["overrides"]["scale_levers"] = ["plain"]
        plan["configs"][0]["requires_gate"] = "gate.json"
        manifest = freeze_plan(plan, self.root)
        with patch("sweep_shards.run_command") as command:
            with self.assertRaisesRegex(SweepError, "missing"):
                run_shard(manifest, "caps/lobbies-000", self.root.parent / "stopped", self.root)
            command.assert_not_called()
        self.assertFalse((self.root.parent / "stopped").exists())

    def test_command_has_bounded_serial_fresh_import_and_pinned_toolchain(self):
        hostile = "/tmp/with spaces/$(touch SHOULD_NOT_EXIST);literal.json"
        command = godot_command("bench.gd", ["games=50", "out=a path", "config=" + hostile], 420, self.root)
        self.assertIn("/tmp/bramble-harness-godot.lock", command)
        self.assertIn("MemoryMax=3G", command)
        self.assertIn("systemd-run", command)
        self.assertIn("420s", command)
        shell = command[-1]
        self.assertIn(". /opt/bramble/env.sh", shell)
        self.assertIn("4.7.2.*", shell)
        self.assertLess(shell.index("--import"), shell.index("res://tools/sim/bench.gd"))
        self.assertIn("'out=a path'", shell)
        self.assertIn("config=" + hostile, shlex.split(shell))

    def test_one_command_archives_validated_outputs_and_removes_temporary_csv(self):
        spec = self.manifest["shards"][0]

        def fake_godot(argv, _log, _timeout, _root):
            prefix = Path(next(value[4:] for value in shlex.split(argv[-1]) if value.startswith("out=")))
            for name in TABLES:
                rows = list(players(spec)) if name == "players" else []
                write_csv(prefix.with_suffix(f".{name}.csv"), rows, sorted(rows[0]) if rows else ["seed", "card"])
            with prefix.with_suffix(".fights.jsonl").open("wb") as stream:
                for record in captures(spec):
                    stream.write(canonical(record) + b"\n")

        output = self.root.parent / "one-command"
        with patch("sweep_shards.run_command", side_effect=fake_godot) as command:
            result = run_shard(self.manifest, spec["id"], output, self.root)
            command.assert_called_once()
        self.assertEqual(result["shard"], spec)
        self.assertTrue((output / "result.json").is_file())
        self.assertFalse(any(path.name.startswith("raw-") for path in output.iterdir()))
        restored = self.root.parent / "restored"
        materialize_result(result, output, restored)
        validate_lobby_result(self.manifest, result, restored)
        self.assertEqual((restored / "bench.profile.csv").read_text(), "seed,card\n")

    def test_deterministic_canonical_archives_and_empty_profile_round_trip(self):
        folder = self.root.parent / "archive"
        folder.mkdir()
        first = archive_jsonl(folder / "a.gz", [{"b": 2, "a": 1}])
        second = archive_jsonl(folder / "b.gz", [{"a": 1, "b": 2}])
        self.assertEqual(first["sha256"], second["sha256"])
        self.assertEqual(list(archived_rows(folder, first)), [{"a": 1, "b": 2}])
        empty = archive_jsonl(folder / "empty.gz", [])
        output = folder / "empty.csv"
        write_csv(output, archived_rows(folder, empty), ["seed", "usec"])
        self.assertEqual(output.read_text(), "seed,usec\n")
        with self.assertRaisesRegex(SweepError, "relative"):
            artifact_path(folder, {"path": "../a.gz", "sha256": first["sha256"]})
        (folder / "a.gz").write_bytes(b"changed")
        with self.assertRaisesRegex(SweepError, "changed"):
            list(archived_rows(folder, first))

    def test_missing_duplicate_config_and_artifact_tamper_are_rejected(self):
        self.lobby_results()
        paths = sorted(self.results.rglob("result.json"))
        found = load_results(self.manifest, paths, {"lobbies"})
        self.assertEqual(len(found), 3)
        with self.assertRaisesRegex(SweepError, "missing shard"):
            load_results(self.manifest, paths[:-1], {"lobbies"})
        with self.assertRaisesRegex(SweepError, "duplicate/overlapping"):
            load_results(self.manifest, [*paths, paths[0]], {"lobbies"})
        original = json.loads(paths[0].read_text())
        changed = copy.deepcopy(original)
        changed["shard"]["config_sha256"] = "f" * 64
        atomic_json(
            paths[0], seal({key: value for key, value in changed.items() if key != "result_sha256"}, "result_sha256")
        )
        with self.assertRaisesRegex(SweepError, "changed configuration"):
            load_results(self.manifest, paths, {"lobbies"})
        atomic_json(paths[0], original)
        (paths[0].parent / "captures.jsonl.gz").write_bytes(b"partial transfer")
        with self.assertRaisesRegex(SweepError, "changed artifact"):
            load_results(self.manifest, paths, {"lobbies"})

    def test_global_sampling_uses_complete_150_lobby_population_and_portable_bundle(self):
        self.lobby_results()
        field_folder = self.root.parent / "field-inputs"
        bundle = merge_lobbies(self.manifest, [self.results], field_folder)
        self.assertEqual(len(bundle["lobby_results"]), 3)
        for entry in bundle["fields"].values():
            self.assertEqual(Path(entry["path"]).name, entry["path"])
            field = json.loads((field_folder / entry["path"]).read_text())
            data = next(iter(field["rounds"].values()))
            self.assertEqual(data["population_counts"], {"hard": 600, "tribal": 600})
            self.assertEqual(data["sample_counts"], {"hard": 16, "tribal": 16})
            self.assertEqual(len(data["boards"]), 32)
            self.assertTrue(any(board["seed"] >= 1101 for board in data["boards"]))
            self.assertEqual(len(field["sources"]), 3)
        relocated = self.root.parent / "another-input-location"
        shutil.copytree(field_folder, relocated)
        self.assertEqual(load_field_bundle(self.manifest, relocated), bundle)
        again = merge_lobbies(self.manifest, [self.results], self.root.parent / "again")
        self.assertEqual(again, bundle)

    def test_merge_rejects_semantically_incomplete_players_and_captures(self):
        self.lobby_results()
        path = sorted(self.results.rglob("result.json"))[0]
        result = json.loads(path.read_text())
        rows = list(archived_rows(path.parent, result["artifacts"]["players"]))
        old = result["artifacts"]["players"]
        result["artifacts"]["players"] = {
            **archive_jsonl(path.parent / old["path"], rows[:-1]),
            "columns": old["columns"],
        }
        atomic_json(
            path, seal({key: value for key, value in result.items() if key != "result_sha256"}, "result_sha256")
        )
        with self.assertRaisesRegex(SweepError, "duplicate, missing"):
            merge_lobbies(self.manifest, [self.results], self.root.parent / "invalid")
        # Capture completeness is checked independently of artifact checksums.
        folder = self.root.parent / "raw"
        materialize_result(result, path.parent, folder)
        self.assertEqual(len(list(jsonl(folder / "bench.fights.jsonl"))), 3200)
        write_csv(folder / "bench.players.csv", players(result["shard"]))
        records = list(jsonl(folder / "bench.fights.jsonl"))
        for broken in (records[:-1], [*records, records[0]]):
            (folder / "bench.fights.jsonl").write_bytes(b"".join(canonical(record) + b"\n" for record in broken))
            with self.assertRaisesRegex(SweepError, "incomplete|duplicate"):
                validate_lobby_result(self.manifest, result, folder)

    def test_field_pairs_need_every_global_pair_and_exact_nonnegative_replicates(self):
        field = {"rounds": {"6": {"boards": [{"id": str(value)} for value in range(4)]}}}
        rows = list(pairs(field))
        validate_pairs(field, rows, 8)
        for broken, message in (
            (rows[:-1], "missing field"),
            ([*rows, rows[0]], "duplicate"),
            ([{**rows[0], "trials": 8}, *rows[1:]], "replicate budget"),
            ([{**rows[0], "wins_a": -1, "draws": 17}, *rows[1:]], "nonnegative"),
            ([{**rows[0], "a": rows[0]["b"], "b": rows[0]["a"]}, *rows[1:]], "unexpected"),
        ):
            with self.assertRaisesRegex(SweepError, message):
                validate_pairs(field, broken, 8)

    def test_final_merge_rebuilds_actual_metrics_and_report_from_all_shards(self):
        self.plan["context_links"] = [{"label": "Frozen baseline context", "path": "content/units/plain.json"}]
        self.plan["configs"][0]["upset_diagnostic"] = {"seeds": [str(seed) for seed in range(7001, 7009)]}
        self.plan["configs"][0]["head_comparisons"] = [
            {
                "id": name,
                "candidate": name,
                "incumbent": "hard_field",
                "independent_seeds": 80,
                "first_seed": first,
                "chunk_seeds": 20,
            }
            for name, first in (("best", 9001), ("tribal_mixture", 10001))
        ]
        self.manifest = freeze_plan(self.plan, self.root)
        original_captures = captures

        def three_line_captures(spec):
            for row in original_captures(spec):
                for side, seat in enumerate(row["players"]):
                    if seat >= 6:
                        row["combat_start"][side]["policy"] = "other"
                yield row

        with patch(f"{__name__}.captures", side_effect=three_line_captures):
            self.lobby_results()
        field_folder = self.root.parent / "field-inputs"
        bundle = merge_lobbies(self.manifest, [self.results], field_folder)
        self.field_results(bundle, field_folder)
        self.head_results()
        with self.assertRaisesRegex(SweepError, "missing shard results: caps/upset"):
            load_results(self.manifest, [self.results])

        def fake_upset(argv, _log, _timeout, _root):
            field_path, plan_path, trials_path = map(Path, shlex.split(argv[-1])[-3:])
            field = json.loads(field_path.read_text())
            plan = json.loads(plan_path.read_text())
            trials_path.write_bytes(b"".join(canonical(row) + b"\n" for row in diagnostic_trials(field, plan)))

        with patch("sweep_shards.run_command", side_effect=fake_upset) as command:
            result = run_shard(self.manifest, "caps/upset", self.results / "caps/upset", self.root, field_folder)
            command.assert_called_once()
        upset_spec = next(spec for spec in self.manifest["shards"] if spec["kind"] == "upset")
        full_field = diagnostic_field(self.manifest, bundle, field_folder, upset_spec)
        frozen_diagnostic = diagnostic_plan(full_field, upset_spec["seeds"])
        trials = list(archived_rows(self.results / "caps/upset", result["artifacts"]["trials"]))
        self.assertEqual(validate_upset(full_field, frozen_diagnostic, trials)["fights"], 1024)
        for broken in (trials[:-1], [*trials, trials[0]]):
            with self.assertRaisesRegex(SweepError, "128 frozen trials"):
                validate_upset(full_field, frozen_diagnostic, broken)
        wrong_source = copy.deepcopy(trials)
        wrong_source[0]["field_sha256"] = "f" * 64
        with self.assertRaisesRegex(SweepError, "provenance differs"):
            validate_upset(full_field, frozen_diagnostic, wrong_source)
        output = self.root.parent / "merged"
        status = merge(self.manifest, [self.results], field_folder, output, self.root)
        self.assertEqual(status["state"], "complete")
        metrics = json.loads((output / "stages/caps/analysis/metrics.json").read_text())
        self.assertEqual(metrics["outcomes"]["r8_stat_leader_wins"]["seed_clusters"], 150)
        self.assertEqual(metrics["rounds"]["8"]["stats"]["n"], 1200)
        self.assertIn("150 independent lobbies", (output / "report.md").read_text())
        self.assertTrue((output / "stages/caps/analysis/adoption.json").is_file())
        self.assertEqual(len(status["stages"]), 20)
        upset = json.loads((output / "stages/caps/upset/upset-report.json").read_text())
        self.assertTrue(upset["complete_frozen_design"])
        self.assertEqual(upset["attribution"]["answer_necessary"]["count"], 128)
        self.assertEqual(upset["attribution"]["placement_necessary"]["count"], 128)
        self.assertIn("Controlled upset diagnostics", (output / "report.md").read_text())
        self.assertIn("They are not disjoint cause shares", (output / "report.md").read_text())
        for name in ("best", "tribal_mixture"):
            result = json.loads((output / f"stages/caps/analysis/head-to-head-{name}.json").read_text())
            self.assertEqual(result["independent_seeds"], 80)
            self.assertFalse(result["passes"])
            self.assertIn("outcome_rates", result)
        self.assertIn("32,256 fights", (output / "report.md").read_text())
        self.assertIn("merge-lobbies manifest.json", (output / "report.md").read_text())
        self.assertIn("Frozen baseline context", (output / "report.md").read_text())
        entry = bundle["fields"]["caps/field-r06"]
        path = field_folder / entry["path"]
        field = json.loads(path.read_text())
        field["rounds"]["6"]["boards"][0]["seed"] += 10000
        atomic_json(path, field)
        entry["sha256"] = file_sha(path)
        atomic_json(
            field_folder / "inputs.json",
            seal({key: value for key, value in bundle.items() if key != "bundle_sha256"}, "bundle_sha256"),
        )
        with self.assertRaisesRegex(SweepError, "global field sample differs"):
            merge(self.manifest, [self.results], field_folder, self.root.parent / "tampered-field", self.root)

    def test_field_shard_requires_honest_global_dependency_before_any_godot(self):
        with patch("sweep_shards.run_command") as command:
            with self.assertRaisesRegex(SweepError, "requires --inputs"):
                run_shard(self.manifest, "caps/field-r06", self.root.parent / "field", self.root)
            command.assert_not_called()
        self.assertFalse((self.root.parent / "field").exists())

    def test_head_to_head_seed_budget_is_frozen_without_inventing_strength_evidence(self):
        plan = copy.deepcopy(self.plan)
        plan["configs"][0]["head_to_head"] = {
            "candidate": "line_example",
            "incumbent": "hard_field",
            "independent_seeds": 80,
            "first_seed": 9001,
            "chunk_seeds": 20,
        }
        specs = shard_specs(plan)
        head = [spec for spec in specs if spec["kind"] == "head"]
        self.assertEqual(
            [(spec["first_seed"], spec["count"]) for spec in head], [(9001, 20), (9021, 20), (9041, 20), (9061, 20)]
        )
        plan["configs"][0].pop("head_to_head")
        plan["configs"][0]["head_comparisons"] = [
            {
                "id": name,
                "candidate": name,
                "incumbent": "hard_field",
                "independent_seeds": 80,
                "first_seed": first,
                "chunk_seeds": 20,
            }
            for name, first in (("best", 9001), ("tribal_mixture", 10001))
        ]
        expanded = shard_specs(plan)
        self.assertEqual(len([spec for spec in expanded if spec["kind"] == "lobbies"]), 3)
        head = [spec for spec in expanded if spec["kind"] == "head"]
        self.assertEqual(len(head), 8)
        self.assertEqual({spec["comparison_id"] for spec in head}, {"best", "tribal_mixture"})
        self.assertEqual(sum(spec["count"] for spec in head), 160)
        plan["configs"][0]["head_comparisons"][1]["id"] = "best"
        with self.assertRaisesRegex(SweepError, "unique"):
            shard_specs(plan)


if __name__ == "__main__":
    unittest.main()
