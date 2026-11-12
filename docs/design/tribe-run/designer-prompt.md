# Designer prompt for the tribe run

This is the 12 Nov Ogre test prompt (the version with the tier guide), with only the game and the seed swapped. Keep the wording. `<…>` marks the slots.

**Brief file, one per seed (`<seed>/BRIEF.md`):**
- **Part A, the seed.** The species or tribe idea: its folio entry if it has one (species, place, the institution or genre it parodies, and its real-animal behaviour), plus concrete material a designer could draw on. Same length and kind as the Ogre brief's lore section.
- **Part B, how Bramble plays.** A neutral summary of the rulebook: board, shop and tiers, economy, triples, combat, keywords in use, and today's tribes' core mechanics in one line each. Written once and shared by every seed.
- **Part C, the tier guide.** The text of `docs/design/tier-guide.md`, Parts 1 and 2, unchanged, under the heading "Part C: tier guide", with this intro: "A short guide to what each tier is for and roughly how much a unit there gives. It was built from 310 Battlegrounds units valued by role and by stats added per turn. It's a guide, not a limit: a unit can break it if that makes the tribe more fun and you say why."

**Prompt:**

```text
Design a complete new Bramble tribe: **<tribe name or seed>**, with **19 units**: 2 at Tier 1, 3 at Tier 2, 4 at Tier 3, 4 at Tier 4, 3 at Tier 5 and 3 at Tier 6. Read <path>/BRIEF.md first, for the seed, the current game and a tier guide (Part C). Read no other file in that folder or under /home/alex/code, and don't use the web.

This is one of several parallel design exercises. Each uses a different design route. Yours is below. Follow it faithfully, even where another route would feel more natural.

<route block, verbatim from the list below>

**Audience (owner's words):** "Johnny is the more important one to focus on. Cards need to have cool interlapping, interwoven and overlapping effects and synergies... Ways of using them outside of their necessarily intended purpose." Spike is kept happy through balance. Timmy is not the focus.

**Output:** write <path>/<letter>.md, at most about 2,500 words:
1. **Identity:** the core mechanic and any new keyword, and one paragraph on how the tribe plays.
2. **The 19 units:** a table with name, tier, attack/health, text and golden text, sorted by tier. Add any tokens or spells the tribe needs, kept few, listed separately.
3. **Builds:** two to four ways to play the tribe, and how it mixes with other tribes in a lobby.
4. **Risks and holes** you can see.
5. **Tier check:** one line per tier on how its units fit the tier guide in Part C, and where you broke it on purpose.
6. **Design rationale:** the main decisions in the order you made them, one line each with the reason, at most 12 lines.

Leave the route's name out of the file, because the owner will rate the files blind. Your final reply to me is just the file path.
```

**Route blocks (verbatim from the Ogre test):**

- **Bottom-up mechanical:** "**Your route: bottom-up, mechanical-first.** Start from specific, concrete mechanical interactions or player tensions you find interesting: particular numbers puzzles, decisions and trade-offs, not themes. Design cards from those one at a time. Let the tribe's shared mechanic emerge from what the cards have in common, then fill out the tribe from there. Add lore and names last. The owner's example of this route is a leftover-and-efficiency puzzle: a conversion that gives a better rate of return but not what you need right now."
- **Surgical:** "**Your route: surgical (middle-out).** In the owner's words: "neither a top-down nor a bottom-up approach... examining the whole system and trying to place a piece surgically inside of it." 1. Examine the existing game: the current tribes, neutrals, keywords and systems, and how a lobby plays. 2. Find the roles, play patterns and decisions that are under-served. 3. Decide which gaps this tribe should fill. 4. Place each card deliberately, by its role (economy, enabler, payoff, stat holder, bridge to other tribes, and so on) and by its tier in the player's progression curve. 5. Add flavor and names after the slots are set." Its output's rationale also lists "the gaps you found in two or three lines".
- **Top-down flavour:** "**Your route: top-down, flavor-first.** Start from a high-level flavor concept: what <the folk> are in the world, and what fantasy playing them should give. Pick the themes from the seed that define the tribe. Decide what kinds of effects those themes imply. Work down from there to the tribe's mechanic, and then to each specific card. Mechanics follow from flavor."
- **Spare, top-down mechanical:** "**Your route: top-down, mechanical-first.** Start from the mechanical system the tribe needs: 1. Define its core mechanic. 2. List the categories of effect the mechanic needs in order to work (for example generating it, scaling it, converting it, paying off on it, supporting it). 3. Decide how many cards each category gets and where they sit in the tiers. 4. Sketch many loose concepts per category. 5. Fill each slot with a specific card. Lore and names come last."

**Run settings from the test:** one fresh Opus `general-purpose` designer per version. No examples from other tribes, since designers copy them. The original and tested prompts are in `docs/design/tier-guide-test/prompts/`.
