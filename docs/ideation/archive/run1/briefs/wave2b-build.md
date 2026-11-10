# Brief: wave 2b build (Oozes, the Hedgerow light pass, the neutrals)

**Plan:** v3 step 2 (`../plan-scale-rework.md`): "Then W2b, rebased onto W2a: Oozes, the Hedgerow light pass and the neutrals. The neutrals: keep 9, change 4, add Shieldbug and Click Beetle, and retire the 38 prototype bodies last."

**Why:** Oozes and Hedgerow are the two tribes still on pass 2, and their boards stay flat. Every playtester's control game with a flat tribe "felt hopeless" next to the rebuilt tribes (fun probe, `../evidence/fun-probe/verification.md`). The original problem is a scale that's too small and flat (owner notes 09a, 09c, 09h: generous first).

**Base:** `ideation/main` after the wave 2a merge. Work on a new branch `ideation/wave2b` in `/home/alex/code/Bramble-ideation-balance`.

## Sources (designs are settled; build them as written)
- `../content/pass3/oozes-pass3.md`: the 16 Oozes, tribe rules, **Engine support needed** (17 items), harness line policies, boards by round.
- `../content/pass3/hedgerow-pass3.md`: the 16 cards, tribe rules, **Engine support needed** (data-only items, then the new ones in order), harness lines.
- `../content/pass3/cross-tribe.md` §8: the neutrals. Keep 9. Change Ballooning Spider, Charcoal Burner and Whirligig Beetle. Pipistrelle Echo stays only if spell scaling shipped in the wave 2 pool rules; otherwise retire it. Add Shieldbug and Click Beetle. Retire the 38 units that have no set, last.
- `../content/pass3/presets.md` and `presets.json`: the B and C dials for Oozes and Hedgerow. Every new dial lands at B's value or above (generous first, 09h).
- `../DECISIONS.md` "Paper values for presets B and C, and the rule questions they raised", questions 1 and 2:
  - Click Beetle replaying "When played" on each homecoming is allowed.
  - Charcoal Burner reads body stats only, not slot Rings.
- Lessons from wave 2a's reviews (`../evidence/review-wave2a-*.md`):
  - Line seats protect their own engine pieces through `BotBrain._can_replace`.
  - The pin filter applies only from R4 with three or more units.
  - Valuation fixes come with directed before/after tests.
  - Every rate is a dial.

## Order: one reviewed hand-off per part
1. **Oozes**, with their engine support, line JSON and Hard-bot fixes.
2. **Hedgerow light pass**, the same way.
3. **Neutrals:** the changes and the two adds.
4. **Retire the 38 prototype bodies,** as its own commit, last. Check first that no test or fixture still needs them, and say which ones changed.

At each hand-off, stop and report. The orchestrator sends your tip to the cloud full gate and a scope review at the same time.

## Test rules (DECISIONS "Test-suite plan approved")
- Run only the targeted test files your change touches, through `/tmp/bramble-godot-slot systemd-run --user --scope -q -p MemoryMax=3G <command>`.
- Don't run a local full gate.
- Sims take the harness lock only.
- If a measurement run looks like it will take over 60 minutes on one process, report the per-lobby time instead. The orchestrator moves it to cloud sessions.

## Screens
Follow the declutter rules (09e; `../evidence/declutter/`).
- The main screen assumes a player who knows the rules: no new static labels or reminder text. Stats and hero Health are exempt, and there are at most 10 other text nodes.
- Explanations go in the card's hover text.
- The play is shown by animation where the doc asks for it: the ladle, the meal inside the jelly, wake pips. Keep these minimal. The declutter branch ports them into its wordless face later.

## Deciding criteria (at most two, 09i)
1. **Text equals behaviour:** every new or changed card has a known-answer test of its rules text, golden included.
2. **Not flat:** at B, in 32 line lobbies, each W2b tribe's committed line grows at least ×1.3 a round, R8–R14, on the pre-start median.

Also report, but not as criteria:
- the realized R12 median against 900;
- paper accounting (0.5–2×);
- splash per offer;
- Click Beetle's homecoming effect.

## Don'ts
- Don't push or merge.
- Don't touch `main`.
- Don't credit the owner with orchestrator calls. Cite DECISIONS for those.
- Don't re-pin a fixture without logging why.
