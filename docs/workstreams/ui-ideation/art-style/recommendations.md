# Card art style: three recommendations

From an art-director agent, 22 Nov 2026. Proposals, not decisions. Samples are made from [prompts.txt](prompts.txt).

## Diagnosis

Measured on all 108 unit pictures, using the pane's centre as the fighter and its outer bands as the background:

- **The background is as loud as the fighter.** Median saturation is 0.70 for both. In 65 of 108 the background is brighter.
- **Too many hues.** 62% of each pane is strong colour, in 3–4 hue families, up to 6–7. Sweetbriar has blue, yellow, pink, green and gold.
- **Busy leading.** Background panes are cut as small as the fighter's, so nothing rests.
- **Sunbursts** aimed at the fighter, as in Bramble Runner and Skin-shedder.

So twelve cards shout at one level. The prompt says only "in full colour".

## Three styles

### P — Quiet ground
**Rule:** The place is built from a few large panes in muted tones of one colour family per tribe. Only the fighter gets bright glass, at most four colours. No sun rays.
**Costs:** The jewel sunset skies. Places differ by tint, not colour.
**Prompt:** replace the sentence beginning "The picture is:" with:
> The picture is: the subject named in the item, drawn in flat hard-edged shapes in strong, bright colour, against the place named in the item. The place is built from a few large, calm panes in soft, muted tones of the one colour family the item names, so the subject stands out from it at a glance. No sun rays or sunbursts.

### Q — Clear-glass ground
**Rule:** The place is near-colourless clear and opal glass, with its shapes painted on in grey-brown lines and a touch of pale gold. Only the fighter is coloured. This is the medieval "band window": coloured figures set in grisaille.
**Costs:** Biome colour and night scenes. The screen turns pale, and tier 1's pale frame blends in. Spells already use grisaille, so they would need a new look.
**Prompt:**
> The picture is: the subject named in the item, drawn in flat hard-edged shapes in full colour, standing in front of the place named in the item. The place is made in a different glass: almost colourless pale clear and opal-white glass, with the place's shapes painted on in soft grey-brown linework and at most a touch of pale gold. Only the subject is coloured glass.

### R — Single field
**Rule:** No scene. The fighter, full body and filling most of the height, stands on a strip of ground. Behind it is one plain field of large panes in a single soft colour, with at most one shape from the place.
**Costs:** The scenes stop telling a story. Larger fighters risk the owner's earlier "too big and zoomed in".
**Prompt:**
> The picture is: the subject named in the item, drawn in flat hard-edged shapes in full colour, full body, standing on a simple strip of ground. Behind it there is no scene: one plain field of large, calm panes in a single soft colour taken from the place named in the item, with at most one simple shape from that place. The subject fills most of the panel's height.

**Risk for all three:** the recipe found that added style rules made pictures flat, so each change is one sentence swap. The old picture is attached for subject and pose and may pull its colours back in. The prompt says not to copy them.

## Sample cards

All three are on the baseline screen.

- `thorn/sweetbriar`, the most garish: 6 hue families, with a background as bright as the fighter.
- `mouse/bell-ringer`, average: near the median on every measure.
- `badger/hedge-lancer`, already works: a grey-steel fighter on a coloured field reads at once.

## Pick

**P.** It fixes the measured fault, an equally loud background, and keeps the named place, the fighter's full joy and the tier frames' colours readable.

Try Q next if P looks too timid.
