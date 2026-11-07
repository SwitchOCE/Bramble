# Critic: the reveal as a standard rule

Fresh critic, 7 Nov 2026. I ran one script over `reveal-data/probe-n1.csv` and played nothing.

**(1) Owner's words.** One line supports it: "Position during combat is very interesting" (02h). Two cut against it. "Just doing nothing is boring" (02h), and standing still is the screen's default. "This feels very brute force" (02b), and the case rests on a bot running 45 fights. The scout and the 0.5-place bar are agents' calls, not the owner's.

**(2) Round 10.** From round 9 on:
- In 35% of fights no swap gains over 3 points.
- In 53%, standing still wins ≥90% or ≤10% of the time.
- In 49%, some swap is worth 10+ points, on a crowded 7-v-7 board.

A person catches the obvious swaps (toad across their giant) and guesses the rest. That's about seven screens a game, half of them a Fight-button chore.

**(3) Misleading numbers.**
- +8.7 is win-rate points a fight. The bar is places a game, and the two don't convert.
- "Best +14.9" is scored against the enemy's board after its own simultaneous swaps. That is hindsight, not room for a skilled player.
- Hard is noisy: from round 9, 16% of its swaps are worse than standing still.
- The bar's shuffled arm now swaps at random, so the bar partly measures the reveal itself. Adopting a rule to pass a bot-against-random bar is backwards.

**(4) Placing and the scout.** Neither becomes pointless, since pinned units (1.44 places), Rings and bands stay recruit-phase choices. But matchup placing moves to the reveal, and the scout shrinks to a buying aid. That hurts the new tribes, whose design is the scout: Bridge Toad is "a scout test from turn 2 to turn 14", and Hunters "mark from last round's board".

**The bell and the tribes.**
- The swap must come before the bell; `reveal.md` doesn't say. After the bell, Mire stays on its slot but Quarry follows the animal, so a late swap dodges mud and never a mark.
- With the swap before the bell, "walling answers Hunters; moving doesn't" fails: the enemy sees Nip's lane and swaps a wall in. Both tribes become a one-swap guessing game.
- Birds: the real board shows who's away, which DECISIONS says "is meant to be guessed at". That's a leak.
- Oozes: fine.

**N.** N=1, if adopted; N=2 is a re-layout.

**(5) Cheapest disproof.** Make 20 probe reveals as screenshots or text. Three fresh reviewers each get 30 seconds a screen, with no simulation, to pick a swap or stand still. Score the picks on the probe's 32 fixed fight seeds.
- Under about +3, or mostly what a one-line rule finds: it's a chore, so drop it.
No UI is needed.

**(6) Simpler alternative.** Show the reveal only when a board holds slot-reading text (Mire, Quarry, Hedge Witch, Changeling and the like), with N=1. It appears only where `placing.md` found the value.

**(7) Change.** Run the reviewer test first. If it passes:
- Gate the reveal to slot-reading boards, with N=1.
- Swap before the bell.
- Hide Passage absences.
- Re-cost Bog folk and Hunters with the reveal on.

---
Bot search and hindsight inflate the numbers, and about half the late screens are chores. The reveal undercuts Bog folk and Hunters and leaks the Passage. Test it with reviewers judging by eye. If it passes, gate it to slot-reading boards, with N=1 and the swap before the bell.
