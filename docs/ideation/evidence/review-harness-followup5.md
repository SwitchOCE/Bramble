# Harness follow-up review 5 (10 Nov 2026)

Fresh scope reviewer, range 109d404..0043d62 on ideation/harness. Verbatim report.

## Harness follow-up 5: `109d404..0043d62` on `ideation/harness`

**Counts:** 14 items: 11 keep, 0 cut, 1 simplify, 2 ask.

**Cut items:** none.

**Merge:** clear to merge into ideation/main at `034b098`. It can't be a fast-forward: main has moved 13 commits past `cd07673`, which is still the common base. No files overlap, and `git merge-tree` against `034b098` is clean. Main's newest commit (`034b098`, the triage) is docs only. But main also brought the strong-field changes to `game_config.gd` and `game_session.gd`, which `bench.gd` uses. The worker's merged-tree gate log is only in `build/` and isn't committed; I didn't read it. Run the gate on the merged tree before pushing, and commit its log as earlier rounds did.

**Does it move the original problem?** It shows where the gap is; it doesn't fix the scale.
- Real R12 boards reach 0.17–0.72× of paper.
- Growth from R8 to R14 reads ×1.29 a round across all seats, which the doc labels preliminary. That figure isn't comparable with the ×1.14 pre-wave-1 baseline: the config, seat mix and combat all differ.

**The two triage findings: neither blocks the merge. Both are follow-ups.**

1. **Lobby config (`tribes_per_lobby` 0, both caps off):**
   - **Disclosed only partly.** The doc's first line says "size/rate caps off" and its second paragraph says "all tribes available". It never says that `full_game()` ships 5 tribes with both caps on, or why the run differs.
   - **Fairies and Tempo: not misleading.** Fairies at 0.17–0.27 can't reach 0.5 from these settings, and Tempo at 0.72 stays inside the band.
   - **Homecoming: misleading at the edge.** It reads 0.439 [0.414, 0.460], and 0.490 against the built-timing paper. With all six tribes in the shop, Birds are offered less often than with five, so "outside the band" may not hold at the shipped config. Caps off pushes the other way, but the old baseline showed the caps barely move the median.
   - **For the rerun the triage called for:**
     - Plan v3's checkpoint config has caps **off**, but `full_game()` has them on. Use 5 tribes with caps off, or run both.
     - With 5 of 6 tribes, about a third of lobbies lack Birds or Fairies. The driver treats the resulting fallback as an error ("committed seat fell back"), so it needs a roster that forces both tribes in, or separate lobbies per line.

2. **Line-file rules that no bot runs (`thank`, `max_copies`, `stayer_cap` and more):**
   - **Disclosed in HARNESS.md:674:** "conditional-buy, copy, stayer-cap, spell, thank and placement prose remains advisory to the shared Hard pass-3 adapters".
   - **The accounting doc only says "Partial prose execution in the shared Hard adapters".** It doesn't name the rules.
   - **What actually runs:** tribe, base strategy, priority, keep (or the first three of the stayer rank), climb, the engine flag, the switch, the flight limits (`from_round`, `keep_home_min`, `max_away`, `allowed`), and the Court's Annis slot, which is still keyed by line name.
   - **Hard does thank:** it has its own thank logic (`bot_pass3.gd` `thank_ready`/`thank_aim`). The line file's thank schedule is what goes unused.
   - **Strict loading is not a correctness problem.** Rejecting unknown keys catches typos, which is what the call asked for. The cost is that `_validate_advice` type-checks about 20 fields no bot runs, such as `max_copies` counts and `stayer_cap` rounds, so they look enforced.
   - **Follow-up:** split the loader's key list into rules bots run and advisory text, and print that split in the doc. This fits the triage call that "the line files hold only rules a bot runs".

**What I checked:**
- **Paper figures:** I rebuilt `wave1-accounting-paper.json` from the models. It matches exactly: 615, 361, 530 and 945 at R12.
- **Medians:** I recomputed every line's medians from the committed boards archive. They match the doc (270, 260.5, 142 and 160 at R12).
- **Python suite:** 154 tests pass at `0043d62`.
- **GUT:** all of `tests/core` passes at `0043d62` on its own: 1,509 of 1,509, with no problem lines. My filter didn't narrow the run, so it held the shared lock for about 4 minutes, one process.
- **The call's fixes all landed:**
  - The Whistlers setup is now the doc's Tern swap: Whistlers at 10/12, Nest, sky and both Jays kept, six different Birds, no omen. The old omen rows are withdrawn.
  - Starting-line labels are in `bench.gd`, `field.py` and `metrics.py`. The accounting run already grouped seats by assigned line.
  - The provenance rule for pre-wave-1 evidence is stated.
  - The loader reads tribe and base strategy from each file, and a Bog/Hunters test file loads without code changes.
  - `max_away` applies only when a policy sets it.
  - Granny is labelled as pass 2 Oozes.
- **No new pass/fail bars:** the only classification is the plan's R12 0.5–2× check, and growth is marked preliminary with no bar.

### Table
| # | Item | Verdict | Evidence / action |
|---|---|---|---|
| 1 | Accounting suite, roster, frozen plan and driver (`bench_suites.gd`, `bench.gd` `assigned_line`, `wave1_accounting.py`) | keep | Plan v3 step 4. The driver was edited after the run (formatting only), so the plan's `driver_sha256` matches `fa95a41`, not head; HARNESS says the run is frozen at `fa95a41`. |
| 2 | Paper conversion (`wave1_paper.py`, paper JSON) | keep | Rebuilt; matches |
| 3 | Built-timing reconciliation with its own "inside same band" column | simplify | Keep the ratio, drop the second classification. Only one denominator decides, and Homecoming's 0.490 makes a second pass/fail column confusing. |
| 4 | Results JSON, boards archive, seat labels, progress | keep | Medians recomputed; match |
| 5 | `wave1-accounting.md` | ask | Add one sentence saying how the config differs from `full_game()` and why; mark Homecoming's call as config-sensitive (triage 1) |
| 6 | Preliminary growth table | keep | Labelled; no bar |
| 7 | Starting-line attribution | keep | As called |
| 8 | Whistlers Tern-swap recipe | keep | Matches the doc. When step 5 runs it, record what stands across the Whistlers: the doc's 42%→96% assumes it halves the enemy carry. |
| 9 | Pre-wave-1 provenance rule | keep | As called |
| 10 | Generic loader (tribe and base from file, unknown keys rejected) | keep | Tested, including Bog/Hunters |
| 11 | Type checks on fields no bot runs (`_validate_advice`) | ask | Split rules bots run from advisory text in the loader and the doc (triage 2) |
| 12 | Optional `max_away` | keep | Ordinary Hard unchanged |
| 13 | Granny labels, smoke qualifications JSON | keep | As called |
| 14 | `base_strategy` and `allowed` moved into the line files | keep | Replaces the hard-coded copies; same values |