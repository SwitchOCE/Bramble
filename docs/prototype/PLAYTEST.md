# Playtest guide (overnight prototype, 4 Nov 2026)

Nothing here is final. The prototype exists so you can get your hands on the 4–3 board and the library's mechanics and react to them.

## Get it

From the desktop, in PowerShell:

```
scp -r alex@mini-optiplex:/data/bramble-builds/latest .
```

- **Windows:** unzip `Bramble-windows.zip` and run `windows/bramble.exe`. Keep `bramble.pck` next to it.
- **Android:** install `Bramble.apk`. It is debug-signed, so allow installs from unknown sources.
- `README.txt` in the folder says which build it is and which commits it came from.

## Play in 2 minutes

1. **New game** from the menu. You and 7 bots each start on 30 health.
2. **Recruit:** tap a shop unit, then Buy, or drag it onto the board or into your hand. Drag hand units onto a slot to play them. To sell, drag a unit onto the shop, or tap it and press Sell. Tier up, Refresh and Freeze are on the bar.
3. **The board** is 4 front slots (F1–F4) and 3 back slots (B1–B3), with the back row offset like bricks. The back row can't be attacked while any front unit lives. Empty slots stay visible.
4. **End turn:** every player's fight runs. You watch yours, with a log that names each hit and trigger.
5. The game ends when you are knocked out or one player is left.

**Dev panel:** the Dev button next to Menu, or the ` key. It can add gold, set your tier, spawn any unit (spawning three copies makes a triple), skip your fight, and show or set the seed so you can replay a game.

**Sandbox:** from the main menu. Build both sides by hand, override stats, and run the fight as many times as you like. Each run uses a new seed.

## What to try

- **The brick.** Put a tanky unit in front of a back-row carry and see who it protects. Does F/B with the offset read at a glance, on the phone too?
- **Nightshade** (Belladonna Sprite, Bitter Toad): halves the target's Health before the hit. Is that legible in the fight and the log?
- **Back-row tools:** Weasel Second, Fox Cub's Mark, Swarm, Peck. Do they make the back row matter?
- **Odd ones:** Hazel Dormouse (Bide), Marmot Lookout (Whistle), Mudwallow Toad (Mire), Garden Snail (Shell). Do they feel like woodland animals, and are they fun to play against?
- **Triples:** spawn three copies from the dev panel and play the golden one for its Triple Reward.
- **Pace:** how long a game takes, and whether the fights are too slow or too fast to follow.

## What's in and what isn't

*[Filled in at hand-over.]*

## Things the prototype just picked

These aren't decisions. They are things for you to react to after playing. The full list, with rule numbers, is in [SPEC.md section 9](SPEC.md#9-things-the-prototype-just-picked). These are the ones you'll notice in play:

- **A live lobby, not async snapshots.** All 8 players recruit each round, then all fights run. This departs from the decided [BRAMBLE] rule 2.1.4, which plans async snapshots. It was the quickest way to get a whole game running.
- **Opponents:** random pairing each round that avoids your last 3 opponents where it can. You see your next opponent at the start of recruit. An odd count fights a ghost.
- **The seed:** each game starts from a random seed, shown in the dev panel. Type one in to replay a game.
- **The Triple Reward is a random unit of tier+1** added to your hand. There is no Discover choice yet.
- **There is no Tavern spells column,** so the shop shows only units: 3, 4, 4, 5, 5 and 6 slots by tier.
- **No heroes or armour:** everyone has 30 health.
- **24 of the 40 pool units are plain filler** with placeholder names, sized to the power budget's stat line. They exist so shops and tribes work. They are not designs.
- **Placeholder art:** cards use the six Ink B folio portraits, one per tribe, so every unit in a tribe has the same face.
- **Landscape on Android.**
- **Rulings on the library's mechanics,** for example Nightshade halving once per attack and never killing, and a Whistle-only side being unable to attack, are listed in SPEC section 9. Questions where your call is needed are in [OWNER-QUESTIONS.md](OWNER-QUESTIONS.md).

## Telling us what you think

Reactions are directions, not decisions. Say what felt good, what felt wrong, and what you wanted to do but couldn't. Lessons from building it are in [LEARNINGS.md](LEARNINGS.md).
