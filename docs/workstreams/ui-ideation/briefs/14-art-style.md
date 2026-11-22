# Art-style recommendations for Bramble's card art

From the orchestrator of `ideation/ui-ux` (an agent, not the owner). You are an art director for one task: recommend how Bramble's card art could be painted so that a screen full of cards is not garish. You write the recommendations and the prompts; a separate worker with an image tool will then make the sample pictures from your prompt file. Everything outside the quotation marks is my reading or proposal.

Bramble is an auto-battler in the style of Hearthstone Battlegrounds, set in a woodland of animal folk, fairies and oozes. Its art direction is lead and stained glass, for cards and the whole UI (`docs/design/art-direction/README.md`). The owner accepted today's card art on 17 Nov 2026 and is now open to changing its style.

## The owner's words (22 Nov 2026)

*[Transcribed from dictation: filler removed, punctuation added, "card out" read as "card art".]*

Earlier the same day:

> "the colours are incredibly noisy because of partially how the card art is done, right? Which limits us in terms of the contrast we're able to generate and what draws the eye. The eye just doesn't know where to go in these images, because the cards are so bright and draw so much focus."

After two rounds in which screen designers dimmed the art with filters:

> "Some of the artwork is the source of the colour issues, right? And just applying a filter on top to dial down the contrast and artwork doesn't really do it."

> "And the agents dealing with the card art being very garish by just putting darkening filters on it was not the goal. I can change the card art style, then give me style recommendations, right? Like an example of what the before and after card art would look like, or, you know, these cards must have a restricted colour palette on the background, you know, and the foreground character can have this, but the backgrounds can't be as busy or something of the sort, right? I'm okay with all of these as ideas or recommendations of adjusting colour tone. Those are all fine suggestions"

## Read first

- `docs/design/art-direction/README.md` and `docs/design/art-direction/card-art-recipe.md`: the approved recipe (the prompt, the shape guide, the run, the check).
- `tools/art/prompts/`: the prompt-file format the image worker needs (a fixed header, then numbered `filename -- description` items). `tools/art/prompts/glass-s1.txt` is a good example.
- Today's art: `assets/units/`. Look at a good spread of it at full size.
- Today's art in use, twelve or more cards on one screen: `/data/ui-ideation/baseline/shots/recruit-mid.png` and `/data/ui-ideation/concepts/E/p2r1/mid.png`. This is where the problem shows: judge the art as a crowd, not one card at a time.

Do not read `docs/workstreams/ui-ideation/council/` or the concept folders.

## What to write

1. **The diagnosis**, 120 words at most: what in today's art makes a full screen noisy. Be specific and measurable where you can (how many hues per card, how saturated the backgrounds are against the figures, how much of the pane the figure fills, how busy the leading is). Name three or four cards as evidence.
2. **Three style recommendations** that differ in kind, not degree. Each keeps lead and stained glass and the woodland theme, and each must still look joyful: the owner said dimming "sucked all the joy out of the scene". For each: a name, the rule in 60 words at most (written so a painter or an image prompt could follow it), what it costs (what today's art has that it gives up), and the change to the recipe's prompt, as exact wording.
3. **Sample cards.** Choose three existing units as samples: the most garish, an average one, and one that already works. The same three for every style, so the owner can compare.
4. **The prompt file** for the image worker, in the format of `tools/art/prompts/`: nine pictures (three styles by three cards), each a repaint of that card in that style, with the existing card's file named as the reference so the subject and pose stay. File names `<style letter>-<unit>.png`, styles lettered P, Q, R. Follow the recipe's shape guide and size so the pictures sit in the same hexagon window as today's.
5. **Your pick**, in two lines: which one you would recommend to the owner and why.

Write the recommendations to `docs/workstreams/ui-ideation/art-style/recommendations.md` (500 words at most, excluding the prompt wording) and the prompt file to `docs/workstreams/ui-ideation/art-style/prompts.txt`.

## Rules

Write only those two files and your scratch folder (`TMPDIR=/data/ui-ideation/tmp/art-style`; create it). No commits. Never run a delete command. Never read token or `auth.json` files. Start no subagents. Make no pictures yourself.

## Report

In under 150 words: the three styles in a line each, the three sample cards, your pick, and a **Disk** line (anything written outside the two files, with sizes).
