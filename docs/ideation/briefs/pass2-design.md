# Pass 2 design brief (9 Nov 2026)

Plan step 4 of `docs/ideation/plan-triage-redesign.md`. You are one of three designers working in parallel, each on one group of tribes. Design cards; don't build them.

## The problem, in the owner's words (`docs/design/owner-notes/2026-11-08f-birds-case-study.md`)

- "I can't see why you would play the early-game Birds over other cards in the game."
- "You have to have some synergy that gets you there along the entire journey."
- "We should have an even number of cards for every tribe and an even tier distribution."
- "If it's not fulfilling its primary purpose, then it's always useless and it becomes a trap."
- On journeys: look for skips, and "discovery rather than planning a tribe to be formulaic."
- On wording: "Clear and concise wording... If it's implied, let it be implied."

## Read first

- `.claude/skills/triage/SKILL.md`: the method. Role and window, competitors, journeys, parity.
- `docs/ideation/evidence/triage-audit.md`: §2 lists the cards that fail in their window, §3 the journeys, and §5 the gaps.
- `docs/ideation/evidence/benchmark-boards.md`: what each tribe's board looks like at rounds 3, 6, 9 and 12.
- `docs/ideation/evidence/birds-player-check.md`: a fresh player's notes after the Birds redesign.
- `docs/ideation/content/birds-pass1.md`: a worked example of a redesign in this format.
- Your tribes' existing content docs in `docs/ideation/content/`, and their `content/units/*.json`.
- `docs/design/rulebook.md`, for the rules you build on.

You are not given the power budget, on purpose. A separate reviewer will cost your designs.

## The target: every tribe has 16 shop-pool cards at 3/3/3/3/2/2 per tier (T1 to T6)

The shop pool today (`set: "slice"`, `pool` not false):

| Tribe | Count | T1–T6 | Needs |
|---|---|---|---|
| Birds | 16 | 3/3/3/3/2/2 | at par |
| Bog folk | 14 | 3/3/3/2/2/1 | +1 T4, +1 T6 |
| Fairies | 14 | 3/3/2/2/2/2 | +1 T3, +1 T4 |
| Hedgerow folk | 11 | 3/1/3/2/1/1 | +2 T2, +1 T4, +1 T5, +1 T6 |
| Hunters | 14 | 3/3/3/2/2/1 | +1 T4, +1 T6 |
| Oozes | 16 | 3/3/3/2/1/4 | +1 T4, +1 T5, two T6s move down or are redesigned |

Failing cards are **redesigned in place** (new text, new body, or a new tier) rather than added on top. Existing cards that work stay; taste revisions are out of scope. A card can move tier if the parity needs it and its role fits.

## For every new or changed card, give

- Name, tier, tribe, Attack/Health, and the full rules text (short; the details line separately).
- Golden text.
- **Role and window:** when a player wants it (the rounds and the board they'd have), and what it's for.
- **Competitors:** the best same-tier cards it must beat in that window, and why it beats them there.
- How it fits the tribe's journey from T1 to T6, and which sub-route it belongs to. Keep at least two sub-routes per tribe, so the tribe isn't formulaic.
- One situation where it's a great buy and one where it's a bad buy. Bad buys are fine; a card that fails its *primary* role in its window is a trap.
- Two variations.
- Any new mechanic or rule it needs, stated exactly.

Then for each tribe: a T1→T6 journey table that shows there's no tier players would skip, and two sample boards (a high roll and a low roll) at round 9.

## Groups

- **Group A, Hunters and Hedgerow folk.**
  - Hunters: early tempo (they're flat early: 6 reports), +1 T4, a second T6 finisher.
  - Hedgerow folk: +2 T2, +1 T4, and T5 and T6 payoffs that grow its bodies.
  - Mr Crumb's Pass landing on itself when the zigzag breaks: fix it, or make the rule obvious.
- **Group B, Oozes and Bog folk.**
  - Oozes: a T2 enabler, a T5 body for the slow middle, +1 T4, and fix the T6 pile-up (four T6s).
  - Bog folk: +1 T4, a second T6, and an earlier Mire (T2). The Peat Cutter and Tiddy Mun are weak in their windows (triage-audit §2). Mirers die before their target swings (P5 a).
- **Group C, Fairies, Birds tier 3, and the early rounds.**
  - Fairies: +1 T3 (not another Ring source), +1 T4, and Shy (5 reports call it a trap: Hob-in-the-Hearth walks out).
  - Birds tier 3: Tom Tit, Old Tern and Jack Daw were weak buys every time (player check). Also the 4–6 loss slump in rounds 7–12 while Birds are away and the board is half-stat Eggs. Stork's "missed a fight" rule and Nests' hidden Egg stats need clear wording. Birds stay at 16 cards.
  - The scripted early rounds (tally item 9: rounds 1–4 have few decisions and 0-damage ties) and thin supply (tally item 14). Propose concrete changes to neutrals, spells or the shop that give rounds 1–4 real decisions, as cards or rules.

## Output

Write `docs/ideation/content/pass2-<group>.md` (`pass2-a.md`, `pass2-b.md` or `pass2-c.md`), under 4,000 words. Commit it on a new branch `ideation/c-pass2-<group>` from `origin/ideation/main`, and push. Don't change game code. Never push to or merge into `main`.
