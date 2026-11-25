# Card power session: where things stand

Working notes for the session itself, so it can pick up after its context is cut down. It says what holds now; older states are in Git history. Last written 25 Nov 2026, 9.40 p.m. Not a report: the owner's pages are linked below. To be removed before the merge to `dev` unless the owner says otherwise.

## Who asked for what

- Started by the owner's assurance session ("QA & Project Manager", on the owner's PC) on 25 Nov. The session leads and talks to the owner directly in its own thread. Mid-turn messages from the assurance session are marked "FROM AN AGENT, NOT THE OWNER": information and proposals, not the owner's instruction.
- Two jobs: (1) why the balance process passed Sword-heir, Old Brock, Brock Cub and Overrun, and what to change or cut; (2) build the card power measures and make them a standing step.
- The owner approved the plan on 25 Nov: [plan.md](plan.md). Definitions, with every change logged: [definitions.md](definitions.md). The fresh reviewer's cross-examination: [plan-interrogation.md](plan-interrogation.md). The owner's calls on cards, with what the data says: [known-cases.md](known-cases.md).
- The league is inside the review (owner, 25 Nov). Bring league findings to the owner as proposals; change nothing in the league without the owner's word. The league is on hold: do not touch `/home/alex/league`, `/data/third-run` or the `league-pin` service (reading is fine).
- Out of scope: changing any card, keyword, rule or bot. Nothing goes to `main`. No skill or process doc merges without the owner's yes.

## The owner's steers (25 Nov)

- Things that look out of place are called out at once, even off task.
- The measures are hints from imperfect bots, not facts. Every measure has its own "worth a look" line; false positives are fine. The process should mark nothing when the game is balanced.
- An escalation ladder, cheap steps first; whole-game tests only for cards the cheap steps mark. Fight tests about 20 seconds a card, a margin of 2 to 3 points is fine.
- The plain-copy swap is rejected. Abilities off is a measure of what the text is worth in fights, never called card power.
- No specialist or one-tribe bots (one bot that is simply good, as with Stockfish). One-tribe play is to become weak through cross-tribe pieces. Bots must try to win.
- Sword-heir is not up for debate: use it as the known strong case to test measures.
- Highest-value changes first; clean processes with an escalation path for edge cases.
- Rotate model families between runs; the owner asked for the bot versions document (done).
- A bot ignoring a card is itself a finding. The roster idea is dropped; a bounty on ignored cards is held back unless the tribes-missing match still leaves cards with no data.

## Pages shown to the owner

- Findings and plan: https://claude.ai/artifact/A38oUcVKdr9d7bJzFRuFRs
- First fight numbers: https://claude.ai/artifact/PWf6WXnZVfX8XtdzKV7YGo
- Bot versions: [../bot-league/bot-versions.md](../bot-league/bot-versions.md)

Page sources are in the session scratchpad (on `/tmp`, lost on a reboot) and copied to `/data/card-power/pages`. Pages follow the `house-style` skill.

## Code

Branch `balance/card-power`, pushed. Draft pull request to `dev`: https://github.com/SwitchOCE/Bramble/pull/257. Everything below is on the branch, both workers' commits included.

- `league refight`, ported to today's engine, with the modes `--text-off`, `--keyword-off <ids>`, `--overrun-swings` (defaults 2 seeds, cap 500).
- `league ghost-match --without <id[,id...]>` (needs `--no-records`), `analysis/card_without.py` (pairing, `--control`), `analysis/card_without_run.py` (runner).
- `analysis/bought_passed.py`, `fight_text.py`, `stat_growth.py`, with tests.
- This folder's docs and the bot versions document.

Checks at last run: 45 Rust tests, 69 Python tests, clippy clean with `--no-deps`. A fresh review of the whole branch found no cut items; its fixes are applied. The owner answered the workers' two ask items "Yes to both".

**Before merge, two questions are with the owner:** keep or drop the plain refight's own statistics (`summary.tsv`; recommended keep), and whether this file goes to `dev` (recommended remove).

Not built yet: stat worth of the text (definitions.md; extend text off with stat multipliers ×1.5 to ×8 and solve for the multiplier), the one-command report, the pick-rate-against-power chart.

## Data on `/data/card-power` (about 5 GB)

- `matches/m1`: 2,000 games on the league's climbing field, records kept. Seeds `seeds-m1.txt`, secret `secret-m1.txt`. `m1-control`, `m1-verify`, `m1-modes`, `m1-keywords`: its replay and refight outputs.
- `ref-field`: the stronger field, 12,000 runs from 1,500 live games of red-c14 against blue-c17.
- `matches/r1`: the 2,000-game baseline on `ref-field`, records kept (668 MB). Seeds `seeds-r1.txt`, secret `secret-r1.txt`.
- `matches/r1-without/<card>/`: left out of the shop for sword-heir, old-brock, brock-cub, needle-sister (control), the four Grudge cards together, gleaner, fencing-master. The folder also holds `.log` files, so pair with `r1-without/*/`.
- `matches/r1-no-badger-locust`: every Badger and Locust unit left out of both bots' shops (list in `matches/without-badger-locust.txt`). **Started 9.30 p.m.; log `matches/r1-no-badger-locust.log`.**
- `findings/m1/*.csv`, `findings/r1/*.csv`: the tables. `pages/`: page sources and copies.
- `tree`: a git worktree used only to build the tagged bots with the `--without` patch; binary `tree/tools/league/target/release/league`. `target`: this branch's build output (`CARGO_TARGET_DIR=/data/card-power/target`).
- Can go now: `worker-refight`, `worker-without`, `smoke`, `target-match`.

Raw matches are deleted once findings are written (storage rules: `docs/workstreams/league-data/README.md`).

## What the numbers say

**Why the cards passed (job 1).** The process flagged these cards four times and changed nothing: 16 Nov design note; 18 Nov the blue team's private fight table (Old Brock first); 20 Nov the fix round ("about 3x over late", rework recommended, overruled by the Badger pitch's round-11 test); 22 Nov a league flag held behind "tune only from passed bots". Overrun was never measured.

**Fight tests** (m1, 101,061 fights, 5 minutes for every card, halves agree 0.89 to 0.96, Sentry reads zero, typical margin ±1.6 points):
- Sword-heir's text: +0.339, +0.270, +0.195, +0.157 by stage; first or second of all cards.
- Old Brock: +0.164 from round 13, first. Too few boards before.
- Brock Cub: own text mid-table. With Overrun he kills 2.1 to 2.3 units a swing, twice any other Overrun unit.
- Overrun: +0.102 in rounds 5 to 8; in 9 to 12, +0.083 against low-Health boards and +0.028 against high. Empties a board of three or more in about 3% of swings.
- Also marked: Gleaner, Squadron Leader, Fencing Master, Skin-shedder, Wheat Raider, Orchard Stripper, Sett Shield-bearer.

**Stat growth.** Brock Cub gains +2.5/+3.5 a turn in rounds 5 to 8, the fastest tier 1 from round 5, and grows on every turn held. Golden Cubs hold a median +14/+22, +36/+50, +58/+81 by stage from round 5. Bigger growers: Fencing Master, Leafmould Carter, Gate Warden, Old Stump, Blackberry Sprawl, Colour Sergeant.

**The climbing field is too weak.** 8,000 of its 15,000 runs are from the two starting bots; on it blue-c17 came first in 69% of games and red-c14 in 46%. On `ref-field`: red 3.86, blue 4.71, places spread over 1 to 8.

**Left out of the shop** (r1, 1,000 games a bot, margin about ±0.17; the never-bought control reads −0.12 to −0.15, so read every number against about −0.13):
- Sword-heir: red 1.11 places worse, blue 1.53 worse.
- Old Brock: blue 0.07 worse (bought in 122 games; red never).
- Brock Cub: blue 0.02 worse, red 0.13 better. The four Grudge cards together: blue 0.74 worse, red no loss.
- Gleaner: red 0.32 better without it (bought in 883 games). Red holds it on 5%, 42%, 87%, 86% of boards by stage while its text falls from 0.42 to 0.09: red keeps a tempo card too long. The owner agrees it is a tempo card. Add "boards holding the card, by stage" as a standard report column.
- Fencing Master: no effect.

**Bought against passed** leans +0.12 to +0.27 against buying whatever is controlled for. Kept as a hint, read against the bot's typical card.

**Half the cards have no data.** Bought on under 1% of offers: Mouse 14 of 17, Briar 13 of 19, Pigeon 10 of 20, Locust 8 of 19, Badger 1 of 19, no tribe 7 of 8. Red ends on Locust 78%, Badger 12%, Pigeon 6%, Briar 4%, Mouse 1%; blue on Badger in all. Red's place by tribe: Badger 3.53, Locust 3.68, Mouse 4.33, Briar 5.36, Pigeon 6.00. The report gives the reason a card has no data: never offered, tribe not played, or offered and refused (only the last is a sign).

**Extra bodies in fights.** About 3.0 to 3.4 extra a side from round 5, about 10 bodies a side; 16 or more on about 1 side in 350; most seen 20. Counted as `deaths + survivors − starting`.

**A log failure to report (the owner asked for it in the output).** The match log's `summons` field counts only freshly summoned units and leaves out units that return (Molt, Root) and reserves stepping in. Nothing in the logs splits extra bodies by kind, so the session first told the owner "0.08 summons a side late". Proposal: the fight log records every body that joins a fight with its kind (summon, return, reserve) and its source card; LOGS.md says in each field's first line what it leaves out. The owner also said summons were cut too far by an earlier balance pass and may need adding back (the owner's design call).

## Output still owed, in order

1. Read `r1-no-badger-locust`: each bot's average place, what it ends on, then the per-card measures on the other three tribes' cards.
2. Full results page: every card with data, the four cases, the known cases scored, the reason for each card with no data, boards holding the card by stage.
3. Proposals page for the process and the league: one page for the common path, plus edge cases and what to drop. To include: the weak climbing field; tribes-missing scoring for generality; teams' card findings passed to balance; the card report run before records are deleted; the known-cases set; rotating model families and the two-strategy restarts; a flagged card may change before a bot passes (the owner said yes); the costing method needs a measured price for growing effects and a same-effect-across-tiers check; a first-sight read; the log failure above; drop made-up-board pitches as evidence, the generic power check, and the stopping test as a gate on card changes. Also `trace.md`.
4. `tools/league/card_report.sh`, one command.
5. Stat worth of the text and the pick-rate chart; a cheaper whole-game step (stop early, play only bots that buy the card, share a match); an add-a-fresh-copy fight test (the blue team's `cardpower` does this) and a forced-in test for ignored cards.
6. Merge PR 257 once the owner has answered; clean `/data/card-power`; disk report.
7. Report the Hazel Coppicer with Blackthorn Sapling replay bug to whoever owns the fight record.

The planted-strong-card check probably cannot run against a recorded field (changing a card changes the rules hash; not verified). Sword-heir stands in as the known strong case.

## Things that bit, so they don't again

- Never wait on another command with `pgrep -f <name>` inside a command that contains that name: it matches itself and waits forever. The tribes-missing match sat unstarted this way. Chain commands or wait on a process id.
- After starting a background run, check within a minute that the real process exists.
- Check a log field's definition before reporting a number that looks too low or too high.
- `league ghost-match` refuses `--no-records` unless `--without` is given. For an unchanged replay, let it write records and delete them.
- `ref_field.sh` checks for build output in the tree's own `target`, so do not set `CARGO_TARGET_DIR` for it.
- 37 of 101,061 fights do not replay exactly; all hold Hazel Coppicer and Blackthorn Sapling. The refight modes leave such fights out.
- The red bot reads its clock, so two runs of it differ slightly; always pair with a control when a difference is small.
- `t3-approval-watch.py` under its own name is killed on this machine; the referee runs a renamed copy.
- The machine is shared; other sessions' matches run on it. Use at most 4 threads.
- A definition changed after data was read must be logged in definitions.md with its reason.
