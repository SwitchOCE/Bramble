# Look L2: A strip of colour

Every unit card is a tall stained-glass hexagon bordered all the way round by one calm, even strip of coloured glass, like a real lancet window. Each part of the screen is built from a distinct physical material inside a woodland glazier's hall, so shop, board, hand and fight separate at a glance.

**Tier in the shop.** A continuous strip of backlit glass sits cleanly between two dark lead lines all around the hexagon: frosted pearl (1), emerald green (2), sapphire blue (3), royal amethyst (4), burnt marigold-amber (5) and ruby red (6). Tiers 4–6 also wash their carved-oak shop niche with matching tinted light, and tiers 5–6 set a bright diamond glass facet into the top and bottom points.

**Tier on the board.** The coloured strip stays on the card so a bought unit remains the same piece, but the board drops the niche wash. Against a cool dark mossy-slate table, normal cards stay calm and matte-leaded.

**Golden, still and in motion.** Every normal card has heavy dark charcoal lead and a flush hexagon edge. Tripling turns all its lead—rim, inner frame, joints and stat bezels—into sculpted burnished gold, adds a bold wrought-gold crown finial breaking the top silhouette, and lights a sunlit halo behind the card. In motion, a slow diagonal sheen sweeps across the gold while gilt motes drift upward through the halo; normal cards stay still.

**The shop and regions.** The shop is an illuminated carved-oak cabinet at the top, backed by lantern-lit mullions with brass price discs on the sill. A heavy timber-and-iron beam divides it from the cool mossy-slate board below; a shadowed walnut tray holds the hand along the bottom. Dark stone piers hold hero, gold and controls on the left, and the eight-player strip plus glowing amber End Turn seal on the right. (A second buy-screen variant tests a wider framed table with controls on the shop arch and a slim left leaderboard.)

**The fight.** The oak shop lifts away to open a quiet, atmospheric outdoor woodland arena—moonlit birch glade or misty autumn hollow—behind both armies.

**Drop or change.** Keep the hexagon and colour order, but push tier 5 from bright yellow to deep burnt amber-orange so it never fights Golden. Drop half-frames, vines, tier numerals and tribe badges. Pull today's card-art backgrounds back in saturation so fighter and strip both sing.

---

## Stage 2: review, build layers, and motion

Pictures reviewed at full size in `/data/bramble-art/uiid-looks/L2/` (eight 1672 × 941 targets); six best assembled at full size in `/data/ui-ideation/looks/L2/sheet.png`. No second batch needed—the set proves what works and exposes the real trade-offs clearly.

### What worked and what did not

- **Golden at a glance on the board — worked cleanly.** In `02-buy-tabletop-alcove`, `06-cards-board-golden` and `07-board-seven-unit-glance`, Golden cards jump off the dark slate immediately, even parked right next to a normal Tier 5 burnt-amber boar and a Tier 6 ruby holly knight. Shifting Tier 5 to burnt amber inside heavy matte dark lead eliminated the yellow-vs-gold clash. Two caveats: (1) on a Golden Tier 4/5 card (`02`'s owl), bright gold metalwork and warm glow visually tint the tier strip itself toward gold—acceptable on the board, where Golden matters more than tier, though keeping the strip's hue saturated (like `07`'s green Golden mouse) looks cleaner; (2) the small bottom gold trefoil will shrink to ~6 px at game size and can be dropped—the top crown, thick bright gold frame and warm halo do the real work.
- **Tier felt in the shop — worked, with one lighting fix.** In `05-cards-shop-tiers` and `08-shop-alcove-closeup`, the continuous coloured glass strip reads in one sweep and the carved-oak niches feel genuinely diegetic. However, lighting *every* niche warmly (as the painter did on `05`'s pearl slot and across the warm oak arch in `01`/`02`) softens the jump between low and high tiers and lets warm wood blend slightly with Tier 5 amber. In production, keep the oak cabinet darker/cooler walnut behind Tiers 1–3 and turn on the matching coloured backlight wash only for Tiers 4–6.
- **Stained glass without busyness — works on the buy board, needs restraint in fights.** Against the dark mossy-slate board (`02`, `07`), a calm coloured strip on every board card does **not** feel busy—*because* the card interiors here use quieter frosted backgrounds than Bramble's current unit art (`assets/units/`). Drop today's loud cobalt/fire backgrounds straight into these frames and the board will get noisy. Even more honestly: on a 12-card fight over a vivid warm forest (`04-fight-autumn-hollow`), bright orange autumn leaves right behind the cards fight with Tier 5 amber and Tier 6 ruby borders. By contrast, the cool misty glade (`03-fight-moonlit-glade`) keeps all 12 cards crisp. **Advice:** keep fight arenas cool, misty, and vignetted dark in the centre (put rich foliage round the stone arch edges), and test dimming non-golden border strips by ~25% once a card leaves the shop.
- **Buy-screen layout pick:** `02-buy-tabletop-alcove` beats `01-buy-chapterhouse`. Mounting the 8-player portrait strip as a slim hanging banner on the far left and placing Refresh/Upgrade/Freeze on the shop arch gives the shop and 7-slot board much better breathing room and clearer separation.

### How it would be built

Each screen is composed of clean, independent art layers—no baked-in single flats:

1. **Arena / hall background layer (swappable per phase & fight biome):** carved stone outer arch + dark walnut chamber for buying; swappable misty woodland paintings (moonlit glade, autumn hollow, marsh, snow birch) darkened/vignetted in the central combat zone for fights.
2. **Region furniture layer (buy phase only):** carved-oak shop alcove with recessed niche slots and sill coin sockets; heavy bevelled timber-and-iron divider beam; mossy-slate board slab with subtle inlaid brass/lead hex slot outlines; recessed dark walnut hand tray along the bottom. (Swaps out cleanly when the fight starts, leaving the stone arch, hero piers and subtle clash line.)
3. **Interactive diegetic chrome layer:** hanging left leaded-glass leaderboard banner (8 portrait sockets + heart counters), hammered-brass shop fixtures (Upgrade, Refresh, Freeze) mounted on the shop arch, bottom hero bezel, gold coin dish, and amber stained-glass End Turn / Skip dial.
4. **Card stack (per unit, at 112 × 200 px game size):**
   - *Outer light/aura layer (behind card):* off for normal board cards; soft coloured niche backlight for shop Tiers 4–6; warm sunlit golden halo + additive sparkle particles for Golden cards.
   - *Unit glass art layer:* hexagonal masked stained-glass fighter with quieter, lower-saturation background glass.
   - *Border strip & metalwork overlay (112 px budget):* ~2.5 px outer rim, ~6 px calm backlit coloured glass strip with 4–6 simple straight cross-lead joints, ~1.5 px inner line (~10 px total per side, leaving ~78% of width for art). Normal cards use dark charcoal lead (#1b1d20) with flush corners (Tiers 5–6 add a 10–12 px bright diamond glass facet at top and bottom points). Golden cards swap the metalwork mask to sculpted burnished gold with high-contrast specular bevels plus a bold ~22 px-wide wrought-gold top crown breaking the top silhouette.
   - *Stat roundels:* two 26–28 px glass discs anchored at lower-left (warm amber, dark bold serif Attack) and lower-right (deep crimson, ivory bold serif Health), framed in dark lead (normal) or burnished gold (Golden).
   - *Spells:* circular dark-leaded glass medallions (~112 × 112 px), no stat roundels.

### Motion and light (not judged from stills)

- **Golden cards (the only always-moving cards on the board):** a slow diagonal specular sheen sweeps across the burnished gold metalwork and glass every ~3.5 seconds; subtle warm gilt motes drift lazily upward through the backlit halo; the top crown catches a soft highlight pulse. Non-golden cards stay completely still and matte-leaded so the eye locks onto Golden instantly.
- **Shop high-tier presence:** Tiers 4–6 breathe with a very slow, calm stained-glass backlight swell inside their oak niches (strongest on Tier 6 ruby); hovering a shop card lifts it slightly and brightens its coloured glass strip as if daylight hit it from behind.
- **Phase transition (buy → fight):** the carved-oak shop cabinet slides/lifts smoothly out behind the stone arch as lantern light fades and the outdoor woodland fight arena illuminates behind the two armies; combat hits throw brief warm amber glass-spark bursts at the point of impact.
- **Ambient life:** gentle lantern flicker on the oak shop sconces during buying; slow drifting fireflies or misty leaves near the stone arch perimeter (kept out of the centre card zone) during fights.

