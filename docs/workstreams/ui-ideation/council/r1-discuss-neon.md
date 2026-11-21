# Council round 1 discussion: neon

Having read `r1-relay.md`, `r1-opus.md`, and `r1-sol.md` in full—and re-opened `A/mid.png`, `A/after.png`, `B/mid.png`, `D/mid.png`, `D/fight.png`, `D/extra1.png`, `E/mid.png`, `F/mid.png`, and `baseline/shots/game-end-result.png` at full size to verify every contested point—here is my response.

---

## 1. The fixed things

1. **Sol fails B on Hexagons (spell frames) — Disagree.**
   - *Evidence:* As the orchestrator verified in `assets/glass/frames/` and `src/glass/glass_spell.gd`, no spell frame asset exists; `tier1.webp`–`tier6.webp` are unit frames with baked-in Attack/Health discs, and today's game draws spells in plain-lead stand-in hexagons. B uses undistorted `0.56` (`151.2×270`) real `tier1–6.webp` frames on every unit and sets `Sharpen` and `Seek` in undistorted `0.56` leaded blue-glass hexagons without empty unit stat discs.
   - *Shortlist or fix:* Neither a fail nor a reason to keep B off the shortlist; no spell-frame fix is required beyond waiting on a project spell-frame asset.

2. **Sol fails C on Hexagons (spell frames) — Disagree.**
   - *Evidence:* Same asset fact. Every unit in C uses undistorted `0.56` real unit frames, and `Sharpen`/`Seek` use clean leaded tall hexagons. Notably, A and F only passed Sol's check by putting `tier1.webp` onto spells, which leaves broken empty yellow stat discs on `Sharpen` (`A/mid.png`, `F/mid.png`).
   - *Shortlist or fix:* Not a reason to exclude C (C is excluded for flat HUD chrome, tiny `156–180 px` cards, and visual clutter).

3. **Sol fails D on Hexagons (spell frames) — Disagree.**
   - *Evidence:* Every unit in D uses undistorted `w = h * 0.56` real `tier1–6.webp` frames. `Sharpen` and `Seek` use undistorted `0.56` tall hexagons in plain black lead, matching today's own `glass_spell.gd` stand-in.
   - *Shortlist or fix:* Not a fixed-rule fail and not a reason to exclude D; upgrading the plain black hex outline to a richer leaded-glass spell frame is a simple polish **fix** (included below).

4. **Sol fails E on Hexagons (spell frames) — Disagree.**
   - *Evidence:* Every unit in E uses undistorted `0.56` real `tier1–6.webp` frames at `250–300 px`; `Sharpen` and `Seek` use undistorted `0.56` dark-lead hexagons matching today's stand-in.
   - *Shortlist or fix:* Not a reason to exclude E; adding richer leaded detail to the spell frames is a minor polish item.

5. **Neon fails F on Lead and stained glass — Hold as Fail.**
   - *Evidence:* Re-inspecting `F/mid.png`, `F/fight.png`, and `F/after.png`, Fixed #2 in `04-designer.md` requires that *"every panel, button, counter and label reads as glass, lead, or the stone, wood or light around them."* Despite F's brass book border and four corner leaf flourishes, the top 8-player standings bar, header stat chips (`11 Health`, `20 Gold`, `3 Compost`, `2 Tide`), shop buttons, flat rectangular `Sharpen` strips, Turn-8 scout tiles, `Fight log`, `Defeat` box, and giant opaque charcoal text slabs burying ~45% of every unit card's art (and ~75% of hand cards in `F/fight.png`) read as matte dark-mode web/app UI. Opus noted the same visual fact (*"the controls and counters are flat rounded chips. The lead and the light don't reach them"*).
   - *Shortlist or fix:* **Reason to keep F off the shortlist.** Fixing F's material would require rebuilding virtually every panel, button, spell strip, scout card, and card face across all four views—a redesign outside defect-fix scope.

---

## 2. The shortlist and score differences (`≥ 2` points)

### Shortlist update: `D B A` → **`D A E`**

- **Why D stays #1 and A moves up to #2:** **A** is on all three shortlists with zero fixed fails and clean recruit reading; **D** is on Opus's and my lists and was Sol's top Reading score (`9/10`), kept off Sol's shortlist solely by the mistaken spell-frame fail. Together **D** (sunlit diegetic workshop + light table) and **A** (perfected classic Gothic three-light window, the control) form an unmistakable, high-readiness core.
- **What changed my mind on B vs E (dropping B, adding E at #3):**
  1. Re-checking `B/mid.png` alongside Opus's and Sol's critiques convinced me I overrated B's look: both Opus (`6/10`) and Sol (`6.5/10`) ranked B **6th (last)**, and looking again at the right half (`x ≈ 1040–1900`), ~10–12 dark slate quarry cells read as cold empty hex-HUD space with little woodland warmth outside the card art, while the mid-torso dark bars obscure every warrior and the vertex-mounted lobby health beads (`31`, `23`) sit awkwardly between stacked portraits.
  2. Conversely, all three members gave **E** the highest or tied-highest Look score (`8.5 / 8.5 / 9`), and the owner's stated top priority is *"look and feel"*. In Round 1 I excluded E only because I worried adding text would redesign it; Opus's fix list for E convinced me otherwise. Checking `E/mid.png`, trimming card height slightly (`270/300 px` → `~245/255 px`) leaves clean room for compact dark leaded name+cue plates beneath cards and name tags beside the hanging tree lanterns **without** losing the frameless dusk clearing, hanging bough, or woodland magic.
  3. **`D A E`** gives the owner three genuinely distinct, gallery-worthy styles and layouts: sunlit glazier's workbench (**D**), refined Gothic three-light window (**A**), and open stained-glass woodland clearing (**E**).

### Score differences of `≥ 2` points (Look of B, D, F)

- **Look of B** (Opus `6`, Sol `6.5`, Neon `8` → **Move to `7`**): Re-inspecting `B/mid.png`, Opus and Sol are right that the right-side dark slate cells feel cold and sparse and the woodland theme barely enters the chrome. I move down 1 point to `7` (still above Opus's `6` because every control genuinely shares the leaded-glass `0.56` hex architecture).
- **Look of D** (Opus `7`, Sol `7.5`, Neon `9` → **Move to `8`**): Re-inspecting `D/mid.png` and `D/fight.png`, Opus and Sol rightly caught that the blazing bright cream/white light table and hard diamond quarry grid in `D/fight.png` are brighter than the stained-glass cards themselves, flattening their jewel glow, and the plaques lean slightly papery. I move down 1 point to `8` (staying above Opus's `7` because the painted workshop bench, tools, bramble sprigs, and recessed leaded framing still read as one crafted physical object belonging beside *Backpack Battles* and *Inscryption*).
- **Look of F** (Opus `6`, Sol `7.5`, Neon `4` → **Move to `5`**): Re-inspecting `F/mid.png`, F's clean diptych balance, brass double-line borders, and corner botanical leaves merit `5` rather than `4`. I do not move to `6` or `7.5` because its matte dark-green flat CSS chips, rectangular spell strips, and opaque charcoal card slabs burying ~45% of every warrior's art do not read as backlit stained glass.

*(Revised Neon scores — Look / Reading: **D** `8 / 8`, **A** `7 / 7`, **E** `9 / 4`, **B** `7 / 7`, **C** `6 / 6`, **F** `5 / 7`, **Today** `5 / 3`.)*

---

## 3. Audit of other members' fix items & proposed joint fix lists

### Concept D — The glazier's bench

**Review of Opus's blocking fixes for D:**
- **Opus D1 (Real frame for spells, `mid` 1300–1570):** **Agree** — `Sharpen` and `Seek` currently use bare black hex outlines (`D/mid.png`); leaded stained-glass spell frames finish the craft.
- **Opus D2 (Dim shop window & light table to darker coloured glass; tinted glass labels instead of paper):** **Agree with a different fix** — `D/mid.png` and `D/fight.png` are indeed too bright and wash out card glow, and the labels look papery, *but* making the table dark would erase D's sunlit glazier light-table identity. Instead, tone the shop panes, light table, and fight quarry field down to warm frosted parchment/smoked-amber backlit glass with subtle bevelled lead rims and softer quarry lines so the jewel-toned cards pop as the brightest elements.
- **Opus D3 (Raise board cards to ≥240 px tall, `mid` 340–1580):** **Agree with a different fix** — `172 px` cards leave ~220 px empty margins each side (`D/mid.png`), and Sol rightly notes the shop plaques have excess vertical whitespace; trimming ~35–45 px off the shop label height lets the light table grow so board cards reach `~215–230 px` cleanly without cramping the two rows + plaques.
- **Opus D4 (One accent: unify left-lane buttons so Freeze isn't bright pale blue; only End turn is lit):** **Agree** — in `D/mid.png`, pale-blue `Freeze`, green `Refresh`, and cream `March Hare`/`Dame Farthing`/`Compost`/`Tide`/shop plaques all compete with `End turn`.
- **Opus D5 (Move Renown off top-left shoulder or change shape/colour):** **Agree** — bare yellow diamonds (`7`, `2`, `3`) on the top-left shoulder mimic shop price coins and look attached to the card rather than the slot (`D/mid.png`, `D/fight.png`).
- **Opus D6 (Fill or narrow fight's empty side columns and mid's empty hand strip):** **Agree with a different fix** — in `D/fight.png`, widening the central window or placing live stakes / expanded Reserves cleanly reduces blank wood; in `D/mid.png`, the hand strip is `1/7` and *must* keep space for 6 more cards—fix it by giving the strip a compact 7-slot hex layout that scales cleanly to 7 cards rather than leaving one wide text box.
- **Opus D7 (`after`: post-fight standings values):** **Agree** — `D/after.png` still shows pre-fight health (`Pipkin 31 1st`) while marking `Dame Farthing` `OUT`.
- **Opus D8 (`extra1`: dock reading panel without covering table frame):** **Agree** — in `D/extra1.png`, the `Wing Commander` panel overlaps the light table's right lead border and corner pin bolts.

**Review of Sol's listed defects for D:**
- **Sol D-spell fail:** **Disagree** on fixed-rule fail (no spell frame exists), **agree** to upgrade the black outline to a leaded-glass spell frame (joint fix #6).
- **Sol D-shop height vs small board (`mid`/`first`):** **Agree** — trimming unused bottom height in short shop plaques (`Bramble Runner`) frees space to grow board cards (joint fix #3).
- **Sol D-16 px shop decision text (`mid`):** **Agree** — `.tx` is `16 px` (`Sweetbriar` rules text); raise actionable shop rules text to `18 px` (joint fix #4).
- **Sol D-hard diamond grid & tight transom spacing (`fight`/`after`):** **Agree** — soften the dark diamond grid lines on the bright `D/fight.png` backdrop and add vertical clearance above the central lead divider (joint fix #2).
- **Sol D-label starting stats in `after` + note `Watch again` suggestion:** **Agree** — either show actual post-fight survivor stats or label them as starting stats, and label `Watch again` as a flow suggestion in `notes.md` (joint fix #7).

**Proposed joint blocking fix list for D:**
1. **Single primary action accent (`mid`, `first`; left lane `Gold`/`Upgrade`/`Refresh`/`Freeze`, right standings, bench plaques, bottom-right `End turn`):** Unify left-lane controls in quieter leaded glass (toning down pale-blue `Freeze` and green `Refresh`), mute `March Hare`/`Dame Farthing`/`Compost`/`Tide` and shop plaques to quieter frosted parchment-glass, and reserve the warm backlit amber-gold glass accent strictly for `End turn`.
2. **Tone down backlight & glassify plaques (`mid`, `first`, `fight`, `after`; shop panes, light table, fight quarry backdrop, card plaques):** Lower the white/cream backdrop luminance into warm frosted backlit glass with softer diamond quarry lines in `fight`/`after` so the stained-glass cards read as the brightest jewels on screen, style labels as bevelled tinted glass in lead rather than flat paper, and add vertical clearance above the central fight divider.
3. **Grow board cards and reclaim dead margins (`mid`, `first`, `fight`, `extra1`; shop plaque heights, light table, fight side columns):** Trim unused vertical height in the shop text panes, expand the light table to grow board cards from `172 px` to `~215–230 px`, inset the `extra1` reading panel cleanly inside the table border so it clears the right frame and corner pins, and widen/balance the fight window to trim blank wood side columns.
4. **Differentiate Attack, Health, buffed stats, Renown, and board cues (`mid`, `fight`; all unit cards and shop text):** Replace identical plain white `36 px` stat circles with distinct Attack and Health glass badges scaled cleanly to the frame's disc zone plus green buffed-stat cues; replace the bare top-left yellow Renown diamond with a clearly labelled star + `Renown N` slot marker etched onto the slot surround in a non-gold colour; add concise 2–3 word trigger cues to non-keyword board plaques (`Famine-caller`, `Squadron Leader`, `Granary Glutton`, `The Eighth Plague`) and restore Charge pips (`Wing Commander`, `Weasel`); raise shop rules text (`.tx`) from `16 px` to `18 px`; add a subtle non-colour tier numeral/pip cue in the lead frame.
5. **Fix `Reserves in hand` and keep `Turn 9`/Menu stationary (`fight`, `after`; bottom-left & top-left):** Draw `Home Guard` and `Hayloft Aunt` in `Reserves in hand` with real Attack/Health numbers (never empty yellow discs) and `≥18 px` names, and keep `Menu` + `Turn 9` anchored at bottom-left across all four views instead of jumping to top-left in `fight`/`after`.
6. **Upgrade spell frames & scalable 7-card hand (`mid`, `first`; `Sharpen`, `Seek`, bottom `Hand 1/7` trough):** Replace the plain black hex stand-in outlines on `Sharpen` and `Seek` with crafted leaded stained-glass spell frames, and lay out the `Hand 1/7` trough as a compact 7-slot hex band that provably fits 7 cards without collapsing.
7. **Post-fight standings & end-stat clarity (`after`, right column & enemy board; `notes.md`):** Update `after` standings to post-fight Turn-9 values (`Dame Hoolet 23` 1st, `Pipkin 21` 2nd, etc.), either show surviving end-of-fight unit stats or clearly label displayed values as starting stats, and label `Watch again` as a flow suggestion in `notes.md`.

---

### Concept A — The great window, refit

**Review of Opus's blocking fixes for A:**
- **Opus A1 (Proper 4+3 rows & consistent left-anchored row labels in `mid` and `fight`):** **Agree** — `A/mid.png` and `A/fight.png` interleave rows into a wide zigzag with mixed centred/left-aligned row labels.
- **Opus A2 (Show tribe at a glance on all 12 cards in `mid`):** **Agree** — currently requires selecting each card to check tribe in `Card details`; a small leaded shoulder crest or tribe word in the caption solves it.
- **Opus A3 (Move `10 at this price` to Refresh, `mid` 355, 356):** **Agree** — currently grouped directly inside Upgrade's subtext under `−3 next turn`.
- **Opus A4 (Enlarge spells to ≥ half a unit card, drop empty stat discs, one label per spell, `mid` 1445–1560):** **Agree** — `Sharpen` hexes are `54 px` wide with empty unit stat discs and one shared caption that breaks when two spells differ.
- **Opus A5 (`after` standings — real Turn-9 post-fight order):** **Agree** (clarification: `A/after.png` copied `game-end-result.png` where remaining ghosts resolved off-screen so 2–6 show `Out`, rather than inventing random numbers—still, on a `Turn 9 · Fight ended` screen, Turn-9 post-fight standings from `fight-mid-t9-result-defeat.png` are far clearer).
- **Opus A6 (`after` — add 3-item "what beat you" list over empty board):** **Agree** — currently only shows arithmetic + one Gorger line in the side pane.
- **Opus A7 (Left light: trim empty `Card details` void & enlarge `Seek` in `Hand 1/7`):** **Agree** — `~150 px` dead dark pane under `Card details`, while `Seek` is tiny (`54 px` wide) and hides its `3` gold cost and cue.
- **Opus A8 (`notes.md`: list row 20 as reversed):** **Agree**.

**Review of Sol's blocking fixes for A:**
- **Sol A1 (Clear bottom sill for back-row captions, consistent left row-label anchors, fixed price baseline instead of inline beside `Bramble Runner`):** **Agree** — back-row captions press into the bottom stone sill (`crop-A-board.png`), bottom-tip keyword marks collide with caption tops, and inline prices sit unevenly.
- **Sol A2 (Unambiguous `Sweetbriar` text "+1/+1 when you Compost a unit"; attach Renown to slot surround; aim `first` tutorial cue at an actual empty front slot):** **Agree** — `+1/+1 per Compost` reads ambiguously as a static count aura, and `A/first.png` places the tutorial box in the gap between slots 1 and 2.
- **Sol A3 (Carry compact unit names into `fight` including `Golden Gorger`, and mark survivors/fallen + threat explanations in `after`):** **Agree** — all names disappear in `A/fight.png` and `A/after.png` shows an unannotated starting board.
- **Sol A4 (Record row 40 reversal in `notes.md`):** **Agree**.

**Proposed joint blocking fix list for A:**
1. **Fix 4+3 row geometry, sill clearance, mark clearance, and row-label anchors (`mid`, `first`, `fight`; centre board):** Tighten front 4 and back 3 into two clear half-slot staggered rows on a shared centre line (no wide zigzag), anchor `Front row` and `Back row` consistently at the left of each row in both recruit and fight, raise the back row so captions clear the bottom stone sill, add clearance so bottom-tip keyword marks (`Shrew Cutpurse`, `Blackberry Sprawl`, `Hedge Lancer`, `Wing Commander`) never touch caption tops, and anchor Renown pills to the slot surround.
2. **Show tribe, fix `Sweetbriar` wording, and align shop prices (`mid`, `first`; shop & board cards):** Add a small leaded tribe crest or tribe word at a glance on all shop/board cards plus a subtle non-colour tier cue, align shop price coins on a shared horizontal baseline instead of inline after variable-length names, change `Sweetbriar`'s caption to unambiguously state the trigger (`+1/+1 when you Compost`), and point `first`'s tutorial cue directly at one highlighted empty front slot.
3. **Fix shop spells & Refresh stock grouping (`mid`, `first`; left & right shop wings):** Move `10 at this price` onto the `Refresh` control; enlarge the two shop spells to at least half a unit card, strip the empty yellow unit stat discs from their frames, and give each spell slot its own independent label and effect line.
4. **Rebalance left light & keep phase stability (`mid`, `first`, `fight`, `after`; left & right lights):** Anchor `Dame Farthing`'s portrait, health, and `Compost`/`Tide` in one consistent position across all four views (never jumping top-left ↔ bottom-left); trim the empty lower portion of `Card details` in `mid` to give `Hand 1/7` larger, readable hex cards showing `Seek`'s `3` gold cost and short cue; in `fight`, use the right light's empty centre glass (e.g., waiting Reserves) or tighten it to eliminate the dead void.
5. **Name fighters in combat and upgrade `after` recap (`fight`, `after`; centre window & right light):** Keep compact unit names and short cues visible on both boards in `fight` (including `Golden Gorger`); in `after`, mark surviving vs fallen enemy slots, add a 3-item "what beat you" breakdown in the Defeat panel, and show Turn-9 post-fight standings (`Dame Hoolet 23`, `Pipkin 21`, etc.) rather than off-screen match elimination (`Out` for places 2–6).
6. **Update `notes.md`:** Record reversed owner-decision rows `20` and `40`.

---

### Concept E — Glass in the forest

**Review of Opus's blocking fixes for E:**
- **Opus E1 (Lead-set name + short cue plates under shop & board cards, `mid`):** **Agree** — solves E's 12–15-open failure while keeping the card faces unobstructed and preserving the woodland clearing; extend compact name plates into `fight` as well.
- **Opus E2 (Label each hanging player lantern with name, raise rank numerals to ≥18 px, add `Fight March Hare` on `End turn`, `mid` 1680–1870):** **Agree** — also fix lantern threads passing behind lanterns above, add a dark backing plate behind rank numerals (rank `5` measured `4.49:1` on bare bark), raise lantern health digits to `≥18 px`, and label `Dame Farthing`'s own portrait.
- **Opus E3 (Distinct hanging-tag price shape instead of stat-like discs, `mid` y ≈ 400):** **Agree** — also un-overlap `Refresh`'s `(1)` coin from the button border.
- **Opus E4 (Make `End turn` the primary lit gold lantern and tone down the 20-gold medallion, `mid`):** **Agree** — currently the oversized `20` gold medallion top-left outshines `End turn` bottom-right.
- **Opus E5 (Add `Compost` and `Tide` words to counter roundels, `mid`/`fight` 30–175, 790–850):** **Agree** — bare icons aren't teachable at a glance.
- **Opus E6 (Lift hand tray so `Seek` is whole on screen and raise hand numbers to ≥18 px, `mid`/`fight` 215–330):** **Agree** — the bottom-left wooden rail is half-clipped at `y=1080`, overlapped by bottom icons, and hand stats render at `15.4 px` with sub-14 px keyword-count badges (`1`/`2`).
- **Opus E7 (Drop/trim competing tribe outer glow so frame alone carries tier colour, `mid`/`fight`):** **Agree** — keep the tribe crest only and add a subtle non-colour tier cue.
- **Opus E8 (`fight`/`after`: space enemy rows so marks don't sit on Renown plates; show post-fight health in lanterns):** **Agree** — `★ 7` and `★ 3` crowd adjacent card tips/marks, and `after.png` lanterns still show pre-fight health.

**Review of Sol's listed defects for E:**
- **Sol E-spell fail:** **Disagree** on fixed-rule fail (no spell frame exists), **agree** as minor polish to give spells richer leaded framing.
- **Sol E-flat shop branch & hand log against textured glass (`mid`):** **Agree** — add leaded facet shading and glass texture to the top bough and lifted hand ledge so they match the painted stained-glass trees (joint fix #5).
- **Sol E-lantern identity/undersized HP digits, tribe halos, identical stat/price coins (`mid`):** **Agree** (joint fixes #2, #3, #6).
- **Sol E-14–17 px hand stats & cramped bottom marks (`fight`):** **Agree** (joint fix #5).
- **Sol E-`extra1` inspector covers middle board units while citing Pigeon synergies:** **Agree** — dock or offset the reading pane so it does not cover matching board units, and style both `extra1` and `after`'s reckoning box as leaded stained glass rather than flat dark rectangles (joint fix #7).
- **Sol E-`after` dimming live survivors makes them look fallen:** **Agree** — highlight the 3 key threats with glowing rings/numbered badges without greying out live survivors so all 7 visibly read as surviving (joint fix #7).
- **Sol E-`notes.md` (add row 40 and label `Watch again` as flow suggestion):** **Agree** (joint fix #8).

**Proposed joint blocking fix list for E:**
1. **Add leaded name + short cue plates to cards (`mid`, `first`, `fight`; shop units, spells, board units, enemy units):** Slightly trim card heights (`~245–255 px`) and place compact dark leaded-glass name + short cue plates beneath each shop, board, and fighting unit (and each spell) so weighing the shop and reading combat require 0 opens while keeping the card art unobstructed.
2. **Label player lanterns, fix threads & contrast, and name `Dame Farthing` (`mid`, `first`, `fight`, `after`; right lantern tree & bottom-left portrait):** Add player names beside each lantern, put dark leaded backing plates behind `≥18 px` rank numerals and `≥18 px` health digits (fixing `4.49:1` rank `5`), terminate each thread cleanly above its lantern so threads never pass behind lanterns above, label `Dame Farthing`'s portrait, and put `Fight March Hare` on `End turn`.
3. **Separate prices from stat discs & fix `Refresh` overlap (`mid`, `first`; shop prices & left controls):** Restyle shop prices as hanging leaded tags distinct from Attack/Health discs, and seat `Refresh`'s `(1)` price cleanly inside or beside the button without overlapping its border or crowding `Freeze`.
4. **Fix accent hierarchy & label counters (`mid`, `first`, `fight`; top-left `20` gold, bottom-left counters, bottom-right `End turn`):** Tone down the `20`-gold medallion so the bottom-right `End turn` lantern is the sole brightest lit action accent, add the words `Compost` and `Tide` to the counter roundels, and label the kill-tally bar during `fight`.
5. **Lift and texture the hand ledge & top bough (`mid`, `first`, `fight`; bottom-left hand tray & top shop bough):** Lift the hand ledge completely inside the viewport (`y < 1080`) so `Seek` and bottom icons clear the rail, raise hand card stats to `≥18 px` and keyword-count digits to `≥14 px`, and give the bough and hand ledge faceted leaded-glass texture matching the trees.
6. **Remove competing tribe outer-glows & add non-colour tier cue (`mid`, `first`, `fight`; all unit cards):** Drop the coloured outer halos around cards (keeping the clean tribe crest) so tier frames read without colour conflict, and add a subtle non-colour tier numeral/pip cue in each lead frame.
7. **Fix fight spacing, `after` survivors/standings, and leaded popups (`fight`, `after`, `extra1`; enemy rows, lanterns, popups):** Increase vertical spacing between enemy rows in `fight` so marks never touch Renown badges (and route the strike arc cleanly outside `Squadron Leader`); in `after`, update lantern health to post-fight Turn-9 values, keep non-culprit survivors visibly alive (highlighting the 3 key threats without greying out live survivors), and style both `after`'s reckoning panel and `extra1`'s inspect pane as leaded glass docked without covering synergistic board units.
8. **Update `notes.md`:** Record row `40` (always-visible standings) and label `Watch again` as a flow suggestion.

---

## Not judged

From 1920×1080 stills alone, motion, attack pacing, timing, hover/drag-and-drop feel, sound, and other screen resolutions or aspect ratios are **not judged** (and not passed).

## Disk

No new scratch files were created in this discussion step. Existing scratch from Round 1:
- `/data/ui-ideation/tmp/council-neon/` (`du -sh`: **9.0M**, 14 verification PNG crops from Round 1). **Can be deleted by orchestrator** once Round 1 closes.
- **Keep:** [r1-neon.md](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/council/r1-neon.md) and [r1-discuss-neon.md](/home/alex/.t3/worktrees/Bramble/ideation-ui-ux-dce1598bde386004/docs/workstreams/ui-ideation/council/r1-discuss-neon.md).
- **`df -h /data /`:** `/data` 13G / 70G used (20%, 54G avail); `/` 84G / 163G used (55%, 71G avail).

JOINT PROPOSAL: SHORTLIST D A E
