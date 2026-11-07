# Bog folk and Hunters: implementation and evidence

Work in progress on `ideation/tribes56`, 7 Nov 2026. The owner's bar is interesting designs and
strategic depth. Great beasts remain on file.

## State after the first implementation turn

- Shared engine: bell after Mag Pye and before Goose/heroes/ordinary Start of Combat, one
  snapshot for patches and marks, first-claim overlap, targeting precedence, simultaneous death
  witnesses, single Take credit, and a bounded queue for named immediate attacks.
- Bog folk: all 14 shop cards, Prince Restored and Peatling; approved costing bodies and caps,
  Bitter, Snap, Hopkin's cycle order, counters, kiss persistence and transformation, original
  pool-copy return, and first-spell purchase pricing.
- Combat and CLI logs name patches, marks, Takes, replies, kisses and transformations. The
  replay model stores their state, and the Prince refreshes its card. Board overlays are still to do.
- Tests: 21 directed shared-engine tests and 29 Bog folk tests. The initial shared foundation
  commit `847c962` passed the full gate (998 tests). Bog roster full gate and preliminary soak
  results are recorded below when complete.
- Directed soak setup: 24 normal/golden bog mirror fights, including Belly refills, counterattacks,
  a third-kiss frog, and Peatling/kiss/transform caps. Transformation views update the soak's
  invariant replay and coverage map.

## Validation

Bog roster full gate: **PASS**, 1,030 tests across 78 scripts; all gate steps pass. Command:
`source /opt/bramble/env.sh; taskset -c 2 ./scripts/check.sh`. Includes 21 shared-engine tests,
29 Bog folk tests, two new replay/log tests, and the explicit pending-art fallback check.
Preliminary five-tribe soak: **PASS**, `taskset -c 2 tools/checks/soak.sh 100 53`: 100 games,
seeds 53–152, 1,704 rounds, 5,294 fights, **0 violations**. 5,291 fights ended with a board empty;
three ended with neither side able to attack. No attack/trigger-limit finishes. 67.3 seconds on
core 2. All 24 directed bog mirrors also passed before the games.

Natural slice coverage recorded firing for 14 of the 16 Bog cards/created cards. **Peat Cutter
and Prince Restored did not fire in natural games.** They have directed tests; the restored
Prince also appears in the directed mirror setup. These counts are reachability evidence, not
proof that bots play the tribe well. Explicit Bog strategies and scouting placement are still
pending. The final six-tribe gate and 100-game soak must be repeated after Hunters, bots and UI.

## Measurements still to run

**No focus-seat shares or placement figures yet.** Hunters and the bots that intentionally play
both tribes must be built first. The final small simulation must give each tribe's focus-seat
share and placement, with sample sizes and seeds. It must include all seats scouting and bots
holding carries still between rounds.

**No six-tribe shop measurement yet.** The current setting allows five tribes, so all five
currently built tribes are in every slice lobby. After Hunters, raise it to six and measure
shop-unit on-tribe share before deciding whether thinness justifies rotation.

## What is not done

Hunter cards and their Pack/Pounce/Poach/recruit rewards; explicit Bog/Hunter bot strategies and
scout assignment; stable carry placement; board patches, paw marks and connecting lines in scout
and fight; event-specific UI feedback; phone renders and visual inspection; the final small sim;
the final full gate and `taskset -c 2 tools/checks/soak.sh 100 53`.

Portraits have deliberately not started: they follow the UI, per the requested order. The 16 Bog
folk portraits are explicitly listed in `content/portraits_pending.json`; the portrait tests
verify the existing tribe fallback only for those entries. Existing art remains required for
every other card. Generate with `tools/art/run-codex-image.sh`, inspect, convert to 512×512 JPEG,
then remove completed entries from the pending list.

The requested `evidence/placing.md` is absent in this checkout. `evidence/position-test.md` and
`evidence/design-review-3.md` supply the placement finding and binding calls. No gameplay strength
or strategic-depth claim is made from unit tests alone.


## Next implementation notes

The Hunter lending integration must distinguish Young Brock's lasting bell buff from Old Brock's
live neighbouring Attack/Pounce aura. `lend_quarry` currently has a selector string and positive
Attack field; extend the content checker/payload for those real cards rather than encoding a
zero as an invalid `number`. `Combat`, `RecruitRules` and `CombatScreen` are near 1,000 lines:
continue extracting focused helpers before adding Hunter hooks or lane drawings.
