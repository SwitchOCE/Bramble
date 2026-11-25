# Card power measures and the balance process review: plan

**Proposal, not approved.** Written 25 Nov 2026 by the card power session (branch `balance/card-power`). Everything here is the session's proposal unless it is in quote marks. A fresh agent cross-examined the first draft the same day ([plan-interrogation.md](plan-interrogation.md)); this text is the plan after its cuts. The page shown to the owner: https://claude.ai/artifact/A38oUcVKdr9d7bJzFRuFRs.

## The problem, in the owner's words

> "Old Brock, Last of His Sett, and [Sword-heir], I looked at them instantly the very first time I saw them, and I knew that both were completely overpowered. Within two seconds of seeing them. And I expected them to be nerfed at some point during this process automatically. So I didn't really bring it to anybody because I was hoping that agents would catch it themselves. And the fact that they haven't caught it is really useful data."

> "I think Brock Cub is another candidate for being too strong as well. And Overrun's mechanics, in terms of how Overrun functions and continually chaining, is another candidate for problems. Any low health board, Badgers will just clean up with no issues."

> "I'm saying that it's broken and a lot of effort's going in the wrong places if it's not catching this ... So there's missing pieces or there's waste or both."

> "We need to build our processes to catch this kind of stuff."

> "How do we isolate card power? Because pick rate's one thing and power is another thing. What good measurements [can] Claude come up with that'd be easy for us to look at data-wise to find problematic cards without going into bot weightings, which is useful, but I think potentially more tedious."

The owner agreed to three measures ("I think that all of those measures are good"): a swap test, bought against passed, and pick rate against power on one chart. They asked whether their view of the named cards is "borne out by the data".

Out of scope: changing any card, keyword, rule or bot. The league is on hold and is not touched.

## What is already done (25 Nov)

- `league refight` is on this branch and builds on today's engine. It reproduces every recorded fight of a fresh ghost match (2,028 of 2,028).
- A fresh ghost match plays on this branch against the kept field (`/data/third-run/field-fa1d51ec`, read only): 40 games in 14 seconds.
- The trace of the design and league stages is read; findings are in the page for the owner and will be written to `trace.md` in this folder.
- The evidence that already existed (the blue team's 18 Nov fight table, the 20 Nov fix-round page on Old Brock, the 22 Nov league flag) is on the owner's page, with what it does and does not show for each of the four cases.

## Steps

### 1. Fix the definitions before any data is read

Write `definitions.md` in this folder and commit it before step 3's match is analysed. It holds the three definitions below, the flag line, the smallest sample a number needs, and the list of what each measure cannot see. One thing has already been seen and is stated there: the blue team's own table of 18 Nov (a fresh copy of each card added to recorded boards), in which Old Brock ranks first and Brock Cub near the bottom.

**Swap test (fight value).** One observation is one unit on one side of one recorded fight. The fight is fought again with that unit swapped, on the same fight seeds as the unswapped board (the recorded seed and three more). Score for the unit's side: win 1, draw ½, loss 0. Two swaps, both reported:
- *Whole unit:* replaced by a plain unit with no text and the average printed Attack and Health of its tier (double if golden). This counts everything the unit had gathered by then.
- *Text only:* the unit keeps its recorded stats and loses its text and keywords. This counts what its text does inside the fight.

Swap value = mean score as recorded minus mean score swapped. Also reported: the change in damage dealt, and the share of fights whose recorded result changes, by stage of the game (rounds 1–4, 5–8, 9–12, 13 on), with a 95% interval grouped by game. At most 1,000 unit-fights per card per stage, picked by a fixed hash, never by outcome. Under 200, the cell reads "too few". Gains a unit got from other cards count for the unit that holds them, so the report marks a card whose whole-unit value is mostly gathered stats (whole-unit value far above text-only value).

**Keyword off.** The same tool removes one keyword from every unit on a side (own or granted) and refights. Run for Overrun and two other fight keywords for comparison (Cleave and Fury); the rest wait for the standing report. For each keyword the result is also split by the enemy board's typical Health (low, middle, high third), which tests "any low health board" directly.

**Bought against passed.** One observation is one turn of the live seat in which the card was on offer and affordable. Bought means at least one copy was bought that turn. The number is mean final place when bought minus when passed, compared only inside the same bot, round and "is this the seat's main tribe at the time of the offer" group, then averaged. Under 100 bought or 100 passed, the cell reads "too few". This is not an experiment: bots buy a card when it suits the board, and a card a bot always buys cannot be measured this way. The report says so on each row.

**Pick rate against power.** Pick rate is bought divided by offered-and-affordable. One chart with each card a dot: pick rate across, whole-unit swap value up, colour by tribe, tier marked. A second chart puts bought-against-passed on the upright axis.

**The flag line.** Cards are compared inside one stage of the game, never across stages. A card is over the line when, at any stage with enough data, the low end of its whole-unit swap interval is above the typical (median) card two tiers up at that stage; for tiers 5 and 6, above the best quarter of tier 6. It is on watch when above the typical card one tier up. A card under the typical card one tier down is listed as weak. On bought against passed: flagged when buying goes with half a place or more better and the interval excludes zero. These lines are a first guess; the first report shows where they fall and the owner can move them.

### 2. Build the swap test

Extend `league refight` with a swap mode: a per-card selector, the two swaps, keyword off, several seeds, the sampling cap. Tests: every recorded fight still reproduces with no swap; swapping a plain unit for itself changes nothing; a planted card (one card's Attack raised a lot) comes out flagged.

Why not only the blue team's tool: it adds a fresh card to a board, which is the right test for a card that does not exist yet (see step 6), but it cannot see a unit as it really stood in a game, with what it had gathered. The swap test can.

### 3. Play fresh matches with records kept, and give the first answer

Bots are built from their tags in a build tree of this session's own (`/data/card-power/tree`), never in the league's folders. Matches are ghost matches against the kept field, on today's cards.

First: one match of 2,000 games, 1,000 with red-c14 in the live seat and 1,000 with blue-c17 (always Badger). About ten minutes. Fights between the field's ghosts are in the records too, so the swap test also sees boards from the 15,000 runs of earlier bots, of every tribe. More games are played only where a card reads "too few". Runs with a bot held to a tribe it plays badly are not planned: they measure the bot as much as the cards.

The swap test and Overrun on and off are run on this match. **First report to the owner:** the four cases, and every card with enough data, as one table and one chart.

Raw files are deleted once the findings are written; the per-card tables and the report stay (under 2 MB).

### 4. Bought against passed, pick rate and the chart

In Python, from the match's `shops.jsonl.gz` and `games.jsonl`, reusing what `tools/league/analysis/cards.py` already reads (buy rate when buyable). No database: the storage rules say a DuckDB file comes only when the Python reports can't answer a question.

### 5. Check the measures

- Split the games in two halves and compare the rankings: they should agree, and a card flagged in one half only is noise.
- The planted card from step 2 must be flagged in the real data.
- Compare the swap ranking with the blue team's independent table.

These run before the first report in step 3 is shown. The report states plainly where the data disagrees with the owner on any card.

### 6. Make it a standing step, and propose the process changes

One command, `tools/league/card_report.sh <match folder>... --out <folder>`, writes `cards.csv` (every card, every number, sample sizes), `flags.txt` (over the line, on watch, weak) and `card-report.html` (the charts, the full ranking, each measure's limits). It runs the refights itself.

Proposals only; nothing here merges without the owner's yes. Each comes with its evidence from the trace. The first one is already with the owner as a decision: whether a flagged card may be changed before a bot passes its stopping test.
- Where the report runs: after the field runs of every kept bot, and on any match the balance session reads. This needs one line added to the keep rule in `docs/workstreams/league-data/README.md` (records are kept until the card report is written).
- Flags go to the balance notes at once; they do not wait for a bot to pass its stopping test.
- `bramble-design` skill: a pitch that says "leave" or "on target" quotes the card's line from the latest report; a new or changed card is run through the add-a-fresh-copy test on recorded boards before it is pitched; the costing section gets a rule for effects that grow with the board, and a same-effect-across-tiers check.
- The list of steps to drop, with what each cost and why it could not have caught these cards.
- `trace.md`: what each stage saw and concluded on the four cases, and whether the climb itself earned its cost.

### 7. Clean up

Delete raw matches and build output, keep the findings, write the disk report.

## How the work is done

- Step 2 goes to an Opus worker in its own worktree; steps 4 and 6's report are small enough to follow it. Workers get the owner's words quoted and this plan as a labelled proposal. Each code step passes the project's tests and a `scope-reviewer` before it merges to `dev` by pull request. Nothing goes to `main`.
- Step 3's match can run while step 2 is built, because the file formats are fixed.
- Checkpoints with the owner: this plan; the first report (step 3); the process proposals (step 6).

## Cost

- To build all three: refight is ported. Left: the swap mode, bought against passed and the chart, the report command. About a day of agent work and about ten minutes of matches for the first answer.
- To keep catching this: one command after a match. Each run needs the match's records kept until the report is written (about 23 KB a game gzipped) and some tens of minutes of refights.
