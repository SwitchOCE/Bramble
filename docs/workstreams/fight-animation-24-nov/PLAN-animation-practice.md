# Animation practice: plan (24 Nov 2026)

Runs beside pass 2 (`PLAN-pass-2.md`). Same branch and limits: nothing reaches `dev` or `main`; what is built into the game, and any rule or skill agents must follow, is the owner's call.

## The owner's words (24 Nov, dictated, filler removed)

> "Another thing I forgot to mention is that death animations in general might need work, and the player taking damage after a fight as well. We have all sorts of other things that we need animations for that I think we don't necessarily do a great job of. Triples are great. A triple animation is great, I really like that one. But a lot of the other stuff: what other animations do we have in the game beyond hits? Cards are going to have their own individual animations for damage triggers, or maybe special keywords."

> "I think we need to look at animations in the game in general, think about rules for good animations, and maybe even do research about what makes animations feel good in games, examples of what people love in animations and what's done well, guidance. Are there skills out there for doing good animations, maybe on GitHub, for helping AI agents do it? Or is it better not to use those skills and just do it ourselves with some guidelines we make internally?"

> "I feel like animations are a weak spot in our process and we need to improve them. Your general goal is not just improving the current animations but also helping improve the process for future ones, and having animation quality in the game feel good. Like you're a professional animator and you're in charge of this part of the studio, almost. But obviously it needs to be AI-agent capable."

## Goal

Two outcomes: the game's animations feel good, and agents have a process that reliably makes good ones, given that no agent can watch motion at speed (`docs/AGENT-BLIND-SPOTS.md`).

## Steps

1. **Three studies at once:**
   - **Inventory** of every animation in the game today (shop, buying, selling, refresh, tier-up, triples, the move into the fight, attacks, hits, triggers, buffs, deaths, summons, the result, damage to the player, elimination, hover and drag): where each is in code, its timings, what the owner has said of it (triples loved; fight hits "doesn't feel right yet"), and which film fixtures already exist for it.
   - **What makes animation feel good:** the published craft (animation principles, game feel, juice, hit-stop, anticipation and follow-through, easing, timing, readability under speed), talks and writing by working game animators, and examples players love, with sources. Turned into rules a person or an agent can check.
   - **Skills and tools for agents:** what exists on GitHub and in skill collections for agents making animation or motion (game feel, motion design, Godot tweens, Lottie, CSS motion); what each does, quality, licence, and whether it would help, hurt, or teach us something. Recommend: use, adapt, or write our own.
2. **Draft the practice:** written motion guidelines for Bramble (rules with numbers where the research supports them, each saying how it is checked), and a process agents follow: brief, reference study, timing spec in frames, film with `tools/feel`, per-frame log and charts, the comparison viewer, what an agent may claim, and what only the owner judges. Proposed as a project skill; the owner decides whether it becomes one.
3. **A ranked list of the game's weakest animations** from the inventory against the guidelines, with what to do for each. Death and damage to the player are already flagged by the owner; pass 2 already covers attacks, buffs, combos and several deaths at once.

## Checkpoints

After step 1: the inventory and the research summary to the owner. After step 2: the guidelines and process, before any skill is installed or any rule binds agents.

## Changed after the plan review (24 Nov)

A fresh agent questioned this plan. Its main point: as written, no step makes an animation better; it ends in documents and a list. Taken:
- **Inventory builds on what exists:** `research/our-events.md` and the 20 Nov fix round's `anim-recruit` and `anim-fight` notes, checked against today's code, with the gaps marked.
- **A look back, added:** how the triple (loved) was made, compared with fight hits and the 20 Nov death call (not liked). The lessons feed the process.
- **The research is capped** at what becomes a checkable rule.
- **Guidelines extend what exists** (the Motion sections in `design-handoff` and `design-system`, and the brief template) before any new skill is proposed. The owner decides.
- **Numbers are starting points.** The owner's 18 Nov rule puts feel ahead of any specific timing.
- **A pilot, added:** run the drafted process on the two problems the owner named, damage to the player after the fight and the look of a single death. Film the options; show any new visual element as a picture first; the owner judges. Staggered deaths stay in pass 2.
- **Revise after the pilot,** then the ranked list and the owner's decision on rules or a skill.
- **The process covers:** animations for a single card or keyword, sound cues that move with a timing, a Windows build as the last check, and where the quality bar hooks in (brief, handoff, a film-and-compare gate before a motion change merges).
- **Pass 2's results** feed in as evidence once they land; no scope is added to running workers.

Open for the owner: the pilot now or later; whether card- and keyword-specific animations are in scope now; whether the practice extends the existing skills or becomes its own.
