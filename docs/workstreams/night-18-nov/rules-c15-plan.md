# Plan: make the game follow rulebook v0.9 (18 Nov 2026)

## The owner's words

> I want you to ensure that the rules are up to date with the current version of the rulebook. And you have permission to fix all those kinds of bugs, like the field marshal and stuff. Like you should fix any bugs you find. There are changes to the rulebook in terms of how stuff moves between zones, etc. And I want that to be the case.

## What the audit found

The full audit is in [rules-audit.md](rules-audit.md). It read every rule in chapters 1 to 10 against `src/core` and the recruit screen at dev `960625f7`. Of 193 rules, 140 match, 24 differ, 14 are missing and 15 are N/A.

None of the owner's 17 Nov changes (source C15) is in the game. They are all about how cards move between zones:

| Rule | Rulebook says | Game does today |
|---|---|---|
| 4.3.7 | Sell from hand or board, for the same value | Board only |
| 7.2.4 | During the Recruit Phase, move a unit from board back to hand, free, any number of times | No such move |
| 7.2.5 | You can't return a unit to a full hand (7). The unit keeps its stats, buffs and origin | Not applicable, since there is no return move |
| 7.2.3 | A unit's effect fires when it is recruited (bought). Playing it triggers nothing | Fires when played from hand |
| 7.2.6 | The recruit effect also fires for units gained without buying: Discover, Triple Reward, and effects that add to hand | Fires only on play |
| 7.3.6 | The Triple Reward is added to hand when the triple forms | Added when the golden is played |

Only two cards have a play effect today:
- **Harvest Piper** (Mouse, tier 2) gives your other board Mice +2 Attack. It works as before on recruit: it buffs the Mice on the board when it is bought.
- **Master-at-Arms** (Badger, tier 4) gives a chosen friendly unit +1 Fury. When it is recruited it is still in hand, so which units it may pick needs a decision (question 1).

Both cards' text says "When played"; it changes to the recruit wording.

## Steps

Each step is one branch into `dev`, built by a Codex worker. Each passes `scripts/check.sh` and a scope review before it merges.

1. **Bugs the audit found**, on the owner's standing permission (running now):
   - Root loses a ghost's buffs.
   - A golden can fall below its golden base stats (7.3.4).
   - Master-at-Arms on an empty board, a third bug the audit found, is dropped here because step 2 replaces that targeting.
2. **Recruit timing** (7.2.3, 7.2.6). This comes first. If units could return to hand while effects still fire on play, Piper and Master-at-Arms could be replayed for endless buffs.
   - Unit effects fire through one path for every gain: buy, Discover pick, Triple Reward pick, and effects that add to hand. Playing triggers nothing.
   - A card lost to a full hand fires nothing.
   - A recruit effect with a target (Master-at-Arms) needs:
     - a target on the buy and pick actions
     - legal-action listing, so bots can use it
     - an aim step in the UI on buy, including a drag-buy onto a slot
     - an automatic choice when end turn auto-resolves a Discover
   - Goldens follow question 2.
   - Spells keep firing when cast.
   - Both cards' text moves to the recruit wording (ux-copy skill).
3. **Zone moves** (4.3.7, 7.2.4, 7.2.5).
   - Sell from hand:
     - the `sell` action gains a hand form
     - sale listeners fire for hand sales too (Gorger, Granary Glutton, Compost and Sweetbriar listen to sales)
     - only units sell from hand; spells don't
   - Board to hand: a full hand refuses the move, and the unit keeps its stats, buffs, origin and this turn's counters (Order uses). A test proves each.
   - UI:
     - drag a hand card up to the shop to sell it, as board cards sell today
     - drag a board card down onto the hand to return it
   - Bots need not use the new moves.
   - A 60 fps film of both drags, for the owner.
   - Economy units can work in the shop and then return to hand. That follows question 3.
4. **Triple Reward when the triple forms** (7.3.6).
   - The reward spell goes to hand the moment the triple forms. If the hand is full it is lost (7.1.2).
   - This removes the play-time reward path and its special case for a full hand.
   - The triple animation is updated to show the reward arriving.
   - Its tier follows question 4.
5. **Rulebook wording**, only with the owner's OK. It changes no decided rule.
   - 3.2.1 still says the tier-up cost drops by a flat 1. Point it at 4.6.3.
   - 5.3.5 and 5.3.6 say Created copies return nothing to the pool. Add the exception 4.3.2 requires: Created pool copies, such as Discover picks, do return. The code already does this.
6. **Build** for Windows, and Taildrop it to the owner's PC.

Steps 2, 3 and 4 merge into `dev` in that order, and the owner gets them in one build. They share `recruit.gd` and the recruit input code, so they run one after another.

**Checkpoints with the owner:**
- before step 2 starts, with questions 1 to 4 answered
- the build after step 4: the owner plays it and watches the drag film

## Not in this plan

- **Differences in systems that don't exist yet:** heroes, hero powers, rating, asynchronous opponents and tribe rotation.
- **Combat differences:**
  - the order of start-of-combat effects (9.3.2)
  - where delayed summons land (8.4.2)
  - when deaths are checked (9.6.3)
  - damage after each fight rather than after all fights (3.5.1)
  - Lieutenant's fallback target

  The owner accepted the game's current behaviour on 17 Nov, but these still differ from the rulebook, so the owner decides which side wins. They are listed in [rules-audit.md](rules-audit.md), to bring up after this plan.
- **Card text that disagrees with behaviour,** like the Field Marshal report: those get fixed as found, under "fix any bugs you find". This plan doesn't hunt for them.

## The owner's answers (18 Nov 2026)

1. Master-at-Arms on recruit: "Any unit, hand or board."
2. Golden recruit effects: yes, a golden fires its doubled recruit effect when the triple forms.
3. Economy units and free moving: "Prototype and design a lock keyword yourself. I mean, it's the intent is there. It doesn't, like, figure out the best way of achieving the intent. If you use the economy effect, it's on your board for the fight, or you have to sell it. You can't, like, cheese it and put it, like, you know, not have to commit an economy to the board. If you can find a different way around it other than this, that also works."
4. The Triple Reward's tier: read when you cast it.
5. Rulebook wording: not asked yet.

## The lock (orchestrator's design, a prototype, not decided)

The owner's intent: "If you use the economy effect, it's on your board for the fight, or you have to sell it." Their first idea was a keyword on each such unit: once played, it's locked on the board for the turn and goes back to hand at the start of the next turn (ideas log, entry 3).

Prototype: a general rule rather than a keyword.

> **A unit that worked this turn stays on the board until the fight.** You can still sell it, but you can't move it back to hand.

- A unit has "worked" when one of its own Recruit Phase effects changed something this turn. That includes:
  - a start-of-turn trigger fired
  - a sale or buy listener fired
  - an Order ability was used
  - a cost or income modifier changed the price of an action the player took
- Recruit effects (on buy) don't count, because they fire in hand.
- The card shows a small lock mark while it's locked. Its hover line says why: "Worked this turn: stays for the fight."
- Next turn it starts unlocked. If it works again, it locks again.

Why not the keyword:
- No card needs extra text, and every future shop-phase unit is covered without anyone remembering to add the keyword.
- Nothing jumps back to hand at the start of a turn.
- The keyword is still available if the owner prefers it. The lock check would then read the keyword instead of "worked".

Example: Gorger gains stats whenever you sell a unit.
- Sell two units: Gorger has worked, so it can't go back to hand this turn. It fights, or you sell it.
- Leave it in hand and it gains nothing. That's the commitment the owner asked for.

This goes into step 3, alongside free moving, so the loophole never ships open.

## Questions for the owner

Only question 5 above is still open.
