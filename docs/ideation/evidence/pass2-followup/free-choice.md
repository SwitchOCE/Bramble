# Bench: latest run

Written by `tools/sim/bench.sh`; reproduce with the same command and seed. Bars come from `docs/ideation/PLAN.md`; TOO CLOSE means the bar sits inside the measurement's 95% margin. A strategy's result measures the bot as well as the game. Bot-or-game reading: `bench-reading.md`.

## Free-choice final boards: free_choice

NOT RUN

## Free-choice final boards: free_choice_plain

Eight seats per lobby; zero tribe priors, no routes. Majority and plurality exclude all tokens; neutral non-token slots count. Away Birds/Bellies add none. Plurality ties retain every leader. Pick uses all seats; lobby pick uses seats where the tribe was offered. Outcomes condition on majority label. 95% t intervals use lobby-clustered ratio residuals; exploratory, no multiple-comparison correction. Boundary rates use a conservative Wilson bound with one trial per informative lobby; fewer than two informative lobbies have no interval. Sparse results need more lobbies. Other hints (flight, larder, spells, heroes, placement) and live mechanic evaluation remain. Buy/keep hints are bypassed, including text_value; generic text fallback is 1.5 × tier.

| Tribe | Seats | Pick (95%) | Lobby pick (95%) | Mean place (95%) | First (95%) |
|---|---:|---:|---:|---:|---:|
| Birds | 371 | 11.59% [10.42%, 12.77%] | 13.76% [12.50%, 15.03%] | 5.10 [4.91, 5.29] | 4.85% [2.74%, 6.97%] |
| Bog folk | 336 | 10.50% [9.35%, 11.65%] | 12.77% [11.49%, 14.04%] | 4.30 [4.09, 4.51] | 12.80% [9.49%, 16.11%] |
| Fairies | 29 | 0.91% [0.58%, 1.24%] | 1.13% [0.72%, 1.53%] | 3.79 [2.94, 4.65] | 31.03% [14.72%, 47.35%] |
| Hedgerow folk | 281 | 8.78% [7.76%, 9.81%] | 10.45% [9.32%, 11.59%] | 3.75 [3.51, 3.99] | 25.27% [20.56%, 29.98%] |
| Hunters | 705 | 22.03% [20.45%, 23.62%] | 25.54% [24.00%, 27.08%] | 3.89 [3.75, 4.03] | 17.59% [15.30%, 19.87%] |
| Oozes | 283 | 8.84% [7.73%, 9.96%] | 10.69% [9.43%, 11.95%] | 4.76 [4.52, 5.01] | 9.19% [6.01%, 12.37%] |
| no_tribe | 1195 | 37.34% [35.69%, 39.00%] | — | 4.86 [4.76, 4.97] | 9.12% [7.76%, 10.49%] |

no_tribe breakdown (plurality share uses eligible slots):

| Reason | Plurality | Seats | Share of no_tribe | Mean plurality share | Mean place | First |
|---|---|---:|---:|---:|---:|---:|
| mixed | Birds | 124 | 10.4% | 42.1% | 5.52 | 5.6% |
| mixed | Bog folk | 134 | 11.2% | 42.4% | 4.86 | 7.5% |
| mixed | Fairies | 49 | 4.1% | 41.4% | 4.55 | 16.3% |
| mixed | Hedgerow folk | 121 | 10.1% | 42.2% | 4.40 | 14.0% |
| mixed | Hunters | 217 | 18.2% | 42.5% | 4.39 | 9.7% |
| mixed | Oozes | 122 | 10.2% | 41.5% | 5.35 | 4.9% |
| tied_plurality | Birds+Bog folk | 11 | 0.9% | 30.9% | 6.36 | 9.1% |
| tied_plurality | Birds+Bog folk+Fairies | 4 | 0.3% | 29.8% | 6.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Fairies+Hedgerow folk | 1 | 0.1% | 25.0% | 3.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Fairies+Hedgerow folk+Hunters | 3 | 0.3% | 18.1% | 4.67 | 0.0% |
| tied_plurality | Birds+Bog folk+Fairies+Hunters+Oozes | 1 | 0.1% | 14.3% | 8.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Fairies+Oozes | 1 | 0.1% | 25.0% | 2.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Hedgerow folk | 4 | 0.3% | 28.6% | 6.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Hedgerow folk+Hunters | 1 | 0.1% | 20.0% | 2.00 | 0.0% |
| tied_plurality | Birds+Bog folk+Hedgerow folk+Hunters+Oozes | 2 | 0.2% | 17.1% | 4.50 | 0.0% |
| tied_plurality | Birds+Bog folk+Hunters | 5 | 0.4% | 28.6% | 6.20 | 0.0% |
| tied_plurality | Birds+Bog folk+Oozes | 5 | 0.4% | 27.9% | 5.80 | 20.0% |
| tied_plurality | Birds+Fairies | 13 | 1.1% | 34.2% | 5.69 | 15.4% |
| tied_plurality | Birds+Fairies+Hedgerow folk | 1 | 0.1% | 28.6% | 7.00 | 0.0% |
| tied_plurality | Birds+Fairies+Hedgerow folk+Hunters | 2 | 0.2% | 22.5% | 3.00 | 0.0% |
| tied_plurality | Birds+Fairies+Hedgerow folk+Hunters+Oozes | 1 | 0.1% | 20.0% | 3.00 | 0.0% |
| tied_plurality | Birds+Fairies+Hunters | 4 | 0.3% | 28.6% | 7.50 | 0.0% |
| tied_plurality | Birds+Fairies+Hunters+Oozes | 1 | 0.1% | 25.0% | 3.00 | 0.0% |
| tied_plurality | Birds+Fairies+Oozes | 7 | 0.6% | 29.3% | 5.43 | 14.3% |
| tied_plurality | Birds+Hedgerow folk | 21 | 1.8% | 34.2% | 5.38 | 4.8% |
| tied_plurality | Birds+Hedgerow folk+Hunters | 3 | 0.3% | 28.6% | 5.67 | 0.0% |
| tied_plurality | Birds+Hedgerow folk+Oozes | 4 | 0.3% | 28.6% | 6.00 | 0.0% |
| tied_plurality | Birds+Hunters | 29 | 2.4% | 35.0% | 5.17 | 6.9% |
| tied_plurality | Birds+Hunters+Oozes | 6 | 0.5% | 28.6% | 6.50 | 0.0% |
| tied_plurality | Birds+Oozes | 27 | 2.3% | 35.5% | 6.22 | 3.7% |
| tied_plurality | Bog folk+Fairies | 17 | 1.4% | 35.0% | 4.65 | 17.6% |
| tied_plurality | Bog folk+Fairies+Hedgerow folk | 3 | 0.3% | 28.6% | 6.67 | 0.0% |
| tied_plurality | Bog folk+Fairies+Hedgerow folk+Hunters+Oozes | 2 | 0.2% | 17.1% | 4.50 | 0.0% |
| tied_plurality | Bog folk+Fairies+Hedgerow folk+Oozes | 1 | 0.1% | 25.0% | 4.00 | 0.0% |
| tied_plurality | Bog folk+Fairies+Hunters | 3 | 0.3% | 28.6% | 3.33 | 33.3% |
| tied_plurality | Bog folk+Fairies+Oozes | 2 | 0.2% | 33.3% | 2.00 | 0.0% |
| tied_plurality | Bog folk+Hedgerow folk | 19 | 1.6% | 34.2% | 5.63 | 5.3% |
| tied_plurality | Bog folk+Hedgerow folk+Hunters | 6 | 0.5% | 28.6% | 5.33 | 0.0% |
| tied_plurality | Bog folk+Hedgerow folk+Oozes | 5 | 0.4% | 27.9% | 5.80 | 0.0% |
| tied_plurality | Bog folk+Hunters | 18 | 1.5% | 35.0% | 4.61 | 5.6% |
| tied_plurality | Bog folk+Hunters+Oozes | 4 | 0.3% | 28.6% | 6.25 | 0.0% |
| tied_plurality | Bog folk+Oozes | 18 | 1.5% | 32.9% | 5.89 | 0.0% |
| tied_plurality | Fairies+Hedgerow folk | 24 | 2.0% | 32.3% | 3.58 | 20.8% |
| tied_plurality | Fairies+Hedgerow folk+Hunters | 4 | 0.3% | 29.8% | 3.75 | 25.0% |
| tied_plurality | Fairies+Hedgerow folk+Hunters+Oozes | 1 | 0.1% | 20.0% | 4.00 | 0.0% |
| tied_plurality | Fairies+Hedgerow folk+Oozes | 4 | 0.3% | 28.6% | 5.00 | 0.0% |
| tied_plurality | Fairies+Hunters | 25 | 2.1% | 38.3% | 3.92 | 24.0% |
| tied_plurality | Fairies+Hunters+Oozes | 10 | 0.8% | 29.5% | 4.70 | 10.0% |
| tied_plurality | Fairies+Oozes | 12 | 1.0% | 34.6% | 4.83 | 0.0% |
| tied_plurality | Hedgerow folk+Hunters | 38 | 3.2% | 38.2% | 3.47 | 18.4% |
| tied_plurality | Hedgerow folk+Hunters+Oozes | 7 | 0.6% | 28.6% | 3.14 | 28.6% |
| tied_plurality | Hedgerow folk+Oozes | 24 | 2.0% | 36.1% | 4.67 | 4.2% |
| tied_plurality | Hunters+Oozes | 24 | 2.0% | 36.4% | 5.17 | 8.3% |

## Paired head-to-head

"Clearly better" = positive gain whose 95% margin excludes 0, on fresh seeds, at no meaningful turn-time cost. Positive gain is incumbent minus candidate mean place. Each independent seed supplies the average of its two swapped games; the 95% margin uses Student t over seeds.

NOT RUN.

## Bot yardstick: one best bot among seven

NOT RUN Best bot among seven Naive: top 4 at least 85%, wins at least 45%.

| One of | Among seven | Games | Avg place (95%) | Win (95%) | Top 4 (95%) |
|---|---|---:|---:|---:|---:|

## Builds per seat, unpinned and varied bots

NOT RUN

## Win spread: pinned Hard bots in mixed lobbies

NOT RUN

## Are the strategies different boards?

NOT RUN

## Does the bench catch a bad bot?

NOT RUN

## Does placing matter with everyone scouting?

NOT RUN

## Pace and economy

NOT RUN

## Cards and heroes in the mixed lobbies

NOT RUN

## Time per bot turn

NOT RUN

## What ran on what code

| Suite | Games | Commit |
|---|---:|---|
| free_choice_plain | 400 | 66afe50 |
