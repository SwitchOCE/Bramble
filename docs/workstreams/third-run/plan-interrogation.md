# Plan interrogation: the ghost plan, first draft

Run on 19 Nov 2026 by a fresh agent that did not write the plan, following `~/.claude/skills/plan-interrogate/SKILL.md`, on the first draft of [ghost-plan.md](ghost-plan.md). It was given the owner's own words, quoted. The plan has since been revised; its last section says what was taken. This is the agent's output, lightly formatted.

Main finding: in the plan as written, the owner's goal is only met after **step 6**, the last step. The async game can be played much earlier. Once step 3 lands, the final league bots can make a field of ghosts in under an hour (decision 6a-A), and the owner could play them in a Windows build before the third run starts. Most of the plan moves the problem. A few ghost pieces have nothing in this phase that reads them.

| Step or item | Moves the problem? | Proposed by | Verdict | Why |
|---|---|---|---|---|
| 1. Rust engine level with `dev` (six rule changes, proof) | Yes: the balance work and the third run both run on it | Brief (item 4) | keep | Brief: "the first thing the balance work waits on" |
| 1. Bot API stays compatible, 200-game smoke | Yes: third run, "bots carry over" | Assurance session (agent) | keep | Cheap. Without it, `red-m2` and `blue-m2` don't compile |
| 1. "Kept level" regenerate script | Yes, if decision 5 is A | Agent | keep, small | Card numbers are already read from `src/content` at run time. The script only refreshes the pinned identity and the reference games |
| 2. Pool removed | Yes | Owner | keep | "I want that removed" |
| 2. Smallest version | – | – | shrink | With decision 1-A, the draw stays as it is in `card_pool.gd` (proportional to copies) and nothing ever takes or returns copies. The Rust port is then a few lines too |
| 2. Rulebook rewrites | Yes | Brief | keep | Required by the brief |
| 3. Ghost run format | Yes | Owner ("full replay architecture") | keep | |
| 3. Per-card fingerprints and the per-card retirement rule | No, not in this phase | Agent | defer the rule, keep the field only if it is one line | The plan's own 4-A says "for now: refill the field from bots". Nothing reads the rule until there are players |
| 3. Per-turn health in a run | Only under 3b-B | Agent | ask, decided by decision 3 | Fight payloads have no health. Under 3b-A nothing reads it |
| 3. Cutting runs out of records "(GDScript and Rust)" | Yes | Owner ("take replay files from the Rust bots") | shrink to one cutter | Rust already writes GDScript's record format (`league/src/game.rs`). Two cutters is duplicate work |
| 3. Writing the player's own run at the end of each game | No | Agent | defer | No step in this plan reads them. The owner's records are kept anyway, and the cutter can make runs from them later |
| 3. Async game in both engines, hash for hash | Yes: the run is played in Rust, the owner plays in GDScript | Agent, from the owner's words | keep | Fight parity is already proved (100k fights). Only the new session loop needs a new proof |
| 3. Records name the runs they used | Yes | Owner (17 Nov, "reconstruct a game exactly") | keep | Without it, async records can't be replayed |
| 3. Ghost store interface plus local folder | Yes | Owner ("other interfaces … during development") | keep | |
| 3. Separate "submit" interface | Weak | Agent | shrink | Fold it into the store as an "add" call. Upload is plan-only anyway |
| 3. Matchmaker interface, simple rules | Yes | Agent | keep | `matchmaking.gd` only pairs players inside a lobby; it doesn't pick a lobby |
| 3. Ratings (hidden, updated from placements) | Weak | Agent | shrink | 6c-A scores teams on identical lobbies and doesn't need ratings. Store placement and bot version; match by version and placement band. Rating maths waits for players. The interface stays |
| 3. Server design note | Yes ("everything needs to be ready") | Owner | keep, short | |
| 3. Plan-only rows | – | – | keep as plan-only | |
| 4. Assurance check | Only through the balance measurement | Assurance session (agent) | shrink: fold into the balance orchestrator's run | The plan already says "not twice" |
| 5. Third run | Yes | Owner | keep | |
| 6. Windows build with the run's ghosts | Yes, the end goal | Owner | keep | |
| Decision 5-A: a Rust port and a passing proof before any mechanic PR merges to `dev` | No: a standing process | Agent | ask | It puts a Rust port in front of every future rework, including the balance orchestrator's |

**Fixed after which step.** As written, the goal is met only after step 6. Reordered, the owner can play async ghosts after a new step 3a (below), and the full goal is still met after the Windows build of the third run's ghosts.

**Smallest plan.**
1. Rust level with `dev`, bot API kept compatible.
2. Pool removed (1-A as the small no-take/no-return change), ported to Rust.
3. Ghosts: run format; one cutter; async session in both engines with its proof; records name the runs they used; store and matchmaker interfaces with local versions; a short server note.
   3a. The final league bots play 1,000 games on the new game and make the first field. A Windows build with that field goes to the owner.
4. Balance pass measured (includes the assurance check).
5. Third run.
6. Windows build with the third run's ghosts.

**Deferred.** Per-card retirement rule (trigger: first players' ghosts). Rating updates (trigger: real players, or a field of many strengths). The player's own run in the field (trigger: a run that includes the owner's ghosts). Per-turn health (trigger: decision 3b-B). Upload (trigger: a server).

**Checkpoints.** After step 2: the owner plays without the pool, if they want. After 3a: the owner plays the async game against league-bot ghosts; the most important stop. Before step 5: the owner signs off the balance pass.

**Open questions for the owner.** Decision 5 (gate on every mechanic PR, or caught up before each run). Decision 3b (A drops per-turn health from the format). Whether 3a's early build goes in. Whether "scoped as it will need to be for the full game" means ratings built now.
