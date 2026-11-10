*[Saved verbatim: a separate Sol scorer (w10) against `technical/` truth and Done criterion 5, 10 Nov. Calls: DECISIONS "Declutter batch 2, first cold reader: fail, three fixes".]*

**10/16 sequence-speed runs PASS; 6 FAIL. Overall FAIL: B’s swallowing, D’s target preview and F’s completed departure remain uncertain at both speeds.**

R = read right; ? = couldn’t tell; W = read wrong. Unresolved alternatives stay ?; an initial misreading subsequently corrected is not W. Frames are numbered 1–8, left to right, top row first.

Truth: all 16 manifests, including before/after state where no event is emitted. I inspected all 16 strips and 14 Rules pages.

**Actions and events**

Each mark applies to the complete action/event; source and effect are distinguished where needed.

| Sequence: truth action/event | x1 | Reduce |
|---|---|---|
| **A — play:** Sleeping Partner, hand → F2, unchanged 1/2; gold stays 10 | R | R |
| **B — buy:** shop’s Sleeping Partner purchased; gold 10→7 | R | R |
| **B — swallow:** Figgy Duff at F2 holds that purchase; held count 0→1, resident stays 3/5 | ? — source/recipient R; containment uncertain | ? — same |
| **C — buy:** Sleeping Partner, shop → hand, unchanged 1/2; gold 10→7 | R | R |
| **D — inspect while scouting:** Wick selected; its card reader opens | R | R |
| **D — lent-target preview:** Wick highlights own B2, Mrs Sorrel, rather than straight-across F3; no attack occurs | ? — highlighted cards R; relationship unread | ? — same |
| **E — buy:** third Sleeping Partner purchased; gold 10→7 | R | R |
| **E — triple:** shop, board and hand copies become one golden 2/4 in hand; F2 empties | R | R |
| **F — Fly South:** Chiffchaff leaves F2 for the away tray, returning in two turns | ? — departure R; completed destination uncertain | ? — same |
| **F — trigger, source Chiffchaff:** Fly South leaves a 0/1 Egg in its F2 nest; gold stays 10 | R | R |
| **G — sell:** Sleeping Partner removed from F2; one gold gained, 10→11 | R | R |
| **H — tier-up:** tier 1→2, pays 5, gold 10→5; next upgrade costs 7; offers unchanged | R | R |

D and H emit no recruit-log events; their UI actions/state changes are scored above. E has no Discover event yet: its reward is pending until the golden unit is played.

| Sequence | x1 | Reduce |
|---|---|---|
| A | PASS | PASS |
| B | FAIL: swallowing versus stacking unresolved | FAIL: same |
| C | PASS | PASS |
| D | FAIL: target meaning unresolved | FAIL: same |
| E | PASS | PASS |
| F | FAIL: arrival/away state unresolved | FAIL: same |
| G | PASS | PASS |
| H | PASS | PASS |

**Rule knowledge versus screen uncertainty**

A’s “is this hand?” and H’s tier-control meaning need no board labels: Rules pages 1/4 establish buying/playing, and page 3 shows the tier glyph and distinguishes better future shops from refreshing. E’s delayed reward is explicitly taught on page 5.

B remains a screen failure despite page 12 teaching Belly containment. F’s general departure/Egg relationship is also taught there; the exact two-turn duration is card-specific knowledge, not explained by these pages. Likewise, D’s Old Brock lending exception is not taught in the 14 pages. That limits any claim that the reader should explain *why*; the screen still failed to convey that the paired highlights identify a target.

**Problems and misreadings, ranked by damage to reading**

1. **B, frames 5–8: swallowing looks like stacking.** The Belly badge initially reads as equipment/bag/padlock. Reduce frame 8 retains a separate squirrel overlay; x1 clears it. Smallest fix: shrink the purchase into the Belly glyph, retire its overlay, then pulse the count once.

2. **F, frames 5–8: departure lacks a convincing arrival.** The away portrait resembles a hero/ability button. Reduce frame 8 retains the bird card beside it; x1 clears it, although the reader reports otherwise. Fix: dissolve the departing card into that portrait and briefly pulse its crescent/countdown.

3. **D, frames 2–7: identical gold highlights convey no relationship.** Selection, shared tribe and golden upgrade all seem plausible. Fix: retain a distinct selection treatment and briefly stamp a quarry glyph on the previewed target; clear it with the pulse.

4. **E, frames 3–7: identical overlapping copies resemble extra copies.** Reduce additionally obscures the golden result in frame 8. Fix: retire incoming overlays before exposing the golden card; briefly pulse each contributing source.

5. **C, frames 3–6: purchase crosses playable slots; an acorn resembles mouse artwork.** Fix: route travel clear of occupied portraits and pulse the hand destination.

6. **G, frames 2–7: fading resembles death; acorns crowd the counter.** The claimed 11→10→11 rollback is **W**: images and JSON show 10 through frame 5, then 11 throughout. Fix: keep acorns clear of digits and synchronize one payout pulse with removal.

7. **H, frames 2–6: new cost 7 competes with payment 5.** Fix: reveal the new price after payment settles; pulse the tier glyph.

Reduce loses travel continuity in A/B/C/E/F and gold routing in G/H, but introduces no additional failed sequence. No prohibited board tutorial text, reminders or static pointers were found; D’s opened card reader is permitted.

Read-only review completed. No files changed, commits, Godot runs or denied actions; nothing left undone.
