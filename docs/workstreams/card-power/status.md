# Card power session: where things stand

Working notes for the session itself, so it can pick up after its context is cut down. Last written 25 Nov 2026, evening. Not a report: the owner's pages are linked below.

## Who asked for what

- Started by the owner's assurance session ("QA & Project Manager", on the owner's PC) on 25 Nov. The session leads and talks to the owner directly in its own thread.
- Two jobs: (1) why the balance process passed Sword-heir, Old Brock, Brock Cub and Overrun, and what to change or cut; (2) build the card power measures and make them a standing step.
- The owner approved the plan on 25 Nov: [plan.md](plan.md). Definitions, with every change logged: [definitions.md](definitions.md). The fresh reviewer's cross-examination: [plan-interrogation.md](plan-interrogation.md).
- The league is inside the review (owner, 25 Nov). Bring league findings to the owner as proposals; change nothing in the league without the owner's word. The league is on hold: do not touch `/home/alex/league`, `/data/third-run` or the `league-pin` service (reading is fine).
- The owner wants things that look out of place called out at once, even off task.
- Out of scope: changing any card, keyword, rule or bot. Nothing goes to `main`. No skill or process doc merges without the owner's yes.

## Pages shown to the owner

- Findings and plan: https://claude.ai/artifact/A38oUcVKdr9d7bJzFRuFRs (source: scratchpad `card-power-review.html`)
- First fight numbers: https://claude.ai/artifact/PWf6WXnZVfX8XtdzKV7YGo (source: scratchpad `card-power-first-numbers.html`, generated from the CSVs in `/data/card-power/findings/m1`)
- Bot versions: [../bot-league/bot-versions.md](../bot-league/bot-versions.md)

Pages follow the `house-style` skill. The scratchpad is on `/tmp` and can be lost; the first-numbers page can be rebuilt from the CSVs.

## Code and where it is

Branch `balance/card-power` (pushed), from `origin/dev`:
- `league refight` ported to today's engine (three commits). Reproduces recorded fights.
- `tools/league/analysis/bought_passed.py` and `fight_text.py`, with tests.
- This folder's docs and `docs/workstreams/bot-league/bot-versions.md`.

Two worker branches, **not merged**, each scope-reviewed with no cut items and one ask item waiting on the owner:
- `t3/card-power-refight-modes` (a46ecfc7, on c9a5b8c8): `league refight --text-off --keyword-off <ids> --overrun-swings --seeds N --cap N`. Ask: keep or drop the unused `taken_recorded` / `taken_off` fields (recommended: drop). Simplify: defaults should be `--seeds 2 --cap 500`.
- `t3/ghost-match-card-exclusions` (410a2619, on f572a0c5): `league ghost-match --without <card>` (needs `--no-records`), `analysis/card_without.py` (pairing, `--control`), `analysis/card_without_run.py` (runner). Ask: must the two real-game checks (a never-bought card reads zero; a planted strong card is flagged) pass before merge or before the first full report (recommended: before the report). Simplify: runner timeout 1200 s; one card per `--without`.

Not built: the owner's stat-worth idea (definitions.md, "Stat worth of the text"). It extends text off with stat multipliers ×1.5 to ×8 and solves for the multiplier over the sample. Build on the refight-modes branch once merged.

Before any merge to `dev`: project checks, a `scope-reviewer` agent on the session's own commits too (never reviewed in this context), a pull request. Merge alone only with no cut or ask items.

## Data on `/data/card-power`

- `matches/m1`: 2,000-game ghost match on the climbing field, red-c14 and blue-c17 in the live seat (1,000 each), records kept. Seeds `matches/seeds-m1.txt`, secret `matches/secret-m1.txt`.
- `matches/m1-control`: the same match replayed unchanged (records removed). Noise floor: blue −0.012, red −0.045 places over 1,000 games each.
- `matches/m1-verify`, `m1-modes`, `m1-keywords`: refight outputs. `findings/m1/*.csv`: the tables (text_cards, keywords, overrun_swings, bought_passed).
- `tree`: a git worktree used only to build the tagged bots (red-c14, blue-c17) with the `--without` patch applied. Its binary is `tree/tools/league/target/release/league` once `ref_field.sh` has rebuilt it; `target-match` is the older build output.
- `worker-refight/target/release/league`: the binary with the refight modes. `worker-refight`, `worker-without`, `smoke`, `target`: can go once the branches are merged.
- `ref-field` (being made, background task): about 12,000 runs from 1,500 live games of red-c14 against blue-c17, by the referee's `ref_field.sh` run with `TREE=/data/card-power/tree CORES=0-5` and no `CARGO_TARGET_DIR`. Log: `ref-field.log`.

Raw matches are deleted once findings are written (storage rules: `docs/workstreams/league-data/README.md`).

## What the numbers say so far

Fight tests only (101,061 fights, m1):
- Sword-heir: text first or second of all cards at every stage (+0.34, +0.27, +0.195, +0.157; typical tier 3 about +0.04).
- Old Brock: first from round 13 (+0.164; typical tier 6 +0.032). Too few boards before round 13.
- Brock Cub: own text mid-table. With Overrun given to him he kills 2.1 to 2.3 units a swing, twice any other Overrun unit. His strength is gathered stats; needs the whole-game test.
- Overrun: rounds 9–12, +0.083 against low-Health boards, +0.028 against high. Empties a board of three or more in about 3% of swings.
- Checks passed: two halves agree (0.89–0.96), Sentry reads zero, typical margin ±1.6 points, 5 minutes for every card.

Whole-game tests are **not usable yet**:
- On the climbing field blue-c17 came first in 69% of games and red-c14 in 46%: the field is too weak (over half of it is the two starting bots).
- Bought against passed read positive for almost every card: a bot that is ahead passes, a bot that is behind buys. The definition needs a control for how strong the board is. Fix it so the typical card reads zero, log the change in definitions.md, and only then read named cards.

Trace (job 1), early findings: the process flagged these cards four times (16, 18, 20, 22 Nov) and changed nothing. Details and quotes are on the first page. League findings given to the owner on 25 Nov: weak field; card knowledge kept private to teams; records deleted before any card reading; one-tribe bots can count as strong; rotate model families; the gate on card changes.

## Update, 25 Nov late evening

- Both worker commits are now on `balance/card-power` (cherry-picked), with the reviews' small fixes (refight defaults 2 seeds and 500; runner timeout 1200 s). 45 Rust and 68 Python tests pass. The two ask items are still unanswered by the owner, so nothing goes to `dev`.
- New measures since the first write-up, all defined in definitions.md: one worth-a-look rule for every measure (three spreads from the middle); stat growth per turn held (`analysis/stat_growth.py`, the owner's idea; Brock Cub is the fastest-growing tier 1 from round 5, golden Cubs hold a median +58/+81 from round 13); bought against passed kept as a hint read against the typical card (it leans +0.12 to +0.27 against buying whatever is controlled for).
- The stronger field is made: `/data/card-power/ref-field` (12,000 runs). Baseline on it: `matches/r1` (2,000 games, seeds `seeds-r1.txt`, secret `secret-r1.txt`): red-c14 averages 3.86, blue-c17 4.71, places spread over 1 to 8. So the field is strong enough.
- Running: left out of the shop on r1 for sword-heir, old-brock, brock-cub and a never-bought control (needle-sister), into `matches/r1-without`; results to `findings/r1/left_out.csv`. Log `matches/r1-without.log`.
- Known rough edge: stat growth's same-tier line over-marks tiers 4 to 6, where most cards do not grow at all and the spread is tiny. A floor (say three stats a turn) would fix it.
- The planted-strong-card check cannot be run against a recorded field as planned, if changing a card changes the rules hash (to verify). Substitute to propose: leave out a whole set the bot depends on (every Badger unit for blue-c17) and confirm it finishes far worse.
- Still to do from the earlier list: fight tests on r1's boards; stat worth of the text; full report page; process and league proposals; trace.md; one-command report; scope review of the session's own commits; PR; clean-up.

## Update, 25 Nov night

- **Left out of the shop on the strong field (r1), 1,000 games a bot:** Sword-heir: red 1.11 places worse, blue 1.53 worse (over the line). Old Brock: blue 0.07 worse (bought in 122 of 1,000 games; red never). Brock Cub: blue 0.02 worse, red 0.13 better (no loss). Control Needle Sister (never bought): 0.12 to 0.15 better, so read every number against about −0.13 (one less dead card in the shop). Margin about ±0.17. Table: `/data/card-power/findings/r1/left_out.csv`.
- **Running:** left out for all four Grudge cards together (brock-cub, sett-shield-bearer, armsbearer, grudge-keeper), then gleaner, then fencing-master; log `matches/r1-without-2.log`; then re-pair with `analysis/card_without.py r1 r1-without/*/` (directories only, not the `.log` files).
- **The owner's calls are recorded:** [known-cases.md](known-cases.md), with what the data says on each. Use it to test every measure and process change.
- **The ladder** (definitions.md): readings of played games, then experiments on recorded fights, then the whole-game test only for marked cards, then a read. A fixed floor sits beside the three-spreads rule so a balanced game marks nothing.
- **Order of value for process changes** (told to the owner): fix the climbing field; run the cheap steps after every kept bot; give teams' card measurements to balance; the known-cases set; a make-it-work test for ignored cards; rotate model families and run the restarts; a measured price for growing effects in the design method; drop made-up-board pitches as evidence, the generic power check, and the stopping test as a gate on card changes.
- **Half the cards have no data** because neither kept bot buys them (bought under 1% of offers: Mouse 14 of 17, Briar 13 of 19, Pigeon 10 of 20, Locust 8 of 19, Badger 1 of 19, no tribe 7 of 8). Red ends on Locust in 78% of games, blue on Badger in all. The report must give the reason a card has no data: never offered, tribe not played, or offered and refused (only the last is a sign).
- **The owner asked for a considered answer on how to get data on ignored cards** (forcing bots against running more bots). The session's answer, given 25 Nov: never change how the league's best bots play; get the data from separate runs. In order of cost: (1) an add-a-fresh-copy fight test for every card (the blue team's `cardpower` tool does this already); (2) a forced-in whole-game test, the mirror of left out, read as a lower bound; (3) one specialist bot per neglected tribe, forked from the best bot by a fresh agent of another model family, once per balance pass, with its games added to the field. Not random buying inside the league bots.

- **The owner's follow-up on ignored cards (25 Nov night):** change the rules the bot teams work under so they have to find uses for cards ("the value tables can't set a card to zero ... It's very hard to create a rule that can't be gamed"). The session's answer: rule on measured results, not on a bot's insides. Two proposals to write up with the league changes: (a) each team fields a roster, one bot per tribe or style, and the team's score counts all of them; (b) a bounty for any card bought on under 1 offer in 100: a team earns it with a bot variant that plays the card often and that the referee's left-out test shows really depends on it. A card no team can claim goes to design as weak.

## Next steps, in order

1. When `ref-field` finishes: play a 2,000-game baseline on it with the tree's binary (records are forced on; delete them after), and check each bot's average place is near 4. If it is under 3.5, say so.
2. Left out of the shop on that baseline for sword-heir, old-brock and brock-cub, plus the two checks (a card the bots never buy; a planted strong card, which needs a copy of the card data and its own baseline). About ten minutes a card.
3. Fix bought against passed (see above) and rerun on the new baseline.
4. Get the owner's answers on the two ask items, apply the simplify items, merge the worker branches into `balance/card-power`, build stat worth.
5. Full report page for the owner: every card with enough data, the four cases, what disagrees with the owner.
6. Process proposals page (design stage and league), each with its evidence and what to drop; `trace.md`. Proposals only.
7. The one-command report (`tools/league/card_report.sh`) and where it sits in the process.
8. Pull request to `dev`; clean up `/data/card-power`; disk report.

## Things that bit, so they don't again

- `league ghost-match` refuses `--no-records` unless `--without` is given. For an unchanged replay, let it write records and delete them.
- `ref_field.sh` checks for build output in the tree's own `target`, so do not set `CARGO_TARGET_DIR` for it.
- 37 of 101,061 fights do not replay exactly; all hold Hazel Coppicer and Blackthorn Sapling. The refight modes leave such fights out. Worth a bug report to whoever owns the fight record.
- The red bot reads its clock, so two runs of it differ slightly; always pair with a control when a difference is small.
- `t3-approval-watch.py` under its own name is killed on this machine; the referee runs a renamed copy.
- The machine is shared; other sessions' matches run on it. Use at most 4 threads.
- A definition changed after data was read must be logged in definitions.md with its reason.
- Mid-turn messages from the assurance session are marked "FROM AN AGENT, NOT THE OWNER": information and proposals, not the owner's instruction.
