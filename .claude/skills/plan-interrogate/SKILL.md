---
name: plan-interrogate
description: Cross-examine a build plan against the problem that started it, before any code is written, so every step, layer, table and decision either moves that problem or gets cut or deferred. Use before approving an agent-written plan, especially one that widens scope.
argument-hint: "[plan file or section] [the problem that started this work]"
disable-model-invocation: true
---

# Plan interrogation

Over-engineering usually comes in when a plan is approved, not in review: once a plan step is approved, every PR that builds it is "in scope". This skill questions the plan itself. Run it in a session that did not write the plan.

## 1. Brief

Ask the user, in one message, for what you can't know, unless `$ARGUMENTS` or the conversation already gives it:

- **The problem**: what started this work, in their words: a user's complaint, a bug, a goal.
- **Who it's for**: real users today and the next few months; scale.
- **Plans**: what's coming that the design should allow for, and what won't happen.

Don't proceed on a guessed problem.

## 2. Inventory

Read the plan and list, without judging yet:

- Each step, and what it builds.
- Everything it implies adding: tables and columns, recorded events, jobs, settings and flags, layers and abstractions, simulations and tooling, docs.
- Each decision, and **who proposed it**: the user's own words, or an agent's recommendation the user accepted. Quote the source. "Accepted a batch of recommendations" counts as agent-proposed.

## 3. Interrogate

For every step and every added thing, answer from the plan and the code, citing them:

- **Which part of the problem does it move?** Name it. "Supports a later step" is only an answer if that later step moves the problem.
- **What's the smallest version that would?** Compare it with what the plan builds. Name what the difference is for.
- **Who reads it, and when?** For anything recorded or stored: the step that first reads it. Nothing reads it in this plan means defer it.
- **Why not what exists?** Check the code for an existing table, service or rule that could do it.
- **What if it's dropped?** Say what the user would notice.

Then the plan as a whole:

- **When is the problem fixed?** Name the first step after which the user's problem is gone, and how they'd check. If that's the last step, or never, say so. That's the main finding.
- **Order**: could the fix for the problem come first, with restructuring after it, or not at all?
- **Checkpoints**: after which steps should the user re-check the original problem before the plan continues?

## 4. When the user pushes back

As in `/pr-interrogate`: agreement is not an answer. Hold a verdict with evidence, or concede and say exactly what to drop. Change it only for a new fact.

## 5. Output

A table: **Step or item | Moves the problem? | Proposed by | Verdict** (keep / shrink / defer / cut / ask) **| Why**.

Then:

- **Fixed after step**: the step at which the problem is gone, today and in your reordered plan.
- **Smallest plan**: the steps that fix the problem, in order.
- **Deferred**: what waits until something needs it, and what would trigger it.
- **Checkpoints**: where to stop and re-check with the user.
- **Open questions**: only what the user must decide.

Don't change the plan file unless the user asks.
