# What bots know

The rules live in the cards. This folder holds what a bot can't read from them: what a card's text is worth, where a card wants to stand, and which builds exist. `src/core/bots/bot_knowledge.gd` loads it; a GUT test checks that every id named here exists. Shared lane rules in `BotLanes` read the actual mechanics: Mire and quarry ownership, Pack adjacency, lending and Pounce. They use only the next opponent's public scout.

Bog folk have the Bitter Swamp (wide Soak and Toll answers), the Bog Court (a Tiddy-fed carry beside a frog), and the Borrowed Bog (Chorus lending Mire and Soak to Bog walls). Their strategy ids remain `bog_bitter`, `bog_tongues` and `bog_borrowed`. Hunters have Open Season (front quarries and Takes), the Sett (Brock's back-row reach and Pounce), and the Pact (Pack and Grizel). Each has its own unit priorities and tier curve. Mirers may choose either row to catch the scouted attacker; other row hints, pinned units and occupied Nests still matter. Generic carries keep their slot during Hard's speculative fight search, leaving useful landmarks for the next opponent's scout.

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

Cards: `keep` (text's worth on the board), `buy` (worth on buying, if different, as for on-play text), `row` (`front` or `back`), `aim_at` (`carry`, or `in_front`/`behind`: the slot whose neighbours are best fed), `faces` (`across` or `behind`: stands against the best enemy scouted), `cast_last`, `value_per_gold`, `sell_at_bands`, `sell_late_round`, `sell_late_bands`, `value` (a spell's worth), `avoid` (don't buy), `larder_value` (points per held gold while this is on the board), `fly` (what one trip south earns), `on_nest` (played onto a Nest if there is one), `next_to` (a tribe it wants to touch when played), `keep_empty` (no unit goes in this Belly).

Heroes: `rating` (points when choosing), `power` (`spare`: when gold is left over; `borrow`: only to make a climb; `never`), `save`, `max_units`.

Turn counts, timers, bands, Shy and Acorn eating are read from the rules, not written here.

Commitment spells use the current board in `BotCommitment`: kin columns are worth twice an off-tribe column, Harvest Supper values owned units plus future replacements and stops at its cap or after one cast that turn, and Hiring Fair gains value with five units of a tribe on the board. Units offered by shops and Discovers include the standing tribe bonus in their purchase value. Owned units already include it in their stats. Ooze and Bird builds use the Parish's tribe weight (5). Oozes keep their measured Hard power prior 8; redesigned tribes start with provisional priors.

Pass 3 Birds value a trip from its configured homecoming gain and the body missing this fight. Hard leaves three units home, flies the Goose before smaller payoffs, waits for two Birds away before flying Old Tern, and keeps all seven different Birds home for the Whistlers. At low Health the biggest Bird stays. The Lump takes the largest empty Nest and stays on it; the Golden Egg targets the biggest eligible Bird.

Pass 3 Fairies keep the existing strategy names. The Long Dance and Hag routes feed one Ring carry with Annis in F1 and Fetch in F2. The Rainbow and Hired Help routes spread with Annis in F2 and keep cheap tithe food behind the Queen. Ring spells complete the seven-slot rainbow before stacking the largest back-row Ring. Surplus gold buys, plays and sells spare units through Annis in a flex slot. Cluricaun is valued on remaining tier-ups; Fetch, the Monarch and holders read the current Ring board. Shy departures value Lob's actual bank and the strongest Silky's single shared growth.

The old measured route priors no longer describe these redesigned cards. Bird and Fairy strategies start with the same provisional power prior of 3; the harness can measure replacements after merge.

Pass 3 Bog uses `BotBog` for board-aware text values and the shared lane planner for placement. Hard retains one live Tiddy and frog, its grown carry, and the Swamp's Nan and useful Chorus. The court feeds one carry from a row end; the Swamp places Tiddy between two Bog units. Frogs favour large neighbours of any tribe, with overlapping doubles valued once; Chorus favours large Bog neighbours without Soak. Hopkin stands behind a strong front attacker. The scout forecast reserves Lantern identities, then applies Jenny's row pull before ordinary patches, including deferred targets inside Bellies. A surviving carry drinks the giant; Bufo takes it when its Attack exceeds twice the carry's Health. Soak avoids Eggs, empty lanes and zero Attack. The court holds its first Highness only until a neighbour can reach twice the board median, or round 10; other routes play immediately. A full Peat King board sells a replaceable unit for a gap only when a scouted early Sink is worth more than twice that body and a sturdy front will otherwise leave no gap. Bog's redesigned strategies also start at provisional power 3.

The four round-five cards use current-board values in `BotContent5`. Horseshoe waits for a scouted Ring, chooses the slot across from the largest one and skips lanes already marked for the next fight. Barn Owl values back-row targets, refuses quarry loans and avoids front-row Mire bindings. Redwing values the extra Egg stats it actually supplies, stands beside useful Nests and counts the support lost if it flies; flight and Egg-cover decisions share the engine's Egg forecast. Market Stall is an investment while healthy, stops at two and skips a capped ordinary shop; Pipkin can still value the extra spell slot. All three Bird strategies include Owl and Redwing, with the strongest Owl preference in Highway and Redwing preference in Summer and Winter. The replacement Bird route priors are provisional.

Pass 2 changes card hints and card-specific values without changing strategy routing. Shy ignores indirect gifts, so Burners, tribe bonuses and placement no longer predict an accidental departure. A deliberate aimed spell compares the lost unit against next-turn gold and Ring growth. Tom Tit values its protected Bird; Lamp Moth values only a usable upgrade discount. Stone Soup makes one recruit swallow worth considering while its growth is unused, after four bodies are already on the board.
