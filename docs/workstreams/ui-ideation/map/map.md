# Map of today's game: screens, decisions, information tiers

From the running build (`ideation/ui-ux` at `98e8ba68`, game code as `dev` at `007e2789`) at 1920 x 1080, and its code (`src/screens/`, `src/game/`, `src/main/`). Method: the `game-ui-design` skill (`/data/ui-ideation/skills/game-ui-design/SKILL.md`). The tiers sort **today's** screens as they are; where today's placement looks wrong for the tier, that goes in `critique.md`, not here.

Screenshots: `/data/ui-ideation/baseline/shots/`. The exact mid-game state: `state.md`.

Tier words: **glance** (always on screen, read in two seconds), **reach** (one click or key away, at the point of use), **archive** (found when looked for), **hidden by design** (the game withholds it), **not yet** (appears when it first has something to show).

## How a player moves between screens

```
Start ──Play──▶ Recruit ──End turn (click next opponent's portrait)──▶ Fight ──(plays out, or Skip / Space)──▶ Recruit (next turn)
  │               │  ├─ Past boards ──Back to recruit / Esc──▶ Recruit                              │
  │               │  ├─ Compost plate ─▶ Compost panel (overlay) ─Close / Esc─▶                     └─ when you are out ─▶ Result ─▶ Play again / Start screen / Quit
  │               │  ├─ Cards ─▶ Card browser (overlay) ─Back / Esc─▶
  │               │  └─ Your portrait / Tab ─▶ leaderboard (toggles in place)
  └─Cards─▶ Card browser ─Back─▶ Start
Esc or the cog (recruit and fight) ─▶ Pause panel ─▶ Resume / Quit to start / Quit
```

There is no menu, hero, tribe or lobby choice before a game: Start has Play, Cards and Quit, and shows the eight portraits of the lobby ("Play against seven ghosts"; yours is labelled "You"). All five tribes are in every game. When the human is out, the remaining ghosts play out off screen and the result screen appears straight after the losing fight.

## Screens reached and shots

| Screen or state | Shot(s) | How reached |
|---|---|---|
| Start | `start.png` | live |
| Card browser (units, a card's detail, spells) | `browser-start.png`, `browser-card-detail.png`, `browser-spells.png` | live, from Start; the in-game Cards button opens the same browser (code: `src/screens/browser/`) |
| Recruit, turn 1 | `recruit-t1.png` | live |
| Card detail (click or hover; name, tier, cost, keyword boxes) | `recruit-t1-card-detail.png`, `recruit-board-unit-tip.png`, `recruit-mid-hand-hover.png` | live |
| Hover on upgrade, refresh stock, End turn (no tip appears) | `recruit-t1-hover-upgrade.png`, `-hover-stock.png`, `-hover-endturn.png` | live |
| Bought a unit; a spell in hand (with its tip); after casting it on a unit | `recruit-t1-bought.png`, `recruit-t1-hand-spell-tip.png`, `recruit-t1-after-spell.png` | live |
| Not enough gold | `recruit-not-enough-gold.png` | live |
| Shop frozen | `recruit-shop-frozen.png` | live |
| Fight, turn 1: start, an attack, defeat | `fight-t1-start.png`, `fight-t1-attack.png`, `fight-t1-result-defeat.png` | live |
| Recruit turn 2; leaderboard open | `recruit-t2-start.png`, `recruit-t2-leaderboard.png`, `recruit-t2-leaderboard-hover.png` (hovering an entry: nothing appears) | live |
| Past boards | `past-boards.png` | live |
| Pause | `pause.png` | live (Esc) |
| Recruit turn 8 (autoplayed), with a spell tip | `recruit-t8-autoplayed.png` | live, debug autoplay (F8) turns 3–8 |
| Compost panel | `compost.png` | live |
| Fight turn 8: start, attack, damage, a big hit, late, defeat with leaderboard | `fight-mid-start.png`, `fight-mid-attack.png`, `fight-mid-damage.png`, `fight-mid-big-hit.png`, `fight-mid-late.png`, `fight-mid-result-defeat.png` | live |
| **Recruit mid-game (turn 9)**; with leaderboard | **`recruit-mid.png`**, `recruit-mid-leaderboard.png` | live |
| Hand of 3 and 4 cards; board full | `recruit-mid-hand3.png`, `recruit-mid-duplicate-in-hand.png` | live |
| Discover (Seek spell) | `recruit-discover.png` | live |
| Duplicate glow on a shop card (a copy of a board unit) | `recruit-duplicate-glow.png` | live |
| Refresh price stepped up (2 gold), unaffordable prices greyed | `recruit-refresh-price-up.png` | live |
| Dropping a hand unit on a full board (it goes back, no message) | `recruit-board-full-drop.png`, `recruit-board-full-after.png` | live |
| After selling a unit (Compost 3 → 4, gold +2) | `recruit-after-sell.png` | live |
| Fight turn 9 (the fight after `state.md`): start, attack, big hit, late, defeat | `fight-mid-t9-start.png`, `-attack.png`, `-big-hit.png`, `-late.png`, `-result-defeat.png` | live |
| End of game (result) | `game-end-result.png` | live, out in 7th |
| Triple: third copy in the shop with duplicate marks, the golden forming, the Triple Reward, after | `triple-1-third-copy-in-shop.png` … `triple-4-after.png` | frames from the film tool's scripted triple (`tests/screens/feel/triple-reward.json`, `tools/feel/film`), a real game scene with a set-up board |
| A unit's ability button ("Order 1") | `fixture-recruit-ability.png` | test fixture scene `tests/screens/recruit_ability.tscn` (stand-in units; no live unit has an ability today) |

**Not reached, and why:**
- **The sell cue while carrying a card.** The game shows a dark pane over the shop with the sale value while a card is carried (`RecruitShop.show_sell`), but `look` can only drag-and-release, and the still caught after the release. Not photographed.
- **Golden preview (hold Alt over a card).** Exists in code (`src/screens/glass_tips.gd`); not photographed.
- **Choosing a spell's target** shows "Choose a target" in the message line (`AIM_PROMPT`); my clicks on Sharpen went straight to a drag-cast, so no shot of the aiming state. A fixture exists: `tests/screens/recruit_aim.tscn`.
- **A full hand (7/7).** Not reached live (hand reached 4/7). The film scenario `tests/screens/feel/triple-full-hand.json` covers it.
- **A locked shop.** The build has no shop lock besides Freeze (shot). The prototype Lock keyword named in `docs/STATUS.md` has no screen element I could find in `src/screens`.
- **Winning a fight, and winning the game.** Both of my mid-game fights were losses; the turn-1 fight too. The result splash reads "Victory"/"Defeat" by the same code path; the game-won result screen was not seen.
- **Error G1** (no ghosts) and "Restart Bramble to play against more ghosts" on Start: not reached on purpose.
- Settings beyond the pause panel: there are none.

## Recruit

The main screen. Primary area: the board (bottom half) and the shop (top half), which share the centre column.

### Decisions, in player words

| Decision | What the player must know to make it |
|---|---|
| **Buy this unit or not** (drag to the board or hand; double-click buys into the hand) | its price; whether I can afford it (gold); what it does (name, text, keywords, stats); whether it pairs with my board (tribe, duplicates toward a triple); whether there is room (board 7/7, hand x/7) |
| **Buy this spell or not, and cast it on whom** | price, gold, its text, which unit is the best target |
| **Where to put a unit** (slot; front row 0–3 or back row 4–6) | slot positions, which slots carry Renown, front/back rules (Sortie hits the back row, Guard, "units in front of this"), what each unit does |
| **Move units between board and hand** (free) | board and hand contents; Reserve units step in from the hand during fights |
| **Sell a unit** (drag to the shop) | its sale value (1–3); what selling triggers (Compost, Glutton eats Locusts); what I lose |
| **Refresh the shop** | refresh cost; gold; how many refreshes are left at this price ("10 left at this price") |
| **Freeze the shop** | whether the shop is frozen now |
| **Upgrade the tier** | upgrade cost, gold, the discount next turn ("−3 next turn"), my tier now |
| **Play or keep a hand card** | hand contents and their text |
| **Pick one of three (Discover)** | each option's stats and text (shown under each option) |
| **Use a unit's ability** (none in today's content; fixture only) | ability cost, what it does |
| **End the turn** | that nothing else is worth doing; who I fight next and their health |
| **Plan for later turns** (implicit) | my health vs others', next turn's income (+19), opponents' strength (tier, tribes, boards), what the last fights did |

Information a player wants but today's screen does not give at all: opponents' tiers, tribes and current boards (only their portrait, place and health); the next opponent's last board; card names on the card face (hover or click needed); how much damage I take if I lose next.

### Elements and tiers (mid-game, `recruit-mid.png`)

| Element | Where today | Tier |
|---|---|---|
| Board units: art, Attack, Health | bottom half, two rows 4 + 3 | glance |
| Keyword marks on units (small icons under the card; number for Fury/Grow) | card bottom edge | glance (tiny) |
| Renown pills on slots | above each slot's card | glance |
| Charge pips (white dots) | across a card | glance |
| Tier colour of each card (frame) | card frame | glance |
| Shop units: art, Attack, Health, marks | top half centre | glance |
| Shop prices (coins; greyed when unaffordable) | under each shop unit | glance |
| Shop spells with price | top centre, above the shop | glance |
| Gold | left of the shop | glance |
| Upgrade button: tier "5 → 6", cost (dimmed when unaffordable) | left of the shop | glance |
| Upgrade discount "−3 next turn" | under upgrade | glance |
| Refresh button and cost | right of the shop | glance |
| Refresh stock "10 left at this price" | over refresh | glance |
| Freeze button (and its on state) | right of the shop | glance |
| Your health (and portrait, name) | bottom left | glance |
| Counter plates (Compost 3, Tide 2) | bottom left, over the name | glance |
| Next opponent's portrait and health, which is also End turn | bottom right | glance |
| Next turn's income "+19" | by End turn | glance |
| Hand count "Hand 1/7" and the hand cards' tops | bottom centre | glance |
| Turn number | top left | glance |
| Settings cog | top left | glance (a control) |
| Past boards button | top left | glance (a control) |
| Cards (browser) button | top right | glance (a control) |
| Message line ("not enough gold", "Choose a target") | between shop and board | not yet (appears on a refusal or while aiming) |
| Duplicate glow on a shop or hand card that copies a board unit; duplicate marks | the card's rim | not yet (when a duplicate exists) |
| Frozen look on the shop | the shop | not yet (when frozen) |
| Card detail: name, tier, type, cost or sale value, rules text, printed stats and each buff's source, a box per keyword | beside the card, on hover **or click** | reach |
| Keyword explanations | the same detail, one box each | reach |
| Golden version of a card | hold Alt while hovering | reach (hotkey and hover only) |
| Leaderboard: all eight portraits, places, health; next opponent ringed | right light, on click of your portrait or Tab | reach |
| Sell cue (dark pane over the shop with the sale value) | while carrying a card | not yet (while dragging) |
| Discover overlay (three options with text) | centre, veiled screen | not yet (when a Discover fires) |
| Past boards: your and each opponent's starting board in the fights you played | its own screen | archive |
| Compost contents, newest first | Compost panel (click the plate) | archive |
| Card browser: every unit and spell, by tribe and tier, golden toggle, search | overlay | archive |
| Seed | pause panel | archive |
| Opponents' boards now, tiers, tribes | nowhere | hidden by design? *[unsure: the async ghost rules may withhold them; I found no owner decision either way. Designers should not assume they may show them.]* |
| Shop odds, what the next refresh holds | nowhere | hidden by design |
| Opponents' hands and gold | nowhere | hidden by design |

**Glance tier: 23 items** (counting each row marked glance above once; the board's and shop's cards count as one item each, with their parts listed separately where they are separate things to read: art and stats, marks, Renown, charge pips, tier colour). Of these, three are controls that are not about this phase's decisions (cog, Past boards, Cards), and two are rarely-needed readouts (turn number, upgrade discount).

## Fight

Primary area: both boards, centre column; you below, the opponent above, mirrored (their back row at the top, front rows meet in the middle).

### Decisions, in player words

| Decision | What the player must know |
|---|---|
| **Watch or skip** (Skip button bottom right, or Space) | nothing; whether I care how it goes |
| **Pause** (cog or Esc) | — |
| **Learn from it** (not an action, but the reason to watch): why did I lose, which enemy unit beat me, what to buy against it next turn | each unit's name and text on both sides; what each trigger did; damage dealt to me and why that amount |

### Elements and tiers (`fight-mid-t9-start.png` … `-result-defeat.png`)

| Element | Where | Tier |
|---|---|---|
| Both boards: art, Attack, Health, marks, Renown pills, golden rims | centre | glance |
| The attacker and its target (the attacker moves onto the target; it lifts and glows) | centre | glance (motion: not judged) |
| Damage splashes ("−19" on the hit unit) | on the unit | glance, briefly |
| Units dying (slot empties) | board | glance |
| Opponent's portrait, name, health | right light, top | glance |
| Your portrait, name, health; counter plates | left light, bottom | glance |
| Turn number; settings cog | left light, top | glance |
| Skip button | right light, bottom | glance (a control) |
| Result word ("Defeat" / "Victory") and the damage on the loser's portrait ("−13") | centre and portrait | not yet (at the end) |
| Leaderboard (slides in on the right at the end) | right light | not yet (at the end) |
| Unit detail on hover | beside the unit | reach *[from the code's shared tips; I did not hover during a fight]* |
| The fight log, step by step | Past boards shows only the starting boards; there is no log | archive (only partly: start boards) |
| Why the damage is that number (the rule behind it) | nowhere | hidden by design? *[unsure; no owner decision found]* |

**Glance tier: 9 items** during the fight (boards; attacker/target; splashes; deaths; opponent; you; turn; cog; Skip), plus 2 at the end (result, leaderboard).

## Start

Decisions: **play**, **look at the cards**, **quit**. What the player must know: nothing beyond the button names. Glance: title "Bramble", "Play against seven ghosts", the eight lobby portraits ("You" under yours), Play, Cards, Quit: **6 items**. Not yet: the "no ghosts" error. No settings, no profile, no tribe choice, no record of past games.

## Result (end of game)

Decisions: **play again**, **go to start**, **quit**. What the player must know: my place; the final standings. Glance: "You placed 7th", "Round 9", a list of all eight (place, portrait, name, health; you highlighted in gold), Play again, Start screen, Quit: **6 items**. Missing: my final board, which ghost knocked me out, any record of the game. *[The other players' health shows 0 for places 2–8 although only some were knocked out by that round; the remaining ghosts were played out, so it is probably right, but it reads oddly.]*

## Pause

Decisions: **resume**, **quit to start**, **quit**, **cards drop by pointer or card middle** (where a carried card lands), **sound volume / mute**. Glance: "Paused", three buttons, "Cards drop by" with two choices (one ringed), "Sound" slider and Mute, "Seed 7": **6 items**. The screen behind dims.

## Past boards

Decision: **which past fight to look at**, and **back to recruit**. Glance: "Fight from round N", both starting boards as in the fight (opponent above with portrait, name, health), "Back to recruit": **4 items**. *[I saw round 1 only; how to step to other rounds was not visible in that shot (there was one fight).]*

## Compost panel

Decision: none (read only), **close**. Glance: "Compost", "N cards", "Newest first", Close, each card with name, Attack · Health and tier as words: **5 items**.

## Card browser

Decisions: **filter** (Units/Spells, Golden, tribe, tier), **search**, **look at a card** (click for the same detail as in recruit), **back**. Glance: Back, Show (Units, Spells), Golden, Tribe list (All, Badgers, Mice, Pigeons, Locusts, Briars), Tier (All, 1–6), "Cards", count ("108 units"), search box, the cards by tier with names under each: **9 items**. This is the only place card names show under the cards.

## Discover (overlay on recruit)

Decision: **pick one of three**. Glance: "Discover a unit", three cards, each with name and text under it: **3 items**. The rest of the screen is veiled but still visible.
