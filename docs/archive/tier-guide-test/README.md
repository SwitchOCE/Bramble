# Tier guide test: the Ogre tribes, with and without the guide (12 Nov 2026)

**What ran.** The 10 Nov design-skill test had five designers each make a 24-minion Ogre tribe for Hearthstone Battlegrounds, one per design route. It was rerun on 12 Nov with the same prompts, the same model (Opus `general-purpose` agents) and the same brief. One thing was added: the tier guide (`../tier-guide.md`, as "Part C"), numbers included, plus a tier check at the end of each design. For each route, a fresh Codex (gpt-6.1-sol) judge compared the old and new design blind, labelled A and B, on two things: power for place and distinctiveness.

**Files:**
- `old/` and `new/`: the designs and briefs. P is top-down mechanical, Q bottom-up flavour, R surgical, S top-down flavour, T bottom-up mechanical.
- `prompts/`: the exact prompts.
- `judge/`: the judge brief, the five verdicts and the A/B key.

## Result

| Route | Better power for place | More distinctive | Outliers, old → new |
|---|---|---|---|
| Top-down mechanical (P) | old | new | 2 → 4 |
| Bottom-up flavour (Q) | old | old | 1 → 5 |
| Surgical (R) | new | new | 4 → 2 |
| Top-down flavour (S) | new | new | 4 → 4 |
| Bottom-up mechanical (T) | old | new | 2 → 4 |

- **Distinctiveness held:** the new design was judged more distinctive in 4 of 5 routes.
- **Power:** the new designs ran hotter. 17 cards were judged far too strong, against 9 in the old designs, and 12 of those 17 are at Tiers 1–3. One reason is that designers costed per trigger while the judges counted the whole board.
- **One run per route,** so part of every difference is run-to-run luck.

## The owner's call (12 Nov)

> "I like these designs better. They're more creative. They feel more powerful. I can balance them afterwards. ... Even if it ships a bit overpowered, these tribes are cooler. They feel more interesting than the previous ones. So no, I don't want these changed."

> "I don't want it folded into the skill. I want it folded into the next run. Like, I wanted them to use the skill and, like, I want the process that produced this results in our next run. Obviously, the skill is independent of, it's a generic skill ... but this guide is about our designs."

So the guide stays as tested, the `game-design-process` skill stays generic and unchanged, and the next tribe run uses this process: `../tribe-run/PLAN-draft.md` and `../tribe-run/designer-prompt.md`.
