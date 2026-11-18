# Bounded rules-engine speed pass — 18 November 2026

Baseline: `d39e812845293aa31e8c97e39c65b28645e64df3`. All implementation changes are under
`tools/league`. No card data, GDScript engine, root tests or scripts changed. Nine small local
implementation commits were made; nothing was pushed. This report is a separate documentation
commit. The existing proof programs, reference corpora and pre-existing test bodies are unchanged.

Whole games meet the 2× target. The final median fight speedup is **2.56×**, below the
3× target. The quiet first final pair was 2.87×; the profile's remaining costs are spread
across aura evaluation, unit/query dispatch, setup and after-fight work. The last vector-removal
check improved `_fight` by about 3%, so this pass stops here.

## Profile and decisions

`perf` exists but the kernel denies recording (`perf_event_paranoid=4`). Temporary targeted
scope timers were used and removed before the final build. Initial late-fight measurements:

- `Combat::run`: 744 µs/fight; aura refresh 321 µs (43% of run, inclusive).
- Combat-unit display views: 126 µs/fight, 41,402 calls across 2,000 fights (17% of run).
- Initial bench CPU parts: hashes 97.95 ms/game, views 85.00 ms, actions 26.58 ms.
- Recruit fixture: legal 27.9 µs, move 4.1 µs, view 111.3 µs. Snapshot building alone cost
  42 ms across 14,014 unit snapshots in that run.

An audit of Rust and pinned GDScript found no gameplay reads of combat events or `fight["after"]`.
The aura event's `after` index is presentation-only. Session triple events are read by league
round statistics and remain available.

A follow-up profile after log elision found aura passes at 131 µs/fight (46% of combat run),
setup at 38 µs and after-fight contexts at 32 µs. This justified the final aura metadata and
allocation changes. The CPU parts in the final bench are:

| Part | Before ms/game | After ms/game |
| --- | ---: | ---: |
| state_hashes | 97.242 | 46.338 |
| views | 87.582 | 26.179 |
| engine_act | 26.947 | 17.473 |
| bots | 4.780 | 4.268 |
| round_stats | 2.686 | 1.886 |

## Changes and equivalence

1. **Combat log construction:** `keep_fight_events` propagates to Combat's runtime `keep_events`.
   With it false, display dictionaries, board/reserve views, held events and shown-stat comparisons
   are omitted. The living-health guard, all rule hooks, RNG draws and trigger limits still run.
   The true path keeps event order and aura indices. Session logs and fight `after` data remain.
2. **Hash construction:** GameSession's single field list filters excluded fields before conversion.
   Retained fields use the same conversions and order. Canonical Godot JSON and SHA-256 bytes remain
   exact. JSON sorts borrowed entries with the same Godot sorter, writes UTF-8 spans between the
   same escape bytes, formats integers directly and preallocates dictionaries.
3. **Dictionary hashing:** `IndexMap` still controls insertion/replacement/`shift_remove` order;
   only its hash buckets use the already-vendored `foldhash` 0.2. Standard `IndexMap` conversions
   remain supported. This is separate from the SHA-256 state hash.
4. **Owned views:** fight snapshots read the same 14 integer stat layers directly. `Me` reuses its
   freshly copied payload containers for slot/heap/standing views. Immutable past-fight histories
   use copy on write; retained views keep their old history. Payload/SnapUnit clones remain deep,
   and no view gains a handle to a live game object.
5. **Recruit actions:** raw dictionaries and typed actions use one ordered engine enumeration.
   Sandbox legal/view calls emit typed values directly. The harness materializes only the chosen
   action's dictionary with the same keys, order and values. The old builder remains; the public
   `league-api` addition is `harness::view_typed`.
6. **Aura work:** empty grant lists skip empty binding allocations. Context construction waits
   until an aura needs it and allocates empty dictionaries only for empty slots. Pure stats reads
   reuse maximum health while preserving Vector3i narrowing. All 18 existing aura mechanics state
   which hooks they implement; only inherited zero/empty trait hooks are skipped. Unknown/custom
   mechanics conservatively run every hook. Existing masks must be updated when adding an aura hook.
7. **Pure queries and arrays:** parameter emptiness checks read the integer/text stores that
   `to_dict` would emit. Membership checks avoid concatenated hook lists. Cached boards and private
   batches use an owning index iterator with no borrow across callbacks; genuine source snapshots
   (including joiners' `duplicate()`) remain. Pure collection pipelines avoid intermediate vectors.
8. **Release compilation:** thin LTO and one codegen unit allow engine/API helpers to inline across
   crate boundaries. This increases release link time (the final build took about one minute).

Focused new checks cover skipped-field conversion, JSON bytes/escaping, dictionary order,
all 14 snapshot layers, every card's ordered typed actions and selected dictionary fields,
event elision with RNG/trigger equivalence, and live-array alias/ownership semantics. Existing
planted attack/tier hash checks also pass.

## Before/after measurements

All figures below use saved pre-pass binaries and final release binaries, identical inputs,
seeds and flags, run sequentially without other work from this pass. Other machine workloads
varied substantially during the final runs, especially the third fight pair and baseline bench.
Wall times include that interference; the CPU columns and complete trials are included so it
is visible. An earlier quieter paired bench was 249.5 → 117.8 ms/game (2.12×).

| Workload | Before | After | Speedup |
| --- | ---: | ---: | ---: |
| Late `_fight`, median of 3 runs | 843.772 µs | 328.993 µs | 2.56× |
| Late runner including restore/dump, median of 3 | 2538.550 µs | 1498.342 µs | 1.69× |
| `league bench --games 20`, mean | 444.160 ms/game | 147.234 ms/game | 3.02× |
| `league bench --games 20`, median | 443.618 ms/game | 141.913 ms/game | 3.13× |
| 50-game match, 3 threads, wall | 8.120 s | 3.810 s | 2.13× |
| 50-game match, total user + system CPU | 16.790 s | 7.920 s | 2.12× |
| Sandbox legal actions | 31.524 µs/call | 3.051 µs/call | 10.33× |
| Sandbox move action | 4.734 µs/call | 3.394 µs/call | 1.39× |
| Sandbox legal + move | 38.881 µs/call | 6.529 µs/call | 5.96× |
| Sandbox view | 132.057 µs/call | 43.226 µs/call | 3.06× |

Late cases: `/home/alex/league/proof/late-cases.jsonl`, all 2,000 fights per run.
`fight_only_us_per_fight` from the last stderr line, with no restore/dump in that timer:

| Trial | Before µs | After µs | Speedup |
| --- | ---: | ---: | ---: |
| 1 | 827.679 | 287.985 | 2.87× |
| 2 | 843.772 | 328.993 | 2.56× |
| 3 | 1129.496 | 466.176 | 2.42× |

Recruit uses the first late case, round preserved, its board/hand restored into a sandbox,
5,000 legal calls, 5,000 accepted alternating moves, 1,000 views and 5,000 legal/move pairs.
The benchmark is `league-api/examples/recruit_bench.rs`.

## Final proofs

| Required proof | Result |
| --- | --- |
| Offline locked release workspace, bins and examples | Pass |
| All-tribe replay, 3 processes | **1,000/1,000**, **45,900 checkpoints**, all complete |
| Fight corpus, 3 ordered slices | **100,000/100,000 matched**, **3,109,481,223 exact state bytes**, zero rejected |
| `league selfcheck`, 2 threads | **1,000/1,000**, **956,706 lines**, **909,806 actions** |
| Tribe/stand-in replay, 2 processes | **2,000/2,000**, **92,124 checkpoints**, all complete |
| Badger / locust / mouse / pigeon / thorn | **300/300 each**, included in combined tribe result |
| Stand-ins | **500/500**, included in combined tribe result |
| Offline locked workspace tests | **68 passed**, zero failed (62 ordinary tests, 6 doc tests) |
| Strict workspace Clippy, all targets, `-D warnings` | Pass |
| `cargo fmt --all --check`, `git diff --check` | Pass |
| Extra late before/after comparison | **2,000/2,000**, **66,234,436 exact state bytes** |
| Extra timed match record comparison | **50/50 files byte-identical** |

Commands ran from `tools/league`, with `CARGO_BUILD_JOBS=2`, Rust on PATH and a worktree-local
`TMPDIR` under `.copies/speed/tmp`. Each long command had `timeout -k 10`; proof stages were
sequential, with at most three fight/replay processes. Measurement and proof outputs stayed in
ignored worktree artifacts. `/home/alex/league/fights/{cases,gd}.jsonl` were read only.

```sh
cargo build --release --offline --locked --workspace --bins --examples
proof/replay_all.sh 3 /home/alex/league/records/gd/c0 /home/alex/league/records/gd/c1 /home/alex/league/records/gd/c2
# bramble-fight: first/count = 0/33334, 33334/33333, 66667/33333; concatenate in that order.
target/release/bramble-fight cases=/home/alex/league/fights/cases.jsonl out=<new-file> first=<first> count=<count>
python3 bramble-fight/compare.py /home/alex/league/fights/gd.jsonl <combined-new-file>
target/release/league selfcheck --records /home/alex/league/records/gd/c0 --records /home/alex/league/records/gd/c1 --records /home/alex/league/records/gd/c2 --threads 2
proof/replay_all.sh 2 /home/alex/league/records/{badger,locust,mouse,pigeon,thorn,standin}
cargo test --offline --locked --workspace
cargo clippy --offline --locked --workspace --all-targets -- -D warnings
```

Timing commands (same arguments before and after; distinct output paths):

```sh
target/release/bramble-fight cases=/home/alex/league/proof/late-cases.jsonl out=<new-file>
target/release/league bench --games 20
target/release/examples/recruit_bench /home/alex/league/proof/late-cases.jsonl 5000
# seeds.txt contains decimal seeds 1 through 25.
/usr/bin/time target/release/league match --red flow --blue random --games 50 --threads 3 --seeds seeds.txt --secret speed-pass --out <new-directory>
```

Raw measurements are in `.copies/speed/final/`; final proof logs are
`.copies/speed/{replay-all-final,fights-compare-final,selfcheck-final,replay-tribes-final}.log`.
The combined new fight output is `.copies/speed/fights-final.jsonl`. Temporary profiling helpers
and binary copies are ignored under `.copies/speed`. No profiling instrumentation remains in
production code. Git metadata escalation was approved; there were no approval rejections.
