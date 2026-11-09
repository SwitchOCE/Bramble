# Strong-field narrow follow-up review (9 Nov 2026)

Fresh scope reviewer, range 0946909..541963e. Verbatim report.

## Narrow follow-up: `ideation/strong-field`, `0946909..541963e`

**Counts:** 11 keep, 1 cut, 1 ask.

**Cut:** `docs/ideation/strong-field.md:297` says "The owner has since merged wave 1 and the harness at `0946909`." The orchestrator made that merge. Change "The owner" to "The orchestrator"; past reviews cut owner credits like this.

**Ask:** nothing reads `tests/fixtures/field/normal-9af89c2.json` (713 lines) any more. Delete it, since git history keeps it? (`content-9af89c2.json` is still used, by the exact-replay test.)

**Clear to merge into `ideation/main` at ba37b9e?** Yes, once the one-word cut is fixed.
- The merge is textually clean.
- Main has no non-doc changes since a51d9f3, the merge's other parent. So the worker's merged-tree gate covers the merged code: it ran at 8987512 with 1,882 Godot and 70 Python tests, and 541963e only changes docs.
- I agree peak memory needn't block while the mode is off in player builds. But gzip left peak memory unchanged (1.17 GB), so the pre-ship fix has to shrink what is parsed, not what is stored. The planned top-4-only recapture halves the trajectories, which should help.

### Your four questions

**1. Are the merge fixes right? Yes.**
- **Normal mode matches main.** I ran the re-pinned regression, with its fixtures and frozen content, on `ideation/main` (ba37b9e), which has no field code. It passes: 1 test, 9 assertions, all four game fingerprints equal.
- So normal mode is byte-identical with and without strong-field, not just identical to the merge commit. The worker's gate shows the head also matches 0946909.
- **Allowed keys:** the whitelist now accepts any key in `GameConfig.defaults()` or the pass 3 rate defaults. That's loose, but any change in behaviour would still change the game fingerprint, so it's acceptable.
- Freezing and restoring the pass 3 rates in the frozen-content helper has its own test.

**2. Is the loader still loud? Yes.** My probe ran 11 malformed cases, and each returned a specific error:
- truncated gzip, a flipped byte, a missing gzip trailer;
- an empty file, gzip of nothing;
- invalid JSON, a JSON array;
- gzip bytes under a `.json` name, plain JSON under a `.gz` name;
- a missing file, a missing `content/pass3`.

Valid gzip loads, and the folder rename was restored afterwards. The new tests cover only a bad header; my probe covers the rest.

**3. Do the presentation fixes add on-screen text? No.** Every string literal added under `src/ui` is an existing label ("Field ghost", "A ghost"), a comparison ("Rival ", "Ghost"), a node name or a comment.
- The Settings tray is now created only when the flag is on, and the rest is centred. In player builds, the empty gap is gone.
- The scout-heading shift also applies in normal games, but only while the Last Stand strip shows (Last Stand active). It moves the heading and shop down and adds no text.

**4. Anything blocking the merge?** Only the cut. Worth knowing: main's current export presets don't include `content/pass3/*.json`, although main reads the pass 3 rates in 38 places, including the state shown to the player. This branch adds that include to all four presets, plus an export-smoke check for it. If strong-field's merge slips, main's exports may need that line on their own. I didn't test a current main export.

### Items (keep unless marked)
- The merge resolution keeping both key sets.
- The re-pinned regression and the frozen 0946909 content.
- The allowed-keys rule.
- **Gzip storage loaded through one validated snapshot.** The worker's figures: 50.35 → 2.08 MB stored, start-up 4.6 → 2.4 s, peak memory about 1.17 GB both before and after.
- The loader's explicit errors.
- `content/pass3` added to the validated folders, the exports and the export smoke.
- Validation of pass 3 rate overrides in a library's config.
- The presentation fixes.
- `rg` replaced by `grep -E`, and the stale pointers corrected.
- The load-profiling tool and its evidence.
- The changes to the comparison tool.
- **Ask:** the archived 9af89c2 normal fixture.
- **Cut:** the owner credit at `strong-field.md:297`. The 9d quote now matches the record.

### What I ran
All Godot runs held the shared lock with the 3 GB cap, one at a time, in temp copies made with `git archive` (since deleted).
1. The re-pinned regression on an `ideation/main` copy.
2. The malformed-library probe on the head tree. My first attempt failed the project's strict typing; I fixed it and reran.
3. A read-only `merge-tree` of 541963e into `ideation/main`.

**Not run:** the full suite and the export smoke. I relied on the worker's logs at 8987512 and 44c7329.