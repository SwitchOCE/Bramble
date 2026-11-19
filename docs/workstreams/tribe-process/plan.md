# A repeatable process for new tribes: investigation and plan (19 Nov 2026)

Written by an Opus session for the owner, from the code and docs on `dev` (54c9351d) and the league data on the Optiplex. The first draft went to a plan interrogation ([plan-interrogation.md](plan-interrogation.md)) and then to the owner. **This version carries the owner's answers** (section 2, quoted). One choice is still open, and one reading of mine needs the owner's check (section 8). Nothing has been built.

## 1. The owner's words

The request (19 Nov 2026, dictated):

> I want to be able to run more tribe designs and have them go through the same kind of processes in terms of balance and adjustment: the tribe goes into a bot, the bots are refined to adjust [to] the new tribe, we check the balance, we do a redesign if it's not up to balance standards. It has to be decent. I'm okay with the tribe not being the best. I'm okay with it having many weaknesses. But if we're in a five-tribe lobby and one tribe's being played under five percent of the time by a bot that's operating near equilibrium at a high skill level, I would say that that's a big balance problem and needs to be resolved, and is something that agents need to iterate on, because it's not a design that's fit for purpose yet.

> Pretty much any individual card within a tier, the worst card in a tier should be used at least a third as much as the most used card. It's okay for there to be a best card that's very popular, but it's not okay for there to be parts that aren't being used, aren't powerful enough.

> I want essentially to set up a process that we can give a prompt for a tribe, three or four different variations of that tribe come out designed by different agents. The agents try and refine their tribe. A reviewer looks at all of the tribe designs and highlights which ones it thinks are best. That goes through the balance test process. If the best design doesn't work, you go to option two.

## 2. The owner's answers on the first draft (19 Nov 2026, dictated, lightly cleaned)

**On the bots and equilibrium:**

> The bots are not yet at equilibrium. They over-adapted to the stronger tribes, and as a result, they only followed into the weaker tribes when they got an extremely lucky angle where they were well set up to take advantage of it, because they over-preference slightly the better tribes. It's not going to be perfect. Play share is probably a better metric. Neither win rate nor play share are in of themselves a good enough metric to measure equilibrium. Additionally, bots are never going to be able to reach perfect equilibrium unless we devote too much of the project to it. At that point, we'd be creating some sort of generalized strategy game engine … far more ambitious than developing the game. The point of this stuff is to sense check it and get it close[r] than it would otherwise be without it. Mice boards would fall radically. Both teams tested trying more Mice after they saw the win rates, and both saw win rates go down. Mice are weaker than the others; it's just that they picked it when they had a very good spot for it.

*[Editor note: this corrects the first draft, which read Mouse's 3.48 average place on 15% of boards as the bots under-playing Mice. The owner's reading: the bots picked Mice only from strong positions, which flatters Mouse boards.]*

**On what counts as "used" (Standard B):**

> Final board is definitely not a good measurement. Some entire units' purpose is to exist to be replaced, to give you time to find better long-term units. … There are some cards that we may design that only do something when you buy them or sell them. … A card being used at some point in the game, or when offered, it is taken, like purchased or picked, X percentage. We measure that, we look at the best, most picked cards versus the worst, least picked cards.

> Let's say that there's 10 or 12 T4 cards … If the most played one has like a 20% pick rate, or maybe it's lower, maybe it's 17, the least played one should have at least six. Elsewise, it's probably too weak and it just needs a buff. Or it needs to be redesigned or removed and replaced with something else. … The comparison is just compared to other tier 4 units of all tribes. That's the comparison pool.

**On what counts as a tribe being "played" (Standard A):**

> Honestly, a tribe is just the aggregate of its cards. I don't really care what strategies exist and how they mix units between tribes. I just want the game to be interesting. I don't care if your final board is seven Badgers or one Badger, two Briars, one Mouse, two Pigeons … What counts as a tribe being played? I don't really think that necessarily matters so much as the cards in the tribe. The tribe is basically what's included in the lobby, and the cards need to be good. … Most of the cards should be useful. We put cards in the game so that they're used by players, not so that they ignore them every time because they're so useless or underpowered.

**On building, rounds, the page and lobbies:**

> Doesn't need to be built in-game. It can be built just in the Rust engine for testing. If it passes all the checks in the Rust engine, then it can go into the game.

> Yeah, let's do three. Three sounds reasonable.

> Artifact page is good. Very happy with that.

> Lobbies need to pick five tribes at random. The tested tribe can be picked four ways *[probably "is always picked"]*, and the other four can be picked at random. As the pool increases, that will change things. And we need to evolve our bots and our other practices to deal with that.

**On today's tribes:**

> Today's tribes do fail the standards, but they fail the standards as of the last data check, and they're currently being improved as a result of the process. … You can have a go at applying these standards to today's tribes, but we're already in the process of rectifying.

**On the bots not seeing a sixth tribe:** "That was always intended to be something that was developed as a result of this."

**On the plan interrogation:** "Agree with the cross-examining agent so far." On proving the check script flags Badger and Briar: "That's so obvious, I don't even think we need to test it."

## 3. What one new tribe costs today (Pigeon and Mouse reworks as the worked example)

All times are wall-clock times from the commits on `dev`, 19 Nov 2026. Token use for each step isn't recorded anywhere I could read.

| Stage | What it involved | Time observed | Who | Evidence |
|---|---|---|---|---|
| Design to approval | One designer's pitch per tribe, costed by hand with the `bramble-design` method. One page for the owner with 10 questions, one round of review | about 2.5 h, from the direction committed (11:47) to the picks approved (14:15) | designer agents (number unknown), the owner | db8aab20, 6a62eaa4, `docs/workstreams/reworks/pitch-*.txt` |
| New core rules the tribe needs | Renown and the Reserve limit (S3); Active display (S1). S3 changed every state hash | 14:15 to 15:22, in parallel | Claude, scope reviews | #172–#174 |
| The tribe's own mechanics and cards | Pile on N and Hand-me-down (S6); 19 Mouse units and the Cousin (S7), with 7 test files rewritten | 15:21 to 16:22 | Claude (S6); Codex wrote S7, Claude fixed the review findings | #175, #176 |
| Rust port and proof | A line-by-line mirror ("'Close' is a failure", `tools/league/PORTING.md`); `refresh_reference.sh`; `recheck.sh` (about 8 min); the 200-game bot smoke test | under way for the reworks. Earlier ports took 1–1.5 h with Codex (#164; `engine/badgers-port`) | Codex, run by the ghost orchestrator | |
| Bots | TribeBot text matches and Reserve holding (S8) | not done. The league bots still name cut cards, and stock 3 cards in hand where the limit is now 2 | | `tools/league/bots/blue/src/cards.rs` |
| Art | 12 new cards on the stand-in panel (`tools/art/waiting.txt`) | deferred until the cards survive a measurement | | |

**For a brand-new tribe:**
- **The bots can't see it.** Red, blue, TribeBot and the harness each hard-code five tribe names (14 places in `tools/league`). Fixing this was always meant to come out of this work (owner, section 2).
- **The harness doesn't pick lobby tribes.** Both engines can already pick a subset of tribes for a lobby (`lobby_tribes`), but the league harness always loads all five.
- **The art test needs a fix.** `tests/glass/test_unit_art.gd:72` asserts "five tribes ship". This only matters once a tribe goes into the game, after it has passed.

## 4. How the bots are built, and what each needs for a new tribe

| Bot | How it values cards | Hard-coded tribe and card knowledge | What a new tribe needs |
|---|---|---|---|
| **red** | Stats plus a `power` column (`data/cards.tsv`). An agent wrote the first values from the card text; they were refit by self-play regression and from practice games | `TRIBES: [&str; 5]`; named cards in `tactics.rs`; special play only for Briar, Locust and Pigeon | A table row per new card (an agent reads the text); a refit pass ("about 2 hours of CPU"); special play for any mechanic it can't use by default |
| **blue** | Mostly `−100 × lift`, measured in self-play | `TRIBES: [&str; 5]`, `tribe_pref: [f64; 5]` (a tuned Badger −6, Locust +6 lean); rules for named cards | `rebuild_lift.sh` (3 steps of 1,000 games; "a new card starts at 0 and is measured like the others"); special play as for red |
| TribeBot | SimpleBot locked to one tribe; it places units by card text | `TRIBES: [&str; 5]` | The tribe added to its list |
| SimpleBot, FlowBot, RandomBot | Tier and stats | none | nothing, but they are naive |

The bots run only on the Rust engine, so a tribe needs to exist there before they can play it. The refit loops are scripts. Reading new cards and writing special play is work for an agent session.

### The equilibrium sense check

The owner's bar is a sense check that gets the bots closer than they would be without it, not a proof (section 2). Play share counts for more than win rate, and neither is enough alone. Two checks, as the plan interrogation advised:

- **E1. A forced-tribe probe** for any tribe whose cards fail. Push 4 seats hard into that tribe (red's `tribe_lean`, blue's `pref_*`) against 4 normal seats. If the pushed seats place worse, the weakness is real. This is what both teams did by hand with Mice in the league, and their win rates went down. If the pushed seats place better, the bots are missing something: fix the bots before redesigning the cards. It needs registry entries such as `red-lean-<tribe>`, because `league match` takes bare bot names only.
- **E3. The two bots agree.** Red and blue were built separately. Compare their pick rates and tribe shares (`agree.py`, `tribes.py` by colour). Where they agree, the reading is more likely real. It needs nothing new.

E2 (one more refit step gains nothing) is deferred until E1 and E3 disagree.

## 5. The two standards: measures

### Standard B, the main measure: every card earns its place

- **"Used":** the **pick rate when offered**: of the shops that showed a buyable copy, and the Discover choices that offered the card, the share in which it was bought or picked. Final boards are not used (owner, section 2). `cards.py` computes the shop part today; adding the Discover picks is a small change.
- **The comparison pool:** **all tribes' cards of the same tier** in the test (owner: "compared to other tier 4 units of all tribes").
- **The line:** the least-picked card's rate is at least a third of the most-picked card's (owner's example: top 17–20%, so the worst must be at least about 6%).
- **A card under the line** gets, in the owner's words, a buff, a redesign, or removal and replacement. The `bramble-design` method picks among them: numbers, tier, replace or rework; the support checked first; no double-tap.
- **Not counted:** tokens, and Discover-only cards. Spells are left out until the owner says otherwise.
- **Sample size:** to tell a third apart at top rates around 20%, each card needs about 1,000 shops where it was offered. A 1,000-game match gives tiers 1–3 many times that (23,000–57,000 shops per card on arm-b) and tier 4 about 4,900. Tier 5 gets about 1,800 and tier 6 about 650, so it needs about 2,000 games (about 1.5 h on the Optiplex). Under 1,000 offers, the check says "not enough data", not pass or fail.

### Standard A: the 5% floor

**My reading, for the owner to check.** The owner: "a tribe is just the aggregate of its cards". So a tribe counts as "played" by **its cards' share of all units bought and picked, in lobbies that include it**. The final board's main tribe is not used.

- **The line:** under 5% fails if the upper end of the 95% interval is under 5%. A tribe's cards are about 20% of a five-tribe shop, so a 5% share means players take its cards about a quarter as often as an average tribe's.
- **Sample size:** 1,000 games (500 seed pairs) gives about ±0.4 points near 5%.
- **The bar:** it counts against a design only after the sense check in section 4.

Standard B already compares every tribe's cards in one pool, so a tribe failing A will usually fail B too. A stays as the owner's stated floor.

### Lobbies

- **Five tribes per lobby, at random.** The tested tribe is in every lobby; the other four are drawn at random from the rest (owner, section 2, with my reading of "four ways").
- **Fair comparison:** today's five tribes plus one candidate makes six, so each test lobby leaves one of today's tribes out. Seeds rotate through the five possible leave-outs equally.
- **As the roster grows,** the bots and these practices change with it (owner).

## 6. Where today's five tribes stand

**The data:** arm-b, `/data/measure/arm-b/bots` on the Optiplex, 19 Nov 16:10. red-m2 against blue-m2, free choice of tribe, no shared pool, 1,000 games. Pass One for Pigeon and Locust is in. **The Badger part of Pass One and all the Pigeon and Mouse reworks are not.** The rework and balance work now under way is meant to fix what this shows (owner, section 2).

**Standard B (shop buy rate when buyable, all tribes' cards in the tier; Discover picks not yet included):** worst ÷ best is below a third in every tier.

| Tier | Most bought | Worst ÷ best |
|---|---|---|
| 1 | Sentry, 38% | 0.004 |
| 2 | Blackthorn Sapling, 38% | 0.001 |
| 3 | Needle Pikeman, 92% | 0.000 |
| 4 | Orchard Stripper, 78% | 0.001 |
| 5 | Elder Mother, 20% | 0.045 |
| 6 | Regimental Sergeant Major, 21% | 0.141 |

- 69 of 95 units are under a third of their tier's top.
- Passing, by tier:
  - **1:** Sentry, Husk Sentry, Green Recruit, Needle Page;
  - **2:** Blackthorn Sapling, Lance Corporal, Wheat Raider, Prophet of the Dust;
  - **3:** Needle Pikeman, Skin-shedder, Gleaner;
  - **4:** Orchard Stripper alone;
  - **5:** Elder Mother, Eighth Plague, Tourney Champion;
  - **6:** all but Marshal of the Red Mist, Kettle Drummer, Dame Bodkin and The Oakfeller.
- At tiers 3 and 4, one card (Needle Pikeman, Orchard Stripper) is bought so often that it sets the line out of reach. That is the "best card that's very popular" the owner allows. Whether it makes the line too hard there is for the owner to judge.
- Local copies of the data and the script that worked these out are in the planning session's scratchpad. They aren't kept.

**Standard A:** not yet worked out under the "share of cards bought" reading. On final main tribe, the measure now set aside, Badger was 0.1% and Briar 4.0%.

**The run that answers both on current `dev`:**
1. The reworks ported to Rust.
2. The bots updated for the cut and new cards.
3. One 2,000-game match, analysed with the check script.

The balance orchestrator's own sign-off measurement can serve, if the check script is run on it (plan interrogation).

## 7. The process

Times are estimates unless marked "observed".

### Before the first tribe, once

| Piece | Input | Output | Who | Cost |
|---|---|---|---|---|
| P1. Bots see any tribe | the card library | red, blue and TribeBot read the tribe list from the library; blue's preferences resize to fit | Codex, scope review, Rust proof and bot smoke test | about 2 h |
| P2. Lobby tribes in the harness | — | `league match --lobby-tribes` with a fixed tribe and four drawn at random, rotating the leave-outs | Codex | about 1 h |
| P4. Probe bots in the registry | P1 | `red-lean-<tribe>`, `blue-lean-<tribe>` runnable by `league match` | Codex | about 1 h |
| P5. The check script | a match folder | Standard B per tier, Standard A per tribe, E1 and E3, verdicts (pass / fail / not enough data) and the list of cards under the line | Codex | about 2 h |

P1 and P4 should land before the third run's teams take over the bot code. The art-test fix (P3 in the first draft) waits until a tribe goes into the game. The wrapper script (see below) waits until the second tribe.

### For each new tribe

| Stage | Input | Output | Who | Cost |
|---|---|---|---|---|
| **1. Tribe prompt** | the owner's idea: a species seed, theme or mechanic | `docs/tribes/<name>/prompt.md`, quoting the owner, plus the fixed constraints: tier shape, tier guide, guardrails, shared keywords | the owner; the orchestrator writes the brief | minutes of the owner's time |
| **2. Designs and refinement** | the prompt and the `bramble-design` reading list | 3–4 full tribes of about 19 units, each with full card text, a rough power number for every utility effect, a tier check, the new core rules it needs, and a note on how a bot would have to play it. Each designer then refines its own once, with rough fight checks kept small, as the skill says | 3–4 agents in parallel, Opus and Codex mixed so the designs really differ (Opus only on the Claude side) | about 1.5–2 h in parallel |
| **3. Reviewer's ranking** | the designs, the prompt, the tier guide, the latest card pick rates | a ranking with reasons: fit to the prompt, distinctness, fragility, build cost (new core rules), how much special bot play it needs | one fresh agent that wrote no design | about 1 h |
| **3b. The owner's page** | the ranking | an artifact page with each design's example cards and the ranking (owner: "Artifact page is good") | the orchestrator builds it; the owner reads it | one review round (about 2.5 h on 19 Nov, observed) |
| **4. Build in Rust only** | the chosen design | the tribe as a content folder in `bramble-engine` on a candidate branch, with Rust tests | Codex, Claude review | about 1–2 h; more if it needs new core rules |
| **5. Bots learn it** | the candidate engine | red's card rows and a refit pass, blue's lift rebuild, special play where a mechanic needs it | a bot-coach agent session, using the refit scripts | about 4–6 h, mostly CPU; the session 2–4 h |
| **6. Balance test** | the bots | a 2,000-game match with the tested tribe in every lobby, E1 for any tribe with failing cards, and the check script's verdict | the orchestrator runs the commands | about 2–3 h of CPU; can run overnight |
| **7. Redesign** | the failing cards, what the bots prefer, the design | a change per failing card: buff, redesign, or replace | the design's own designer, or a balance agent | about 2–3 h a round in Rust only (change, refit step, retest) |
| **8. Option two** | 3 failed rounds (owner: "let's do three") | stage 4 with the reviewer's next design | the orchestrator | as from stage 4 |
| **9. Into the game** | a tribe that passed | the GDScript tribe, tests, cross tests, the art test fixed, art stand-ins; then the usual Rust proof, which checks that the game and the Rust candidate match hash for hash | Codex, Claude review, scope review | about 2–3 h; art after the owner plays it |

**What Rust-only testing changes.** Today `PORTING.md` makes the GDScript game the truth and Rust the copy ("Never change anything in `src/`"; "where the port and it differ, the port is wrong"). A candidate tribe reverses that until it passes, so the Rust engine needs one written exception:
- a candidate tribe lives only on a candidate branch of the Rust engine, and never merges to `dev` in Rust before its game version exists;
- once the game version is written (stage 9), the proof runs as usual, and any difference is fixed on the game side or the Rust side, whichever misread the design.

This saves the GDScript build, the screens and the tests for every design that fails. That is the costliest part of a failed attempt.

**About a day per design tested:** stages 2–3 in an afternoon, stages 4–6 in most of a day, much of it CPU that can run overnight (the `overnight-run` skill). The Optiplex is shared, so check its load first, as the league brief says.

**The wrapper script, deferred.** The balance test in stage 6 is about four commands in order:
1. the match;
2. the forced-tribe probes;
3. the analysis;
4. the check script.

The wrapper is one script that runs them all, so an agent can't skip or misorder a step. For the first tribe, the orchestrator runs the four by hand. The first tribe will show which steps the test really needs, and then they get wrapped.

### What becomes a skill, a script or a check, and what stays with the owner

- **A skill, `tribe-pipeline`:** the stages above, the designers' brief, the reviewer's checklist, the redesign rule and the move to option two. Drafted before the first tribe, finished from what it actually did. `bramble-design` gets two short sections: "designing a tribe to a prompt" and "ranking tribe designs".
- **Scripts and checks:** P1, P2, P4, P5; the Rust-only exception written into `PORTING.md`; the wrapper after the second tribe.
- **Stays with the owner:** the prompt, the ranking page, accepting a tribe that passed (by playing it in the game), and what happens when all options fail.

## 8. Still open

1. **Does the owner see the ranking before anything is built** (stage 3b)? The owner liked the artifact page but didn't say whether building waits for it. Recommendation: yes. It costs one stop and saves about a day on a design the owner would reject.
2. **For the owner to check: Standard A as the share of the tribe's cards bought and picked** (my reading of "a tribe is just the aggregate of its cards", section 5).

Agreed with the plan interrogation and taken: E2 deferred; the baseline taken from the balance pass's own measurement; no new third-run rule; the art-test fix moved to stage 9; the wrapper deferred; one version per designer, not two.

## 9. Is the problem fixed?

**The owner's problem:** a process that turns a prompt into a tribe whose cards all earn their place. It exists once P1, P2, P4 and P5 are done and the first new tribe has gone through stages 1–8. Stages 1–3 are documents only and can start now, alongside the third run. Stages 4–6 need the Rust engine level with `dev`. The ghost orchestrator is doing that now.
