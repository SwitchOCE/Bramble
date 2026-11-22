# Pass 2, round 1: the checker's items, for the voting members to keep or drop

Put together by the orchestrator (an agent). The items are GPT Sol's, from `p2r1-sol-check.md`, word for word apart from the item numbers. Sol checks measurable defects only and has no vote. Each voting member marks every item **keep** (the designer should fix it) or **drop**.

## Facts from the orchestrator (mine, not a judgement)

- Sol's first item for each concept said Briar King must survive, citing `map/state.md`. That line of `state.md` was wrong and is now corrected: in the recorded fight March Hare loses Briar King and keeps six. All three concepts follow the record. Those three items are left out below.
- Item E3: `state.md` says "four cards in hand" at the start of the fight and names three (Home Guard, Hayloft Aunt, Hedge Lancer; Seek was cast). I cannot say which is right without replaying the record.

## A

- **A1.** `hover-board` (x752–1076, y813–1032): Hedge Lancer's tooltip hides both of Blackberry Sprawl's stats and Wing Commander's 17 Health.
- **A2.** `hover-shop`, `keywords-off` (x875–1199, y170–333): Home Guard's tooltip covers Hayloft Aunt and Sweetbriar across a 164 px band of the shop row.
- **A3.** `hover-spell` (x1088–1412, y197–331): Sharpen's tooltip covers Sweetbriar and Shrew Cutpurse across a 135 px band of the shop row.

## D

- **D1.** `fight`, `after` (x760, y0): the top of Weasel's Renown diamond is clipped by the screen. Its 34 px square rotates around y18 and reaches 6 px above the viewport.
- **D2.** `hover-shop`, `keywords-off` (x753–1052, y370–505): Hayloft Aunt's tooltip covers the top of Squadron Leader and cuts into the left edge of Bell-ringer's Renown diamond by up to 17 px.
- **D3.** `hover-board` (x862–1162, y430–566): Granary Glutton's tooltip covers the full width of Bell-ringer and up to 73 px of Squadron Leader through the centre of their cards.
- **D4.** `mid` (x1710, y42 and x1718, y841): leaderboard ordinal contrast is 3.66:1 for Pipkin's 1st (#AC9F87 on #4C443D) and 3.24:1 for Brother Bracken's 8th (#8B8983 on #3C3A38).
- **D5.** `mid` (x92, y66, y174 and y256): the income, upgrade shortfall and discount, and refreshes left at the current price are set at 16 px.
- **D6.** `hover-spell` (x1262–1335, y400–483): Sharpen's tooltip covers up to 74 px of Granary Glutton's upper-right side.

## E

- **E1.** `hover-spell` (x1509–1641, y116–248): the second Sharpen offer's tooltip fully covers the first Sharpen card's 132 × 132 px box.
- **E2.** `after` (x560–570, y811–867): the "See the standings" button overlaps the result panel's right frame by about 10 px.
- **E3.** `fight` (x226–558, y818–1004): three cards are in hand during the opening exchange, with no friendly deaths shown. `state.md` gives 4 cards at fight start, including the Hedge Lancer picked with Seek, which is absent from the hand here.
- **E4.** `hover-shop`, `keywords-off` (x941–1301, y161–311): Home Guard's tooltip covers the full width of Hayloft Aunt and Sweetbriar through a 151 px band of their art.
- **E5.** `hover-board` (x44–306, y627–690): the Fury reminder shows `+N` twice where `state.md` specifies `+1` twice.
- **E6.** `mid` (x578, y465, x978, y465 and x678, y733): the Renown numbers 7, 2 and 3 are set at 17 px.
- **E7.** `hover-shop`, `hover-board` (x24, y528 and y587): the top of the keyword reminder panel moves down 59 px between views. Its bottom edge stays at y712.
