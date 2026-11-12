## Product
A Claude Code skill, `game-design-routes`, that AI agents load when they do game design work for the owner, a game designer. The main use is Bramble, an asynchronous auto-battler in Godot inspired by Hearthstone Battlegrounds. In Bramble an orchestrator agent runs designer, critic and playtester subagents to design tribes, cards, mechanics and systems. The owner also wants the skill to work for game design in general.

What it's compared against: agents designing with no guidance, as they have so far, with the owner stepping in by hand.

## Goal of this change
In the owner's words:
- "I want to extract my design philosophy and contrast that to how the agents are designing and how I think about design. Because I think I can develop a few skills that will really help agents and improve design processes."
- "picking the right tool to bring to a problem is challenging"
- On the route process: "I wouldn't try and force the agents into exactly that structure. It feels like it could be very token wasteful... suggest that like when you're doing these types of roles or doing these types of jobs, this may be the way you want to try and think. Or it can be helpful to think this way if you're running into issues."
- "There are no hard rules when it comes to design... use their judgment and their reasoning and decide what they think the best choice is."
- "we don't want it to be too lengthy. We want it to capture the essence of what we want the agents to do, and don't want to overwhelm the context window with just the skills."

The owner's review question: will this skill be fit for purpose and actually work, giving better design results? Or is the process misguided? Give proper, candid feedback.

## Done looks like
With the skill loaded, agents doing design work:
- choose an approach on purpose, and switch when stuck;
- fix recurring problems at the right level (system, mechanic or content) instead of patching card after card;
- place power at the right tier;
- produce designs with interesting play patterns and cross-tribe synergies;
- need fewer owner corrections.

The skill stays short enough that loading it doesn't crowd an agent's context, and it doesn't turn into a rigid procedure that wastes tokens.

## Must not change
The owner's stance that design has no hard rules and agents use their own judgment. Brevity.

## Target
- /home/alex/code/design-skills/game-design-routes/SKILL.md (the skill)
- /home/alex/code/design-skills/game-design-routes/owner-notes.md (the reference file the skill points to)

## Allowed reading (optional)
These describe Bramble and the problems its design agents have had. They are read-only: do not edit anything under /home/alex/code/Bramble-ideation, because a live session is working there.
- /home/alex/code/Bramble-ideation/README.md and CLAUDE.md
- /home/alex/code/Bramble-ideation/docs/ideation/LEARNINGS.md
- /home/alex/code/Bramble-ideation/docs/ideation/fundamentals.md
- /home/alex/code/Bramble-ideation/docs/ideation/evidence/birds-case-study.md
- /home/alex/code/Bramble-ideation/docs/design/owner-notes/ (the owner's dated notes)
