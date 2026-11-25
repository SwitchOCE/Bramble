# Council review, one round (24 Nov 2026)

Mode: low sensitivity, one round only (owner: "only a single council review"; "one four round", read as one full round, findings fixed, no re-check). Members reviewed the page, the tree, the proposal and the clips independently, read-only. Brief: `/data/fight-anim-work/council/BRIEF.md`.

| Member | Verdict | Score | How it viewed the clips |
|---|---|---|---|
| Claude Opus (claude-opus-5-5, high) | changes needed | 7/10 | ffmpeg frames, stacked sheets |
| GPT Sol (gpt-6.2-sol, high) | changes needed | 6/10 | ffmpeg stills from all nine clips, against the logs |
| Gemini Neon (gemini-4-neon, high) | changes needed | 6/10 | 39 ffmpeg frames, against the logs and code |

No member re-checked the fixes (one round). Members' findings overlapped; no two members contradicted each other, so the change list below is their union, no item dropped. Who raised each item is in brackets.

## Change list

**Tree and proposal (`plans/best.md`, `plans/tree.json`)**
1. Same unit attacks again (Windfury, Oakfeller, Tourney Champion) started at C+8, before the rules resolve the death round that causes it. Gate the re-lift on the queue; Oakfeller waits for its kill's fall. [Opus, Sol, Neon]
2. "After the hit" started at C+14, before a far attacker is home (C+15 to C+17). Start it at max(C+14, home). [Sol]
3. Aura loss shown at the fall; the rules remove it at once. Attach it to the lethal hit or destroy. [Sol]
4. Windows keyed on the exchange's first `damage` break when an exchange is fully prevented; War-drummer runs death effects inside `on_attack`; Captain summons before the hit; any pre-hit kill of the defender; nested attacks; Root or Molt returning to another slot. Key windows on the combat action and the logged destination. [Sol, Neon]
5. "Plays in the raised hold" is a guess: Battlegrounds footage has no case of an attacker's own trigger before its hit. Mark it as a guess on the page. [Opus]
6. The 1.6 s cap is per repeat group; the fixture's long aftermath runs 2.6 s. Say so. [Sol]
7. Stag Beetle prevents Cleave; CB5's moment is an area-damage death, not a summon. (non-blocking) [Neon]

**Film treatment and clips**
8. The proposal holds 1 frame at contact (C and C+1), not 0. Fix and re-film. [Neon]
9. CB4: the "today/freeze" pane splits Thorns (C+12) from the exchange (C+22) where the real build shows both at C+22; the "after" pane shows Health 5 → 1 under a −2 burst. Match the real build or label it; show 5 → 3 → 1 in step; say lethal Thorns can't use "after". [Sol, Opus, Neon]
10. CB7: rule 7's speed-up only on the proposal's pane; six buff repeats can't show the 9+ cap or a running-total damage burst; plan B's option missing. Same speed-up rule across panes; 10+ repeats of a damage effect; add B. [Sol, Opus, Neon]
11. CB2: add a past-centre stop (Galaxy) pane. (non-blocking) [Opus]

**Page**
12. Fix: best's moment timestamps; CB6 B's lift label; today's contact hold (5 frames on screen) and 12 frames to contact; strobe note with both the fast strike and the fast first return frame (108 px/f), and per-card-height comparison with Battlegrounds. [Opus, Neon]
13. The council's copy of the page had no clips beside it (orchestrator's setup error; the published page has them). [Sol]
