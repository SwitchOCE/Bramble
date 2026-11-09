# Declutter spec (ideation, 9 Nov 2026)

Source: owner note `docs/design/owner-notes/2026-11-09e-ui-clutter-and-tutorials.md`, five area audits and two critiques of the UI on `ideation/wave1` (`/home/alex/code/Bramble-ideation-balance`). Code and screenshots were read. Godot was not run. Where reviewers disagreed, the call is marked † and its reason is in the Appendix, ready for `DECISIONS.md`.

This spec overrules one reason given for choosing the current look: "its THIS HIT panel explains a fight best" (`DECISIONS.md`, 6 Nov, "Which look to build on"). That reason came from critics scoring still screenshots, and the owner's 9 Nov direction replaces it.

---

## 1. The rule

> "The job of a tutorial is to tutorialize. Other than that, the player is assumed to know how to play the game when they're in the game environment."
>
> "We need to have fewer reminders, fewer static images that indicate where things are. Animations should, by player feel, capture how a game is and how it plays."

### Three tests for any element

1. **The hundredth game.** Would a player in their hundredth game look at this to make a decision now? If they already know it (a rule, a card's text, a slot's geometry, a fixed schedule), it leaves the game screen. It goes to the tutorial, the Rules pages or the reader.
2. **State or rule.** If it shows state that changes during play and can't be seen any other way, it stays, in its smallest wordless form: a number, an icon, a frame or a texture. If it restates a rule, a relation the board's shape already gives, or something shown elsewhere, it goes.
3. **Event or standing image.** If it describes something that happens, it becomes motion at the moment it happens. Only the resulting state is left on screen. No lines, arrows, captions or labels stay on the board.

### Standing rules that follow from the tests

- **Words** appear only on buttons that act (End turn), in the reader, in menus, in the tutorial, on the Rules pages and on game-over. Shop and board tiles carry no words at rest. Today the recruit overview has about 65 words on its tiles.
- **Every wordless mark can be read.** Tap it (hover on PC) and the reader opens. This covers plaques, counters, slot marks, tokens and marked empty pockets in fights.
- **No lines between tiles at rest**, on any screen.
- **Keyword marks (Battlegrounds' Taunt rule).** A keyword gets a resting wordless mark only if it changes who attacks whom (Mire, Quarry, Swoop), or if it is a one-use defence you must see to count damage (Shield, Shell). The same mark shows whether the keyword is printed or granted. Every other keyword shows by motion when it acts, and in the reader.
- **Names.** A name leaves a tile only once that unit has its own portrait that can be told apart at board size.
- **No first-encounter pop-ups** in a real game. Only the tutorial, the Rules pages and the reader teach.
- **Every cut ships with its replacement motion** (Section 5).
- **Reduce motion uses flashes, not words** (Section 3).

---

## 2. Per screen

Verdicts: **cut**, **shrink**, **animate** (the static form goes and motion replaces it), **move to reader**, **move to tutorial**, **keep**. Rows run from highest impact down. "Anim N" points to Section 3.

### 2.1 Unit and card tiles (shop, hand, board, combat, scout)

| Element | Verdict | Replacement |
|---|---|---|
| Trigger/ability chip ("End of Turn", "Start of Combat", "Take reward", "Ability"), `card_view.gd` `_refresh_chip` | Animate | One 44 px glyph at bottom centre, between the stat beads. Use `spark` for any trigger and `bones` for When this dies. On play gets none. It pulses when the ability fires (anim 14). Delete `RULE_TAGS`, `TAG_KEYWORDS` and the "Ability" fallback. |
| Keyword words on the chip (Quarry, Mire, Snap, Pack, Cleave, Shy, Peck 2, Bristle 2, Belly 1, "Gives Nightshade", "Ring +1/+1") | Cut † | No words. Wordless frame marks for three keywords: reeds along the tile foot (Mire), a claw notch on the frame (Quarry hunter) and a wing notch (Swoop). All other keywords show by motion (anims 2–12) and in the reader. |
| Rules text on shop unit tiles | Move to reader | Shop units use the board tile: portrait, beads and glyph. Full text on hover (PC) or tap (phone). |
| Unit name: shop tiles and board name strips | Cut per unit † | Gone on units with their own portrait. Two groups keep one short-name line at `MIN_FONT` 31 until their art lands: the 50 of 157 units still on a shared tribe portrait, and portraits reviewers confuse at board size (today Brock, Old Brock, Sable and Russet). |
| Tier knot on unit tiles | Move to reader | Shown only in the reader's knot. The freed top-left corner holds a cost knot only when the price isn't the standard 3 (poached). |
| Tribe word under shop tiles | Move to reader | The reader's type line. |
| Spell and item tiles: name, text and the word "Spell"/"Item" | Move to reader | An arched tile with art and its gold cost knot. |
| Status slips in fights (Shield, "Mired +1", Nightshade, Waiting, Warned, First Bite, Shell, Borrowed, Stalled) | Animate | One visual per status, stacking freely. Shield: a bubble. Shell: a pale rim. Nightshade: a berry on the Health bead and a purple tint. Mired: a mud rim at the tile foot. Waiting: drifting z curls. Warned: a whistle note on the Attack bead. First Bite: a fang glint on the Attack bead. Borrowed: the tile stands in the enemy tray (anim 29). Stalled: reader only. Statuses that persist into recruit (Shield) show there too. |
| Counter slip ("In 1/1", "Hex 2 (4 stored)", "3g"/"No ammo", "Bitter 3", "Kiss 1/3") | Shrink | A number-only pip in the glyph's spot (at least `MIN_FONT`, at most 64 px wide) with a small icon: belly outline, hex curl or acorn. Kisses: three pips on the face. The breakdowns go to the reader. The pip flips when the count changes. |
| Golden marks: glow, gilt face, gold knot, spark star, gilded frame | Shrink | Keep the gilded frame and the soft glow. Cut the star. The knot goes with the tier knot. |
| Frost: double rim, rime, frost face, "FROZEN kept next turn" | Shrink | Rime over the art and one frost rim. Cut the tag (anim 36). |
| Poached badge (paw + "2 gold") | Shrink | A gold cost knot "2" in the freed top-left. The reader keeps the Poached link. |
| Created marks (pine face, dashed edge) | Move to reader | The type line reads CREATED, and the Sell button shows 0. |
| "Egged" gold glow on a Bird | Move to reader | No tile mark. The reader keeps "Golden Egg used". |
| Stat beads | Keep | Optional: board beads drop from 84 to about 72 px, with numbers of at least 36 px. |
| Triple outline on a shop offer | Keep | Merge animation on buy (anim 49). |
| Selected, drop-ok and out outlines | Keep | Feedback during an action only. |
| "Not built" chip | Cut | Dev builds only. |

### 2.2 Recruit board and slots

| Element | Verdict | Replacement |
|---|---|---|
| Name strips above and below the board ("F1 Annis ×2"), `board_view.gd` `_place_label` | Cut (name rule above) | Nothing. The 100 canvas px they took go to bigger pockets (`BOARD_POCKET`/`READING_POCKET`). |
| Dotted grooves between rows (the "diagonals"), lit gold when both ends hold units, `_draw_grooves` | Cut | No lines, in any phase. Effects that use a relation show as motes when they fire (anim 40). |
| Permanent "Pass end" banner and arrow, `slot_marks.gd` | Cut | The Pass seed at End of Turn (anim 41). This also removes the confirmed bug where the mark shows with no Pass unit on the board. |
| "Pass lands" preview while selecting or dragging, plus the hover line "Pass order: F1-B1-…" | Cut † | Nothing. The recipient is your rightmost other unit, which the board already shows. |
| Relation highlight (gilt slots on select, during drag, after placing) and the reader line "Highlighted: B1 and B2." | Animate † | A single reach pulse when the unit's reader opens, replayed when you tap a spatial word in it (anim 42). While dragging over a candidate pocket, the drag lean plays (anim 43). Nothing at rest or after the drop. Cut the "Highlighted" line. |
| Slot-code chips F1–B3 on tiles and marked empty slots | Cut | Codes stay only on the Rules brick-wall diagram and the log page. |
| Empty-pocket text ("F3 / before B2 & B3", "B2 EMPTY") | Move to tutorial | A bare carved pocket with its dashed edge. |
| Row tags FRONT / BACK / SHOP | Cut | The board and hero move left into the gutter. |
| Ring badge ("×2", "+3/+3 · 2", "+4/+4") | Shrink | Your own board only: one digit on a toadstool at the ring's top-left, shown from 2 Rings up. A single Ring shows just the dots. The stats are already in the beads, and the reader has the note. |
| Fairy-ring dots (26 dots, 8 px) | Shrink | Dots of about 5 px with a thin ink rim, so the ring reads as a frame (anim 44). |
| Empty Nest: Egg art, 64 px beads, "Egg · home in 2" | Shrink † | Egg-in-nest art fills the pocket like a tile, with beads at normal tile size. No label and no countdown on the board. The countdown lives on the away token. |
| "On Nest 1" banner under a unit | Shrink † | A thin twig rim inside the pocket edge, with no words and no digit. The reader says "Stands on Mrs Jay's Nest." |
| "Board 7/7" chip | Cut | A refused play onto a full board shakes the board tray (anim 57). |
| Legal-target highlight during drag, aim or tap-to-move | Keep | It breathes (alpha 0.6 to 1, 0.8 s loop) so it reads as "here". |
| Rainbow band, Horseshoe icon | Keep | Paint wipe (anim 45). |
| Carved pocket and oak tray | Keep | This is the horse on the chessboard. |

### 2.3 Recruit HUD (economy column, hand, away Birds, counters, hero, toasts)

| Element | Verdict | Replacement |
|---|---|---|
| "Birds away" paper panel ("Now → landing", "7/8 → 14/16 · F3"), `away_tray.gd` | Animate | A row of round Bird tokens under the hand (104 canvas px, 122 on phone). Each has its portrait and a moon badge with the turns left. A Bird waiting on the doorstep sits on the tray rim with a closed-door mark. Tap a token for the reader (stats now and at homecoming); its Nest pulses. Anims 46–48. The hand keeps its normal size. |
| Hand shows 6 cards (4 while Birds are away) behind "+N more" | Cut † | Every card shows, up to 10, overlapping as a fan when they don't fit. |
| Tier up / Refresh / Freeze leaves with words, 442×128 | Shrink | Icon plus cost pill, no words. Leaves are 122 px tall and the column narrows from 442 to about 300. While frozen, the snowflake leaf stays pressed in with a frost fill. Long-press or hover shows the word. |
| End turn sub-line ("0 + starting survivors", "then fight Old Tansy", "Toll 3, cap 5") | Cut | The formula lives in the tutorial and on Rules. The round base is in your own plaque's reader. |
| End turn leaf, 189 px | Shrink | About 140 px tall, and it keeps its word. It curls away as the fight starts. |
| Gold plaque's acorn pile and the word "GOLD" | Cut | The big acorn and the number only (about 260×100). Buys and sells fly acorns (anims 33–34). |
| Gold number | Keep | It stays visible while the reader is open on phone. Today it hides (`recruit_layout.gd:330-335`). |
| "Next +5" income line | Shrink | Hidden while income matches the schedule. When gold is queued or debt is being repaid, a ghost-acorn badge shows only the difference ("+2" or "−1") (anim 53). |
| "Tier 4" label row | Shrink | A digit inside the Tier up leaf's stack icon (anim 37). |
| "Turn 2" label row | Shrink | A small "Turn 8" at `MIN_FONT` inside the gold plaque. |
| Hand title "Hand" | Cut | Nothing. |
| Hand count "1/10" | Shrink | Shown only at 10/10, in red on the tray corner. |
| Empty-hand hint "Bought units wait here…" | Move to tutorial | An empty tray. The buy flight (anim 33) teaches it. |
| Ring size chip "Ring size 1.25" | Shrink † | A ring icon with "×1.25" in a counter column beside the hero portrait. Tap it for the reader. |
| "Midsummer N" chip | Shrink | A sun icon with a digit, in the same column. |
| "Tribe bonus" caption and chips | Shrink | Cut the caption. Tribe portrait plus number chips go into the counter column (anim 54). |
| Scout token and its Close state | Cut | Tap the Next portrait in the lobby (2.5). |
| Who? token | Cut | The opponent's portrait chip on the scout tray. |
| Hero plaque name | Cut | The portrait fills the plaque. Tap it for the hero card. |
| Hero portrait | Keep | Add a small grey shield with the armor number when armor is above 0 (anim 56). |
| Hero power leaf "Power" | Shrink | A round icon button with a cost badge, greyed when spent or unaffordable. Limited uses show as rim pips (anim 55). |
| Ask for Kin leaf | Shrink | An icon with a "2" cost pill, greyed after use. Long-press shows its name. |
| Shy confirm (second press after a warning toast) | Cut † | One press. When an aimed spell thanks a Shy unit, it bows and walks off (anim 52). No looping fidget. |
| Top toasts (Triple!, Triple Reward, Stash, Poached, kiss, walked out, New Nest, Pipkin, ghost-next, rejections) | Animate | Each becomes its motion (anims 49–52, 57–59, 60). Text stays only for rare cases motion can't show ("Discover found no eligible cards"). |
| Gear token | Keep | The left margin narrows. |

### 2.4 Card reader

| Element | Verdict | Replacement |
|---|---|---|
| Reader core: art, name, type line, knot, stats, rules with keyword links, reminder slip, actions, state lines | Keep | Grows to take what tiles drop: name, tier, tribe, Created, counter breakdowns, slot note, and in fights quarry, Mire binding, Hex, held count, kisses and skip reason. |
| On PC the recruit reader replaces the hand panel | Shrink | It floats beside the hovered card, like Battlegrounds' hover card, and the hand stays in view. |
| Keyword reminders that use slot codes (`keyword_rules.gd` Behind, Touching; the Pass keyword) | Reword † | Behind: "Each back slot is behind the two front slots it sits between." Touching: "An unbroken chain of units, left to right through both rows. An empty slot breaks it." Pass: "Pass X: your rightmost unit, other than this, gains X." |
| Action hints ("Tap an empty slot to play it", "Tap where to use it", "Or tap an Ooze…") | Move to tutorial | The breathing target glow shows where. A no-target reason ("Every Ring is full") becomes the label on a disabled Play button, and the tapped card shakes. |
| "Highlighted: F1 and F2." | Cut | The reach pulse (anim 42). |
| Sale and buy notes ("Sell value: N gold.", "Fly south: 0 sale gold.", "Poached. Costs N gold…") | Shrink | The buttons carry the numbers: "Sell 0", and "Fly south" with a turn count when it isn't 2. One line only when it applies: "Its wait restarts." |
| Separate Golden / Created / Details links, and "No special rules." | Shrink | GOLDEN and CREATED join the type line as links ("GOLDEN · BIRDS"). Keep Details. Cut "No special rules." |
| Worked examples and "Offered from tier 3." inline | Move to reader (Details slip) | Opened from the Details link. |
| Slot note "F1: Ring +3/+3 · 2, Rainbow band." | Keep, reworded | "This slot: 2 Rings (+3/+3), painted." No codes. |
| Ring size where Ring cards are read | Keep | "Your Ring size: +1.25/+1.25." on Ring spells, Fairies and ringed slots. |
| Discover and choice picker with full text | Keep | A modal choice, as in Battlegrounds. |

### 2.5 Lobby and scouting

| Element | Verdict | Replacement |
|---|---|---|
| Two-line hero names on plaques, and the "Rival N ·" prefix | Shrink | A round hero portrait (about 96 canvas px) with the tier knot on its lower-left and the Health rosehip on its lower-right. Tap it for the hero card. Real lobbies deal heroes without repeats (9 heroes, 8 seats) †. |
| Seat order | Change † | Sorted by standing. Re-sorted after each fight with a 0.3 s slide. |
| Top strip position | Move † (batch 3, conditional) | A vertical portrait column down the left edge, like Battlegrounds' leaderboard. It goes in only if 8 portraits at about 96 canvas px, with numbers at least `MIN_FONT`, fit at 1688x780. Otherwise the strip stays. |
| "You" plaque | Shrink | A moss-rimmed portrait with Health. No word and no tier knot (the tier is on the Tier up leaf). |
| Health rosehips | Keep | Count-down on change (anim 61). |
| Tier knot on opponents | Keep | Smaller, overlapping the portrait. It flips on tier up (anim 62). |
| "Next:" word | Shrink | Keep the red rim and darker fill, without the word. The rim draws itself at turn start (anim 60). |
| "Last Stand: ready/used" tags | Animate | A 2 px gold ring round the rosehip while the save is unused. It snaps off when used, and a crack mark stays (anims 31, 64). |
| Out plaques at full size with struck name, knot and "0" | Shrink | A half-size grey portrait chip at the end of the list, with no numbers (anim 63). |
| Ghost plaque: "Ghost of X", NEXT tag | Shrink | A grey chip with the red Next rim and a slow see-through shimmer (alpha 0.6 to 0.9, 2 s). Tap it for the ghost card (`RecruitView.ghost_card`). |
| Toast "Next fight: a ghost. Scout it to see." | Cut | The rim animation on the ghost chip. |
| Scout lane forecast: hunter lines, reed links, paws, "F2 MIRE" patches, pack bracket (`lane_overlay.gd` in scout) | Cut † | No lines, no patches. Their tiles' frame marks (Mire, Quarry, Swoop) carry the read. Tapping one of their units pulses the slots on your board it will reach, including a lent quarry that isn't straight across (anim 42). |
| Scout title "Rival 4 · Brother Bracken's last fight" | Shrink | The opponent's portrait chip at the scout tray's corner. Tap it for their hero card. |
| Scout empty text on turn 1 | Cut | On turn 1 the Next portrait can't be tapped. |
| Scout slot captions F1–B3 and "B2 EMPTY" | Cut | Bare pockets. |
| Counters on their tiles ("2 gold", Belly) | Keep | The same pip component as your own board ("2" with an acorn). |
| Their Ring and Nest marks | Keep | Floor visuals only, with no count digit and no text. |

### 2.6 Combat

| Element | Verdict | Replacement |
|---|---|---|
| THIS HIT panel (`hit_panel.gd`) | Cut | The full lunge, a damage pop on the Health bead and the bead rolling (anims 1, 7). The freed left column holds the two hero plaques. |
| Attack yarn (`attack_yarn.gd`) | Animate | The full lunge (anim 1). No yarn under reduce motion either †. |
| Quarry links, paws and the "Marked" chip | Animate | A paw stamp at Start of Combat (anim 18). A 30 px paw stays on the quarry. The hunter carries its claw notch. |
| Combat log note (`log_note.gd`) | Move to reader | Off the fight screen. It opens as a full-height page from Log in the pause menu, and from "Last fight" in your own plaque's reader. Names only; a slot code appears only to tell two same-named units apart, with a small labelled brick at the top of the page. Keep `CombatLog` and `LogNote.all_text` for tests. |
| Keyword box with automatic reminders ("QUARRY: The enemy across…") | Cut | Keyword rules live in the reader only. |
| The same box as the unit reader, with "Tap a unit to read it." | Move to reader | PC: hover shows a floating reader beside the unit and playback continues. Phone: a tap opens the reader and pauses; tapping anywhere closes it and resumes. Tapping a marked empty pocket shows its slot note. |
| ATTACKING and TARGET slips | Cut | The lunge. |
| Mire reed links, mud labelled "MIRE", "Mire" and "Mire: waits" chips | Animate | A mud splash (anim 19). A mud strip stays under the pocket, with no word, no reeds and no line. |
| Trigger flash plus floating trigger name | Animate | Glyph pulse, hop and motes (anim 14). |
| Slot-code chips F1–B3 | Cut | Nothing. |
| Empty-pocket words "B3 EMPTY" | Cut | A dark recess with a dashed edge. |
| Grooves in combat | Cut | Nothing. |
| Damage burst: 150 px star at the card's right edge, covering the neighbour | Shrink | A star of about 96 px centred on the struck unit's Health bead. The number is at least 52 px, and the star grows in steps with the damage (anim 7). A blocked hit shows no number (anim 8). |
| Opponent header ("FIGHTING", name, rosehip) and rotated side tags ("BROTHER BRACKEN" / "YOU") | Shrink | Two hero plaques of about 140 px, a portrait and rosehip each, with no words. The opponent's sits beside the enemy tray, yours beside yours. |
| Result panel (Victory/Defeat, "X dealt N damage to you", cap/toll notes, Watch again, Continue) | Cut † | The damage lands on the plaques (anim 31), then the game returns to recruit about 1 s later, or sooner on a tap. Watch again and Log move to the pause menu and your plaque's reader. |
| Stat change chips ("+1/+1", "-2 Attack") | Animate | The bead pops and rolls (anim 15). No "+X" text †. |
| Status chips ("Shield", "Nightshade", "Warned") | Animate | The status's own visual scales in (anim 16). |
| Event words (Pounce!, Counter!, Gulp!, Pinched!, Whistle!, Cancelled, "Skips: reason", Hex!, A prince!) | Animate | Anims 3, 20, 22–26, 30. |
| Arrival words (Summoned, Out!, Home!, Split!) | Animate | Each unit enters from its source (anim 29). |
| Phase caption ("Start of Combat", "Attacks") | Animate | The bell (anim 17). It is a picture and a sound, never a word (wording guide: write Start of Combat). Nothing marks the start of attacks; the first lunge does. |
| "X can't attack: pass", "Mousewife: no room for a Mouse" | Animate | Anims 27–28. |
| Kiss chip "Kiss 2/3" | Animate | Three pips on the face (anim 30). |
| Hex slip "Hex −4" | Shrink † | A purple sigil (about 36 px) in the pocket corner with "−4" at `MIN_FONT`. |
| Slot trap ("Marked: 3" and a red pocket) | Shrink | A small red stake glyph in the pocket corner with its damage number (anim 21). |
| Held attacker, defender and joiner outlines | Cut | Short flashes (0.25 s or less) appear only inside animations. |
| "ATTACK n" counter | Cut | Nothing. |
| "Takes N back: M left" | Cut | A counter pop on the attacker, and thorns for Bristle (anim 10). |
| Nightshade "½: 26 to 13" chip | Animate | Anim 9. |
| Waiting text "Start of Combat first. The first attack will appear here." | Move to tutorial | The bell. |
| Combat tile chip "Ring +1/+1", and the reminder line "Ring: Whoever stands on this slot…" | Cut | Ring dots on the pocket. The reader holds the rest. |
| Speed plaque ("SPEED", ×1 ×2 ×4) | Shrink | One token showing the current speed. Each tap cycles ×1, ×2, ×4 and saves to `Settings.fight_speed`. |
| Pause | Keep | In one control row at the bottom right, with speed and Skip, each at least the tap minimum (90 canvas px narrow, 122 wide). |
| Step | Shrink | Hidden while playing. While paused, it takes the speed token's place. |
| Skip leaf "Skip / to the result" | Shrink | A token at the tap minimum with a double-chevron glyph. |
| Hit shake, death fall and leaf puff | Keep | Plus the timing rule in anim 13. |

### 2.7 Menus, how-to-play, settings, game-over

| Element | Verdict | Replacement |
|---|---|---|
| First New game opens the 14-page guide | Move to tutorial | Ask once: "Play the tutorial" (the default) or "Skip". |
| Linear guide ("Page N of 14", Skip/Back/Next, a strategy-tips page) | Shrink | A Rules reference organised by topic (Section 4). Tips become tutorial coach lines. |
| Static demos ("CAN BE HIT" / "SAFE FOR NOW", numbered order chips, "Last fight, they stood here", worded leaves) | Animate | Looping demos built from the in-game animations, drawn in the new look. |
| Card exceptions on guide page 12 (Moss Ooze, Mother Goose's Egg, Birds can't fly on landing) | Move to reader | Into those cards' text and Details. |
| Rules term links (Round base, Starting survivor, Last Blow, Last Stand) | Keep | Add Ghost, Last Four, Early Spoils, Nest/Egg and Across. |
| Main menu title and portraits | Keep | Not game space. |
| "Your records" panel | Shrink | One line under the portraits, hidden until the first game ends. |
| Menu leaves | Keep | How to play opens a hub: Tutorial and Rules. Quit is hidden on phone. |
| Settings "Changes save as you make them." | Cut | Nothing. |
| Settings decorative portrait tray | Cut | A "Replay tutorial" leaf, and Opponents if that ships. |
| Reduce motion subtitle "no lunges, shakes or leaves" | Keep, reworded | "Flashes instead of lunges and shakes." |
| Ask for Kin latch | Keep | Under an "Experiments" heading. |
| Game-over placement, hero line, "New best!" | Keep | Animated arrival (anim 66). |
| Game-over final board with slot captions | Shrink | No captions. |
| "How it went" tokens and moment lines | Keep | Tokens fill in (anim 66). |
| Final standings: a "0" rosehip on every out player, and the "Knocked you out" tag | Shrink | Hero portraits. Health only for the winner. The moment line keeps who knocked you out. |

---

## 3. Animations

### Time budget and fallbacks

- **Recruit input never waits on an animation.** Actions queue, as in Battlegrounds.
- **Speed.** The speed setting and tap-to-skip cover recruit animations as well as fights.
- **Single cues** (the bell, a Pass seed, an Egg crack) stay under 0.4 s.
- **Sequences.** The End of Turn and Start of Turn sequences each stay under 1.5 s at ×1. Sources start in reading order (F1, F2, F3, F4, B1, B2, B3), 0.12 s apart and overlapping. The stagger compresses to fit.
- **Lunge floor at ×2 and ×4.** Holds and gaps between events shrink first. Lunge travel never drops below 0.10 s, and the hit-stop never below 0.04 s. `set_speed` scales every tween today, so without this floor travel at ×4 would last about 2 frames. Tutorial fights are locked at ×1.
- **Reduce motion.** Travel becomes a 150 ms brightness flash on the source, then on the target. Damage numbers still pop, deaths fade, and end-state marks (paw, mud, sigil, pips) appear in place. No yarn and no toasts.
- **Sound.** Keep the existing fight sounds (`combat_sounds.gd`). Add sounds for buy, sell, refresh, freeze, triple, fly south and coins.

### Fights

| # | Trigger | What moves | ×1 | Replaces |
|---|---|---|---|---|
| 1 | Each attack | **Lift** 0.10 s: z-index to the top, scale 1.0 to 1.1, shadow 6 to 18 px. **Travel** 0.16 s ease-in, straight, until the attacker overlaps the target by about 15% of tile height. A back-row attacker leaps over its own front row. **Contact**: 0.05 s hit-stop, both tiles shake, both damage pops play, and the hit sound is sized by damage. **Return** 0.20 s ease-out. | ~0.5 s | Attack yarn, ATTACKING/TARGET slips, held outlines, THIS HIT's attacker and target |
| 2 | Pack joins | Joiners lift 0.04 s after the leader and land 0.03 s apart. Only the leader takes a counter-damage pop. | +0.1 s | Pack bracket, "Pack!" |
| 3 | Pounce, Counter | No lift: a 0.12 s snap travel with its own sound. | 0.3 s | "Pounce!", "Counter!" |
| 4 | Cleave hit | The lunge ends in a sideways sweep. Units beside the target shake and pop together with it. | +0.1 s | "Cleave" chip |
| 5 | Peck N | N jabs of 0.12 s each, with one pop per jab. | N×0.12 s | "Peck N" chip |
| 6 | Quarry, Snap or Swoop attacker | The lunge goes straight to its real target, diagonally if needed. | (in 1) | Hunter lines |
| 7 | Damage | A −N star on the Health bead scales 0.4 to 1.15 to 1.0 in 0.12 s, holds 0.25 s, then drifts up 16 px and fades over 0.15 s. The bead rolls to its new value and flashes red for 0.15 s. | 0.52 s | THIS HIT before/hit/after |
| 8 | Shield blocks a hit | The bubble shatters into shards. No number. | 0.25 s | "Shield" chip |
| 9 | Nightshade on contact | A berry drops onto the Health bead (0.15 s). The bead flashes purple and rolls to half (0.25 s), then the normal pop plays. The source's mark pulses. | 0.4 s | "½" panel step and chip |
| 10 | Bristle | Three thorns jut toward the attacker before its pop. | 0.12 s | "Takes N back" |
| 11 | Hunker, Damage Reduction | Hunker: the defender crouches (scale-y 0.9) at contact. Damage Reduction: a grey dent flash. Both play before the smaller number pops. | 0.1 s | The cause THIS HIT used to show |
| 12 | Bitter | The attacker's Attack bead tints and rolls down before contact. | 0.2 s | "Bitter" text |
| 13 | A unit reaches 0 Health | Hold 0.15 s after the visible cause, then tilt, fall 44 px, fade and puff leaves. Units that die in the same event fall together. A When-this-dies unit's bones glyph pulses as it falls, and its effect launches from where it fell. | 0.15 s + fall | "dies" in THIS HIT |
| 14 | Any trigger fires (fights and recruit) | The glyph scales 1 to 1.5 to 1 with an acorn glow, and the tile hops 10 px. The keyword sound plays. One mote in the tribe colour flies to each affected unit on a shallow arc, 0.05 s apart, and the change plays on arrival. A whole-board effect sends one ripple instead. | 0.25 s + 0.22 s | Trigger chips, floating trigger names |
| 15 | Stats change | The bead scales 1 to 1.35 to 1, tints green (gain) or red (loss), and its number rolls. A permanent gain adds a gold glint. | 0.2 s | "+1/+1" chips |
| 16 | Status gained | Its visual scales 0.3 to 1 with a flash in the status colour. | 0.25 s | Status chips |
| 17 | Start of Combat | A 64 px bell in the gap between trays swings twice (±20°) with the bell sound and fades. Then Start of Combat sources fire one at a time in reading order. | 0.35 s | Phase caption, "Start of Combat first" text |
| 18 | Quarry set (Start of Combat or a lent quarry) | The hunter crouches (0.1 s). Three paw prints stamp from it to its quarry, and the last stays as a 30 px paw at the quarry's top-right. It fades (0.2 s) when the quarry is lost. | 0.4 s | Quarry lines, paws, "Marked" |
| 19 | Mire at Start of Combat | Mud splashes straight across to the enemy pocket (0.3 s) and spreads into a strip (0.15 s). When the maker's attack comes and it waits, it lifts and sinks back as a bog bubble pops. A broken patch fades (0.2 s). | 0.45 s; wait 0.3 s | Reed lines, "MIRE", "Mire: waits" |
| 20 | Hex applied | A purple sigil drifts from the hexer to the slot across and settles in the corner with −N. The occupant's Attack bead rolls down. | 0.35 s | "Hex!", Hex slip words |
| 21 | Trap set, then a unit enters | The stake appears. On entry it springs up and the damage pop plays. | 0.3 s | "Marked: 3", red pocket |
| 22 | Gulp | The swallowed tile shrinks into the swallower (0.25 s). The swallower bulges 1.15 to 1 (0.15 s) and its held pip ticks up. | 0.4 s | "Gulp!" |
| 23 | Pinched (ability taken) | The glyph peels off the victim and flies to the taker. | 0.3 s | "Pinched!" |
| 24 | Whistle | A ring expands from the whistler, and a whistle note lands on the warned enemy's Attack bead. | 0.35 s | "Whistle!", "Warned" chip |
| 25 | Effect cancelled | The mote reaches its target and fizzles into grey smoke. | 0.2 s | "Cancelled" |
| 26 | A unit skips (Mired, Stalled, Bide) | It lifts 6 px and sinks back with a small head-shake (±0.05 rad). The blocking status flashes; Bide adds z curls. | 0.25 s | "Skips: reason" |
| 27 | A side can't attack | Its tray dips 6 px and settles with a dull knock. | 0.25 s | "X can't attack: pass" |
| 28 | A summon has no room | A 40% Mouse pops out, bumps the tray edge and bursts into a grey puff. | 0.3 s | "no room for a Mouse" |
| 29 | Arrivals | A death summon grows where its source fell. Out slides from the holder. Home drops in from the tray edge. Split slides sideways out of its parent. Borrowed slides into the enemy tray and back after its attack. Each ends with a 0.2 s moss outline flash. | 0.3–0.35 s | "Summoned", "Out!", "Home!", "Split!", Borrowed slip |
| 30 | Kiss, transform | A heart flies from the dying Mired enemy to the unit and a pip fills. At 3 kisses the tile flips edge-on and back as the prince. | 0.3 s; 0.4 s | "Kiss 2/3", "A prince!" |
| 31 | Fight ends | Pause 0.3 s. All the winner's starting survivors flick sparks at once, and the round base flies from the winner's plaque. One thump lands on the loser's plaque: a −N pop, the rosehip rolls down and the plaque shakes. **Last Blow**: the base spark rises from where the deciding unit fell. **Last Stand**: the rosehip stops at 1 and the gold ring snaps. **Tie**: both plaques bump and nothing lands. **Spoils**: a coin pops onto your plaque. Then the game returns to recruit about 1 s later. | ≤0.6 s + 1 s | Result panel, Victory/Defeat, "X dealt N damage", Continue |
| 32 | A quarry falls (Take, Poach) | A coin flies from it to the hunter side's plaque, with the coin sound. | 0.35 s | "Take!", "Poach claim" |

### Recruit

| # | Trigger | What moves | ×1 | Replaces |
|---|---|---|---|---|
| 33 | Buy | The card lifts off the shelf and flies into the hand. One acorn per gold flies from the plaque to the card as the number ticks down. | 0.35 s | Hand hint, "Hand" title, acorn pile |
| 34 | Sell | Acorns fly from the sold card into the plaque. A card selling for 0 sends none. | 0.3 s | "Sell value" note |
| 35 | Refresh, Ask for Kin | Shelf cards flip away left to right and new ones flip in. Ask for Kin offers that share your tribes glint in the tribe colour. | 0.35 s | Leaf words |
| 36 | Freeze, unfreeze | Rime creeps over each offer, left to right, 0.25 s each and staggered 0.05 s. On unfreeze it cracks and falls away. | ~0.45 s | "FROZEN kept next turn" |
| 37 | Tier up | The digit in the leaf's stack flips up and the stack gains a step, while the new shop deals in. | 0.4 s | "Tier 4" row |
| 38 | On play, After you cast | Anim 14 fires right after the action. | 0.5 s | Trigger chips |
| 39 | End turn pressed | End of Turn sources fire in reading order (anim 14), Pass seeds last. A tap skips. Then the End turn leaf curls away and the fight opens. | ≤1.5 s | "End of Turn" chips; effects that happen unseen today |
| 40 | An effect using behind, beside, next to or touching fires | A mote goes from the source to each affected tile (0.25 s ease-out). Touching hops tile to tile, left to right, 0.06 s per hop, and stops at a gap. Beads pop on arrival. | ≤0.4 s | Grooves and lit grooves |
| 41 | A Pass resolves | A glowing seed hops pocket to pocket, left to right, skipping empty pockets, 0.05 s per hop. It lands on the recipient with a bead pop. A combat Pass flies straight (0.3 s). With no one to pass to, it fizzles at the source. | ≤0.4 s | "Pass end" banner, preview arrow, zigzag line |
| 42 | A unit's reader opens, or you tap a spatial word in it | The slots its text reaches glow and fade once. When scouting, this includes the enemy slots it will reach, such as a lent quarry. | 0.4 s | Relation highlight, "Highlighted" line, scout lane forecast |
| 43 | Dragging a unit with spatial text over a candidate pocket | The units it would reach lean 6 px toward that pocket and back. It replays when the pocket changes. | 0.15 s | Relation highlight during drag |
| 44 | Ring added, moved or grown | **Added**: toadstools sprout clockwise round the pocket and the count digit ticks up. **Moved** (Reel-Mistress): the dots hop pocket to pocket to the new slot. **Ring size grows**: the counter pulses and every Ring shimmers. **Midsummer reaches 0**: a sun arc sweeps across the board and the Rings flare. | 0.3 s; ≤0.4 s; 0.4 s; 0.6 s | Ring badge stats, "Ring size" words |
| 45 | A unit paints its slot | The colour wipes across the band. | 0.3 s | Nothing new |
| 46 | Fly South | The card lifts, shrinks into its token and arcs into the away row with a wing-flap sound. An Egg drops into the Nest with a bounce. | 0.5 s + 0.25 s | Birds away panel text |
| 47 | Start of Turn, Birds away | Each moon digit flips down one, staggered 0.08 s. | 0.2 s | "home in 2 turns" |
| 48 | Homecoming | The token swoops into the hand and unfolds into its card, while Attack and Health count up to the doubled values. Its Egg cracks and vanishes. With a full hand the token hops onto the tray rim (doorstep), then into the hand when there's room (0.3 s). | 0.6 s; Egg 0.3 s | "Now → landing", "7/8 → 14/16 · F3", "Egg · home in 2", "On Nest" |
| 49 | Triple, Triple Reward | The copies fly together and merge in a gilt flash. The golden card drops into the hand and shimmers slowly until played. A picked reward flies from the picker into the hand (0.35 s). | 0.6 s | "Triple!" toasts |
| 50 | Three Acorns combine | They slide together and pop into a Stash. | 0.4 s | "Three Acorns made a Stash." |
| 51 | Poached offer | The card flies from that rival's portrait into your shop. | 0.5 s | "Poached X…" toast |
| 52 | Shy thanked by an aimed spell | It bows (0.15 s) and slides off the board edge (0.4 s). Its 2 (or 4) acorns drop into the next-turn badge. | 0.55 s | Shy confirm, walk-out toast |
| 53 | Gold queued or debt repaid | Acorns drop into the ghost-acorn badge. At Start of Turn the badge pours into the number. | 0.3 s | "Next +5" line |
| 54 | Tribe bonus grows | A spark leaps from the chip to each unit of that tribe. | 0.4 s | "Tribe bonus" caption |
| 55 | Hero power used | The button flips to its back. Limited-use pips empty. | 0.3 s | "Power" word, "Pipkin's buys are used" |
| 56 | Armor absorbs damage | The shield chips and its number ticks down. | 0.3 s | Armor only in tap text |
| 57 | Action refused | Whatever is short shakes (gold plaque, hand rim or board tray) with a dull click. | 0.25 s | Rejection toasts, "Board 7/7" |
| 58 | Kiss in recruit | A heart pops off the frog and a pip fills. | 0.3 s | "A frog gets a kiss (2/3)" |
| 59 | Nest replaced | The old Egg rolls off and the new Nest drops in. The old Bird's token stays in the away row. | 0.4 s | "New Nest replaces…" toast |

### Lobby and menus

| # | Trigger | What moves | ×1 | Replaces |
|---|---|---|---|---|
| 60 | Recruit turn opens | The red rim draws itself round the next opponent with a soft drum, and the portrait nudges 4 px. | 0.4 s | "Next:", "then fight X", ghost toast |
| 61 | Back from a fight | Each rosehip that fell shakes and counts down, with a −N pop. Then the plaques re-sort by standing with a slide. | 0.6 s + 0.3 s | Seat-order reading of Health |
| 62 | A rival tiers up | Its knot flips with a gold glint. | 0.3 s | Nothing new |
| 63 | Elimination | The rosehip hits 0, the portrait greys, a crack runs across, and it shrinks and slides to the end. | 0.4 s + 0.3 s | Full-size out plaque |
| 64 | Last Four reached | A gold ring draws round each remaining rosehip, with a bell note. | 0.5 s | "Last Stand: ready" |
| 65 | Scout open/close (tap the Next portrait) | The scout tray drops from the portrait into the shop's place, and folds back up on close. The portrait looks pressed in while open. | 0.25 s | Scout/Close and Who? tokens |
| 66 | Game over | The placement carves in (scale 1.3 to 1), then "New best!" stamps on. The round tokens fill in left to right, 40 ms each. | 0.3 s + tokens | Nothing new |

---

## 4. The tutorial and how-to-play

### Tutorial: one scripted game, 4 rounds, about 5 minutes

- **Setup.** You plus 3 rivals with fixed boards each round (built like `content/scenarios`), fixed shops, and fights locked at ×1.
- **Coach.** A coach slip sits outside the board. An animated finger shows each new action once, and only that control works.
- **Access.** It can be skipped at any time. It replaces the guide on the first New game, and can be replayed from the menu hub, Settings and the pause menu.
- **Containment.** The coach exists only in the tutorial.

| Step | Round | The player does | It makes safe the cut of |
|---|---|---|---|
| 1 | 1 | Taps a shop unit (hover on PC) to open the reader, then taps its underlined keyword for the reminder. Coach: "Tap any card, here or in a fight, to read it." | Rules text, names, tier and tribe on tiles; keyword chips; the fight's keyword box |
| 2 | 1 | Buys a unit and drags it (or taps a lit slot) into the front row, while acorns fly off the gold. | Hand title and hint, "Board 7/7", the acorn pile, action hints |
| 3 | 1 | Ends the turn. In the fight, which you win: the bell rings and the coach says "Start of Combat first". Your glyph pulses and its mote flies. Then the lunges, damage pops and a death. Coach: "Then the sides take turns: front row left to right, then the back row." | THIS HIT, yarn, slips, phase captions, the "Start of Combat first" text |
| 4 | 2 | Sells, refreshes (icon leaf; hold it to see its word), buys two and puts one in the back row. Coach: "The back row is safe until the front row falls." | Row tags, leaf words, empty-slot notes |
| 5 | 2 | Opens a unit with "beside" text, and the slots it reaches pulse. Places it. At End of Turn its spark jumps to its neighbours. | Grooves, relation highlight, slot codes |
| 6 | 2 | In the fight, which you lose (the rival has the bigger band and goes first), taps a unit. Play pauses and the reader opens; a tap resumes. | The combat log and keyword box |
| 7 | 2 | Watches the damage, with sparks staggered this one time: one spark per enemy starting survivor, and a summoned survivor sends none. Coach: "You lose the round's base plus 1 for each of their units that started and survived. The base is 0 now and rises each round." | End turn formula, result panel, damage text |
| 8 | 3 | The red rim marks who you fight next. Taps it to see their last board, taps their portrait to read their hero, and taps the rim again to close. | "Next:", Scout/Close, Who?, scout title, "then fight X" |
| 9 | 3 | Tiers up (the cost is lower than last turn), then freezes. | "Tier 4" row, frozen tag |
| 10 | 3 | Skips the fight with the double-chevron. | "Skip / to the result" |
| 11 | 4 | A third copy is offered. Buys it; the three merge into a golden card in hand. Plays it and Discovers. | Triple toasts, spark star |
| 12 | 4 | Uses the hero power, and plays a bought spell onto a unit. | The "Power" word, spell tile text |
| End | | Coach: "The rest is on any card you tap, and in How to play." | |

**Left to the Rules pages and the reader, not the tutorial:** ghosts, eliminations, Last Four, Last Stand, Last Blow, Pass and Touching, Rings, Nests, Belly, Hex, Shy, Mire, Quarry, statuses, counters, tribe and Ring-size counters, the income badge, the hand limit and armor. Each has a tappable mark whose reader states the rule.

### Rules reference (replaces the 14-page guide)

A hub of topic tabs. Each topic has one short paragraph and one looping demo built from the in-game animations, in the new look (icon-only leaves, no slot codes except page 3's diagram). Read in order, they teach:

1. **Reading cards.** Tap any card, mark, plaque or token to read it. In a fight, a tap pauses. (Today this is on page 12 of 14. It moves to page 1.)
2. **Recruit.** Gold and the income table, buy, sell, refresh, freeze, tier up and its falling cost, triples and Discover, spells, hero power, and the hand limit of 10.
3. **Board.** The brick wall, the only labelled diagram. The front row takes the hits. Behind, beside, next to and touching, worded without codes. Across means the same column. Then Rings, Nests and Eggs, and the Rainbow band.
4. **Fights.** Start of Combat first (shown with the bell), then front row left to right and then the back row, sides alternating, the bigger band first. Demo: lunges and deaths, with the back unit untouched until the front falls. Then Last Blow.
5. **Damage and Health.** Round base plus 1 per enemy starting survivor, the base schedule as a table, ties, armor and Early Spoils.
6. **Lobby, ghosts and the last four (new page).** The standings order, the Next rim, scouting a last board, the ghost chip (their last board, with no Health), Last Four, and Last Stand (gold ring unused, crack used).
7. **Tribes.** The counter column (tribe bonus, Ring size, Midsummer) and the Birds away tokens.
8. **Keywords A–Z.** Each keyword with its mark or its motion: the Mire reeds, Quarry claw and paw, Swoop notch, Shield bubble, Shell rim, Nightshade berry, Pass seed, Cleave sweep, Pack join, and so on.

**Edits to `how_to_play.gd`:**
- Reword every slot code as in 2.4.
- Add "Start of Combat effects go first, then attacks" to "Who attacks when".
- Change "Tap Scout" to "Tap your next opponent".
- Move card exceptions to their cards.
- Turn every static tag and numbered chip into an animation.

---

## 5. Build order

Each batch ships on its own and passes the runtime gate. That means tests updated for the strings it removes. The tests that pin current text: `tests/ui/test_polish.gd`, `test_engines.gd`, `test_full_game.gd`, `test_look.gd`, `test_milestone_b.gd`, `test_cards.gd`, `layout_check.gd`, `shots/playthrough.gd` and `tests/core/test_full_games.gd`.

Each batch logs its calls in `DECISIONS.md` and saves evidence in `docs/ideation/evidence/declutter/batchN/`. Every "after" screenshot uses the same scripted scenario and seed as its "before". Where a "before" exists at only one size, shoot it from `ideation/wave1` at the other size first.

### Batch 1: fights read by motion (highest impact)

**Scope:**
- Everything in 2.6.
- Fight animations 1–32.
- Combat tiles switch to the new face: glyph, keyword frame marks, status visuals, pips. No chips, tier knots or slot chips.
- The log page in the pause menu, and auto-return after the fight.
- Reduce-motion flashes.
- Free cuts that need nothing in their place: row tags on every screen, "Board 7/7", the hand title, the empty-hand hint, "Changes save", the settings portrait tray, the "ATTACK n" counter and the ghost toast.
- Rules page 1 gains "tap any card, or tap in a fight, to read it".
- Doc: log that the 6 Nov look reason is overruled.

**Checks:**
- Before/after at 1688x780 and 1920x1080 for `wording2/combat_mid`, `reminder/combat_reminder`, `wave1/homecoming-following-combat` and strong-field `rival-fight`.
- The combat screen at rest has no words, and no lines between tiles.
- Nothing is under `MIN_FONT`, and controls meet the tap minimum.
- Frame strips of 3 fights at phone size (8 frames per attack) at ×1 and at ×4, plus one under reduce motion.
- The cold-reader test (Section 6) passes.

### Batch 2: recruit board, tiles, scouting and the reader

**Scope:**
- 2.1 on every zone, applying the per-unit name rule.
- 2.2, the scout rows of 2.5, and 2.4.
- Animations 14 and 38–45 in recruit, plus anim 36: the End of Turn sequence, Pass seed, relation sparks, reach pulse, drag lean, Rings, paint and frost.
- Doc edits, with reasons logged:
  - Rulebook 12.1.6: drop the sentence about the permanent Pass mark and the selection preview, and reword "last in F1-B1-…-F4" as "rightmost". The rule itself is unchanged.
  - Wording guide line 13 ("Always shown") and line 73 ("selecting a unit lights the slots": becomes "opening a unit's reader pulses the slots its text reaches").
  - `keyword_rules.gd` reminders reworded.

**Checks:**
- Before/after at both sizes for `wave1/redbreast-label/ui-after-overview`, `reader-reel_mistress-golden`, strong-field `scout` and `lobby`, and `wave1/natural-birds` or `round4-geometry`.
- Words at rest on shop and board tiles: 0, apart from short names on units that lack their own portrait. Today the count is about 65.
- No lines on the scouted board.
- Pocket size before/after, with the freed 100 px spent on pockets.
- Frame strips of an End of Turn with a Pass and a Touching effect, and of the reach pulse during scouting with a lent quarry.

### Batch 3: HUD and lobby

**Scope:**
- 2.3 and the lobby rows of 2.5.
- Animations 33–35, 37, 46–65.
- Deal heroes without repeats.
- Lobby sorted by standing. The vertical left column goes in if it passes the fit test; otherwise the portrait strip stays at the top.
- How-to-play: the new "Lobby, ghosts and the last four" page.

**Checks:**
- Before/after at both sizes for `wave1/ui-followup/ui-after-away-tray`, the overview, strong-field `lobby` and `ghost-scout`.
- Shop tile width and board height before/after. Target: about 140 canvas px of width back on phone.
- A hand of 10 cards with all cards visible. Birds away with a full hand, showing a doorstep token.
- The gold number stays visible with the reader open on phone.
- Frame strips: Fly South, then a homecoming, then the post-fight Health count-down and re-sort.

### Batch 4: tutorial and Rules reference

**Scope:**
- Section 4: the scripted 4-round tutorial, the first-run choice, and the Rules hub with animated demos.
- 2.7: menu, settings and game-over.
- A sweep for any tests and docs still pinning removed text.

**Checks:**
- A screenshot of every tutorial step at both sizes.
- A frame strip of each Rules demo.
- Game-over before/after (`evidence/ui/game_over`).
- The cold-reader test rerun using only the tutorial script and the Rules pages.
- A fresh first-timer agent plays the tutorial, then one real game, and lists anything it met in the game that neither had taught.

---

## 6. Review criteria for UI reviewers and playtesters

These replace every criterion that rewards explaining things on the main screen. That includes "explains a fight best" and "a first-time player can tell X from the screenshot".

**Who judges:** a player in their hundredth game, a strong Battlegrounds player, for every main screen. A first-timer judges only the tutorial and the Rules pages.

**Resting stills (recruit, scout, lobby, combat paused):**
1. **Words at rest.** On shop and board tiles the target is 0, apart from short names on units without their own art. The whole recruit screen allows only End turn, numbers and those names. Report the count.
2. **Lines at rest.** Lines, arrows or links between tiles: 0.
3. **Every mark passes the three tests** (Section 1). For each mark, the reviewer names the changing state it shows that can't be seen any other way. A mark with no answer is a finding.
4. **Every mark is readable.** Tapping each kind of mark in a scripted run opens the reader with its meaning.
5. **Side by side** with Battlegrounds, TFT and Once Upon a Galaxy screenshots of the same phase (owner, 9 Nov 09f). Count the elements on the board in each.
6. **Phone floor.** Nothing under `MIN_FONT`, and controls at least the tap minimum.

**Motion (never judged from stills):**
7. **Cold reader.** A fresh agent who has read only the tutorial script and the Rules pages gets frame strips of 3 fights at phone size. For every attack it must say who hit, what triggered and why each unit died. At ×1 all answers must be right. At ×4, "who hit" and "why it died" must still be right.
8. **Timing.** Recruit input is never blocked. The End of Turn and Start of Turn sequences each take 1.5 s or less. Single cues take 0.4 s or less. A fight ends and returns to recruit within 1.6 s of the last death.
9. **Reduce motion.** The same fights as frame strips under reduce motion carry the same answers, without text.

**Questions for playtesters and play-reviewers:**
- What would you turn off after your third game?
- What did you have to stop watching the board to read?
- Was there a fight result you couldn't explain from what you saw?
- What did you want to know mid-game that took more than one tap to find? (This checks that the cuts didn't go too far.)
- Which marks still meant nothing to you after the tutorial?
- By your tenth fight, did any animation feel slow?

---

## Appendix: calls where reviewers disagreed (for `DECISIONS.md`)

| Question | The options | Call | Why |
|---|---|---|---|
| Keyword chips | Card audit: no static mark. Critique A: frame marks for Mire and Quarry; test Swoop and Bristle. | Frame marks for Mire, Quarry and Swoop. Bristle is motion only. | These decide who attacks whom, which is the read on a scouted board (Battlegrounds' Taunt frame). Bristle changes damage, and the hit shows that. |
| Nest countdown and homecoming | Board and card audits: a digit on the Nest; the Bird swoops into its slot. Critique A: off the board; home to hand. | A for the countdown (on the token only) and homecoming (into the hand). Keep a wordless twig rim under a covering unit. | Rulebook 12.1.4 sends Birds to the hand. A covered Nest still decides where an Egg fights if you move the unit, like a Ring. |
| Ring size | Board audit: reader only. HUD audit and both critiques: a counter. | Counter | Whole-player state that a Fairy player prices on every refresh. |
| Hand overflow | HUD audit: keep "+N more". Critique A: show every card. | Show every card, fanned when tight. | The hand is decision state (pairs close to a triple). |
| Result panel | Combat audit: a banner. Critique A: cut it and auto-return. Critique B: the word "Last Blow". | Cut it and auto-return. Last Blow's base spark rises from the deciding unit. | Battlegrounds has no result screen, and this saves 15 or more taps a game. The spark's source shows the cause without a word. |
| Reach highlight | Board audit: lean on drag only. Card audit and critique B: a tint while the reader is open. Critique A: nothing at rest. | One pulse when the reader opens or a spatial word is tapped, plus the lean on drag. No lasting tint. | Keeps the wording guide's cue on demand. On phone the reader opens on every tap, so a held tint would come back as standing clutter. |
| Scout forecast | Board audit: cut with nothing. Lobby audit: hold to draw links. Critique B: reader tint. | No lines. The reach pulse lights the enemy slots a unit will reach. | Lent quarries aren't straight across (`lane_projection.gd`, `own_across`), so "across" alone can't teach them. |
| Slot codes in text | Undecided. Critique B: reword. | Reword | The zigzag (`board_geometry.gd` `ZIGZAG`) runs left to right, so the Pass recipient is the rightmost other unit. |
| Pass preview | Board audit: a "Passes to" reader line. Card audit: a mote while dragging. | Neither | The rightmost other unit can be seen on the board. |
| Lunge at speed | Combat audit: every timing scales. Critique B: a floor. | Floor | At ×4 the travel would last about 2 frames, and the yarn that used to show the hit is gone. |
| Names on tiles | Board audit: cut now. Critique B: cut per unit. Critique A: cut once all art exists. | Per unit. Portraits reviewers confuse count as missing. | The chess point works only if pieces look different. 50 of 157 units share a tribe portrait. |
| Lobby names | Lobby audit: portraits are enough. Critique A: the strong-field lobby repeats heroes. | Deal heroes without repeats | Portraits identify only unique heroes. There are 9 heroes for 8 seats. |
| Lobby order and layout | Lobby audit: re-sort optional. Critique A: always sorted, and a vertical column. | Always sorted. The column goes in only if the fit test passes. | Standing is checked every turn. The phone screen is short on height. |
| Shy | HUD audit: a looping fidget and keep the confirm. Critique A: cut both. | Cut both. The unit leaves at once when thanked. | Only an aimed spell thanks Shy (`shy.gd`), so the player just chose it. Critique A's "at End of Turn" was wrong. |
| Reduce motion | Yarn for 0.4 s, flashes, or toasts | Flashes | Toasts bring back the narration the owner asked to remove. |
| Damage sparks | Staggered (three audits) or all at once (critique A) | All at once, 0.6 s or less. Staggered only in tutorial step 7. | They play after every fight of every game. |
| Tutorial length | Lobby audit: 6 rounds. Critique B: 4 rounds. | 4 rounds | Rare states have tappable marks and a Rules page. Scripting an elimination teaches no control. |
| "+X" pops on gains | Board and card audits: keep. Combat audit: none. | None. The bead pops and rolls. Damage keeps −N. | Battlegrounds shows buffs by the stats changing. Damage is what a fight is read by. |
| Hex amount | Combat audit: sigil only. Board and card audits: a number. | Sigil with the number | On an empty hexed pocket the amount shows nowhere else. |
| Hand count | From 8 cards (card audit) or at 10/10 (HUD audit) | 10/10 only | Every card is visible anyway. |
| Ring count digit | Bottom-right or top-right | Top-left of the ring | Bottom-right is the Health bead and top-right is the quarry paw. |
| Names on combat plaques | Combat audit: a short name. Lobby audit: none. | None | The same reason as the lobby. |
| Mire pictures | Reeds on the unit and on the patch | Reeds on the Mire unit; plain mud on the patch | One picture per meaning. |
| The bell | Combat audit: "the game's word". Critique B: wording guide line 45. | A picture and a sound only; the text says Start of Combat | The wording guide says to write Start of Combat, not bell. |
| End of Turn pacing | Card audit: one by one, 0.35 s each. Critique A: 1.5 s total. | Reading-order stagger of 0.12 s, overlapping, 1.5 s or less | Order stays visible, and seven units don't cost 2.5 s. |