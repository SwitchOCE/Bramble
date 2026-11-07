# Playing Bramble (ideation builds)

## Getting it

Open the portal's builds page and take the newest ideation build, or look in `/data/bramble-builds/latest/`.

- **Windows:** unzip `Bramble-windows.zip`, run `windows/bramble.exe` (keep `bramble.pck` next to it).
- **Android:** install `Bramble.apk`. It's debug-signed, so allow installing from unknown sources.
- **Linux:** `linux/bramble.x86_64`.

No real phone has been tested, and nobody has heard the sounds: agents can only measure layouts at phone size and check the sound files. Tell us if text is too small on your phone or if a sound is wrong.

## What to try

Pick a difficulty, pick one of three heroes, and play an 8-player game against bots. Hard is the one to beat; the menu keeps your best place and wins at each level.

Ideas for builds that should feel different:

- **Hedgerow, Acorns:** hold Acorns instead of cashing them, and feed the units that eat them.
- **Fairies, Rings:** put Rings on slots, then choose who stands on them.
- **Fairies, Rainbow:** get all seven slots paying the pot.
- **Oozes, Belly:** drop a unit onto an Ooze from the shop or hand, or with the Into a Belly button from the board. When the Ooze dies they come out. Who goes in last? How many bodies can seven slots hold?
- **Birds, Fly South:** sell a bird that has fought. You keep the gold, it's home in 2 turns, and its When played fires again. Stand someone on its Nest, or leave the 0/2 Egg. Does the gap feel worth it?
- **Saving up:** skip buying and bank gold for a big late turn, using the late spells (Hiring Fair, Market Day, Last Orders). One bot tries it on a fixed schedule and does poorly, which says little. You're the test: is it a real way to play?
- **Stats early:** stay on low tiers and out-muscle the climbers.
- **Your first two rounds:** a unit now, Rainy Day for gold next turn, or A Leg Up to climb sooner. Do they feel like a real choice?

The Scout button shows the board your next opponent fought with last round, Hexes and Rings included, in place of the shop row. The shop shrinks beside it, so you can still buy and move while you look. Tap one of their cards for its full text, or Who? for their hero. Use it to decide who stands across from whom.

Words: **gold** is what you spend each turn. An **Acorn** is a card in your hand that you play for gold. With an odd number of players left, one fights a **ghost**: the board of the last player knocked out. Beating it costs nobody anything; losing to it still costs you Health.

## What this build is not

It has 4 tribes out of a planned 6. Oozes and Birds are new and untuned against play by people. Fuller tribes, more balance and a clear step up to Hard are still to come. The latest numbers are in `docs/ideation/evidence/bench-latest.md`.

## What changed

**Ideation build 1:** the first build of the new game. New rules engine, Hedgerow and Fairies, neutrals, 10 spells, 9 heroes, the Woodcraft look, art on every card, sound, three bot levels, and the Scout button.
