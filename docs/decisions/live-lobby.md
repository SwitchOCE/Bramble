---
id: live-lobby
group: prototype
size: big
headline: Is fighting live bots fine for playtesting, instead of recorded boards?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#3
option: Fine for playtesting
option: Build recorded opponents into the prototype
suggested: Fine for playtesting
---
In the finished game, the opponents you fight are meant to be boards recorded from other players' past games, so you never wait on anyone. We don't have any recorded games yet. So in the prototype, you fight seven bots that play the same round as you, live: everyone shops, then all the fights run.

**What we need from you:** is that fine for playtesting for now? We'd suggest yes, and switching over once there are real games to record.

**Why it matters:** with recorded opponents, how you're paired, what happens when an odd number of players is left, and how a game ends are still undecided. The prototype's answers to those are stand-ins, so don't read too much into them.

## Detail

- **The decided rule:** rulebook 2.1.4 [BRAMBLE], decided 2 Nov: no turn timer; fights are against snapshots of other players' boards. The prototype departs from it.
- **What the prototype does:** a live 8-player lobby in one process. Each bot's "snapshot" is its board at the end of its own recruit phase in the same round. Every round, all bots and the human finish recruiting, then all fights run. Pairing is random each round and avoids your last 3 opponents where it can; you see your next opponent at the start of recruit; an odd count fights a ghost.
- **Why:** it was the quickest way to get a whole game running.
- The suggestion is ours.
- **Still open in the rulebook:** 2.1.5, lobby size, snapshot matching, ghosts and game end under async play. It needs a proposal.

**The original question (prototype question 3):**
> "Live lobby. The prototype fights each bot's board from the same round, live, instead of async snapshots (rulebook 2.1.4, a decided Bramble rule). Is that fine for playtesting?"

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/PLAYTEST.md`, `docs/prototype/SPEC.md` section 9; `design/tribes-and-budget:docs/design/rulebook-deltas.md`.
