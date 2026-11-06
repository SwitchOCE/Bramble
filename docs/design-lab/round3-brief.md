# Round 3 brief (design lab): combat and settings

Round 2 refined the recruit screen and cards of the four directions that went on. Round 3 does the same for two more screens: **combat**, and a **settings** menu. You work on one direction; your message names it.

Read first: `r1/gauntlet-results.md`, your own `r1/<id>/note.md` and `r2/<id>/note.md`, and `generator-brief.md`. The generator brief's ground rules, asset rules and render tool still apply. Set `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64` and `NODE_PATH=/home/alex/.local/share/bramble-tools/node_modules` when you render.

## What to make

Everything goes in `docs/design-lab/r3/<id>/`. Touch nothing else, and don't commit: the orchestrator commits.

1. Start from your round 2 files (`r2/<id>/`) for the shared CSS and JS, and from `r1/<id>/combat.html` for the combat page. Copy what you need into `r3/<id>/`.
2. `combat.html`: the fixture's combat moment, in your round 2 style.
   - **Show each hit as a fixed breakdown.** Health before, then halved by Nightshade, then after the hit, with the damage number. This was the idea most judges wanted, from Clean Arena's panel, Folk Print's numbered steps and Field Journal's crossed-out strip. Do it in your own idiom.
   - Make the attacker and the target unmistakable. Put any "attacking" label on the attacker, never on an empty slot.
   - Show the 4–3 brick on both boards the way your round 2 recruit board does.
   - Include a combat log line and speed and skip controls.
   - Fix anything the round 1 judges said about your combat screen (see `r1/gauntlet-results.md` and the gallery notes).
3. `settings.html`: a settings menu in your style. Include:
   - sound and music volume;
   - combat speed (1×, 2×, 4×) with "skip my fights" and "skip others' fights" toggles;
   - text size, with a preview of a board-size card at each size;
   - a colour-blind aid toggle that shows how your stats and tribe marks change;
   - language, as a placeholder;
   - a back button.
   No account, store or social features: they're undecided.
4. Render both pages at both sizes into `r3/<id>/shots/` (`combat-desktop.jpg`, `combat-phone.jpg`, `settings-desktop.jpg`, `settings-phone.jpg`). Look at your shots and fix what's broken. On phone, text should be at least about 11 CSS px and touch targets about 44 CSS px. Say in your note where you fall short.
5. `r3/<id>/note.md`, at most 10 lines: how you showed the breakdown, what you fixed from round 1, which ideas you borrowed and from which direction, and anything you'd flag.

## Limits

- The machine is shared and not powerful. Other agents are rendering too, so render only when you need to look. One Chromium at a time.
- Time box: about 30 minutes. Finish with a short report: the files you made, anything that didn't work, and any gotcha worth logging.
