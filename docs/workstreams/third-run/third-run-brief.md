# The third bot run: referee and team briefs (draft for the owner)

**Status: a draft, not started.** Written 21 Nov 2026 by the ghost orchestrator from ghost-plan step 5 and decision 6, which the owner approved on 19 Nov. The owner reads it before anything starts: "You prepare it, we revisit for the third run." No session starts and no bot climbs until the owner says go. Everything marked **Proposed** is my choice, not the owner's.

## 1. Why

The owner, 19 Nov: "do a third bot run after we've removed the minion pool, built out the ghost system, etc." The owner, 20 Nov: "We need strong bots for balance." "They have to hill climb and at least reach a local maximum. Even if it's not the actual maximum, we need to at least reach local. And I prefer not to get stuck at a local maximum."

So the run makes the strong bots that balance is measured with (owner note `2026-11-20a`). It plays the game as it will be played: async, against recorded runs, with no shared pool. Its kept bots go to the balance orchestrator; balance tunes only from bots that passed the stopping test (owner: "Only passed bots").

## 2. What carries over from the league, and what changes

The league brief, `docs/workstreams/bot-league/brief.md`, still holds where this page doesn't replace it: the isolation of the clones (section 6), what teams may and may not do, port bugs reported at once, equal caps, hand-ins as tags in the clone, and the checks for cheats and harness bugs (section 8). The owner on the league: no extra cheat checks, and the teams are trusted.

| | League (18–19 Nov) | Third run |
|---|---|---|
| Game | live 8-player lobbies, shared pool | **one bot against 7 recorded runs**, no pool (rulebook 2.1.5) |
| Scored by | fixed matches at deadlines, red against blue | **a climb**: each team's new version against its own current one, paired on the same seeds and the same 7 ghosts (decision 6c) |
| Ends | after 3 matches | when **both bots pass the stopping test** after their restarts, or the owner stops it |
| Teams | red and blue sessions | the **same two sessions carry on** with their notes (decision 6d A) |
| Referee | the league's referee session | the same (decision 6e) |
| Rules | frozen engine `league-engine-v1` | frozen per climb: **no card numbers change while the bots climb** (owner: "Freeze per climb") |

## 3. Before it starts (the referee)

1. **The engine tag.** Tag `dev` as `third-run-engine-v1` once the owner approves this brief. It holds the batch-1 cards (PR 222), step E's proof (PR 225) and ghost matches for the teams' tools (PR 226). Rules hash `4e3317511de4…`.
2. **The clones.** Merge `third-run-engine-v1` into `league/red` and `league/blue` in `/home/alex/league/red` and `/home/alex/league/blue`. Each team's tools crate moves from `league::matchrun::run_factories` (live) to `league::ghostmatch::run_factories(&args, new, old, field)`. A team's diff is then checked against `third-run-engine-v1`, not `league-engine-v1`.
3. **The fields.** Two folders of ghost runs, each made with `tools/league/proof/make_field.sh` (1,000 live games of the final league bots, cut and verified):
   - **The climbing field**, which grows. It starts as `/data/third-run/field-f82d9c94`: 8,000 runs from red-m2 and blue-m2 at the current rules, made 21 Nov. Every kept version's runs are added (decision 6b), and the field keeps the newest **[Proposed: 4,000]** runs per bot version, so old versions age out.
   - **The reference field**, frozen for the stopping test: **[Proposed: a 1,500-game field, about 12,000 runs, cut once at the start and never added to]**, so every version is tested against the same opponents. It must be that big: a stopping-test match needs about 1,510 seed pairs, each pair uses 7 runs, and no run is used twice in a match (section 9).
4. **The teams' practice field.** Each team gets read access to the climbing field only, never the reference field.

## 4. One thread count

The final league bots time their search by CPU, so the same game at a different thread count can play differently (19 of 20 games matched at 1 against 8 threads). Every scored match and stopping test uses **[Proposed: 4 threads on cores 2–5, `--clock-ms 1000`]**. The teams' practice uses cores 0–1, one each. The owner, 21 Nov 2026: "I agree with the calls."

## 5. Climbing

- Each team changes its bot **one idea at a time** and hands the referee a tag (`red-c<n>`, `blue-c<n>`).
- The referee plays the new tag against the team's current kept version in a **paired ghost match**: `league ghost-match --red <new> --blue <current> --field <climbing field>`, the same seeds and the same 7 ghosts per pair, then `league analyze` and `tools/league/proof/check_ghost_match.py`.
- **Keep** the new version only if it places better with a 95% interval that excludes zero. Otherwise the current version stays.
- Size: **[Proposed: 1,000 games (500 pairs)]**. That sees a gain of about 0.17 in mean placement (section 9). A smaller real gain is usually rejected here; the stopping test is where 0.1 is checked.
- A kept version's runs join the climbing field.

## 6. The stopping test: a local maximum

On the reference field, each match sized to see 0.1 in mean placement: **about 3,020 games (1,510 pairs)**, 20–35 minutes each (section 9). Up to 10 numbers with a step each way is up to 20 matches, so **a full stopping test takes about 7–12 hours per bot**, plus one match per tribe for the per-tribe report:
- **Numbers.** For each of up to 10 numbers the team names up front, one step up and one step down (the steps named up front) don't beat the current version.
- **Ideas.** The team's last 8 ideas, covering economy, tribe choice, board order and each reworked mechanic, were all rejected.
- **Both bots** pass, on overall placement. The test also plays each bot made to stay in each tribe and reports its placement per tribe (owner: "Overall + per-tribe report").

**Not getting stuck.** At a bot's first local maximum its team climbs again from 2 different strategies it names; the best of the three is kept. The teams use different model families, and each team's best plays the other's. **Open, for the owner:** in the league both teams were Opus orchestrators, and decision 6d keeps the same sessions, so they are one family today. **[Proposed:** red's session carries on in Opus; blue's continues from its own notes in a new session on a different family (Codex `gpt-6.2-astra` as the orchestrator, or Fable)**.]** The run ends when both bots have passed the stopping test after their restarts, or the owner stops it.

## 7. The reworked mechanics

For each reworked mechanic (holding reservists, Actives, Mouse pilers, Hand-me-down routing), the referee reports how often the bot uses it, and plays the bot against itself with that mechanic switched off. If switching it off costs nothing, the team hears that its bot isn't using it well.

**Open: how "switched off" is done.** **[Proposed:** each team's bot reads an environment flag per mechanic and never takes that action when it is set; the referee checks with the decision logs that it wasn't taken.**]** The harness can't do this for the bots without new code.

## 8. What goes to whom

- **Balance orchestrator:** every kept version, labelled interim, with what it picks and how it places per tribe, and its rework checks. Balance tunes only from bots that passed the stopping test. Card numbers change only between climbs; then the bots climb again on the new numbers, from where they were, on a new field cut at the new rules.
- **The owner:** a short report each day: versions kept, the gap between the teams, and where each bot stands on the stopping test. Stop and ask only for a confirmed cheat, a harness bug that changes a result, a busy machine, a Codex limit on both models, or the stopping test passed.
- **The teams:** each other's method summaries after each kept version, as in the league (section 7b), never code or numbers.

## 9. Size, time and disk

Measured 21 Nov on `/data/third-run/field-f82d9c94`, 1,000 games each, 5 threads, `--clock-ms 1000`:

| Match | Mean placement, red minus blue | Spread of the pair difference | ± at 95%, 500 pairs | Pairs to see ±0.1 |
|---|---|---|---|---|
| red-m2 against itself | +0.01 | 1.98 | 0.17 | about 1,510 |
| red-m2 against blue-m2 | −0.80 | 2.80 | 0.25 | about 3,020 |

Pairing works: the same bot's two games against the same 7 ghosts correlate at 0.67, so a paired match needs about a third of the games an unpaired one would. Two versions of one bot are like the first row, so the stopping test is sized from it. In ghost play red-m2 beats blue-m2 clearly, the reverse of the league's live matches.

- **Field capacity.** A ghost match never reuses a run within a match, and each seed pair uses 7, so a field of R runs supports about R ÷ 3.5 games per match: 8,000 runs, about 2,280 games (1,140 pairs). That is enough for climbing matches and too few for a stopping-test match, hence the bigger reference field.
- **Time.** 1,000 games of the final bots on 5 threads: 7–11 minutes as a ghost match, 21 minutes as a live match (8 bots per game instead of 1).
- **Disk.** Today a 1,000-game ghost match writes about 355 MB, and a live match about 0.9 GB. A full stopping test is about 20 matches, about 20 GB at today's defaults; `/` was 89% full on 21 Nov before the league data was cleared. What a match keeps is the League Data and Storage session's question for the owner; the run follows what the owner picks.

## 10. The team brief (same for both, apart from the colour)

*[To be written into `tools/league/bots/<colour>/THIRD-RUN.md` in each clone once the owner approves.]*

- Your league brief and notes still hold, apart from what this page changes. Your bot carries over as it is: `<colour>-m2`.
- The game is now async: one bot against 7 recorded runs, no shared pool. Read rulebook 2.1.5 and the batch-1 card changes.
- **Your job:** climb. One idea at a time, tagged `<colour>-c<n>`; the referee keeps it only if it beats your current version on the climbing field. Then pass the stopping test (section 6 above), and climb again from 2 different strategies you name.
- Name up front, before your first stopping test: up to 10 numbers and their steps, and your 2 restart strategies.
- Practise with `league::ghostmatch::run_factories` against the climbing field on your one core. Never read the reference field.
- Support a per-mechanic off switch (section 7).
- Card numbers don't change during a climb. Report a port bug at once, with a seed and the actions.
- Workers never run `rm -rf`; each lists the files it made that should go.
