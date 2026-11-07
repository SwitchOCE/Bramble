# Critic: the reveal as a standard rule

Fresh critic, 7 Nov 2026. Read `reveal.md`, `placing.md`, PLAN Done means, owner notes 02, 02b, 02h, 02i, and `bog-folk.md`, `hunters.md` on `ideation/tribes56`. I ran one script over `reveal-data/probe-n1.csv` (sides with 2+ units). I built and played nothing.

**(1) Owner's words.** Nothing forbids it, and one line supports it: "Position during combat is very interesting" (02h). Two lines cut against it. "Just doing nothing is boring" (02h): the screen's default is standing still. "Fully randomised placements feel like overkill... very brute force" (02b): the case rests on a bot running 45 fights. The scout and the 0.5-place bar are agents' calls, not the owner's.

**(2) Round 10.** From round 9 on, the probe shows:
- In 35% of fights no swap gains more than 3 points.
- In 53% standing still wins at least 90% or at most 10%, so nothing matters.
- In 49% some swap is worth 10+ points.

So about half the screens are a Fight-button chore. The other half hold a real gain, but on a 7-v-7 board with Mire, Bitter, Pack, Quarry, Bellies and Rings. A person finds the obvious ones (toad across their giant, Changeling across a 1/1) and guesses the rest. That's about seven screens a game, half of them hollow.

**(3) Misleading numbers.**
- +8.7 is win-rate points a fight from simulated fights. The bar is places over a whole game. They don't convert.
- "Best +14.9" is scored against the enemy's board *after* its swaps. Swaps are simultaneous, so that's hindsight no player can reach. It is not "room for a skilled person".
- Hard's choices are noisy: from round 9, 16% of its swaps are worse than standing still.
- The opponents are Hard bots that swap 96% of the time. A person's opponents and a person's eye both differ.
- The bar's "shuffled" arm now also swaps at random, so a pass would partly measure the reveal itself. Adopting a rule to pass a bot-against-random bar is the wrong way round.

**(4) Recruit placing and the scout.** Neither becomes pointless: pinned units (1.44 places), Rings and bands stay recruit-phase choices. But matchup placing moves wholesale to the reveal, and the scout drops to a buying aid. That's good for Hedgerow and Fairies. It's bad for the two new tribes, whose identity *is* the scout: Bridge Toad is "a scout test from turn 2 to turn 14", and Hunters "mark from last round's board". With the reveal, each becomes a simultaneous one-swap guess.

**Bell and tribes.**
- The swap must come before the bell. After it, Quarry follows the animal and Mire stays on the slot, so a late swap would dodge mud but never a mark. The reveal page doesn't say which comes first; it has to be written down.
- With the swap before the bell, "walling answers Hunters; moving doesn't" stops being true: the enemy sees Nip's lane and swaps a wall into it.
- Birds: the reveal shows the real board, so it shows who is away. DECISIONS says the Passage's surprise "is meant to be guessed at". That's a leak to fix.
- Oozes: fine, since a Belly's contents are already public.

**N.** N=1 is right if it's adopted. N=2 becomes a re-layout.

**(5) Cheapest disproof.** Make 20 reveal screens from the probe seeds as text and pictures. Three fresh reviewers each get 30 seconds a screen to pick a swap or stand still, with no simulation. Score their picks on the probe's 32 fixed fight seeds.
- If they average under about +3, or most of their value comes from a one-line rule, the screen is a chore. Drop it.
- Also log how often they said "nothing to do".

This needs no UI and no bot changes.

**(6) Simpler alternative.** Reveal only when a board holds slot-reading text (Mire, Quarry, Hedge Witch, Changeling and the like), with N=1. Most fights skip the screen, and the screen shows up exactly where `placing.md` found the value. The other option is to make the reveal a card or hero effect ("Spyglass") rather than a rule, so that *when* to use it is the decision.

**(7) Verdict: change.** Run the reviewer test first. If it passes, adopt it gated (slot-reading text only), N=1, swap before the bell, Passage absences hidden. Re-measure Bog folk and Hunters with the reveal on before building the screen.

---
Bot search inflates the case, and "best" is hindsight. About half the late screens are a chore. The reveal undercuts Bog folk and Hunters, whose design is the scout, and it leaks the Passage. Test with reviewers judging by eye first. Then gate the reveal to slot-reading boards, keep N=1, swap before the bell.
