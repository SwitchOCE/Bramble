# Playing Bramble (ideation builds)

## Getting it

Open the portal's builds page and take the newest ideation build, or look in `/data/bramble-builds/latest/`.

- **Windows:** unzip `Bramble-windows.zip`, run `windows/bramble.exe` (keep `bramble.pck` next to it).
- **Android:** install `Bramble.apk`. It's debug-signed, so allow installing from unknown sources.
- **Linux:** `linux/bramble.x86_64`.

No real phone has been tested, and nobody has heard the sounds: agents can only measure layouts at phone size and check the sound files. Tell us if text is too small on your phone or if a sound is wrong.

## Returning after build 3

Build 4 adds **Bog folk** and **Hunters**, completing all six tribes. Each lobby uses five of the six tribes. Bog folk lay Mire across the enemy lanes and pull attacks toward the unit that made it; Hunters mark Quarry at the bell and earn Takes when it faints. Scout shows their lane links, and fights show patches and marks. Crowded Scout shops wrap and scroll to keep offers finger sized.

## What to try

Choose New game, pick one of three heroes, and play against seven opponents. There is one bot strength. The menu keeps your best place and wins.

Ideas for builds that should feel different:

- **Hedgerow, Acorns:** hold Acorns instead of cashing them, and feed the units that eat them.
- **Fairies, Rings:** put Rings on slots, then choose who stands on them.
- **Fairies, Rainbow:** with a Rainbow unit on your board, play units into empty slots to paint bands. Moving or removing a unit fades its band. Rainbow Chaser grows with the bands; sell it for 1 gold per band and 5 more for all seven, then the bands wash away.
- **Oozes, Belly:** drop a unit onto an Ooze from the shop or hand, or with the Into a Belly button from the board. When the Ooze dies they come out. Who goes in last? How many bodies can seven slots hold?
- **Birds, Fly South:** send away a Bird that has fought, for no sale gold. It returns to hand after its trip (normally 2 turns; Old Tern takes 3), ready to play again. Its empty Nest fights as a textless Egg with half the Bird's Attack and Health, rounded up; Mother Goose's own Egg stays 0/2. Does the smaller body feel worth the trip? Small Birds are allowed to fly almost free: Old Tern's payoff is its homecoming, and One Swallow trades its body for gold when replayed next to a Bird. Watch these choices in playtests, especially beside larger, buffed Birds.
- **Bog folk, Mire:** scout, then put a sturdy mirer across from an enemy you want to draw into it. Try Bitter beside your wall and watch when the lock ends. Does shifting lanes to escape enemy mud feel useful?
- **Hunters, Quarry:** aim Little Nip at something killable for next-turn gold; try Pack beside a Hunter and compare the fight. With Mistress Russet, watch for a cheaper pool copy of fallen quarry in your next shop when its tier is no higher than yours. Does scouting make your Takes more reliable?
- **Charcoal Burner — provisional, bot-tuned numbers:** it is tier 4, burning gold above 5 up to 6 (golden 12), for permanent +1/+1 per 2 burned to units behind. Keep 11 gold for +3/+3 behind it and 5 left, or spend on a better buy? Judge this retune by **human play**; bot uptake is weak evidence, not a card-strength verdict. Tell us when banking feels useful, automatic or too costly.
- **Saving up:** hold some gold for a big late turn, using Hiring Fair, Market Day or Last Orders. Money Spider pays for gold carried over. The Long Purse bot saves on a fixed schedule and does poorly, which says little about saving by hand. Is it a real way to play?
- **Stats early:** stay on low tiers and out-muscle the climbers.
- **Your first two rounds:** a unit now, Rainy Day for gold next turn, or A Leg Up to climb sooner. Do they feel like a real choice?

The Scout button shows the board your next opponent fought with last round, Hexes and Rings included, in place of the shop row. The shop shrinks beside it, so you can still buy and move while you look. Tap one of their cards for its full text, or Who? for their hero. Use it to decide who stands across from whom.

Words: **gold** is what you spend each turn. An **Acorn** is a card in your hand that you play for gold. With an odd number of players left, one fights a **ghost**: the board of the last player knocked out. Beating it costs nobody anything; losing to it still costs you Health.

Short UI check on ef27d6f: 2 games each at 1920x1080 and 1688x780 plus 2 late checks, 0 UI problems, hard 30-minute limit. A cached-shader recompilation warning flagged the first desktop game; its full retry passed all original checks. Normal engine clock; all real UI actions and layout checks enabled. Gate: 1,152/1,152. No depth-bar UI run or full bench on this commit, no real device test, and nobody has heard the sounds.

## What this build is not

All six tribes are present; Bog folk and Hunters need fresh playtests and balance work. The numbers in `docs/ideation/evidence/bench-latest.md` are **older evidence**, recorded on 1d12de0. No full bench or depth-bar UI run has been completed on this source; those older numbers do not validate build 4. A detached six-tribe bench is being started separately; its results are not part of this build's checks.

Older bench measurements found little placement benefit; that has not been remeasured on this source. Tell us if positioning feels useful.

## What changed

**Ideation build 4:** all six tribes, with Bog folk and Hunters new; Mire, Quarry, Takes and Pack bring new lane choices, rewards and visible fight links. Crowded Scout shops keep full-size tap targets and scroll when needed.

**Ideation build 3:** more of your bought shop tier, a price for early losses and a cap on late damage, bounded Acorn growth, clearer rules and Hex values, and phone recruiting controls that stay visible while reading a bird. Hero names stay readable on phone, with long words shortened in the small portrait plaque; tap the portrait for the full name. Hiring Fair stays at 6 gold. Fetch no longer copies a stripped printed Fetch. Still four tribes.

**Ideation build 2:** Oozes (Belly) and Birds (Fly South), so 4 of 6 tribes. Longer games, fewer runaway units and spells, a new opening choice in rounds 1 and 2.

**Ideation build 1:** the first build of the new game. New rules engine, Hedgerow and Fairies, neutrals, 10 spells, 9 heroes, the Woodcraft look, art on every card, sound, and the Scout button.
