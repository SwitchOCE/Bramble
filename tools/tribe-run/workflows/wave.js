export const meta = {
  name: 'tribe-run-wave',
  description: 'Per design: Opus designer writes v1, Opus extractor makes the JSON, then committee reviews and revisions until settled or capped at v3',
  phases: [{ title: 'Design', model: 'opus' }, { title: 'Extract', model: 'opus' }, { title: 'Review', model: 'opus' }, { title: 'Revise', model: 'opus' }],
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
const MAXV = 3
const VERDICT = { type: 'object', properties: { fun: { type: 'integer' }, distinct: { type: 'integer' }, verdict: { type: 'string', enum: ['settle', 'iterate'] } }, required: ['fun', 'distinct', 'verdict'] }
const MEMBERS = {
  combo: { name: 'the combo player', lens: `You are the combo player (the owner's "Johnny"). You look for interwoven synergies, uses of a card outside its intended purpose, and real decisions each turn. A tribe where every card does one obvious job bores you; a tribe whose cards overlap in ways the designer may not even have listed delights you.` },
  climber: { name: 'the ranked climber', lens: `You are the ranked climber. You ask: does each tier do its job in the tier guide (Part C of the brief)? Does the number growth have a shape you'd want to play, from the first turns to the late game? Flag runaway loops as \`broken\` or \`watch\`, and don't mark power down just because it runs hot: the owner balances afterwards.` },
  reader: { name: 'the reader', lens: `You are the reader. You ask: can a player who knows Bramble read each card at a glance and know what it does? Does the woodland folk fantasy come through in what the cards do, not just in their names?` },
}
const reviewPrompt = r => `You are one of three committee members reviewing one version of a new tribe design for Bramble, a Hearthstone Battlegrounds-style auto-battler. The other two members review the same version through other lenses; you never see their reviews. Don't start subagents or workflows.

**Your lens.** ${MEMBERS[r.member].lens}

**What the owner wants from this run (owner's words):** "I want reviews and ratings for the best designs", "ratings for them so that I can kind of see what the agents think is good", and "I don't want bad ones removed". On an earlier batch of hot, creative designs: "They're more creative. They feel more powerful. I can balance them afterwards." and "we're way too worried about balance." So: rate honestly, never ask for a design to be removed, and don't sand a hot, creative design down.

**Read only these three files**, and nothing else under /home/alex/code (no other versions, reviews or designs), and don't use the web:
1. ${RUN}/seeds/${r.seed}.BRIEF.md — what the designer was given: the seed, how Bramble plays, and the tier guide.
2. ${W}/docs/design/tribe-run/data-format.md — only the section "designs/<id>/reviews/v<n>--<member>.json" (the review format) and "Stable card ids".
3. ${RUN}/designs/${r.id}/v${r.v}.json — the version you are reviewing. Judge it as it stands.${r.v > 1 ? ' It is a revised version: its "changes" and "declined" lists say what the reviser did; you are reviewing the result, not the revision.' : ''}

**Write** ${RUN}/designs/${r.id}/reviews/v${r.v}--${r.member}.json in the review format, with "id": "v${r.v}--${r.member}", "design_id": "${r.id}", "v": ${r.v}, "member": "${r.member}".
- **ratings:** two whole numbers from 1 to 10, through your lens. "fun" is **Fun to draft and grow**: would you want to draft this tribe and watch its board grow across a game? "distinct" is **Distinctive**: does it play unlike today's tribes and unlike a generic auto-battler tribe? The owner will sort 45 designs by these numbers, so they must tell designs apart: every design in this run is competent, and competent is not a high score. Anchors: 4 = it works but you'd skip it; 5 = solid, does the expected thing; 6 = good, with one or two fresh interactions; 7 = clearly better than a typical new tribe, you'd happily draft it; 8 = you'd pick it over today's tribes most games (rare); 9 = one of the best tribe designs you've seen (very rare); 10 = almost never. Rate the two separately: a tribe can be fun and familiar, or novel and a chore. Before giving 8 or more, name in ratings_why the specific thing that earns it over a 7. Give each a one-line reason in ratings_why.
- **points:** at most 5, the ones that matter most, each with a pid (p1, p2, …), the card's uid (or null for a point about the whole tribe), a kind and a short text. A point is a **fix** only when something is broken (a loop with no counterplay, one choice that is always right) or unclear (a card a player can't read or whose rules don't work as written). Anything else, including "this would be more fun if", is an **idea**. Being strong is not a fix.
- **standouts** (up to 3) and **weakest** (up to 3): cards by uid, each with a short why.
- **flags:** any number, each with a uid, kind broken | watch | unclear, and a short note. broken = a real runaway or lock with no counterplay; watch = could run away, worth the owner's eye; unclear = can't be read.
- **verdict:** "settle" when more iterating would likely make the design only different, not better. "iterate" when there is a real fix to make. Give verdict_why in one line.
- Keep every text short and plain: one or two sentences. Name cards by their names in the text; use only uids that exist in the version file.

**Check your file:** cd ${W} && python3 tools/tribe-run/decide.py docs/design/tribe-run/run ${r.id} --write && python3 tools/tribe-run/validate.py docs/design/tribe-run/run ${r.id}
Fix any problem it reports in your own review file (ignore problems in files that aren't yours, and a "tier shape" warning). If the command fails with a JSON read error, wait a few seconds and run it again: another member may be writing at the same moment. Change no file but your review.

Your final reply: one line with your two ratings and your verdict.`
const revisePrompt = d => {
  const p = d.v - 1
  const D = `${RUN}/designs/${d.id}`
  return `You are the reviser for one tribe design in Bramble's tribe design run. Bramble is a Hearthstone Battlegrounds-style auto-battler. A designer wrote this tribe, three committee members reviewed it, and you now write version ${d.v}. Don't start subagents or workflows.

**Your instructions (from the run's brief, which the owner approved):**
"Keep what makes this tribe this tribe: its core mechanic, its best cards, its boldness. The owner prefers designs that are creative and run hot, and does the balancing later, so don't tone a card down just because it is strong. Change a card for being broken (a loop with no counterplay, one choice that is always right) or unclear. Ideas you like are welcome too. Answer every point marked fix: apply it, or decline it in one line. Ideas are optional. Every changed card gets a short what and a short why. Keep card ids; new cards take new numbers. Keep the 19-unit shape unless a review asks you to fix it."

**Read only these**, and nothing else under /home/alex/code (no other designs, no earlier versions than v${p}), and don't use the web:
1. ${RUN}/seeds/${d.seed}.BRIEF.md — what the designer was given: the seed, how Bramble plays, and the tier guide.
2. ${W}/docs/design/tribe-run/data-format.md — the format of the file you write (sections "Stable card ids" and "designs/<id>/v<n>.json") and of the reviews you read.
3. ${D}/v${p}.json — the version you are revising.
4. ${D}/reviews/v${p}--combo.json, ${D}/reviews/v${p}--climber.json and ${D}/reviews/v${p}--reader.json — the three reviews. A point's reference is "<review id>#<pid>", for example "v${p}--combo#p2".

**Write** ${D}/v${d.v}.json: the whole tribe as it now stands, in the v<n>.json format, with "design_id": "${d.id}" and "v": ${d.v}.
- Start from v${p}.json and carry over everything you don't change, word for word (identity, units, extras, builds, risks, tier_check, rationale).
- Every card keeps its uid, even if renamed, retiered or rewritten. A new card takes the next free number (units after the highest u-number ever used, extras after the highest x-number). A removed card drops out of "units" and keeps its uid in "changes" with kind "removed"; its uid is never reused.
- "changes": one entry for every unit or extra that differs from v${p} in name, tier, attack, health, text or golden: {"uid", "kind": changed|added|removed|renamed|retiered, "what", "why", "from"}. "what" and "why" are at most about 20 words each, plain words. "from" lists the review points behind the change, or ["own"] if it was your own idea. If you change the tribe as a whole (the mechanic, a keyword's text, how it plays, the tribe's name), add one entry with "uid": "identity" and what, why and from. Don't list a card you didn't change.
- "declined": one entry for every fix point you did not apply: {"point": "v${p}--<member>#<pid>", "why": "one line"}. Every point with kind "fix" in the three reviews must appear either in some change's "from" or in "declined". Ideas you didn't take need no entry.
- Update builds, risks and tier_check where your changes make them wrong; otherwise leave them.
- When you fix an unclear card, write the full new card text, in Bramble's card wording from the brief, so a player can read it at a glance. Keep golden text in step with the text.

**Then:**
1. cd ${W} && python3 tools/tribe-run/decide.py docs/design/tribe-run/run ${d.id} --write
2. In ${D}/design.json, add a "summary" to the version ${d.v} entry in "versions": two lines on what changed in this version and why, in plain words. Change nothing else in that file.
3. python3 tools/tribe-run/validate.py docs/design/tribe-run/run ${d.id}
   Fix v${d.v}.json until it reports 0 problems. A "tier shape" warning is fine if the shape was already different. Change no other file.

Your final reply: one line on what you changed, and how many fix points you applied and declined.`
}

const review = (id, seed, v, member) => agent(reviewPrompt({ id, seed, v, member }) + '\n\nReturn the two ratings and the verdict exactly as you wrote them in the file.', { label: `review:${id}:v${v}:${member}`, phase: 'Review', model: 'opus', effort: 'medium', agentType: 'general-purpose', schema: VERDICT })
const revise = (id, seed, v) => agent(revisePrompt({ id, seed, v }), { label: `revise:${id}:v${v}`, phase: 'Revise', model: 'opus', effort: 'high', agentType: 'general-purpose' })
// args.items: [[designId, version, 'review' | 'revise', membersStillMissing?], ...] from decide.py (tools/tribe-run/todo.py)
async function runDesign(item) {
  const id = item[0], seed = id.split('--')[0]
  let v = item[1], members = item[3] && item[3].length ? item[3] : Object.keys(MEMBERS), votes = item[4] || 0
  if (item[2] === 'revise') {
    const r = await revise(id, seed, v)
    if (!r) return { id, v, state: 'revise returned nothing; decide.py will pick it up' }
  }
  while (true) {
    const rs = await parallel(members.map(m => () => review(id, seed, v, m)))
    if (rs.some(x => !x)) return { id, v, state: 'reviews incomplete; decide.py will pick it up' }
    const settle = votes + rs.filter(x => x.verdict === 'settle').length
    const summary = rs.map(x => `${x.fun}/${x.distinct} ${x.verdict}`).join(', ')
    if (v >= MAXV) return { id, v, state: 'capped', last: summary }
    if (settle >= 2) return { id, v, state: 'settled', last: summary }
    v += 1; members = Object.keys(MEMBERS); votes = 0
    const r = await revise(id, seed, v)
    if (!r) return { id, v, state: 'revise returned nothing; decide.py will pick it up' }
  }
}

// args.designs: [{ id, seed, name, route }] — designs with no v1.md yet
async function runNew(d) {
  const a = await agent(designPrompt(d), { label: `design:${d.id}`, phase: 'Design', model: 'opus', effort: 'high', agentType: 'general-purpose' })
  if (!a) return { id: d.id, state: 'design returned nothing; decide.py will pick it up' }
  const e = await agent(extractPrompt(d), { label: `extract:${d.id}`, phase: 'Extract', model: 'opus', effort: 'low', agentType: 'general-purpose' })
  if (!e) return { id: d.id, state: 'extract returned nothing; decide.py will pick it up' }
  return runDesign([d.id, 1, 'review'])
}
const out = await parallel(args.designs.map(d => () => runNew(d)))
return out
