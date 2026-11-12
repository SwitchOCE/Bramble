# Plan: publish the game-design-process skill into the Bramble repo

## Owner's words
- "Okay, you can publish the skills into the Bramble repo now as a result. I'm not sure which branch or work tree is best to put them in. How do we plan on, because the repo's in a bunch of different branches and work trees states, like where are you planning on loading it?"
- Earlier: "It should be a when instructed to only. And an orchestrator can instruct a worker to do so."
- Earlier: the skill "should be about process", and Bramble specifics are kept separate in their own guidance doc.

## Facts found
- Bramble has about 16 worktrees. Design work happens on `ideation/main`, checked out at `/home/alex/code/Bramble-ideation`, where the live "Bramble Ideation 2" orchestrator session works. That checkout is clean at 4db7b177.
- `ideation/main` already holds the repo skills (`.claude/skills/triage`, `plan-interrogate`). The main checkout `/home/alex/code/Bramble` is on `design/tribes-and-budget` and has no skills.
- `docs/ideation/ORCHESTRATION.md`:
  - Never touch `main`. No PRs.
  - Outside agents push a branch named `ideation/codex-<slug>` that changes only `docs/`, and put any question in the commit message.
  - The orchestrator merges these branches after `check.sh --docs-only`.
  - Every step passes the Actions gate and a fresh reviewer before it merges into `ideation/main`.
  - Most workers are Codex (Sol/Astra), not Claude. They read files; they can't use the Skill tool. Codex Cloud and Claude cloud routines see only the repo, not `~/.claude/skills`.

## Steps
1. Create a new worktree, `/home/alex/code/Bramble-ideation-skill`, from `origin/ideation/main` on a new branch, `ideation/codex-design-process`. Don't touch the live checkout.
2. Add the files:
   - `.claude/skills/game-design-process/SKILL.md` and `background.md`
   - `docs/design/bramble-design-guidance.md`, with its status line updated to say where it now lives

   Don't edit `CLAUDE.md`; the orchestrator owns it.
3. Commit. The commit message explains to the orchestrator:
   - the branch isn't docs-only, because it adds a skill folder;
   - the owner approved publishing on 10 Nov;
   - workers should use the skill only when told to;
   - Codex workers should be told the path to read;
   - it asks the orchestrator to add a one-line pointer to the skill and the guidance doc in `CLAUDE.md`, and to answer the open question in the guidance doc in DECISIONS.
4. Push only that branch to origin. Never push to `main`, and don't merge it ourselves: the orchestrator merges it through its own gate and reviewer.
5. Optionally, also install the general skill globally in `~/.claude/skills/game-design-process` for other local projects. Keep the repo copy as the one Bramble agents use.
