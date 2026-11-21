# Today's recruit and fight screens: the baseline to beat

Judged mid-game from the running build at 1920 x 1080 (`state.md`: turn 9, full board, 20 gold, a full shop, a spell in hand), with the `game-ui-design` skill's checks. Today's layout is one option among others on this branch; it is judged on its merits, not as a rule. The fixed things (woodland theme, lead and stained glass, the tall hexagon cards) are not criticised here.

Every finding comes from stills and the code. I am an agent: I never tire, misclick or forget a card, and I saw the game at about four frames a second (`docs/AGENT-BLIND-SPOTS.md`). Motion, timing, hover feel and sound are **not judged**.

Shots: `/data/ui-ideation/baseline/shots/`.

## Critique: Recruit, mid-game (turn 9, `recruit-mid.png`)

Decisions this phase: buy a unit or spell (and cast it on whom); where to place each unit (front/back row, Renown slots); move between board and hand; sell; refresh; freeze; upgrade; pick a Discover; end the turn; plan against the lobby (health, income, opponents).
Targeted outcomes: (1) read the shop and the board fast enough to decide without opening each card; (2) know who I face and how I stand.
Glance tier: **23** items (`map.md` lists them).

| # | Finding | Severity | Fix |
|---|---------|----------|-----|
| 1 | **Card faces show no name, tribe or rules text.** To weigh five shop offers against seven board units the player opens a detail per card (hover or click). Mid-game that is up to 12 opens per shop, and again after each refresh (I refreshed ten times on turn 9). Art alone must carry identity across 108 units. *[Whether a returning player recognises them by art is exactly what an agent cannot test; the owner's hands can.]* The keyword marks that do show are ~14 px monochrome icons along the card's bottom lead, many with a tiny number beside them. | slows play | Put the deciding facts on the face at a size that reads: a name or short title on shop cards at least, and larger keyword marks with their numbers. Or a "read" view one key or click away that labels every card on screen at once. |
| 2 | **The decision area is small inside a large frame.** Cards are about 140 x 250 px. The shop and board use the middle ~650 px of a ~1400 px centre pane; about 400 px of empty lattice sits each side, and the four side lights below and above the corner controls are empty glass. The space that would let cards be bigger, or names fit, holds texture. | slows play | Grow the cards (the board is only 4 wide) or move the hand, leaderboard and counters into the side space; keep the frame as frame, not as empty panels. |
| 3 | **The hand is cut off by the bottom edge.** Only the top third of each hand card shows (`recruit-mid-hand3.png`): no stats, no marks. Hovering lifts one card at a time (`recruit-mid-hand-hover.png`). Reserve units fight from the hand, so the hand is part of the fighting force, but it reads as a drawer. | slows play | Show hand cards whole, smaller if needed, or at least their stats and marks; or give the hand a fixed band with room. |
| 4 | **The lobby is hidden behind your own portrait.** The leaderboard opens on a click on *your* portrait or Tab; nothing on screen says so. Once open it shows portraits, places and health only: no names, tiers, tribes or the last result against each, and hovering an entry shows nothing (`recruit-mid-leaderboard.png`; hover: `recruit-t2-leaderboard-hover.png`). The next opponent's portrait (on End turn) shows their health but not their board; the board they last brought is in Past boards only if you have already fought them. | slows play | Keep the eight always visible in compact form (they are glance information for planning: lose conditions), each one click from its last known board; or label the toggle. |
| 5 | **Refusals are uneven.** "not enough gold" appears in small lowercase text in the gap between shop and board, away from the gold counter (`recruit-not-enough-gold.png`). Dropping a unit on a full board sends nothing: the card slides back to the hand with no word (`recruit-board-full-drop.png`, the game record holds no action). The player learns why only by counting slots. | slows play | Say the reason at the point of the action (on the gold counter, on the board), and refuse a drop visibly when the board is full. |
| 6 | **Unaffordable prices are hard to read.** An unaffordable price turns the coin silver and the numeral pink: pink (255,180,162) on the silver coin (~160,157,146) measures about **1.6 : 1**, under the 4.5 : 1 text and 3 : 1 UI floors. The upgrade cost "23" uses the same. The silver coin is a second cue, so "can't afford" is not told by colour alone, but "by how much" can't be read. | polish | Keep the gold/silver coin cue, draw the numeral dark on silver (or light with a dark rim). |
| 7 | **Small readouts crowd the glance tier.** "10 left at this price", "−3 next turn", "+19", the turn number, Past boards, Cards and the cog all sit at the glance level with the decision information. Of the 23 glance items, five or six are rarely needed while recruiting. | polish | Move refresh stock, upgrade discount and the corner buttons to reach (on the control's own detail, or a menu); keep gold, prices, health, next opponent and End turn. |
| 8 | **Renown reads as the card's, not the slot's.** The slot's Renown pill sits on the top tip of the card in that slot; in the back row it overlaps the gap between rows (`Renown 3` between Famine-caller and Wing Commander). When a unit moves, the pill stays: the rule (Renown belongs to the slot) is the opposite of what the picture suggests. | slows play | Draw Renown on the slot itself (under or around the empty hexagon, visible when the slot is empty too). |
| 9 | **No single action accent.** Buttons are slate glass, coins are gold, the End turn label is orange, the income pill is gold, your ring is white, the next opponent's ring is gold. When gold is spent, nothing marks End turn as the next step. | polish | Keep one accent for "press next" (End turn when nothing is affordable, the Discover pick, a pending target). |
| 10 | **Counters sit far from what they change.** Compost 3 and Tide 2 are plates by your portrait, bottom left; Tide changes every Locust's Attack and Compost drives Grow and Sweetbriar on the board. In the fight they change (Tide 2 → 4) out of the eye path. | polish | Put each counter next to the units it feeds, or flash the units it changes when it changes. |
| 11 | **Tier is told by frame colour alone on the card face** (cream, green, blue, purple, gold, red). The detail names the tier, but at a glance a colour-blind player can't tell T3 blue from T4 purple. | polish | Add a second cue on the face (pips, a numeral in the lead). |
| 12 | **The golden preview is hotkey-and-hover only** (hold Alt over a card). | polish | Offer it in the card's click detail too. |

Not judged from stills: dragging and dropping (the owner found the feel wrong once before, 17 Nov), hover delay, the turn-start and triple animations, the sell cue while dragging (not caught in a still), sound, other resolutions and real hardware.

What works:
- **Controls sit next to what they act on.** Gold and upgrade left of the shop, refresh and freeze right of it, the shop directly above the board: the eye path from a price to the gold to the slot is short, and nothing jumps between turns.
- **Card detail on click as well as hover, and honest numbers.** The detail lists printed stats and each buff's source ("Printed 6/4. Tide +2/+0. Renown +7/+7."), one box per keyword with its own wording. Buffed stats turn green on the face. This is better than most of the genre.
- **Affordability at a glance.** Gold coins for what you can buy, silver for what you can't, on every price, the refresh and the upgrade.

Top 3 changes:
1. **Put identity on the card face** (finding 1, with 2 to make room): it is the most frequent cost in every mid-game turn and the reason the hundredth game is still slow.
2. **Make the lobby glance information** (finding 4): health and the next opponent are lose-condition state; where you stand decides whether to upgrade or spend.
3. **Show the whole hand and refuse visibly** (findings 3 and 5): reserves fight from the hand, and silent refusals cost the player a guess each time.

## Critique: Fight, mid-game (turn 9 vs March Hare, `fight-mid-t9-start.png` … `fight-mid-t9-result-defeat.png`; also turn 8 vs Little King Wren)

Decisions this phase: watch or skip; pause. The real job of the screen is to let the player learn: what did the opponent bring, which unit beat me, what to buy against it.
Targeted outcomes: (1) see what each side has and what is happening now; (2) know afterwards why I lost and by how much.
Glance tier: **9** items during the fight, **11** at its end (`map.md`).

| # | Finding | Severity | Fix |
|---|---------|----------|-----|
| 1 | **The opponent's units are unnamed strangers.** Mid-game the opponent brings units the player may never have seen in their own shop (Briar King T6, a golden Gorger 38/68, The Eighth Plague). The faces carry art, stats and tiny marks only. Learning what they are means hovering a moving unit or opening Past boards afterwards, which shows the starting boards *[I did not check whether its cards open a detail]*. | slows play | Name the units (at least the enemy's), and make each fight inspectable afterwards: Past boards with the same card detail, and the fight's key events. |
| 2 | **Why I lost is not told.** "Defeat" appears in the middle, "−13" on my portrait bottom left, my health goes to 0, the leaderboard slides in. Which enemy units survived and what the 13 is made of are not shown. | slows play | A short end-of-fight line: survivors and the damage they make. |
| 3 | **The fight uses the same small cards in a mostly empty frame.** Fourteen cards fill the middle ~650 px; the side lights hold one portrait each and the Skip button. The moment with the most to read is drawn at the same scale as the shop. | polish | Scale the boards up in the fight, or use the side lights for each side's key facts (counters, reserves waiting). |
| 4 | **State that changes during the fight sits out of view.** Tide went 2 → 4 on my plate bottom left while units died in the middle; reservists step in from a hand the fight screen does not show. | polish | Show changes where they act (on the units), and show waiting reservists. |
| 5 | **Damage numbers are on the hit unit only.** A "−19" splash covers the card's art; the attacker's Attack is the cause but is not marked with it. In a still the hit and its source are hard to pair; in motion it may be clear (not judged). | polish | Not judged from stills; check on film before changing. |

Not judged from stills: the attack motion and its pace, how long a fight takes, whether the eye can follow which unit attacks, the Skip timing, the end splash's timing, sound. A full mid-game fight took over a minute and a half of wall time in this slow session; real pace unknown.

What works:
- **Stability.** Your board stays exactly where it was in recruit (bottom half), the opponent mirrors above with front rows meeting in the middle, and the corner pieces (cog, turn, your portrait) do not move. Skip sits where End turn was: the "go on" control keeps its place.
- **The opponent is clear:** portrait, name and health in the right light for the whole fight.
- **Marks carry across:** Renown, golden rims, Charge pips and keyword marks look the same in recruit and fight, so a learned look is reused.

Top 3 changes:
1. **Make the fight explain itself afterwards** (findings 1 and 2): the player's only lesson from a loss today is a number.
2. **Name the enemy's units** (finding 1): they are the cards a player knows least.
3. **Show fight-time changes where they happen** (finding 4).

## What a redesign should target first

1. **"I can read the shop and my board mid-game without opening each card."** This is the most frequent action in the game (every shop, every refresh, every turn) and today it costs a hover or click per card. It also drives how big cards must be, where the hand goes and how the empty frame is used, so solving it shapes the rest of the layout. It serves the hundredth game: a returning player still has to identify 108 units by picture alone.
2. **"I know who I'm up against, and after a fight I know why I won or lost."** Opponents' standing is lose-condition information that is hidden today behind an unlabelled toggle, and the fight, the game's payoff, ends with a single number. Both are cheap to show and both change what a player buys next turn.

Both are testable on the two screens a council can compare side by side: the same `state.md` moment drawn by each concept.
