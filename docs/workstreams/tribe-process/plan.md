# A repeatable process for new tribes: investigation and proposed plan (draft, 19 Nov 2026)

Written by an Opus session for the owner, from the code and docs on `dev` (54c9351d) and the league data on the Optiplex. Nothing here is decided and nothing has been built. Each choice the owner needs to make is listed with options and a recommendation, in section 7.

## The owner's words (19 Nov 2026, dictated)

> I want to be able to run more tribe designs and have them go through the same kind of processes in terms of balance and adjustment: the tribe goes into a bot, the bots are refined to adjust [to] the new tribe, we check the balance, we do a redesign if it's not up to balance standards. It has to be decent. I'm okay with the tribe not being the best. I'm okay with it having many weaknesses. But if we're in a five-tribe lobby and one tribe's being played under five percent of the time by a bot that's operating near equilibrium at a high skill level, I would say that that's a big balance problem and needs to be resolved, and is something that agents need to iterate on, because it's not a design that's fit for purpose yet.

> Pretty much any individual card within a tier, the worst card in a tier should be used at least a third as much as the most used card. It's okay for there to be a best card that's very popular, but it's not okay for there to be parts that aren't being used, aren't powerful enough.

> I want essentially to set up a process that we can give a prompt for a tribe, three or four different variations of that tribe come out designed by different agents. The agents try and refine their tribe. A reviewer looks at all of the tribe designs and highlights which ones it thinks are best. That goes through the balance test process. If the best design doesn't work, you go to option two.

## 1. Summary

- **What a tribe costs today.** Using the Pigeon and Mouse reworks: design to the owner's approval took about 2.5 hours, and the Mouse game code about 1 hour. Most of the cost comes after that, and none of it is done for either rework: the Rust port, the bots and the measurement. A new tribe would cost about one day of wall-clock time per design tested, most of it machine time that can run overnight.
- **The bots can't see a sixth tribe.** Both strong league bots, TribeBot and the harness list exactly five tribe names in their code. A sixth tribe would never become their main tribe. Its share would be 0% because the bots can't see it, not because of its balance. Fixing that is a one-time change.
- **Today's five tribes fail both standards.** On the latest league data (arm-b, 19 Nov, before the reworks), Badger is the main tribe of 0.1% of final boards and Briar of 4.0%. In every tier, most cards are bought less than a third as often as the tier's best.
- **The bots aren't near equilibrium yet, and the data shows it.** Mouse boards placed best (3.48 average) but only 15% of seats played Mouse. At an equilibrium, a tribe that places best would be picked more. So under the owner's own wording, the 5% standard can't be applied yet, to old tribes or new ones.
- **Recommended order:** first build the one-time pieces (bots that read the tribe list, a lobby rotation, a check script). Then measure today's five tribes as the baseline once the reworks are ported. Only then run the first new tribe through the process.

## 2. What one new tribe costs today (Pigeon and Mouse reworks as the worked example)

All times are wall-clock times from the commits on `dev`, 19 Nov 2026. Token use for each step isn't recorded anywhere I could read.

| Stage | What it involved | Time observed | Who | Evidence |
|---|---|---|---|---|
| Design to approval | One designer's pitch per tribe, costed by hand with the `bramble-design` method ("about ten small scenarios each … No engine fights were run"). One page for the owner with 10 questions, one round of review | about 2.5 h, from the direction committed (11:47) to the picks approved (14:15) | designer agents (number unknown), the owner | db8aab20, 6a62eaa4, `docs/workstreams/reworks/pitch-*.txt` |
| Build plan and its check | A planner, then a fresh plan-interrogate agent | written before the approval commit | 2 agents | `docs/workstreams/reworks/build-plan.md`, `plan-interrogation.txt` |
| New core rules the tribe needs | Renown and the Reserve limit (S3); Active display (S1). S3 changed every state hash | S0 to S3 took 14:15 to 15:22, in parallel | Claude, scope reviews | #172–#174 |
| The tribe's own mechanics and cards | Pile on N and Hand-me-down (S6); 19 Mouse units and the Cousin (S7), with 7 test files rewritten | 15:21 to 16:22 | Claude (S6); Codex wrote S7, Claude fixed the review findings | #175, #176 |
| Pigeon cards (S5) | 20 units, cross tests | **not done** | planned: Codex with Claude review | none |
| Rust port and proof | A line-by-line mirror of the GDScript ("'Close' is a failure", `tools/league/PORTING.md`). Then `refresh_reference.sh` regenerates 1,200 games, 100,000 fights and the build pin; then `recheck.sh` (about 8 min) and the 200-game bot smoke test | **not done for either rework.** Comparable earlier ports took 1–1.5 h with Codex (#164; `engine/badgers-port`); the original full port took about 3 h | Codex, run by the ghost orchestrator | PR #176 body: "The Rust engine still has the old Mice until the port" |
| Bots | S8 (TribeBot holds Reserve units, new text matches) | **not done.** The league bots were left unchanged; blue still names cut cards (`adjutant`, `brigadier`) and stocks 3 cards in hand for the Colonel, where the limit is now 2 | planned: Claude | `tools/league/bots/blue/src/cards.rs` |
| Tests | `scripts/check.sh` (13 steps, 962 tests at S7, a short soak, 2 records replayed), plus a scope review for each step | inside each step | | |
| Art | The 12 new cards use the stand-in panel, listed in `tools/art/waiting.txt` | **deferred** until the cards survive a measurement | | build-plan.md |
| Balance measurement | Old against new | **not done**; it needs both ports and S8 | | |

**What changes for a brand-new tribe, compared with a rework:**
- `tests/glass/test_unit_art.gd:72` asserts `cards.size() == 5` ("five tribes ship"). A sixth tribe fails it until the assertion counts the tribe folders instead.
- Both engines can already pick a subset of tribes for a lobby (`lobby_tribes` in `game_session.gd` and `game_session.rs`). But the league harness always loads all five tribes ("All five tribes are in every lobby", `tools/league/league/README.md`).
- How many tribes rotate, and how many go in each lobby, is still open in the rulebook (5.2.5). The owner's "five-tribe lobby" suggests 5 per lobby. This plan assumes that, and it is listed as a question in section 7.

## 3. How the bots are built, and what each needs for a tribe it has never seen

| Bot | How it values cards | Hard-coded tribe and card knowledge | What a new tribe needs |
|---|---|---|---|
| **red** (`tools/league/bots/red`) | Stats plus a `power` column from `data/cards.tsv`. An agent wrote the first values from the card text; they were then refit by self-play regression (4 passes) and by fitting practice games (3 passes). The Sim is used only to arrange the board | `const TRIBES: [&str; 5]` (lib.rs:14); named cards in `tactics.rs`; special play only for Briar, Locust and Pigeon ("no special code" for Badger and Mouse) | Its tribe list edited; a table row per new card (an agent reads the text); a refit pass ("about 2 hours of CPU", NOTES.md:149); special-play code for any mechanic it can't use by default |
| **blue** (`tools/league/bots/blue`) | Mostly `−100 × lift`: how much better seats holding the card placed in self-play. The Sim arranges the board | `TRIBES: [&str; 5]`, `tribe_pref: [f64; 5]` defaulting to a tuned Badger −6 and Locust +6 lean (lib.rs:103); card rules for the Glutton, Gorger, War-drummer, Orders, Bury and the Colonel | Its tribe list and preferences edited; `tools/scripts/rebuild_lift.sh` (3 steps of 1,000 games, each checked against the old table; "a new card starts at 0 and is measured like the others"); special-play code as for red |
| TribeBot (Rust `league/src/baselines.rs:315`, GDScript `tools/league/gd/tribe_bot.gd`) | SimpleBot locked to one tribe; it places units by matching card text | `TRIBES: [&str; 5]`; a seat's tribe is picked with `% TRIBES.len()` from that fixed list | The tribe added to the list and to the registry; text matches for new placement rules |
| SimpleBot, FlowBot, RandomBot | Tier and stats only | none | nothing; but they are naive and don't meet "a high skill level" |

**Before any Rust bot can play a tribe, the tribe must be ported to the Rust engine and proved.** The bots only run on the Rust engine.

**Who re-runs what.** The refit loops are scripts. The rest is work for an agent session: deciding whether each refit is kept, reading the new cards, and writing special play. In the league, each team was an Opus lead with helpers and Codex, working 6 hours in round 1 and 4 in round 2.

### Showing "near equilibrium at a high skill level" rather than assuming it

At an equilibrium of tribe choice, every tribe that gets played places about equally well, and a tribe nobody plays would place no better if somebody did. Three checks test that from the outside, and a script can run each one:

- **E1. A forced-tribe probe.** For each tribe under 5%, 4 seats are pushed hard into that tribe (red's `tribe_lean`, blue's `pref_*`), against 4 normal seats. If the pushed seats place better than the field average, the bots are under-playing a good tribe: the low share is the bots' fault, not the design's. If they place worse, the low share is real. It needs a registry entry such as `red-lean-<tribe>`, because `league match` takes only bare bot names. Today those settings pass only through the teams' own tools.
- **E2. No gain left.** One more refit step for each bot, after it has learned the new tribe, should gain about zero places in its A/B check and leave the tribe shares inside their intervals. Blue already stopped refitting for this reason ("half-steps helped twice … then stopped helping"). It needs the existing refit scripts, plus 1,000 games for each check.
- **E3. Two independent bots agree.** Red and blue were built separately. If both give a tribe a similar share (`agree.py`, `tribes.py` by colour), that is evidence. If one is at 85% Locust and the other at 53%, as in arm-b, they don't agree yet. It needs nothing new.

**Today's data fails E1 in spirit already:** Mouse places 3.48 on 15% of boards, the best average with a low share. The owner's note of 19 Nov agrees: "I don't think we've technically reached equilibrium yet."

## 4. Exact measures for the two standards, with sample sizes

### Standard A: "played under five percent of the time"

| Option | "Played" means | For | Against |
|---|---|---|---|
| **A1 (recommended)** | The tribe is the **main tribe of the final board**: the harness's rule, most units, with ties going to the higher total stats | Already computed, with intervals (`tribes.py`); used through the whole league | A tribe that is splashed but never finished on scores 0 |
| A2 | The seat **committed**: it had 4 or more units of the tribe at some point | Counts attempts that pivoted away | Counts failed tries as "played" |
| A3 | The tribe's share of all units bought | Counts splashes and tempo buys | A tribe of strong tier-1 tempo units could pass while no one builds around it |

- **Denominator:** seats in lobbies that include the tribe. With a sixth tribe, that means a rotation through all six 5-tribe lobbies in equal numbers, with the share reported per lobby set and pooled.
- **Verdict:** fail if the upper end of the 95% interval is under 5%. Pass if the lower end is over 5%. Run more games if the interval straddles 5%.
- **Sample size:** 1,000 games (500 seed pairs, 8,000 seats) gives about ±0.4 points near 5% (measured on arm-b: Briar 4.0% [3.6, 4.4]). That is about 40 minutes on the Optiplex at a 1 s bot clock.
- **Counts only after E1–E3 pass** (an assurance-session proposal; recommended, see section 7).

### Standard B: "the worst card in a tier should be used at least a third as much as the most used card"

What "used" means:

| Option | "Used" means | For | Against |
|---|---|---|---|
| B1 | Times bought | Simple | Rises and falls with how often a card is offered and with its tribe's share |
| **B2 (recommended)** | **Buy rate when buyable** (`cards.py`: shops that showed a buyable copy, and how often it was bought) | Fair across offers; it is what the strong bots prefer, which is the owner's rule of 19 Nov ("look at what the bots are actually preferencing") | Low for a good card that is only bought once a game |
| B3 | On final boards | Counts the cards that are kept | Low-tier cards are rarely on final boards, so the ratio is noisy |

What "within a tier" means:

| Option | Scope | For | Against |
|---|---|---|---|
| S1 | All tribes' cards of that tier together | One list per tier | It doubles as Standard A: every card of an unpopular tribe fails. Today, 69 of 95 units fail it |
| **S2 (recommended)** | **One tribe's cards of that tier, counted among seats whose final main tribe is that tribe** | Answers "parts that aren't being used" in the tribe's own build; keeps the two standards apart | Only 2 to 4 cards per tribe in a tier; needs more games for rare cards |

- **Sample size (S2, B2):** telling a third apart, with top rates around 20%, needs about 1,000 shops per card from seats in that tribe.
  - 1,000 games are enough for tiers 1–4 of a tribe on about 15% or more of boards.
  - Tiers 5–6, or a tribe near 5%, need the E1 forced-tribe seats as the source: about 3,000 games with 4 pushed seats, about 2 hours.
  - Under 1,000 shops, the script says "not enough data", not pass or fail.
- **"Pretty much any":** the owner's "pretty much" allows exceptions. Recommended: the check lists every card under a third. An exception counts only when written down with a reason, as the tier guide already asks for cards "well outside" it.
- **What isn't counted:** tokens and Discover-only cards. Spells (not in `cards.py` today) are left out until the owner says otherwise.

## 5. Where today's five tribes stand

**The data:** arm-b, `/data/measure/arm-b/bots` on the Optiplex, 19 Nov 16:10. red-m2 against blue-m2, free choice of tribe, no shared pool, 1,000 games. Balance Pass One for Pigeon and Locust is in; **the Badger part of Pass One and all the Pigeon and Mouse reworks are not.** The two earlier datasets (m2, and baseline) give the same picture.

| Tribe | Share of final boards (95% interval) | Average place | Standard A |
|---|---|---|---|
| Locust | 69.3% [68.2, 70.3] | 4.46 | pass |
| Mouse | 15.4% [14.7, 16.2] | **3.48** | pass |
| Pigeon | 11.2% [10.6, 11.9] | 6.22 | pass |
| Briar | **4.0% [3.6, 4.4]** | 4.36 | **fail** |
| Badger | **0.1% [0.0, 0.1]** (4 seats) | 5.75 | **fail** |

Standard B, reading B2, worst ÷ best within each tribe's cards of each tier, over all seats (S2's "seats in that tribe" has too little data in arm-b for Badger and Briar):

| Tier | Badger | Briar | Locust | Mouse | Pigeon |
|---|---|---|---|---|---|
| 1 | 0.11 | 0.60 | 0.96 | 0.62 | 0.06 |
| 2 | 0.04 | 0.01 | 0.04 | 0.49 | 0.01 |
| 3 | 0.24 | 0.04 | 0.07 | 0.00 | 0.13 |
| 4 | 0.49 | 0.29 | 0.00 | 0.11 | 0.02 |
| 5 | 0.13 | 0.16 | 0.34 | 0.53 | 0.74 |
| 6 | 0.37 | 0.79 | 0.54 | 0.50 | 0.57 |

Under 0.33 fails. Across all tribes (S1), 69 of 95 units are under a third of their tier's top. Only Orchard Stripper passes at tier 4.

**Caveats:**
- These numbers measure a game that no longer exists on `dev`.
- The bots fail the equilibrium checks, so Standard A can't be held against any tribe yet.
- **The run that would answer it on current `dev`:**
  1. The reworks ported to Rust, and Pigeon S5 built.
  2. The bots updated for the cut and new cards.
  3. `league match` with red and blue, 1,000 games (about 40 min), then `analyse_match.sh`.
  4. One forced-tribe probe per tribe for E1 and for the rare cards (about 3,000 games each, run overnight).

## 6. What depends on the third run, and what can start now

**Depends on the third run's work (`docs/workstreams/third-run/ghost-plan.md`):**
- **A Rust engine level with `dev`.** It isn't level now: S3 changed every hash at 15:22, and the reworks aren't ported. Ports are the ghost orchestrator's job (decision 5A: "I port it within a day").
- **The strongest bots.** The third run's teams carry their bots over (decision 6d A). The "high skill level" bar is best met by those bots. And while the run is going, the teams own the bot code, so changes for a new tribe would collide with their work.
- **The balance sign-off.** The third run starts only after the owner signs off the balance pass, which is also the baseline this plan needs.

**Doesn't depend on it:**
- The async ghost game. Measuring in live 8-seat lobbies, where every seat adapts, is the right test for tribe choice. Ghosts are for the owner's play.

**Can start before:**
- the measures and the check script, tested on the arm-b data already on the Optiplex;
- the lobby rotation in the harness, the art test's tribe count, and the bots reading their tribe list from the card library;
- the skill drafts;
- stages 1–3 of the process (prompt, designs, ranking), which are documents only.

**Recommended:** make "bots read the tribe list from the card library" a third-run rule, so the teams' bots are ready for a sixth tribe when the run ends.

## 7. Decisions for the owner

| # | Decision | Options | Recommendation |
|---|---|---|---|
| 1 | What "played" means (Standard A) | A1 main tribe of the final board; A2 committed (4+ units at some point); A3 share of units bought | **A1**: already measured, with intervals |
| 2 | What "used" and "within a tier" mean (Standard B) | B1 buys / **B2 buy rate when buyable** / B3 final boards; S1 all tribes in the tier / **S2 one tribe in the tier, among that tribe's seats** | **B2 + S2**, with written exceptions for "pretty much" |
| 3 | Is a candidate built in the game, in Rust, or both before it is tested? | (a) **Both**: GDScript first, then the port and its proof, as today. (b) Rust only for candidates, GDScript for the winner: faster, but the bots would play rules nothing has proved, and you couldn't play or see the candidate in the game. (c) GDScript only, tested with GDScript bots: they are naive and slow (1.9 s a game), which fails "a high skill level" | **(a)**. Only one design is built at a time, so the cost is paid once per design. A numbers-only redesign reaches Rust with one command (`refresh_reference.sh`, then the proof) |
| 4 | Redesign rounds before option two | 1 / **up to 3** / until the measures stop moving | **Up to 3 rounds.** Move to option two early if two rounds in a row don't move the failing measure halfway to its line, or if the diagnosis says the tribe's core mechanic is the cause |
| 5 | Where you see the designs | (a) **an artifact page** like the 19 Nov rework page, with the reviewer's ranking, example cards and your questions; (b) a doc in the repo; (c) in the game (only after building) | **(a)**: one review round took about 2.5 h on 19 Nov and worked |
| 6 | Do the two standards apply to today's tribes? | (a) yes, now (Badger and Briar fail A; most tiers fail B); (b) **measure them as the baseline now, and apply both standards once the bots pass E1–E3**; (c) new tribes only | **(b)**. A new tribe's share depends on the field: with Locust at 69%, a sound new tribe could still fall under 5% |
| 7 | Lobby size for a sixth tribe (rulebook 5.2.5, open) | 5 of 6, by rotation / all tribes in every lobby | **5 of 6**, as your "five-tribe lobby" suggests |

**Proposals from the assurance session (not decided), with my view:**
- *The owner sees the reviewer's ranked designs before any is built.* **Agree.** It costs one stop, the same as the 19 Nov round, and it avoids a day spent building a design you'd reject.
- *The 5% standard counts against a design only after a check that the bots play that tribe well.* **Agree,** with E1–E3 as that check. Arm-b shows the bots fail it today.
- *Today's five tribes are measured first, as the baseline.* **Agree.** See decision 6.

## 8. The proposed process

Times are wall-clock estimates. "Observed" marks a time taken from the reworks; the rest are estimates.

### Before the first tribe, once

| Piece | Input | Output | Who | Cost |
|---|---|---|---|---|
| P1. Bots see any tribe | the card library | red, blue and TribeBot read the tribe list from the library; blue's preferences resize | Codex, with a scope review; Rust proof and the bot smoke test | about 2 h |
| P2. Lobby rotation in the harness | the decided lobby size | `league match --lobby-tribes rotate:5`, using the engines' existing `lobby_tribes` | Codex | about 1 h |
| P3. Art test counts tribe folders | — | the "five tribes ship" assertion follows the content folders | Codex | under 30 min |
| P4. Probe bots in the registry | P1 | `red-lean-<tribe>` and `blue-lean-<tribe>` that `league match` can run | Codex | about 1 h |
| P5. `tribe_standards.py` | a match folder | Standard A and Standard B verdicts (pass / fail / not enough data), E1–E3 results, and the list of cards under a third; tested on arm-b, where it must report Badger and Briar | Codex | about 2 h |
| P6. The baseline | the reworks ported, the bots updated | today's five tribes against both standards | ghost orchestrator for the port; one overnight run | port about 1.5 h per tribe (observed for earlier ports); runs about 4 h of CPU |

### For each new tribe

| Stage | Input | Output | Who | Cost |
|---|---|---|---|---|
| **1. Tribe prompt** | your idea: a species seed, theme or mechanic | `docs/tribes/<name>/prompt.md`, quoting you, plus fixed constraints: tier shape, tier guide, guardrails, which keywords are shared | you, plus the orchestrator turning it into a brief | minutes of your time |
| **2. Designs and refinement** | the prompt, the `bramble-design` reading list | 3–4 full tribes (about 19 units), each with full card text, a rough power number for every utility effect, a tier check, two variations of its main mechanic, the new core rules it needs, and how a bot would have to play it. Each designer then does one refinement pass: rough fight checks on the game's fight engine, kept small as the skill says | 3–4 agents working in parallel, with different starting angles; Opus and Codex mixed for real difference (Opus only on the Claude side) | about 1.5–2 h in parallel; 3–4 agent sessions |
| **3. Reviewer's ranking** | the 3–4 designs, the prompt, the tier guide, today's baseline | a ranking with reasons, against fit to the prompt, distinctness from the other tribes, fragility (your note on Mice: "very fragile"), build cost (new core rules mean port cost), and how much special bot play it needs | one fresh agent that wrote no design | about 1 h |
| **3b. You see the ranking** (assurance proposal) | the ranking page | your pick of option one and the order after it | you | one review round (about 2.5 h on 19 Nov, observed) |
| **4. Build the chosen design** | the design | GDScript tribe folder and tests, cross tests, art stand-ins on the waiting list; the Rust port and its proof | Codex builds, Claude reviews; the ghost orchestrator ports | about 1–2 h without new core rules (observed for S6–S7); up to about 3 h with them (observed for S3); port about 1–1.5 h |
| **5. Bots learn it** | the ported tribe | red's card rows and a refit pass, blue's lift rebuild, special-play code where a mechanic needs it, then E1–E3 | a "bot coach" agent session, using the refit scripts | about 4–6 h, mostly CPU; the coaching session 2–4 h |
| **6. Balance test** | the bots that pass E1–E3 | a 1,000-game rotation match, forced-tribe probes for the new tribe and any tribe under 5%, and `tribe_standards.py`'s verdict | a script run by the orchestrator | about 3 h of CPU; can run overnight |
| **7. Redesign** | the failing measures, what the bots prefer, the design | a change chosen by your four-kinds method (numbers, tier, replace, rework), with the support checked first and no double-tap | the design's own designer, or a balance agent | numbers only: about 2–3 h a round (refresh, a refit step, retest). A mechanic change: about 5 h (port included) |
| **8. Option two** | up to 3 failed rounds, or a structural failure | stage 4 with the reviewer's next design | the orchestrator | as stage 4 onward |

**About one day per design tested.** Stages 2–3 take an afternoon. Stages 4–6 take most of a day, much of it CPU that can run overnight (see the `overnight-run` skill). The Optiplex has 6 cores shared with other agents, so long runs check its load first, as the league brief says.

**After a pass:** you play the tribe in the game. Art is made only after that, as for the reworks.

### What becomes a skill, a script or a check, and what stays with you

- **A skill, `tribe-pipeline`** (new): the stages above, the designers' brief, the reviewer's checklist, the redesign rule and when to move to option two. `bramble-design` gets two short sections: "designing a tribe to a prompt" and "ranking tribe designs".
- **Scripts and checks:** P1–P5 above; `tribe_standards.py` gives the verdicts; a `tribe_test.sh` runs stage 6 end to end.
- **Stays with you:** the prompt; your pick from the ranking; the measures in section 4 (once); accepting a tribe that passes; and what happens when every option fails.

## 9. Is the problem fixed?

**The owner's problem:** a process that turns a prompt into a tribe that meets the two standards. It exists once the one-time pieces and the baseline are done (P1–P6) and the first new tribe has gone through stages 1–7. Before P6, a verdict on any tribe means little, because the bots aren't near equilibrium and the field is lopsided (Locust 69%).
