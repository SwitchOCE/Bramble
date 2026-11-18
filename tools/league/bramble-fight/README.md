# Isolated fight runner

`bramble-fight` streams the [version 1 fight format](../fights/FORMAT.md), preserving its
validation errors, player seats, default session state, and exact Godot state string/hash.
It calls `GameSession::_fight` once; that method owns damage, write-back and both
`after_fight` contexts, including their effect RNG caches. It never starts a round or runs
End of Turn.

From the repository root:

```sh
(cd tools/league && CARGO_BUILD_JOBS=2 cargo build --offline --locked)
tools/league/target/debug/bramble-fight cases=build/cases.jsonl out=build/rust.jsonl first=0 count=-1
```

`first` skips physical lines, including malformed/blank lines. `count` selects that many
physical lines; omitted or `-1` reads to EOF. Errors remain individual result lines and later
cases continue. File, content and usage failures exit 2. Output flushes every 1,000 results;
timings and rejected counts go to stderr. `--cases PATH`, `--out PATH`, `--first N`,
`--count N` and `--repo-root ROOT` are accepted too. Paths prefixed `res://` resolve under
the repository root. Input and output paths must differ.

The optional case `content` field selects its content independently of other cases:

| Case metadata | Content |
| --- | --- |
| Absent | All default tribes, or the CLI `folders` fallback when supplied |
| `"content":"standin"` | `GameContent.load_folders([])` |
| `"content":{"folders":[]}` | Stand-ins |
| `"content":{"folders":["shared","badger"]}` | Those exact `src/content/<name>` folders, in order |

`folders=shared,badger` supplies the fallback for cases without metadata; `folders=` means
stand-ins. A case's explicit metadata takes precedence. Folder names contain ASCII letters,
digits, `_` or `-`. `shared` is included only when named. Each distinct recipe loads once and
is reused across cases; every case still receives a fresh session. JSON files remain unchanged.

## Reproducible random corpus and oracle

The generator defaults to 20,000 cases and stand-in content. It records its seed, exact ordered
folder recipe, script fingerprints, card/board/hand/golden/slot/grant coverage, rejected reasons
and timing in `cases.jsonl.report.json`. Rejected candidates go to
`cases.jsonl.rejected.jsonl`; replacements are generated until the accepted count is reached.
Use the same seed, count, engine/content files and generator version to reproduce case bytes.
Timing fields in the report vary. A smaller `count` is useful for a smoke check.

```sh
mkdir -p build/league-fights
timeout -k 10 14400 godot --headless --log-file "$PWD/build/league-fights/generate.log" \
  -s res://tools/league/gd/standin_fights.gd -- \
  cases="$PWD/build/league-fights/cases.jsonl" \
  out="$PWD/build/league-fights/gd.jsonl" count=20000 seed=20261118 folders=
tools/league/target/debug/bramble-fight \
  cases=build/league-fights/cases.jsonl out=build/league-fights/rust.jsonl
python3 tools/league/bramble-fight/compare.py \
  build/league-fights/gd.jsonl build/league-fights/rust.jsonl
```

Run Godot from the repository root after its initial timed `--import`. In restricted
environments use writable `XDG_CONFIG_HOME` and `XDG_DATA_HOME`. Inspect the Godot log and
captured stdout/stderr for script errors and warnings even when its process exits zero.
Do not treat missing results, mismatched ids or timeouts as accepted cases.

For a tribe worker, use `folders=shared,badger` (or another exact ordered selection) on the
generator. Its case metadata makes the Rust command unchanged.

To prove a fixture detects a deliberate mismatch, pass `--plant-attack CARD_ID` to the Rust
runner. This adds one attack to that loaded definition in memory before restoring any cases,
once per loaded recipe. Choose a card occurring in the corpus with its default base attack
omitted from the snapshot. Run the same comparison; it must fail and report the first state
field and byte offset. A planted card absent from every selected recipe is a usage failure.
Omitting the option restores normal behavior.
