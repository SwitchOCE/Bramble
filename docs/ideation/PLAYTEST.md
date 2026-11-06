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
- **Saving up:** skip buying and bank gold for a big late turn. The bots never try this, so we don't know whether it's too strong. You're the test.
- **Stats early:** stay on low tiers and out-muscle the climbers.

The Scout button shows your next opponent's hero and the board they fought with last round. Use it to decide who stands across from whom.

## What this build is not

It has 2 tribes out of a planned 6. Fuller tribes, more balance and a clear step up to Hard are still to come. The latest numbers are in `docs/ideation/evidence/bench-latest.md`.

## What changed

**Ideation build 1:** the first build of the new game. New rules engine, Hedgerow and Fairies, neutrals, 10 spells, 9 heroes, the Woodcraft look, art on every card, sound, three bot levels, and the Scout button.
