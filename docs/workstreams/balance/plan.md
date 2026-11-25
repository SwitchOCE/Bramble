# Balance plan (20 Nov 2026)

Proposed by Balance Orchestrator 2 and checked by a fresh agent (plan interrogation). **Approved by the owner, 20 Nov 2026:** "I agree with all of your proposals. They seem very reasonable."

The aim is the owner's, in [note 2026-11-19b](../../design/owner-notes/2026-11-19b-balance-pass-aims-and-method.md). Balance is measured with the league's strong bots, on a field of strong runs ([note 2026-11-20a](../../design/owner-notes/2026-11-20a-strong-bots-for-balance.md); [ghost plan, step 5](../third-run/ghost-plan.md)). The stopping test is the test of a bot. It is not a gate on changing a card ("The card step" below). Where balance stood at the start: [hand-over.md](hand-over.md).

## What counts as balanced

- With its most-played tribes left out of the shop, a strong bot still plays well: each tribe it then ends on in at least 5% of games averages between **3.8 and 5.2** places out of 8. The report says how far the bot fell and what it ended on. One match, about 9 minutes: `league ghost-match --without <every unit of those tribes>`, paired with the same games played with nothing left out.
- Left free to choose, the bots end on each tribe **at least 5%** of the time.

No bot is locked to a tribe. The owner, 25 Nov: "I don't think a bot held to each tribe is necessarily a good thing. As the game goes on, I want that to be less and less of a good strategy", and "We need to have bots that try to win". Taking tribes away replaced the locked-tribe target on the owner's yes of 26 Nov; the 3.8 to 5.2 band is carried over from it. On 25 Nov, with Badgers and Locusts left out, red-c14 fell 0.79 places and ended on Pigeons (4.44), Briars (4.95) and Mice (4.64).

Where a bot avoids a tribe, check first that it can play that tribe's cards (the step-5 rework checks), before reading the avoidance as weakness ([note 2026-11-19a](../../design/owner-notes/2026-11-19a-balance-reads-bot-preferences.md)).

## The plan

1. **Pitches, nothing built until the owner picks.** Each card is shown as in game, with the four kinds of change weighed (numbers, tier, replace, rework), a defence of the card, the support that may be the real cause, a rough power number for utility effects, and a tier check (the `bramble-design` skill). In order:
   1. **Wing Commander:** replacement designs.
   2. **Neutral and tech units.** The neutral pool is units with no tribe, offered in every game: about 8, one or two per tier, mostly tech and scam units, including a Guarded answer to Cleave. The two archived candidates (Harrier, Ballista) are in it.
   3. **One page per tribe:** Briars (the Compost), Locusts (late game, Gleaner, Eighth Plague, Granary Glutton, Hoppers and Tide, Swarm-lord), Badgers (Fury from first principles, T5–T6), the gold cards, and Mice and Pigeons (the tuning checked for buffs that lean on each other). Each page includes its tier-one and utility-effect checks.

   Where one card's strength is in doubt, measure it on recorded boards with the card step below. A fight on a made-up board may illustrate a pitch; it is not evidence of a card's strength.
2. **Build what the owner picks,** on branches from `dev`. Each step passes the gate and a scope review; the Ghost Build Orchestrator hears before it merges.
   - **New cards and reworks land in one batch, agreed with the ghost orchestrator, before the third run's first climb.** Anything not ready waits until between climbs. **Nothing merges during a climb.**
3. **Tune between climbs,** from the card step below and from what the strong bots pick and how they place, against the target above. No double-taps ([note 2026-11-19c](../../design/owner-notes/2026-11-19c-double-tap-nerfs.md)).
   - **A card the card step marks may be changed before a bot passes its stopping test.** The referee stops the climb, the change merges, the field is cut again at the new rules, and the bots climb on from where they were. The owner was asked this on 25 Nov and said yes, and again on 26 Nov. Why: the 22 Nov flag on the Badger cards waited three days behind "tune only from passed bots", and 15 minutes of card tests confirm it.

## The card step

How one card's power is measured, cheap steps first. The owner said yes to it on 26 Nov 2026: "I was happy with all of the proposals so proceed". Definitions, costs and each measure's "worth a look" line: [card-power/definitions.md](../card-power/definitions.md). Why it exists: [card-power/trace.md](../card-power/trace.md). Everything the owner approved with it: [card-power/proposals.md](../card-power/proposals.md).

| Step | What | When |
|---|---|---|
| 0 | First-sight read: the owner, or a fresh agent, marks any card that looks too strong or too weak on sight. The pitch records it | When a card is designed or changed |
| 1–2 | The card report, `tools/league/card_report.sh <match dir>` (about 13 minutes). It marks cards worth a look, and says "nothing marked" when nothing is | After every kept bot version, and on every balance match, before the match's records are deleted |
| 3 | Left out of the shop (about 10 minutes a card), for every marked card, every card the owner names, and every new or changed card | The same day |
| 4 | A read: one line that explains the mark, or a proposal to the owner with the card shown as in game | The same day |

- The measures are hints from imperfect bots. A mark means look, not change.
- A card no bot buys, a card a bot is built around, and a tier the bots rarely reach each have their own route (the edge-case table in proposals.md).
- The owner's calls on cards are a test set: [card-power/known-cases.md](../card-power/known-cases.md). A new measure or a change to this process is run against it first.
- When a design estimate and a measurement disagree, the measurement on a strong field wins, and the owner sees both.
- The teams hand balance their own card measurements ([third-run brief, section 8](../third-run/third-run-brief.md)).

## How far the balance orchestrator goes without asking

- Designs always go to the owner first.
- Once the owner picks a design, it is built and merged to `dev` without asking if it passes the gate and the scope review.
- Tuning numbers from bots that passed the stopping test merge to `dev` without asking.
- A change to a card the card step marks, made before a bot has passed, goes to the owner as a proposal first.
- `main` only on the owner's say-so.

## Out of scope

Screens, animation and bug fixes go to the session that owns the playable build, or to the owner. The Rust engine and `tools/league` are the ghost orchestrator's. `docs/workstreams/tribe-process/plan.md` is a separate draft.
