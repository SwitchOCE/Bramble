# Fix round, 20 Nov 2026: plan for the owner to approve

A proposal, not decided. Written by the orchestrator on 20 Nov 2026 against `dev` at 5d697e07, the branch the owner's builds come from. The recommendation page (link in the PR) holds the before shots, the mock-ups, the art and the design proposals this plan refers to. The owner approves steps one at a time.

**Base: `dev`.** `main` is 214 commits behind dev. Everything here lands on dev through PRs; nothing goes to `main` without the owner's say-so.

## The owner's decisions, one line each

1. Hand overflow: a waiting pile next to the hand (recommended), or let the hand go over 7? Is there a limit on the pile (proposed: none)?
2. Buying straight onto the board with a full hand, and swapping a hand card with a board unit: OK as rules? Should the bots get both moves now (proposed: yes, so league balance plays the same game)?
3. Skip: a "Skip" button, with Space still skipping; clicks elsewhere do nothing. OK?
4. Duplicate and triple marks: count only cards you own. Keep the faint edge on the copies you own?
5. Art: choose A or B for each of the 16 cards (12 new Mouse and Pigeon units, 3 spells, the Triple Reward). "All A" is the default if you'd rather not pick each.
6. Shop layout: A (two wings), B (one purse) or C (gold on top)?
7. Type line on the card: above the stats or under the top point?
8. Keyword tooltips: in the left light, or along the top?
9. Keyword looks: which to build, and keep the round marks under the card?
10. The golden rule ("stats and the signature double"): which part of each card doubles. How strong each golden ends up (its numbers, Fury 1 or 2 on the free-attack goldens) goes to the balance session.
11. **Settled 20 Nov.** The owner: "you can do those, I don't have a preference, give me suggestions." The orchestrator's picks:
    - end-of-fight effects move to the start of your turn, and Grudge becomes "Grudge 1";
    - Grudge keeps paying units that died (today's rule);
    - this round builds the golden engine support (step 9), and the balance session sets the 12 goldens' texts and numbers;
    - both land before the first climb, in the shared window.
12. Old Brock: the bots' answer is on the page. Any change to him goes to the balance session with the rest of the Badgers, unless you rule on it here.
13. Animations: which prototypes to build first.

## Steps

Steps 1 to 5 are bug fixes. Their rule calls are in decisions 1 to 5; once those are answered they need no more design. Steps 6 to 12 wait on the owner's choice of design first.

Every step that changes code passes two gates before it merges to dev: the runtime gate (the project's tests, `scripts/check.sh`, and a check on the running build named in the step) and a scope review by a fresh `scope-reviewer` agent on the step's commits, briefed with the owner's words and this plan.

### Quick fixes

**Step 1. Buy onto the board, and swap from the hand.** Items 2 and 3.
- Changes: a core action that buys a shop unit straight into an empty slot, allowed with a full hand. It keeps the bought flag (sell price) and fires Recruit effects as a normal buy does. Dropping a hand unit on an occupied slot swaps the two; the board unit takes the hand card's place. Rulebook 4.2.1, 4.2.2 and 7.2 updated.
- Cards checked: four cards fire on gain (Master-at-Arms, Harvest Piper, Hayloft Aunt, Quartermaster). None fires on play. All four behave the same bought onto the board. Hayloft Aunt's Cousin and Quartermaster's hand target go through the hand, so they meet step 3's waiting pile. Reserve and The Colonel's double Renown count only hand units, so a unit bought onto the board doesn't get them; that is the same as playing it today.
- Bots: `src/core/recruit/legal_actions.gd` lists only empty slots for a play, so bots learn both moves only if they are added there (decision 2). The ghost build orchestrator ports every rules change to the league's Rust engine (`tools/league/bramble-engine`) and re-pins it; send it each rules PR number as it merges (steps 1, 3, 8, 9, 10 and anything else under `src/core` or `src/content`).
- Depends on: decision 2, and step 3 (both touch `_gain` and `_buy` in `recruit.gd`; step 1's full-hand checks need the waiting pile).
- Checked by: tests for buy-to-slot (gold, sell value, Recruit effects, full hand) and for the swap; look shots of b02 and b03 again, against the mock-ups; a film of both drags (`tools/feel`); the owner tries both in a Windows build.

**Step 2. Skip button.** Item 5.
- Changes: left click no longer skips the fight or the result. A "Skip" button in the right light skips; Space still does.
- Depends on: decision 3.
- Checked by: an input test (a click on the board doesn't skip; the button and Space do); a shot compared with `skip.html` (`tools/look/compare.py`).

**Step 3. Nothing is lost to a full hand.** Item 1.
- Changes: rule 7.1.2 changes from "lost" to "waits". A card gained with a full hand goes to a waiting pile and joins the hand, oldest first, when a place frees. The pile stays across turns. It covers the Triple Reward, Discover picks, Hoppers, Cousins and every other gain. The pile is drawn beside the hand with a count, and hovering it lists the cards. The two tests that pin the loss (`tests/core/test_triples.gd`) are rewritten.
- Depends on: decision 1.
- Checked by: tests for each way a card is gained; replaying the b01 game path (a triple at 6/7) and seeing the reward wait and then arrive; a film of the slide-in.

**Step 4. Duplicate and triple marks.** Item 4.
- Changes: the marks count only copies you own (hand and board). One owned: the soft glow on matching shop cards. Two owned: the triple glow and foil on matching shop cards. They update as the hand and board change.
- Depends on: decision 4.
- Checked by: unit tests for the marks in each case (0, 1, 2 owned; shop copies never count; goldens); shots of both cases against `duplicates.html`.

**Step 5. Art for every card.** Item 6.
- Changes: the chosen pictures go into `assets/units/mouse`, `assets/units/pigeon` and the spell art. The spell pictures are cropped to the spell frame. A test fails when any card has no picture, so the gap can't come back.
- Depends on: decision 5.
- Checked by: the new test; the card browser shot on dev showing all 100 units and the spells; a recruit shot with a new card in the shop.

### Design steps

**Step 6. Type line and tooltips.** Items 8, 9 and 13's tooltip line.
- Changes: each card prints its types ("Badger Knight") on the card and in the hover's kind line, in place of "Unit". Keyword boxes move to a fixed place apart from the card's tooltip. Grudge's reminder says when it pays.
- Depends on: decisions 7 and 8; step 8's wording for Grudge.
- Checked by: compares with `type-line.html` and `tooltips.html`; shots of hovers on the shop, the board, the hand and the fight; a check that every card's type fits.

**Step 7. Shop layout.** Item 7.
- Changes: the gold, tier-up, refresh and freeze controls and their readouts move to the chosen layout.
- Depends on: decision 6. Do it before step 12, so animations are drawn for the final places.
- Checked by: compare with `layouts.html`; an agent play-test for misclicks; the owner plays it.

**Step 8. End-of-fight effects move to the start of the turn.** Item 13.
- Changes: Grudge, Relic Seeker and Old Campaigner pay at the start of your turn, reading the last fight's result. Grudge becomes a numbered keyword ("Grudge 1"), which fixes the golden's "+1" reminder. The recruit screen plays start-of-turn events: the source unit lights, the gain flies to its target, gold to the gold readout. Today it plays none, so Horde-runner's Hopper also gets a visible arrival.
- Depends on: decision 11.
- Checked by: tests that the numbers match today's (alive or dead, outnumbered, first and last turn); a film of a turn start with Grudge, Relic Seeker and a Hopper.

**Step 9. Goldens.** Item 12.
- Changes: rulebook 7.3.5 becomes the signature rule, plus any engine support a golden needs (for example a start-of-fight attack that happens twice). The 12 cards' golden texts in `design/goldens.md` go to the balance session as proposals: it sets their numbers and lands them in its per-tribe batch, so the Badgers are judged once.
- Depends on: decision 10.
- Checked by: a test per changed golden; each flagged golden fought on the fight engine at golden stats against a full mid board, and compared with its tier's golden ceiling (x2 at tiers 1 to 3, x2 to x4 at 4 to 6).

**Step 10. Old Brock.** Item 14.
- Changes: handed to the balance session (Balance Orchestrator 2), with `design/old-brock.md` and the recommendation (he gains the dead unit's printed stats, not its buffs). It judges him with the rest of the Badgers. This round makes no Old Brock change unless the owner rules on him here.
- Depends on: decision 12. The numbers so far were measured before dev's Mouse and Pigeon reworks; rerun them first. Separate from step 9, so the two don't double up on him (the owner's double-tap rule).
- Checked by: the board scenarios rerun on the fight engine (target about 6 tier 6 bodies on both mid and late boards); then a league match with bots that play Badgers to a local maximum (owner, 20 Nov). Heavy compute runs on the Optiplex, which has no limit.

**Step 11. Keyword looks.** Item 10.
- Changes: the chosen looks on cards in the shop, hand, board and fight, including the used-up state.
- Depends on: decision 9.
- Checked by: compares with `keywords/sheet.html` and `board.html`; shots of a late-game board with three keywords stacked on one unit.

**Step 12. Animations.** Item 11.
- Changes: the chosen prototypes built in batches. The recruit batch comes first (overflow slide, buy to board, swap, start-of-turn effects, refresh, tier-up), then the fight batch (Hit line, death effects, grouped ×N triggers). A fast-forward skip is left out until you ask for one.
- Depends on: decision 13, and steps 2, 3, 7 and 8 for the places and events they animate.
- Checked by: every animation filmed with `tools/feel` at 60 frames a second and stepped through frame by frame. Agents can't judge motion or feel (AGENT-BLIND-SPOTS item 1). The owner plays each batch in a Windows build before the next starts.

## Order

1. Steps 2, 4 and 5 in parallel, each in its own worktree. Step 3, then step 1.
2. A Windows build: you re-check items 1 to 6. The bug complaints are fixed here.
3. Steps 8 and 9 (rules change). Then re-sync the Badger balance work running on dev: "Grudge 1", the goldens and Old Brock all touch Badgers.
4. Steps 6 and 7, and step 10 if decision 12 asks for it.
5. Step 11, then step 12 in batches; you play each batch before the next.

The whole list of 14 is done only after step 12.

## Shared files with the ghost build (agreed 20 Nov)

The ghost build runs on dev at the same time. Its orchestrator owns `src/game/` (game_flow, game_controller, game_content, flow_bot, `ui/start_screen.gd`, `ui/result_screen.gd`), `src/core/ghosts/`, `src/core/records/`, `src/core/session/`, the opponent parts of `src/game/view_adapter.gd`, and `tools/league/`. This round owns `src/screens/`, `src/glass/`, `src/core/recruit/` and the card files in `src/content/`. Either side may edit its own parts of `view_adapter.gd` and tells the other the PR so it can rebase. Opponent screens change only after asking the ghost build orchestrator. Places this round needs the ghost build: step 2 (the result screen moves on with any click), step 8 (last fight's result kept until the next turn, if it lives in the session), step 12 (start and result screen animations).

## Shared with the balance session (agreed 20 Nov)

Balance Orchestrator 2 (`docs/workstreams/balance/plan.md` on dev) owns card power. This round owns the rules: end-of-fight effects to start of turn, Grudge as a numbered keyword, the golden rule. Card numbers, the 12 golden texts and Old Brock go to the balance session. A ruling by the owner on any of them is passed on as given. When a rules PR merges, it gets the PR number and the card ids changed. No rules PR merges during a third-run climb.

## Disk

Every worker reports what it wrote outside its checkout. Worktrees and look sessions are removed when a step is merged. Art masters go to Cloudflare R2 through `tools/assets/`.
