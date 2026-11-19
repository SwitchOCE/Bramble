# Bramble ghost runs

Build from `tools/league` with `cargo build --offline --locked --release -p bramble-ghosts`.

```sh
bramble-ghosts cut --match MATCH --store STORE --made 2026-11-19T11:00:00Z
bramble-ghosts verify --store STORE
bramble-ghosts verify --run PATH/ID.json
bramble-ghosts index --store STORE
```

`cut` reads the harness's `records/game-*.jsonl` and `games.jsonl`. It uses the
seat's `label` when present and its `bot` name otherwise. The record's build
fingerprint must match the rules checkout used for replay. Use `--repo-root`
when replaying against a different checkout. `--include-unfinished` includes
valid partial records with fight snapshots. Malformed records are errors.

Use the same `--made` value to reproduce a cut. The store writes each run
under its SHA-256 id in `runs/<first-two-hex>/<id>.json` and uses `gzip` from
`PATH` to archive the original record in `records/<record-sha256>.jsonl.gz`.
`verify` checks run hashes and structure. `index` rebuilds `index.jsonl` from
the verified run files.
