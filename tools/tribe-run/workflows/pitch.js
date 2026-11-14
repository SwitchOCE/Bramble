export const meta = {
  name: 'tribe-run-pitch',
  description: 'One Opus pitch writer per design writes pitch.json: the two-minute read on top of the full design',
  phases: [{ title: 'Pitch', detail: 'one writer per design', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
// args.items: [[designId, finalVersion], ...]
const prompt = (id, v) => {
  const seed = id.split('--')[0], D = `${RUN}/designs/${id}`
  return `You are writing the short pitch for one tribe design in Bramble's tribe design run. Bramble is a Hearthstone Battlegrounds-style auto-battler. The design is finished: a designer wrote it, three reviewers rated it, and it may have been revised. The owner has 60 of these to read and each takes about 15 minutes in full. Your pitch is the layer on top that lets the owner understand this tribe in two or three minutes. Don't start subagents or workflows.

**The owner's words:** "I want this stuff summarized. ... a layer of interfacing on top that makes it so I can look at one of these tribes and get an understanding within 2 to 3 minutes, because it currently would take me probably 15 minutes to go through each one. So I need to cut the word count down, but preserve the most important top line stuff. ... Highlight the important stuff first. Take me through almost as like a pitch in a slide." And: "Don't change the underlying stuff."

**Read**, and nothing else under /home/alex/code, and don't use the web:
1. ${W}/docs/design/tribe-run/data-format.md — the section "designs/<id>/pitch.json" is the file you write; the rest explains the files you read.
2. ${RUN}/seeds/${seed}.BRIEF.md — Part B only (how Bramble plays), so you use the game's words correctly.
3. ${D}/v${v}.json — the final version. This is what you pitch.${v > 1 ? `\n4. ${D}/v1.json${v > 2 ? ` and ${D}/v2.json` : ''} — earlier versions, only to say what changed since v1 (each later version's "changes" list gives the what and why).` : ''}
5. ${D}/reviews/v${v}--combo.json, v${v}--climber.json and v${v}--reader.json — what the three reviewers said about the final version.
6. ${D}/design.json, and ${RUN}/rankings/seed--${seed}.json — where the design stands and how it compares with the same seed's other two designs.

**Write** ${D}/pitch.json in the pitch format, with "design_id": "${id}" and "v": ${v}. Change no other file.
- **hook:** the one sentence you'd say to make someone want to play this tribe. What you do and why it feels good, not a list of features.
- **loop:** three steps, in order: what you do each turn, what that builds, how it pays off. Name the tribe's own mechanic.
- **growth:** pick the shape that fits best, and say in one line how the numbers grow (when, on what, how fast).
- **feel:** early, mid and late game, a few words each.
- **stars:** the 3 cards that best show what the tribe is, each with why in a few words.
- **roles:** one role for every unit and extra in v${v}, from the format's list, by what the card mostly does in this tribe.
- **card_short:** for every unit and extra, at most 10 words saying what the card does in plain words, so a row of cards can be scanned. Keep the tribe's keyword names; drop exact numbers unless the number is the point.
- **builds:** up to 3, a name and a line each.
- **liked** and **worries:** up to 2 each, from the three reviews of v${v}: what they agreed was best, and what they most worried about. A broken or watch flag in those reviews belongs in worries, naming the card.
- **changed:** ${v > 1 ? 'up to 3 lines: the biggest changes since v1.' : 'an empty list (this design was never revised).'}
- **verdict:** one sentence: who would enjoy this tribe and what kind of game it gives them. No ratings, rank or pick number: the page shows those itself.

**Rules:**
- Plain words, short, a person talking. No process talk, no jargon beyond the game's own terms, and never name the design method or route.
- Report, don't judge: the pitch says what the design does and what the reviewers and ranker said. Don't add your own opinion, and don't invent anything that isn't in the files.
- Stay inside the word limits; they are what makes this a two-minute read.

**Check:** cd ${W} && python3 tools/tribe-run/check_pitch.py docs/design/tribe-run/run ${id}
Fix your file until it reports 0 problems.

Your final reply: the hook, one line.`
}
phase('Pitch')
const out = await parallel(args.items.map(it => () => agent(prompt(it[0], it[1]), { label: `pitch:${it[0]}`, phase: 'Pitch', model: 'opus', effort: 'high', agentType: 'general-purpose' }).then(r => ({ id: it[0], hook: r }))))
return out
