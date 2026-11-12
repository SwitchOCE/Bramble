# Design-process session (archived 12 Nov 2026)

The working files of the "Bramble design agents and philosophy" session (Claude Code, 10–12 Nov 2026). It reviewed how Ideation 1 and 2's agents designed, interviewed the owner on their design philosophy, and ran two small experiments on design routes. Exploratory work: nothing here is a rule or a decided design. The Quilboar card and the Ogre tribes were test pieces for comparing routes, written for Hearthstone Battlegrounds, not for Bramble.

**What came out of it** lives on `ideation/main` (merged at `2057daed`), not here:
- the general `game-design-process` skill (`.claude/skills/game-design-process/`), used only when the owner or an orchestrator says so;
- Bramble's specifics in `docs/design/bramble-design-guidance.md`;
- the owner note `docs/design/owner-notes/2026-11-10d-audience.md`.

## The experiments
Each was one run per route (n = 1), judged by the owner. The skill's route table and `background.md` summarise the findings.

**1. One new Quilboar card per route** (`routes/`). `KEY-do-not-show.txt` maps the letters to routes: A surgical, B bottom-up mechanical, C top-down flavor, D bottom-up flavor, E top-down mechanical. The owner rated E best.

**2. One 24-minion Ogre tribe per route** (`tribes/`). Every designer got the same brief, `BRIEF.md` (Warcraft lore plus how Battlegrounds plays), and a route. The owner judged them blind:
- `Tribe-1..5.md` in `tribes/blind/` are the blinded copies the owner saw.
- `KEY-blind-do-not-show.txt` maps them to `P–T.md`.
- `KEY-do-not-show.txt` maps P–T to routes: P top-down mechanical, Q bottom-up flavor, R surgical, S top-down flavor, T bottom-up mechanical.
- `compare.json` holds the rule-difference overview behind the page.

## Files
| Path | What it is |
|---|---|
| `design-philosophy-notes.md` | Interview notes on the owner's design philosophy, the contrast with how the agents designed, both experiments and the owner's decisions |
| `routes/` | Experiment 1: five Quilboar cards and their key |
| `tribes/` | Experiment 2: the brief, five tribes, the blinded copies, the keys and the comparison data |
| `page/ogre-tribes.html` | One page with no build step (open it in a browser): the five tribes as card templates, a rules matrix, a tier heatmap and side by side. It shows the blinded labels |
| `page/parse.py`, `build.py`, `template.html`, `data.json` | How the page was built: `python -I parse.py <tribes/blind> data.json`, then `python -I build.py <tribes/compare.json>` |
| `review/` | Two independent Fable 5.2 reviews of the skill draft (`brief*.md` are the briefs, `report-fable*.md` the reports) and the plan for publishing it to `ideation/main` |
