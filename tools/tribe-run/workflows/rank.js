export const meta = {
  name: 'tribe-run-rank',
  description: 'One Opus ranker per seed compares its three designs; then one Opus chair picks the best of the run',
  phases: [{ title: 'Rank seeds', detail: 'one ranker per seed', model: 'opus' }, { title: 'Overall picks', detail: 'one chair', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
const WORDS = `Write for the owner, who reads these lines on the run's portal: plain words, short sentences, a person talking. Say what the tribe does and why it is or isn't the better one, naming cards or mechanics. No process talk, no jargon, and never name a design method or route (the owner may be reading with the methods hidden).`
// args.seeds: [{ id, designs: [[designId, finalVersion], ...] }], args.chair: true|false
const rankPrompt = s => `You are the ranker for one seed in Bramble's tribe design run. Bramble is a Hearthstone Battlegrounds-style auto-battler. Three designers each designed a 19-unit tribe from the same seed, a committee reviewed them, and some were revised once or twice. You compare the three and put them in order. Don't start subagents or workflows.

**What the owner wants (owner's words):** "ratings for them so that I can kind of see what the agents think is good", "I don't want bad ones removed", and on an earlier batch: "They're more creative. They feel more powerful. I can balance them afterwards." The run's deciding question is: **is the tribe fun to draft and grow, with a number-growth shape you'd want to play?** Distinctiveness comes second. Balance is not the question: the owner balances afterwards.

**Read only these**, and nothing else under /home/alex/code, and don't use the web:
1. ${RUN}/seeds/${s.id}.BRIEF.md — the seed, how Bramble plays, and the tier guide.
2. ${W}/docs/design/tribe-run/data-format.md — the version format you are reading, and the section "rankings/seed--<seed>.json" for the file you write.
3. For each design, its first version and its final version (the same file when it was never revised):
${s.designs.map(d => `   - ${d[0]}: ${RUN}/designs/${d[0]}/v1.json${d[1] > 1 ? ` and ${RUN}/designs/${d[0]}/v${d[1]}.json (final)` : ' (never revised; v1 is final)'}`).join('\n')}
Don't read the reviews or design.json: judge the designs yourself.

**Write** ${RUN}/rankings/seed--${s.id}.json:
{"seed": "${s.id}", "order": [the three design ids, best first, judged on their final versions], "why": [{"design": id, "line": one or two sentences}] for all three, "iteration_helped": [{"design": id, "line": one sentence}] for each design that was revised: did the final version beat v1, stay level, or lose something? Leave out designs that were never revised.}
${WORDS}
Use the design ids exactly as given above. Check the file parses: python3 -c "import json;json.load(open('${RUN}/rankings/seed--${s.id}.json'))"

Your final reply: the order, one line.`
const chairPrompt = `You are the chair of Bramble's tribe design run. Bramble is a Hearthstone Battlegrounds-style auto-battler. 45 tribes were designed from 15 seeds (three each), reviewed by a three-member committee, some revised once or twice, and each seed's three designs were ranked. You pick the best of the whole run: up to 12 picks. Don't start subagents or workflows.

**What the owner wants (owner's words):** "I want reviews and ratings for the best designs", "ratings for them so that I can kind of see what the agents think is good", "I want a good variety of species and tribes", and on an earlier batch: "They're more creative. They feel more powerful. I can balance them afterwards." The run's deciding question is: **is the tribe fun to draft and grow, with a number-growth shape you'd want to play?** Distinctiveness comes second. Balance is not the question.

**Read**, under ${RUN} only (and ${W}/docs/design/tribe-run/data-format.md for the formats), and don't use the web:
1. ${RUN}/run.json and every ${RUN}/designs/*/design.json — each design's tribe name, summaries, status, and the committee's mean ratings and votes at each version.
2. Every ${RUN}/rankings/seed--*.json — each seed's order and reasons.
3. Then the version files (v1.json, v2.json, v3.json) of your contenders — read as many designs as you need to choose well, at least 20, and always both the first and the final version of anything you might pick, because a pick names a version and v1 is sometimes the better one. Read a seed's BRIEF.md in ${RUN}/seeds/ if you need the game rules or a seed's background.
The committee's ratings are one input; they cluster around 7, so don't just sort by them. Read the cards.

**Write** ${RUN}/rankings/overall.json: {"picks": [{"design": design id, "version": the version you pick (1, 2 or 3), "rank": 1.., "line": one or two sentences on why it's a pick}]}, up to 12 picks, best first. Prefer a spread of seeds and of kinds of play over three takes on one seed, but don't drop a clearly better design for the sake of spread.
${WORDS}
Use design ids exactly as the folder names. Check: every pick's design folder and version file exist, ranks run 1..n, and the file parses.

Your final reply: the picks, one line each (rank, design id, version).`
const ranked = await parallel((args.seeds || []).map(s => () => agent(rankPrompt(s), { label: `rank:${s.id}`, phase: 'Rank seeds', model: 'opus', effort: 'high', agentType: 'general-purpose' }).then(r => ({ seed: s.id, order: r }))))
let chair = null
if (args.chair) chair = await agent(chairPrompt, { label: 'chair', phase: 'Overall picks', model: 'opus', effort: 'high', agentType: 'general-purpose' })
return { ranked, chair }
