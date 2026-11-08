# Review: pass 1 fixes build (9 Nov 2026)

A fresh cloud scope reviewer, on `origin/ideation/pass1-fixes` at 0131486, diffed against `origin/ideation/main`. Scope: `content/pass1-fixes.md` as amended by DECISIONS "Pass 1 fixes: review calls" (the amendments win), and plan step 3. The owner's words: "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap"; "Clear and concise wording... If it's implied, let it be implied."

**Counts: 0 cut, 6 ask, everything else fine. Moves the problem: yes.** The Chaser carry, the Ring piles, Hex 8 at T1, the gold-only bodies, Hob's Health spiral, Bracken's full-board zero and Mousewife's no-room failures are all fixed as specified.

**What I ran:** `./scripts/check.sh` on the branch passed every step, with 1,492 of 1,492 GUT tests passing. I ran 8 mutations against the six affected test files (125 tests), and each one turned the tests red: Ring cap 4→99 (6 failures), Chaser sale per slot instead of per pair (2), Toll-Bard paying on every attack (1), Hob's repaying check removed (1), Hob allowed on turn 1 (1), Mousewife's limit removed (2), Witch cap at tier instead of tier + 2 (3), and Sally ignoring full Rings (1). I didn't rerun the soak, and I didn't look at the UI renders. Those two claims are the builder's.

## (1) Spec match

| Card | Amended spec | Built | |
|---|---|---|---|
| Rainbow Chaser | T1 1/2; +1/+1 per 2 painted; sale 1 per 2, +2 for seven; golden top 8/10, sale 10 | Same, tested both sizes (4/5, 5 gold; 8/10, 10 gold) | fine |
| Ring cap | +4/+4 in the rule; full Ring can't be aimed; overflow lost; Sally skips full; Monarch above; Reel past; Horseshoe halves | All, plus rulebook 8.5.4 and the reminder at 12 words | fine |
| Hedge Witch | Golden capped at tier + 2; stored count shown | **Plain is also capped at tier + 2** (spec: "up to your tier") | ask 1 |
| Little Nip | 2/2, Take +1/+1 permanently and 1 gold | Same, golden ×2, survives a trade | fine |
| Toll-Bard | 2/4; Attack loss twice, gold once; "the quarry loses" | Same; the limits are only in Details | ask 2 |
| Old Lutra | 3/4; gold reads Lutra's own row | Same; text "if this is in back" | fine |
| Peat Cutter | 2/4 Mire | Same | fine |
| Cricket Busker | 2/3; 1 gold now, once a turn | Same | fine |
| Money Spider | T3 1/3, 1 gold; golden "1, 2 if you carried over 3 or more" | Same (`golden_static`) | fine |
| Pennywort Snail | 1/3, +1 Health and +1 sale for 3 turns | Same | fine |
| Hob | Borrow 3, repay 1 on each of the next 2 turns; not on turn 1; not while repaying; no Health | Same | fine |
| Bracken | 5 or fewer units: +1/+1 per tier, up to +5/+5 | Same | fine |
| Mousewife | In its place, twice a fight, not Mice | Same, plus the deviation | (4) |

## (2) Mechanics and tests

The mechanics are correct where I probed them, and the regressions bite. Changed old tests were updated to the new rules, not loosened. One exception: `test_feedback5_log` lost its check that a Mousewife no-room event reaches the log and the hero toast, and the Earwig deviation still produces that event (ask 6).

## (3) Ring cap

The cap is enforced once, in `BoardUpkeep.add_ring`, and that covers Nan, Sally, Spore Cloud and Boundary Stone. `item_aim_problem` and `LegalActions` reject full Rings without spending the card, and bots filter and value aims by applied stats. The preview shows "+1/+1, 1 lost" and "Full", and greys out full slots. Monarch, Reel-Mistress and Horseshoe each have a test. Wisp reads Rings only and is untouched. The UI preview hardcodes `4` instead of reading `RING_CAP` (ask 4).

## (4) Mousewife deviation: acceptable

If a dying front unit's own death summon (Earwig Mother) refills its slot, the Mouse fails. Letting the dying card's text go first is the natural reading, it's rare, and Details say so. The full-back-row failure the owner's players hit is gone (tested). The only question is whether a failed attempt should use up one of the two (ask 6).

## (5) Other effects, bots

No other card effect changed. `target_select`'s dead-self exception applies only to `on_take` self-targets, and Nip and Lutra are the only cards that use it. Bot changes are `cards.json` keep values, ratings and row hints, plus card-specific scoring for the changed cards: Ring aims (in the spec), the Toll-Bard hunt score and the Lutra own-row fix. Tribe routing is untouched. Fine.

## (6) Wording

All texts are 22 words or fewer, and most are short and clear. Two need a look:
- **Chaser:** "wipe paint for 1 gold per 2" makes the reader guess "2 what". The spec's "get 1 gold per 2 painted slots" costs two words (ask 3).
- **Toll-Bard:** "twice" and "once" aren't implied, so a player reads gold on every attack. A hidden limit is the trap the owner warns about (ask 2).

## (7) Out of scope

Two doc comments were deleted in `recruit_screen.gd` and `combat.gd`, presumably for line limits. That's harmless. The Mousewife toast now fires once a fight through `hero_limits`, which matches the feedback5 decision. Fine.

## Ask (orchestrator's call)

1. **Hedge Witch plain cap.** The builder read "tier + 2 … too" as applying to both versions, so plain reaches Hex 3 at T1 and Hex 8 at T6. The spec's plain cap was "your tier" (6 at T6, the review's "fair late niche"). Pick one and log it.
2. **Toll-Bard limits only in Details.** Suggest: "Quarry. After its quarry attacks: it loses 1 Attack (twice a fight); the first time, get 1 gold next turn." Or accept the hidden rule.
3. **Chaser wording:** "per 2" → "per 2 painted slots".
4. **Ring preview hardcodes 4** in `recruit_view.gd ring_preview`. If the logged +5/+5 fallback is taken, the preview and greying will disagree with the engine. Read the engine constant, or carry `ring_cap` in state.
5. **`card_view.gd` checks `def_id == "hedge_witch"`** to hide the chip when the Hex label wraps. Units with granted or borrowed Hex don't get this. Key it on `hex_stored` instead.
6. **Mousewife no-room path:** restore a log and toast test for it, and decide whether a failed Mouse should use up one of the two attempts. It does now, and it's pinned by a test.
