## Re-check of the Done-means fidelity fixes (10 Nov)

*[Saved verbatim from a fresh reviewer's hand-back, 10 Nov. It read PLAN.md, plan-to-done.md and DECISIONS.md at 34d8397e against `done-means-fidelity.md`. Calls: DECISIONS "Done means: re-check calls".]*

Of the 8 items, 5 are closed (cuts 2 and 3, asks 1, 3 and 5), 2 are mostly or partly closed (ask 2, ask 4) and 1 is partly closed (cut 1). I read the files at 34d8397e. Ask 3 is labelled now, but its stated reason doesn't fit.

**Each item**

- **Cut 1, declutter: partly.** The board half is back and tested. DM5 deciding 2: "The same reader checks build 9's recruit and fight screenshots at both sizes against … 'no tutorial text, rule reminders or static pointers on the board' (09e). Any one found fails it." The fight half, "through animation and feel rather than static labels, arrows or a running log", appears only in table row 5. No governing test checks it, and labels would help a strip reader pass rather than make it fail.
- **Cut 2, filler: closed, by restoring the line.** Checklist: "no final reviewer names a filler unit that isn't a deliberate vanilla body". Left over: `plan-to-done.md` §1.12 still lists it as a loosening.
- **Cut 3, worth beating: closed.** "Done fails if most final reviewers call the rivals pushovers." Small gap: the brief asks "worth beating?" but the fail word is "pushovers".
- **Ask 1, DM7 label: closed.** It now reads "**loosening** on 'fixed'". The reason, "09d is the owner's own direction", covers the power filter but not C4.
- **Ask 2, field make-up: mostly closed.** Fixed: equal weight per line, each line scored without its own boards, draws count half, and "A committed line is one in `tools/sim/lines/*.json`". Still open:
  - That folder isn't frozen. Today it holds 10 lines from 5 tribes, with no Hedgerow. Lines added after A4 would change both the field and the "5 lines from 4 tribes" count.
  - "Its own boards" isn't defined for a tribe's designed board.
- **Ask 3, reviewer row: closed on the label, but the reason doesn't fit.** The cited 09d line, "I don't want you to force it", is about "power budgets and performance", not reviewer counts. The owner's 06a line on independent agreement would fit.
- **Ask 4, lines the revision leaves out: partly.** The rule is now stated: "Every line of the 6 Nov text that no row below changes is still part of Done". The pool target is restated in DM1. But it doesn't say whether those lines decide, are checklist or are reported. And it brings back some lines nobody tests (finding 2).
- **Ask 5, phone text: closed.** "text under `UiTheme.MIN_FONT` (31 canvas units, which is 22 window px at 1688×780…)". `tests/ui/layout_check.gd` matches: `min_font()` is 31, and the tap minimum is 122 on a phone and 88 on a desktop.

**Made worse or newly ambiguous**

1. **09i holds in label only.** No criterion has more than two deciding items. But checklist items "must hold", so the number of things that can block Done went up:
   - DM4's default-opponent fact still blocks; it was relabelled so that "the criterion still has two deciding items".
   - DM1's checklist now holds one reviewer's judgement as a veto.
   - DM5 deciding 2 now combines two independent tests.
   - DM5's checklist gains two items.
   - The "still bind" rule adds lines with no stated status.
2. **Bars no one can test.** Through the "still bind" rule:
   - "A human can pick a hero and play 8-player games to the end through the real UI": no row changes it, and agents can't play it themselves.
   - "reviewers check economy by hand": no owner and no bar.
   - Separately, "full rules text one tap away from every card on every screen" names no check.
3. **A clause that can't apply.** With "0 units without rules text", no "deliberate vanilla body" can exist. Row 1, labelled "unchanged", is really a tightening.
4. **Bars that can loosen without a logged line.** A layout failure is now whatever `layout_check.gd` reports, so a later edit to that file (`SLACK`, `OVERLAP_SHARE`, `DESKTOP_RULES_FONT` = 22) loosens DM5 with no DECISIONS entry. The `tools/sim/lines/` folder has the same problem. Fix both, or say that changing them changes the bar.
5. **Uneven rules.** One reviewer's filler call blocks Done, while a re-skin call needs 2+ reviewers, and that rule is justified by 06a.
6. **Out-of-date pointers.**
   - PLAN says every loosening's reason is in §1.12 and in DECISIONS "Plan to Done v3 approved"; rows 2 and 7's reasons are in neither.
   - The DECISIONS entry ends "Agreed by: the fidelity check, with no cut left open", but that check read 322a28cb and hasn't seen these fixes.

Files: `docs/ideation/PLAN.md`, `docs/ideation/plan-to-done.md` (§1.12, §4), `docs/ideation/DECISIONS.md` (lines 42–61), `tests/ui/layout_check.gd`.
