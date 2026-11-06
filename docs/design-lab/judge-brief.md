# Judge brief (design lab gauntlet, round 1)

You are one of four judges comparing 8 UI directions for Bramble, a Hearthstone Battlegrounds-style auto-battler set in an idealized European woodland of animal folk, fairies and oozes. Its core difference is a two-row board: 4 front slots and 3 back slots, the back row offset by half a slot like bricks. The back row can't be attacked while any front unit lives. The game targets Windows and Android phones, in landscape.

Your persona is in your message. Judge as that person would, honestly, including your own taste.

## What you get

`docs/design-lab/blind/<letter>/` for letters A–H. Each folder holds screenshots only: `recruit`, `combat`, `menu`, a fourth screen, `cards` and `moodboard`, each at `-desktop.jpg` (1920×1080) and `-phone.jpg` (a phone in landscape, 844×390 CSS px at 2× scale). Read the images. Every direction shows the same mock data: the same shop, board, hand, lobby, hero card (Belladonna Sprite) and combat moment (a Hornetling attacking a boar marked with Nightshade, which halves its Health before the hit). Small inconsistencies in that mock data aren't the direction's fault: ignore them.

Don't look for the directions' names or notes, and don't open anything else in `docs/design-lab/`. You judge what you see.

## Score each direction, 1–10

1. **Phone readability:** on the phone shots, can you read attack, health, tier, gold and what each button does at a glance? Are touch targets big enough?
2. **The board:** is the 4–3 brick obvious? Front vs back, which back slot sits behind which front slots, empty slots?
3. **Cards:** hierarchy and legibility at full, shop and board size; does the keyword (Nightshade) read?
4. **Combat clarity:** can you follow who hits whom, the halving, the damage and the log?
5. **Distinctiveness:** would you recognise this game from one screenshot?
6. **Woodland feel:** does it feel like an idealized European woodland?
7. **Your taste:** as your persona, would you want to play this?

Also one line, not scored, on **fit with the decided illustration style**, Ink + flat B (bold even ink lines, flat colour fills, no gradients, no painterly rendering, cream paper). Some directions ignore it on purpose: that isn't a fault.

## Output

Your final message, in this shape:

```
JUDGE: <persona>
<letter> | phone | board | cards | combat | distinct | woodland | taste | total
...one row per letter...
NOTES
<letter>: best thing; worst thing; one change that would most improve it; ink-B fit (one line)
...
TOP 3: <letters in order>, one line on why
WILDCARD: <one letter outside your top 3 you'd most like to see developed, and why>
STEAL: <the 2–3 best individual ideas from any direction, by letter, that should be borrowed by others>
```

Be specific: point at what's on screen. Time box: about 25 minutes.
