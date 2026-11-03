# Generator brief (design lab, round 1)

You make one visual direction for Bramble's UI. Your direction's id, name and idea are in `directions.md`; your message names which one is yours. Read first: `PLAN.md` (this folder), `directions.md`, `fixture.json`, `/home/alex/code/Bramble-design/CLAUDE.md`, `docs/design/direction-summary.md` (the game in brief) and `docs/design/owner-notes/2026-11-01-art-style-decision.md`.

## What to make

Everything goes in `docs/design-lab/r1/<id>/`. Touch nothing else, and don't commit: the orchestrator commits.

1. `palette.json`: 8–14 named colours with hex and what each is for (background, card, ink, tribe accents, gold, health, attack, statuses such as Nightshade and golden, positive and negative). Check text contrast on the colours you put text on (WCAG AA for body text).
2. Screens, as HTML/CSS pages, all built from `../../fixture.json`'s data (copy the values in, or load it with a small script). Use system fonts or Google Fonts only. No external images except your own assets and the Ink B portraits in `docs/folio/art/web/trials/`.
   - `recruit.html`: the recruit phase. The shop (4 offers, one frozen), the 4–3 brick board (the back row offset by half a slot, the slots labelled or obvious, empty slots visible), the hand, gold, tier and tier-up cost, refresh and freeze buttons, end turn, and a compact lobby strip with the next opponent marked.
   - `combat.html`: the fixture's combat moment: both boards, the attacker and target, the Nightshade halving shown clearly, a damage number, and a combat-log line. Speed and skip controls.
   - `menu.html`: the main menu (title "Bramble" is a code name: use it but keep the title area replaceable).
   - `standings.html` or `settings.html` or `collection.html`: one more screen of your choice.
   - `cards.html`: the hero card (Belladonna Sprite) at full size, plus the same card at shop size and at board size, a golden version, and one plain unit, side by side. Card anatomy to show: name, tier, attack, health, type line, rules text with the keyword visible, tribe.
   - `moodboard.html`: one page from your own material: swatches, type samples, textures or patterns, icon samples (gold, tier, health, attack, refresh, freeze), and crops of your screens. No scraped reference art.
3. Render each page with `node docs/design-lab/tools/render.js <page.html> <out_prefix> both`, which writes `<out_prefix>-desktop.jpg` (1920×1080) and `<out_prefix>-phone.jpg` (844×390 CSS px at scale 2, phone landscape). Put the JPEGs in `r1/<id>/shots/`. Each page must work at both sizes: on the phone the board, shop and buttons must still be usable by thumb (touch targets about 44 CSS px or more). Look at your own screenshots (Read the JPEG) and fix what's broken before you finish. The render script reports any file that failed to load: fix those.
4. Images: directions 1–5 reuse the Ink B portraits in `docs/folio/art/web/trials/ink-b-*.jpg` for card art. Directions 6–8 may make up to 3 images with Codex in their own style:
   `codex exec --skip-git-repo-check -s workspace-write -C <your r1/<id>/assets dir> "<prompt asking Codex to generate the image with its image tool and save it as <name>.png in the current folder>"`
   Run them one at a time, then convert to JPEG (`convert x.png -quality 85 x.jpg`, keep only the JPEG). If Codex fails, use CSS shapes and say so in your note.
5. `note.md`, at most 10 lines: the idea in one line, who it's for, what makes it distinct, the cost to build it in Godot 4 (Control nodes and Themes, nine-patch frames, shaders, animation), and the risks (readability, animation load, small screens, how it would fit the Ink + flat B illustrations).

## Ground rules

- The fixture's units and text are the only content. Don't invent units or mechanics.
- Readability first: a player must read attack and health at board size on a phone at a glance.
- The 4–3 brick board is Bramble's core difference. Make the stagger and the front/back rows obvious.
- Lean into your direction's idea. Being distinct matters more than being safe; the judges compare all eight.
- The machine is shared and not powerful. Render only when you need to look, not after every edit. One Chromium at a time.
- Time box: about 45 minutes. Finish with a short report: the files you made, anything that didn't work, and any setup problem or gotcha worth logging.
