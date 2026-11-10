# Batch 2 focus follow-up

Captured on production **4c5c2900**. Ten native stills, six recruit strips
(48 frames), current per-node budgets and both contact sheets are complete.
No fresh cold-reader pass is claimed.

The pinned input is an exact byte copy of `../states.json`. All ten before images
and their existing masks/manifests are referenced under `../before/`; none are
rerendered, copied over or reclassified. `input-provenance.json` guards the source
state and 23 existing before artifacts with SHA-256 hashes. The overview, golden
Reel-Mistress reader and natural Birds use the recorded wave1 inputs. Lobby/scout
retain the parent's explicitly labelled recorded-board reconstruction; the missing
original field library still prevents claiming a historical full-screen replay.

## Cuts and reasons

These are the orchestrator's follow-up budget cuts, alongside the approved scout
focus. They apply the 09e rule that the game environment assumes the player knows
the rules; this report does not attribute a new decision to the owner.

| Change | Reason |
| --- | --- |
| Shipped tile names leave the face | The latest portrait merge resolves the final Brother Wolf/Grizel pair. Every shipped unit now has identifying art; synthetic missing-art test names still count. |
| Ring-stack digits leave the resting board | The floor marks and current beads retain the immediate read; exact stack counts remain in the reader. This removes repeated standing counters. |
| Standard-1 card cost knots leave the face | A default price repeats fixed knowledge. Nonstandard prices and the reader retain the price decision. |
| Opponent tier digits leave lobby portraits | The hero reader retains the tier, while each visible hero Health remains counted on its portrait. |
| Away Birds become portrait tokens with moon countdowns | The main screen retains which Bird is away and when it returns; full current/homecoming stats move to the token reader. No Bird is hidden to meet a count. |
| Scouting uses a focused board view | Comparing both complete boards takes precedence over the shop/hand during this action. The normal recruit view returns on close. |
| Phone reader and counter bounds are repaired | A decision must remain readable without cropped text, covered stat beads or hidden gold/end-turn controls. Targeted geometry checks accompany the images. |

The earlier rulebook/wording-guide/keyword reminder edits and their reasons remain
in the parent batch report. No new rulebook mechanic or combat timing is introduced
by this follow-up.

## Evidence and checks

`pairs.json` links each immutable before to its new native 1688×780 or
1920×1080 after, with raw counts, pocket dimensions and the same semantic
free-surface mask used by the parent packet. This proxy measures unoccupied
surface, not perceived calm; carving and background grain are not separately
subtracted. It is not a fresh visual-tier score.

`budget-breakdown.json.gz` and `.md` list every current node by its actual owning
widget/field, split into unit stats, hero Health, fallback names, costs/controls and
other. Those categories sum to the unchanged raw count; none are exemptions. The
reader-open rows are shown separately from the resting 40-node gate. Historical
nodes are not retroactively assigned categories by guessing from printed digits.

The six recruit strips use the existing 120-Hz explicit animation clock and eight
native frames per cue at ×1, ×4 and reduce motion. They cover a real Mr Crumb Pass
and a declared **test-only** End-of-Turn variant of Standing Committee's Touching
effect. A capture-only override assigns that variant the Committee portrait; the
core events and numbers are unchanged. This fixture is not a shipped timing
change. The scout strips open Wick's reader while native Old Brock lends its own
across quarry: pocket 5 must pulse, pocket 2 must stay dark, then the pulse clears.
The assembler verifies identical End-of-Turn events across modes, exact final
beads against the core, cue timing limits and the resolved lent target.

[Shipped contact sheet](shipped-unit-board-faces.jpg) contains all **120** definitions
in `GameConfig.full_game().card_set()` (`slice`), including created units: every
face has its own portrait and **zero** fallback names. It repacks exact rendered
cells offline without changing their pixels. [Full library audit](all-unit-board-faces.jpg)
retains all 158 definitions, including 38 legacy units outside the shipped set;
those 38 missing-art legacy names remain visible and counted. Both manifests
retain source entries and art-rectangle shares.
A fresh cold reader, external-game comparison and uniform art-share approval are
not claimed by these captures.

## Measured result

| State | Before 1688 / 1920 | After both sizes |
| --- | --- | --- |
| Overview | 134 / 135 | 40 |
| Lobby | 127 / 128 | 39 |
| Scout | 136 / 136 | 30 |
| Natural Birds | 103 / 103 | 30 |
| Open golden Reel-Mistress reader | 145 / 135 | 51 |

The 51-node open reader is reported separately; it is not a resting view. Every
resting row passes without stat, hero-Health or control exemptions. Typical pocket
canvas grows from 209×189 to 209×229; the 1688 reader's narrow canvas grows
180×163 to 180×203. `pairs.json` records each exact dimension and mask share.
Overview free-surface proxy rises 44.7%→52.4% at 1688 and 35.7%→44.8% at 1920;
scout rises 52.1%→75.6% and 44.8%→60.6%. These are the declared proxy, not a
perceptual calm score.

Native review checked the 1688 overview and focused scout: both full boards fit,
stat beads remain readable, Away tokens retain portraits/countdowns, and gold and
End turn remain in bounds. The detailed phone geometry tests are reported by the
orchestrator. EOT shown beads equal the real core, including a target receiving
both Touching and Pass; scout pulse resolves pocket 5 and clears.

`process-history.json` records each accepted capture's wrapper CSV entry. All
accepted runs were sequential, exited 0, and completed before runtime release.
The initial still acquisition waited 35.1 seconds for a shared host slot. No
failed or timed-out capture contributed to this packet. The 24 parent artifacts
remain hash-identical.
