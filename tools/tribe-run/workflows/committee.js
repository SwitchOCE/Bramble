export const meta = {
  name: 'tribe-run-committee',
  description: 'Committee round: three Opus members each review one version of a tribe design through their own lens',
  phases: [{ title: 'Review', detail: 'one agent per member per design version', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
const MEMBERS = {
  combo: { name: 'the combo player', lens: `You are the combo player (the owner's "Johnny"). You look for interwoven synergies, uses of a card outside its intended purpose, and real decisions each turn. A tribe where every card does one obvious job bores you; a tribe whose cards overlap in ways the designer may not even have listed delights you.` },
  climber: { name: 'the ranked climber', lens: `You are the ranked climber. You ask: does each tier do its job in the tier guide (Part C of the brief)? Does the number growth have a shape you'd want to play, from the first turns to the late game? Flag runaway loops as \`broken\` or \`watch\`, and don't mark power down just because it runs hot: the owner balances afterwards.` },
  reader: { name: 'the reader', lens: `You are the reader. You ask: can a player who knows Bramble read each card at a glance and know what it does? Does the woodland folk fantasy come through in what the cards do, not just in their names?` },
}
const prompt = r => `You are one of three committee members reviewing one version of a new tribe design for Bramble, a Hearthstone Battlegrounds-style auto-battler. The other two members review the same version through other lenses; you never see their reviews. Don't start subagents or workflows.

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
phase('Review')
const out = await pipeline(args.reviews, r => agent(prompt(r), { label: `review:${r.id}:v${r.v}:${r.member}`, phase: 'Review', model: 'opus', effort: 'medium', agentType: 'general-purpose' }).then(x => ({ id: r.id, v: r.v, member: r.member, result: x })))
return out