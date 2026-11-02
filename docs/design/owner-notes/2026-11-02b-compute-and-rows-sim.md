# Owner direction: compute limits, saved rules and the rows sim

Said by the owner in chat on 2 November 2026, while Stage 1 of the design pass was running.

## Compute

If the simulation runs again, use 50% of the CPU, not maxed out.

Simulations that are going to be incredibly heavy and use more than half the computer: the agent starting it should ask me about the state of the computer at that time, whether it's okay to exceed the limit, and what the limit should be. Up to 50% is okay. If you are thinking about seeking clarification, do not just accept 50%. Ask for clarification, because your task could clearly use more if it's available.

Load across all agents on this computer is an issue that has come up a few times. And it's not just CPU usage; it can also be memory.

*[Editor note: the owner approved the exact wording of the rule now in the project CLAUDE.md, "Heavy compute such as simulations may use up to half the CPU cores and up to half the free memory without asking. …"]*

## Saved rules

Don't save any rules for all future agents. You're not allowed to save rules for all future agents without asking me. You must propose rules. You may not save rules under any circumstances unless you propose them to me first and I agree to the rule in its exact wording.

*[Editor note: this came after Claude saved a CPU rule to its memory without asking. That memory was deleted.]*

## The rows sim

Why are the Python scripts so resource-intensive that they're using so much of the PC? What is actually being done in them?

The fully random placement stuff is very bottom-up design. I think we should not need even this much simulation to have instincts about what to do. This feels very brute force. Can we approach this in a smarter way that is less resource-intensive? The script is very, very resource-intensive, even after it's been shrunk. Fully randomised placements feel like overkill. And if we're going to be doing work of this size, is Python even the correct tool for it?

## Answers to Claude's questions

- **Shrink the rows sim's default sizes:** "Yes, shrink it."
- **Claude's recommendation:** keep the full run's results as the record, keep the smaller defaults so an accidental re-run stays small, and answer future position questions with small hand-built puzzle boards when they come up, instead of rebuilding the study now. The owner: "Agreed."

*[Editor notes:*
- *The full rows run (about 250 million fights, roughly 16 minutes on all 24 cores) had already finished with a "keep the rows" verdict. Its tables are the committed record.*
- *Claude's proposal for puzzle boards: hand-build 10–20 boards where placement should matter, score all 35 front/back splits against a rule of thumb, and stop each comparison once the answer is clear.*
- *On Python: Claude's view was that the cost came from the experiment's design more than the language. The real headless rules sim belongs in the game's engine core later.]*
