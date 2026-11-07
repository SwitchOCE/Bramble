# The reveal by eye

**7 Nov 2026, `ideation/c-reveal2`: 70366f7 (six tribes) with the reveal merged in.**

## Job 2: the critic's test. **FAIL.**

- **The screens.** 20 positions from 4 spread-suite games (seeds 41-44, every strategy, reveal on), picked at random by round: 7 from rounds 3-5, 7 from 6-9 and 6 from 10 on. Every tribe appears.
- **What a screen shows.** Both boards with stats, card text, Rings, hex and Bellies. A Nest shows only its Egg, and swaps come before the bell.
- **The readers.** Three fresh agents, blind to each other and to the scores. Each got only the screen file and the rule in 3 lines.
- **Scoring.** 32 fixed fight seeds against the enemy as it stood: win-rate points over standing still, with 95% CIs over the 20 screens.
- **The one-line rule**, written first: put your highest-Attack unit across their front unit with the least Health.

| Pick | Gain | Real decisions | Stood still |
|---|---:|---:|---:|
| Random swap | +0.7 ±3.7 | | |
| One-line rule | +2.3 ±6.7 | | 2 |
| Reader 1 | +6.2 ±7.3 | 12 of 20 | 9 |
| Reader 2 | +4.9 ±7.2 | 11 | 13 |
| Reader 3 | +5.2 ±7.4 | 11 | 12 |
| Hard (45 fights) | +8.4 ±7.2 | | 2 |
| Best swap (hindsight) | +19.7 ±9.4 | | |

- **By eye minus the rule:** +3.8 ±7.5, +2.6 ±6.4 and +2.9 ±6.1; pooled +3.1 ±6.5. None is clearly above the rule.
- **One screen carries the readers.** On screen 2 all three moved their 15/21 away from an enemy Changeling, worth +73. Without it, they average **+1.9 ±1.5**.
- **Standing still was right on 6 of 20** (no swap gains over 3 points). On the other 14 the best swap averaged +28, but the readers found little of it.

**Verdict.** The readers clear +3 only on one obvious screen, and none is clearly above the rule. As a decision for people, the reveal is a chore on about half its screens, and its value sits in reads not made at a glance. My recommendation:
- Drop it as a standard rule and keep the flag off.
- Revisit it only in the critic's gated form: when a board holds a Changeling, Hedge Witch, Mire or Quarry. Screen 2 is that case.

## Job 1: the six-tribe placing bar

*Running:* reveal off with 1000 paired seeds, then reveal on with the shuffled arm still at the reveal. Pending.

- **For reference**, on the old build with reveal N=1 and the shuffled arm swapping at random: 1.01 ±0.15 (1000 seeds).
- **Partial data** (1797 Hard seats, reveal off): Bog folk builds hold 21% of seats and Hunters 17%. Oozes and Birds are under 2%.

## Data

[reveal-data/eye/](reveal-data/eye/):
- the screens and the prompt;
- the readers' picks;
- `answers.json`: every swap's score, Hard's pick and the rule's pick;
- `score.py`.

Screens come from `tools/sim/reveal_screens.gd`.
