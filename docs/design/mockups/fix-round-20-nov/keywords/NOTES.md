# Keyword looks on cards (fix round item 10)

PROPOSAL, not decided. Made 20 Nov 2026 for the fix-round recommendation page. The fix round is based on `dev` (origin/dev 5d697e07). Mouse and Pigeon cards on these pages use dev's numbers and keywords; the other tribes barely changed on dev.

The owner: "In the same way that Hearthstone Battlegrounds has different visual ways of rendering cards for different keywords, like Windfury cards have a little wind effect and Taunt cards have a shield around them that makes it obvious that they're taunting, we need some sort of visual indicator to accomplish the same thing."

## Pages

Open in a browser from this folder (`assets` and `units` are links to the game's `assets/glass` and `assets/units`). Every page has a control bar: **Looks** On / Off (Off is today's build: round marks only, and dev's "Renown N" pill), and **Motion** Loop / Still.

| Page and query | Shows | PNG (in `scratchpad/after/keywords/`) |
|---|---|---|
| `sheet.html?view=board` | All 12 first-round keywords, each alone on a real card, at board size (140 x 250) | `k01-sheet-board.png` |
| `sheet.html?view=set1` | Guard, Attacks twice, Cleave, Overrun, Pile on, Fury at board size and at 1.6x | `k02-sheet-set1.png` |
| `sheet.html?view=set2` | Molt, Reserve, Sortie, Stiff Upper Lip, Thorns, Root at board size and at 1.6x | `k03-sheet-set2.png` |
| `sheet.html?view=stack` | Two and three at once (stacks that happen on dev), board size: spaced out, then 12 px apart as on the board | `k04-sheet-stack.png` |
| `sheet.html?view=stack16` | The same stacks at 1.6x | `k05-sheet-stack-1.6x.png` |
| `sheet.html?view=spent` | Molt, Root and Stiff Upper Lip ready and used this fight, at both sizes, plus Guard with a used Root | `k06-sheet-spent.png` |
| `sheet.html?view=dev` | New on dev: Hand-me-down (alone, with Guard, and the receiver's look), Pile on 1, Renown on a slot (with a unit, empty, with Cleave and Charge, with Supply), at board size and 12 px apart | `k10-sheet-dev.png` |
| `sheet.html?view=dev16` | The same at 1.6x | `k11-sheet-dev-1.6x.png` |
| `board.html?screen=fight` | Mid-fight on dev's cards, a mixed board each side (4 front, 3 back): Molt and Root used, a Hand-me-down received, Renown on three slots, Charge pips | `k12-board-fight-dev.png` |
| `board.html?screen=recruit` | The recruit screen on dev's cards: shop, board and hand (Reserve and Hand-me-down in the hand) | `k13-board-recruit-dev.png` |
| `board.html?screen=fight&looks=0` | The same fight as dev draws it today: marks, pips and Renown pills only | `k14-board-fight-dev-marks-only.png` |

`k07-board-fight.png`, `k08-board-recruit.png` and `k09-board-fight-marks-only.png` are the first round's boards on main's cards (Shrew Harrier, Kettle-drummer, Brigadier: gone on dev). `board.html` now draws k12 to k14 instead; k07 to k09 are superseded and can go.

The code is `kw.js` (one function per keyword, drawn in the card's own 560 x 1000 units so it scales with the card; Renown and the pips too), `kw.css` (the loops, marks and pips) and `data.js` (the real cards used). The cards, frames and screens are the playable build's mock-up pieces from `docs/ideation-track-2/mockups/`, unchanged. `cand/` holds three candidate pictures from the art round for dev cards with no art in the game yet (Thimble Sentinel, Hayloft Aunt, Drill-sergeant); each is a whole card picture used as the art layer under the real frame. Only Thimble Sentinel and Hayloft Aunt are shown.

## The idea

Each keyword gets its own place on or around the card, so two or three never cover each other, and each is made of lead lines and lit glass like the frame:

| Keyword (game's name) | Look | Where |
|---|---|---|
| **Guard** | A leaded amber ward round the whole card, panes and studs, thicker over the roof, glowing. The strongest look, as Taunt's shield is in Battlegrounds | Behind, all round |
| **Attacks twice** | Two whirls of pale glass shards wrapped round the card; the far side goes behind it, the near side crosses the art. *No card has it on dev* (Brigadier and Kettle-drummer are gone); the look is kept for when one does | Round the middle |
| **Cleave** | An axe blade of red glass on each long side: it hits the units beside the target | Middle of both sides |
| **Overrun** | Two red-glass chevrons above the crest, pointing at the enemy | Above the crest |
| **Pile on N** | Two linked rings on each long side; two Pile on units side by side look chained. On dev it is numbered: the number goes in the round mark ("Pile on 1"), as Fury's does, and the look stays the same | Lower middle of both sides |
| **Fury N** | Glass flames rising from both lower corners, outside the Attack and Health discs. Taller for a bigger Fury (1, 2, 3+) | Lower corners |
| **Molt** | A pale, frosted husk over the roof, split at the crest and lifting away | The roof |
| **Reserve** | A lancet arch of pale blue glass behind the top of the card: a niche it waits in | Behind, over the top |
| **Sortie** | An arrow of sky-blue glass arcing over the crest: it flies over the front row | Above the crest |
| **Thorns N** | A lead bramble stem down each long side with red-tipped thorns pointing out | Both long sides |
| **Root N** | Lead roots with green glass knots gripping the bottom point and running up the lower edges | Bottom point |
| **Hand-me-down** (new on dev) | A ring of green glass tied round the Attack disc, with a bow and a ribbon tail trailing out of the card: its Attack is handed on when it dies. The unit that receives it gets the green bow pinned over its Attack disc for the rest of the fight (no ring, no mark) | Round the Attack disc |
| **Renown N** (new on dev, on a slot) | A gold glass star medallion with the number at the slot's foot, and laurel sprays up its lower edges, longer for more Renown (1-2, 3-5, 6+). It is the slot's, so it looks the same with a unit on it or none, and is drawn over the cards as dev's pill is. On the enemy's board it sits at the slot's top, the side away from you, so it never meets Overrun or Sortie. **It replaces dev's "Renown N" pill** at the slot's head | The slot's foot |
| ~~**Stiff Upper Lip**~~ | **Gone on dev.** It was a ring of gold glass bound round the Health disc, with a clasp. Still shown on the sheets (labelled "gone on dev") in case it comes back | Round the Health disc |

**Used this fight** (Molt, Root; Stiff Upper Lip on main): the look turns grey, cracked and faded to 0.4, the same fade the game already gives a used mark (`KeywordStyle.SPENT_ALPHA`). The mark dims as today. Hand-me-down needs no used state: the unit is dead when it fires.

**On the enemy's board** the two looks that point (Overrun, Sortie) turn to point down, at you, and Renown moves to the slot's top.

**The round marks are kept**, unchanged (up to 3 under the card, the third says "+N" when there are more). They carry the numbers (Fury 3, Thorns 8, Root 2, Pile on 1), match the tooltip's marks, and cover the terms that have no look (Grudge, Squire, Seed and the rest). Hand-me-down's mark uses dev's icon.

**Charge and Supply pips need nothing new.** Dev already draws them as lead-and-glass pips just over the stat discs (round for Charge, square crates for Supply), dimmed when used; they are counters, not keywords, and read clearly at board size (k10, k12). These pages draw them as dev does. The only check: Hand-me-down's ring sits just under the pips' row and they don't overlap at any size shown.

**In-game text:** none new. The pages use only the game's own keyword names, spelled as the cards and keywords.json spell them (dev's for Hand-me-down and Renown).

## Stacks checked

Real stacks from dev's cards and auras: Hedge Knight with Dame of the Old Sett (Guard, Fury 3, Overrun); Lone Hawthorn with The Old Hedge (Guard, Thorns 8, Root 1); Thimble Sentinel (Guard, Hand-me-down); Husk Sentry (Guard, Molt); Hedgerow Scout next to Drill-sergeant (Hand-me-down, Pile on 1); Wing Commander on a Renown 3 slot (Sortie, Renown); Flying Ace on a Renown 3 slot (Cleave, Charge 2, Renown); Sentry on a Renown 2 slot (Supply 6, Renown); and a four-at-once stress case (Hawthorn Warden on a Guard post with Skin-shedder and Holly Knight: Guard, Root, Molt, Thorns), where the marks show "+2".

## The keywords no card uses (no mock-up)

On dev these are Divine Shield, Reborn, Venomous and Stealth, and now Attacks twice (its look is above).

- **Divine Shield:** a clear sheet of pale gold glass in large diamond quarries over the whole card face, with a bright rim; it shatters into falling shards on the first hit.
- **Reborn:** a white-glass ghost of the card's outline standing just behind it, offset up; gone once used (Molt's husk is its tribe-flavoured cousin).
- **Venomous:** a drop of dark green glass hanging from the crest, with green lead veins running down the roof. (Changed from the first round's ring on the Attack disc, which Hand-me-down now uses.)
- **Stealth:** the card's glass turns smoked and dim, the lead left dark, until it attacks.

## For the owner to choose

1. **Keep the round marks?** Kept here, because they carry the numbers. The other way: drop the mark for any keyword that has a look, and keep marks only for numbers and terms with no look.
2. **Renown as a medallion at the slot's foot** in place of dev's "Renown N" pill at the slot's head. The pill covers the crest and art; the medallion sits in the gap under the card.
3. **Attacks twice crosses the art**, as Battlegrounds' Windfury does (moot on dev until a card has it).
4. **Reserve only matters in the hand.** Shown here wherever the unit has it. The other way: hide the arch on the board, where Reserve does nothing.
5. **Molt's husk is the biggest look after Guard.** Fine if Molt should stand out; otherwise make it smaller.
6. **Looks reach into the 12 px between cards.** Two Guards side by side touch; two Pile on units' rings meet (meant: they look chained). Renown's medallion reaches into the gap between the back-row cards below.

## What I could and couldn't check

- **Motion: not judged.** The loops (whirls drift, flames flicker, Overrun's chevrons rise, Molt's husk shimmers, Cleave's blades glint, Sortie's arrow flows, Hand-me-down's ribbon sways) run on the pages with `motion=1`, and a shot with motion on differed from a still one, so they move. I can't judge from stills whether they feel gentle or distracting (`docs/AGENT-BLIND-SPOTS.md` item 1). All PNGs are stills (`motion=0`).
- Readability at board size I judged from the 1920 x 1080 shots only, not on the owner's screen.
- Not checked for colour-blind players. Each look differs by place and shape as well as colour: Guard and Renown are both gold but one is round the card and one a star under it; Hand-me-down and Root are both green but one rings the Attack disc and one grips the bottom point; Cleave and Thorns are both red but blades against a row of thorns.
- The looks are SVG with soft glows. In Godot they would be a texture layer per keyword over the card, drawn in fixed places; the cost of many glows on a full board is untested.
- Dev's Mouse and Pigeon numbers and keywords were read from `/data/worktrees/fix-round-dev/src/content/*/units.json`; the art for those cards is the same file on main and dev.
