---
id: random-seed
group: prototype
size: small
headline: Each new game starts from a random seed you can replay
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#6
option: Random seed each game
option: Seeds 1, 2, 3 in order
suggested: Random seed each game
---
Everything random in a game (what the shop offers, who you're paired with, which way a coin-flip effect goes) comes from one starting number, the seed. The same seed plays out the same game.

In the playable game, every new game picks a random seed. The dev panel shows it, and you can type one in to replay a game exactly, which is handy when you want to show us something odd. The alternative would be to number them 1, 2, 3 and so on each time you launch the game.

**What we need from you:** is a random seed each game fine?

**Why it matters:** it only affects testing: random seeds give you fresh games, numbered ones make every session start the same way.

We'd suggest keeping it random. You can always type in a seed when you want a repeat.

## Detail

- **As built:** every new game starts from a random seed, shown in the dev panel (Dev button or the ` key), where you can also set it to replay a game.
- **The alternative named:** seeds 1, 2, 3… per launch.
- **"Same seed plays out the same game"** assumes the same choices by you; the bots and shop follow the seed. The suggestion is ours.

**The original question (prototype question 6):**
> "Seed. Picked: every new game starts from a random seed, which the dev panel shows and lets you type in to replay a game. Seeds 1, 2, 3… per launch would be the alternative."

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/PLAYTEST.md`.
