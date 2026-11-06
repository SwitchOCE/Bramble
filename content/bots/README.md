# What bots know

The rules live in the cards. This folder holds what a bot can't read from them: what a card's text is worth, where a card wants to stand, and which builds exist. Adding a tribe means adding lines here and no code. `src/core/bots/bot_knowledge.gd` loads it; a GUT test checks that every id named here exists.

## strategies/<id>.json

One named build. A bot pinned to it (`hard:<id>`) plays it always. Unpinned Normal and Hard bots pick among the strategies whose `needs_tribes` are in the lobby.

| Field | Meaning |
|---|---|
| `id`, `name`, `shape` | Who it is. `shape` is the archetype, for the report. |
| `needs_tribes` | Tribes the lobby must have. |
| `tribes` | Tribe -> points added to any card of that tribe. |
| `units` | Unit id -> points added to that unit. Negative to avoid it. |
| `spells`, `heroes` | Id -> points added. |
| `curve` | The turn to reach tier 2, 3, 4, 5, 6. |
| `max_units` | Slots it means to fill. |
| `save` | `[[until_round, gold], ...]`: gold it keeps back. First row that applies wins. |
| `larder_value` | Points each gold of held items is worth, before any cards say more. |
| `pin_only` | Never chosen by an unpinned bot (test bots). |

## cards.json

`cards` by unit, spell or item id; `heroes` by hero id. Points are stat points: +1 Attack or +1 Health is 1.

Cards: `keep` (text's worth on the board), `buy` (worth on buying, if different, as for on-play text), `row` (`front` or `back`), `pin` (don't move once it's counting), `pins_board` (nothing moves while this stands), `shy` (never aim stats at it), `aim_at` (`carry`, `weakest`, `shy`), `value` (a spell's worth), `avoid` (don't buy), `larder_value` (points per held gold while this is on the board).

Heroes: `rating` (points when choosing), `power` (`spare`: when gold is left over, `always`, `never`), `save`.
