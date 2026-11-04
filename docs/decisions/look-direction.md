---
id: look-direction
group: looks
size: big
headline: Pick the look we'll build every screen and card on
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#16
source: design-lab/main:docs/design-lab/r1/gauntlet-results.md
source: design-lab/main:docs/design-lab/PLAN.md
image: design-lab/main:docs/design-lab/r2/folk-print/shots/recruit-desktop.jpg | The shop in Folk Print
image: design-lab/main:docs/design-lab/r2/woodcraft/shots/recruit-desktop.jpg | The shop in Woodcraft
option: Folk Print
option: Woodcraft
option: A mix of both
option: Neither, try new ideas
---
We've been trying out different looks for the game's screens: the shop, the cards, fights and menus. Out of eight quite different looks, two came out on top in the first round, just one point apart (the later polish wasn't re-scored).

**Folk Print** uses bold, woodcut-style shapes printed on warm, unbleached paper, a bit like an old European folk-art poster. Cards are arched papercut shapes, Attack is a black shield and Health a red heart.

{image:1}

**Woodcraft** feels hand-carved, like a little tabletop diorama. The board is a wooden tray cut to the shape of the two rows, the buttons are leaves, and your gold is a pile of acorns.

{image:2}

Both are in the playable build too, so you can switch between them from the main menu (Look) and see them in a real game; tell us if you'd rather the build kept just one, or neither, for now. Two runners-up, Field Journal (a naturalist's notebook) and Storybook Ink (closest to the art style you picked), are in the details if you want a wider view.

**What we need from you:** which way do you want to go? One of the two, a mix (tell us what you like in each), or neither, and we'll try some fresh ideas.

**Why it matters:** whatever you pick becomes the starting point for every screen and card from here on.

We don't have a strong favourite: the two scored a point apart. Play a game in each and go with what you like.

## Detail

**Where this came from.** The design lab drew eight UI directions on the same mock game (the same shop, 4–3 board, hand, lobby and one combat moment). Four agent judges scored them blind from screenshots: a storybook art director, a casual phone player who has never played Battlegrounds, a high-MMR Battlegrounds veteran, and a UX and accessibility designer. Seven criteria, each 1–10 per judge, so 280 is the maximum.

| Rank | Direction | Total | In judges' top 3 |
|---|---|---|---|
| 1 | Folk Print | 226 | 4 of 4 |
| 2 | Hedgerow Woodcraft | 225 | 4 of 4 |
| 3 | Field Journal | 220 | 3 of 4 |
| 4 | Storybook Ink | 206 | 0, wildcard for 2 judges |
| 5 | Clean Arena | 180 | 1 |
| 5 | Night Wood | 180 | 0 |
| 7 | Woodland Nouveau | 179 | 0 |
| 8 | Chunky Cozy | 175 | 0, wildcard for 1 judge |

**More pictures** (open them in the gallery, or by path on `design-lab/main`):
- Field Journal's shop: `docs/design-lab/r2/field-journal/shots/recruit-desktop.jpg`. Graph paper, sticky tape, specimen labels and pencil notes that explain the rules where they apply ("B3 sits behind F3 & F4").
- Storybook Ink's shop: `docs/design-lab/r2/storybook-ink/shots/recruit-desktop.jpg`. Cream paper, one bold ink line, flat colours, and a bramble vine round the board; the closest to the decided art style.
- Folk Print in the playable game, at phone size: `docs/design-lab/game/folk_print_recruit_1688x780.jpg`.
- Woodcraft in the playable game, at phone size: `docs/design-lab/game/woodcraft_recruit_1688x780.jpg`. The in-game versions are simpler than the mock-ups; between looks, the board tray, the stat shapes and frozen shop offers differ the most.
- Combat and settings screens (round 3): `docs/design-lab/r3/<id>/shots/`.

**Rounds 2 and 3.** The top four got a second pass on the shop and cards (round 2), then a third on combat and a settings menu (round 3). Each fixed the judges' notes and borrowed ideas from the others: the tray cut to the 4–3 shape (from Woodcraft), plain notes on the screen such as "behind F3 & F4" and "then fight Old Tansy" (from Field Journal), stats told apart by brightness as well as colour (from Folk Print), and full keyword text on tap (from Chunky Cozy). Rounds 2 and 3 were not re-judged.

**Known weak spots on phone (round 3 notes).** Folk Print: card names and keyword chips about 10–11 CSS px. Woodcraft: combat-tray chips and tags about 8–9 CSS px. Field Journal: tribe tape and tier labels about 5–6 CSS px. Storybook Ink: one long name clipped, toggles 34 px tall.

**In the playable build.** Build 4 switches between Plain (the default, a simple dark-green look), Folk Print and Woodcraft from the main menu and the dev panel. The choice is remembered. These looks went in before you had seen the gallery, so they decide nothing. Question 16 also asks whether to keep them in the build, swap in another direction, or take them out.

**Fixed points.** The illustration style is already decided: Ink + flat colour, take B (1 Nov). The UI, card frames, menus and colours are not.

**The original question (prototype question 16):**
> "Design-lab looks in the playable build. The gauntlet's top two looks are switchable from the main menu and the dev panel ("Look: Plain | Folk Print | Woodcraft"), so you can compare them in real play: Folk Print scored 226 and Woodcraft 225. Plain stays the default. They went in before you'd seen the gallery, so they decide nothing. Keep them, swap in another direction, or take them out?"

**Sources.** `design-lab/main`: `docs/design-lab/r1/gauntlet-results.md`, `docs/design-lab/r1/scores.json`, `docs/design-lab/r2/<id>/note.md`, `docs/design-lab/r3/<id>/note.md`, and the gallery `docs/design-lab/gallery.html` (screens for every direction and round, plus an "In the playable build" section). In-game screenshots: `docs/design-lab/game/`. `proto/main`: `docs/prototype/OWNER-QUESTIONS.md` question 16 and `docs/prototype/PLAYTEST.md`.
