## Product
A Claude Code skill, `game-design-routes`, that AI agents load when they do game design work for the owner, a game designer. It ships with a background file. A separate project guidance file sits beside it for one game, Bramble: an asynchronous auto-battler in Godot inspired by Hearthstone Battlegrounds. In Bramble, an orchestrator agent runs designer, critic and playtester subagents to design tribes, cards, mechanics and systems.

It is compared with agents designing without guidance, which is how they have worked so far, with the owner correcting them by hand.

## Goal of this change
In the owner's words:
- "I think I can develop a few skills that will really help agents and improve design processes."
- "picking the right tool to bring to a problem is challenging"
- "I wouldn't try and force the agents into exactly that structure. It feels like it could be very token wasteful... suggest that like when you're doing these types of roles or doing these types of jobs, this may be the way you want to try and think. Or it can be helpful to think this way if you're running into issues."
- "There are no hard rules when it comes to design... use their judgment and their reasoning and decide what they think the best choice is."
- "we don't want it to be too lengthy. We want it to capture the essence of what we want the agents to do, and don't want to overwhelm the context window with just the skills."
- New requirement: "I want the skill to be generically about process. ... these skills are anchored to exactly Bramble-specific documentation, tier systems, right? That's a design system inside a game that already exists. That's a mechanic that can be changed. ... we might remove shop tiers, right? That's a game paradigm. This needs to be about the process of game design and how you go about doing it. It needs to be more general. You may want Bramble-specific documentation and guidance, and the skill could reference, look at your specific documentation and guidance for this project. But the fact that we even had tier stuff inside of the skill, I think, is also an issue ... I want that stuff separated out from the skill, which should be about process. And also write ... for Bramble specifically ... the minutia, the stuff that ... things that aren't general to all game design."

The owner's question: is the skill fit for purpose, and will it actually give better design results? Or is the process misguided? Give proper, candid feedback, including on whether the general/specific split is clean and whether it works.

## Done looks like
- The skill is about the process of game design and holds up for any game: card, board, video or tabletop. Nothing in it assumes one game's systems, such as tiers, shops or tribes.
- Game-specific facts live in project guidance, and the skill points agents to it.
- The Bramble file holds Bramble's specifics, accurate to Bramble's own docs.
- With the skill loaded, agents doing design or reviewing designs:
  - choose an approach on purpose and switch when stuck;
  - fix recurring problems at the right level instead of patching piece after piece;
  - size pieces for their place in the game;
  - produce interesting play patterns;
  - need fewer owner corrections.
- It stays short and isn't a rigid, token-wasting procedure.

## Must not change
The owner's stance that design has no hard rules and agents use judgment. Brevity.

## Target
- /home/alex/code/design-skills/game-design-routes/SKILL.md
- /home/alex/code/design-skills/game-design-routes/background.md
- /home/alex/code/design-skills/bramble-design-guidance.md

## Allowed reading (optional)
Read-only. Do not edit anything under /home/alex/code/Bramble-ideation, because a live session works there.
- /home/alex/code/Bramble-ideation/README.md and CLAUDE.md
- /home/alex/code/Bramble-ideation/docs/ideation/LEARNINGS.md, fundamentals.md, DECISIONS.md
- /home/alex/code/Bramble-ideation/docs/ideation/evidence/birds-case-study.md
- /home/alex/code/Bramble-ideation/docs/design/ (rulebook.md, power-budget.md, owner-notes/)
- /home/alex/code/Bramble-ideation/.claude/skills/triage/SKILL.md
