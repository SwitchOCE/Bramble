# Batch 2 on wave 2b

Main input: `80dcc35a`. The merge preserves the reviewed slim evidence; no screenshots are added here. `DECISIONS.md` remains exactly main's version.

| Conflict | Resolution |
| --- | --- |
| `recruit_layout.gd` | Retained the full-hand fan, reserved away-token row and 122px empty-hand phone target; kept the Larder tooltip and room for its full-hand header. |
| `recruit_screen.gd` | Kept extracted builders, wordless HUD, recruit motion, scout focus and shared-clock Ooze adapter; retained main's per-screen Ooze instance and Larder state. |
| `card_view.gd` | Kept wordless art, beads, name policy and distinct scout selection; added wave 2b's Hedgerow mount and refresh hooks. Legacy rule-tag text stays deleted. |
| `test_pass2_ui.gd` | Preserved cached/legacy Hedgerow fixtures and Pass/reader checks with hidden resting pointers. |
| `test_polish.gd` | Preserved cached current roster and B/C normal/golden coverage, with complete rules in the reader and scout focus hiding/restoring shop/lobby. |
| `test_round4_finish.gd` | Kept wordless cues plus Hex/Mire visibility and collision coverage in recruit, scout and guide. |

The remaining main changes, including neutral previews, S3 library loading and the play/render tools, merged without conflicting edits. The screen stays below 1,000 lines (922).

## Hedgerow re-face

Removed the standing Committee-runt circle, Hunker shield and selected wake-reset outline. Wake-progress pips remain because they show changing hidden state. The existing reader retains exact share totals, wake progress/reset and Hunker; it now identifies the Committee's current smallest unit. Existing End of Turn routes/bead rolls and Hunker's crouch/reduced-motion flash supply the event motion. No game rules changed.

## Integration checks

The all-UI run exposed older assertions for inline worked examples, captions, toasts and synchronous End of Turn. Tests now follow the real Details/actions/type-line readers and finish actual recruit motion; their game, payout, triple/reward and placement assertions remain. Restored stored-Hex reader values and triple/combine sounds, and stopped empty drag tweens. Larder totals remain available by tapping the hand tray (or hovering it on PC); hiding their extra resting label restores the existing 40-node gate without excluding nodes.

Final validation passed on the complete merged/refaced tree:

- All `tests/ui/`: **70 scripts, 522/522 tests, 24,313 assertions, 177.311s**; strict hook clean and no engine errors.
- `./scripts/check.sh --no-tests`: docs-size, tools, versions, shell, Python (159 tests), content, format, lint, import, compile (685 files, zero failures) and parity passed.
- `ruff check tools`, `ruff format --check tools`, `gdlint src tools`, `(cd tests && gdlint .)` and `gdformat --check src tools tests` passed. The existing tile-word publisher also passes scoped Ruff.
- The existing `declutter_b2_report.py --tile-words-run` publisher audited all 16 scenario/size rows and verified per-zone/category sums. Current production rows have **0 tile words**; all 120 shipped units also have zero words across four zones and normal/golden variants.

| State | 1688×780 labels | 1920×1080 labels | Tile words, both sizes |
| --- | ---: | ---: | ---: |
| Overview | 40 | 40 | 0 |
| Lobby | 39 | 39 | 0 |
| Scout | 30 | 30 | 0 |
| Natural Birds | 30 | 30 | 0 |
| Reader open (separate) | 51 | 51 | 0 |
| Ten-unit hand (edge case) | 61 | 61 | 0 |

Every hand stat remains visible. No label exclusions were added. Historical non-shipped fixtures still count their six/eight missing-portrait name words; their raw totals remain 30/28, with no unexpected words.

Compact counts, state hashes and re-face source hashes are in [merge-wave2b-counts.json](merge-wave2b-counts.json). Raw logs, JUnit and the full publisher output remain in `build/declutter-b2-merge/`; this note adds no screenshots or archived packet copies.
