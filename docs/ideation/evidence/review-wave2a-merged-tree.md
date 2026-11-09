**Narrow scope check: `ideation/wave2a` 09d60646..a563fd5b**

The brief gave me the owner's standing rules and the orchestrator's brief, but no plan text the owner approved. That doesn't change any verdict below.

| keep | cut | simplify | ask |
|---|---|---|---|
| 10 | 0 | 0 | 0 |

**Does it move the problem?** Yes. Main's tests now pass on the merged tree, and no assertion was loosened to get there. **No cut or ask items.**

**Is 2fa5247f clear to push once the cloud gate passes?** Yes. The final merge adds no `src/` or `content/` changes. It adds only main's `--docs-only` gate option and main's newer tests (skilled Birds, line bans). Those tests have never run against this code, so the cloud gate is their first run.

**1. Fixture re-record (f8bac021): intended, but the cause it names is vague.**
- The four seeds and every original config value are kept. The 42 added rate values equal the archived 0946909 rates. The old fixtures are byte-identical.
- I replayed both versions on temp copies:
  - the main parent cc6d26d5 reproduces all 4 old hashes;
  - the head reproduces all 4 new hashes.
  So the change comes from wave2a's code, not from the merge.
- First places the games split:
  - Games 1–3: Bridge Toad and Little Nip have +1/+1 less after a fight. Wave2a's pool rule (acf3d633, `pending_gains.gd`: "Takes and Soak share one queue") holds those gains until the next turn. That rule is intended and was reviewed.
  - Game 4: a bot doesn't buy Russet in round 3. That fits the Russet valuation fix, but I didn't prove it.
- The log names Cluricaun End of Turn and Queen Start of Turn first. Neither is what first changes these games. The log line could name the held Take/Soak gains instead.

**2. Time limit (e46027fc): no check relaxed.**
- `GUT_TIMEOUT` goes from 900 to 1,200 s. It is a hang guard on the whole GUT step, not a performance test.
- It moved because the suite slowed: 742.7 s before the merge, 882.5 s after (98% of 900).
- This is its second raise today. Before 50e28e79, GUT used the 600 s Godot limit.
- On CI it can't trigger anyway: the PR job's `timeout-minutes: 20` kills the job first.

**3. Separate GUT user data (d3c5dba9): correct, contained, with one gap.**
- It sets `XDG_DATA_HOME` to a fresh temp directory for the GUT command only. It doesn't touch the shared user data folder; GUT runs simply stop using it.
- The shared folder also holds export templates and the debug keystore (per `cloud-setup.sh`). GUT doesn't need them.
- The full gate passed all 2,142 tests this way, so no test depends on saved user data.
- **Gap:** the race it fixes happened in targeted runs, which don't go through `check.sh`. Workers now run only targeted tests, so they still share the folder. The two new tests also write fixed `user://` paths. The planned in-repo slot wrapper could set the same variable.

**4. Do the cache fixes change non-test behaviour?**
- a3b6dfe9 is test-only.
- f406dd5c and 067429a3 change `src/core/field_library.gd`, so they do change non-test behaviour. The effect is limited to which field libraries load, and with which rates. Gameplay rules are untouched.
- Code that uses it: the game UI (`core_port.gd:61`), field rivals (`field_rivals.gd:27-29`) and `play_game.gd`.
- It is needed: 18 of main's field tests failed because wave2a's empty preset rates were rejected.
- The two values it now skips are safe to skip: `pass3_text_defaults` only feeds card text (`scale_overlay.gd:81`), and the exact-rate values are still compared exactly after being restored.
- New tests cover it in `test_field_library_v2.gd`.

**5. Out of scope or gold-plated?** Nothing found.
- The Python changes (3fbe34bd, 2c1fc9c5, 53925ecf) were needed for main's Python tests. The accounting report now reads its published paper JSON instead of recomputing it from today's rates, which is right for a historical report.
- The splash wording (5a8b5c0a) matches the reviewer's text.
- The old fixture is kept as the brief asked. Only the recorder reads it.

**Files**
- Probe and the dumped games are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/rv-merged/`:
  - `probe/divergence_probe.gd`
  - `out-main-game*.json`
  - `out-head-game*.json`
- The re-record log is in `/home/alex/code/Bramble-ideation-balance/docs/ideation/content/pass3/wave2a-build.md`.
