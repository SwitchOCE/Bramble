# Briefs: mechanics library reviewers

Repo: C:\Users\keech\Documents\Bramble (its CLAUDE.md applies). Input: four designer files in `scratchpad/library/` (C:\Users\keech\AppData\Local\Temp\claude\C--Users-keech-Documents-Bramble\ba2bf7cc-7113-4f9d-8dce-033d247d6ffb\scratchpad\library\): `design-batch1.json` to `design-batch4.json`. Each is an array of mechanics with example units, written by designers who never saw the budget. Mechanics are identified by `num` plus `name` (new ones have `num` "new").

The owner's rules for review: design reactions are directions, not decisions; nothing is cut (CLAUDE.md, "Design reactions are directions"). A flag always comes with a change that keeps the design's creative core. Don't edit any repo file or designer file.

## A. Rules reviewer

Check every mechanic and its units against `docs/design/rulebook.md` (v0.4) and `docs/design/architecture-notes.md`, and guardrail G1 in `docs/design/content-guardrails.md`. For each, in at most three sentences: does the text work under the rules; what is ambiguous; any loop or stalemate; is it readable on a card. Reuse the shared findings in the old list where they still apply (`docs/design/mechanics-ideas.md`, sections "Shared rules several mechanics need" and "Rules review: shared findings"). Ignore its budget lines.

Output `rules-review.json`: an array of {`num`, `name`, `verdict` ("clean", "needs a ruling" or "broken as written"), `review`}.

## B. Budget reviewer

Cost every example unit against `docs/design/power-budget.md`: V(t), the tier curve with its growth caps, and the tolerance bands (±15% plain, ±25% economy, scaling and engine). Use `docs/design/effect-taxonomy.md` for class prices; most prices are guesses until simulated, so mark them **[guess]**. Flag only against the tier curve and the tolerance bands, not against caps or guardrails the owner hasn't approved (owner, `docs/design/owner-notes/2026-11-02g-stage-2-checkpoint-scope.md`: "Don't flag against them"); mention one as information only if it matters. Reuse prices from the old budget lines in `docs/design/mechanics-ideas.md` where the effect is the same.

Output `budget-review.json`: an array of {`num`, `name`, `units`: [{`name`, `verdict` ("in band", "edge", "flag over" or "flag under"), `estimate` (a short working line, e.g. "body 7 + Peck ≈ 0.5 ≈ 7.5 vs V(3) 8: −6%"), `fix` ("" if in band)}], `line` (one plain sentence for the owner)}.

Check that your file parses as JSON. Return one line: the path and counts by verdict.
