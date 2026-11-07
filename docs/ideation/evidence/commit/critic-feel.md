# Critic: feel, readability and fit with the owner's notes

Lens: tribe fantasy in play, readability (one picture, no hidden geometry, no "their stats"), fit with the owner's direction. Numbers are left to the costing reviewer.

## Verdicts

- **Designer A (tribe-count payoffs): workable.** Each count grows out of the tribe's own mechanic, which is the right instinct. But it leaves the generic 40% alone (A says so itself), its superlinear swings get decided at the bell, and three cards rely on hidden geometry ("run", "Ooze next to this", "across from a Nest").
- **Designer B (generic sources favour your tribe): strong.** It is the only draft that moves the 40% of stats that actually decides fights, and it does so with text a newcomer reads in one glance ("those that share a tribe with it"). Weak spots: Nest-sitters becoming Birds, and a tribe pool close to Battlegrounds' "your Undead have +1 Attack this game".
- **Designer C (capstones): weak as a package, with two good parts.** The flavour is the best of the three (Peg Powler, elf-shot, rooks in session). But all six cards are anti-giant tech, which punishes the owner's named "one or two really big units" comp instead of rewarding commitment. Four of them are the hardest texts on the table to read. Its Nest Egg rule and its Hiring Fair are the best Bird fix and the best Hiring Fair fix in any draft.

## Recommended set (smallest I'd ship)

Core:
1. **Stand Behind Me** (B): "Aim at a front-row unit: the units behind it gain +1/+1, or +2/+3 if they share its tribe." This is positioning text the owner asked for ("the units behind this"), and the kin clause turns the most-cast card in the game into a tribe card.
2. **Harvest Supper** (B), reworded so the game keeps one permanence word: "Aim at a unit with a tribe: your units of that tribe gain +1/+1 permanently, including ones you get later." It is the one new rule, a per-tribe pool shown on the tribe icon. It rewards the 7th unit and lets a late tier 6 arrive already big. To set it apart from Battlegrounds, keep the pool fed by this spell and by tribe actions (item 6), and print no flat "this game" auras.
3. **Hiring Fair** (C's wording): "If 4 or more of your units share a tribe, one of the three choices is of that tribe." A's "all three" feels scripted.
4. **Birds: C's Nest Egg rule**: "While a Bird is away, the Egg on its Nest fights with that Bird's Attack and Health, and no text." It keeps Fly South's bargain and Nests, and the board stops looking empty. Pair it with **The Seven Whistlers** under its own name, rewritten with C's count but read in whole numbers: "Start of Combat: the enemy with the most Attack loses 2 Attack and 2 Health this combat for each Bird you have, on the board or away" (golden: 4 and 4). Eighths are arithmetic, not a picture.
5. **Oozes: B's Moss Ooze** ("When a spell gives one of your Oozes stats, the units inside it gain them too") and **A's Elder Ooze** ("Whenever a unit comes out of one of your Oozes, it gains +1/+1 this combat for each unit that has come out this fight"). Together they make the Belly the best place to spend a spell and pay for depth.
6. **One tribe-action feeder per tribe**, all from B, written as "permanently": Fieldfare (a Bird comes home), Crested Newt (a Mired enemy faints), Stoat Captain (first Take), Hedgerow Elder (a Stash is played), Great Ooze (a unit is bought into a Belly). Growth tied to the tribe's own action, as the owner liked in 02h.

Optional: A's **Fairy Monarch**, with only its first sentence ("Rings under your Fairies give double their stats"). It does B's Ring rule as card text and gives a tier 6 a reason to exist. A's **Laird** line ("After each Take this fight, your Hunters gain +1/+1 this combat") is clear and suits the Pack.

Not design, but first: fix the bot priors (`strategy_fit`, `power`) for Oozes and Birds, or the bench will mislead.

## Cut or rename

- **Cut B's "a unit on a Nest is also a Bird".** A hedgehog that is secretly a Bird breaks the type line (rulebook 5.2.1) and makes the Seven Whistlers count invisible. The Egg rule does the same job honestly.
- **Cut B's Ring rule line** if the Monarch ships. A keyword that doubles itself for one tribe is a hidden multiplier.
- **Cut C's Reynard.** "A quarter of what its quarry had gained on top of its card" is exactly the "their stats" problem playtesters hit, and long-range reach has no picture.
- **Cut C's Peg Powler as written.** Lock passing, the maker changing and nearest-by-slot-distance are three hidden rules on one card. If the bog wants a capstone, keep the name and have the lock pass only to "the Bog folk behind this".
- **Cut C's Bound-Beater and A's "run".** Both count the F1-B1-F2-B2 zigzag, the same geometry newcomers fail on ("behind F2").
- **Cut A's Figgy Duff and Old Crane.** "Ooze next to this" across staggered rows is unclear. Growth inside a Belly or on Birds away is growth nobody can see, and it rewards standing still each End of Turn.
- **Names.** None of the proposed names copies a Hearthstone card exactly. Buzzard echoes Starving Buzzard, but it is a plain animal and fine. Peg Powler and the Seven Whistlers are clean folklore. Keep "The Seven Whistlers" over "Parliament of Rooks": it is the Birds' existing identity card, and a rename loses the folklore of birds calling in the night.

## Per-card notes

**A**
- Standing Committee: a graded run is better than "if all 7 touch". But the run is a new term and has to be traced along the zigzag.
- Old Mother Mast: Acorns that scale with commitment is good economy tied to an action.
- Seven Whistlers (A): "across from a Bird or Nest" from the back row is unclear, and -49/-49 decides the fight before any swing.
- Buzzard: an aura on whoever sits on a Nest reads well. A fallback if the Egg fails.
- Peat King (A): "each Mired enemy loses Attack per Mired enemy" is readable, but dropping the Peatlings loses Bog folk's summon identity.

**B**
- Moss Ooze: the cleanest new card in any draft.
- "For the rest of the game": change it to "permanently" everywhere (owner, 27d).

**C**
- Elf-Shooter: readable ("loses that Ring's stats"), and it is good that Shy pulls against it. A fine replacement for the duplicate-named tier-6 Belladonna.
- Bottomless Pot: great fantasy, but "no other Ooze" is a hidden end condition; if kept, release only "when this dies".
- Parliament: the count of Birds away is the right idea. Use whole numbers.

## New rules count

My set adds one rule (the per-tribe pool) and one rule change (the Nest Egg), and no keywords. A adds one term and one swap. B adds the pool plus two keyword lines. C adds the Egg plus six bespoke engine behaviours.
