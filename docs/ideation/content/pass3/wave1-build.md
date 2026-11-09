# Wave 1 build: Birds and Fairies

Built on `ideation/wave1`, from `ideation/main` c74c2b9. The two 16-card rosters replace the previous Birds and Fairies. The twelve retired prototype bodies remain loadable for old scenarios but cannot appear in shops. Other tribes and neutrals retain their authored content. Existing portraits are reused.

The recruit rules live in `Pass3Birds` and `Pass3Fairies`; combat rules in the three `pass3_*_combat.gd` helpers. Card mechanic entries carry an ability and a golden strength, so stolen or borrowed golden text retains its strength. Rates live in `content/pass3/rates.json`; setting the same key on `GameConfig` overrides a default. The two JSON files in `tools/sim/lines/` preserve the synthesis policies. Neither `bench.gd` nor `BenchSuites` was edited.

## Readings and rulings

- Golden Mag Pye takes the first occupied unit next to the across target, using reading-order ties. “Next to” includes front/back neighbors as well as beside.
- The adopted amendments win. In particular, One Swallow travels for one turn, Tom Tit grants Damage Reduction, Fetch and Hob require Fairies, and Belladonna aims across (golden also marks the enemies beside that target).
- Under [amendment 7](README.md#amendments-adopted-from-the-cross-tribe-critique) and the post-review ruling, Cluricaun grows shared Ring size by **+1/+1 on each tier-up**, golden +2/+2, if every slot has a Ring. `fairies_ring_growth` remains the step dial, default **1**. The earlier quarter-point default misread the old turn timer's period as the new step; the corrected README removes that reading. Cluricaun has no turn timer.
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

The new order is mandatory whenever pass 3 content is in the pool or present in a fight; `GameConfig.full_game()` enables pass 3 content. Biggest-enemy effects wait until both sides' other combat-start effects have resolved and can select units inside Bellies. Hob also waits for Fetch. This can change same-seed results for existing cards when enabled. The production `pass3_start_order` setting has been removed. Only tests set the per-fight diagnostic `combat.notes["test_pass3_start_order"]` to exercise the old order; normal games and harness configurations cannot disable the rule.

Twelve full combat-result fixtures were captured from the untouched c74c2b9 engine in an isolated archive, covering the other four tribes and neutrals, including gathering, control effects and Belly contents. The test-only old-order path compares exact serialized results. Old-design Bird/Fairy regression suites explicitly opt into frozen c74c2b9 card definitions; current-content tests and actual games use the new pool. The frozen pass 2 Birds/Fairies tests are the rollback until checkpoint 2, then deleted.

The missed-fight recall test uses a Bird that left in an earlier numbered turn but has not actually missed a fight: the old `left < round` predicate would recall it, while the new rule waits for the explicit missed-fight flag. Duplicate growing text is tested on a single unit carrying its printed ability plus borrowed text, including guard-disabled counterexamples.

`Pass3Text.face()` generates every new face from resolved rates, using fraction words. The library uses that generator at defaults and the scale overlay uses it for sweeps. Authored JSON faces are checked copies: a test reads the files directly and compares them with generated defaults. Tom Tit's full normal line is tested exactly, and One Swallow's face includes “Its trips last 1 turn.” Jack Daw remains permanent by default with its comparison dial intact.

`pass3_loop_guards=false` is a diagnostic test switch: the new suites use it to reproduce failures without copy, doubling, recall, countdown, Nest-drop and Dance guards. It is true by default and is independent of the general caps overlay. No new size caps were added.

## Validation

The final UI follow-up locked 3G [full gate](../../evidence/wave1/ui-followup/quality-gate-final.log) **passes** on `695e156`: **1,797 tests, 29,513 assertions, 164 scripts**, strict hook clean. All other gate steps pass, with 496 source files compiled. The final screenshot captures were refreshed on that same source after the gate. The subsequent evidence commit changes documentation, recorded outputs and the three imported Godot UIDs only.

The post-review locked 3G [full gate](../../evidence/wave1/bot-review/review-gate.log) **passes** on source checkpoint `76c259b`: **1,791 tests, 29,353 assertions, 163 scripts**, strict hook clean. All tools, versions, shell, Python, content, formatting, lint, import, compilation and pool-parity steps pass; 493 source files compile. Rules/text are checkpoint `4a052e4`, and Hard Fairy policy/probe are `76c259b`. The subsequent evidence commit changes documentation, recorded outputs and the imported probe UID only.

The initial locked 3G `./scripts/check.sh` gate **passes** on source checkpoint `d83b4ae`: all 1,779 tests and 29,298 assertions across 163 scripts, with the strict hook clean. Tools, versions, shell, Python, content, formatting, lint, import, compilation and pool parity also pass. Combat remains 937 lines, below its 1,000-line lint cap.

The new core suites cover 117 tests, including all twelve exact legacy replays, configurable rates, bounded guard counterexamples and a real eight-seat Hard-bot lobby. Phone UI tests cover all 32 cards and both golden states. Final review and a regression test confirm that hidden Belly targeting preserves permanent rewards without intercepting dying Hunters' Take rewards. Golden Egg explicitly reuses the existing Nest Egg portrait.

Hard bot strategy IDs stay stable; the redesigned tribes use provisional route priors pending fresh measurements. Its Annis churn has a bounded work budget of eight actions, not an engine limit. It keeps at least three home Birds, uses a simple low-Health flight guard, places Annis and Fetch around a Ring carry, and holds a Golden Egg for a larger Bird due home next turn.

Balance measurements and harness loading belong to the separate harness branch. The visual follow-up below identifies UI gaps in the implemented build.

The harness branch will load `tools/sim/lines/*.json` after it merges; no loader was added here. The existing bot spell-aim legality filter applies to all tribes because the aimed-item pipeline is shared: it excludes candidates rejected by the real `item_aim_problem` rule, including invalid Golden Egg targets. The route priors remain provisional; the new Fairy counts below are behaviour checks, not a checkpoint 2 balance measurement.

## Post-review Hard Fairy behaviour

The small policy changes retain one Lob, Hob and Cluricaun as engine investments; Cluricaun can retire at tier 6, and spare copies can make room. Lob's bank is priced into buying an aimed spell and choosing its target. Thank-you value includes the lost body and Hob's lost protection, so Shy units leave when the payout pays. With Cluricaun held, missing Rings get spell-buy and aim value, and affordable Rings are placed before the scheduled tier-up. The shared buy/place/recruit action machinery is retained.

The reviewer's original probe and project copies were deleted, and its surviving log has no seeds or configuration. Consequently its aggregate “5 thanks” cannot be reproduced honestly. The [paired probe and full tables](../../evidence/wave1/bot-review/README.md) use the same documented replacement seeds **412, 413 and 414** before and after, with the original bot archived from `13eac5f`. Eight Hard seats play Bird/Fairy routes through real recruiting and combat. A same-rate control keeps the old Cluricaun step 0.25; another run uses the corrected step 1. Ordinary 40-Health runs are also saved. The 80-Health control keeps all twelve Fairy-route seats observable at R12 and is not a live balance estimate.

| Fairy-route seats, three 80-Health lobbies | Thanks | Lob sales/buys | Hob sales/buys | Cluricaun sales/buys | Mean Ring size at R12 |
|---|---:|---:|---:|---:|---:|
| Before, step 0.25 | 3 | 2/2 | 3/6 | 1/1 | 1.25 |
| After, same step 0.25 | 9 | 1/9 | 0/7 | 2/3 | 1.67 |
| After, corrected step 1 | 17 | 0/4 | 1/8 | 1/3 | 2.17 |

At ordinary 40 Health, Fairy-route thanks rise from **5 to 11**, Lob sales from **2/3 to 0/3**, and Hob sales from **3/6 to 0/7**; Cluricaun sales are **0/1 to 1/4**. Every after-policy Cluricaun sale by a Fairy-route seat, in both Health controls and at either step, was at tier 6. Survival changes which seats reach R12, so the complete per-seat sizes and missing seats are listed rather than filled in. The baseline replacement trio's one Cluricaun sale was already at tier 6; it does not reproduce the reviewer's premature-sales evidence. Retention while tier-ups remain is separately exercised by a focused bot test. An [independent event-count audit](../../evidence/wave1/bot-review/verification.json) verifies the counts and sale tiers against the raw reports. These short probes demonstrate behaviour, not tuned tribe strength.


## UI review follow-up

The attribution audit now explicitly records the later correction of the quarter-step reading: Cluricaun's tier-up step is +1/+1, golden +2/+2, the orchestrator's call after review.

`AwayTray` now displays the existing `RecruitHeld.sky_card()` forecast in a persistent panel below the hand, rather than using the PC card reader that covers recruiting controls. Each Bird shows its name, turns remaining, current stats and landing stats, with Nest location where one remains. Doorstep Birds are listed too. The hand temporarily uses compact tiles and its existing full-hand picker; the forecast list scrolls at the shared font minimum, and ordinary hand layout returns when the sky is empty. The tray stays visible when selecting or clearing a card.

Counted Ring badges now show compact ×count in the name strip, reserving space for the slot chip and unit name. Full Ring stat totals remain in the slot reader, with shared Ring size above the shop. End Turn's subtitle clears the leaf rim in the full and compact phone layouts. Crowded PC shops get more tile width; their name measurement follows actual smart wrapping and reserves space above stat badges. Name fonts stay at or above 31 canvas pixels.

The [matching before/after evidence](../../evidence/wave1/ui-followup/README.md) contains **12 native screenshots**, three scenes at **1688×780 and 1920×1080** in each phase, plus renderer logs, exact shared input state, forecast/footer geometry and independent PNG/state verification. Before UI is `95128ed`; final after UI is `695e156`, with tray/layout in `82b4b21` followed by a correction to count already-merged shop offers once. The snapshot deliberately retains its historical Ring size 1.25 so the comparison changes only UI. Both away forecasts are visible at the phone minimum without hiding economy controls. Tests also cover larger flocks with a full hand, restored empty-sky layout, Ring badge clearance, whole-word PC names and the End Turn subtitle.

The previous screenshots below remain historical evidence. The away-tray gap, Ring badge crowding, End Turn clipping and PC shop-name wrapping they identified are resolved by this follow-up. Fractional Cluricaun trigger-chip formatting under non-default sweeps remains separate.

## Real-game and screenshot evidence

The [attribution audit](../../evidence/wave1/attribution-audit.md) found only the corrected Cluricaun credit; none of the three original wave 1 commit messages claimed owner confirmation. This follow-up adds new commits. The images and logs below record the engine, UI and card data at 6a54286; later review fixes are recorded separately and do not rewrite that evidence.

All Godot runs used `/opt/bramble/env.sh`, `/tmp/bramble-godot.lock` and a user scope with `MemoryMax=3G`. [Replay proof](../../evidence/wave1/games-replay-proof.json) and the per-size [phone](../../evidence/wave1/screenshots-1688x780.json) / [PC](../../evidence/wave1/screenshots-1920x1080.json) provenance record the exact commands. [Independent artifact verification](../../evidence/wave1/verification.json) checks native PNG dimensions, accepted commands, save hashes and exact fresh-CLI game-log equality.

### Complete games through tools/play

A transparent [scripted command client](../../../../tools/play/wave1_games.gd) used `PlayGame.run` for every action with normal shops, economy, hero choices and the full-strength lobby. Seed 1 is the first ordinary rotated lobby containing both tribes; outcomes were not selected. Each save was then independently reloaded through actual `tools/play/play.sh` for both `log` and `--json`.

| Commitment | Player game end | Commands | Primary logs and replay save |
|---|---|---|---|
| Birds | First place, R19, 1 Health; 35 logged flights and 30 homecomings | 269 accepted, none refused | [Playthrough](../../evidence/wave1/birds-playthrough.txt), [fresh CLI log](../../evidence/wave1/birds-cli-log.txt), [command trace](../../evidence/wave1/birds-actions.jsonl), [save](../../evidence/wave1/birds-save.json), [game log](../../evidence/wave1/birds-game-log.json) |
| Fairies | Eighth place at normal player game over, R11; 10 Rings, Ring size 1 | 90 accepted, none refused; all 9 unit purchases were Fairies | [Playthrough](../../evidence/wave1/fairies-playthrough.txt), [fresh CLI log](../../evidence/wave1/fairies-cli-log.txt), [command trace](../../evidence/wave1/fairies-actions.jsonl), [save](../../evidence/wave1/fairies-save.json), [game log](../../evidence/wave1/fairies-game-log.json) |

The Fairy player never completed the rainbow or bought Annis, so this game did not exercise Ring-size growth. Its elimination ends the player's normal CLI game; the remaining lobby is not artificially fast-forwarded. The result is retained as observed. These are behaviour records, not balance estimates.

[Clean game-client stdout](../../evidence/wave1/games-run.txt), fresh CLI JSONs, every round state, checkpoint save and per-fight JSON are enumerated in the [artifact index](../../evidence/wave1/README.md). A [client audit](../../evidence/wave1/command-client-audit.json) records the corrected spell-aim validation bug in the evidence client and the discarded provisional summaries; the production rules were unchanged. The homecoming checkpoint label was also corrected: return at Start of Turn 5, followed by the actual turn-5 fight, captured in turn 6.

### Full-window screenshots

There are 30 unaltered native-resolution PNGs, 15 at each requested size. Natural game checkpoints are listed first. Controlled scenes use the production UI, production dev setup and actual rule actions; their injected setup is disclosed in provenance and is separate from the unchanged-economy full games. The three longest faces were selected over all 64 normal/golden wave 1 faces by whitespace word count, then card ID for ties; Jack Daw is included as the tied fourth reader.

| Scene | Phone 1688×780 | PC 1920×1080 |
|---|---|---|
| Natural Birds game: both tribes offered, R2 | [PNG](../../evidence/wave1/natural-birds-mixed-shop-1688x780.png) | [PNG](../../evidence/wave1/natural-birds-mixed-shop-1920x1080.png) |
| Natural Birds game: Ring plus away Birds, R4 | [PNG](../../evidence/wave1/natural-birds-ring-and-away-1688x780.png) | [PNG](../../evidence/wave1/natural-birds-ring-and-away-1920x1080.png) |
| Natural Birds game: Chiffchaff returns 4/6, R5 | [PNG](../../evidence/wave1/natural-birds-first-homecoming-1688x780.png) | [PNG](../../evidence/wave1/natural-birds-first-homecoming-1920x1080.png) |
| Natural Birds game: returned Chiffchaff fights 5/7, R5 | [PNG](../../evidence/wave1/natural-birds-homecoming-following-combat-1688x780.png) | [PNG](../../evidence/wave1/natural-birds-homecoming-following-combat-1920x1080.png) |
| Natural Fairies game: 10 Rings, R10 | [PNG](../../evidence/wave1/natural-fairies-ring-carry-1688x780.png) | [PNG](../../evidence/wave1/natural-fairies-ring-carry-1920x1080.png) |
| Ordinary turn-1 shop, before controlled setup | [PNG](../../evidence/wave1/shop-birds-fairies-1688x780.png) | [PNG](../../evidence/wave1/shop-birds-fairies-1920x1080.png) |
| Controlled real-rules Ring carry, Fetch, and away Birds | [PNG](../../evidence/wave1/ring-carry-away-birds-1688x780.png) | [PNG](../../evidence/wave1/ring-carry-away-birds-1920x1080.png) |
| Controlled real-rules Swallow returns 7/8 → 14/16 | [PNG](../../evidence/wave1/homecoming-return-1688x780.png) | [PNG](../../evidence/wave1/homecoming-return-1920x1080.png) |
| Controlled real-rules returned Swallow fights 17/19 with its +3/+3 Ring | [PNG](../../evidence/wave1/homecoming-following-combat-1688x780.png) | [PNG](../../evidence/wave1/homecoming-following-combat-1920x1080.png) |
| Golden Mag Pye reader, 18 words | [PNG](../../evidence/wave1/reader-mag_pye-golden-1688x780.png) | [PNG](../../evidence/wave1/reader-mag_pye-golden-1920x1080.png) |
| Golden Reel-Mistress reader, 18 words | [PNG](../../evidence/wave1/reader-reel_mistress-golden-1688x780.png) | [PNG](../../evidence/wave1/reader-reel_mistress-golden-1920x1080.png) |
| Golden Cradle Fetch reader, 17 words | [PNG](../../evidence/wave1/reader-cradle_fetch-golden-1688x780.png) | [PNG](../../evidence/wave1/reader-cradle_fetch-golden-1920x1080.png) |
| Jack Daw reader, tied at 17 words | [PNG](../../evidence/wave1/reader-jack_daw-1688x780.png) | [PNG](../../evidence/wave1/reader-jack_daw-1920x1080.png) |
| Away Nest tap: current Bird and countdown | [PNG](../../evidence/wave1/away-nest-reader-1688x780.png) | [PNG](../../evidence/wave1/away-nest-reader-1920x1080.png) |
| Away preview gap after clearing selection | [PNG](../../evidence/wave1/away-sky-preview-gap-1688x780.png) | [PNG](../../evidence/wave1/away-sky-preview-gap-1920x1080.png) |

Homecoming occurs at Start of Turn, not inside combat. Both return/following-fight pairs show that chronology. In the controlled case, Swallow's permanent 7/8 doubles to 14/16, then its destination Ring adds +3/+3 in combat; in the natural case, Chiffchaff returns 4/6 and its separate When played buff makes it 5/7 for combat. Neither sequence is mislabeled as a Ratchet drop-in.

[Phone renderer log](../../evidence/wave1/screenshots-phone.log) and [PC renderer log](../../evidence/wave1/screenshots-pc.log) both exit cleanly with zero automated layout notes. Visual inspection found issues those checks missed:

- **Away preview gap:** Nest countdowns and the current-Bird reader work, but no current→landing tray is displayed. `RecruitScreen._show_sky()` only calls `show_empty()`, leaving the implemented `RecruitHeld.sky_card()` forecast unused. This is an implementation gap in 6a54286, not a deferred design choice.
- **Fractional Cluricaun chip at 6a54286:** the natural Fairy PC board shows “Ring +0” although its then-default growth was +0.25. `CardView._keyword_number()` matches integer prefixes and truncates that decimal display. The review correction to default +1 resolves this default case; fractional sweeps still expose the display limitation.
- **Ring badge crowding:** with the phone card reader open, B1's large Ring badge overlaps its slot name; on PC it can cover part of the trigger chip.
- **Phone footer clipping:** the End Turn subtitle is partly cut at the bottom edge.
- **PC shop-name wrapping:** long names such as His Highness and Jenny Greenteeth wrap into stat-badge space in the controlled Ring scene.

The full card-reader texts fit at both sizes. The findings above are preserved for the fresh review; this evidence follow-up does not change the existing UI or engine to hide them.

The follow-up full [quality gate](../../evidence/wave1/quality-gate.txt) also passes with both evidence drivers present: 1,779 tests and 29,298 assertions, strict hook clean. No existing engine, UI, bot or card source was changed during this evidence follow-up.
