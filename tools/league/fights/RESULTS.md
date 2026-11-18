# GDScript fight proof: 18 November 2026

100,000 record-derived mutated cases accepted; zero rejected. Two independent runs of 1,000
cases are byte-identical and match the full-corpus oracle. This supplies the GDScript reference
for the Rust worker; cross-engine parity has not been claimed here.

The restoration and output contract is [FORMAT.md](FORMAT.md). The runner is
[`../gd/fight_run.gd`](../gd/fight_run.gd); the generator is [make_cases.py](make_cases.py).
Only these tools and this directory changed. Nothing in `src/`, `tests/`, `scripts/`, `addons/`
or card data changed. The worktree base is `5132760e`; the first working version was committed as
`08089de0` after validating 1,000 cases, before scaling up. Nothing was pushed.

## Corpus

Data is outside Git, in `/home/alex/league/fights/`:

| File | Contents |
| --- | --- |
| `cases.jsonl` | 100,000 accepted cases, ids 0..99,999 |
| `gd.jsonl` | 100,000 complete GDScript results with state strings and hashes |
| `cases.report.json` | Source-prefix manifest, coverage, rejection counts and shard timings |
| `verification.report.json` | Independent full-corpus audit and file checksums |
| `determinism-1.jsonl`, `determinism-2.jsonl` | Independent 1,000-case oracle runs |
| `determinism.report.json` | Byte comparison and comparison with the full corpus |
| `cases.work/` | Candidates, three output shards, logs and empty `rejected.jsonl` |
| `smoke/` | The earlier 1,000-case accepted corpus, oracle and manifest |

RNG seed: **20261118**. Tested with Python **3.14.4**, Godot **4.7.2**.
Source: **543** format-2 records from `gd/c0`, `gd/c1`, `gd/c2`, containing **46,185** living
player payloads, indexed by tribe and turns **1–22**. All source builds have rules fingerprint
`addc00f4679610334cc25fd0375ee92d0ce0dbc28c0fe1b4d04e69743e7f7d2e`.
The source scan omitted **1,805 ghost payloads**; there were no malformed or partial record
lines in this snapshot. Exact source byte prefixes and hashes are in the manifest, so later
records do not prevent reproduction.

## Accepted-case coverage

Counts below are cases containing the feature in either player's board/hand; tribes overlap.
Tribe names are content folders (`thorn` cards have the Briar tribe in card data).

| Tribe | Cases |
| --- | ---: |
| badger | 97,806 |
| locust | 94,913 |
| mouse | 94,355 |
| pigeon | 98,190 |
| thorn | 97,194 |

| Feature | Cases |
| --- | ---: |
| Golden units | 76,172 |
| Nonempty heaps | 98,673 |
| Nonempty hands | 96,235 |
| Native Reserve cards in hand | 22,134 |
| Slot stat buffs | 93,714 |
| Slot keywords | 73,124 |

| Mutation kind | Cases |
| --- | ---: |
| Swap units | 54,349 |
| Toggle golden | 53,926 |
| Change slot stat buffs | 53,905 |
| Change slot keywords | 54,275 |
| Resize heaps | 54,158 |
| Resize hands | 54,217 |
| Pair across records and turns | 100,000 |
| Repair colliding player ids | 19,623 |
| Renumber UIDs | 100,000 |

Heap resizing comprises **30,647 additions** and **23,511 removals**. Hand resizing comprises
**19,786 Reserve additions** and **34,431 removals**. These count mutation operations/cases,
not the number of entries/cards moved. Every case has at least one requested mutation kind.

**Rejected generated cases: 0 / 100,000 attempted.** No rejection reasons occurred. The
generator nevertheless records error cases and reasons, drops them, and generates replacements
when a runner returns an error. Script errors, warnings, crashes and incomplete output fail
the job. The separate importer checks deliberately rejected 12 invalid inputs (duplicate UID,
unknown card, colliding seats, ghost, out-of-range seed, missing payload field, invalid heap
numbering/tier, parameterized slot keyword, bad grant, malformed JSON and non-object JSON)
and confirmed that later valid cases still run. These fixtures are outside the proof corpus.

## Timing and checks

Three concurrent timed background processes handled **33,334 / 33,334 / 33,332** cases.
Their elapsed times were **1,082.028 / 1,088.562 / 1,104.640 seconds**. Summing those process
timers gives **32.752 ms per fight**, including input, validation, fresh-session construction,
restoration, combat, state serialization and output. Case generation/validation/concatenation
took **1,178.924 seconds (19m 39s)** after the initial record scan. The earlier single-process
1,000-case smoke run averaged **29.495 ms per fight**. `keep_fight_events` was false; the
unchanged core still constructs temporary combat events, as documented in FORMAT.md.

Passed:

- All 100,000 output ids match input ids, and every state string hashes to its output hash.
  The independent audit also checked seed/round/pairings, all eight seats, side-vs-seat winner
  and loser conventions, unique persistent UIDs, and `_next_uid` above every input and output
  UID. All 100,000 fights ended with `board_empty`.
- Determinism: physical line offset **66,668**, count **1,000**, run twice in fresh processes.
  Both output files are byte-identical, including full state strings, and equal lines
  66,668..67,667 (zero-based) of the 100,000-case oracle. Repeated output SHA-256:
  `141ab71b843d119a4d1c71a96529ea7816d647dfd0048fa57b0817a080030ac3`.
- Manifest replay reproduced all 1,000 smoke input cases byte for byte after more records
  appeared. An independent 100,000-input audit checked heap card ids/tiers/sequence numbers,
  globally unique consecutive UIDs, distinct seats and mutation/tribe coverage.
- `timeout -k 10 600 python3 tools/league/fights/check_runner.py`: passed. Checks include
  signed int64 boundary seeds, exact standing parameter internals, slot/heap restoration,
  golden/stat/origin restoration, hand UID bounds, known damage, no second Sentry End of Turn,
  rejected inputs followed by valid inputs, final lines without a newline, and `first/count`
  slicing across a multimegabyte UTF-8 prefix. The final runner skips shard prefixes in byte
  chunks; these checks and the repeated oracle outputs verify that slicing change.
- Clean headless import with writable XDG directories; final runner compilation/execution;
  GDScript lint/format; Python lint/format and compilation; `git diff --check`.

The full-corpus file SHA-256 checksums are:

```text
cases.jsonl c477248c038bccf52f5475730f8ebd1c194074da50e77bcefcc4c8ba578ea8bf
gd.jsonl    c9bf0af60a74f2baf56837c39be283da2b1a8f8f599ffb424f8af7dae91752fa
```

Cargo build/test/clippy were attempted but could not run: this worktree has no
`tools/league/Cargo.toml`. Rust comparison and the planted Rust bug check belong to the port
worker and remain outstanding. No Rust was written. No approval action was denied.
