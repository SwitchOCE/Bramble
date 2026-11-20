# Ghosts: saving, finding and picking runs

The game's local ghost store and matchmaker, and the writer that saves the player's own runs. They stand in for the server (docs/workstreams/third-run/ghost-server-plan.md). Reading a run's boards into a game is part of the rules and stays in `src/core/ghosts/ghost_run.gd`.

This folder is outside `src/core` on purpose. It holds no rules. It isn't in the rules fingerprint (`RecordBuild`), so a fix here never retires the field of ghosts. It isn't mirrored file by file in the Rust engine. Its Rust counterpart is the `bramble-ghosts` crate, and the proof below keeps the two the same (owner, 20 Nov 2026).

- `GhostStore.new(root)` opens the same content-addressed folder as Rust. `add(bytes)` returns the stored ID and reuses that ID for another cut of the same record seat. `fetch(id, library, registry)` checks the hash before returning the run. `find(query)` returns Rust-compatible run summaries. `rebuild_index()` regenerates `index.jsonl` in ID order. Check `store.error` after a write or query to distinguish a failure from an empty result.
- Queries accept optional `rules_hash`, `kinds`, `labels`, `placement` (an inclusive `[min, max]` pair), and `exclude` (a dictionary keyed by ID). With no query, `find()` returns the whole index. Use `index_only: true` to require the index and skip the fallback run scan. Override `add`, `fetch`, and `find` to supply another backend.
- `LayeredGhostStore.new(writable_root, shipped_root)` can read a shipped `res://` field and a `user://` field of saved player runs. It uses the writable folder for adds and index rebuilds. It returns each ID once across both folders. Use `shipped_only: true` to query the field alone.
- `Matchmaker.pick(store, rules_hash, band, exclude, rng)` returns seven distinct IDs in seat order or an error message. The band accepts store filters including `kinds`, `labels` and `placement`. It skips unfinished runs and uses at most one cut of each record seat.
- Call `GhostRunWriter.cut(game.record, made, player, label, opponent_store)` with a finished record and pass the result's `bytes` to `store.add`. The writer replays the saved record to recover pre-fight health, armor, and gold, and hashes the exact record bytes. `made` is supplied by the caller. For async games the opponent store must still resolve the original run IDs.

The [cross-language proof](../../tools/league/proof/ghost_core.sh) compares the two stores and matchmakers
and cuts the same finished Godot games in both languages. Run `tools/league/proof/ghost_core.sh <data folder>`; `recheck.sh` runs it too.
