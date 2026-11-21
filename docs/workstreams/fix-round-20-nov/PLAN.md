# Fix round, 20 Nov 2026: the plan

Written by the orchestrator on 20 Nov 2026 against `dev`. Approved by the owner on 21 Nov, with the changes below. The recommendation page (https://claude.ai/artifact/LuKsXGPJzCxSkneGpM8kAc) holds the before shots, the mock-ups, the art and the design proposals this plan refers to.

**The owner's answers, 21 Nov** (dictated, relayed by the assurance session; question numbers are the page's item numbers): "For the Bramble fix round document, question six: I want B for all images. For question seven, I want option A but the tooltip under the gold value displacing it and having it be asymmetrical in terms of like the gaps between the buttons on each side of the screen, I don't like so the plus 13 next turn maybe just the end turn button shows like a little plus X gold icon next to the person you're going to fight in the top right corner of the profile picture of the next opponent So, set *[probably "instead"]* of that little line. So basically option A except with some adjustment Question nine of the tooltips. I think I like the option one. Option one is my pick The keyword stuff I don't like. It's too busy. I deny all changes to 10. We'll revisit that. It can go into the backlog. We'll keep the small marks for now and iterate later. So, option 10, question 10, we're not doing But option 11, I accept all changes I accept all the other proposals from that document. All other proposals I approve"

**Base: `dev`.** `main` is 214 commits behind dev. Everything here lands on dev through PRs; nothing goes to `main` without the owner's say-so.

## The owner's decisions, one line each

1. **Settled 21 Nov** (all other proposals approved). Hand overflow: a waiting pile next to the hand, with no limit.
2. **Settled 21 Nov.** Buying straight onto the board with a full hand, and swapping a hand card with a board unit, are rules; the bots get both moves now.
3. **Settled 21 Nov.** A "Skip" button, with Space still skipping; clicks elsewhere do nothing. Enter no longer skips: asked whether Enter should keep skipping, the owner picked "Space only" (21 Nov).
4. **Settled 21 Nov.** Duplicate and triple marks count only cards you own; the faint edge on your own copies stays.
5. **Settled 21 Nov.** Art: B for all 16 cards ("I want B for all images").
6. **Settled 21 Nov.** Shop layout: A (two wings), changed: nothing under the gold, the same gaps on both sides, and the next turn's gold as a small "+X" gold mark beside the top right of the next opponent's portrait on the End turn button, not on top of it (the owner's correction: "next to the top right of the circle down near the profile picture, not on top of it"). Built in PR 237. A mock-up goes to the owner before it is built.
7. **Settled 21 Nov.** Type line: above the stats.
8. **Settled 21 Nov.** Keyword tooltips: option 1, the left light.
9. **Not doing** (owner, 21 Nov): "The keyword stuff I don't like. It's too busy. I deny all changes to 10. We'll revisit that. It can go into the backlog. We'll keep the small marks for now and iterate later." Step 11 is dropped; the item is in `docs/workstreams/backlog-briefs.md`.
10. **Settled 21 Nov.** The golden rule comes from the owner: "Keywords, you know, some things can't be doubled. We need to keep balanced considerations, you know, in mind with goldens. You can't have it completely consistent no matter how much you might like to." Rulebook 7.3.5 says so (PR 224). How strong each golden ends up goes to the balance session.
11. **Settled 20 Nov.** The owner: "you can do those, I don't have a preference, give me suggestions." The orchestrator's picks:
    - end-of-fight effects move to the start of your turn, and Grudge becomes "Grudge 1";
    - Grudge keeps paying units that died (today's rule);
    - this round builds the golden engine support (step 9), and the balance session sets the 12 goldens' texts and numbers;
    - both land before the first climb, in the shared window.
12. **Settled 21 Nov.** Old Brock goes to the balance session with the rest of the Badgers.
13. **Settled 21 Nov.** Animations: all of them ("I accept all changes"), built in batches the owner plays between.
14. **Settled 22 Nov.** The Charge and Supply pips sit above the type strip, as built in PR 249. Asked the morning pack's questions, the owner said (22 Nov): "I will accept all the recommendations except the rules, which I want a reminder on first."
15. **Settled 22 Nov.** A carried shop card keeps its price tag (recruit/NOTES.md §2), not prototype 18's drop. Same answer as 14.
16. **Settled 22 Nov.** The turn-start income coins and new shop drop-in (prototypes 9 and 10) go in the next animation batch, not the recruit batch. Same answer as 14.

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

**Step 11. Keyword looks.** Item 10. **Dropped 21 Nov** (decision 9): the owner said no; it is in the backlog.
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
5. Step 12 in batches; you play each batch before the next. (Step 11 is dropped.)

The whole list of 14 is done only after step 12.

## Shared files with the ghost build (agreed 20 Nov)

The ghost build runs on dev at the same time. Its orchestrator owns `src/game/` (game_flow, game_controller, game_content, flow_bot, `ui/start_screen.gd`, `ui/result_screen.gd`), `src/core/ghosts/`, `src/core/records/`, `src/core/session/`, the opponent parts of `src/game/view_adapter.gd`, and `tools/league/`. This round owns `src/screens/`, `src/glass/`, `src/core/recruit/` and the card files in `src/content/`. Either side may edit its own parts of `view_adapter.gd` and tells the other the PR so it can rebase. Opponent screens change only after asking the ghost build orchestrator. Places this round needs the ghost build: step 2 (the result screen moves on with any click), step 8 (last fight's result kept until the next turn, if it lives in the session), step 12 (start and result screen animations).

## Shared with the balance session (agreed 20 Nov)

Balance Orchestrator 2 (`docs/workstreams/balance/plan.md` on dev) owns card power. This round owns the rules: end-of-fight effects to start of turn, Grudge as a numbered keyword, the golden rule. Card numbers, the 12 golden texts and Old Brock go to the balance session. A ruling by the owner on any of them is passed on as given. When a rules PR merges, it gets the PR number and the card ids changed. No rules PR merges during a third-run climb.

## Disk

Every worker reports what it wrote outside its checkout. Worktrees and look sessions are removed when a step is merged. Art masters go to Cloudflare R2 through `tools/assets/`.
