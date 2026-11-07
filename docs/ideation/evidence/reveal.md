# The reveal: one last decision before each fight

**Branch `ideation/c-reveal`, from `ideation/main` at 758b5e6 with `ideation/c-placing` merged in. The code is at 6a37cfe.** This page answers the orchestrator's brief of 7 Nov, which followed `placing.md`: with the scout a layout is worth about +4 win-rate points a fight, and against the real board about +14. The test: show the real board, so placing is decided where that value lives.

**Status: in progress.** Each arm's 1000-seed bar and an 8-game probe are queued on this VM behind the sticky-board bench. Everything marked *pending* is filled in when they finish. The numbers below are from a single probe game, so read them as direction, not results.

## The rule (config, off by default)

- `reveal_swaps: N` (0 means off) and `reveal_from_round: R` (default 1).
- After every player has recruited, each fight's two players see each other's real fight board, Eggs on Nests included.
- Each player makes up to N swaps of their own slots, unit with unit or unit with gap. Both choose from the same snapshot at the same time, then the fight runs.
- **The swaps hold for this fight only.** The recruit board goes home unchanged, with its turn counts (Dozey, Sleeping Partner), bands, Passes and Nests. Carry-home buffs find units by iid, so they still land.
- A Ring or a band is a slot, so it buffs whoever stands there in the fight. Swapping a unit onto a Ring for one fight is allowed, and it's part of the decision.
- A ghost doesn't swap. A seated human has no way to choose yet (no UI), so they stand still. The hook is `Bot.reveal_layout`, with `GameSession._reveal` as the seam for the UI.

**Bots** (`BotBrain.reveal_layout`, `Reveal`):
- **Hard** searches greedily against the real snapshot. Each step plays up to 45 fights over standing still and every legal swap (up to 22): each once, the better half twice, the best 6 four times. It takes the winner and stops when standing still wins. N=2 is two such steps.
- **Normal** (the rule placer) does the same with 12 fights a step.
- **Easy and Naive** stand still.
- **The bench's shuffled arm** swaps at random, up to N.

## Results

The bar is measured with one Hard among 7 Hard, 1000 seeds, paired by seed. The probe uses 8 Hard on seeds 31-38. At each fight, the probe scores each side's snapshot against the enemy's board as it fought, after the enemy's own swaps, on 32 fixed fight seeds. It also replays the real fight with that side standing still.

| | N=1 | N=2 |
|---|---:|---:|
| **The bar: shuffled minus search, places** (1000 paired seeds) | *pending* | *pending* |
| Bar without the reveal, for reference | 0.31 ±0.15 (f51eefa, placing.md) | |
| Layout value per fight: the bot's swaps over standing still | +12.5 ±4.2 (1 game, 100 sides); 8 games *pending* | *pending* |
| Random swaps over standing still | +3.4 ±1.8 (1 game) | *pending* |
| Best board within the limit (600-fight search) over standing still | +19.1 ±5.1 (1 game) | *pending* |
| Contested fights only (standing still wins 10-90%), bot's swaps | +21.1 ±6.6 (1 game, 42%) | *pending* |
| Fights where this side's swaps changed the result | 30% (1 game) | *pending* |
| Sides that swapped | 95% (1 game) | *pending* |
| Hard's reveal time a side, here | 148 ms mean, 225 ms p95 (1 game, shared CPU) | *pending* |

**The comparison that matters:**
- Under the scout, a 150-fight search is worth +4.3 ±1.2 a fight over shuffling every unit (placing.md, 8 games).
- Hard's own recruit layout is worth +2.7.
- In the first reveal game, one swap chosen with 45 fights a step is worth +12.5 over standing still, and it changes who wins in 3 fights of 10.

A random swap is worth +3.4, so most of the value comes from choosing the swap, not from moving at all. *(8-game numbers pending.)*

**Phone budget.**
- Assumed phone core: 3 times slower than this VM (`bench-latest.md`).
- Hard's reveal takes about 150 ms here, so about 0.45 s on that phone core. Seven bots would take about 3 s in a row.
- That is over the 1 s lobby limit if a player has to wait for it. But the reveal is simultaneous: the bots choose while the person is choosing, and a person looks at two boards for longer than 3 s. So the cost is hidden if the bots run in the background or across frames, and only an all-bot lobby shows it.
- If it must fit in 1 s, the step can drop to 22 fights, one per swap. That cost is untested.

**Which rounds.** *Pending: the 8-game probe by round.* In the first game, the value per fight is about the same from round 2 on: +10 to +15 points a fight. The result changed in 17% of fights in rounds 1-2, 50% in rounds 3-4 and 25-28% after. Round-1 boards hold one unit, so there is nothing to swap.

## How it would feel to a person (reasoned by hand, not played)

**A real last decision, most rounds.**
- Recruiting is about building. The reveal is about the matchup, read off a real board. Their Hedge Witch is in F2, so which of my units eats the −Attack? Their Whirligig will swap my rows, so I pre-swap the rows that matter. Their Changeling trades with whatever stands across from it, so I put a 1/1 there. A Belladonna in the back row poisons the two front enemies facing it, so I take my carry out of that pair.
- Each of those is one or two swaps, which is what N allows.
- It is the decision `placing.md` found the most value in: +14 against the real board, against +4 with the scout.
- It also gives the cards that read "the enemy across" a moment of their own, where the owner's direction wants depth: "It needs to focus on interesting designs and strategic depth."

**The risk is the chore.**
- If nothing on either board reads position, the right answer is "stand still". Making the player confirm that every round is a chore.
- Remedies for the UI:
  - The reveal screen has a timer and a "Fight" button that is ready from the start.
  - "Stand still" is the default.
  - Show the reveal only when either board holds a unit whose text reads slots, or whose row matters to it. *This needs a measure of how often the bot's best swap is "none".*
- **N=1 is the cleaner rule.** One swap is a single sharp question: what's my one adjustment? Two swaps begin to ask for a full re-layout under a timer, which is fussier. *N=2's extra value is pending.*

**Simultaneous play is what keeps it fair**, and it adds a little bluff. If my opponent expects me to move my carry, they might put their Changeling elsewhere. Each side reads the other's board as it stood, not as it will be.

**Which rounds.** My call, pending the probe:
- Every round from round 3: in rounds 1-2 boards have 1-3 units and the shop is the whole game.
- Not only on some rounds: a rule that appears now and then is harder to learn than one that is always there.
- `reveal_from_round` is the setting.

**What it does to the tribes.**
- **Whirligig, Changeling, Belladonna, Hedge Witch, Turnip Scarecrow, Mrs Posset, Hasty Pudding, Mag Pye, Jack Daw:** all read the enemy across. They gain the most, because the player can now aim them, and the enemy can dodge them.
- **Rings, bands:** they stay on their slots, and a one-fight swap can move a big unit onto a Ring. That is a new use for them.
- **Dozey, Sleeping Partner:** untouched. The swap doesn't reset their counts, so placing them stays a recruit-phase commitment.
- **Nests:** an Egg can be swapped like a unit, which can be a decoy.
- **Belly:** unaffected; Oozes hold their units through the fight.

## The screen, sketched (no UI built)

```
 ┌──────────────── Round 7 · The reveal · 0:12 ─────────────────┐
 │  THEM  (Rook, 22 hp)                                          │
 │    back:   [Belladonna]   [   ]   [Hedge Witch]               │
 │    front: [Bramble Boar] [Whirligig] [Toad] [Mole]            │
 │                       ↕ across                                │
 │    front: [Vole 6/7]  [Dozey 12/14•] [Frog 5/5] [Partner•]    │
 │    back:   [Nan ◎Ring]   [Wisp]   [   ]                       │
 │  YOU  (32 hp)                         Swaps left: ● (1 of 1)  │
 │                                                               │
 │  Drag one unit onto another or onto a gap to swap, for this   │
 │  fight only. • marks a count that won't be broken.            │
 │                        [ Undo ]        [ Fight → ]            │
 └───────────────────────────────────────────────────────────────┘
```

- Each enemy unit across one of yours shows a thin line to it.
- Cards that read "across" glow on both boards.
- Tapping an enemy unit shows its text.
- When the timer ends, the fight starts with whatever was set.

## Calls I made

1. **The swaps hold for the fight only.** If they lasted, they would break turn counts, bands and Passes. Every swap would then be a recruit-phase cost as well, which is the stickiness problem `placing.md` just ruled against.
2. **Hard decides greedily, one swap at a time.** It does not search every pair of swaps, to stay near the phone budget. The probe's 600-fight search over every reachable board shows what that gives up.
3. **Normal gets a short search, Easy and Naive none.** That keeps the levels apart without a separate rule.
4. **A human stands still for now.** No UI, so the bench is bots only.

## Limits

- One probe game so far. The full numbers are pending.
- Hard lobbies play mostly Hedgerow and Fairies (`placing.md`), so Birds and Oozes are barely tested.
- The round-3 change to shop odds and damage will move the bar; it will be re-read then.
- The time measurement shares the CPU with other runs.

## How to reproduce

```
BENCH_SET="reveal_swaps:1" tools/sim/bench.sh --cores 4 --timeout 20000 place_search=1000 place_shuffled=1000
godot --headless -s res://tools/sim/reveal_probe.gd -- games=1 first_seed=31 out=<csv> set="reveal_swaps:1"
```
