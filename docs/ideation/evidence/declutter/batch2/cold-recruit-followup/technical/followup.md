# First-reader follow-up: technical notes

Source: `58e836078b79af4ff7085b667a5ea06d1a11443c`. The complete fresh packet uses one source revision.

The first reader at `origin/ideation/main:docs/ideation/evidence/declutter/batch2-cold/reader1/` scored 10/16 runs. This follow-up changes the three failed actions and the inexpensive defects identified by the scorer. Only `reader/` is for the next cold reader; this file contains the answer key.

| Item | Change and reason |
| --- | --- |
| B, swallow | The purchase shrinks and dissolves into a 16px landing at the stomach glyph over 0.36s. Its separate overlay retires before the Belly count appears and pulses once for 0.18s. The badge is an unboxed stomach silhouette. This shows containment rather than stacking or equipment. |
| D, lent target | The selected aimer has a blue frame. Only the resolved quarry gets the brief gold pulse and quarry reticle; straight-across slot 2 remains unmarked. The reticle disappears with the pulse. This distinguishes selection from the target relationship. |
| F, Fly South | The departing card dissolves into the matching away portrait over 0.40s, then its crescent/countdown pulses for 0.18s. The countdown is held until arrival and no departing card remains beside the token. This supplies a visible completed destination. |
| B/E/F reduce endpoints | Moving copies hide and retire before the settled state. Ghost pivots are zero so reduced-motion scaling cannot land a card beside its destination. The capture endpoint is also two fixed ticks beyond the production cue duration, with no surviving visible action overlay. |
| E, triple | All three incoming overlays retire before the golden result appears and pulses. The last arrival is at 0.35s. This avoids showing incoming and resulting cards as extra copies. |
| C, purchase path | The card contracts to a 32px picture, crosses the shop/board gutter, then descends through the hand column; the hand destination pulses. This keeps the journey clear of occupied portrait faces. |
| G, sale payment | The acorn arrives at the large gold icon, clear of the digits; the balance settles after sale removal and the large icon receives one payout pulse. This ties the payment to the removal. |
| H, tier-up price | The old upgrade price remains until the 0.36s payment has settled; the new price appears with the tier pulse. This keeps the next price from reading as the current payment. |

No text labels, arrows, rule reminders, or standing marks were added. Existing reader content and all hand stats remain.

## Targeted validation

The isolated explicit eight-file run passed **57/57 tests, 2,527 assertions, 27.648s**, with strict warnings enabled and no errors. The preceding accidental invocation loaded default directories and was stopped; its totals are not used. Runtime source is unchanged from `f85a45ca` to this capture revision; the latter only fixes a typed local in the capture script.

| Test file | Tests | JUnit time |
| --- | ---: | ---: |
| tests/ui/test_recruit_actions_motion.gd | 2 | 6.773309s |
| tests/ui/test_scout_reach.gd | 7 | 3.902327s |
| tests/ui/test_combat_face.gd | 12 | 0.036601s |
| tests/ui/test_away_tokens.gd | 6 | 0.228869s |
| tests/ui/test_counter_layout.gd | 1 | 0.055790s |
| tests/ui/test_recruit_declutter.gd | 12 | 7.072544s |
| tests/ui/test_tile_words.gd | 6 | 6.155886s |
| tests/ui/test_phone_layout.gd | 11 | 2.861442s |

JUnit and strict-run log supplied to the worker: [`targeted-tests.xml`](targeted-tests.xml) and [`targeted-tests.log`](targeted-tests.log). Capture process times are reported in `process-history.json`. Its first row is a failed strict parse on the preceding source revision and produced no accepted frames; the second and third rows are the successful fresh capture and face audit. The typed-local preflight passed on a separate task-specific slot log, copied into `validation.json`.

## Resting counts

| State | 1688×780 | 1920×1080 | Tile words at both sizes |
| --- | ---: | ---: | ---: |
| Overview | 40 | 40 | 0 |
| Lobby | 39 | 39 | 0 |
| Scout | 30 | 30 | 0 |
| Natural Birds | 30 | 30 | 0 |
| Reader open | 51 | 51 | 0 |
| Full ten-unit hand | 61 | 61 | 0 |

Every visible text node counts. The full hand remains a separately reported edge case and keeps every attack/Health bead. `tile-words.md` and JSON list all 44 state/stage/size rows and split raw counts into unit stats, hero Health, fallback names, costs/controls and other.

A fresh reader/scorer is still required; capture and developer inspection do not establish a passing reader result. Hedgerow re-facing remains pending wave 2b on main.


The fresh full capture held its worker slot for **178.4s**, and the face audit for **14.8s**; both exited 0 with no script errors. The packet contains 16 neutral sheets (128 native frames), 44 resting state/stage/size rows, 14 Rules pages and 120 shipped faces. All ten historical-before/fresh-after links resolve from `paired-stills.json`.

The hand-off static checks all passed on the finished source tree: `ruff check tools`, `ruff format --check tools`, `gdlint src tools`, `(cd tests && gdlint .)`, and `gdformat --check src tools tests` (656 files). The changed Python capture report also passed explicit Ruff check/format checks, and the shell runner passed `bash -n`.
