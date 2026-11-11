# Journey lab: layout handoff

For a model building UI in the engine. This page sums up what the owner decided in the journey lab (11 Nov 2026) and where to find it. The lab is a set of static HTML mock-ups. They are reference only: copy the ideas, not the code.

## Where things are

| What | Path (under `docs/design-lab/journey/`) |
|---|---|
| **The layout to build on**: Clean Arena, layout B | `arena/` (`index.html`, `arena.js`, `arena.css`) |
| All four layouts side by side, in recruit and fight | `layouts.html` |
| Unit-shape study | `shapes/` |
| Shared hex masks, 4-3 board packing, stage scaling, game state | `shared/journey.js`, `shared/journey.css` |
| Same ideas in two other looks (left-right layouts) | `storybook/`, `nouveau/` |
| Hub page with links to everything | `index.html` |

To run it: start `python docs/design-lab/serve.py 8771` from the repo root, then open `http://localhost:8771/journey/`. URL options on the Arena page:
- `?layout=a|b|c|d` picks a layout variant (b is the default);
- `?stop=1..5` picks the area;
- `?mode=fight` opens the fight;
- `?static` turns off motion.

**Aspect ratio.** The lab is designed at 1920 × 1080 and only packs as intended at 16:9. At other sizes it packs poorly. That is a limit of the mock-up, not part of the design. The engine needs its own rules for other screen shapes.

## The owner's layout rules

These are decisions, not lab choices.

1. **Clean Arena's layout is the base.** The owner called it "the closest thing we've got currently to layout perfection". The direction is about the layout, not the Clean Arena visual style.
2. **Your board never moves.** It keeps the same place and size in recruit, fight and travel: "exactly static between phases". Everything else moves around it.
3. **Your board is centred:** horizontally when the layout is stacked (your board at the bottom, the market or opponent above it), and vertically when the layout is left-right.
4. **Every unit is the same size everywhere** (market, hand, your board, the opponent's board). In the owner's words: "when you move a unit from the shop to the player's board, it's going to be the same sized object."
5. **The board is a framed, contained zone**, clearly separate from everything else.
6. **The shop is its own zone, and its buttons (tier up, refresh, freeze) sit inside it.**
7. **Vertical space goes to the boards.** Use spare width for everything else.
8. **The leaderboard (other players) is on the right, vertically centred.** In a left-right split, the player is on the left, and the shop or opponent is on the right.
9. **Layout B was chosen** from four variants. The leaderboard is a slim strip of portraits on the right edge. Your hero and End turn sit beside your board on the right. Turn and route are top-left. The hand is left of your board.
10. **Unit shape:** a hex between the "mid hex" and the "tall hex", about 0.78 wide to 1 tall, with its points about a fifth of the height deep and slightly rounded corners. The back row of the 4-3 board tucks into the front row's points, so the board takes less height.
11. **The board is 4 front, 3 behind**, with the back row offset by half a slot, in every look.
12. **Placeholder art fit doesn't matter** at this stage. Layout does.

## How the Arena lab sets it up

These are the lab's own numbers, chosen by the agent and not decided. They show one way the rules above fit on a 1920 × 1080 screen.

- **Units:** 176 × 226 everywhere. The hex points up and down (`--hex-v` in `shared/journey.css`). Left-right layouts use the sideways version (`--hex-h`).
- **Your board:** an 820 × 510 frame, centred horizontally, sitting under the top zone. Its back row tucks up by 29 px.
- **Top zone:** the market in recruit (1160 wide, 510 tall, with the awning, gold and three buttons inside) or the opponent's board in fight (820 × 510). Your board does not move when this zone swaps.
- **Sides:**
  - left: turn and route at the top, the hand tray beside your board;
  - right: the portrait strip (96 wide, centred top to bottom), with your hero and End turn between your board and the strip.
- **Mouse hits:** each unit takes the mouse only inside its hex, so overlapping packed units never pick the wrong one.

## Status

Exploratory. The lab lives on the `design-lab/journey` branch and is not on `main`. Its portraits and unit text come from the ideation branch, so use them only as placeholders. They must not reach `main` without the owner's say-so.
