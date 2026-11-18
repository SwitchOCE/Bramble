# Rebuilding the card table

The bot's card values (`data/cards.tsv`, column `power` and `keep_late`) come from measurement, so they can be rebuilt when card numbers change. Two loops, both re-runnable:

## 1. Self-play regression (no opponent needed)

1. Play noisy self-play: every card gets a random value bias per game, so the data shows which cards really move placement.
   `red-tools pit red:noise=6,sim_positioning=0 red:noise=6,sim_positioning=0 2000 seeds.txt out/data 1000 2` (from `tools/league`, release build).
2. Fit placement on the cards on board at rounds 4, 7 and 10, centred within tier and round:
   `python3 regress.py out/data --lam 20 --out reg.json`
3. Move the coefficients into `power`, K points per unit of placement, capped:
   `python3 adjust.py reg.json data/cards.tsv new.tsv 6 5 out/data/library.json`
4. A/B the new table against the old one: `red-tools pit red:table=new.tsv red 200 seeds.txt out/ab`, then `python3 quick.py out/ab`.

Four passes of this gave 0.45, 0.23, 0.62 and 0.32 places in self-play during round 1.

## 2. Practice against a fixed opponent (round 2)

1. Run practice games against the opponent: `practice_queue.sh 200 name "k=v,..."` (it writes `src/overrides.rs` for the run and restores it).
2. Estimate each card's worth from the games: a fight model (who wins given both boards' stats and tier, by round band) gives each card's effect in stat points beyond its body. Placement of seats fielding it in rounds 6–10 and buy rates when offered are used as checks. Steps are capped by sample size:
   `python3 practice_table.py cards_in.tsv cards_out.tsv pr/run1:1 pr/run2:0.5 ...` (folder:weight)
3. A/B the result on two seed sets.

The first pass, table p2, moved red from +0.48 to −0.41 against blue-m1. It only reads what the opponent's seats bought, sold and fielded, plus fights and placements. It never reads the opponent's `reports.jsonl` rows.

## What isn't measured

- Each card's `row`, `syn` and `pair` columns, its `growth`, and the starting `power` of a brand-new card. These came from a one-off reading of the card text by a model. A card missing from the table falls back to its stats plus 2 per tier.
- The cards that `tactics.rs` names (eaters, Compost, the Colonel).
