# Tribe run with a committee: brief for the orchestrator (14 Nov 2026)

You are the orchestrator, running as **Fable 5.2**. You plan, start agents, check their files and keep the run moving. Every agent you start is **Claude Opus**. You write no designs or reviews yourself.

## The owner's words

14 Nov, starting this run:
> "I want to do a big orchestration because today's my last day before my token reset and I've got 28% budget left. So I want heaps of designs, reviews, etc., using Claude, and some sort of committee to kind of give them [ratings]. I don't want bad ones removed, but I do want to be able to see the version history for all the designs in some sort of portal. That portal needs to be built. The data structure should be kept. Whatever data structure we record all the designs and the changes to them needs to be thought of beforehand. But I want to be able to see how the design's changed and why in short descriptions per card or whatever. And I want reviews and ratings for the best designs and when they stop iterating at a certain point when their design feels in a good spot. I don't want them like to go through more than like one or two iterations, right? They can stop at one if they feel it's in a good spot, two at most. And I want like ratings for them so that I can kind of see what the agents think is good. ... I want a good variety of species and tribes. I want a good variety of methods, like bottom up, different, processes to get there, that kind of thing. ... I want the brief to have a Fable orchestrator who is instructed strictly to use Opus subagents."

11 and 12 Nov, on the run itself:
> "give a bunch of agents species and, or like tribe, like ideas, seeded ideas ... 10 to 15 prototype tribe designs ... 2 or 3 options for each tribe with a different design method ... 2 tier 1 units, 3 tier 2 units, 4 tier 3s, 4 tier 4s, and 3 tier 5s, and 3 tier 6s." "I want to get scaling and power budgeting in ... focus on, like, number growth."
> On the Ogre test designs: "They're more creative. They feel more powerful. I can balance them afterwards."
> "I want more unreviewed stuff coming to me, because those designs slapped ... we're way too worried about balance."

These outrank everything else here. Where this brief proposes something the owner didn't say, it's marked **(proposal)**. Keep it unless it plainly fails; if you change one, say so in the report.

## The model rule (strict)

- **Every subagent is Opus.** On every Agent tool call, pass `model: "opus"`. On every workflow `agent()` call, pass `{model: 'opus'}`. Never leave it out: an agent with no model set inherits yours, which is Fable.
- That includes the scope reviewer and any helper or checker. Tell every agent in its prompt: "Don't start subagents or workflows."
- No Sonnet, Haiku or Fable subagents, and no Codex workers.
- **Check it.** After the first designs, and before the final report, run `python3 tools/tribe-run/usage.py --session-dir ~/.claude/projects/<this project's folder>/<your session id>`. It exits non-zero on zero calls (wrong folder) or on any model other than `claude-opus-5-5` (your agents) and `claude-fable-5-2` (you), and names the file. If that happens, find the call, fix it and say so in the report.

Effort per role **(proposal)**:

| Role | Effort |
|---|---|
| Seed scout, Part B writer, designers, revisers, rankers, portal builder | high |
| Committee members | medium |
| Extractor (v1 Markdown to JSON) | low |

Designers stay at high because that's what the Ogre test used.

## Setup

- Create a worktree at `~/code/Bramble-ideation-tribe-run` on a new branch `ideation/tribe-run`, cut from `origin/ideation/design-hard-rules`. Work and commit only there, and push that branch.
- Don't touch `~/code/Bramble-ideation`, `ideation/main` or any other branch or worktree; other sessions own them. Never merge, push or open a PR into `main`.
- This is a content track beside the look-and-feel phase, on the owner's words above. Don't write an owner note for it.
- The Godot test gate doesn't apply, because nothing here touches game code.

## Read first

1. `docs/design/tribe-run/data-format.md`: the data format. **Every agent except the designers reads it**; designers use the tested prompt and read only their seed's brief. The portal reads nothing else. `tools/tribe-run/validate.py` checks the files, and `tools/tribe-run/decide.py` works out each design's next step from them.
2. `docs/design/tribe-run/designer-prompt.md`: the designer prompt and the route blocks. Use the wording as written.
3. `docs/design/tier-guide.md`: goes into every designer brief unchanged, as Part C.
4. `docs/design/tier-guide-test/README.md`: why this process. Don't show the Ogre designs to anyone; designers copy examples.
5. `docs/design/owner-notes/2026-11-12a-tier-guide-designs-and-less-review.md`.

## What gets made

**15 seeds × 3 routes = 45 tribes**, each with 19 units in the shape above **(proposal; the owner asked for 10–15 seeds with 2–3 methods each)**. Every version of every design is kept, and nothing is removed or hidden.

**Seeds.** One Opus scout reads the 36 faction seeds in `docs/folio/woodland-folio.html` and proposes about 20, folio and new, each with a one-line pitch of the play it suggests. You pick 15.
- **Different play, not just different animals:** different growth shapes (tall, wide, economy, death, spells, position, shop, combat triggers and so on).
- **Different species:** at most two seeds from the same broad kind (mammal folk, birds, insects, fungi and plants, fae, oozes, water folk, and so on).
- **A few that aren't in the folio,** at least 3.

Write the `seeds/<seed>.json` files and each seed's `BRIEF.md`:
- **Part A:** the seed, the same length and kind as the Ogre brief's lore section.
- **Part B:** how Bramble plays, written once from `docs/design/rulebook.md`, short and neutral, shared by every seed.
- **Part C:** the tier guide, with the intro line from `designer-prompt.md`.

**Routes.** Each seed gets 3 different routes. Spread them so the run covers every route.

| Route | Source | Uses, out of 45 |
|---|---|---|
| Bottom-up mechanical | tested | ~8 |
| Surgical | tested | ~8 |
| Top-down flavour | tested | ~8 |
| Top-down mechanical | tested | ~5 |
| Bottom-up flavour | tested | ~4 |
| Player story | new | ~4 |
| One constraint | new | ~4 |
| Borrow and twist | new | ~4 |

The tested blocks are in `designer-prompt.md`. Bottom-up flavour's block is in `docs/design/tier-guide-test/prompts/new-Q.txt`. The three new ones are untested **(proposal)**:

- **Player story:** "**Your route: player-story first.** Before any card, write three short moments a player would tell a friend about after a game with this tribe: one in the shop, one in a fight, one about how the board grew across the game. Then design the cards that make those moments happen, and keep testing each card against them: which moment does it build towards? Let the shared mechanic come from what the moments have in common. Names and lore come last."
- **One constraint:** "**Your route: one hard constraint.** Pick one rule the whole tribe lives under, and make it strong enough to change how you play: for example a limit on board size, stats that only ever move between your units, or buffs that only last if something happens. Design every card inside it. The constraint should create decisions, not just limit them; the tribe's power comes from playing well inside it. Names and lore come last."
- **Borrow and twist:** "**Your route: borrow and twist.** Take one mechanic from outside auto-battlers (a deckbuilder, a board game, a roguelike, an MMO class, a sport) and make it work in Bramble's shop-and-fight loop. Say in one line where it comes from. Change it until it fits the woodland and the tier guide, then build the tribe around it. Names and lore come last."

## The loop for each design

Stopping rule **(proposal: the owner's "one or two iterations, two at most", read as one revision always and a second only if needed)**: `min_versions` is 2 and `max_versions` is 3 in `run.json`. To let a v1 settle with no revision, set `min_versions` to 1.

1. **Design (v1).** One fresh Opus designer, with the prompt in `designer-prompt.md` as written. Fill its slots with full paths:
   - `<path>/BRIEF.md` becomes `…/docs/design/tribe-run/run/seeds/<seed>.BRIEF.md`;
   - `<path>/<letter>.md` becomes `…/docs/design/tribe-run/run/designs/<seed>--<route>/v1.md`.
2. **Extract.** An Opus extractor turns `v1.md` into `v1.json` and fills `design.json`.
   - It copies text exactly, assigns `u01`–`u19` in tier order and changes no design content.
   - It runs `validate.py` and fixes its own errors; the validator checks the copy word for word against `v1.md`. A shape warning is fine.
3. **Committee review.** Three fresh Opus members review the version at once, each through one lens. Each reads only the seed's `BRIEF.md`, `data-format.md` (the review format) and that version's JSON: no other versions, reviews or designs.
4. **Decide.** Run `tools/tribe-run/decide.py run --write`. It records each version's votes and mean ratings in `design.json`, and prints each design's next step:
   - The version has reached `max_versions`: the design is **capped**.
   - The version has reached `min_versions` and at least 2 of 3 members vote `settle`: the design is **settled**.
   - Otherwise it gets revised.
5. **Revise (v2, v3).** One fresh Opus reviser reads the brief, the previous version's JSON and its three reviews. It writes `v<n>.json` directly, with `changes` and `declined` filled. Then it runs `validate.py` until the file passes. Its instructions:
   > "Keep what makes this tribe this tribe: its core mechanic, its best cards, its boldness. The owner prefers designs that are creative and run hot, and does the balancing later, so don't tone a card down just because it is strong. Change a card for being broken (a loop with no counterplay, one choice that is always right) or unclear. Ideas you like are welcome too. Answer every point marked fix: apply it, or decline it in one line. Ideas are optional. Every changed card gets a short what and a short why. Keep card ids; new cards take new numbers. Keep the 19-unit shape unless a review asks you to fix it."
6. Go back to step 3 with the new version.

**Committee (proposal).** Each member gives both ratings, from 1 to 10 in whole numbers, through its own lens:

| Member | Lens |
|---|---|
| `combo`, the combo player | Interwoven synergies, uses outside a card's intended purpose, real decisions each turn. This is the owner's "Johnny". |
| `climber`, the ranked climber | Does each tier do its job in the tier guide? Does the number growth have a shape you'd want to play? Flag runaway loops as `broken` or `watch`, and don't mark power down just because it runs hot. |
| `reader`, the reader | Can a player who knows Bramble read each card at a glance? Does the woodland folk fantasy come through in what the cards do? |

The two ratings are **Fun to draft and grow** and **Distinctive**, from the run plan's deciding criterion plus distinctiveness, which the owner valued in the Ogre test. Each member gives at most 5 points, up to 3 standout and 3 weakest cards, flags, and a verdict. A point is a `fix` only when something is broken or unclear; anything else, including "this would be more fun if", is an `idea`. This keeps the hot, creative v1s the owner liked from being sanded down.
- **Verdict:** `settle` when more iterating would likely make the design only different, not better. `iterate` when there's a real fix to make.
- **Reviewers never remove or hide a design.** A low rating is information for the owner.

**Rankings.** When all three designs of a seed have stopped, one Opus ranker reads their final versions and their v1s. It writes `rankings/seed--<seed>.json`: the order, a line each, and whether iterating beat v1. At the end, one Opus chair reads every `design.json` and the seed rankings, and writes `rankings/overall.json` with up to 12 picks. A pick names a version, and can be a v1.

## The portal

A private claude.ai artifact the owner can open on a phone **(proposal: it's separate from the LAN portal, which other sessions own)**. One Opus builder makes it first, against `data-format.md` and a small sample run, while the designers work.
- **First publish:** publish it once at the start, with sample data, while the owner is present, in case publishing asks for approval. Store the link in `run.json` as `portal_url`. Always republish the same file path, so the link never changes; a resumed session publishes with `url` set to `portal_url`.

- **Build.** `tools/tribe-run/bundle.py` reads `run/` and writes `portal/index.html` from `portal/template.html`, with all the data embedded, so publishing is one file. It must stay under 16 MB. The builder loads the `artifact-design` skill before writing the page.
- **Home.** A sentence or two framing the run in plain speech, then every design as a row or card. Each shows the tribe name, the seed, the method, the status ("settled at v2", "capped at v3", "being revised"), and the two ratings at each version. Filter by seed, method and status; sort by rating; the overall picks sit at the top. A "hide the method" switch lets the owner read blind.
- **Design.** Opens with v1 beside the final version (one column on a phone, with a switch), then a switch for any version. Each version shows the identity, the 19 cards by tier with full text and golden text, the builds, the risks, the tier check and the shape. A link opens the designer's own `v1.md` text.
  - Click a card to see its story across versions: what changed and why at each step, and which review point asked for it.
  - Each version's reviews show the three members' ratings, verdicts, points and flags. For each point, show what the reviser did with it (applied, with what; or declined, with why).
  - Cards with standout picks or flags are marked.
- **Seed.** Filtering by seed shows that seed's three designs together, with the ranker's order and lines.
- **Wording.** Follow `docs/portal/WORDING.md` (on `portal/main`; read it with `git show`): frame first, talk like a person, no process talk on the first two tiers.
- **Gate.** This is a code step, so it gets two checks:
  - **Runtime:** the bundle builds from real run data and the page renders at phone and desktop width. The artifact preview counts.
  - **One scope review:** the `scope-reviewer` agent, with `model: "opus"`, on the commit range of `tools/tribe-run/` and `portal/`. Its brief is the owner's words above plus this section.
  Fix any cut items. List ask items in the final report. Design content gets no gate beyond the committee.

## Running it

**Order: every v1 first, then the committee** (so if usage runs out, the owner still has all 45 designs). Don't wait for the owner between phases: the owner watches the portal and can interrupt.

1. **Seeds, briefs and the portal.** Then a checkpoint: 3 designs made, extracted and validated before fanning out.
2. **All 45 v1s, plus extraction.** Then publish.
3. **Committee rounds.** Each round: review every version that `decide.py` says needs it, run `decide.py --write`, revise the designs it says to revise, then publish. Two or three rounds cover the whole run.
4. **Rankings,** the final publish and the report.

- **Workflows.** Use them (the owner asked for a big orchestration): one workflow per phase or round. A workflow script can't read files, so run `decide.py` between workflows and pass its list in as `args`. On this 6-CPU machine a workflow runs at most 4 agents at once. If you need more, run a second workflow alongside, or use background Agent calls. Aim for 10–12 agents working at once.
- **State lives on disk.** `decide.py` reads only the files, so after a usage-limit stop, rerun it and carry on. A workflow agent that returns nothing (often a usage limit) leaves its step to run again; that's not a failure. Don't hold back to save usage: the owner wants it spent today. If a `get_usage` tool is available, check it between rounds.
- **After each phase or round:** run `validate.py` on everything, bundle, publish the portal, then commit and push `ideation/tribe-run`.
- **A design fails** only when its agent finished but the file is still invalid after one redo. Set `status` to `failed` with a `stop_reason`, and move on.

## Report to the owner

Use plain words, following `WORDING.md`:
- the portal link and what's in it;
- how many designs settled at v2, capped at v3 or failed;
- the overall picks, a line each;
- every `broken` flag;
- whether iterating tended to beat v1;
- tokens and API-equivalent cost by model, from `usage.py`;
- any breach of the model rule and how you fixed it;
- any proposal above you changed.

## Not in scope

Game code, art, changes to today's tribes, cutting or hiding designs, owner notes, and anything on `main`.
