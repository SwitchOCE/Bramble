---
id: scenario-replays
group: prototype
size: small
headline: Sandbox scenarios replay the same fight until you change them
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#15
image: design-lab/main:docs/design-lab/game/plain_sandbox_scenarios_1688x780.jpg | The sandbox's Scenarios tab, with one loaded
option: That's what I'd expect
option: Use a new seed every time
suggested: That's what I'd expect
---
The sandbox, on the main menu, has a Scenarios tab with 15 ready-made fights, one for each of the mechanics we're testing. Each comes with a short "Watch" line telling you what to look for, like "the hit lands as 11 (Hunker), the Warden lives".

So that what you see matches that line, a scenario plays exactly the same fight every time you press Fight, as long as you haven't touched it. Once you edit either board, each Fight rolls the dice fresh, like any fight you build by hand.

{image:1}

**What we need from you:** is that what you'd expect?

**Why it matters:** it decides whether a scenario is a fixed demonstration or a starting point you can rerun for different outcomes.

We'd suggest keeping it: the scenario shows what it promises, and you can still get variety by changing anything at all.

## Detail

- **As built:** a loaded scenario replays its own seed until you edit it, so the fight matches its "Watch" line. Once edited, each Fight uses a new seed. Fights you build by hand always use a new seed.
- **Scenarios:** 15, taken from the mechanics library's scenes, one per mechanic.
- The suggestion is ours.

**The original question (prototype question 15):**
> "Scenario replays. A loaded scenario replays its own seed until you edit it, so what you see matches its "Watch" line. Once edited, each Fight uses a new seed. Is that what you'd expect?"

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/PLAYTEST.md`.
