---
name: bramble-art
description: Make, prompt, assemble or review art for Bramble (card art, card frames, screen and UI art, concept pictures, Codex image batches), or brief another agent to. Says which recipe to follow and how a picture batch is run. Not for screen layout (design-critique) or in-game wording (ux-copy).
---

# Making art for Bramble

- **Card art: follow `docs/design/art-direction/card-art-recipe.md` as written.** It is the process the owner approved: the prompt, the shape guide, the runner, the check and the assembly. The six tier frames are finished, in `docs/design/art-direction/frame-lab/final/`.
- **Other pictures** are made by Codex workers with their built-in image tool. `tools/art/run-codex-image.ps1 -PromptFile <file> -OutDir <dir>` runs one batch, and `-Image <path>` attaches a reference picture. The prompt files next to it show the format: a fixed header, then numbered `filename -- description` items.
- **Codex workers can't see this skill.** Put the recipe's path, or the prompt itself, in their brief.
