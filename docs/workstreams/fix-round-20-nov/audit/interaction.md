# Interaction audit: Bramble playable build

Branch `plan/fix-round-20-nov` (same commit as `main`, 13f44dd9). Read-only. All paths are relative to `/home/alex/code/Bramble`. Rule numbers are from `docs/design/rulebook.md` v0.10.

The live game loads the five tribe folders. The stand-in *units* in `src/game/data/stand_in_units.json` are not loaded, but the three stand-in *spells* are, because no tribe has a spell (`src/game/game_content.gd:73-82`). Those spells are `sp_sharpen` (play_buff, aimed), `sp_seek` (Discover) and `sp_forage` (Discover x2) (`stand_in_units.json:368,385,399`). Shop size is 5 units and 2 spells (`src/core/rules/game_config.gd:31-32`).

---

## 1. Hand limit and lost cards

**Where the limit is set:** `GameConfig.hand_limit = 7` (`src/core/rules/game_config.gd:36`). It is read through `Rules.hand_limit()` (`src/core/rules/rules.gd:164-165`) with a floor of 1 (`rules.gd:76-77`). No content card changes it. The screen shows "Hand N/7" (`src/screens/recruit/recruit_counts.gd:88-101`, from `view_adapter.gd:37`). Rules: 7.1.1 (7 cards, C14) and 7.1.2 [BG]: "A card gained while the hand is full is lost, unless the effect says it waits for space."

**The single gain path:** every gain goes through `Recruit._gain` (`src/core/recruit/recruit.gd:599-611`):

```gdscript
## 7.1.2: a card gained while the hand is full is lost (its pool copies go back).
func _gain(player: PlayerState, unit: Unit, target: int = -2) -> bool:
	if player.hand.size() >= _rules().hand_limit(player):
		var pool: CardPool = session.spells if unit.is_spell() else session.units
		pool.give_back(unit.def.id, unit.pool_copies)
		_log(player, {"type": "card_lost", "id": String(unit.def.id)})
		return false
```

| Way in | Code | Full hand |
|---|---|---|
| Buy (drag to hand, double-click, drag onto a slot) | `_buy`, `recruit.gd:183-184`: `if player.hand.size() >= ... : return "hand is full"`. LegalActions lists no buys: `legal_actions.gd:45-46`. | **Refused.** Message "hand is full". Rule 4.2.2. |
| Board to hand (7.2.4) | `to_hand_error`, `recruit.gd:438-439` | **Refused.** "hand is full". Rule 7.2.5. |
| Discover pick (Triple Reward, `sp_seek`, `sp_forage`) | `_pick` → `_gain`, `recruit.gd:489-505`. It never checks the hand first, and picks stay legal with a full hand (`legal_actions.gd:15-19`). | **Lost** (logged `card_lost`). Casting the spell frees one place first (`recruit.gd:262`), so a single Discover fits. `sp_forage`'s second pick can still be lost. |
| Triple golden | `_combine`, `recruit.gd:778-784` | **Never lost.** It goes to the hand if there is room, or if no copy was on the board. Otherwise it goes to the first vacated board slot (7.3.7 [PROPOSED]). |
| **Triple Reward** | `recruit.gd:785-789`: `var gained: bool = _gain(player, reward)` | **Lost.** The comment says "through the ordinary full-hand loss path". It logs `card_lost`, and the triple event gets `reward_uid: -1` (`recruit.gd:790-799`). |
| `give_card` (Horde-runner `locust_hopper_to_hand`, start of turn) | `recruit_context.gd:308-318` → `_gain`; `hopper_to_hand.gd:1-2,16` | **Lost**, one Hopper per missing place. |
| Elimination ghost hand | `game_session.gd:369-378` | Copy only. Not a gain. |

**The owner's complaint is reproducible, and it is the intended code.** The golden takes a hand place whenever one is free, even when a board copy vacated a slot (`recruit.gd:778`: `if player.hand.size() < limit or vacated.is_empty(): _gain(player, golden)`). The reward is gained afterwards. It is lost whenever the hand is at 7 after the golden is placed. Two cases do this:
- The hand reaches 7 when the third copy arrives, and only one of the three copies is in hand (two on the board). That is the common case: hand at 6, then buy or Discover the third copy. One copy leaves (6), the golden enters (7), and the reward is lost.
- The hand is full and all three copies are on the board. The golden goes to the board and the reward is lost.

Two tests pin both cases: `tests/core/test_triples.gd:242-256` (`test_7_3_6_reward_lost_when_golden_fills_the_last_hand_space`) and `:259-268`. Rule 7.3.6 says only "a Triple Reward spell is added to hand"; it doesn't say what happens with a full hand. The UI never reports a lost card: no code in `src/screens` or `src/game/view_adapter.gd` reads `card_lost`.

---

## 2. Buying with a full hand, and buy-time effects

**What blocks it:** the core refuses the buy (`recruit.gd:183-184`) before it looks at the board. The UI also lights no slot while a shop card is carried, because "buy" is not in legal_actions (`recruit_board.gd:122-127`; `recruit_screen.gd:211-212`). Rules: 4.2.1 "The bought unit goes to the player's hand"; 4.2.2 "A player with a full hand can't buy"; 7.2 Note (`rulebook.md:431`): "This rulebook keeps HSBG's hand (4.2.1), because merges, Discover and triples all depend on it." The open owner item is `docs/design/review-queue.md:44` (item 17).

**Shop straight to board already exists, but only as a UI composite.** Dropping a shop card on an empty slot sends `buy` to hand, then `play` into that slot (`recruit_input.gd:336-338, 357-378`; `bought_onto` `:522-531`). The core has no buy-to-board action. With a full hand the buy fails, so the play never happens. On an occupied slot the drop is a plain buy to hand (`:526`). When the buy forms a triple, nothing is played (`bought_card` returns -1, `:544-556`). For a unit that needs a recruit target, the screen asks for the target, then plays (`:372-373, 452-457, 509-516`).

**Triggers that exist.** Playing a unit fires nothing: `_play` only places the unit and refreshes auras (`recruit.gd:268-271`; rule 7.2.3). Recruit effects fire inside `_gain` → `_recruit_unit` → `on_recruited` (`recruit.gd:609-610, 657-667`) for every gain: buy, Discover, give_card, golden (rule 7.2.6). The completing third copy does not fire; the golden does (`recruit.gd:608-610`; owner 18 Nov "Only the golden fires"). A golden placed on the board fires too (`recruit.gd:784`). No listener exists for "a unit is bought, played or gained". `notify` is called only for start of turn, end of turn, any sold, after fight and heap added (`recruit.gd:80,92,245,586`; `recruit_context.gd:220`). The hook list is `src/core/mechanics/mechanic.gd:101-196`.

**Cards with an effect at recruit or play time, all five tribes (98 units):**

| Card | Trigger | If bought straight onto the board |
|---|---|---|
| Master-at-Arms (Badger t3, `badger/units.json:350`, `badger/mechanics/arms_master.gd`) "Recruit: Give a unit +N Fury." | `on_recruited`, target FRIENDLY_UNIT from hand or board, itself included (`recruit.gd:638-644`) | Fires the same way if the new path still runs `_recruit_unit`. The target choice still applies; the current drag flow already handles it. |
| Harvest Piper (Mouse t2, `mouse/units.json:67`, `mouse/mechanics/piper.gd`) "Recruit: Give your other Mice +N Attack." | `on_recruited`; buffs `board_units()` only, never itself (`piper.gd:12-14`) | Same result: it skips itself in either zone, and Mice in hand are never buffed. |
| Golden copies of these two | `on_recruited` when the triple forms (`recruit.gd:609-610, 784`) | Unchanged. |

No other unit has `on_recruited`, `on_played` or any hook tied to buying or playing. Checked: every `func on_*` in `src/content/*/mechanics/*.gd`. `play_buff` (`core/mechanics/effects/play_buff.gd`) is used only by the stand-in spell `sp_sharpen`, and spells are cast, never placed (`recruit.gd:265-267`).

**Effects that depend on location but are not buy triggers.** A buy-to-board path would change these by where the unit sits:
- **Reserve:** Territorial (`pigeon/units.json:45`) and The Colonel's "Units in your hand have Reserve" (`pigeon/units.json:443`, `colonel.gd` side_query) count only hand units at fight time. A unit bought onto the board is not in hand.
- **Auras:** these are recomputed on every board change (`recruit.gd:270, 802-821`). A unit bought onto the board gives and receives them at once, as a played unit does.
- **Origin:** `_buy` sets `bought_copies = 1` (`recruit.gd:202`). Sell value reads it (`rules.gd:119-121`), and so does Lone Hawthorn (`lone_hawthorn.gd:21`, via `combat_unit.gd:59`). A new path must keep it.
- **Triples:** these count hand and board together (`recruit.gd:616-623`), so the zone doesn't matter. The golden goes to hand (7.3.1).

**"When you buy" on other cards:** none. Gorger, Granary Glutton and the Thorn Compost react to sales (`on_any_sold`: `gorge.gd:14`, `glut.gd`, `compost.gd:10`). Bury is an activated ability that takes a shop card, not a buy (`thorn/lib/bury_base.gd:11-28`). No content changes unit price or hand limit (no `modify_int` for those queries in `src/content`).

---

## 3. Hand to board, and board to board

The drop logic is `RecruitInput._drop` (`src/screens/recruit/recruit_input.gd:332-354`). `slot_at` returns any slot under the pointer, empty or not (`recruit_board.gd:85-92`).

- **Hand unit dropped on an occupied slot:** `_play(index, card, slot)` (`:346-347`). LegalActions lists plays only into empty slots (`legal_actions.gd:64,79`), so nothing matches. The action is sent as built (`:498-506`), and the core refuses it with "choose an empty slot" (`recruit.gd:297-298`). The controller shows that message (`game_controller.gd:84-91`) and the card returns to hand. **There is no hand-to-board swap.** Only empty slots light up while a hand card is carried (`recruit_board.gd:119-137`).
- **Hand unit dropped above T0 (y < 456.5):** sold from hand (`:344-345`; rule 4.3.7).
- **Board to board:** this exists and swaps. A drop on any other slot sends `move` (`:349-350`), and `_move` swaps when the target is taken (`recruit.gd:402-417`; rule 8.3.3). The slot test runs before the sell test.
- **Board unit dropped at y ≥ sill (966):** `to_hand` (`:353-354`). Above T0 it is sold (`:351-352`).

---

## 4. Triple highlighting

The marks are computed in `RecruitDuplicates.marks(state)` (`src/screens/recruit/recruit_duplicates.gd:8-38`). It reads the shop units, board and hand. Spells, Discover options and the fight screen are not included.

- `copies[id]` counts every unit copy in shop, board and hand, goldens included (`:20`). `normal[id]` counts only combinable non-golden copies (`:21-22`, `_can_combine` `:48-52`).
- **Nothing is marked unless that id is in the shop now** (`:30`). Two owned copies with no shop copy show nothing.
- **MATCH (rim glow), shop cards only:** `copies >= 2`, counting itself (`:32-33`). So one owned copy (golden included) or a second shop copy gives MATCH. Two identical shop cards and nothing owned also light each other.
- **TRIPLE (strong rim plus foil), any zone:** a non-golden card with `normal >= 3`, shop copies counted (`:34-35`). Example: one shop copy and two owned light all three. Two shop copies and one owned also light all three, although one buy gives only two copies.
- How it is drawn: `GlassDuplicateGlow.apply` (`src/glass/glass_duplicate_glow.gd:25-35`, layers `:9-17`, `_set_mark` `:38-63`). The foil is `GlassTripleFoil.apply(card, mark == TRIPLE)` (`glass_duplicate_glow.gd:39`; `glass_triple_foil.gd:22-58`).
- **When it updates:** in `RecruitScreen._place_cards` (`recruit_screen.gd:440-454`) on every layout, which means every new state and every redraw (`glass_screen.gd:191-203`, `recruit_screen.gd:273-281`). Nothing recomputes during a drag. The pulse runs each frame from `_process` → `set_phase` (`recruit_screen.gd:108-117`; `glass_duplicate_glow.gd:68-77`). `candidate` is always 0 (`:6, :20`).

---

## 5. Left click skips the fight

`GameController._input` (`src/game/game_controller.gd:226-258`; header `:7-13`).
- **Input:** a left mouse button *press* anywhere (`click.pressed and button_index == MOUSE_BUTTON_LEFT`), or Space, Enter or keypad Enter (`SKIP_KEYS`, `:30`; test at `:238-244`).
- **During FIGHT:** after `RESULT_GUARD` = 0.4 s (`:28`), it calls `fight.skip()` and `settle()` and goes to the result (`:245-251`).
- **During AFTER_FIGHT:** after 0.4 s the same input moves on (`:252-257`); otherwise it moves on by itself after `AFTER_FIGHT` = 2.5 s (`:26`, `:213-217`).
- **Exceptions:** an open Compost overlay (`:228-229`), Escape, F11 and Tab (`:236-237`). The settings cog reads its click first (`main.gd:184-187`, `settings_cog.gd:73-`). The Compost chip is handled first too (`glass_counters.gd:29-41`).
- **Other skip controls:** none for players. The hint reads "Space or click to skip" (`:31`, drawn at (960, 1040) `:189-199`). F8 autoplay in debug builds skips fights entirely (`:117`, `:232-235`). `FightScreen.speed` is an export with no UI (`fight_screen.gd:43-44`). The pause panel has no speed or skip option (`src/game/ui/pause_panel.gd:33-42`).

---

## 6. The type line

- **"Unit"** is printed only in the hover pane's kind line: `"Tier %d · unit"`, plus "· costs N" and "· sells for N", in upper case (`src/screens/glass_parts.gd:273-284`). It reads, for example, "TIER 2 · UNIT · COSTS 3". The card face draws art, frame, golden rim and stats only, with no name or type (`src/glass/glass_card.gd:191-213`), plus keyword pills (`glass_screen.gd:340-358`). `kind_line` overrides it for counters ("Counter", `glass_counters.gd:109,114`) and abilities (`recruit_buttons.gd:99`).
- **`types` is never shown.** It is loaded into `UnitDef.types` (`unit_library.gd:81-82`, `unit_def.gd:14-16`) and used by Badger `is_knight` (`badger_rules.gd:87-88`). It also supplies the first word of a token's reminder, e.g. "A 1/1 Locust." (`game_content.gd:186-187`). `browser_catalog.gd:22` copies it into the card, but nothing reads it there; search matches only name and text (`:38-41`). `ViewAdapter.printed_unit` doesn't pass it (`view_adapter.gd:235-251`). Rule 5.2.1 defines the type line.
- Data shape: Badger cards have ["Badger", "Knight"/"Squire"]. Mouse cards have ["Mouse"/"Vole"/"Shrew"/"Dormouse", role]. Locust, Pigeon and Thorn cards each have one type (["Locust"], ["Pigeon"], ["Briar"]).

---

## 7. Tooltips

The code is `GlassTips` (`src/screens/glass_tips.gd`), with `RecruitTips` (`src/screens/recruit/recruit_tips.gd`) for the recruit screen's own kinds. The pane text is built by `GlassParts.tip_text` (`glass_parts.gd:242-332`) and the keyword boxes are placed by `KeywordLayout.arrange` (`src/screens/keyword_layout.gd`). Sizes are in `src/glass/keyword_style.gd:11-22` (PANE_W 340, DETAIL_W 330, GAP 12). No scene files are involved; everything is built in code.

**Positions:**
- **Board, shop or fight card:** an enlarged copy 1.6 × H (400 px) at pointer x + 28, y − 200, with the Words pane to its right (`glass_tips.gd:200-249`; layout `stage.tip.*`). It flips left if `tx + bigW + 320 > 1900` and is clamped between y 10 and 1070 (`:229-245`).
- **Hand card:** the card stands up unturned, with no enlarged copy. The words sit 16 px to its right, raised to stay on screen (`recruit_tips.gd:88-122`).
- **Ability button:** the words beside its card (`recruit_tips.gd:164-183`).
- **Discover option:** the words over the option's own pane (`:185-205`).
- **A pill on the card's border:** that keyword alone at pointer + 12 (`glass_tips.gd:322-331`).
- **Counter plate:** the words only (`:252-266`).
- **Alt held:** a golden preview (`glass_tips.gd:24-40, 113-131`; `recruit_tips.gd:35-63`).
- **Keyword boxes** stack under the Words pane. The whole group moves to avoid the hovered card and the Hero, HeroHealth, EndTurn, EndTurnWords, Opponent and OpponentHealth nodes (`glass_tips.gd:393-417`; `keyword_layout.gd:8-41, 64-108`). If the column won't fit, it goes beside the Words pane (`:23-41`).

**What decides the lines:**
1. **The Words pane** holds the name, the kind line and the rules text as `KeywordText`. Each term from `CardTerms.all_pills` becomes a mark: printed keywords with their numbers, counters, and given mechanics. Given terms not in the text get their own mark line (`glass_parts.gd:297-314`; `card_terms.gd:61-75`).
2. **One keyword box per mark** in the Words pane, each with a non-empty reminder, deduplicated by key. Then one more level for terms named in those reminders (`glass_tips.gd:336-390`).
3. **Reminder lines inside the pane** come from `GlassScreen._reminders` = `CardTerms.reminders` plus green source lines (`glass_screen.gd:371-376`; `card_terms.gd:161-202`). Card data feeds them through the `reminders` field (`game_content.gd:163-190`). Any line whose title is a display-table term is dropped from the pane (`glass_parts.gd:317-324`), so the pane keeps only token lines ("Hopper: A …"), core terms (Discover, `game_content.gd:24`), source lines and the fight's Outnumbered line (`fight_screen.gd:457-466`). Consequence: a display term listed in a card's `reminders` that is neither a mark nor named in another box's reminder appears nowhere.
4. **Pills on the card face:** as many as fit, up to `MAX_PILLS` 3, with the last place showing "+N" (`card_terms.gd:21-22`; `glass_screen.gd:331-358`).
5. **"Recruit:"** (Piper, Master-at-Arms) has no display entry and no core term, so it gets no reminder.

---

## 8. Recruit screen controls

Everything is built in code; `recruit_screen.tscn` is an empty Control. Positions are on the 1920×1080 stage from `RecruitShop.geometry()` (`recruit_shop.gd:37-49`), which shifts `assets/glass/layout.json` `stage.recruit.geom` down by 12.1 (hand) and the shop up by 54. Resulting values: handTop 980, sill 966, boardTop 486.5, T0 456.5, T1 472.5, shopTop 138.5, shopBot 388.5, shopL 586, card 140×250, gap 12.

| Control | Position (top-left) / size | Code |
|---|---|---|
| Shop units ×5 | x = 586 + 152·i, y 138.5; 140×250; hanging price coin under each | `recruit_screen.gd:227-228`; tag `recruit_shop.gd:165-178` |
| Shop spells ×2 | x = 814 + 152·k, y ≈ 6; 140×167 | `recruit_screen.gd:232-243` |
| Gold display (a button box, not clickable) | (390, 185.5), 176×68 | `recruit_shop.gd:53-57` |
| Upgrade tier "t → t+1" + cost coin | (390, 269.5), 176×68; hidden at top tier | `:58-72` |
| Refresh + cost coin | (1354, 185.5), 176×68; "N left at this price" at y 155.5 | `:73-84` |
| Freeze (toggle, frost when frozen); no separate lock | (1354, 269.5), 176×68 | `:85-88`; rule 4.5.1 |
| End turn = next opponent portrait | portrait (1734, 930) 128 px; "End turn" (1728, 892); HP (1722, 1014) | `recruit_buttons.gd:26-64` |
| Hero portrait (click toggles leaderboard) | (40, 930) 128 px; name (40, 892); HP (118, 1014); "Turn N" (54, 150) | `glass_screen.gd:442-476`; toggle `recruit_input.gd:470-471` |
| Counter plates (Compost, Tide, medals…) | x 40, y = 836 − 54·i | `glass_counters.gd:12-14, 45-46` |
| Leaderboard (when toggled) | right side, centred x 1797, top 74, row step 92 | `glass_screen.gd:493-514` |
| Next turn income / tier-up drop readouts | (196, 962) / right edge 1700, y 962 | `recruit_screen.gd:303-322` |
| Cards (browser) button | (1763, 64) | `browser_look.gd:74` |
| Settings cog | (94, 72), 58 px | `settings_cog.gd:13-14` |
| Board, front row F1–F4 | x 662/814/966/1118, y 486.5 | `recruit_screen.gd:247-258` |
| Board, back row B1–B3 | x 738/890/1042, y 702 | same |
| Hand fan | centred at x 960, top 980, step 103.6, 2.5° per card | `recruit_screen.gd:262-267` |
| "Hand N/7" | x = 960 − fan width/2 − 150, y 1020 | `recruit_counts.gd:80-101` |
| Message line | centred x 960, y ≈ 464.5 (between T0 and T1) | `glass_screen.gd:551-565` |
| Sell area | no fixed control. Dragging a board or hand unit above T0 shows "Sell for N" over the shop at (566, 124.5), 788×280; letting go there sells | `recruit_shop.gd:182-222`; `recruit_input.gd:221-231, 344-352` |
| Buy gestures | drop below shopBot (388.5), or double-click | `recruit_input.gd:198-205, 336-338` |
