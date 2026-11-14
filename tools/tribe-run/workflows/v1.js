export const meta = {
  name: 'tribe-run-v1',
  description: 'Design each tribe (v1) with an Opus designer, then extract it to JSON',
  phases: [{ title: 'Design', detail: 'one fresh designer per tribe', model: 'opus' }, { title: 'Extract', detail: 'v1.md to v1.json', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
const ROUTES = {
  'bottom-up-mech': `**Your route: bottom-up, mechanical-first.** Start from specific, concrete mechanical interactions or player tensions you find interesting: particular numbers puzzles, decisions and trade-offs, not themes. Design cards from those one at a time. Let the tribe's shared mechanic emerge from what the cards have in common, then fill out the tribe from there. Add lore and names last. The owner's example of this route is a leftover-and-efficiency puzzle: a conversion that gives a better rate of return but not what you need right now.`,
  'surgical': `**Your route: surgical (middle-out).** In the owner's words: "neither a top-down nor a bottom-up approach... examining the whole system and trying to place a piece surgically inside of it."
1. Examine the existing game: the current tribes, neutrals, keywords and systems, and how a lobby plays.
2. Find the roles, play patterns and decisions that are under-served.
3. Decide which gaps this tribe should fill.
4. Place each card deliberately, by its role (economy, enabler, payoff, stat holder, bridge to other tribes, and so on) and by its tier in the player's progression curve.
5. Add flavor and names after the slots are set.`,
  'top-down-flavour': `**Your route: top-down, flavor-first.** Start from a high-level flavor concept: what <the folk> are in the world, and what fantasy playing them should give. Pick the themes from the seed that define the tribe. Decide what kinds of effects those themes imply. Work down from there to the tribe's mechanic, and then to each specific card. Mechanics follow from flavor.`,
  'top-down-mech': `**Your route: top-down, mechanical-first.** Start from the mechanical system the tribe needs:
1. Define its core mechanic.
2. List the categories of effect the mechanic needs in order to work (for example generating it, scaling it, converting it, paying off on it, supporting it).
3. Decide how many cards each category gets and where they sit in the tiers.
4. Sketch many loose concepts per category.
5. Fill each slot with a specific card.
Lore and names come last.`,
  'bottom-up-flavour': `**Your route: bottom-up, flavor-first.** Start from specific things in the seed that you like: particular characters, objects, places, customs and moments. Design cards from them one at a time, working out how each specific thing would behave mechanically. Let the tribe's shared mechanic emerge from what those cards have in common, then fill out the tribe from there. The owner's example of this route: "I really like beer. How would beer work as a resource?"`,
  'player-story': `**Your route: player-story first.** Before any card, write three short moments a player would tell a friend about after a game with this tribe: one in the shop, one in a fight, one about how the board grew across the game. Then design the cards that make those moments happen, and keep testing each card against them: which moment does it build towards? Let the shared mechanic come from what the moments have in common. Names and lore come last.`,
  'one-constraint': `**Your route: one hard constraint.** Pick one rule the whole tribe lives under, and make it strong enough to change how you play: for example a limit on board size, stats that only ever move between your units, or buffs that only last if something happens. Design every card inside it. The constraint should create decisions, not just limit them; the tribe's power comes from playing well inside it. Names and lore come last.`,
  'borrow-twist': `**Your route: borrow and twist.** Take one mechanic from outside auto-battlers (a deckbuilder, a board game, a roguelike, an MMO class, a sport) and make it work in Bramble's shop-and-fight loop. Say in one line where it comes from. Change it until it fits the woodland and the tier guide, then build the tribe around it. Names and lore come last.`,
}
const designPrompt = d => {
  const folk = d.name.replace(/^The /, 'the ')
  const block = ROUTES[d.route].replace('<the folk>', folk)
  const extra = d.route === 'surgical' ? ' Include the gaps you found in two or three lines.' : ''
  return `Design a complete new Bramble tribe: **${d.name}**, with **19 units**: 2 at Tier 1, 3 at Tier 2, 4 at Tier 3, 4 at Tier 4, 3 at Tier 5 and 3 at Tier 6. Read ${RUN}/seeds/${d.seed}.BRIEF.md first, for the seed, the current game and a tier guide (Part C). Read no other file in that folder or under /home/alex/code, and don't use the web.

This is one of several parallel design exercises. Each uses a different design route. Yours is below. Follow it faithfully, even where another route would feel more natural.

${block}

**Audience (owner's words):** "Johnny is the more important one to focus on. Cards need to have cool interlapping, interwoven and overlapping effects and synergies... Ways of using them outside of their necessarily intended purpose." Spike is kept happy through balance. Timmy is not the focus.

**Output:** write ${RUN}/designs/${d.id}/v1.md, at most about 2,500 words:
1. **Identity:** the core mechanic and any new keyword, and one paragraph on how the tribe plays.
2. **The 19 units:** a table with name, tier, attack/health, text and golden text, sorted by tier. Add any tokens or spells the tribe needs, kept few, listed separately.
3. **Builds:** two to four ways to play the tribe, and how it mixes with other tribes in a lobby.
4. **Risks and holes** you can see.
5. **Tier check:** one line per tier on how its units fit the tier guide in Part C, and where you broke it on purpose.
6. **Design rationale:** the main decisions in the order you made them, one line each with the reason, at most 12 lines.${extra}

Leave the route's name out of the file, because the owner will rate the files blind. Your final reply to me is just the file path.

Don't start subagents or workflows.`
}
const extractPrompt = d => `You are the extractor for Bramble's tribe design run: you turn one designer's Markdown file into the run's JSON format, changing no design content. Don't start subagents or workflows. Write only inside ${RUN}/designs/${d.id}/ ; don't commit.

Read ${W}/docs/design/tribe-run/data-format.md (the format), then ${RUN}/designs/${d.id}/v1.md (the design).

1. Write ${RUN}/designs/${d.id}/v1.json in the "v<n>.json" format, with "design_id": "${d.id}" and "v": 1.
   - identity: tribe_name (the name the designer gave the tribe), mechanic (the core mechanic, in the designer's words), keywords (each new keyword's name and rules text), plays (the paragraph on how it plays).
   - units: every unit, uid u01, u02, … in tier order (within a tier, the order of the designer's table). tier, attack and health are whole numbers. text and golden are the card's text and golden text. If a card has no golden text, use "".
   - extras: tokens, spells, trinkets and anything else listed separately, uid x01, x02, …, with kind token|spell|trinket|other. Put a token's or spell's stats and cost inside its text if the designer gave any.
   - builds, risks, tier_check (one entry per tier the designer wrote a line for), rationale: from the matching sections, in the designer's words.
   - "changes": [] and "declined": [].
   - Copy every name and every card text exactly, word for word, from v1.md. The validator checks each name and text against v1.md (after stripping the characters * _ \` \\ and collapsing whitespace), so don't fix typos, reword, shorten, merge table cells or change punctuation. Markdown bold may stay in the text. A table cell's escaped pipe or <br> stays as written.
   - Change no design content. If the design has more or fewer than 19 units, or a different tier shape, extract what is there.
2. Write ${RUN}/designs/${d.id}/design.json: {"id": "${d.id}", "seed": "${d.seed}", "route": "${d.route}", "tribe_name": "<as in identity>", "status": "reviewing", "versions": [{"v": 1, "author": "designer", "summary": "<two lines: the tribe in short, plain words, without naming the design route>"}]}
3. Run: cd ${W} && python3 tools/tribe-run/validate.py docs/design/tribe-run/run ${d.id}
   Fix your JSON until it reports 0 problems. A "tier shape" warning is fine; never change the design to remove it.

Your final reply: "ok", or the problems that remain.`
const results = await pipeline(
  args.designs,
  d => d.need === 'design'
    ? agent(designPrompt(d), { label: `design:${d.id}`, phase: 'Design', model: 'opus', effort: 'high', agentType: 'general-purpose' })
    : 'already designed',
  (prev, d) => agent(extractPrompt(d), { label: `extract:${d.id}`, phase: 'Extract', model: 'opus', effort: 'low', agentType: 'general-purpose' })
    .then(r => ({ id: d.id, design: prev ? 'done' : 'none', extract: r }))
)
return results