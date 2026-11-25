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
