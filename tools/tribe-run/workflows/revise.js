export const meta = {
  name: 'tribe-run-revise',
  description: 'One fresh Opus reviser per design writes the next version from the committee reviews',
  phases: [{ title: 'Revise', detail: 'one reviser per design', model: 'opus' }],
}
const W = '/home/alex/code/Bramble-ideation-tribe-run'
const RUN = `${W}/docs/design/tribe-run/run`
const prompt = d => {
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
phase('Revise')
const out = await pipeline(args.designs, d => agent(prompt(d), { label: `revise:${d.id}:v${d.v}`, phase: 'Revise', model: 'opus', effort: 'high', agentType: 'general-purpose' }).then(x => ({ id: d.id, v: d.v, result: x })))
return out