# S3 export review simplifications — 10 Nov 2026

Memory was completed first in `fb659fc3`: the unchanged 480-trajectory bundle
now adds **166.1 MB** median peak RSS, versus the 300 MB limit. All three fixed-seed
full-game traces match the eager reader. See [memory-lazy.md](memory-lazy.md).

## One export smoke contract

`scripts/export_smoke.sh` now always requires
`content/fields/baseline.json.gz`, in every pack it exports. The old
`REQUIRE_FIELD_LIBRARY` switch and the field-exclusion branch are removed.
The early missing-bundle check fails clearly before doing exports. Every preset
still includes the library; feature activation does not determine pack presence.
`build/export.sh` uses this single contract without a field-mode environment flag.

Every Linux smoke also runs the packed UI/CorePort feature-off probe. It checks
that defaults are Bots, the Strong field choice is absent, a saved field preference
still starts Bots, and the game can choose a hero and finish its first round.
Positive library loading is checked separately from the disabled-feature UI.
The probe explicitly disables the runtime feature so opt-in dry-run packs also
exercise this path; ordinary feature-off presets already initialize it disabled.
The settings probe suppresses its audio instance to avoid starting a discover
voice immediately before headless teardown; it does not claim audio coverage.

CI's export call now explicitly requires a committed library and runs the same
single smoke contract, including its existing `--aab` option. With no committed
library before A6, requested export jobs fail with a clear recapture instruction.
No automatic fixture/capture step was added. The actual workflow's gate pushes
run static/test jobs and skip the exports job; manual runs and export-labelled
PRs run exports. Its job conditions are unchanged.

Validation:

- Missing-library preflight: exit 1, explicit required-bundle message.
- Actual feature-off Linux, Windows and required Android APK exports: passed;
  all three listings contain the library. Linux boots and the packed default/
  saved-preference checks pass without logged errors.
- The feature-off Linux PCK reports `OS.has_feature("strong_field") == false`.
- Positive Linux field load validates the unchanged bundle SHA
  `6ca0dc2b191c53007dd2b8f2415305077b1e19fbd16b7310fe246030e0cda396`.
- Logs and artifacts: `build/export-simplify-check/`; primary log `smoke.log`;
  packed UI log `logs/export_boot_linux_field_settings.log`; feature flag log
  `feature-flag.log`; missing-bundle log `missing-library.log`.
- Test preparation reused the frozen lazy-export project's native code/cache,
  copied in the new smoke/probe scripts, and removed the throwaway opt-in feature
  from that snapshot's presets. Outputs are separate from the memory packs. The
  original memory snapshot source files were restored afterward; its packs, README and
  RSS records were not modified.
- Workflow YAML parses and its required-library call was checked. ShellCheck,
  required ruff checks and both GDScript lint scopes pass. The final targeted GUT
  run passes 36/36 tests, including field settings; all 32 existing targeted
  simulation Python regressions pass. No Actions run or AAB
  export was started locally; the AAB path shares the pack-presence check.

## Remove legacy wrappers

There were **ten**, rather than nine, tracked files matching the requested old
build-5-to-7 patterns: three exporters, two delivery wrappers, three finish scripts
and two check wrappers. All ten are deleted. The tracked scripts directly in
`build/` are now only `export.sh`, `measure_memory.sh` and `verify_field_packs.sh`.
Git retains the old scripts' history. Current docs and the old delivery-plan note
now point at the unified entry point rather than name deleted scripts.

Outside S3's listed file ownership, these changes to CI, the packed-settings probe
and build/field documentation implement the orchestrator's explicit review calls.
No DECISIONS, content/rates, protected art/capture folder, tag, latest pointer or
remote branch was changed.
