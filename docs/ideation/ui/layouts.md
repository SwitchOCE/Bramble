# Layout options

Owner choice for Step 0b; visual proposals, not shipped layouts. [Gallery](http://100.92.26.47:8790/loop1/layouts/) · [Bazaar comparison sheet](http://100.92.26.47:8790/loop1/layouts/sheet.jpg). Each option has recruit and mid-fight at PC 1920×1080 and phone 1688×780, plus a phone still with the tap reader open. All are marked **concept** because their painted backdrops were image-generated. No depth depends on motion, so no GIFs.

## Woodland Table

**Idea:** The Bazaar's stable central stack translated to Bramble: shop, two ranks and hand share one woodland table, with an action dock and a quiet lobby rail.

**Depth:** Godot 2D contact shadows, a thick bevelled rim and a painted forest beyond one coherent tabletop; Mosswood Mist backdrop. **Changes from build 8:** lobby moves left; shop shrinks to one row of five units and a spell; hand becomes a horizontal tray below the four/three formation; gold and actions form one smaller dock. Fight replaces the shop/formation stack with mirrored four/three boards on the same surface. **Cost:** roughly 2–3 days, mainly `recruit_layout.gd`, `combat_screen.gd`, `lobby_strip.gd`, `hand_fan.gd` and `table_background.gd`. **Ink-B fit:** fully face-on art and badges, with a quiet moss inlay separating their ink from the painting.

**Fresh critic:** Shop art stands out first. Framing is quieter than Bazaar, but shop, formation, hand and lobby demand more simultaneous reading. The mirrored fight is clear; shallow depth suits the flat units.

## Sidecar Market

**Idea:** A merchant display sits beside the player's formation, keeping shopping and deployment in stable places and replacing the merchant side with the opponent during a fight.

**Depth:** raised 2D trays with thick side faces and contact shadows; Weald Glow backdrop. **Changes from build 8:** shop wraps into two columns; four front pieces form the inward column and three back pieces the outward column, in recruit and fight; the lobby remains above, hand below, and shop actions beneath the merchant. Fight mirrors those rank columns across the central gap. **Cost:** roughly 3–5 days, mainly `board_view.gd`, `recruit_layout.gd`, `combat_screen.gd`, `combat_motion.gd` and `hand_fan.gd`; rank rotation needs placement and attack-coordinate work. **Ink-B fit:** upright, equally sized pieces; the main tradeoff is learning the sideways formation and looking between two surfaces.

**Fresh critic:** The two surfaces stand out first. Shop versus deployment is clear and the sideways fight ranks are understandable. Ornament is simpler than Bazaar, but shopping takes a wider eye movement across the clearing.

## Rootbridge Diorama

**Idea:** A steeply viewed woodland platform carries upright Ink-B pieces at different depths, with the merchant beyond the formation and a mirrored opponent beyond the fight's centre line.

**Depth:** static pinhole projection of a Camera3D diorama: foreshortened platform, depth-scaled billboard pieces, contact shadows and foreground occlusion; Fen Wisplight backdrop. **Changes from build 8:** the shop becomes a raised distant shelf, the near rank is larger, and the hand sits on the near rim; fight uses four depth planes. **Cost:** roughly 6–9 days for a new `src/ui/stage/woodland_diorama.gd`/scene, integrated through `recruit_layout.gd`, `combat_screen.gd`, `combat_motion.gd` and `card_view.gd`; include screen-space input and reader work. **Ink-B fit:** camera-facing sprites preserve flat ink and legible badges while the world supplies volume; the smaller far rank needs device testing.

**Fresh critic:** Recession and the larger near pieces stand out first. Decoration is quieter than Bazaar; depth scaling adds a reading burden, especially for distant enemies on phone. Upright ink still fits the world.

## Shared behaviour and evidence

Every recruit view retains the full eight-player lobby with Health and opponent tier numerals, gold, tier up, refresh, freeze, End turn, seven deployed pieces and ten hand tiles. Tap inspection uses the existing reader and unchanged card text; it opens over the left activity area and dismisses before returning to play. Fights retain both boards, hero Health, pause and speed. No tutorial labels or static pointers were added. This study does not implement interaction.

Woodland Table's two recruit stills render rearranged real Godot nodes; the other stills recompose transparent renders of the same real widgets. The deterministic recruit state has three unit offers, supplemented with two actual pool units to show the requested capacity. All options share one captured mid-fight state. Table geometry, shadows and projection are scripted and reproducible in Godot; no extra image-model art was needed. Rebuild and verification: [`tools/mockup/README.md`](../../../tools/mockup/README.md). Bazaar sources/timestamps are in the gallery manifest; other studios' frames stay outside git.

The fresh critic inspected every still and reader study beside both Bazaar references and found no missing or obscured required elements. Physical-device readability and live input remain untested; these are static choices for the owner.
