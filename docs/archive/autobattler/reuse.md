# Autobattler: code, scripts and templates worth reusing

Autobattler (Godot 4.7, statically typed GDScript) had 389 commits and 583 `.gd` files in `src/`: presentation 41k lines, app 10.6k, content 4.2k, core 3.2k. It also had 451 test files.

Its infrastructure was stable; its failures were in design and supervision. Reuse means engineering infrastructure and patterns, not game design. Bramble's CLAUDE.md rules out the in-fight player-HP model and Autobattler's other design assumptions.

Verdicts: **copy** as-is, **adapt**, **learn** from only, or **avoid**. **[V]** = verified, **[I]** = inference. Paths are in the Autobattler repo.

## Summary

| Verdict | Items |
|---|---|
| Copy | `tools/checks/layers.py` (adapt only its tables); `compile_all.gd`; `gut_strict_hook.gd`; GUT 9.7.1; the warnings-as-errors block in `project.godot`; `gdlintrc`, `gdformatrc`, `ruff.toml`; `pcg32.gd`, `splitmix64.gd`; `FileKeyValueStore` |
| Adapt | `check.sh` (steps up to tests); the screenshot tool; export presets; `export_smoke.sh`, `set_version.sh`, `stamp_build.sh`; `ci.yml`; `cloud-setup.sh` and `session-start.sh`; PR and issue templates; the sim, ui and app agents (with tick and spire wording removed); the decision-record template; the content JSON-schema validator; the touch-target and motion audits; `tools/art/finish_art.py` |
| Learn from | golden replays, rules lock and command journal (relevant to Bramble's async snapshots, rulebook 2.1.4); the effect registry (the same shape as architecture-notes §6); UI scaling; the `TouchScroll` drag-versus-scroll fix; perf budgets on the median of 3 runs |
| Avoid | every core and effect primitive (they encode spire HP, cooldowns and fatigue); `tools/bot`, `tools/balance`, `tools/cli`, `tools/bench`, `tools/mock_server`; the game-designer and balance-analyst agents; the 17 October delegation of content, balance and rules calls to agents |

## By area

### Layers and their check: copy, adapt the tables
- **Layers [V]:** `src/{core,content,app,infra,platform,presentation,main}`, with the table in `CLAUDE.md`.
  - infra and platform reach app only through `src/app/ports/`.
  - Autoloads may live only in main or presentation.
  - main is the composition root (`main.gd`, 148 lines).
- **`tools/checks/layers.py` [V]:** about 410 lines of stdlib Python, enforced in `check.sh`, with fixture tests in `tools/checks/tests/`. It changed only twice in its life.
  - **How it works:** it tokenizes GDScript (dropping comments, node paths and annotations), then resolves `res://` paths, `uid://` ids (through `.uid` files) and relative paths.
  - **Rules:** `layer`, `ports-only`, `autoload-host`, `autoload-use`, `banned-api`, `core-extends`, `core-scene`, `unknown-layer`.
  - **Banned in core and app:** `randi`, `randf`, `RandomNumberGenerator`, `Time`, `OS`, `seed()`, `.shuffle()`, `.pick_random()`.
  - **Banned in core only:** floats, Node and Control types, and `Engine`. Core may extend only RefCounted, Resource or Object.
- **[I]** The 20 Hz tick rule and the float ban were Autobattler design decisions. Keep integers only if Bramble's rulebook needs nothing fractional.

### Quality gate (`scripts/check.sh`, 11 commits): adapt
- **Steps [V]:** tools, import, format, lint, python, layers, rules, compile, tests, bots, balance, perf. Options `--keep-going` and `--help`. Logs go to `build/check/`.
- **`GODOT_PROBLEM_RE` [V]** fails a step on any ERROR, WARNING or parse error in its log.
- **Godot traps it handles [V]:**
  - `--import` does not compile scripts, so a separate compile step loads every script.
  - GUT exits 0 on tests that assert nothing, on pending tests and on skipped scripts. The strict hook fails all of those, and the gate requires the hook's `gut_strict: ok` line.
  - A missing hook makes GUT hang, so the gate checks for it first.
  - Parse errors and per-case `[Risky]` lines are grepped.
- **Sharding [V]:** `gut_shards.py` splits GUT over parallel processes once the suite gets long (see [toolchain.md](toolchain.md) §2.9).
- **[I]** Copy the steps up to tests, drop bots, balance and perf, and add sharding once the suite takes more than about 5 minutes.

### Lint and typing: copy
- **gdtoolkit 4.5.0 [V]:**
  - limits: line length 100, tabs, files up to 1000 lines, 20 public methods, 10 arguments, 6 returns;
  - names: snake_case for functions, variables and signals; PascalCase for classes; UPPER_SNAKE for constants;
  - a fixed class member order.
- **Ruff 0.16.8 [V]:** py311, line length 120, rules E W F I B UP SIM C4 PTH N RUF.
- **[V]** Only 6 lint suppressions in the whole repo.
- **Warnings that are errors [V]:**
  - `untyped_declaration`, all `unsafe_*` warnings, `inference_on_variant`, narrowing and enum casts;
  - unused, shadowed and unreachable code.
  - `return_value_discarded` and `integer_division` are ignored.
- **Gotchas [V]:**
  - gdlint skips any directory named `fixtures`, so test fixtures had to move.
  - The 20-public-method cap also applies to tests, which forced 16 test base classes.
  - Effect specs stayed untyped Dictionaries: 51 `spec.get(` calls in core and 358 `: Variant` in `src`.
- **[I]** Give tests their own gdlint config, and use typed effect classes rather than Dictionaries.

### Tests and determinism: copy the RNG, learn from the goldens
- **Test setup [V]:** GUT runs from the command line only. 14 static test kits (`sim_test_kit.gd`, `run_test_kit.gd`, …). Tests mirror `src/`.
- **RNG [V]:**
  - PCG32 is written with 32-bit limbs so nothing overflows, and is pinned against outputs from a Python mirror (decision 5);
  - named PRNG streams for shop, chest and event (decision 45).
- **Hashes and goldens [V]:**
  - `log_hash()` is SHA-256 of key-sorted JSON;
  - golden cases are stored as JSON plus a text log, so a failure prints the first divergent event;
  - goldens are regenerated only by a separate tool, never by a test flag, and a coverage test fails if goldens stop using a primitive.
- **Problem [V]:** decision 27 built goldens from the live content, so every balance PR moved them. That meant 62 golden commits, 58 rules-lock commits, `SIM_VERSION` at 20, and a `regen_content.sh` script.
- **[I]** Lock goldens to fixture content only.

### Rules lock and command journal: learn from
- **Rules lock [V]:**
  - the ruleset is `SIM_VERSION.content_hash`, a canonical JSON hash that rejects floats;
  - `rules_lock.py` refuses goldens that change while the ruleset doesn't.
- **Journal [V]:**
  - every accepted command is journaled before it is applied, and `RunReplay` rebuilds a run from the journal;
  - the gate's bot smoke test runs `--verify-resume --verify-replay`, and it caught bug #52.
- **[I]** This matters for Bramble's async fights against snapshots. Design commands to be journaled from the start.

### Screenshots and previews: adapt
- **The tool [V]:**
  - sets the window size in code, because `window_*_override` beats `--resolution`;
  - a Logger counts errors, and any error means exit 1; it also exits 1 under `--headless` or on a size mismatch, and 2 on bad arguments; it supports `--expect-error`;
  - runs under `xvfb-run` with opengl3 and the Dummy audio driver;
  - uses preloads instead of `class_name`;
  - changed 3 times in its life.
- **The scene list [V]:** `screenshots.sh` reads a hand-kept list of 174 entries. It had 45 commits and was a merge-conflict hotspot.
- **Previews [V]:** about 100 `src/main/previews/*_preview.tscn` scenes, with `_xa` (pseudo-locale) and `_a11y` variants.
- **[I]** Discover previews by naming convention instead of a list, and store the PNGs outside git.

### UI scaling and audits: learn from, adapt the audits
- **Scaling [V]:**
  - base size 720×720, `canvas_items` stretch, `expand` aspect, so both 1080×2400 and 1920×1080 get the same 1.5× scale;
  - desktop opens at 1280×720, and phones are fixed to portrait;
  - a landscape profile applies at aspect ratio 1.2 or more;
  - a `SafeAreaContainer` sits at every screen root.
- **Audits [V]:**
  - touch targets: 80 logical px (120 physical) at every UI scale, measured by laying previews out in a 900×2000 `SubViewport` at 80 % scale;
  - motion: a static scan with an allowlist that fails on stale entries.
- **Theme [V]:** `UiTokens` produce a committed theme, guarded by a staleness test. The font is embedded, because referencing an imported `.ttf` broke the first CI import.
- **Scrolling [V]:** `TouchScroll` (decision 130) resolves drag versus scroll inside scroll containers.
- **[V]** `ui-audit.md` judged the UI as reading like "a well-organised prototype, not a product". The UI was redone board-first on the last day; presentation had 92 commits.
- **[I]** The audits proved fit, not quality. Get the owner's review of interaction design up front.
- **Owner decision [I]:** Autobattler chose portrait-only phones. A Battlegrounds-style board may want landscape.

### Exports, versioning, CI and cloud: adapt
- **Export presets [V]:** six presets.
  - Android builds arm64 and armv7, SDK 24 to 36, with `etc2_astc` on.
  - Presets use include and exclude filters, and signing goes only through `GODOT_*` env vars.
- **`export_smoke.sh` [V]:**
  - exports Linux, Windows and the Android APK;
  - fails on any warning in the log;
  - checks file sizes and pack contents;
  - boots the Linux build headless.
- **Versioning [V]:** `set_version.sh` is the single source of the version, backed by `stamp_build.sh` and a consistency test.
- **CI and cloud setup:** see [toolchain.md](toolchain.md).
- **[I]** Rename `curio_spire` and `com.switchoce.curiospire`, and choose the real app ID before the first store upload.

### Process artefacts: adapt
- **`WORKER.md` and `ORCHESTRATOR.md` [V]:** see [orchestration.md](orchestration.md).
- **Templates [V]:** PR and issue templates. The PR template has Summary, Acceptance criteria, Verification (the decisive output lines), Screenshots and Decisions.
- **Agents [V]:** seven in `.claude/agents/`. The sim and ui agents are tied to the tick and spire model; game-designer and balance-analyst encode the old ethos.
- **Decision records [V]:** 207 files numbered by issue, so numbers collide (`2-*` has four files).
- **[I]** Use sequential decision numbers. Replace the old delegation with the owner's current supervision gates.

### Content, effects, save, platform, i18n
- **Content [V]:**
  - JSON with `$schema`, as one file or a directory of `NN_*.json` files per kind;
  - a GDScript validator for a strict subset of JSON Schema that rejects unsupported keywords and collects every error per entry;
  - integral floats converted to ints;
  - key convention `<KIND>_<ID>_<SUFFIX>`.
  Adapt the validator.
- **Effects [V]:** `EffectRegistry` covers triggers, conditions, effects, selectors and values. Learn from its shape; don't copy the primitives.
- **Save [V]:**
  - `FileKeyValueStore` writes a temp file, flushes, reads it back and renames, and recovers on Windows;
  - it sits behind the `KeyValueStore` port;
  - `SaveMigrations` steps one version at a time.
  Copy it.
- **Platform [V]:** `PlatformServices` never throws or blocks, with null and Steam implementations. Learn from it.
- **i18n [V]:**
  - gettext PO files;
  - a generated `en_XA` pseudo-locale that is never exported;
  - `[kw:]` and `{placeholder}` markup;
  - tests for missing and unused keys.
  Adapt.
- **Art [V]:** `tools/art/finish_art.py` crops to alpha and quantises to 256 colours. Adapt it alongside Bramble's Codex image runner.

## Conventions that worked [V]

- **Code style:**
  - static typing everywhere, plus a compile step;
  - one class per file, `snake_case.gd` file names, PascalCase class names, `##` doc comments;
  - no magic numbers; integers, with percentages in basis points.
- **Architecture:**
  - randomness only from named seeded streams;
  - presentation plays back logs and never recomputes outcomes;
  - all player-facing text goes through `tr()`.
- **Workflow:** verify on a merged, re-imported head.
