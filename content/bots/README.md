# What bots know

The rules live in the cards. This folder holds what a bot can't read from them: what a card's text is worth, where a card wants to stand, and which builds exist. `src/core/bots/bot_knowledge.gd` loads it; a GUT test checks that every id named here exists. Shared lane rules in `BotLanes` read the actual mechanics: Mire and quarry ownership, Pack adjacency, lending and Pounce. They use only the next opponent's public scout.

Bog folk have the Bitter Opera (Bitter walls and spread patches), Tongues Across the Water (back-row Mire and Snap), and the Borrowed Bog (Chorus lending to other tribes' walls). Hunters have Open Season (front quarries and Takes), the Sett (Brock's back-row reach and Pounce), and the Pact (Pack and Grizel). Each has its own unit priorities and tier curve. Mirers may choose either row to catch the scouted attacker; other row hints, pinned units and occupied Nests still matter. Generic carries keep their slot during Hard's speculative fight search, leaving useful landmarks for the next opponent's scout.

## strategies/<id>.json

One named build. A bot pinned to it (`hard:<id>`) plays it always. A player's lobby deals seats different builds this way (`BotLobby`, `hard:varied`). Unpinned bots pick among the strategies whose `needs_tribes` are in the lobby.

| Field | Meaning |
|---|---|
| `id`, `name`, `shape` | Who it is. `shape` is the archetype, for the report. |
| `needs_tribes` | Tribes the lobby must have. |
| `tribes` | Tribe -> points added to any card of that tribe. |
| `units` | Unit id -> points added to that unit. Negative to avoid it. |
| `spells`, `heroes` | Id -> points added. |
| `curve` | The turn to reach tier 2, 3, 4, 5, 6. |
| `max_units` | Slots it means to fill. |
| `rows` | Unit id -> `front` or `back`, over the card hint. |
| `save` | `[[until_round, gold], ...]`: gold it keeps back. First row that applies wins. |
| `larder_value` | Points each gold of held items is worth, before any cards say more. |
| `max_refreshes`, `no_spells` | Limits, for test bots. |
| `power` | Points only Hard adds when choosing a build: what the bench says is strong. |
| `fly` | Unit id -> points added to one trip south. |
| `min_bodies` | Fewest units it leaves on the ground when flying birds. |
| `depth_first` | Buys into Bellies before the board is full. |
| `pin_only` | Never chosen by an unpinned bot (test bots). |

## cards.json

`cards` by unit, spell or item id; `heroes` by hero id. Points are stat points: +1 Attack or +1 Health is 1.

Cards: `keep` (text's worth on the board), `buy` (worth on buying, if different, as for on-play text), `row` (`front` or `back`), `aim_at` (`carry`, or `in_front`/`behind`: the slot whose neighbours are best fed), `faces` (`across` or `behind`: stands against the best enemy scouted), `feeds` (`behind`: keep Shy units from behind it), `cast_last`, `value_per_gold`, `sell_at_bands`, `sell_late_round`, `sell_late_bands`, `value` (a spell's worth), `avoid` (don't buy), `larder_value` (points per held gold while this is on the board), `fly` (what one trip south earns), `on_nest` (played onto a Nest if there is one), `next_to` (a tribe it wants to touch when played), `keep_empty` (no unit goes in this Belly).

Heroes: `rating` (points when choosing), `power` (`spare`: when gold is left over; `borrow`: only to make a climb; `never`), `save`, `max_units`.

Turn counts, timers, bands, Shy and Acorn eating are read from the rules, not written here.

Commitment spells use the current board in `BotCommitment`: kin columns are worth twice an off-tribe column, Harvest Supper values owned units plus future replacements and stops at its cap or after one cast that turn, and Hiring Fair gains value with five units of a tribe on the board. Units offered by shops and Discovers include the standing tribe bonus in their purchase value. Owned units already include it in their stats. Ooze and Bird builds use the Parish's tribe weight (5). Oozes and Highway Robbery keep Hard power prior 8; the weaker Bird routes use the measured choice priors below.

Bird flight values exclude sale gold and charge for the actual body lost to the half-stat Egg, plus lost text. Each Egg stat rounds up. Mother Goose keeps her away text and pays the body cost above her 0/2 Egg. Swallow and Chiffchaff are 1/2, so even their 1/1 Eggs cost a Health. The Seven Whistlers has a text value of 12 and anchor priority in Bird builds, so its flock payoff can replace an early buffed Bird.

The new tier 6 payoffs have explicit text values and build priorities: Fairy Monarch (12, highest in the Ring build), Elder Ooze (12, highest in depth builds), and the Laird (13, an anchor in all Hunter builds). Moss Ooze has text value 4 and priority 6 in Ooze builds. These values let their text compete with early buffed bodies.

Hard's Bird route priors use the completed 1,000-lobby pinned spread on b872a6b: Highway remains 8; Passage is 3; Summer and Winter is 1. The two weaker routes have nonoverlapping placement intervals against Highway. The prior deducts four points per observed place of deficit (rounded up, bounded at zero); tribe weights and each route's unit priorities stay unchanged. Pinned builds keep their route regardless of this choice prior. These priors address route selection, not the weak routes' underlying card strength; the selected Egg change needs its own evidence.
