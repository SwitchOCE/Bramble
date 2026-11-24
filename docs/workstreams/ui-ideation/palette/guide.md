# Card art colour guide

From the art director for brief 33, 24 Nov 2026. A proposal for the owner, not a decision. Tested on today's card window; the test sheet is `/data/ui-ideation/palette/sheet.png` and the pictures are in `/data/bramble-art/uiid-palette/`.

## The level

**The fighter stands in clear light; the place behind it lies in soft shade.** The fighter is the brightest, most colourful thing on the card. The place keeps its colour and its story, one step deeper and quieter, in a few large panes, with no sun rays. On a board of seven at 130 px the fighters now lead, and the glass still glows. It is calmer than today, and less grey than the "washed out" middle picture.

A quieter "hushed" strength was tried too. It came out almost the same as "in shade", so one strength is enough.

## How the painter is told

Rules flattened the pictures on 15 Nov. Light does not. In the recipe's prompt (`tools/art/prompts/glass-art-window.txt`):

1. Change "in full colour, against the place named in the item" to "in full, rich colour, against the place named in the item, lit as LIGHT below says".
2. Add this paragraph after "The design":

   > LIGHT: The subject stands in clear light and is the brightest, most colourful thing in the panel. The place behind it lies in soft shade, as in the hour before evening, so its glass glows deeper and quieter than the subject's, mostly in the place colours the item names, in a few large panes. No sun rays or sunbursts.

3. End each item with its tribe's place and a "Place colours:" line from the table, for example: `... at the edge of a cornfield at nightfall under a crescent moon. Place colours: deep dusk blue and dark timber brown; the corn lies in shade, a dull greyed tan.`

It worked on cards with no old picture attached: a new card for every tribe (two for mouse and thorn) came out right first time. Attaching an old picture to keep the pose is risky. The bell-ringer repaint copied its old violet stone and sunset windows. When repainting, write the new place and time of day out in full.

## Palette per tribe

| Tribe | Place and time | Home colours (background) | Value | Figures keep | Avoid |
|---|---|---|---|---|---|
| Badger | old oak wood, damp afternoon | moss `#3c4a26`, oak shade `#23281a`, bark brown `#5a3a1c`, rain grey `#6e7270` | dark | steel `#b8bcc0`, banner red `#b3261e`, cream `#e8e0cc` | orange or gold leaves en masse; green clothes on the fighter |
| Locust | stripped fields, end of a hazy day | dusty rust `#8a4a38`, smoke plum `#6b3a4a`, burnt umber `#5a2a1c`, a little dry stubble `#a88a50` | mid-dark | locust green `#9cc040`, sash red `#c0302a`, wing straw `#d8c070` | yellow or gold skies; plum turning purple |
| Mouse | barn and field at nightfall | dusk blue `#1f2f52`, dark timber `#4a2a14`, shaded hay `#7c6a48`, a little lamp-lit wood `#7a4a20` | dark | mouse tan `#c98a50`, cape red `#c42a20`, tunic blue `#2d5fb0` | golden straw and sunbeams; violet stone |
| Pigeon | home front under an overcast sky | dove grey `#a8aaa6`, faded sage `#8a9470`, pale khaki `#a89a78`, mud brown `#5a4630` | light | guards red `#c0201c`, navy `#283860`, khaki `#a88a40` | pink or orange sunsets; bright green grass |
| Thorn | hedgerows in morning mist | mist blue-grey `#8aa8b8`, grey teal `#5f8080`, hedge shade `#3a5040`, wet stone `#6a6a66` | mid | leaf green `#7cc040`, living wood `#6a3e20`, dog-rose pink `#e8708a` | lilac or purple; blue sky with a sun |
| Neutral | open stony hillside, grey afternoon | warm stone `#8a7e72`, oatmeal `#b8a890`, pale cloud `#c4bcb4`, dry grass `#a08a60` | light-mid | any | green woods (reads as badger); any tribe's home colours |

Each tribe can still change its place from card to card (a tower, a trench, a pond). The colours and time of day stay the same. The hex values are measured from the test pictures and rounded. They are for checking and for the sheet, not for the prompt.

## Kept for the screen

Card backgrounds leave these alone in large areas, so that tier light and gold stay readable:

| Kept for | Colours |
|---|---|
| Golden card | gilt `#d6aa48`, warm glow `#ffbe50`: no gold, amber or sunlit straw fields, no sun discs or rays |
| Tier lights | off-white `#ece8dc`, green `#5ac86e`, blue `#508cf0`, purple `#a05ae6`, orange `#ff9628`, red `#f03c32`: no saturated purple, orange or red fields. Red is fine on a fighter (capes, banners, the marshal's red mist) |
| Room | lead `#26221f`, oak `#38241a`, stone `#3c3b3e`, leather `#5a3a22`: keep some lighter sky, mist or window near the top so dark cards don't sink into the oak |

The test shows the gain: today's gold barn mouse merges with its gilt border, and the nightfall mouse doesn't.

## The larger test: eighteen cards on the wider card

The eighteen cards on the buy screen were painted full-bleed for the 0.69 card (sheet: `/data/ui-ideation/palette/c69-sheet.png`). The old picture was attached for the figure only, and the place was written out in full. 15 of 18 came out right.

- **The wider window works.** Every figure is whole from head to foot. Nothing that matters sits in the cut corners or under the discs, except one knife tip.
- **Mouse** works on all four cards. No old colours were copied.
- **Pigeon, thorn and neutral** are now told apart at 173 px: thorn by its grey-teal mist, pigeon by cool grey and sage, neutral by warm oatmeal.
- **Still open:** neutral is the plainest tribe. Badger cards whose place is built from many small leaf panes let the fighter lead less. Asking for a pale figure on the locust gleaner changed its colours. All three are being painted again.

## Not settled

- **An old picture attached** must be marked "figure only", with the place written out in full. Otherwise it brings its old colours back (the bell-ringer).
- **Neutral** may read a little plain, against "maybe not too plain".
- **Pale pigeon cards under the off-white tier 1 light** have the least contrast of any pairing.
- **Mouse and badger are the two dark tribes.** Mouse is a little heavy at nightfall; a brighter lamp-lit spot is worth trying if the owner finds it gloomy.
