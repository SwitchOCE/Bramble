# Tribe prototype run: goal and draft plan (draft for the owner, revised after the interrogation)

## Your words (11 Nov)

> "I don't think the current tribes are very good, to be honest, in ideation. I think we should give a bunch of agents species and, or like tribe, like ideas, seeded ideas similar to what we did in the Battlegrounds example, because that produced some very interesting tribes, especially a few of them were very good. And yeah. I want to get scaling and power budgeting in. ... we just need to focus on, like, number growth and etc. ... getting like 15 or 10 to 15 prototype tribe designs having each agent given a prompt, have like 2 or 3 options for each tribe with a different design method, and so there's like a bunch of options that I can look at, we don't need 24 units per tribe. Let's go with like 2 tier 1 units, 3 tier 2 units, 4 tier 3s, 4 tier 4s, and 3 tier 5s, and and 3 [tier 6s]."

## The goal

A menu of 10–15 new prototype tribes for you to browse and pick from. Each starts from a seed (a species or tribe idea) and comes in 2–3 versions, each made with a different design method. Every version has 19 units: 2 at tier 1, 3 at tier 2, 4 at tier 3, 4 at tier 4, 3 at tier 5 and 3 at tier 6. Each is designed with the tier guide, and checked for runaway growth.

**Deciding criterion (one):** is the tribe fun to draft and grow, with a number-growth shape you'd want to play?

**Out:** game code, art, and changes to today's tribes. Everything is on paper. You pick the winners; building them comes later.

## Steps

The design process is the one from the 12 Nov Ogre test, whose designs you preferred: "They're more creative. They feel more powerful. I can balance them afterwards." Designers use the `game-design-process` skill's routes, and they get the tier guide in full, numbers included. The skill stays generic; the guide is Bramble's and goes in the brief.

0. **Tier guide: done (12 Nov).** `docs/design/tier-guide.md`. It gives each tier's job, a starting shape for a 19-unit tribe, three rules of thumb and the curve as ratios. It goes into every designer brief unchanged, exactly as the Ogre test used it.
1. **Pilot: 3 seeds × 3 routes = 9 versions.** You see these before the rest is made.
2. **Full run: the remaining 7–12 seeds,** with the routes the pilot kept, in waves.
3. **For each version:**
   - **Design (an Opus designer, as in the Ogre test).** The prompt is `docs/design/tribe-run/designer-prompt.md`: the Ogre test's prompt with Bramble's seed and game in place of Ogres and Battlegrounds. The brief has three parts: the seed (from the folio, or new), how Bramble plays (from the rulebook), and the tier guide. Designers see no other tribe's designs. The three routes, one per version, with the skill's wording:
     - **Bottom-up mechanical:** your favourite on 10 Nov; judged more distinctive with the guide.
     - **Surgical:** won both power for place and distinctiveness with the guide.
     - **Top-down flavour:** won both with the guide.
     - Bottom-up flavour is dropped: it lost both with the guide. Top-down mechanical is the spare.
   - Each design ends with the **tier check** from the test: one line per tier on how it fits the guide, and where it breaks the guide on purpose.
   - **No costing review** (owner, 12 Nov, note `12a`: "I want more unreviewed stuff coming to me"). The designer's own tier check is the costing.
   - **Runaway check (Opus), as a flag only.** This is the two-pass check, against a pool of the version plus today's neutrals. BROKEN and WATCH cards are marked for you and nothing is changed. It runs alongside the gallery and holds nothing up. The winners you pick are checked again together.
4. **Gallery.** One page with every version. Each shows its identity, all 19 cards in full text, its builds, its tier check and any runaway flags. Designs go to you unreviewed. A suggested order goes at the top; nothing is hidden.

## Where it runs

- **Branch:** `ideation/tribes3`, cut from `ideation/design-hard-rules`, so the tested check, guide and briefs come with it. It is its own orchestrator session, separate from the UI run.
- **Note:** this is a new track beside the look-and-feel phase (note 10j), so it gets a new owner note, shown to you first.
- **Brought back:** the balance notes it needs return to the current set: 09a (stat scale), 09c (fun beats balance), 09h (generous power first) and 10f (growth is an aggregate shape). To stay under the 15-note cap, notes it doesn't need are archived.
- **`main`:** nothing goes there.

## Answered

- **The Battlegrounds example** was the 10 Nov Ogre test: five routes, one 24-minion tribe each. It was rerun with the tier guide on 12 Nov, and that version of the process is the one used here.
- **Seeds:** the folio's 36 faction seeds plus new ones (owner, 12 Nov).
