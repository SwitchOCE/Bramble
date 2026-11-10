*[Saved verbatim: a separate Sol scorer (w14, `kind: ask`) that compared the answers with `cold-recruit-followup/technical/`, 10 Nov.]*

**16/16 sequence-speed runs PASS; 0 FAIL. Overall PASS for this recruit packet: B’s containment, D’s selected-unit→target relationship and F’s completed departure now read at both speeds. Some badge meanings remain uncertain. This does not establish the whole build’s Done criterion 5.**

R = read right; ? = couldn’t tell; W = read wrong. Correct readings phrased tentatively still count when no competing action remains unresolved. Initial misreadings subsequently corrected are recorded below, rather than scored W.

Checked all 16 manifests, all 16 strips and all 14 Rules pages. Frames are numbered 1–8, left to right, top row first.

**Actions and events**

| Truth action/event | x1 | Reduce |
|---|---|---|
| **A — play:** Sleeping Partner, hand→F2; remains 1/2; gold stays 10 | R | R |
| **B — buy:** shop Sleeping Partner purchased; offers shift; gold 10→7 | R | R |
| **B — swallow:** Figgy Duff at F2 contains the purchase; hand stays empty; resident remains 3/5 | R | R |
| **B — held count:** 0→1 | ? — sees “1,” unsure what it counts | ? — same |
| **C — buy:** Sleeping Partner, shop→hand, unchanged 1/2; gold 10→7 | R | R |
| **D — inspect while scouting:** Wick selected; card reader opens | R | R |
| **D — lent-target preview:** selected Wick marks own B2, Mrs Sorrel, rather than straight-across F3; no attack occurs | R — target relationship read; lending rationale ? | R — same |
| **E — buy:** third Sleeping Partner purchased; gold 10→7 | R | R |
| **E — triple:** shop, board and hand copies become one golden 2/4 in hand; F2 empties | R | R |
| **F — Fly South:** Chiffchaff leaves F2 and becomes the matching away portrait | R | R |
| **F — return timing:** due round 3, two turns away | ? — correct guess, explicitly uncertain | ? — same |
| **F — trigger, source Chiffchaff:** departure leaves a 0/1 Egg in its nest; gold stays 10 | R | R |
| **G — sell:** Sleeping Partner removed from F2; gold 10→11 | R | R |
| **H — tier-up:** pays five; tier 1→2; gold 10→5; next price 7; offers unchanged | R | R |

D/H emit no recruit-log events; their actual UI actions/state changes are scored. E’s Discover reward remains pending until play.

| Sequence | x1 | Reduce |
|---|---|---|
| A | PASS | PASS |
| B | PASS | PASS |
| C | PASS | PASS |
| D | PASS | PASS |
| E | PASS | PASS |
| F | PASS | PASS |
| G | PASS | PASS |
| H | PASS | PASS |

The remaining count/timer uncertainties concern auxiliary meanings; neither leaves the action’s destination unresolved.

**Rule knowledge versus screen uncertainty**

Rules page 12 supplies Belly containment and bird departure/Egg knowledge. B/C’s “why Belly rather than hand?” therefore does not fail the screen. E’s automatic triple and delayed reward are covered on page 5; H’s future shops versus refresh distinction is covered on page 3.

Page 12 does **not** teach F’s sell trigger or exact two-turn duration. Old Brock’s lending exception is also absent from these pages and Wick’s opened reader. Those are missing card-specific knowledge, not evidence that the motion must explain the rules.

B’s uncertain badge meaning is a screen/glyph issue. F’s crescent resembles decoration, although its arrival and return interpretation now read. Input-method questions in A/G and portrait clickability in F do not obscure the demonstrated actions.

**Problems and misreadings, ranked by damage**

1. **D, frames 2–7, both:** gold initially suggests an upgrade; the reticle initially suggests an attack underway. The reader ultimately identifies scouting and Wick marking B2. Smallest fix: remove the target’s golden frame and use a brief reticle-only pulse, keeping blue selection distinct.

2. **B, frames 6–8, both:** Belly silhouette resembles a pointing hand/thumbs-up; “1” has uncertain meaning. Containment now reads, without stacking as an unresolved alternative. Fix: clarify the stomach cavity and briefly compress the incoming picture into it before the count pulse.

3. **F, frames 2–8, both:** away portrait initially resembles another token; crescent resembles moon decoration. Fix: briefly contract the arriving picture into its portrait and sweep a segmented crescent once when the countdown appears.

4. **E, frames 2–5; A, intermediate frames:** overlapping identical pictures suggest extra copies. E’s shop highlight also suggests premature golden status. Fix: stagger convergence slightly and reserve gold highlighting for the completed result.

5. **C, x1 frames 3–4:** tiny travelling picture resembles a particle. Fix: increase its minimum size slightly.

6. **G, frames 2–5; B/C/H payment frames:** removal briefly resembles death; rolling gold suggests multiple transactions. Fix: synchronize one payment/payout pulse with one balance change.

7. **H, frames 6–8:** tiny tier glyph resembles stacked objects/building. Fix: briefly enlarge the tier glyph during its existing pulse.

Reduce weakens travel continuity in A/B/C/E/F and acorn routing in G/H, but loses no action outcome. **W:** D’s reduce target does not persist through frame 8; images and JSON show it cleared.

No prohibited board teaching text or static pointers found. Read-only: no changes, commits, Godot runs or denied actions; nothing left undone.