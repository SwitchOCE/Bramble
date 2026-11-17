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
