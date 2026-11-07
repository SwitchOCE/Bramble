# The reveal by eye

**7 Nov 2026, `ideation/c-reveal2`: 70366f7 (six tribes) with the reveal merged in.** This is the critic's test (`critic-reveal.md`): can a person, reading the boards, use one revealed swap?

## Job 2: three readers, 20 screens. **FAIL.**

- **The screens.** `tools/sim/reveal_screens.gd` played 4 spread-suite games (seeds 41-44, every strategy, reveal on). From those I picked 20 positions at random, stratified by round:
  - 7 from rounds 3-5, 7 from rounds 6-9, 6 from round 10 on;
  - every tribe appears, Birds on 7 screens.
- **What a screen shows.** Both boards by slot, with stats, card text, keywords, Rings, hex and Belly contents. A Nest shows only its Egg. Swaps happen before the bell, and absent Birds stay hidden.
- **The readers.** Three fresh agents, none seeing the others or the scores. Each got the rule in 3 lines and a paragraph of fight basics, and could read only the screen file.
- **Scoring.** Every pick is scored on 32 fixed fight seeds against the enemy as it stood. Results are win-rate points over standing still, with 95% CIs over the 20 screens.
- **The one-line rule**, written before any screen was seen: put your highest-Attack unit across the enemy front unit with the least Health; if it's already there, stand still.

| Pick | Gain over standing still | Real decisions (self-rated) | Stood still |
|---|---:|---:|---:|
| Random swap (all swaps averaged) | +0.7 ±3.7 | | |
| One-line rule | +2.3 ±6.7 | | 2 |
| Reader 1 | +6.2 ±7.3 | 12 of 20 | 9 |
| Reader 2 | +4.9 ±7.2 | 11 | 13 |
| Reader 3 | +5.2 ±7.4 | 11 | 12 |
| Readers pooled | +5.4 ±7.2 | | |
| Hard (45 fights) | +8.4 ±7.2 | | 2 |
| Best single swap (hindsight) | +19.7 ±9.4 | | |

- **By eye minus the rule:** +3.8 ±7.5, +2.6 ±6.4 and +2.9 ±6.1; pooled +3.1 ±6.5. None is clearly above the rule.
- **One screen carries it.** On screen 2, all three moved their 15/21 away from an enemy Changeling, worth +73. Without that screen the readers average **+1.9 ±1.5**.
- Readers never chose a swap that clearly hurt: one pick was more than 3 points worse than standing still, out of 60.
- **Standing still was right on 6 of 20 screens**, where no swap gains more than 3 points. The readers stood still on 9-13.
- On the other 14, the gains were there: the best swap averaged +28. The readers found the obvious one, missed the rest and said "no real decision" on 8-9 of 20. Hard found +8.4 of the +19.7, and the readers +5.4.

**Verdict.** The pass needs a mean gain of at least +3 and clearly above the one-line rule. The readers clear +3 on average, but only on one obvious screen, and they don't clear the rule. **The reveal fails as a decision for people:**
- About half its screens are chores.
- The value sits in reads a person doesn't find in 30 seconds.

I recommend dropping it as a standard rule and keeping the flag off. If it comes back, it should come back in the critic's gated form: only when a board holds a Changeling, Hedge Witch, Mire or Quarry. Screen 2 is that case.

## Job 1: the placing bar on six tribes

*Running.* Reveal off, 1000 paired seeds, then reveal on with the shuffled arm still at the reveal. To be filled in.

- **Before the six tribes, for reference** (the old build, reveal N=1 with the shuffled arm swapping at random): 1.01 ±0.15 over 1000 seeds.
- **Partial data so far** (1797 seats from the reveal-off search arm): Bog folk builds hold 21% of Hard seats and Hunters 17%. Hedgerow and Fairies hold most of the rest, and Oozes and Birds under 2%.

## Reproduce

```
godot --headless -s res://tools/sim/reveal_screens.gd -- suite=spread games=1 first_seed=41 out=<jsonl>
```

Data: [reveal-data/eye/](reveal-data/eye/): the screens and prompt, the readers' picks, and `answers.json` with every swap's score, Hard's pick and the rule's pick. `score.py` scores the picks.
