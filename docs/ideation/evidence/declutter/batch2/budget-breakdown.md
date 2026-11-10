# Visible-label budget breakdown

Capture stage: after main merge and recruit label cuts.

Current live replay: `cc246987 + classifier zero-name and typed Bird test follow-up`. All categories count toward the raw resting budget of 40; none are excluded.

| Scenario | Pixels | Unit stats | Hero Health | Fallback names | Costs and controls | Other | All labels | Resting gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| slice recruit | 1688x780 | 14 | 5 | 3 | 6 | 2 | 30 | PASS |
| slice scout | 1688x780 | 16 | 0 | 4 | 6 | 2 | 28 | PASS |
| slice recruit | 1920x1080 | 14 | 5 | 3 | 6 | 2 | 30 | PASS |
| slice scout | 1920x1080 | 16 | 0 | 4 | 6 | 2 | 28 | PASS |
| seed72 recruit | 1688x780 | 8 | 8 | 0 | 3 | 3 | 22 | PASS |
| seed72 recruit | 1920x1080 | 8 | 8 | 0 | 3 | 3 | 22 | PASS |
| overview | 1688x780 | 24 | 8 | 0 | 3 | 5 | 40 | PASS |
| overview | 1920x1080 | 24 | 8 | 0 | 3 | 5 | 40 | PASS |
| natural-birds | 1688x780 | 14 | 8 | 0 | 4 | 4 | 30 | PASS |
| natural-birds | 1920x1080 | 14 | 8 | 0 | 4 | 4 | 30 | PASS |
| lobby | 1688x780 | 24 | 8 | 0 | 3 | 4 | 39 | PASS |
| lobby | 1920x1080 | 24 | 8 | 0 | 3 | 4 | 39 | PASS |
| scout | 1688x780 | 24 | 0 | 0 | 3 | 3 | 30 | PASS |
| scout | 1920x1080 | 24 | 0 | 0 | 3 | 3 | 30 | PASS |
| reader-reel_mistress-golden | 1688x780 | 32 | 8 | 0 | 4 | 7 | 51 | reader open; reported only |
| reader-reel_mistress-golden | 1920x1080 | 32 | 8 | 0 | 4 | 7 | 51 | reader open; reported only |

Classification uses the actual owning widget and its known field, never whether the displayed text looks numeric. JSON retains every label's text, path, category, owner, field and fallback reason. Each row's five categories sum exactly to All labels.

Every shipped unit now has its own portrait, including the approved Grizel reroll. No shipped tile name exceptions remain. The former Brock/Old Brock/Sable/Russet and Brother Wolf/Grizel exceptions are no longer used. Synthetic missing-art test cards still count as fallback names; no name is excluded from the cap.

The unchanged legacy slice fixture also contains legacy unit IDs without individual portraits: its recruit/scout fallback names remain visible and count toward the same cap.

Gold and queued-income amounts are Costs and controls. Opponent tiers, Ring-stack/Belly/Hex/Midsummer counters and away text are Other. Reader stat beads are Unit stats; reader name/type/rules/reminders are Other. Reader-open rows are not resting-budget passes.

Historical manifests remain unchanged. Earlier captures lack ownership metadata, so this report does not invent a category split for them.

## Costs, controls and other labels

The first size of each scenario is listed below; the table and JSON retain both sizes. Repeated strings remain separate counted nodes.

### slice recruit

- Costs and controls (6): `1`; `5`; `16`; `7`; `6`; `End turn`.
- Other (2): `3`; `Turn 6`.

### slice scout

- Costs and controls (6): `1`; `5`; `16`; `7`; `6`; `End turn`.
- Other (2): `3`; `Turn 6`.

### seed72 recruit

- Costs and controls (3): `3`; `5`; `End turn`.
- Other (3): `×4.0`; `1`; `Turn 1`.

### overview

- Costs and controls (3): `10`; `10`; `End turn`.
- Other (5): `×1.25`; `1`; `2`; `4`; `Turn 2`.

### natural-birds

- Costs and controls (4): `2`; `0`; `5`; `End turn`.
- Other (4): `×1.0`; `1`; `2`; `Turn 4`.

### lobby

- Costs and controls (3): `7`; `10`; `End turn`.
- Other (4): `×1.25`; `1`; `4`; `Turn 8`.

### scout

- Costs and controls (3): `7`; `10`; `End turn`.
- Other (3): `1`; `4`; `Turn 8`.

### reader-reel_mistress-golden

- Costs and controls (4): `2`; `24`; `8`; `End turn`.
- Other (7): `×1.25`; `4`; `Turn 4`; `Reel-Mistress`; `GOLDEN · CREATED · FAIRIES`; `After a unit on a Ring attacks: its Ring moves to your next unit. Four times per Ring. / Details`; `5`.
