# C15 step 2: recruit timing — 18 Nov 2026

Step 2 only, for rulebook 7.2.3 and 7.2.6 and the owner's answers in [rules-c15-plan.md](rules-c15-plan.md). Steps 3 and 4 await the orchestrator's review. No new rule question needs an owner decision.

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

The implementation is ready for the step 2 gate. No work on free moves, hand sales, the economy lock or changed Triple Reward granting has begun.

## Step 2 review follow-up

Replaced the remaining play-target wording in the core README with the recruit rule. A waiting recruit uses the existing lifted hand position and held-card highlight, including the full-hand golden's board-card highlight. It remains a legal self-target. The existing “Choose a target” banner is reused; real mouse-event buy and Discover tests now assert that the banner is present and visible and that the waiting card is highlighted. The required aim cannot be cancelled after the purchase/pick has completed; Escape and right-click keep it pending so its effect must resolve.

Owner's answer on the third copy, 18 Nov: "Only the golden fires." The completing copy now skips its normal recruit effect for buys, Discover picks and generated gains. The Piper regression gives other board Mice +4 only, with one trigger; Master-at-Arms auto-resolution gives only the golden's +2 Fury. A second copy, or a fourth gain waiting for the enclosing action to settle, still recruits normally. This follow-up is committed separately from step 3.

Follow-up checks: 90 tests passed across recruit drag, core/UI integration and triple-motion suites (`build/check/c15-review.log`), strict hook clean; affected formatting/lint and `git diff --check` passed.

Owner-answer checks: buy, Discover and generated third-copy regressions assert only the golden Piper's +4, with one trigger. Non-completing second/fourth gains still recruit. Master-at-Arms end-turn resolution grants only +2 Fury, and a real drag-buy test verifies a single golden target choice and no normal-copy effect.

The waiting-card held style is reapplied after triple presentation or settling, so the golden remains highlighted while its required recruit target is pending.

Owner-answer validation: 125 affected recruit/triple/bot tests passed, followed by 91 UI checks after retaining the golden's held highlight (`build/check/c15-golden-only.log`, `build/check/c15-golden-ui.log`). Strict hooks, source/test lint, formatting and `git diff --check` are clean.
