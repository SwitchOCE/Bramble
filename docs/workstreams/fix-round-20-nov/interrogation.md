# Plan interrogation: fix round, 20 Nov

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| 1 Buy to board, swap | Items 2, 3 | Agent; owner asked for both | keep, reorder | Shares `recruit.gd` `_gain`/`_buy` with step 3, and its own checks lean on step 3's pile. Run it after step 3, not in parallel. |
| 1: bots' LegalActions | No | Not in plan | ask | `legal_actions.gd:66-83` lists empty slots only. Bots won't buy to the board or swap unless it's added, and league balance runs on dev. |
| 2 Skip button | Item 5 | Owner's ask; Space kept by agent | keep | Smallest fix. |
| 3 Waiting pile | Item 1 | Owner ("queue … little indicator") | keep | Hover list and "stays across turns" are small. A limit on the pile is open in the mock-up NOTES, not in the plan. |
| 4 Marks | Item 4 | Owner's rule | keep | Matches the owner's words exactly. |
| 5 Art + missing-art test | Item 6 | Owner; test by agent | keep | Test is cheap and stops the gap coming back. 16 A/B picks is a lot of decisions; offer "pick all A" as a default. |
| 6 Type line, tooltips | Items 8, 9, 13 | Owner; places by agent | keep | Fine. |
| 7 Shop layout | Item 7 | Owner ("look at new layouts") | keep | The agent misclick play-test is extra but small. |
| 8 Start-of-turn | Item 13 | Owner ("should be start of turn") | keep | Turn-start playback is the owner's stated reason. The Hopper arrival comes free with it. |
| 8: "Grudge 1" keyword | Only the golden reminder bug | Agent | keep | Fixes a real bug with less text. |
| 8: Grudge pays the dead | Item 13's question | Agent | ask | The owner asked to *understand* this, not to keep it. |
| 9 Goldens (12 cards) | Item 12 | Rule from owner; card picks by agent | keep | Only the Fury 1/2 call needs the owner. |
| 10 Old Brock change + league match | No; item 14 is a question | Agent | ask | `design/old-brock.md` already answers it (Blue rates him 5th of 95; on target mid-board, ~3x over late). Numbers predate the dev reworks. Answer first; change him only if the owner wants. |
| 11 Keyword looks | Item 10 | Owner; looks by agent | keep, redo inputs | `keywords/` mock-ups use main's content: Stiff Upper Lip is drawn, and it's gone on dev (0 hits in dev's `pigeon/units.json`). Renown, Charge, Supply and Hand-me-down are missing. |
| 12 Animations | Item 11 | Owner ("prototype for every single one") | keep, redo inputs | `anim-fight/events.js` animates Medals, which are removed on dev. `anim-recruit/` has no NOTES.md. |
| 12: skip as fast-forward | No | Agent | defer | The owner asked for a button, not a speed control. |

**Fixed after step:** the bugs (items 1-6) after the last of steps 1-5 merges plus a Windows build. The whole complaint (items 1-14) only after step 12, the last step. Item 14 can be answered today with no step at all.

**Smallest plan:**
1. Answer Old Brock in chat now.
2. Steps 2, 4 and 5 in parallel. Step 3, then step 1.
3. Windows build: the owner re-checks items 1-6.
4. Step 8, then 9.
5. Steps 6 and 7.
6. Redo the keyword and fight-animation mock-ups on dev content, then the owner picks.
7. Step 11, then step 12 in batches.

**Deferred:**
- Step 10: until the owner, given the answer, asks for a change.
- Skip fast-forward: until the owner asks for speed control.
- Bot support for buy-to-board and swap: until a balance run needs it (unless the owner says now).

**Checkpoints:**
- After steps 1-5: the owner plays a Windows build.
- After steps 8-9: rules changed. Re-sync the parallel Badger balance work on dev, because "Grudge 1", the goldens and Brock all touch Badgers.
- After step 7, before step 12.
- After each animation batch.

**Open questions (owner only):**
1. Waiting pile or a hand over 7. Is there a limit on the pile?
2. Is buying to the board and swapping OK as rules? Should bots get them now?
3. Grudge: pay dead units too, or survivors only?
4. Old Brock: is the answer enough, or change him?
5. Fury 1 or 2 on the free-attack goldens.
6. The picks: layout, type line, tooltip place, art, keyword looks, animation order. Keyword looks and animation order only after the mock-ups are redone on dev.
