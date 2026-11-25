---
name: bramble-art
description: Make, prompt, assemble or review art for Bramble (card art, card frames, screen and UI art, concept pictures, Codex image batches), or brief another agent to. Says which recipe to follow and how a picture batch is run. Not for screen layout (design-critique) or in-game wording (ux-copy).
---

# Making art for Bramble

- **Card art: follow `docs/design/art-direction/card-art-recipe.md` as written.** It is the process the owner approved: the prompt, the shape guide, the run in a Codex worker, the check and the preview. There are no frame pictures: the game draws the card's lead frame in code, the same at every tier (the L1 look, `docs/design/look-l1/`). The recipe says which part of the picture the card shows and where the Attack and Health discs sit. The art in the game stays as it is for now (owner, 25 Nov: "card art replacement can happen later").
- **Other pictures** are made by Codex workers with their built-in image tool. Start one as step 2 of the card art recipe does, with your reference picture's path in place of the guide's (or none). The prompt files in `tools/art/prompts/` show the format: a fixed header, then numbered `filename -- description` items.
- **Codex workers can't see this skill.** Put the recipe's path, or the prompt itself, in their brief.
