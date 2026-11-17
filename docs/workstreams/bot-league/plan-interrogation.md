# Plan interrogation of the bot league brief (18 Nov 2026)

A fresh Opus agent, which did not write the brief, ran `~/.claude/skills/plan-interrogate/SKILL.md` on the first draft (commit `db90bc46`). It was given the owner's words of 18 Nov, quoted in full. It checked the brief's technical claims against the code. Below is its result, shortened, with what the brief now does about each point.

## Fix before approval (all taken)

| Point | Now in the brief |
|---|---|
| `session.seed_value` is public, and every shop, pairing and fight seed comes from it through `Rng.derive` and `Rng.hash32`. So a bot could predict its shops and opponents, and replay can't catch a pure read. | Section 5's information rule bans the seed and the random streams. The code scan looks for them. |
| `take_turn` can be overridden. Thinking in `_init`, in a hook, or on a `Thread` dodges the clock. `Engine.set_meta` shares memory between seats. | The harness runs the turn loop itself and times every call into the bot. `Thread`, `WorkerThreadPool` and `Engine.set_meta` are banned. |
| A Discover pick can't be tribe-locked without changing `src/core`. Refusing an off-tribe buy ends the bot's turn. Spells weren't covered. | The harness filters the legal actions it hands the bot. Off-tribe Discover picks are allowed. Spells are allowed. |
| The tribe left out of a game stays in the pool unless `lobby_tribes` is passed. | The harness passes `lobby_tribes` to `ContentSet.session`. |
| The scan missed `session.units`, `spells`, `events`, `fights`, `recruit` and `seed_value`. | The scan list now has them. |
| The timeline assumed 1-hour matches. Teams will use the whole clock. | Matches are planned at the worst case. The whole league takes about 22 hours. |
| Per-tribe numbers mix tribe power with the effort each team put into that tribe. | Each team's notes give its effort per tribe. Stats are also read from the team whose bot plays that tribe better. |
| A `bots/` folder at the project root would go into the export and the gate. | Bots now live in `tools/league/bots/`. |

## Cut or shrunk (all taken)

- **Free-play exhibition: cut.** The bots weren't built for free play. A free-play league is now a follow-up.
- **Spot-check state hashing: cut.** Full replay already catches a bot that changes the game.
- **Transcript search: cut.** Copying is allowed after each match anyway. The isolation rule stays.
- **Anchor run: once, after match 3,** not every match.
- **Planted cheats: three** (adds gold, reads another player's hand, `static var`).

## Asked of the owner (in the brief's section 12)

1. No ghost warm-up. The interrogator recommends accepting it.
2. Tribe-locked seats. It calls this the biggest change from "anything they want".
3. Whether the owner's merge gates apply inside a team's round. It recommends they don't.
4. Stops for the owner after phase 0 and after match 1, in place of "don't wait". Both are now in the brief.
5. The time dials.

## Kept

- 1,000 games a match. It checked the maths: ±0.054 on a team's average and ±0.11 on the gap.
- Seed pairs with the colours swapped.
- Wall-clock rounds with equal caps.
- Copying allowed.
- The A/A match and the smoke run.
- Full replay, the diff check and the opposing audit.
- The stats list.
- `results.md` built around the ten findings, with the findings table now in every match report.
- No card changes.

# Second interrogation: version 2, free play (18 Nov 2026)

The owner turned down version 1's tribe-locked seats and asked for engine-style bots. A new fresh agent ran `plan-interrogate` on version 2 (commit `cafd01cf`), given both sets of the owner's words, and checked it against the code. It found that version 2 answers the rejection: free play, plus the harness's log of every offer and Discover pick, show "a weighting of 0" and "everyone buys the Pigeon tier 1s" directly. What changed from its result:

| Point | Now in the brief |
|---|---|
| Bots reported only their top values, but a card weighted 0 is a bottom value. | `report()` gives a value for every card on offer, in every shop and Discover choice. |
| Raw table values can't be compared across teams. | The results compare each team's rank for a card within its shop, plus buy rates. |
| The tables-against-play check was circular. | Cut as a cheat check. It is kept as a descriptive stat; hidden rules are left to the opposing audit. |
| The reason given for requiring tables was wrong (the verdicts come from the harness's logs), and the owner said "maybe strategy tables". | Value tables are required. Strategy tables are encouraged. Section 12.2 gives the corrected reason. |
| The naive numbers were played without the game's 3 stand-in spells. | The A/A match runs `TribeBot` on the frozen harness, and that is the naive column. |
| "By main tribe" is not "seat locked to a tribe", and bots commit when a tribe is going well. Early main tribe is noise. | Buy rates are split by the final main tribe. The results say plainly that the two measures differ. |
| The pivot rule flipped on ties. | A pivot now means another tribe reaches 4 or more units after the commit round. |
| Unaffordable offers would inflate "never bought". | Only buyable offers count. |
| Past-opponent boards alone get Pigeons and Briars wrong. An honest lookahead could change the real game and trip the replay. | Seats get full fight payloads (slots, counters, heaps, Reserve hand). Lookahead uses `live=false` and never `session.new_unit`. |
| A bot could work out a small sequential seed from its own random stream or its first shop. | Seeds are random 31-bit numbers. Bot streams aren't derived from the seed. The scan covers building sessions and dynamic calls. |
| Teammates shared one parsed table. | Each seat gets a deep copy. |
| The report call went the wrong way. | The harness calls the bot's `report()`, timed on its clock. |
| Commit triggers came from the bots' own reports. Strategy stats were compared across teams. | Commit triggers come from what the harness sees. Strategy stats are per team. |
| Phase 0 carried the full stats script. | Phase 0 freezes the log format, the score and the health checks. The rest is written during round 1. |
| Tribes nobody plays can't be judged. | At the match 1 stop, each tribe's share of final boards is shown, and a probe is offered. Nothing is built unless the owner says yes. |

# Goal review by a Fable reviewer (18 Nov 2026)

At the owner's request, a Fable reviewer judged the third revision against the owner's goal ("to build strong bots ... by having it be an opposed situation"), not against process. Its verdict: the plan only partly served that goal. What it found, and what the owner decided:

| Finding | What happened |
|---|---|
| Too few practice games: 2 GDScript processes give a team only 4–8 measured decisions a round. | The owner had the engine ported to Rust as the referee's first job, so practice games are cheap. |
| Opposition only bites at three matches; inside a round each team hill-climbs alone. | Score-only practice matches against the other team, mid-round. |
| Nothing shows the bots are strong, only better than each other. | Strength checks: a progress ladder against earlier tags, behaviour checks, a fresh challenger after match 3, and the owner playing them (offered). |
| Copying code makes the bots converge, and loses the independent-agreement signal. | The owner: no code swap, only a high-level method swap written by the referee. Agreement between the teams is reported every match. |
| The native-language rule spent build hours and saved no time while the engine was GDScript. | Superseded by the port: engine, harness and bots are all Rust. |
