*[Saved verbatim from the scope-reviewer's hand-back, 10 Nov. Calls: DECISIONS (ideation/main) "S3 measurement and delivery: review calls".]*

## Scope review: `ce50d9d7..00ed62b9` (S3, ideation/measure)

**Counts:** 13 keep, 0 cut, 2 simplify, 1 ask.

**Does it move the original problem?** Partly. The contamination drop unblocks A3.5's simulation runs, which serves the owner's "rely far more on empirical simulation data". The memory test settles the default-opponent call, and it went against the strong field: a field start adds 665 MB, so the default is normal Hard. Nothing in this change works toward the owner's "best we can make" bot.

**Ask and simplify items, one line each:**
- **Ask:** `export_presets.cfg` now ships `content/fields/baseline.json.gz` in every preset. `strong_field` stays off (`src/ui/settings.gd:17`) and the memory budget failed, so nothing in a player build reads the file. Ship it anyway (plan §5 says "library required"), or leave it out until the budget passes?
- **Simplify:** `scripts/export_smoke.sh` has two modes. The default mode still fails any pack that contains the library, and CI runs that mode on `ideation/gate/**` (`ci.yml:293`), so CI's export smoke breaks as soon as A6 commits the library. The library-required mode also skips `boot_linux_field`, so the build that ships never checks that its default opponents are Bots. Fix: one mode that requires the library, and keep the feature-off probe.
- **Simplify:** nine old per-build scripts are still in `build/` (`export-ideation5-7.sh`, `deliver-*`, `finish-*`, `run-ideation*-checks.sh`). The plan says "the one export script", and git already keeps them.

**Findings**
- **Game behaviour and A3.5's numbers:** no change beyond the drop. With no contaminated trials, `analyze` gets the same seeds; only the report's labels and contamination fields are new. The one game-code edit, in `src/core/field_library.gd`, copies `FightCapture.config_for` (`tools/sim/fight_capture.gd:6-12`) line for line. It was needed because `tools/` is left out of packs. The `field_library.py` fixes (15-digit hashes, line profiles, starting-line labels) affect what goes into the field library, not A3.5's runs.
- **Contamination drop:** in scope, and the claim holds. Raw `ban_violation` records stay in the capture, and dropped seeds are listed in progress, the result and the analysis archive. 2/100 passes and 3/100 fails, counted over all chunks. Missing audits and policy mismatches still raise errors.
- **Export script:** the claim holds for the dry run. README line 1 has no parentheses, and the README names the commit, tag, library SHA and certificate, checked against the keystore and build 7. The real run (tag, `latest`, evidence file) was never run. It also needs the library committed, because it builds from `git archive`. The two extra wrappers are fine: the Godot slot wrapper matches the owner's 10 Nov lock note, and the private `/tmp` fixed a truncated APK. The "Quilboar absent" check is in plan §5.
- **Memory test:** it measures what criterion 4 says. It runs the real Linux export, peak RSS from `/usr/bin/time -v`, normal start against field start on the same binary, median of three runs each. A normal start never loads the library (`core_port.gd:58`). The fail is clear: 1,035,820 against 386,008 KiB, and the two sets of runs don't overlap. Caveat: it used a throwaway library (480 trajectories, 37 MB of JSON), not the shipped one. Build 8's checks re-measure it.
- **Pack load and fail-loud checks:** they pass on the Windows pack and on a zip of the APK's assets. That is the APK's bytes, not a device run.
- **Tutorial and rules filters:** added. `content/tutorial/` and `content/rules/` don't exist yet, so this is untested against real files.
- **History:** nothing discarded. The reset to `origin/ideation/main` left from `340110f0`, which ideation/main already contains. The four amends were never pushed (`origin/ideation/measure` = `340110f0`).
- **Ownership:** `tests/sim/test_line_bans.py` and `test_field_profiles.py` are outside S3's file list. The worker says so; they test only S3's own code.

**Probes**
- Ran the changed tests with `python3 -I` on a cut-down `git archive` copy: `test_line_bans` 11/11, `test_field_profiles` 3/3, `test_wave1_baseline` 7/7.
- The dry-run artifacts match the claims: `results.json` delta 665,407,488 bytes, `within_300_mb: false`. `export_smoke: all checks passed`. Each of the three pack listings has the library once.
- Checked the reflog, ancestry and CI triggers.
- The first archive copy hit the shared `/tmp` disk quota. I removed only my own copy and worked from a 2.3 MB subset in the orchestrator's scratchpad.

**Open question for the orchestrator:** the field costs 665 MB because a 37 MB JSON parses to about 640 MB. Before you log normal Hard as the default, decide whether anyone should try to cut that (a smaller library, or loading it in pieces), given the owner wants one bot at full strength.
