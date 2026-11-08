# Playing Bramble (ideation builds)

## Getting it

Open the portal's builds page and take the newest ideation build, or look in `/data/bramble-builds/latest/`.

- **Windows:** unzip `Bramble-windows.zip`, run `windows/bramble.exe` (keep `bramble.pck` next to it).
- **Android:** install `Bramble.apk`. It's debug-signed, so allow installing from unknown sources.
- **Linux:** `linux/bramble.x86_64`.

No real phone has been tested, and nobody has heard the sounds: agents can only measure layouts at phone size and check the sound files. Tell us if text is too small on your phone or if a sound is wrong.

## Damage on this branch

Start with 40 Health. Lose a fight: take the round base plus 1 per enemy starting survivor. The base is 0/0/0/1/1/2/2/3/4/5/7/9/11/13 from round 1, then stays at 13. No cap or toll. Ties deal no damage. Golden counts once; combat summons and stolen enemies do not count.

Last Blow decides mutual wipes by the final attack or effect and deals only the base. Start of Combat wipes stay ties. Last Stand still saves one lethal loss to a living hero from 2+ Health in the last four, leaving 1 Health after Armor.

## Returning after build 6

Build 7 makes card text and keyword explanations much shorter, about Battlegrounds' length, with the same effects. Hover over a keyword on PC, or tap it, to open its explanation on a smaller italic slip. Tap again to close it. The wording now uses one word for each idea throughout the cards, guide and fight log: for example, **Tier up**, **across**, **base** stats and **painted slots**. The Bog folk card formerly called Belladonna is now **Lady Belladonna**, so it is easier to tell apart from the Fairy Belladonna Sprite.

Try opening an explanation while reading a long card, both in your hand and in Scout. Does the shorter text tell you enough to choose, and is the extra explanation easy to find? Tell us if a familiar effect now sounds different or if anything is hard to read.

## Returning after build 5

Build 6 offers **Harvest Supper from tier 3**. With four heroes left, **Last Stand** saves each hero once from a lethal hero loss at 2+ Health, leaving 1 Health; ghosts never spend it. **Last Blow** awards a mutual wipe to the side that struck last, crediting the finishing effect's owner; Start of Combat wipes remain ties. The lobby shows Last Stand ready or used, and the hero panel and combat log explain it. Bot strength is unchanged from build 5.

## Returning after build 4

Build 5 rewards committing to a tribe. Five of the six tribes appear in each lobby. **Stand Behind Me** buffs units behind a front-row unit by +1/+1 permanently, or +2/+2 for shared tribe; **Bread from the Back** does the same in front of a back-row unit. **Harvest Supper**, offered from tier 3 for 3 gold, gives a standing +1/+1 tribe bonus, including future recruits, up to +3/+3. It is once a turn and excludes fight summons; look for the visible bonus on tribe icons. **Hiring Fair** still costs 6 gold and Discovers tier 6; with five board units sharing a tribe, one offer is guaranteed to share it.

There is one bot strength: Easy and Normal were removed at the owner's request. Away Birds leave textless Eggs with half their Attack and Health, rounded up, except Mother Goose's own 0/2 Egg. Known empty Nests show those stats. Damage now follows the round base and starting survivors described above. Only with four or fewer heroes left, Last Stand saves each hero once from a lethal hero loss at 2+ Health, leaving 1; ghosts never spend it. Last Blow awards a mutual wipe to the attacker, or to the owner of the effect that finishes it; Start of Combat wipes remain ties. Last Blow deals only the round base. From four heroes left, the lobby marks Last Stand ready or used; tap your hero for its rule. A used save also appears in the combat log. Try selling out for one late turn and relying on the save; does the next turn offer a real recovery? The picture guide explains the recruit loop and fights from the menu.

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

Build 7 on 2ac67e8 passed headless import, all ten gate steps (1,321/1,321 tests), and the short UI run: 2 games each at 1920×1080 and 1688×780 plus 2 forced late-game checks, all with zero problems or errors. Normal engine clock, all six cores available, hard 40-minute UI limit, original layout minimums retained. Required Android export and Linux/Wine boots passed; the APK signing certificate matches builds 5 and 6. Windows ZIP and APK integrity passed. See `evidence/ui-run.md` and the build's README.txt and logs. This does not judge the depth bar or bot strength.

## Engines package on this branch

The three engines changes are real rules. Harvest Supper is offered from tier 3. Only with four or fewer heroes left, Last Stand saves each hero once from a lethal hero loss at 2+ Health, never against a ghost. A mutual wipe uses Last Blow, crediting the finishing effect’s owner rather than merely the last attack declared. Start of Combat wipes remain ties. Read the card detail, hero panel and fight result; the picture guide covers all three at phone size.

The full-value-for-Fairies / half-for-everyone-else Ring candidate was tested separately and left out. Its four-seed bot pilot does not establish better carrier or Fairy outcomes, and hand play still rewards keeping a cheap Fairy on a Ring. This is not a balance verdict from the human games’ placements. See [engines build evidence](evidence/engines-build.md) for metrics, hand actions and verification.

## What still needs play

**Last-four watch item (engines follow-up Ask 2):** does the extra time with four or fewer heroes left feel tense or drawn out? Note whether a spent Last Stand creates a meaningful recovery decision or merely delays elimination. The reviewer measured about 1.4 extra last-four rounds without more lead changes in bot lobbies; that is a reason to watch human play, not a human pacing verdict.

No depth-bar UI run or full bench on this source, no real device test, and nobody has heard the sounds. Older bench numbers do not validate build 6's balance or strategic depth. Burner remains provisional and bot-tuned: try its bank-versus-buy decision by hand. Watch small-Bird flights, especially Old Tern and One Swallow beside larger buffed Birds; their low flight cost is accepted for now, not proof of balance. All six tribes are present, five per lobby; Bog folk and Hunters still need fresh human playtests. Tell us whether tribe commitment and positioning feel worth pursuing.

## What changed

**Ideation build 6 (historical damage rules, replaced above):** Harvest Supper from tier 3; the Last Four lifted the damage cap; Last Stand saves each hero once on 1 Health only in the last four; Last Blow decides mutual wipes by the side that struck last (finishing effects credit their owner; Start of Combat wipes remain ties). Bot strength unchanged from build 5.

**Ideation build 5 (historical damage rules, replaced above):** kin rewards and a visible tribe bonus, five tribes per lobby, one bot strength, Bird Eggs and Nest stats, the round toll and a picture guide.

**Ideation build 4:** all six tribes, with Bog folk and Hunters new; Mire, Quarry, Takes and Pack bring new lane choices, rewards and visible fight links. Crowded Scout shops keep full-size tap targets and scroll when needed.

**Ideation build 3 (historical damage rules, replaced above):** more of your bought shop tier, a price for early losses and a cap on late damage, bounded Acorn growth, clearer rules and Hex values, and phone recruiting controls that stay visible while reading a bird. Hero names stay readable on phone, with long words shortened in the small portrait plaque; tap the portrait for the full name. Hiring Fair stays at 6 gold. Fetch no longer copies a stripped printed Fetch. Still four tribes.

**Ideation build 2:** Oozes (Belly) and Birds (Fly South), so 4 of 6 tribes. Longer games, fewer runaway units and spells, a new opening choice in rounds 1 and 2.

**Ideation build 1:** the first build of the new game. New rules engine, Hedgerow and Fairies, neutrals, 10 spells, 9 heroes, the Woodcraft look, art on every card, sound, and the Scout button.
