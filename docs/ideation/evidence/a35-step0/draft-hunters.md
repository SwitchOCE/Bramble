*[Saved verbatim from workflow wf_ce74d9f0-cdb, 10 Nov: the hunters analyst draft. The critic's corrections in critic-hunters.md win where they differ.]*

## Hunters: B and C dial check

**Verdict:** Hunters' committed lines have never been measured at R12 at B or C. On paper, today's moving dials can't reach 900 or 1,800 by themselves. They can only get there if the rest of the lobby grows to its targets. I propose three extra dials.

### 1. Dials (`424b3c2a:content/pass3/rates.json`)
Preset A sets no Hunters dials, so A = base = B for every Hunters dial. Card text comes from `content/units/*.json` and `docs/ideation/content/pass3/hunters-pass3.md`. Paths: gains = `src/core/combat/pass3_hunter_gains.gd`, text = `src/core/pass3_hunter_text.gd`, combat = `src/core/combat/pass3_hunter_combat.gd`.

| Dial | A = B | C | Moves | Read at | Card and text at B |
|---|---|---|---|---|---|
| `nip/sable/lutra_share` | 2/3 | 3/4 | yes | gains:18 through combat:40–47; text:51–58, 76 | Nip, Sable, Lutra: "Take: gain two thirds of the quarry's stats permanently." |
| `glutton_share` | 2/3 | 1 | yes | gains:34; text:124 | Glutton: "After each Take: gain two thirds…" |
| `lodger_share` | 2/3 | 1 | yes | gains:34; text:101 | Lodger: "After a Take beside this: gain two thirds…" |
| `wick_share` | 1/3 | 1/2 | yes | gains:89; text:61 | Wick: "gain a third of the target's stats" |
| `grizel_share` | 1/3 | 1/2 | yes | gains:101; text:119 | Grizel: "its attackers gain a third…" |
| `pelt_share` | 1/3 | 1/2 | yes | gains:157; text:41, 177 | Pelt: "give a Hunter a third of the prey's stats" |
| `russet_buff_share` | 2/3 | 3/4 | yes | gains:58; text:93 | Russet: "a copy, with two thirds of its buffs" |
| `ermeline_pelts` 1 (golden 2), `laird_multiplier` 2 (golden 3), `golden_take_multiplier` 2, `golden_russet_buff_share` 1 | same | same | no | gains:154, 46; combat:46 | Ermeline, Laird ("triggers twice"), every golden |
| `sable_strike` 1/2, `agnes_hit_back` ½/¼, `isegrim_health_cut` 0, `russet_copies` 1, `lane_bard_*` 1/2/2, `take_floor` 1, `young_brock_share` 1, `trophies_after_fight` true | same | same | no | `pass3_hunter_start.gd:110`, gains:59, 112, combat:154, 170, `src/core/pass3_hunters.gd:48` | fight-only, economy or rule switches |

Card text is generated from the dials, so it stays true on any path value.

### 2. Realized boards
- **Open Season** (the engine line) and **Pack**: there are no committed-line lobbies at B or C. Nothing under `docs/ideation/evidence/` or `tools/sim/evidence/` at 322a28cb covers them; `wave1-rebase` seats only Birds and Fairies. RESTART line 99 lists no Hunters line.
- **Nearest data:** 3 bot games with forced Hunter seats on wave 2a (Hard bots, not the committed lines, 7 seats, before the narrowed pin and the engine-piece fix). R12 was **216–467**: `322a28cb:docs/ideation/evidence/review-wave2a-hunters.md:13-14`, also `DECISIONS.md:518`. The lobby's R12 median was about 291 (`review-wave2a-hunters-narrow.md:7`).
- **C:** not measured at all.
- **Older content:** the `line_hunters_*` lines in `harness-baseline.md` are pass 2, so I didn't use them.

### 3. Factor needed
- **B:** 900 ÷ (216–467) = **×1.9–4.2**, or ×2.8 at the geometric midpoint of 318.
- **C:** projected from paper (C ÷ B = 1.31 at today's lobby size), C would be about 283–611, so 1,800 ÷ that = **×2.9–6.4**, or ×4.3 at the midpoint.

### 4. Plausibility
I ran a copy of `hunters-pass3-model.py` with path values and a scaled field (pre-fight boards, n=160).
- At s=½ the copy reproduces the doc's figures, 519 / 594.
- Path values: Takers 0.67 → 0.75 → 0.84 → 0.95; Glutton and Lodger 0.67 → 1, then **clamped at 1** from t=1; Wick, Grizel and Pelt 0.33 → 0.5 → 0.75 → **1** (clamped at t=3).
- Paper to real: 318 ÷ 505 ≈ **0.63**, with a range of 0.43–0.92.

Open Season R12 on paper, with the realized estimate (×0.63) in brackets:

| Field median at R12 | t=0 | t=1 | t=2 | t=3 |
|---|---|---|---|---|
| 270 (today) | 505 (318) | 660 (416) | 708 (**446**) | 750 (**473**) |
| 900 | 1,099 (692) | 1,649 (**1,039**) | 1,906 (1,201) | 2,085 |
| 1,800 | 1,642 | 2,513 (1,583) | 2,942 (**1,853**) | 3,540 (2,230) |

- **Own dials only:** at today's lobby size, t=2 gives about 446 (0.50× of 900) and t=3 about 473 (0.26× of 1,800). **Not plausible.**
- **The clamps bind:** the field-532 run reaches 1,393 at t=3 clamped, against 2,101 unclamped. Past t=1, each step adds only ×1.07–1.16.
- **Hunters eat the field:** R12 rises about as field^0.65. If the other tribes reach 900 and 1,800, Hunters land near B at t≈1 and C at t≈2. Oozes realize 250 today and Bog's lines are unmeasured, so that condition is shaky.
- **The fit is confounded:** run 1 moves every tribe at once, so a Hunters fit against t mixes their own dials with the lobby's growth. Fit Hunters' R12 ÷ lobby median against t instead, or solve Hunters last.
- **Who carries B→C today** (field 532, each dial alone): Glutton ×1.15, Lodger ×1.11, Takers ×1.07, Pelt ×1.04, all together ×1.35. The Glutton carries most, and it's clamped from t=1.

### 5. Proposed extra dials (Open Season; paper multipliers at field 900)
**P1. `hunters_laird_multiplier` and `hunters_golden_laird_multiplier` (existing)**
- B 2 (golden 3), C 3 (golden 4). Path rounded up: 2, 3, 5, 7; golden 3, 4, 6, 8.
- Limit: a whole number, at least 1 (gains:46 rounds down). "Your 'Take:' text triggers twice" sets no ceiling. Golden stays above normal.
- Text at B is unchanged. At C: "Your 'Take:' text triggers 3 times."
- R12: ×1.11 at t=1, ×1.35 at t=2, ×1.58 at t=3. It makes every Taker's gain bigger without touching the share clamp.

**P2. NEW `hunters_laird_after_take_repeats` (proposed)**
- B 1, C 2. Path 1, 2, 4, 8.
- Limit: the Glutton's and Lodger's shares stay at their limit of 1 ("gain the quarry's stats"). Repeating the event keeps that text true.
- At B nothing changes: the Laird reads "Your 'Take:' text triggers twice", and the Glutton's details keep "the Laird does not repeat this reward". At C: "Your 'Take:' text triggers 3 times, and 'After each Take' text twice." The Glutton and Lodger details become "the Laird repeats this reward."
- Code: apply `_repeats` to the Lodger and Glutton loop (gains:26–37), and value it in `bot_hunt.gd`.
- R12: ×1.19 at t=1, ×1.54 at t=2; at today's field, ×1.47 at t=2. This grows the size of the carry's buff, the Quilboar lever.

**P3. `hunters_ermeline_pelts` and its golden twin (existing)**
- B 1 (golden 2), C 2 (golden 4). Path 1, 2, 4, 8; golden capped at 10.
- Limit: the hand limit of 10 (`game_config.gd:70`; "With a full hand it waits on the doorstep").
- Text at B is unchanged. At C: "After each fight: get two Pelts of your biggest quarry."
- R12: ×1.41 at t=2, ×2.11 at t=3. Each Pelt is a buff on the Glutton, not a new body, and Pelts come even after a lost fight.

**With the proposals:**
- P1 and P2 together at today's field size: t=2 gives 1,244 on paper (about **784**, 0.87× of 900).
- P1 to P3 together at t=3: 2,723 on paper (about **1,715**, 0.95× of 1,800).
- If the field does reach its targets, P1 and P2 at t=1 give about 1,356 (1.5×), and the fit simply picks a lower t.

The model copy and drivers are in `/tmp/claude-1000/-home-alex-code-Bramble-ideation/94bf7aaf-6a89-4561-b3da-52d1971d0dd7/scratchpad/hmodel/` (`hm.py`, `drive.py`, `drive2.py`, `drive3.py`).