export const meta = {
  name: 'tribe-run-loop',
  description: 'Per design: three Opus committee reviews, then an Opus revision if they ask for one, until settled or capped at v3',
  phases: [{ title: 'Review', detail: 'three members per version', model: 'opus' }, { title: 'Revise', detail: 'one reviser per new version', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
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
const out = await parallel(args.items.map(it => () => runDesign(it)))
return out
