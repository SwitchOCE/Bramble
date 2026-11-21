# Balance plan (20 Nov 2026)

Proposed by Balance Orchestrator 2 and checked by a fresh agent (plan interrogation). **Approved by the owner, 20 Nov 2026:** "I agree with all of your proposals. They seem very reasonable."

The aim is the owner's, in [note 2026-11-19b](../../design/owner-notes/2026-11-19b-balance-pass-aims-and-method.md). Balance is measured only with bots that passed the third run's stopping test ([note 2026-11-20a](../../design/owner-notes/2026-11-20a-strong-bots-for-balance.md); [ghost plan, step 5](../third-run/ghost-plan.md)). Where balance stood at the start: [hand-over.md](hand-over.md).

## What counts as balanced

- Locked to each tribe, a bot that passed the stopping test averages between **3.8 and 5.2** places out of 8.
- Left free to choose, the bots end on each tribe **at least 5%** of the time.

Where a bot avoids a tribe, check first that it can play that tribe's cards (the step-5 rework checks), before reading the avoidance as weakness ([note 2026-11-19a](../../design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md)).

## The plan

1. **Pitches, nothing built until the owner picks.** Each card is shown as in game, with the four kinds of change weighed (numbers, tier, replace, rework), a defence of the card, the support that may be the real cause, a rough power number for utility effects, and a tier check (the `bramble-design` skill). In order:
   1. **Wing Commander:** replacement designs.
   2. **Neutral and tech units.** The neutral pool is units with no tribe, offered in every game: about 8, one or two per tier, mostly tech and scam units, including a Guarded answer to Cleave. The two archived candidates (Harrier, Ballista) are in it.
   3. **One page per tribe:** Briars (the Compost), Locusts (late game, Gleaner, Eighth Plague, Granary Glutton, Hoppers and Tide, Swarm-lord), Badgers (Fury from first principles, T5–T6), the gold cards, and Mice and Pigeons (the tuning checked for buffs that lean on each other). Each page includes its tier-one and utility-effect checks.

   Where one card's strength is in doubt, rough constructed-board fights at turn thresholds, marked interim.
2. **Build what the owner picks,** on branches from `dev`. Each step passes the gate and a scope review; the Ghost Build Orchestrator hears before it merges.
   - **New cards and reworks land in one batch, agreed with the ghost orchestrator, before the third run's first climb.** Anything not ready waits until between climbs. **Nothing merges during a climb.**
3. **Tune between climbs,** only from bots that passed the stopping test: what they pick and how they place locked to each tribe, against the target above. No double-taps ([note 2026-11-19c](../../design/owner-notes/2026-11-19c-double-tap-nerfs.md)).

## How far the balance orchestrator goes without asking

- Designs always go to the owner first.
- Once the owner picks a design, it is built and merged to `dev` without asking if it passes the gate and the scope review.
- Tuning numbers from bots that passed the stopping test merge to `dev` without asking.
- `main` only on the owner's say-so.

## Out of scope

Screens, animation and bug fixes go to the session that owns the playable build, or to the owner. The Rust engine and `tools/league` are the ghost orchestrator's. `docs/workstreams/tribe-process/plan.md` is a separate draft.
