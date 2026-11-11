# Batch 2 portrait notch repaint

Repainted **47 portraits** from the 52 batch 2 jobs, with 47 matching `notch-<id>.txt` prompts. The five approved pilots in this slice were skipped unchanged: `pill_bug`, `pinch_of_dust`, `toll_bard`, `wee_wobbly`, `wisp`.

**Retries: 4**, once each for `reel_mistress`, `silky`, `signor_ranocchio` and `spitfire_sal`. Their first passes used Mrs Mallow as reference 4; they were regenerated with the required Wisp pilot for local glow. All corrected passes were accepted. No identity or rendering failure required another attempt. **Requested portraits kept unrepainted: 0.**

Each portrait was reviewed against its original for identity, essential props, painted form, upper-right light and crisp outer ink. Reviewed all at 150 px and Pipkin in a 70 px circle. Verified all exports are exact 512×512 RGB JPEGs at quality 90 derived from their accepted PNG masters; all prompt headers match the unchanged production header. All 12 trial portraits remain untouched. Scope and whitespace checks pass. No code, content or tests changed; game tests and in-game captures were not run.

The 47-pair contact sheet is `build/notch/contact-sheet.png`, with its JSON index alongside it. Each portrait is exactly 150 px; current art is exported from `e6af222d`. PNG masters, originals and review artifacts remain uncommitted under `build/notch/`. Generation used the existing Codex image wrapper and built-in imagegen.

Checkpoint commits: `749c2160` (9 portraits), `5f46fbb3` (10), `58a73cef` (10), `863e4554` (12). The final commit adds the remaining six portraits and this note. Nothing pushed or merged.
