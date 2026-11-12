# Brief: Battlegrounds units by tier, role and value per turn

You are one of five workers. Together we are building a report on what Hearthstone Battlegrounds (HSBG) units are actually worth, so that Bramble (a Battlegrounds-style game) can set a simple power budget for new tribes. Your batch is named in your prompt.

## The owner's question, in their words (12 Nov)

> "look at Battlegrounds units by tier and kind of guess at how their power budget kind of works ... what are their strong tier 6 units giving in terms of stats per turn in a good setup ... or stats per effect compared to a tier 4 unit that's existed in the past that does similar things ... how many stats, if you had to guess, is a unit worth per turn versus a composition that was trying to use it, a similar thing without it ... what the kind of different types of units are that each tier ... categorize them into different types, look at what the roles they play in compositions are."

The owner's own tier picture, which the report tests:
- **Tier 6:** "big, impactful ... a capstone. Like a pivotal engine piece or a big scaling payoff for an engine."
- **Tier 5:** "strong enough to give you strategic direction or a lot of tempo to buy you time to find strategic direction."
- **Tier 4:** "a strong player in a composition that sets up future things, enables, gives you some stats, a little bit."

The owner wants rough, honest guesses with the working shown, not false precision. A guess with its assumption written down is the goal.

## Inputs (read-only)

- Your batch: `in/<batch>.csv`, with printed stats, tribes, keywords, normal and golden text.
- Context in `/home/alex/code/Bramble-ideation/docs/research/battlegrounds/`:
  - `rules.md`: the economy is 3 gold on turn 1, +1 a turn to 10; minions cost 3.
  - `power-analysis.md` §1–2: printed-stat medians are T1 4.5, T2 6, T3 7, T4 9, T5 10, T6 12.5.
  - `economy-engines.md`, `strategy-eras.md`, `patch-history.md` and `keywords.md`.
- Your own knowledge of HSBG play is welcome. Say when a value rests on it.

## For each unit, give

| field | meaning |
|---|---|
| `name`, `tier`, `tribes`, `text` | from the CSV (text may be shortened; keep the numbers) |
| `role` | primary role, from the list below |
| `role2` | secondary role, or "" |
| `comps` | the compositions or strategies that play it, e.g. "Elemental shop-buff", "Undead attack", "Beast deathrattle", "Menagerie", "any (tempo)" |
| `window` | the turns it is usually bought and held, e.g. "T5–T9" or "T10+" |
| `value_kind` | one of: `per_turn` (permanent stats every recruit turn), `one_off` (permanent stats once), `in_fight` (value only during combat), `economy`, `multiplier` (repeats or doubles other effects), `tech` (an answer to a specific threat), `body` (mostly printed stats) |
| `sp_per_turn` | permanent stats (Attack+Health summed over your whole board) this unit adds per recruit turn **in a good setup at its normal stage**; 0 if none |
| `sp_one_off` | permanent stats added once (battlecry, buy or sell effect); 0 if none |
| `sp_in_fight` | the stat value it adds inside one typical fight (summons, shields ≈ one enemy hit avoided, deathrattle bodies, in-combat buffs); 0 if none |
| `gold_per_turn` | gold or gold-equivalent a turn (1 refresh = 1 gold; 1 extra card ≈ 3 gold); 0 if none |
| `marginal_sp_per_turn` | **the key number:** how many stats per turn its composition gains with this unit, compared with the same composition using its best usual alternative in that slot. For multipliers, the extra stats the doubled effects add. For economy, convert at about 3–4 SP per gold at its stage, and say so. |
| `setup` | the one-line assumption behind the numbers, e.g. "Elemental board, buys 2 Elementals a turn, turn 9" |
| `basis` | short arithmetic, e.g. "+2/+2 to 2 bought Elementals ×2 turns held… = 8/turn" |
| `compare_to` | a similar unit at a lower tier, or from the past, that does a similar thing (name, tier), and its rough `sp_per_turn` or marginal value in the same setup, e.g. "Lullabot T1: ~2/turn" |
| `premium` | one line: what this tier buys over that comparison (more stats per trigger, more triggers, a multiplier, a capstone loop…) |
| `strength` | `staple` (core of its comp, or broadly strong), `solid`, `niche`, `weak`, or `was_overtuned` (nerfed or removed for strength; say when in `basis`) |
| `confidence` | `low`, `med` or `high` |

### Roles (pick one primary)

- `tempo` — mostly stats or keywords; wins fights now.
- `economy` — gold, free refreshes, extra cards, discovers, tier-up discounts.
- `enabler` — produces what a comp feeds on (tokens, deathrattles, spells, battlecries, Blood Gems, a tribe count).
- `buffer` — gives stats to other units in the recruit phase (one-off or per trigger).
- `scaler` — grows itself or one carry turn after turn.
- `payoff` — turns the comp's resource into large stats or damage.
- `multiplier` — repeats or doubles triggers or effects (Brann, Baron, Rivendare, Titus style).
- `combat_engine` — value inside fights: summons, deathrattle chains, avenge, sticky bodies, combat buffs.
- `tech` — an answer to a threat: Venomous, cleave, shield breaking, anti-summon.
- `capstone` — a unit that defines an endgame or closes a loop: the comp is built to reach it.

## Then, for your batch, a `tier_notes` object for each tier you cover

- `role_mix`: the count of units per primary role.
- `typical`: what a typical unit at this tier gives, as a range of `marginal_sp_per_turn` and a range of `sp_one_off`, in one line.
- `strong_units`: the 5 units that matter most at this tier, with their marginal value.
- `owner_picture`: does the owner's tier picture hold for this tier? Answer `yes`, `partly` or `no`, with 2–3 sentences of evidence and the units that break the pattern. For Tiers 1–3 (no owner statement), write the tier's job in one sentence in the owner's style instead.

## Output

Write one JSON file: `out/<batch>.json` = `{"batch": "...", "units": [...], "tier_notes": {"4": {...}}}`. It must parse with `python3 -c "import json; json.load(open('out/<batch>.json'))"`. Every unit in your CSV appears once. Don't commit, and don't change any file outside `out/`. Report in under 150 words: unit count, the three biggest surprises, and anything you couldn't value.
