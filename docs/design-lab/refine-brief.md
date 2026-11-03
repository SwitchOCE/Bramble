# Refine brief (design lab, round 2)

Round 1's gauntlet picked four directions to go on: Folk Print, Hedgerow Woodcraft and Field Journal, plus Storybook Ink as the wildcard. The results, the judges' notes and the ideas worth borrowing are in `r1/gauntlet-results.md`. You refine one direction; your message names which one and its fix list.

Read first: `r1/gauntlet-results.md`, your own `r1/<id>/note.md`, and `generator-brief.md`. The generator brief's ground rules, asset rules and render tool all still apply.

## What to make

Everything goes in `docs/design-lab/r2/<id>/`. Touch nothing else, and don't commit: the orchestrator commits.

1. Copy what you need from `r1/<id>/` into `r2/<id>/`: the recruit and cards pages, plus your CSS, JS and assets. Leave `r1/` as it is: it is the record of round 1.
2. Refine **only `recruit.html` and `cards.html`**.
   - Fix every item in your fix list.
   - Borrow at least two of the "Ideas to borrow" in the results, done in your direction's own idiom. Copying another direction's look doesn't count. For example, a fixed before → halved → after breakdown can't go on recruit, but a brick that reads in half a second and plain-language notes can. Cards could take shape-coded stats that differ in brightness, or keyword chips with the full text on tap.
   - Keep what the judges liked. Don't sand off what makes the direction distinct.
3. Render both pages at both sizes into `r2/<id>/shots/` (`recruit-desktop.jpg`, `recruit-phone.jpg`, `cards-desktop.jpg`, `cards-phone.jpg`). Look at your shots, and fix what's broken before you finish. Check the phone shots especially: names, stats and buttons must be readable, and touch targets about 44 CSS px or more.
4. `r2/<id>/note.md`, at most 12 lines:
   - each fix-list item and what you did about it;
   - each borrowed idea, named with the direction it came from;
   - anything you kept on purpose despite a judge's note, and why.

## Limits

- The machine is shared and not powerful. Other agents are rendering too, so render only when you need to look. One Chromium at a time.
- Time box: about 30 minutes. Finish with a short report: files made, what didn't work, and any gotcha worth logging.
