# Duplicates — brief 4

## Review correction

Review found that the original films were static: the shadow shader discarded the glow node's modulation. The earlier claim to have judged A's pulse from those frames was wrong. The property test passed because it checked `modulate.a`, not the image. Those original films remain outside Git as historical evidence; replacement evidence lives in `media/dupes/`.

Duplicate layers now supply an explicit shader opacity. Its default is one, preserving existing card shadows; multiplying the fragment's incoming `COLOR` instead would also multiply sampled frame alpha and clip the blur. A rendered regression reads halo pixels at five phases and runs in `check.sh`'s rendering step. Its old-shader run uses the exact source from `e26bcc99`, without replacing any working-tree file.

## Taste calls

- **Effect:** weighed a whole-card wash against the approved cream / gold rim light; retained light behind the frame so art, combat numbers and prices keep their contrast. Look and motion constants remain together in `src/glass/glass_duplicate_glow.gd`; the frame-alpha shadow shader supplies the contour.
- **Motion (chosen again after corrected film):** weighed A’s shallow, slow breath against B’s deeper, quicker fade in the replacement side-by-side film and phase strip. Chose A: its gold halo stays clear through the trough and moves calmly, while B draws more attention as a repeating status flash. All three participants visibly change together; a single match stays steady. Timing and opacity floors remain in `GlassDuplicateGlow`.
- **Golden ownership:** retained a match cue for the same identity, while excluding goldens from the normal-copy count and combining participants (7.3.1). This acknowledges ownership without promising another upgrade.

## Scope and logic

Shop offers and the board/hand copies they would combine with; no duplicate pips, rewards or Discover changes. Preview depends on ownership rather than current affordability, hand capacity or available actions. Created normal copies count (7.3.3).

The preview now reads `combines` from the card definition through `ViewAdapter`, for offers and owned copies. A noncombining offer can match but cannot advertise a triple; noncombining owned copies cannot contribute to one. Tests use the shipped Private token's real definition and also check mixed flag values. The known Triple Reward timing gap is outside this presentation change.

## Verification

The original gate's successful property assertions did not establish drawn motion. The replacement rendered test fails on the original shader (exit 1) and passes on the fixed shader (exit 0):

| Raw rendered halo mean (0–255, Rec.709) | Peak | Quarter | Trough | Three-quarter | Full period |
|---|---:|---:|---:|---:|---:|
| Original shader, A | 56.386 | 56.386 | 56.386 | 56.386 | 56.386 |
| Fixed shader, A | 56.386 | 52.699 | 48.923 | 52.699 | 56.386 |
| Fixed shader, B | 56.541 | 47.752 | 38.434 | 47.752 | 56.541 |

`pixels-old/pixels.json` and `pixels-fixed/pixels.json` contain the exact values; `pixels-old.log` and `pixels-fixed.log` hold the exit evidence. The normal-card crops from both runs are pixel-identical (zero changed pixels), with the before/after pair in `normal-before-after.png`. The film checker also rejects the original candidate and shop films; its measurements are in `old-films.json`. The replacement `candidates-60fps.mp4` contains 378 frames at 60 fps. `motion-strip.png` shows consecutive pulse phases, and `candidates-pixels.json` proves that each of the shop, board and hand halos changes in both candidates.

| Decoded candidate shop halo (0–255, BT.601) | Start | Quarter | Half | Three-quarter | Full period |
|---|---:|---:|---:|---:|---:|
| A | 56.10 | 51.73 | 48.64 | 52.88 | 55.93 |
| B | 55.40 | 43.38 | 38.05 | 51.23 | 55.54 |

Samples begin at frame 6, after setup, so they are slightly past the exact peak; the full lossless phase test above samples exact normalized phases. The film JSON includes sample frame indices and every decoded frame value. Normal-before and normal-after also pass an exact image comparison in that check.

- `tests/screens/dupes_pixels.tscn` reads lossless rendered halo brightness at peak, quarter, trough, three-quarter and full period, and checks that the normal card stays pixel-identical through these phases. The same test must fail with the exact original shader.
- The film measurements (halo strips outside each card, all frames, five phase samples) were made with a one-off script; its results are in the media folder. The gate's rendered test `tests/screens/dupes_pixels` catches the original bug.
- Logic tests cover board/hand ownership, each offer independently completing a triple, Created and golden copies, `combines: false`, real buys and clearing a preview after refresh. Hover, carry and target lighting preserve the cue. No duplicate counter or pip drawing was added.

The chosen A is also filmed in the actual shop as `review/shop-60fps.mp4`. The combined film check writes every candidate and shop frame value, phase samples and normal-card equality to `review/films-pixels.json`.

Final-commit comparisons and `./scripts/check.sh` are run after committing. Their commit, results and logs will be recorded outside Git in `review/final-verification.json`; each compare's `result.json` also records its capture commit. The current adapter switches duplicates **on**. The shop note now distinguishes its historical duplicate-off captures from the current adapter.

Media root: `media/dupes/`. No approved mock-up files changed. The approved shop page SHA-256 remains `611fabe7f12523bbef2612933388fc71a1156cad0b397a4843d98dacfc214ef7`.

## Owner review and limitations

Strength, colour and pacing still need the owner's eyes on their display, especially at laptop scale. Films show every deterministic software-rendered frame; they do not measure GPU performance, input latency or sound. The browser chains drop-shadows while the game draws independent light layers, so halo spread differs. Inherited keyword pills, ability controls, combat number shapes and the reference-only Cards entry remain comparison differences.

Work is PR 127 into `dev`. Runtime jobs use the shared `/tmp/bramble-n18-godot.lock`, `LP_NUM_THREADS=2`, temporary XDG/feel folders and two CPU cores for rendering.
