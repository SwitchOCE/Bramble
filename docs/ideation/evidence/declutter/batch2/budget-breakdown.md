# Visible-label budget breakdown

Current live replay: `3fb19a45 working tree`. All categories count toward the raw resting budget of 40; none are excluded.

| Scenario | Pixels | Unit stats | Hero Health | Fallback names | Costs and controls | Other | All labels | Resting gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| slice recruit | 1688x780 | 14 | 5 | 3 | 8 | 6 | 36 | PASS |
| slice scout | 1688x780 | 16 | 0 | 4 | 8 | 2 | 30 | PASS |
| slice recruit | 1920x1080 | 14 | 5 | 3 | 8 | 6 | 36 | PASS |
| slice scout | 1920x1080 | 16 | 0 | 4 | 8 | 2 | 30 | PASS |
| seed72 recruit | 1688x780 | 8 | 8 | 1 | 5 | 10 | 32 | PASS |
| seed72 recruit | 1920x1080 | 8 | 8 | 1 | 5 | 10 | 32 | PASS |
| overview | 1688x780 | 24 | 8 | 1 | 6 | 18 | 57 | FAIL |
| overview | 1920x1080 | 24 | 8 | 1 | 6 | 18 | 57 | FAIL |
| natural-birds | 1688x780 | 14 | 8 | 0 | 4 | 11 | 37 | PASS |
| natural-birds | 1920x1080 | 14 | 8 | 0 | 4 | 11 | 37 | PASS |
| lobby | 1688x780 | 24 | 8 | 6 | 5 | 11 | 54 | FAIL |
| lobby | 1920x1080 | 24 | 8 | 6 | 5 | 11 | 54 | FAIL |
| scout | 1688x780 | 24 | 0 | 5 | 3 | 3 | 35 | PASS |
| scout | 1920x1080 | 24 | 0 | 5 | 3 | 3 | 35 | PASS |
| reader-reel_mistress-golden | 1688x780 | 32 | 8 | 1 | 5 | 21 | 67 | reader open; reported only |
| reader-reel_mistress-golden | 1920x1080 | 32 | 8 | 1 | 5 | 21 | 67 | reader open; reported only |

Classification uses the actual owning widget and its known field, never whether the displayed text looks numeric. JSON retains every label's text, path, category, owner, field and fallback reason. Each row's five categories sum exactly to All labels.

Fallback names include units without individual art and the four portrait exceptions specified in §2.1: Brock (`young_brock`), Old Brock (`old_brock`), Sable (`sable`) and Russet (`mistress_russet`). These names continue to spend the budget until their portraits are distinguishable at board size.

Gold and queued-income amounts are Costs and controls. Opponent tiers, Ring-stack/Belly/Hex/Midsummer counters and away text are Other. Reader stat beads are Unit stats; reader name/type/rules/reminders are Other. Reader-open rows are not resting-budget passes.

Historical manifests remain unchanged. Earlier captures lack ownership metadata, so this report does not invent a category split for them.

## Costs, controls and other labels

The first size of each scenario is listed below; the table and JSON retain both sizes. Repeated strings remain separate counted nodes.

### slice recruit

- Costs and controls (8): `1`; `1`; `1`; `5`; `16`; `7`; `6`; `End turn`.
- Other (6): `4`; `3`; `4`; `2`; `3`; `Turn 6`.

### slice scout

- Costs and controls (8): `1`; `1`; `1`; `5`; `16`; `7`; `6`; `End turn`.
- Other (2): `3`; `Turn 6`.

### seed72 recruit

- Costs and controls (5): `1`; `1`; `3`; `5`; `End turn`.
- Other (10): `1`; `1`; `1`; `1`; `1`; `1`; `1`; `×4.0`; `1`; `Turn 1`.

### overview

- Costs and controls (6): `1`; `1`; `1`; `10`; `10`; `End turn`.
- Other (18): `1`; `1`; `1`; `1`; `1`; `1`; `1`; `×1.25`; `2`; `2`; `2`; `2`; `36`; `2`; `2`; `One Swallow · home in 1 turn / 7/8 → 14/16 · F3 /  / Mrs Jay · home in 2 turns / 7/7 → 14/14 · F4`; `4`; `Turn 2`.

### natural-birds

- Costs and controls (4): `2`; `0`; `5`; `End turn`.
- Other (11): `1`; `2`; `2`; `1`; `1`; `2`; `1`; `×1.0`; `Chiffchaff · home in 1 turn / 2/3 → 4/6 · F2`; `2`; `Turn 4`.

### lobby

- Costs and controls (5): `1`; `1`; `7`; `10`; `End turn`.
- Other (11): `4`; `4`; `4`; `4`; `4`; `4`; `4`; `×1.25`; `1`; `4`; `Turn 8`.

### scout

- Costs and controls (3): `7`; `10`; `End turn`.
- Other (3): `1`; `4`; `Turn 8`.

### reader-reel_mistress-golden

- Costs and controls (5): `2`; `1`; `24`; `8`; `End turn`.
- Other (21): `2`; `1`; `1`; `2`; `2`; `2`; `2`; `×1.25`; `2`; `2`; `2`; `2`; `38`; `2`; `2`; `4`; `Turn 4`; `Reel-Mistress`; `GOLDEN · CREATED · FAIRIES`; `After a unit on a Ring attacks: its Ring moves to your next unit. Four times per Ring. / Details`; `5`.
