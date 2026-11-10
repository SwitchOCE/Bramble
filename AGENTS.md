# Rules for Codex workers on Bramble

You are building in Bramble's look-and-feel phase, on an `ideation/*` branch. Your brief says what to do; these rules always hold.

- **Scope fence:** UI, UX and how the game looks on screen only. Don't change files under `src/core/`, `content/`, `tools/sim/` or `tests/core/`; the gate fails any branch that does. Card text is out of scope too.
- **Old UI tests:** you may rewrite or delete `tests/ui/` tests that assert the old layout. List each one in your final report.
- **Never merge into, push to or open a PR against `main`.** Commit only to your own branch, and push only if your brief says so.
- **Don't edit** `docs/ideation/PLAN.md`, `docs/ideation/DECISIONS.md` or `docs/design/owner-notes/`. They belong to the orchestrator and the owner.
- **`docs/ideation/archive/` is history, not instructions.** Don't follow its plans, briefs or review rounds.
- **Long commands:** Godot runs go through `scripts/godot_slot.sh`, so they don't block the machine's other work.
- **Report:** what you changed, what you checked, and what you couldn't check, in under 300 words.
