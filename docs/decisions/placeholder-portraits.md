---
id: placeholder-portraits
group: looks
size: small
headline: Stand-in card pictures: one portrait per tribe, or flat colours?
source: proto/main:docs/prototype/OWNER-QUESTIONS.md#5
image: proto/main:docs/prototype/screens/recruit_1688x780.jpg | The shop and board in the playable game: units of one tribe share a face
option: Keep the shared portraits
option: Go back to flat tribe colours
suggested: Keep the shared portraits
---
Most units don't have their own art yet. So in the playable game, cards borrow five of the character portraits we drew when you chose the art style, one per tribe. That means every unit in a tribe wears the same face: the Hedgehog Twin, the Field Vole and the Marmot Lookout are all the same dormouse, for example. Tribes without a portrait, such as Birds and Hive, show the unit's initials instead.

The plan had said flat tribe colours rather than pictures; the portraits went in instead.

{image:1}

**What we need from you:** keep the shared portraits as stand-ins, or go back to plain colours?

**Why it matters:** it's only how the prototype looks while there's no real art. It changes nothing in the finished game.

We'd suggest keeping them: a face says more about a tribe than a colour does, as long as you know the faces are borrowed.

## Detail

- **What's in the build:** five Ink B folio portraits, by tribe (`TRIBE_PORTRAITS` in `proto/main:src/ui/ui_theme.gd`): Fairies (fairy), Oozes (ooze), Hedgerow folk (dormouse), Hunters (squirrel), Bog folk (otter). There is no marmot. Tribes without one, such as Birds (Fieldfare, Still-Water Heron, Drumming Woodpecker) and Hive, show initials on a coloured panel.
- **Six or five:** question 5 and the playtest guide say "the six Ink B folio portraits"; the folio has six (the marmot too), but the build maps five.
- **What the plan said:** flat tribe colours.
- The source records the pick, not the reason for it. The suggestion is ours.
- The Marmot Lookout wears the dormouse face because portraits go by tribe, and it is Hedgerow folk.
- The portraits come from the 1 Nov style trials (`main:docs/folio/art/web/trials/ink-b-*.jpg`).

**The original question (prototype question 5):**
> "Portraits as placeholder card art. Cards use the six Ink B folio portraits by tribe (so every Hedgerow unit has the same face), instead of the flat tribe colours the plan named. Keep, or go back to colours?"

Sources: `proto/main:docs/prototype/OWNER-QUESTIONS.md`, `docs/prototype/PLAYTEST.md`, `docs/prototype/screens/`.
