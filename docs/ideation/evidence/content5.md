# Content5 — 8 November 2026

Implemented the four revised round-5 recommendations on `ideation/content5`, based on `c11e55d`: Horseshoe, Barn Owl, Redwing and Market Stall. Revised normal/golden texts, tiers, costs and bodies are preserved exactly. Existing printed card designs remain unchanged.

Added engine support, live bot valuation/aiming/placement, all Birds bench strategy entries, glossary reminders and four unique built-in-image-tool portraits. JPEGs live in `assets/portraits/`; prompts are `tools/art/prompts/content5.txt`. PNG masters are not committed. Section 3's existing-card alternatives are preserved in `docs/ideation/variation-notes.md`. Silent interaction readings are listed in `docs/ideation/content/content5.md`.

Independent review found and verified fixes for Horseshoe appearing as a Ring, borrowed Redwing text missing from Egg forecasts, and Hungry Gap with seven Poached offers. Supported Egg scout/ghost snapshots expose no away Bird identity, text or countdown.

Validation, pinned to cores `0,5` after sourcing `/opt/bramble/env.sh`:

- Fresh headless import completed; subsequent gates used writable temporary Godot configuration/data directories.
- Fetched and merged `origin/ideation/main` again before the final gate: already up to date at `c11e55d`.
- `./scripts/check.sh`: all ten steps passed; 396 resources compiled; GUT **1,361/1,361 tests**, **18,377 assertions**, strict hook clean. Includes 65 new card/bot/UI tests. Initial guide/catalogue-count failures were corrected before the full rerun.
- Sequential `tools/checks/soak.sh 100 471366083`: **passed**, seeds 471366083–471366182; **1,604 rounds, 4,926 fights, zero violations**, 871.1 seconds.

Soak results are rules-invariant bot evidence, not a balance or human-play claim. Gate logs: `build/check/`.
