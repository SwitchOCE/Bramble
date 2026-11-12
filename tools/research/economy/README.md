# Economy sims

Re-runnable models behind the economy and tier-price research of 12 Nov 2026. What they found, and why, is in [docs/research/economy/](../../../docs/research/economy/README.md). The saved outputs are in its `results/` folder.

All the scripts are plain Node (no packages). Each one is seeded, so a rerun gives the same numbers.

**Defaults are a snapshot.** Each script's built-in values are the rules as they stood when it was run. Several of them predate the decided economy. Pass overrides to test today's rules. The decided values are in rulebook 4.1–4.6 and 6.1.1.

## Folders, in the order they were built

| Folder | What it models | Run (from that folder) | Time |
|---|---|---|---|
| `gold-models/` | One player, gold only, no fights. Tests income, tier-up prices and sell values. `model.js` uses the first-round rules (sell = paid − 1); `model2.js` uses the second-round rules (sell = half tier, rounded up). | `node model.js`, `node sweep.js`, `node test2.js`, `node test3.js`, `node v2test.js`, `node odds.js` | seconds |
| `schedule-search/` | Every possible tier-up schedule. Finds the most gold left for units for each turn tier 6 is reached. | `node rush.js [--one-per-turn]`; `node prices.js '{"A":[8,14,22,30,38]}' [--one-per-turn] [--flat=3]` | seconds |
| `lobby-v1/` | 8 players with fixed tier-up plans: power numbers, fights with a little luck, v0.6 damage. | `node lobby.js '<overrides JSON>' 2000 "<label>"` | about 4 s per 2,000 lobbies |
| `lobby-v2/` | Like v1, but the bots adapt each turn and are evolved for each rule set. Economy units are real board units. | `node lobby2.js '<overrides JSON>' "<label>"`; sweeps: `node sweep2.js configs2.json 7,11,23` | about 2 min per config and seed |
| `shop-calculator.html` | The click-through calculator from 12 Nov. The owner found it over-complicated; it's kept for the record. | Open in a browser | — |

## Overrides

`lobby.js` and `lobby2.js` read a JSON object of overrides for their `CFG` block. Every judgement call lives in `CFG`. Examples:

```bash
node lobby2.js '{"tierBase":[8,12,16,19,26]}' "decided prices"
```

```bash
node lobby2.js '{"tierBase":[8,12,16,19,26],"growth":1.7,"hp":34}' "steeper tiers, 34 health"
```

The main keys:

| Key | Meaning | Default |
|---|---|---|
| `tierBase` | Tier-up base prices, to tiers 2–6 | `[8,14,22,30,38]` (v1 and v2) |
| `disc` | Discount per turn waited (the last value repeats) | `[1,2,3,4,5]` |
| `incStart`, `incStep`, `incKnee`, `incLate` | Income: 5, +2 a turn up to 15, then +1 | 5, 2, 15, 1 |
| `extra`, `extraFrom` | Free gold a turn from a turn: a crude stand-in for economy units (v1) | 0, 4 |
| `econShare`, `econPow`, `econGold` | v2 economy units: share of shop offers, power multiplier, gold a turn by tier | 0.14, 0.5, `[0,1,1,2,2,3,3]` |
| `growth`, `p1` | A tier-N unit is worth `p1 × growth^(N−1)` | 1.5, 10 |
| `goldenMult` | A triple is this many copies' worth | 2 |
| `scaleFlat`, `scalePct` | Growth per turn a unit stays on the board | 1, 0.05 |
| `spellCost`, `spellPct`, `spellsPerShop` | A spell's cost, its buff as a share of a unit of your tier, spells per shop | 3, 0.36, 2 |
| `sigma`, `drawBand`, `bigRatio` | Fight luck, how close counts as a draw, the power ratio under which a loss is big | 0.082, 0.02, 0.65 |
| `hp`, `dmgCap`, `bigBonus` | Health, damage cap, big-loss extra (`dmgCap` and `bigBonus` are v2 only) | 40, 10, 3 |
| `odds` | Per-slot tier odds by shop tier | TFT-like table |
| `seed` (v2) | Random seed | 7 |
| `gens`, `lobbiesPerGen`, `evalLobbies` (v2) | Evolution length and evaluation size; lower them for a quick check | 12, 500, 4000 |

## Sweeps (v2)

- `gen.js` and `gen2.js` write the config lists for rounds 1 and 2 (`configs.json` and `configs2.json`).
- `sweep.js` (round 1, one seed) and `sweep2.js` (any seeds, averaged) run a list four processes at a time. They are the only scripts that write files: `results*.md` and `results*.json`, into the folder you run them from. Run them from a scratch folder, giving the script's full path, so this folder stays clean. Every other script only prints.
- **Before a big sweep,** check the machine's load. Four processes is well under half of this machine's 24 cores. The project rule is at most half the cores and half the free memory without asking.

Quick check that v2 works (a few seconds):

```bash
node lobby2.js '{"gens":1,"lobbiesPerGen":20,"evalLobbies":40,"rushLobbies":20}' smoke
```
