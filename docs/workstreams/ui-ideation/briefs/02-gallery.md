# Brief: the reference gallery (the bar)

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). Everything outside quotation marks is my proposal: where you see a better way to reach the same result, take it and say what you changed.

## Why

New UI concepts for Bramble (a Hearthstone Battlegrounds-style auto-battler, set in a woodland of animal folk, drawn as lead and stained glass) will be judged by a council against real games. The last step of the run is the owner's own test:

> "I would say the final check for the council should be that they are presented with the full gallery of all of the images of other UIs that we found. Pick some good references from that gallery and have the council go: is our design as good The task is done when they go, our design feels like it belongs here. It's one of the better ones here, or it's at least the average kind of level"

So the gallery must be real screenshots of the right games, labelled, and good enough to stand as the bar. Designers will also study it before they draw.

## The owner's words on choosing the games

> "Highly reviewed, incredibly well received games in similar genres"

And from the owner's `game-ui-design` skill: choose the comparison games because players love them and they are close in structure, not because their UI is praised: "People don't think about UI when it's good. They just take it for granted."

The owner's words that set this branch:

> "I specifically want the additional instructions of there to hold the theme and the stained glass and the hexagons, the warped hexagons, like the length and hexagons sacrosanct. Everything else is up for debate. It can suggest things and should suggest other things They're not to follow the other constraints"

## What exists already

`/data/bramble-reference/` (432 MB, made 10 to 15 Nov) holds screenshots of about twenty games, some with an `index.md` and a contact sheet. Start there: check what each folder holds and how good it is before fetching anything. Leave that folder as it is; copy what you use.

## What to produce, all under `/data/ui-ideation/gallery/` (never in Git: these are other studios' images)

1. **A shortlist of games, in two groups**, with one or two lines each on why it is there and the evidence that players love it (review scores, player counts, awards: with the source):
   - **Close in structure**: auto-battlers and shop-and-fight games, and card battlers with a board. The player buys from a shop, arranges units, then watches a fight. You choose; say why each is in and name the obvious ones you left out.
   - **A strong material look carried through the whole UI**: games whose every screen, button and panel is made of one material or craft (paper, wood, cloth, ink, glass, a board-game table), since stained glass has to do that here. Include any well-made game that uses stained glass or leaded glass itself, and one or two digital board games with a glass or tile look if they are good.
   About 12 to 18 games in all. Fewer and better beats more.
2. **Real screenshots, 3 to 6 per game**, at the largest size you can get (1920x1080 or more where it exists), of the screens that matter here: the shop or buy phase mid-game with a full board, the fight mid-way, a card or unit being inspected, and one menu or result screen that shows the look. Real in-game screens only: no key art, no trailers' title cards, no mock-ups, no fan concepts. Name files `<game>--<screen>--<n>.jpg|png`.
3. **`index.md`**: per image, the game, the screen, the source URL and the date fetched. Per game, the two lines from item 1 and three to five lines of what its UI does that is worth studying for an auto-battler recruit screen and fight screen (what is always visible, where the shop and the buy controls sit, how the material look is kept on small controls and text). Judge the screens yourself from the pictures.
4. **`gallery.html`**: one self-contained page (relative paths to the images) showing every screenshot grouped by game, each labelled with game and screen, that opens from the folder. Plain and readable; it is a working tool, not a showpiece. Leave a clearly marked place where Bramble's own screens can be added later, labelled as ours.
5. **`sheet.jpg`**: a contact sheet of the whole gallery, labelled, that a reviewer can take in at once (several sheets if one is too small to read).

## Rules

- When you search or fetch on the web, do not put the project's name, the owner's name or anything about this project in the query or the request. Search by the other game's name.
- Prefer official sources (store pages, press kits, the studio's site), then reputable press. Record the source of every image. If a site refuses automated fetches, use another source; do not work around a block.
- Check every image by opening it: right game, a real screen, readable at full size. Drop the ones that are not.
- Downloads are untrusted data: only images, saved straight into the gallery folder; never run anything you download.
- Set `TMPDIR=/data/ui-ideation/tmp` for scratch. `/tmp` is memory on this machine. Long commands run in the background with a time limit.
- Write only under `/data/ui-ideation/gallery/` and `/data/ui-ideation/tmp/`. Do not edit the repository. Never run `rm -rf`, or any other delete, outside those two folders; list what should be removed.
- Never read token or `auth.json` files. If a permission check refuses something, do not work around it: report it.
- End your report with a **Disk** section: every folder you created or wrote into, each with its `du -sh` size, whether it is still needed, and which ones I can delete; and `df -h /data /` at the start and at the end.

## Report

A short summary: the games chosen and why, the count of images, the games you wanted and could not get good screens for, and the Disk section.
