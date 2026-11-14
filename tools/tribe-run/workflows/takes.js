export const meta = {
  name: 'tribe-run-takes',
  description: 'One Opus writer per seed writes the three-takes comparison: what is different about each of the seed\'s three designs',
  phases: [{ title: 'Takes', detail: 'one writer per seed', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
// args.seeds: [seedId, ...]
const prompt = seed => `You are writing a small side-by-side comparison of the three tribe designs made from one seed in Bramble's tribe design run. Bramble is a Hearthstone Battlegrounds-style auto-battler. Three designers each designed a tribe from the seed "${seed}"; the three are finished, reviewed and ranked. Don't start subagents or workflows.

**The owner's words:** "for each of the seeds, I want to have its, like, the three different takes on changelings and what's different about them, kind of as a small summary, so that I can kind of pick and choose which ones I want to look at."

So the reader has not opened any of the three. They want to know, in a few seconds, how the three takes differ, so they can decide which to open.

**Read**, and nothing else under /home/alex/code, and don't use the web:
1. ${W}/docs/design/tribe-run/data-format.md — the section "rankings/takes--<seed>.json" is the file you write; the sections on pitch.json and the version files explain what you read.
2. ${RUN}/rankings/seed--${seed}.json — the three design ids in ranked order (use this order), and why the ranker placed them so.
3. For each of the three designs (folders ${RUN}/designs/${seed}--*/): its pitch.json (the short pitch: hook, loop, growth, stars, builds), its design.json (final_version), and its final version file v<final_version>.json (identity and cards), so your contrast rests on what the cards actually do.

**Write** ${RUN}/rankings/takes--${seed}.json in the takes format. Change no other file.
- **shared:** what all three have in common, beyond the seed's name: the idea all three designers reached for.
- **differ:** the main way they split: the one question the three answer differently (for example what the tribe's resource is, where its power sits, when it peaks, what the player does each turn).
- **takes:** one per design, in the ranking's order. For each:
  - **label:** a 2 to 4 word nickname that tells the three apart at a glance, built from what the take does (for example "The copy shop", "One giant knight"). Not the tribe's name (two of the three may share it), and never the name of a design method.
  - **line:** what this take does that the other two don't: its own mechanic and the kind of game it makes. Name its key mechanic or a card.
  - **look_if:** finishes "Look at this one if you want…": the reason to open this one over the others. Start it in lower case, without the words "Look at this one if you want".
- The three must contrast with each other: if a line would fit two of the designs, sharpen it.
- Plain words, short, a person talking. Report what the designs do; no ratings, no ranking talk (the page shows order and ratings itself), and never name the design method or route.

**Check:** cd ${W} && python3 tools/tribe-run/check_takes.py docs/design/tribe-run/run ${seed}
Fix your file until it reports 0 problems.

Your final reply: the three labels, in order, on one line.`
phase('Takes')
const out = await parallel(args.seeds.map(s => () => agent(prompt(s), { label: `takes:${s}`, phase: 'Takes', model: 'opus', effort: 'high', agentType: 'general-purpose' }).then(r => ({ seed: s, labels: r }))))
return out
