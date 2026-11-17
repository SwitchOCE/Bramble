# Duplicates — brief 4

## Taste calls

- **Effect:** needed a match cue and a stronger triple cue, with no pips. Weighed a whole-card shader wash against the approved soft cream / gold rim light; chose light behind the frame so art, combat numbers and prices keep their contrast. Look and motion constants live together in `src/glass/glass_duplicate_glow.gd`; the existing frame-alpha shadow shader supplies the contour.
- **Motion:** compared A's slow, shallow breath with B's quicker, deeper pulse, side by side at full card size. Chose A: the three participants stay clearly lit together and the shop stays calm; a single match stays steady. Shared screen time preserves synchronization through redraws, hover and carrying. The candidate scene and JSON keep both options reproducible.
- **Golden ownership:** weighed ignoring a golden entirely against still acknowledging that its unit is owned. Chose a match cue for the same identity, while excluding goldens from both the normal-copy count and the combining participants (7.3.1). This never promises another golden upgrade.

## Scope

Shop offers and the board/hand copies they would combine with. No duplicate pips, reward or Discover changes. Preview depends on ownership rather than current affordability, hand capacity or available actions; a frozen or unaffordable offer still advertises the match. Created normal copies count (7.3.3).

The known Triple Reward timing gap in the core is outside this presentation change. The preview follows 7.3.1 and does not change any recruit rules. The two non-combining token definitions in the build are not shop offers; no token or content rules changed here.

## Verification

| Done when / check | Evidence |
|---|---|
| Shop match from board or hand | Pure preview tests cover either zone, multiple offers, no owned copies, unrelated IDs, empty slots and spells. |
| All triple participants glow | Tests cover both on board, split zones and both in hand; each matching offer previews independently. Created copies count; zero gold / unavailable buys do not hide the cue. |
| Goldens excluded from a normal triple | Tests cover golden-only ownership, golden + one normal, golden + two normals, and a hypothetical golden offer. |
| Updates follow the real state | Real `GameSession` buys move match → triple → golden; a refreshed offer clears the glow on kept board/hand nodes. Hover, carry and target lighting preserve the cue; shared phase is asserted. |
| No duplicate pips | No duplicate counter or pip drawing was added; reviewed candidate and shop frames show rim light only. Existing keyword pills remain the separate brief 2 work. |
| Two candidates, filmed side by side | `candidates-60fps.mp4`: 378 frames at 60 fps, full card size, with both motion choices together; `candidates.png` and `motion-strip.png` show the drawing and pulse phases. A chosen after frame review. |
| Actual shop filmed | `shop-60fps.mp4`: 210 frames at 60 fps. Its report confirms shop `[0,0,1,2,0]`, board `[0,0,0,0,0,0,2]`, hand `[0,0,2,0,0]` (none / match / triple). |
| Approved reference, duplicates on | `compare-1920/`: mean 5.42/255, 4.32% of pixels >32. `compare-1366/`: mean 8.41/255, 7.00% >32. Each includes reference, game, stacked, difference and all 144 regions. |
| Quality gate | `./scripts/check.sh`: all 11 steps passed; 370 resources compiled; 730 tests / 11,907 assertions; 15 games / 683 fights, zero violations; all six planted faults caught. |

Reviewed both the candidate pulse strip and full-size / laptop game shots. The largest comparison differences sit around board card footers: inherited keyword pills and ability controls, the shop branch's combat number shapes, and differences in rim-light rendering. The Cards entry remains reference-only on this branch. These scores are comparison evidence, not a claim of pixel equality. The game uses independent frame-alpha light layers; the browser chains drop-shadows, so its halo spreads differently.

The approved shop page SHA-256 remains `611fabe7f12523bbef2612933388fc71a1156cad0b397a4843d98dacfc214ef7`. Both look runs reported no game errors; their only warning was the virtual display's known V-Sync warning.

Media root: `/home/alex/code/Bramble/.claude/worktrees/night-media/dupes/`, outside Git. The approved mock-up is untouched; `tests/screens/shop_reference.html` now switches duplicates **on**.

## Needs the owner's eyes

The strength, colour and pace of the rim light, especially on the owner's display and at laptop scale. Films show deterministic software-rendered motion, not GPU performance, input latency or sound.

All runtime work used `LP_NUM_THREADS=2` and temporary XDG/feel folders; later films, compares and the final gate were also restricted to two CPU cores. Godot jobs from this worker ran sequentially. Automatic approval review denied stopping the initial accidentally broad test run because it considered the PID a focused test / mismatched target. No termination retry was made; that run finished, and its earlier parse failures were corrected before the focused pass and final gate. Nothing remains blocked by that denial. Media-folder writes and display sessions were approved.

Work is committed on `night/dupes`; no push or PR. No open implementation questions; the remaining review is the owner’s judgment of the effect and motion.
