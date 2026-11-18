# C15 taste log — 18 Nov 2026

## Step 2: recruit timing

This first entry covers step 2, for rulebook 7.2.3 and 7.2.6 and the owner's answers in [rules-c15-plan.md](rules-c15-plan.md). Steps 3 and 4 await the orchestrator's review. No new rule question needs an owner decision.

## What changed

Successful acquisitions share `_gain` and the unit-only `on_recruited` hook: buying, Discover picks (including Triple Reward picks), and effects adding cards to hand. A full hand loses a card before its hook can run. Playing and replaying a unit run no effect. Spell casting retains `on_played` and its existing board/slot/shop targeting.

A triple's golden recruits using the same hook with doubled parameters. The existing full-hand/all-board fallback recruits the golden in its vacated board slot. Triple Reward granting stays at its existing timing for step 4.

Master-at-Arms can target any friendly unit in hand or on board, itself included; spells do not qualify. Legal buy/pick actions list each existing unit UID plus `target: -1` for the incoming unit itself, whose UID does not exist yet. Bots choose those actions normally. When the UI omits `target`, the card is acquired first and its effect waits for a `recruit_target` action. Pending choices are represented in player state and block unrelated actions. SimpleBot, RandomBot and the inherited FlowBot path handle them. End turn resolves remaining Discover picks and recruit choices to the recruited unit itself.

## Taste calls

- **Aim after the acquisition.** Buying or picking Master-at-Arms completes the purchase/pick and shows its hand card before asking for a target. All eligible board and hand units are lit. This also makes self-targeting possible on an empty board. Escape and right-click leave this required choice pending; they cannot undo a completed purchase. Focus loss also preserves it.
- **A drag-buy keeps the intended slot.** The bought unit waits in hand while its recruit target is chosen, then the original copy is played into the dropped-on slot. If recruiting forms a triple, the original copy no longer exists and the golden stays in hand, as with other triple-producing buys. Playing never asks for a second target.
- **Only the golden recruits when the third copy arrives.** The owner's answer, 18 Nov: "Only the golden fires." A bought, picked or generated copy that completes a triple merges without its own recruit effect. Only the golden fires its doubled effect and, when needed, asks for a target. Copies that do not complete a triple recruit normally. This supersedes the earlier normal-then-golden implementation.
- **Use “Recruit”.** Following `.claude/skills/ux-copy/SKILL.md` and the rulebook's name, Master-at-Arms reads “Recruit: Give a unit +1 Fury.” Piper keeps Pile on on its own line, followed by “Recruit: Give your other Mice +2 Attack.” Golden numbers come from the existing parameter doubling. Hand/board eligibility stays implied by the targets the UI offers. The old ideation design is not rewritten; its content test explicitly applies the newer C15 wording to Master-at-Arms.

## Integration and checks

Fetched `origin dev` and rebased the uncommitted work with `git rebase --autostash origin/dev`, onto `ed6db3e6` (PR 155). It applied without conflicts. PR 155's merged-modifier golden floor and ghost Root lookup remain intact; PR 153's recruit income and tier-discount readouts remain intact.

All Godot commands and script runs were bounded with `timeout -k 10`.

- **388 tests passed across 20 affected suites after the rebase**, with the strict hook clean and no error/warning lines: `build/check/c15-final.log`. Includes every gain route, replay, full-hand losses, normal/golden trigger counts, target legality, end-turn resolution, mouse-event UI tests for buy/drag-buy/Discover targeting hand and board, self-targeting, FlowBot recruit choices, existing triple motion, readouts, ghost Root, golden floors and record replay.
- **Compilation:** 430 scripts/scenes/resources loaded, 0 failures: `build/check/c15-compile.log`.
- **Post-rebase soak:** 20 completed games, 315 rounds, 15,619 actions, 892 fights, 0 violations: `build/check/c15-soak-rebased.log`. Both shipped recruit effects fired. An earlier shipped-only 30-game soak also passed with 0 violations before rebasing.
- **`scripts/check.sh`:** passed leftovers, tools, versions, shell, Python (20 tests), format and lint. Stopped at import because the sandbox cannot save `/home/alex/.config/godot/editor_settings-4.7.tres`; both import passes reported only that restriction. Log: `build/check/c15-gate.log`. The orchestrator runs the remaining full gate as briefed.
- **`git diff --check`:** passed. No push or PR. No automatic approval-review rejection; Git metadata writes required sandbox escalation for the authorized fetch/rebase and commit.

At the step 2 checkpoint, no work on free moves, hand sales, the economy lock or changed Triple Reward granting had begun.

## Step 2 review follow-up

Replaced the remaining play-target wording in the core README with the recruit rule. A waiting recruit uses the existing lifted hand position and held-card highlight, including the full-hand golden's board-card highlight. It remains a legal self-target. The existing “Choose a target” banner is reused; real mouse-event buy and Discover tests now assert that the banner is present and visible and that the waiting card is highlighted. The required aim cannot be cancelled after the purchase/pick has completed; Escape and right-click keep it pending so its effect must resolve.

Owner's answer on the third copy, 18 Nov: "Only the golden fires." The completing copy now skips its normal recruit effect for buys, Discover picks and generated gains. The Piper regression gives other board Mice +4 only, with one trigger; Master-at-Arms auto-resolution gives only the golden's +2 Fury. A second copy, or a fourth gain waiting for the enclosing action to settle, still recruits normally. This follow-up is committed separately from step 3.

Follow-up checks: 90 tests passed across recruit drag, core/UI integration and triple-motion suites (`build/check/c15-review.log`), strict hook clean; affected formatting/lint and `git diff --check` passed.

Owner-answer checks: buy, Discover and generated third-copy regressions assert only the golden Piper's +4, with one trigger. Non-completing second/fourth gains still recruit. Master-at-Arms end-turn resolution grants only +2 Fury, and a real drag-buy test verifies a single golden target choice and no normal-copy effect.

The waiting-card held style is reapplied after triple presentation or settling, so the golden remains highlighted while its required recruit target is pending.

Owner-answer validation: 125 affected recruit/triple/bot tests passed, followed by 91 UI checks after retaining the golden's held highlight (`build/check/c15-golden-only.log`, `build/check/c15-golden-ui.log`). Strict hooks, source/test lint, formatting and `git diff --check` are clean.

## Step 3: zone moves and the work lock prototype

Implements 4.3.7, 7.2.4 and 7.2.5 plus the orchestrator's lock design in [rules-c15-plan.md](rules-c15-plan.md). This lock is a prototype, not a newly decided rulebook keyword. Step 4 has not begun. The step 2 review follow-up is the separate amended commit `bac1c909`, including the owner's answer that only the golden fires when a gain completes a triple.

### Behavior and taste calls

- `sell` accepts a hand index or a board slot. Both use the same valuation, pool return and sale-listener path. Created, Bought and mixed-origin golden values are unchanged. Spells cannot be sold. A hand sale has no last-known board slot; its death summons use the existing no-slot placement rule.
- `to_hand` moves the same object, for free. Own permanent/turn buffs, granted effects, origin, counters and Order uses survive. Borrowed board auras and slot bonuses are recalculated. No gain or recruit hook runs. Full hands retain today's refusal feedback.
- A hand unit dragged above the existing sell line sells; a board card dropped below the existing sill returns to hand. Both retain the existing pointer/middle drop setting and CardKeeper motion. A refused return lands back on its board slot through the normal refusal path. Locked cards may still move between board slots or sell.
- The work flag is set by actual context mutations, not a trigger log alone. Losing a generated card to a full hand or failing to summon on a full board does not count. Successful Orders always count because they consume a use, including an Order whose chosen placement is already current. Recipients of another unit's buff are not locked for receiving it.
- `RecruitContext.invoke` scopes sources through nested listeners and death effects. Board membership is checked against the board object, not just the source's retained slot number. Recruit effects exempt their own source, including a golden placed directly onto the board by the full-hand fallback. Other listeners caused by such an effect can still work.
- Rules queries report effective contributors without mutating the unit. Reading legal actions, prices or next-turn previews does not lock anything; a successful buy/refresh/upgrade or an income payment commits its contributors. Capped-away changes and weaker/redundant non-stacking copies do not count. Permanent-effect multipliers commit only when descendant effects actually change state. Continuous borrowed auras and after-fight effects do not count as Recruit Phase work.
- A triple inherits work flags from its copies, preventing a played golden from shedding their commitment. Automatic triple movement itself remains governed by 7.3.1. Start turn clears flags before the income query, so a unit that contributes to that morning's income locks again. The existing timing of the Order-counter reset is preserved.
- The mark reuses `KeywordMark` and the blue Shop glass family. A 22.5 px padlock sits on the upper-right border of a locked board card, separate from its keyword row. It appears only on board cards. Its reminder and refusal line follow UX-copy and the brief exactly: “Worked this turn: stays for the fight.” The recruit-only reminder does not carry into combat tooltips.

### Complete Recruit Phase hook inventory

Paths below are under `src/`. Every concrete Recruit Phase implementation in `src/content` and `src/core` was audited; test-only mechanics are outside this inventory.

| Hook / query | Implementations | How the work flag is set |
|---|---|---|
| `on_start_of_turn` | `core/mechanics/effects/start_turn_gold.gd`; `content/locust/mechanics/hopper_to_hand.gd` (Horde-runner) | Successful `gain_gold` or `give_card` marks the live board source. Full-hand losses do not. |
| `on_any_sold` | `content/locust/mechanics/gorge.gd`, `glut.gd`, through `content/locust/lib/locust.gd` | The winning eater's turn-counter/stat mutations mark Gorger or Granary Glutton. The sold copy is off board, even if it retains an old slot. |
| `on_any_sold`, standing | `content/thorn/mechanics/compost.gd` | Bought copies add Compost entries through `heap_add`. This has no board source to lock; nested unit listeners still get their own scope. Hand sales follow this path too. |
| `on_heap_added` | `content/thorn/mechanics/sweetbriar.gd` | Its own `buff` marks Sweetbriar, including entries produced by a standing Compost or a Bury. |
| `on_ability` / Order | `content/pigeon/mechanics/lance_corporal.gd`, `grenadier.gd`; `content/thorn/lib/bury_base.gd`, inherited by `bury_gold.gd` and `bury_feed.gd` (Hedge-layer, Leafmould Carter, Mother Midden) | Core ability use marks its source when cost/use is consumed. Context slot changes, shop consumption, heap entries, gold and buffs also attribute work correctly. |
| `on_end_of_turn` | Mouse `whetstone.gd`, `grindstone.gd`, `cook.gd`; Pigeon `sentry.gd`, `colour_sergeant.gd`, `sergeant_major.gd`, `grenadier.gd`; Locust `tide_end_turn.gd`; core `end_turn_buff.gd` | Their successful slot/unit buffs and Tide counter changes mark their own source. Moves are already closed by end turn; next start turn resets the flag. |
| `on_recruit_death` | Locust `hoppers_on_death.gd`, `brood.gd`, `tide_on_death.gd`; Thorn `seed.gd`, `pip.gd` | Summons, counters and heap entries use the scoped source. Today's eaten source is already sold, so it is not a board unit to lock. Nested Sweetbriar and modifier sources can still lock. Failed summons do not count. |
| `Q_DEATH_EFFECT_TIMES` | `content/locust/mechanics/dirge.gd` | `Recruit.run_death_effects` uses `ctx.ask`; effective Dirge contributors travel into the successfully changed death effects. |
| `locust_hopper_times` | `content/locust/mechanics/mother.gd` | `Locust.recruit_hopper_count` uses `ctx.ask`; successful descendant summons commit the effective Mother. |
| `thorn_bury_times` | `content/thorn/mechanics/bury_twice.gd` | `BuryBase.on_ability` uses `ctx.ask`; changed repeated gold/buffs commit the effective Midden. |
| `SLOT_BUFF_PERCENT` | `content/pigeon/mechanics/sergeant_major.gd` | `slot_buff` collects the strongest effective Sergeant Major from the read-only query and commits it when a nonzero permanent slot buff is given. |
| `SELL_VALUE` | `core/mechanics/effects/sell_bonus.gd` | Valuation still applies to the sold copy itself. That copy leaves play, so there is no surviving board modifier to lock. |
| Income and action prices | `Rules.INCOME`, `UNIT_PRICE`, `SPELL_PRICE`, `REFRESH_COST`, `UPGRADE_COST` | Core start-turn/buy/refresh/upgrade code collects contributors and marks them only on use. **No shipped card currently implements these modifiers**; synthetic modifier tests cover each path, refusals, previews and caps. |
| Exempt `on_recruited` | `content/mouse/mechanics/piper.gd`, `content/badger/mechanics/arms_master.gd`, core `play_buff.gd` | The recruited source is explicitly exempt. Buff recipients are not sources of that work. |
| Spell `on_played` | Core `play_buff.gd`, `discover.gd`, `triple_reward.gd` | A cast spell is not a board unit to lock. A separate board multiplier used by its effect can still work. |
| Excluded `after_fight` | Badger `relic.gd`, standing `grudge_pay.gd`; Pigeon `adjutant.gd`, `campaigner.gd` | Their context has work tracking disabled; combat has already occurred. Combat hooks and permanent combat writebacks are likewise excluded. |
| Absent | No concrete `on_sold` override or buy-listener hook exists in `src/content` or `src/core`. | The common sale self-hook and scoped notification path are ready for future implementations; none were invented for this step. |

### Verification and film

- New focused coverage: **19 core zone/lock cases plus 5 real mouse-event UI cases**. Includes full-hand refusal, hand-sale values/pool returns/listeners, identity/origin/buffs/Order counters, replay without recruiting, each work category, modifier previews/refusals/caps, stronger non-stacking multipliers, next-turn clearing, full-hand golden recruit exemption and selling a locked unit.
- Broad run: **903 tests across 61 scripts** in core, content, screens and game. **901 passed** immediately; the two tribe-game cases exposed the expected recruit-only tooltip difference. Their comparison now excludes only that status line, and **both cases passed on rerun** (`build/check/c15-step3-tribe.log`). No engine error/warning lines in these runs. Broad log: `build/check/c15-step3-suites.log`.
- Final start-turn ordering/economy/readout check: **73 tests passed** across zone moves, economy rules, recruit phase and view adapter (`build/check/c15-step3-final-core.log`). Strict hooks clean.
- Short soak: **10 games, 154 rounds, 7,682 actions, 444 fights, 0 violations** (`build/check/c15-step3-soak.log`). SimpleBot/FlowBot need not use returns or hand sales; RandomBot can select every new legal action.
- Compilation: **433 scripts/scenes/resources, 0 failed** (`build/check/c15-step3-compile.log`). Formatting, source/test lint and `git diff --check` passed.
- `scripts/check.sh` passed leftovers, tools, versions, shell, Python, format and lint, then stopped at the same sandbox editor-settings write restriction during import (`build/check/c15-step3-gate.log`). Full gate remains for the orchestrator.
- Film: `/home/alex/code/Bramble-media/c15/zone-moves.mp4`, **369 frames at 60 fps, 1920×1080**. Reproducible scenario: `tests/screens/feel/zone-moves.json`, using the real controller and mouse events. Its `.events` records the three drags; its `.report.json` proves the hand sale, returned original copy, refused locked return and retained Gorger. Inspected a rendered final frame: the small lock fits the card border and the refusal banner is readable on the transom. The film does not substitute for hardware feel testing.

All Godot, Xvfb, test and film runs used `timeout -k 10`. No automatic approval-review rejection. Git metadata and the explicitly requested external media directory required approved sandbox escalation. No push or PR; step 4 remains untouched. No new rule question was needed for this prototype.

## Step 4: Triple Reward at formation

Every `_combine` now grants the real Triple Reward spell through `_gain`, after placing the golden, whether its destination is hand or the full-hand board fallback. A full hand loses the spell via the same `card_lost` path as other gains. Playing the golden grants nothing. The `from_triple` field, play-time grant and board-fallback grant special case are removed, including the obsolete snapshot field. The spell still asks for the player's tier when cast; a regression upgrades after formation and casts it while the golden remains in hand.

### Owner's locked-triple decision

Owner, 18 Nov 2026:

> I think the triple should pull locked unit off the board and that allow the rule to be broken, because the rule that triples take place is a more important rule.

Triples therefore keep their normal placement priority: a locked board copy leaves its slot and the golden goes to hand when there is room. No locked-slot retention change or separate commit was made. The regression uses a Hedge-layer that really used its Bury Order, then buys two more copies; the worked source's slot empties, and the golden plus its reward are in hand. Existing work-flag inheritance and the ordinary 7.3.7 full-hand destination remain unchanged.

### Presentation calls

- Core ownership is immediate; presentation only delays visibility. Each triple event includes the actual `reward_uid`, or `-1` when the spell was lost. The adapter associates each spell with its own golden, including multiple simultaneous triples.
- The original golden lift/gather/charge/flash/reveal/landing takes its existing 98 frames. The reward then emerges just below/right of that gathering point and flies into its real hand place. A 27-frame reward beat allows the existing 15-frame flight and 12-frame hop; the 10-frame halo tail gives a total of 135 frames (2.25 s) at brisk pace. Numbers and both paces are documented in [triple-beats.md](triple-beats.md).
- `CardKeeper.arrive_from` reuses normal card arrival and its lean/hop. There is no duplicate reward node and no presentation-side grant. Counter redraws preserve the running arrival; input finishes only the triple and its own reward before the same event continues. Other card flights continue. A lost reward creates no visible card.
- The existing drag-buy rule is now explicit in its comment: a triple leaves its golden and reward in hand. It never automatically plays the newly formed golden. The waiting recruit is found by UID, since the reward is now the last hand card.

### Checks and media

- Core acquire/reward/snapshot suites: **65 tests passed**, followed by **19 core triple tests** for the new cast-before-golden-play case, and **20 core triple tests** after adding the worked Hedge-layer regression. Logs: `build/check/c15-step4-core.log`, `c15-step4-tier.log`, `c15-step4-lock-triple.log`.
- Broader affected run: **754 tests across 40 scripts; 753 passed**. Its only failure was the old double-click test's one-card hand-size/position expectation. That test now expects both golden and reward. The final targeted run passed **56 tests** across core triples, triple presentation and double-click buys, including the additional presentation and locked-copy cases (`build/check/c15-step4-check.log`). Strict hooks clean; no engine warning/error lines in the test runs.
- Short soak: **10 games, 154 rounds, 7,678 actions, 444 fights, 0 violations** (`build/check/c15-step4-soak.log`). Earlier reward ownership works with bots and pending-Discover resolution.
- Compilation: **433 scripts/scenes/resources, 0 failures** (`build/check/c15-step4-compile.log`). Formatting, source/test lint and `git diff --check` passed. `scripts/check.sh` passed through lint and stopped at the known sandbox inability to save `/home/alex/.config/godot/editor_settings-4.7.tres` during import (`build/check/c15-step4-gate.log`); the orchestrator runs the full gate.
- Film: `/home/alex/code/Bramble-media/c15/triple-reward.mp4`, **249 frames at 60 fps, 1920×1080**. Scenario: `tests/screens/feel/triple-reward.json`. The adjacent `.report.json` asserts the spell is owned before any golden play, counts **15 frames of actual card flight**, lists golden and reward in the final hand, and reports the presentation finished. Its only action is the third-copy buy. Inspected rendered frames at reward emergence, in flight and landed; the spell visibly joins the golden in the hand. No extra locked-slot film or code was added.

All Godot, test and film commands used `timeout -k 10`. No automatic approval-review rejection. External media writes and Git metadata required approved escalation. No push or PR.
