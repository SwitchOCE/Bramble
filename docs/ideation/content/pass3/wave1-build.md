# Wave 1 build: Birds and Fairies

Built on `ideation/wave1`, from `ideation/main` c74c2b9. The two 16-card rosters replace the previous Birds and Fairies. The twelve retired prototype bodies remain loadable for old scenarios but cannot appear in shops. Other tribes and neutrals retain their authored content. Existing portraits are reused.

The recruit rules live in `Pass3Birds` and `Pass3Fairies`; combat rules in the three `pass3_*_combat.gd` helpers. Card mechanic entries carry an ability and a golden strength, so stolen or borrowed golden text retains its strength. Rates live in `content/pass3/rates.json`; setting the same key on `GameConfig` overrides a default. The two JSON files in `tools/sim/lines/` preserve the synthesis policies. Neither `bench.gd` nor `BenchSuites` was edited.

## Readings and rulings

- Golden Mag Pye takes the first occupied unit next to the across target, using reading-order ties. “Next to” includes front/back neighbors as well as beside.
- The adopted amendments win. In particular, One Swallow travels for one turn, Tom Tit grants Damage Reduction, Fetch and Hob require Fairies, and Belladonna aims across (golden also marks the enemies beside that target).
- As confirmed by the owner, Cluricaun grows Ring size by **g on each tier-up**: g starts at 0.25, golden at 0.5. It has no turn timer. A full rainbow is still required.
- Fractional Ring size is retained; each slot receives `ceil(count × size)` in each stat. Rounding happens once per slot, including when Rings move in combat. Ring spells add their printed number of Rings at the caster's size. Their shop text and target previews show that meaning.
- A homecoming multiplies only the Bird's base plus permanent buffs. Supper, slot auras and next-combat buffs are excluded. It happens before homecoming listeners, even if the Bird waits on the doorstep. Replaying it is the separate action that fires When played.
- Cuckoo's “other Birds” excludes the arriving Bird (which is in hand), and includes Cuckoo itself. This follows the synthesis model's spread implementation. Copies each fire. Redbreast also reads the arriving Bird's permanent body, without Supper.
- An early recall requires an actual missed fight. Equal departure times prefer the biggest Bird, then reading order. Dunnock chooses the biggest trip with at least two turns left; her extra End of Turn firings cannot advance a trip again.
- All away Birds count for Redwing's biggest-away selection, including a Bird whose Nest has been replaced. Only a selected Bird that still has a Nest can provide an Egg there. Multiple Redwings use the largest target count.
- The Golden Egg's once-per-Bird mark survives triples and remains a guard when the general rate-limit overlay is disabled. Its doubling excludes Supper and auras, like homecoming.
- Fetch copies the source's current combat stats at the configured share, including its Ring, then receives its own slot contribution. Golden Fetch upgrades copied text without doubling the copied current stats a second time; a normal Fetch preserves an already golden source. Fetches cannot copy one another or reuse the same source.
- Annis does not hear her own sale. Lob counts actual End of Turns on the board, unaffected by moves. Only thanking triggers Lob and Silky. Among shared growers, the strongest copy's text fires once; copies share the Monarch clock, which pauses while none is present and resumes when one returns.
- Queen destroys only the units behind her; destroyed Shy units give no thank-you gold or departure growth. There is no self-tithe fallback. Her optional period dial and Monarch's countdown cannot be advanced by extra triggers.
- Dance budgets belong to Ring cohorts, survive meeting other Rings, and reset with the fight copy. Ratchet drops in once per Nest per fight, without homecoming growth or When played.
- Jack Daw remains permanent by default: amendment 5 makes fight-only conditional on a later harness result. `birds_jack_daw_permanent` exposes that comparison without changing code. The Lump retains Cleave and Whistlers start at one-half, pending the specified harness checks.

## Combat compatibility

`pass3_start_order` is a nullable fight-rule switch. Auto mode enables the new order whenever pass 3 content is in the pool or present in a fight; `GameConfig.full_game()` enables pass 3 content. Explicit `false` retains the old order and random stream. Biggest-enemy effects wait until both sides' other combat-start effects have resolved and can select units inside Bellies. Hob also waits for Fetch. This can change same-seed results for existing cards when enabled, so the legacy path is retained.

Twelve full combat-result fixtures were captured from the untouched c74c2b9 engine in an isolated archive, covering the other four tribes and neutrals, including gathering, control effects and Belly contents. The switch-off test compares exact serialized results. Old-design Bird/Fairy regression suites explicitly opt into frozen c74c2b9 card definitions; current-content tests and actual games use the new pool.

`pass3_loop_guards=false` is a diagnostic test switch: the new suites use it to reproduce failures without copy, doubling, recall, countdown, Nest-drop and Dance guards. It is true by default and is independent of the general caps overlay. No new size caps were added.

## Validation

The new core suites cover 117 tests, including all twelve exact legacy replays. The latest combined core run passed 116 tests / 615 assertions; the final combat-only run then passed all 43 tests / 139 assertions, including the added bounded Fetch recursion counterexample. Phone UI checks cover all 32 cards and both golden states; the focused UI regression run passes 34 tests / 3,560 assertions. Hard-bot checks include a real eight-seat lobby using Birds and Fairies. The first full gate passed every step before tests; historical card expectations were then migrated explicitly, with 203 related historical tests and 174 bot/policy tests passing. Final review also verified that hidden Belly targets preserve permanent rewards and do not intercept dying Hunters' Take rewards. The final locked 3G `scripts/check.sh` gate is being rerun against the final source.

Hard bot strategy IDs stay stable; the redesigned tribes use provisional route priors pending fresh measurements. Its Annis churn has a bounded work budget of eight actions, not an engine limit. It keeps at least three home Birds, uses a simple low-Health flight guard, places Annis and Fetch around a Ring carry, and holds a Golden Egg for a larger Bird due home next turn.

No design feature has been deferred. Balance measurements and harness loading belong to the separate harness branch.
