# Prototype spec

**Status: overnight prototype, 3–4 November 2026. Nothing here is a decision.** This is the contract for the workers who build the prototype in [PLAN.md](PLAN.md): the rules core (`src/core/`) and the UI (`src/ui/`) are built in parallel and share only this file, [content/units/](../../content/units/) and [fixtures/](fixtures/). Rule numbers are from [rulebook.md](../design/rulebook.md) v0.4. Where the rulebook is OPEN or silent, the prototype picks something so it runs; every pick is listed in [section 9](#9-things-the-prototype-just-picked) for the owner to react to after playing.

Contents: 1 rule subset · 2 tunables · 3 unit files · 4 effect model · 5 combat event log · 6 state format · 7 the API · 8 bots · 9 things the prototype just picked · 10 build order

---

## 1. Rule subset

The prototype implements these rules as written, including their [PROPOSED] defaults. "As written" means the core follows the rule text, not a summary.

**Lobby and game (ch. 1–2)**
- 1.1.1–1.1.3: 8 players, recruit then combat each round, last player standing places 1st.
- 1.2.2 random is uniform; 1.2.3 reading order F1, F2, F3, F4, B1, B2, B3 for everything board-wide; 1.2.4 integer stats, clamp at 1,000,000,000.
- 2.1.1 eight players (the human plus 7 bots, [section 8](#8-bots)); 2.1.2 ghost for an odd player out; 2.1.3 game ends at round 50.
- 2.2.5 starting health 30. No armor (2.2.6 is about heroes, which are out).
- 2.3.1–2.3.3 matchmaking, simplified as in 9.

**Recruit phase (ch. 3)**
- 3.1.1–3.1.2: no timer; the phase ends when the player presses End Turn.
- 3.2.1 start-of-phase order: gold, upgrade discount, refresh counter reset, shop refill (keeping frozen cards), start-of-turn triggers.
- 3.3.1 actions in any order: buy, sell, refresh, freeze, upgrade, play, move.
- 3.4.1 end-of-phase order: End of Turn triggers, "this turn" effects end, unfrozen shop returns to pool, gold kept, board copied for combat. 3.4.2 hand units don't fight.

**Economy (ch. 4)**
- 4.1.1 income 3, +1 a turn, max 10 from turn 8. 4.1.2–4.1.3 carry-over, no cap, no interest. 4.1.5 gold never below 0.
- 4.2.1–4.2.4 buy for 3 into hand; full hand can't buy; bought slot stays empty; buying allowed with a full board.
- 4.3.1–4.3.4, 4.3.6–4.3.7 origin and selling: Bought sells for 1, Created for 0, a triple's golden sells for 1, only board units can be sold.
- 4.4.1–4.4.5 refresh: paid refreshes 1–15 cost 1, then +1 every 5, count resets each turn; refreshing unfreezes.
- 4.5.1–4.5.4 freeze toggles up to 5 times a turn; frozen shop keeps its cards and refills empty slots.
- 4.6.1–4.6.5 tiers 1–6, upgrade costs 5/7/8/11/11, −1 a turn from turn 2 (min 0), resets after an upgrade, no shop refill on upgrade.

**Shop and pool (ch. 5–6)**
- 5.1.1–5.1.2 one shared pool, copies per tier 15/15/13/11/9/7.
- 5.2.1 type line (the prototype shows the tribe as the type line); 5.2.3 type matching; 5.2.7 neutral units always in.
- 5.3.1–5.3.8 copies leave and return as written, including 5.3.5 (a golden returns one copy per pool copy it holds) and 5.3.8 (eliminated players' units return).
- 6.1.2–6.1.4 draws: one copy at a time, uniform over all copies left at or below the player's tier; empty slot if none.

**Hand and triples (ch. 7)**
- 7.1.1–7.1.2 hand of 10; a card gained into a full hand is lost.
- 7.2.1–7.2.3 play into any empty slot; no play with 7 units on board; placed first, then "when played".
- 7.3.1–7.3.5 triples: three non-golden copies across board and hand combine at once into a golden in hand; double base stats and keep buffs; golden text doubles numbers, keeps thresholds ([4.4](#44-golden)). 7.3.7 full-hand triple goes to the first vacated slot.
- 7.3.6 Triple Reward: **simplified**, see 9.

**Board (ch. 8)**
- 8.1.1–8.1.3 seven fixed slots in a 4–3 brick; 8.2.1–8.2.7 every relation (in front of, behind, adjacent, neighbour, across from, leftmost/rightmost per row, rows), using the relations table in the rulebook.
- 8.3.1 gaps allowed; 8.3.3 move to any empty slot or swap, free; 8.3.4 no packing; 8.3.5 effects that move into an occupied slot fail.
- 8.4.1–8.4.7 summon placement: dying unit's slot first, then the nearest-empty-slot table; one at a time; full board loses the summon.

**Combat (ch. 9)** — all of it, with the hooks of [section 4](#4-effect-model):
- 9.1 boards copied, units start in their recruit slots; 9.2.1 more units attacks first, tie random.
- 9.3.1–9.3.5 Start of Combat: one random player resolves all their Start of Combat units in reading order, then the other; deaths resolve between effects.
- 9.4.1–9.4.12 alternate attacks; the attack pointer and flags exactly as in 9.4.5 and 9.4.8 (this is the part most worth unit tests).
- 9.5.1 back-row protection; 9.5.5 random target among candidates; 9.5.6 random effects ignore rows; 9.5.7 card text can override targeting.
- 9.6.1–9.6.4 attack resolution steps, simultaneous damage, deaths checked after each damage event.
- 9.7.1–9.7.4 dying units leave their slots first; death order (active side first, reading order within a side).
- 9.8.1, 9.8.4 summons join the order where they land and are combat-only.
- 9.9.1–9.9.2 end of combat, ties. 9.10.1–9.10.3 runaway limits.

**Damage and elimination (ch. 10)**
- 10.1.1 damage = winner's tier + total tier of the winner's surviving units; 10.1.2–10.1.3 golden and Created units count their own tier; 10.1.4 cap 5 (turns 1–3), 10 (4–7), 15 (8+), off with 4 or fewer alive; 10.1.6 tie deals nothing; 10.1.7 ghost rules.
- 10.2.1–10.2.3 elimination after all fights, same-round order by health, game ends at one left.

**Durations (ch. 12)**: 12.1.1–12.1.2 "this combat" vs "permanently"; 12.2.1 auras recalculated on every board change; 12.2.2 board scopes; 12.2.3 last-known positions.

**Left out**
- Heroes and hero powers (2.2), armor, hero choice. Health is 30 for everyone.
- Tavern spells (4.2.5, 6.1.5, 5.1.2 spell copies): no spells exist, so the shop shows only units (section 2).
- Discover (6.2) and the Triple Reward spell (7.3.6), replaced by a direct reward (section 9). None of the chosen units Discovers.
- Tribe subsets per lobby (5.2.4–5.2.6): every tribe is in every lobby.
- Slot effects from the Recruit Phase (8.5): no chosen unit makes one. Mark's in-combat marks are handled by its script (section 4).
- Merges and Magnetic (4.3.5, 7.2.2 exception), returns and Reborn (9.8.2–9.8.3 are implemented in the pointer logic only if cheap; no chosen unit returns), "attacks immediately" (9.4.12; no chosen unit uses it), Stealth, Taunt, Divine Shield and the other [EXAMPLE] keywords of chapter 11.
- Systems outside v0 (ch. 13): trinkets, quests, anomalies, tier 7.
- Async snapshots (2.1.4): the prototype runs a live 8-player lobby in one process (section 9).

## 2. Tunables

All of these live in one `GameConfig` (section 7) with these keys, so the dev panel or a test can change them.

| Key | Value | Source |
|---|---|---|
| `players` | 8 | 2.1.1 |
| `starting_health` | 30 | 2.2.5 |
| `max_rounds` | 50 | 2.1.3 |
| `income_by_turn` | 3, 4, 5, 6, 7, 8, 9, then 10 | 4.1.1 |
| `unit_cost` | 3 | 4.2.1 |
| `sell_bought` / `sell_created` | 1 / 0 | 4.3.3 |
| `refresh_base_cost` | 1 | 4.4.2 |
| `refresh_first_step_after` | 15 paid refreshes | 4.4.3 |
| `refresh_step_length` | 5 paid refreshes | 4.4.3 |
| `freeze_toggles_per_turn` | 5 | 4.5.1 |
| `upgrade_costs` (to tier 2–6) | 5, 7, 8, 11, 11 | 4.6.2 |
| `upgrade_discount_per_turn` | 1, min 0, from turn 2 | 4.6.3 |
| `pool_copies_by_tier` | 15, 15, 13, 11, 9, 7 | 5.1.2 |
| `shop_units_by_tier` | 3, 4, 4, 5, 5, 6 | 6.1.1 "of which units" column; prototype pick (no spell slot) |
| `hand_limit` | 10 | 7.1.1 |
| `damage_cap_by_turn` | 5 (turns 1–3), 10 (4–7), 15 (8+) | 10.1.4 |
| `damage_cap_off_at_alive` | 4 | 10.1.4 |
| `attack_limit` | 200 attacks per combat, tie | 9.10.1 |
| `trigger_limit_combat` / `trigger_limit_action` | 10,000 / 1,000 | 9.10.2 |
| `stat_clamp` | 1,000,000,000 | 1.2.4 |
| `pool_filter` | "all" (or "skeleton": only the 6 skeleton units in the pool) | prototype pick (section 10) |
| `bots` | 7: greedy ×2, wide ×2, tribe ×2, balanced ×1 | prototype pick (section 8) |
| `human_bot` | "" (the human plays), or a personality: player 0 is then played by that bot and the game runs until one player is left | core pick, for bot-only test games |

## 3. Unit files

One JSON file per unit in `content/units/<id>.json`. [content/units/README.md](../../content/units/README.md) lists them. `tools/checks/check_units.py` validates them (run by `scripts/check.sh`, step `content`).

```json
{
  "id": "hoglet_mother",
  "name": "Hoglet Mother",
  "tier": 2,
  "attack": 1,
  "health": 3,
  "tribes": ["Hedgerow folk"],
  "text": "Bristle 1. When this dies, summon a 1/1 Hoglet with Bristle 1.",
  "golden_text": "Bristle 2. When this dies, summon a golden 2/2 Hoglet with Bristle 2.",
  "mechanics": [{"id": "bristle", "n": 1}, {"id": "death_summon", "unit": "hoglet", "count": 1}],
  "keywords": ["Bristle"],
  "row_hint": "front",
  "pool": true,
  "priority": 3,
  "skeleton": false,
  "source": {"kind": "library", "entry": 7, "mechanic": "Bristle", "library_stats": "1/3", "stat_fix": null, "note": "..."}
}
```

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Unique, snake_case, equal to the file name. |
| `name` | string | Shown on the card. |
| `tier` | int 1–6 | Shop tier. |
| `attack`, `health` | int | Base stats (Attack ≥ 0, Health ≥ 1). Golden doubles them (7.3.4). |
| `tribes` | string[] | Zero or more of: Fairies, Oozes, Hedgerow folk, Hunters, Birds, Bog folk, Hive. Empty means neutral. The UI shows them as the type line and colours the card by the first. |
| `text` / `golden_text` | string | Rules text for the normal and golden card. Display only: the core reads `mechanics`, never the text. Plain units have `""`. |
| `mechanics` | object[] | Each has an `id` from the mechanic table (4.3) and exactly the parameters that table lists. Order is the order the scripts run for the same hook. |
| `keywords` | string[] | Badges for the UI (e.g. "Bristle"). Display only. |
| `row_hint` | "front", "back" or null | Where bots place it (section 8). Display only for the UI. |
| `pool` | bool | false for tokens: never in the shop or pool, only summoned. |
| `priority` | int or null | Build order for library units (section 10); null for filler and tokens. |
| `skeleton` | bool | true for the 6 plain units of the walking skeleton (section 10). |
| `source` | object | `kind` is "library", "filler" or "token"; `entry` the mechanics-library entry number; `library_stats` the printed stats; `stat_fix` the budget review's change if applied; `note` the keyword's full rules text where the card only names it. |

A new unit that reuses existing mechanic ids is a new JSON file and nothing else. A unit with a new mechanic needs a new mechanic script in the core (section 4) and a line in the checker's table.

## 4. Effect model

No general effects engine. The core has a fixed set of **hook points** in recruit and combat code, and **one script per mechanic id** that implements whichever hooks it needs. A unit's JSON names its mechanics and their numbers. This keeps each mechanic's odd rules in one readable place (Hunker's halving, Peck's strikes), which is what most of the chosen mechanics need: each one bends a different system rule.

### 4.1 Hook points

Every hook receives a context (`CombatContext` or `RecruitContext`) with the unit, its side, its slot, the mechanic's parameters already doubled for golden ([4.4](#44-golden)), the RNG, and methods to act: deal damage, lose health, buff, apply/remove status, summon, mark a slot, emit an event. Scripts never touch the event log directly except through these methods, so every change is logged.

**Recruit phase**

| Hook | When | Rule |
|---|---|---|
| `on_start_of_turn` | step 5 of 3.2.1, reading order | 3.2.1 |
| `on_buy` | after a unit is bought, for the bought unit and for board units | 4.2.1 |
| `on_play` | after a unit is placed from hand | 7.2.3 |
| `on_sell` | before the sold unit leaves, for it and for board units | 4.3.7 |
| `on_refresh` | after a refresh, with `paid: bool` | 4.4 |
| `on_end_of_turn` | step 1 of 3.4.1, reading order | 3.4.1 |

**Combat**

| Hook | When | Rule |
|---|---|---|
| `on_start_of_combat` | 9.3.2 order | 9.3 |
| `choose_turn_action` | a unit is chosen to attack (9.4.5 step 2); returns `attack`, `skip` or `whistle` (as built: `""`, `"skip"`, `"turn"`; see the milestone B picks in 9). Default `attack` | 9.4.5 |
| `on_attack_declared` | before step 1 of 9.6.1, for the attacker, the defender and every other unit on both sides (Bystander, Both Ends). May cancel the attack | 9.6.1 |
| `on_before_attack` | attacker's "whenever this attacks", step 2; once per strike for Peck | 9.6.1 |
| `strikes` | query: how many strikes this attack makes. Default 1 | 9.6.1 |
| `strikes_first` | query: does this unit deal its damage first in this exchange (Quick) | 9.6.2 |
| `modify_damage_taken` | query on each incoming damage amount, with its kind (`attack`, `effect`, `thorns`) and whether the unit is the defender | 9.6.1 step 3 |
| `on_damage_dealt` | after a damage event, for the source | 9.6.3 |
| `on_damage_taken` | after a damage event, for the target, before deaths are checked | 9.6.3 |
| `on_after_attack` | step 4, and again after death resolution with `survived` flags (Sett Warden) | 9.6.1 |
| `on_death` | the dying unit's own death effects, 9.7.2 step 2 | 9.7.2 |
| `on_friendly_death` | 9.7.2 step 3 | 9.7.2 |
| `on_summon` | after a unit enters the board in combat | 9.8.1 |
| `on_enter_slot` | after any unit enters a slot (summon or move) | 8.2.4 |
| `stat_aura` | query: Attack/Health this unit adds to others right now; recalculated on every board change | 12.2.1 |
| `on_end_of_combat` | after 9.9.1, before the result | 9.9 |

**Statuses** are named flags on a combat unit with optional data: `nightshade`, `stalled`, `first_bite`, `shell` (with `n`; removed when it breaks), `warned` (by Whistle), `waiting` (Bide). The UI shows them as badges.

### 4.2 Rulings the scripts need

The library's rules reviews left these open; the prototype rules them so the scripts can be written. Each is also in section 9.

- **Nightshade:** the halving happens at the start of the damage exchange (9.6.1 step 3) to the unit actually hit, once per attack turn: a Peck attack halves once, a Swarm joint attack halves once. Health loss lowers current Health like damage but is not a damage event: Shell doesn't break, Bitter Toad and Bide don't fire, and it never kills (1 Health loses nothing).
- **Peck:** the target's "when attacked" effects fire once; Bystander fires once; each strike is a separate hit for Hunker, Shell and Bristle; the return blow lands with the last strike, so an early kill means no return blow. Strikes don't count toward the attack limit.
- **Shell:** simultaneous hits (a Swarm) cap the largest and then the shell is broken. N stays the same on golden. Two Shells keep the lower N.
- **Hunker:** halves once even if granted twice; rounding up; only attack damage while defending.
- **Bristle and Both Ends:** thorn damage (Bristle, Both Ends' prick) never triggers thorns. Both Ends' prick is effect damage dealt before step 1; if it kills the attacker, the attack doesn't happen and the attacker's turn is used.
- **Pin:** applies even if the toad dies in the same exchange. A stalled unit, when chosen, is flagged, loses the status and its side picks the next unit (9.4.5) in the same turn; this doesn't count as an attack.
- **Bide (Slumber):** a waiting unit is chosen, grows, and is flagged; its side's turn passes to the next unit in the same turn. It wakes when it takes damage or when no friendly unit that isn't waiting can attack.
- **Whistle:** a whistle uses its side's turn and counts toward the 200-attack limit (so two boards that only whistle or wait end). *Superseded by library entry 10: whistlers can't attack for 9.9.1, see the milestone B picks in 9.* A pending warning carries across cycles until the warned enemy attacks.
- **Swarm:** joiners are later unflagged Swarm units in the leader's row, which become flagged. The target hits back only the leader. Each joiner's damage is its own hit.
- **Quick / First Bite:** in a Quick exchange the Quick side's damage (and its thorns) resolves and deaths are checked before the other side's damage. Both Quick means simultaneous. First Bite is used up by the unit's first exchange, attacking or defending.
- **Mark:** entering damage is effect damage (Shell applies, Hunker doesn't). The mark belongs to the marker's side, lasts the combat and survives the Fox Cub's death.
- **Sett Warden:** "survives being attacked" means it is still on the board after that attack's death resolution.
- **Death summon on golden:** the summoned token is golden (doubled stats and numbers); the count stays.

### 4.3 Mechanic table

Parameters marked **number** double on golden; **threshold** keeps its value (7.3.5).

| Mechanic id | Hooks | Parameters | What it does | Units |
|---|---|---|---|---|
| `nightshade_mark` | start_of_combat | `count` number | Give Nightshade to the `count` enemies with the highest Health (ties random). | Belladonna Sprite |
| `nightshade_on_hit` | damage_dealt, damage_taken | — | Enemy this damages gains Nightshade; if golden, an enemy that damages this does too (library entry 75's golden text, hard-coded). | Bitter Toad |
| `bristle` | damage_taken | `n` number | Enemy that damages this during an attack takes `n` thorn damage after the exchange, before death checks. | Hoglet Mother, Hoglet |
| `death_summon` | death | `unit` id, `count` threshold | Summon `count` of `unit` (8.4.1 first slot). Golden summons golden. | Hoglet Mother |
| `hunker` | modify_damage_taken | — | Attack damage taken as the defender is halved, rounded up. | Sett Warden |
| `survive_buff_behind` | after_attack | `attack` number | After surviving being attacked, the units behind this gain +`attack` Attack this combat. | Sett Warden |
| `shell` | modify_damage_taken | `n` threshold | First damage this combat is capped at `n`, then the shell breaks. | Garden Snail |
| `pin` | damage_dealt, damage_taken | — | An enemy that takes damage from this gains `stalled` (library entry 11's text). | Mudwallow Toad |
| `bystander` | attack_declared | `attack`, `health` number | When an enemy attacks one of your other units, this gains +`attack`/+`health` this combat. | Fox Notary |
| `grant_first_bite_in_front` | start_of_combat | — | The units in front of this gain `first_bite` this combat. | Weasel Second |
| `quick_while_undamaged` | strikes_first | — | Quick while this has taken no damage this combat. | Ermine Duellist |
| `peck` | strikes | `strikes` threshold | Attacks as `strikes` strikes, Attack split evenly, larger parts first. | Drumming Woodpecker |
| `on_attack_buff_tribe` | before_attack | `tribe`, `attack` number | Whenever this attacks (each strike), your other `tribe` units gain +`attack` Attack this combat. | Drumming Woodpecker |
| `swarm` | attack_declared | — | Other unflagged Swarm units in this row join the attack (4.2). | Worker Bee |
| `both_ends` | stat_aura, attack_declared | `attack`, `health`, `prick` number | With another Both Ends unit at the other end of the row (F1–F4 or B1–B3), both have +`attack`/+`health`; when an enemy attacks one, the other deals `prick` to the attacker first. | Hedgehog Twin |
| `bide_slumber` | choose_turn_action, damage_taken | `attack`, `health` number | Skips and grows +`attack`/+`health` this combat each time, until damaged or alone (4.2). | Hazel Dormouse |
| `whistle` | choose_turn_action | — | Never attacks; on its turn, warns the highest-Attack enemy not yet warned: its next attack deals half damage, rounded up. | Marmot Lookout |
| `mark` | start_of_combat, enter_slot | `damage` number | Marks the enemy slot across from this; each enemy that later enters it takes `damage`. | Fox Cub |
| `fast` | refresh, buy, sell, end_of_turn | `action` (refresh/buy/sell), `turns` threshold, `feast_attack`, `feast_health` number | At End of Turn, +1 to the count if you didn't do a paid `action` this turn, else 0. At `turns`, gain +`feast_attack`/+`feast_health` permanently and reset. The count is shown on the card (`counters.fast`). | Still-Water Heron |

### 4.4 Golden

A golden unit has double base stats (7.3.4) and its mechanics' **number** parameters doubled when the context is built; **threshold** parameters and `bool`/`unit`/`tribe`/`action` parameters are unchanged (7.3.5). The UI shows `golden_text`. Scripts never check "is golden" except where a card's golden text adds behaviour (`nightshade_on_hit`'s golden defensive mark, `death_summon`'s golden token).

## 5. Combat event log

The core returns a fight as a list of events. The UI plays it back without knowing any rules: it only moves, damages, buffs and removes what the events say. [fixtures/combat_nightshade.json](fixtures/combat_nightshade.json) is a full example.

Common fields: `seq` (0, 1, 2…), `type`. Units are named by `uid` (int, unique within the fight; summons get new ones). `side` is 0 or 1. Slots are ints 0–6 in reading order (0 = F1 … 3 = F4, 4 = B1, 5 = B2, 6 = B3).

| `type` | Fields | Notes |
|---|---|---|
| `combat_start` | `boards`: [side0, side1], each 7 entries of combat unit view (6.3) or null; `first_side`; `player_ids`: [id0, id1] | Always first. |
| `phase` | `name`: "start_of_combat" or "attacks" | |
| `trigger` | `uid`, `mechanic` | A mechanic fires; the UI may flash the card. Followed by its effects. |
| `attack` | `side`, `attacker`, `defender`, `joiners` (uids, Swarm), `strikes` (int), `quick` (bool) | One attack turn. Damage events follow. |
| `skip` | `side`, `uid`, `reason`: "bide", "stalled" | The unit was chosen and didn't attack. |
| `whistle` | `side`, `uid`, `warned` (uids) | |
| `cancel` | `uid`, `reason` | A declared attack didn't happen (Both Ends' prick killed the attacker). |
| `pass` | `side` | 9.4.10: no unit can attack. |
| `damage` | `source`, `target`, `amount`, `raw`, `kind`: "attack", "thorns", "effect"; `strike` (1-based, for Peck), `modifiers` (e.g. ["hunker"], ["shell"], ["whistle"]); `health_after` | `amount` is what landed after modifiers. |
| `health_loss` | `target`, `amount`, `cause`: "nightshade"; `health_after` | Not damage. |
| `status` | `target`, `status`, `on` (bool), `source` (uid or null), `data` (object, e.g. {"n": 4}) | Applied (`on: true`) or removed. |
| `stats` | `target`, `attack_delta`, `health_delta`, `attack`, `health`, `max_health`, `source`, `permanent` (bool) | Any buff or debuff, aura changes included. |
| `slot_mark` | `owner_side`, `side`, `slot`, `damage`, `source` | Mark on an enemy slot. |
| `death` | `uid`, `side`, `slot` | The unit leaves the slot now. |
| `summon` | `unit` (combat unit view), `side`, `slot`, `source` | |
| `combat_end` | `winner`: 0, 1 or -1 (tie); `reason`: "board_empty", "no_attacks", "attack_limit", "trigger_limit"; `survivors`: [uids side 0, uids side 1]; `damage` (to the loser, after cap); `damage_uncapped` | Always last. |

Permanent changes made in combat (Fast doesn't; none of the chosen units do) are carried back by the core, not by the UI.

## 6. State format

The core returns state as plain `Dictionary` values in exactly these shapes (JSON-compatible: ints, strings, bools, arrays, nulls). The UI renders them and never mutates them. Fixtures: [fixtures/recruit_round1.json](fixtures/recruit_round1.json), [fixtures/recruit_round7.json](fixtures/recruit_round7.json), [fixtures/recruit_game_over.json](fixtures/recruit_game_over.json).

### 6.1 Recruit state (`GameSession.get_state()`)

| Key | Type | Meaning |
|---|---|---|
| `round` | int | Turn number, from 1. |
| `phase` | "recruit" or "game_over" | |
| `player_id` | int | The human, always 0. |
| `gold` | int | |
| `tier` | int | |
| `tier_up_cost` | int or null | null at tier 6. |
| `refresh_cost` | int | Cost of the next paid refresh. |
| `paid_refreshes` | int | This turn. |
| `frozen` | bool | |
| `freezes_left` | int | |
| `shop` | array | Shop unit views (6.2), each with `cost`. Bought slots disappear (the array shrinks). |
| `shop_size` | int | Slots this tier. |
| `hand` | array | Hand unit views. |
| `hand_limit` | int | |
| `board` | array of 7 | Board unit view or null, index = slot. |
| `health` | int | The human's hero health. |
| `next_opponent_id` | int | Player id, or -1 for the ghost. |
| `last_combat` | object or null | `{"round", "opponent_id", "winner", "damage"}`; `winner` 0 = you won, 1 = they won, -1 tie. |
| `standings` | array | One per player (6.4), sorted by player id. |
| `placement` | int or null | The human's final place once eliminated or the game is over. |

### 6.2 Recruit unit view

`{"iid", "def_id", "name", "tier", "tribes", "attack", "health", "golden", "origin", "text", "keywords", "counters"}`. `iid` is a stable instance id for the game (for drag and drop and animations). `attack`/`health` include permanent buffs. `origin` is "bought" or "created". `text` is `text` or `golden_text`. `counters` is an object of shown numbers, e.g. `{"fast": 1}`; empty if none. Shop views add `"cost": 3`.

### 6.3 Combat unit view

`{"uid", "def_id", "name", "tier", "tribes", "attack", "health", "max_health", "golden", "text", "keywords", "statuses"}`, where `statuses` is an array of `{"status", "data"}`.

### 6.4 Standing

`{"player_id", "name", "is_human", "personality", "health", "tier", "alive", "placement", "last_result"}`. `personality` is "human", "greedy", "wide", "tribe" or "balanced". `last_result` is "win", "loss", "tie" or null. `placement` is null while alive.

## 7. The API

All core classes are `RefCounted` (no `Node`, no scenes, no autoloads), in `src/core/`, strictly typed, so the core runs headless in GUT tests. The UI holds one `GameSession` or `CombatSandbox` and calls these methods. Actions return `String`: `""` on success, else a short reason the UI can show ("Not enough gold", "Hand is full", "That slot is taken").

```gdscript
class_name UnitLibrary extends RefCounted
static func load_dir(path: String = "res://content/units") -> UnitLibrary
func all_units() -> Array[Dictionary]          # the raw unit files, sorted by tier then name
func pool_units() -> Array[Dictionary]         # pool == true
func get_unit(def_id: String) -> Dictionary    # {} if unknown
func load_errors() -> PackedStringArray        # bad files are skipped and reported here
func unbuilt_units() -> PackedStringArray      # ids of units whose mechanic ids have no script yet

class_name GameConfig extends RefCounted
static func defaults() -> GameConfig
func get_value(key: String) -> Variant         # keys of section 2
func set_value(key: String, value: Variant) -> void

class_name GameSession extends RefCounted
static func create(seed: int, library: UnitLibrary, config: GameConfig = null) -> GameSession
func get_seed() -> int
func get_state() -> Dictionary                 # 6.1, for the human (player 0)
func get_standings() -> Array[Dictionary]      # 6.4
func is_over() -> bool
# Recruit actions (human only). Slots are 0-6 in reading order.
func buy(shop_index: int) -> String
func sell(slot: int) -> String
func play(hand_index: int, slot: int) -> String
func move(from_slot: int, to_slot: int) -> String   # into an empty slot, or swap two units
func refresh() -> String
func toggle_freeze() -> String
func tier_up() -> String
func end_turn() -> String   # runs End of Turn, the bots' turns, all fights, damage, eliminations, next round's start
func get_last_combat() -> Dictionary           # the human's last fight: {"round", "opponent_id", "winner", "damage", "events": [...]} (section 5, fixtures/combat_nightshade.json; "_comment" there is fixture-only); {} before the first
# get_combat_for(player_id, round): deferred, not built tonight (scope review: nothing reads it; question for the owner)
# Dev actions (the dev panel). Same return convention.
func dev_add_gold(amount: int) -> String
func dev_spawn_to_hand(def_id: String, golden: bool = false) -> String   # Created, not from the pool
func dev_set_tier(tier: int) -> String
func dev_skip_turn() -> String   # ends the turn with no fight for the human (no damage either way); bots play and fight as normal

class_name CombatSandbox extends RefCounted
static func create(library: UnitLibrary, config: GameConfig = null) -> CombatSandbox
# A board is 7 entries in reading order: null, or {"def_id": String, "golden": bool, "attack": int, "health": int, "display_name": String}.
# "attack"/"health" are optional overrides of the base stats (to try a tall board); "display_name" (optional)
# replaces the unit's "name" in the combat view (6.3), e.g. "Boar" on a filler unit in a scenario.
func set_board(side: int, board: Array) -> String
func get_board(side: int) -> Array
func set_tier(side: int, tier: int) -> void    # for the damage number only; default 1
func fight(seed: int) -> Dictionary            # {"events": [...], "winner": int, "damage": int}
func load_scenario(scenario: Dictionary) -> String   # both boards and tiers from a ScenarioLibrary scenario; "No such scenario" for {}

class_name ScenarioLibrary extends RefCounted    # content/scenarios/*.json, built from the mechanics library's scenes
static func load_dir(units: UnitLibrary, path: String = "res://content/scenarios") -> ScenarioLibrary
func all_scenarios() -> Array[Dictionary]       # for a list, by library entry then id: {"id", "title", "entry", "units", "watch", "note", "seed"}
func get_scenario(id: String) -> Dictionary     # the full file; {} if unknown
func load_errors() -> PackedStringArray
static func board_of(scenario: Dictionary, side: int) -> Array   # 0 = "mine", 1 = "theirs", as a 7-entry board
```

To show a scenario: `sandbox.load_scenario(scenarios.get_scenario(id))`, then `sandbox.fight(scenario["seed"])`. Show `title`, `watch` (what to look for) and `note` (where the board approximates the scene, because a unit isn't built). A scenario file is `{"id", "title", "entry", "units", "watch", "note"?, "seed"?, "tiers"?, "boards": {"mine": {"F1": unit, ...}, "theirs": {...}}, "expect"?}`. A unit is `{"def_id", "attack"?, "health"?, "golden"?, "display_name"?}`. `expect` lists event field subsets that the fight at `seed` must contain; it is checked by `tests/core/test_scenarios.gd`, and the UI can ignore it. The export must include `content/scenarios/*.json`.

Determinism: the same seed and the same human actions give the same game. The core derives separate `RandomNumberGenerator` streams from the seed per purpose: the pool and each player's shop, each bot's choices, the pairings, and each fight (from seed, round and the pair). Nothing uses the global RNG.

Suggested files (the core worker may change them, not the API): `unit_library.gd`, `game_config.gd`, `game_session.gd`, `player_state.gd`, `pool.gd`, `shop.gd`, `combat/combat.gd`, `combat/combat_unit.gd`, `combat/combat_context.gd`, `mechanics/mechanic.gd` (base class with every hook as a no-op), `mechanics/<id>.gd`, `mechanics/registry.gd`, `bots/bot.gd`.

## 8. Bots

Seven bots play the same recruit actions as the human on their own player state, drawing from the shared pool, each with its own RNG stream. They are not meant to be good; they make the lobby move and give the owner varied boards to fight.

**Every bot, every turn**
1. **Tier up** if its personality says so (below) and it can pay.
2. **Buy**: score each shop unit: `10 × tier + attack + health`, +15 if the bot already has 2 copies (a triple), +8 if it has a tribe it favours (personality), +4 if `row_hint` fits an empty slot. Buy the best while gold ≥ 3 and the hand has space. Keep a personality-specific gold reserve.
3. **Refresh** once if no shop unit scores above the bot's lowest board unit and gold after the refresh is above its reserve; at most 3 paid refreshes a turn.
4. **Play** every hand unit into an empty slot. If the board is full and a hand unit scores more than 3 above the lowest board unit, sell that unit and play the hand unit.
5. **Place**: units with `row_hint: "back"` go to the back row, others to the front; Both Ends units go to F1 and F4 (or B1 and B3); Sett Warden goes to F2 or F3; the highest-Health front units go in F2 and F3. Ties broken by the bot's RNG. Bots re-place their whole board each turn.
6. Bots never freeze.

**Personalities** (the bot's `personality` in standings)

| Personality | Count | Tier-up rule | Buying | Reserve |
|---|---|---|---|---|
| `greedy` | 2 | Whenever it can afford it from turn 2 on, before buying. | Default score. | Saves for the next upgrade when it is within 3 gold. |
| `wide` | 2 | Only on turns 4, 7 and 10. | +6 for tier 1–2 units while it has empty slots; aims for 7 units. | 0 |
| `tribe` | 2 | Turns 3, 5, 7, 9. | From turn 3, picks the tribe it has most of (ties by RNG) and adds +12 for it; never sells a unit of that tribe. | 0 |
| `balanced` | 1 | Turns 3, 5, 7, 9, 11. | Default score. | 2 |

Bot names are "Bot 1" … "Bot 7" plus the personality, e.g. "Bot 3 (wide)".

## 9. Things the prototype just picked

Not decisions. Each is something for the owner to react to after playing. Rule number first.

**Lobby and async**
- **2.1.4 / 2.1.5 (2.1.4 is a decided [BRAMBLE] rule; this departs from it for the prototype):** a live 8-player lobby in one process, not async snapshots. Each bot's "snapshot" is its board at the end of its own recruit phase in the same round. Every round all bots and the human finish recruiting, then all fights run.
- **2.1.5 (OPEN), lobby size:** 8 players, the human plus 7 bots.
- **2.1.5 (OPEN), matching:** each round, random pairing from the seed that avoids each player's last 3 opponents where possible (2.3.2 applied from round 1, since 2.3.1's full round robin needs a schedule); odd count gives a ghost (2.1.2). The human sees the next opponent at the start of recruit (2.3.3).
- **2.1.3:** at round 50 the game ends; places by health, ties by seed.
- **Bots (2.1.4 says bots are outside v0):** the bots of section 8.

**Economy, shop, hand**
- **6.1.1:** with no Tavern spells the shop shows only the units column: 3, 4, 4, 5, 5, 6.
- **7.3.6 (Triple Reward):** playing a triple's golden adds a random unit of tier+1 (max 6) from the pool to hand, Created (4.3.2), instead of a Discover spell. No Discover UI tonight.
- **5.2.2 (OPEN), which types are tribes:** each unit's tribe is the tribe word the mechanics library gives it; the type line shown is that tribe. Snails are neutral.
- **5.2.5 (OPEN), tribes per lobby:** all 7 tribes in every lobby (40 units is too few to subset).
- **5.2.8 (OPEN), traits:** none.
- **8.3.2 (OPEN), minimum front row:** none; any board is legal.
- **11.5.3 (OPEN), back-row access:** no attack reaches the back row early; only effects (Nightshade marks, Mark) ignore rows, as 9.5.6 says.
- **Dev skip turn:** the human doesn't fight that round, takes no damage and deals none.

**Combat rulings** (from the library's rules reviews, section 4.2)
- **Entry 75, Nightshade:** halves once per attack turn, at the start of the exchange, to the unit actually hit; not damage; never kills.
- **Entry 5, Peck:** the target's "when attacked" and Bystander fire once; return blow with the last strike; strikes don't count toward 9.10.1.
- **Entry 4, Shell:** simultaneous hits cap the largest; N kept on golden; two Shells keep the lower N.
- **Entry 1, Hunker:** halves once even if granted twice.
- **Entry 7 / 45, thorns:** Bristle and Both Ends' prick never trigger thorns; Both Ends' prick is effect damage before 9.6.1 step 1.
- **Entry 11, Pin:** applies even if the toad dies in that exchange; a stalled unit's skip passes the turn to its side's next unit.
- **Entry 9, Bide:** a waiting unit's skip passes the turn to its side's next unit in the same turn (it doesn't use the side's turn).
- **Entry 10, Whistle:** a whistle uses the side's turn and counts toward the 200-attack limit; a warning carries across cycles.
- **Entry 25, Swarm:** row only; joiners must be unflagged; Nightshade halves once per joint attack.
- **Entry 24, Weasel Second:** "the unit in front of this" becomes "the units in front of this", because in the 4–3 brick every back slot has two.
- **Entry 40, Mark:** entering damage is effect damage; the mark outlives the Fox Cub.
- **Entry 56, Fast:** Break Fast is left out; only paid refreshes count.
- **7.3.5, golden death summons:** a golden Hoglet Mother summons one golden Hoglet (count kept, token golden).
- **Entry 1, Sett Warden:** "survives" = on the board after that attack's death resolution.

**Content and look**
- **Stats:** firm budget-review fixes are applied ("Change: …"); fixes marked "If the sim agrees" are not, so those units keep their printed stats (Hazel Dormouse 1/3, Mudwallow Toad 2/4).
- **Filler:** 24 plain units with placeholder names, Attack + Health = V(t) from power-budget.md. They exist so shops and the pool work and every tribe has a body at most tiers; they are not designs.
- **Android orientation:** landscape (the project already sets `window/handheld/orientation=0`, 1280×720). The 4–3 brick, the shop row and the hand fit side by side.
- **Heroes:** none; everyone has 30 health and no armor.

**Core worker picks (milestone A, 4 Nov)**
- **9.6.1, 0 Attack:** a unit with 0 Attack deals no damage, so the exchange logs no `damage` event for it (and nothing that fires on dealing damage can fire).
- **3.4.1 / 3.5.1, turn order inside `end_turn`:** every living player's shop fills at the start of the round in player-id order; the human's phase ends first, then each bot takes its whole turn and ends its phase, in id order; then all fights run. Bots therefore draw after the human's buys.
- **4.5.1:** the 5 freeze toggles reset at the start of each Recruit Phase.
- **2.1.2, the ghost:** "most recently eliminated" is the best-placed of the players knocked out in the latest round; before anyone is out (only possible with an odd `players`) the ghost has an empty board.
- **1.1.3 / 6.1, the human knocked out:** the game is over for the human (`phase` "game_over", as in fixtures/recruit_game_over.json); the bots are not played on, so their placements stay null. With `human_bot` set the game runs to one player.
- **CombatSandbox:** no damage cap (the number shown is 10.1.1 uncapped).
- **Section 8, bot reading:** the tribe bot's +12 replaces the generic +8 (no other personality favours a tribe); a unit with no `row_hint` counts as front for the +4; greedy's "saves when within 3 gold" means it buys nothing while 1–3 gold short of its upgrade; the balanced bot keeps no reserve on turn 1 (so it buys), and 2 gold from turn 2.
- **Section 8, step 2:** with no free board slot left (counting the hand), a bot only buys a unit that step 4 would swap in (more than 3 above its weakest board unit), so its hand doesn't fill with units it never plays.
- **`keyword_text`:** each keyword on a card gets the unit's own `source.note` (the Hoglet, Bitter Toad and Ermine Duellist files got the keyword notes they lacked).

**Core worker picks (milestone B, 4 Nov)**
- **Hooks as built (4.1):** only hooks a chosen unit uses exist. `choose_turn_action` returns `""` (attack), `"skip"` (Bide: the side's next unit is chosen) or `"turn"` (Whistle: the turn is used). `on_after_attack` is `on_survived_attack` (Sett Warden). `stat_aura` is `aura`, the bonus a unit gives itself (Both Ends is the only user). Swarm uses a `joiners` query; Whistle uses `acts_without_attack`; Shell and Bide set their status in `setup`. Marks are applied by Combat when a unit enters a slot, with no `on_enter_slot` hook. Fast reads `paid_refreshes` at End of Turn, so there is no `on_refresh` hook. `on_buy`, `on_sell` and `on_start_of_turn` are not built.
- **Entry 75, Nightshade:** Belladonna Sprite's mark passes over enemies that already have Nightshade. The halving happens once per attack, to the defender, after the declaration. Bitter Toad's golden defensive mark is hard-coded, so its file has no parameter for it.
- **9.4.5, skips:** a unit that skipped this turn (Stalled, or waiting with Bide) can't be chosen again in the same turn, even after a cycle reset. If no other unit can be chosen, the side passes.
- **12.2.1, losing a Health aura:** it lowers maximum Health and keeps the damage taken, but never takes Health below 1.
- **Peck and Swarm:** the joiners' hits and the defender's return blow land with the last strike. Swarm joiners must have Attack above 0.
- **Entry 45, Both Ends:** the prick needs the pair in place when the attack is declared. A cancelled attack logs `cancel` with reason `"died_before_attacking"`.
- **Entry 9, Bide:** the "no friendly unit that isn't waiting can attack" check runs when the waiting unit is chosen. Of two Dormice, the first wakes and attacks; the second then waits, because it has an awake friend. Health loss from Nightshade doesn't wake it.
- **Entry 10, Whistle (library text over SPEC 4.2's wording, after the milestone B scope review):** a Whistle unit never attacks, even with Attack, and whistles don't count as attacks for ending combat. A side whose only units have Whistle can't attack (9.9.1), so two such boards, or one facing only 0-Attack units, end the fight at once with reason `no_attacks`. A waiting Bide unit whose only non-waiting friends have Whistle wakes. A Whistle unit still takes its turn in the attack order while the fight goes on, and each whistle still counts toward the 200-attack limit. Ties for highest Attack are broken at random. With no unwarned enemy left, the whistle still uses the turn and warns no one.
- **Entry 24, Quick per exchange:** Quick is checked at each exchange, after the declaration and per Peck strike. A Duellist pricked by Both Ends, or damaged by a Peck's first strike, exchanges without Quick. First Bite is used up by the first exchange. The `attack` event's `quick` field gives the state at declaration.
- **Entry 25, Swarm:** a Stalled unit doesn't join. Joiners must be able to attack (a Whistle unit never joins).
- **Entry 40, Mark:** the mark lasts the whole combat, even after the Fox Cub dies. Placing the mark at Start of Combat is logged as a trigger.
- **Entry 56, Fast:** only board units count. `counters.fast` appears after the unit's first End of Turn on the board. Feast stats are capped at `stat_clamp`.
- **Status keyword text:** each status takes its `keyword_text` entry from one unit's note: nightshade from Belladonna Sprite, stalled from Mudwallow Toad, first_bite from Weasel Second, shell from Garden Snail, warned from Marmot Lookout, waiting from Hazel Dormouse.
- **7.3, triples:** triples are checked after a buy, after a Triple Reward and after a dev spawn, the only ways a copy arrives tonight. The golden is a new instance with its counters reset. Its origin is "bought" if any of the three copies was bought, "created" otherwise; it sells for 1 either way (4.3.4). The Triple Reward is given the first time the golden is played, and never again. It draws with the player's shop RNG. On a full hand it is lost and its copy goes back to the pool (7.1.2). `UnitPool.draw` takes an optional `min_tier` for this draw.
- **Dev actions:** `dev_add_gold` never takes gold below 0. `dev_set_tier` sets the upgrade cost to that tier's base cost. In `dev_skip_turn` the human's opponent also has no fight that round, and `get_last_combat()` is `{}` for the round.
- **QA soak (plan step 4):** `tools/checks/soak.sh [games] [first_seed]` runs `tools/checks/soak.gd`. It plays bot-only full games on the full pool and checks invariants after every round and fight: pool conservation, valid end reasons, no attack limit while units are still dying, no unit left on the board at 0 Health, one unit per slot, goldens at double base and golden parameters doubled, no untripled third copy, and that a `no_attacks` end leaves only Whistle or 0-Attack units. It fails on any violation or Godot log problem. `GameSession.fight_observer` is its hook.
- **Soak finding, no rules change:** in 200 games, 21 of 8667 fights ended `no_attacks` as a draw, every one with only Marmot Lookouts left on both sides (library entry 10 and 9.9.1, as built). No fight reached the attack or trigger limit. This is library entry 10's existing ruling (a side whose only units have Whistle can't attack), so it is for the owner to confirm, not an open question.

## 10. Build order

The core builds a walking skeleton first, then adds one mechanic at a time in the units' `priority` order, each with its own tests. The UI can show every unit from the start; a unit whose mechanic isn't built yet plays as its plain stats, and `UnitLibrary.unbuilt_units()` lists them so the dev panel can show them.

1. **Skeleton:** the 6 units with `skeleton: true` (one plain unit per tier) plus the full recruit phase, pool, combat without mechanics, bots, damage and elimination. The game is playable with only these in the pool (`GameConfig` key `pool_filter: "skeleton"`; default `"all"`).
2. **All plain filler** (every unit with no mechanics).
3. **Library units by priority:** 1 Belladonna Sprite and 2 Bitter Toad (Nightshade), 3 Hoglet Mother (Bristle, death summon), 4 Sett Warden (Hunker, behind), 5 Garden Snail (Shell), 6 Mudwallow Toad (Pin), 7 Fox Notary (Bystander), 8 Weasel Second and 9 Ermine Duellist (Quick), 10 Drumming Woodpecker (Peck), 11 Worker Bee (Swarm), 12 Hedgehog Twin (Both Ends), 13 Hazel Dormouse (Bide), 14 Marmot Lookout (Whistle), 15 Fox Cub (Mark), 16 Still-Water Heron (Fast).

Priority puts the owner's own idea first, then mechanics the owner reacted to well and the position text, then the ones that need the most new plumbing (choosing not to attack, slot marks, recruit counters).

### Skipped from the shortlist

- **Thicket (entry 21):** hedges are targets that aren't units; they change back-row protection, the win check, attack order, adjacency and random targeting at once. A system of its own; next after the 16 if there is time.
- **Dig Down (entry 57):** needs a draw tier separate from the player's tier and a shop that returns to normal at End of Turn. A recruit-phase system the prototype doesn't otherwise need.

### Library gaps

- **Oozes** have only three library units (entry 30, Bud) and Bud needs a split rule the reviews left open, so the Oozes are all filler tonight. The archetypes' amalgamation idea has no library entry yet.
- **Fairies** have 15 library units, but most rely on systems the prototype doesn't have (Changeling swaps sides, Bargain's delayed prices, Rainbow tasks, Foundling triples, Galls); only Belladonna Sprite is in.
- **Tier 4** has no library unit among the chosen 16; the shortlisted mechanics' examples are mostly tiers 1–3.


## Changes after the scope review (4 Nov, orchestrator)

- Cut: `peck_max_strikes` (strikes are per unit), `dev_refill_shop`, `CombatSandbox.fight_many` (no win-rate work). `get_combat_for` is deferred: not built tonight.
- Hooks: implement a hook only when a chosen unit uses it. `on_start_of_turn`, `on_play`, `on_friendly_death`, `on_summon` and `on_end_of_combat` have no user yet. Fast (Still-Water Heron) uses only the `refresh` action.
- Bitter Toad's golden defensive mark is hard-coded; Pin follows the library text (damage from this only).
- **Keyword rules text reaches the player:** both unit views (6.2 and 6.3) gain `"keyword_text": [{"keyword", "text"}]`, filled from each unit's `source.note` (and the status names for statuses). The UI shows it on the full card, so the owner can play without the library open.
- **Recruit-phase auras:** the recruit view shows a unit's own stats; combat-only auras (`stat_aura`, e.g. Both Ends) apply in combat and are listed on the full card, not added to the recruit numbers. A prototype pick.
- The `priority` field stays in the unit files for now; SPEC §10 is the source of truth for build order.
