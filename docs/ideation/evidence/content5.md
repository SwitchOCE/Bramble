# Content5 — 8 November 2026

Four revised round-5 cards: Horseshoe, Barn Owl, Redwing and Market Stall. Existing card definitions and all card text remain unchanged by this review follow-up. Source: `origin/ideation/c-review-content5:docs/ideation/evidence/review-content5.md` and the owner's explicit calls.

Applied:

- Ghost slot snapshots discard spent Horseshoes. The new session regression failed before fixing (three failed assertions), then checks the original cast and two subsequent ghost fights.
- The seven-unit ceiling bounds only Stall additions. Existing hero shops, frozen offers and Poach match `c11e55d`; tier-6 Pipkin without Stalls shows eight units. All heroes/tiers and Poach admission, refresh and expiry have regressions.
- Owl's whole-attack immunity is retained unchanged.
- Removed the separate Redwing scout-rule dictionaries. Plain Egg specs carry two already-revealed full-body stats, preserving dynamic aura loss, golden support, Goose and privacy.
- Re-rolled `assets/portraits/redwing.jpg` and `market_stall.jpg` with the built-in image tool in flat solid-fill style. Prompt set: `tools/art/prompts/content5-flat-review.txt`; PNG masters remain uncommitted.

Interaction readings: `docs/ideation/content/content5.md`. Existing-card alternatives: `docs/ideation/variation-notes.md`.

Validation after sourcing `/opt/bramble/env.sh`, with writable temporary Godot config/data:

- Targeted Stall/legacy regressions: 70/70 passed, 1,654 assertions.
- Targeted ghost/Redwing regressions: 64/64 passed; permanent-Egg-buff safety pass: 30/30 passed. Both ghost and permanent-buff regressions were demonstrated failing before their fixes.
- Merged `origin/ideation/main` at `67cd0b1` (clarity); no conflicts. One final `./scripts/check.sh`: all ten steps passed; 397 resources compiled, 1,378/1,378 tests, 18,863 assertions, strict hook clean. Detached, hard timeout 900 seconds.
- Subsequent `tools/checks/soak.sh 100 735477297`: passed, seeds 735477297–735477396; 1,591 rounds, 4,905 fights, zero violations, 380.6 seconds. Detached, hard timeout 1,200 seconds.

Logs: `build/check/` and `/tmp/content5-owner-*.log`. Soak is rules-invariant bot evidence, not a balance claim.
