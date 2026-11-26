# How Battlegrounds animates a fight, measured (R1, 24 Nov 2026)

Measured frame by frame from six public YouTube videos (2020, 2022, 2025, three from 2026). All times are in frames at 60 fps (1 frame = 16.7 ms). "h" = one card height on screen (the resting oval portrait, 100 to 115 px in a 720p capture). The footage stays in `/data/fight-anim-ref/bg/`; nothing from it is in the repo.

## The owner's claims against the footage

| Claim | Verdict | Evidence |
|---|---|---|
| (a) Attackers travel all the way to the card they hit | **Holds** | In all 11 attacks the attacker ends with its edge overlapping the target's edge by about 0.15 to 0.3 h, at every distance from 0.3 h to 4.6 h of travel. It never stops short and never lands centre on centre. For a target straight across, the centres end 0.8 to 1.0 h apart. For a far target they end 0.4 to 0.65 h apart, because the attacker arrives at speed. |
| (b) They don't move at a consistent speed | **Partly** | Inside the forward strike, speed is almost **constant**. For example A2 moves 20.2, 19.4, 20.2, 20.0, 19.7, 19.4 and 20.2 px per frame, with no ease in and no ease out. What varies is speed *between phases*: a slow lift, a dead-still hold, a fast straight strike, a stop in one frame, then a return that starts fast and slows. Speed also differs *between attacks*, because the strike lasts a **fixed 5 to 8 frames whatever the distance**: about 5 px per frame for a target straight across, about 68 px per frame across the board. |
| (c) No pause mid-animation when a trigger fires; the triggered animation goes off after | **Holds** | In every clip the strike and return run unbroken. Triggered effects (after-attack buffs, projectiles, deathrattles, deaths) start once the attacker is home or nearly home, 26 or more frames after contact (T1). The waiting happens in the **next** attacker instead: it lifts and then holds in its raised pose until the queue clears. In T2 that hold lasted 220 frames, against the usual 21. |
| (d) The wind-up is very clearly visible | **Holds** | The wind-up is long. The card scales up by 14 to 16% over 9 to 11 frames (it rises toward the camera), gets a red ring, then **holds still, raised, for 14 to 22 frames** (usually 21) before it launches. That makes 24 to 33 frames (0.4 to 0.55 s) from first motion to launch. It is a lift, not a pull-back: no backward travel, no tilt, and less than 3 px of drift. |
| Owner, 18 Nov: fixed speeds, sped up when many animations are queued | **Partly** | The timings are fixed *durations*, not fixed speeds, and they are the same in 2020, 2022, 2025 and 2026. A speed-up exists in big 2026 fights: there, lift, hold and strike shrink to 6 to 7, 9 to 12 and 4 to 5 frames, and plain attacks come every 34 to 38 frames instead of 76 to 83. In a six-times deathrattle chain each cycle shortens from 71 frames to 32 to 35. The footage can't tell whether the trigger is queue length, fight length or attack count. No speed-up shows in the 2020, 2022 and 2025 footage, but those fights are short (10 attacks or fewer). |

## The numbers that matter most

| What | Battlegrounds (normal speed) | Our build today (PLAN.md) |
|---|---|---|
| Wind-up | Lift (scale 1.00 to 1.15) over **10** frames, then a raised hold of **~21** frames. 24 to 33 frames from first motion to launch. | 4 frames, 12 px pull |
| Strike (travel) | **5 to 8 frames whatever the distance**, constant speed, no easing | 8 frames |
| Stop point | Edges overlap 0.15 to 0.3 h. Centres 0.8 to 1.0 h apart for a target straight across, 0.4 to 0.65 h for far targets. | Centres 0.62 h apart |
| At contact | Scale jumps to 1.24 to 1.28 for 1 to 2 frames, plus a white impact flash (3 to 6 frames). **0 frames held**: it reverses the next frame. | 2 frames held |
| Return | 9 to 16 frames, eases out (fast first: 30, 23, 19, 16 … 3, 2, 1 px per frame). Scale is back to 1.0 within ~5 frames. | 11 frames |
| Damage number | The yellow damage star appears 3 to 4 frames after contact, on both cards, grows over 5 frames, then stays ~60 frames. The Health number turns red with its new value about 3 frames after contact. | n/a |
| Death | The card shatters **40 frames (2026) to 65 to 68 frames (2020 and 2022)** after the hit. The break takes 5 to 10 frames; dust lingers ~20 more. | 0.3 s step |
| One plain attack, cycle | First lift to next contact **76 to 83 frames** (1.3 s). With a death in it, **150 to 165 frames**. | n/a |
| Big fights (2026) | Lift 6 to 7, hold 9 to 12, strike 4 to 5. Attack every **34 to 38 frames**. | n/a |
| A trigger repeated many times | Each cycle hits all affected cards **at once** (4 cards share one burst). Cycles run one after another and speed up from 71 to 32 to 35 frames per cycle over the chain. No counter appears on screen. | n/a |

The board's perspective makes "h" approximate (±10%), and the lifted attacker is drawn ~15% larger, so stop distances are ±0.1 h.

## Measurement table: attacks

Contact = the frame the impact flash starts. Frame ranges are the source's own frame numbers (index = time × fps). "Lift" is when scale passes 1.02 up to the plateau; "hold" runs from the plateau to the last still frame; "strike" runs from first forward motion to contact.

| ID | Source, link, frames | Event | Lift (fr) | Hold (fr) | Strike (fr) / distance | Speed profile in strike | Stop: centre gap, overlap | Return (fr), curve | Notes |
|---|---|---|---|---|---|---|---|---|---|
| A1 | Savjz, Jan 2022, 60 fps. [youtu.be/sOiaEv25Fgc?t=33](https://youtu.be/sOiaEv25Fgc?t=33), fr 2004–2079 | Plain attack, bottom card hits the card straight above it | 11 (2011–2022) | 21 (2022–2043) | 7 (2044–2050) / 0.35 h | Linear, 4.5 to 5.4 px per frame | 0.92 h, overlap ~0.27 h | ~12, gentle ease-out (traced by the damage star) | Attacker took lethal damage. Shatter at 2119 (68 fr after contact). |
| A2 | Savjz 2022. [?t=75](https://youtu.be/sOiaEv25Fgc?t=75), fr 4499–4553 | Plain attack, diagonal to a near target | 9 (4499–4508) | 22 (4508–4529) | 7 (4530–4536) / 1.35 h | **Linear**: 20.2, 19.4, 20.2, 20.0, 19.7, 19.4, 20.2 px | 0.80 h, overlaps | **16** (4538–4553), ease-out: 30, 23, 19, 16, 9, 9, 8, 7, 5, 5, 4, 4, 3, 3, 2, 1 px | Scale 1.24 at contact, 1.0 again 5 fr later |
| A3 | Savjz 2022. [?t=76](https://youtu.be/sOiaEv25Fgc?t=76), fr 4576–4617 | Plain attack, top card hits down-right | ~8 (to 4584) | 21 (4589–4609) | 7 (4610–4616) / 0.97 h | Linear, 13.5 px per frame on every frame | n/m | n/m (occluded) | |
| A4 | Stormrage Bros, Jul 2020, 59.3 fps. [youtu.be/M11gKHV4whs?t=894](https://youtu.be/M11gKHV4whs?t=894), fr 53069–53124 | Plain attack **across the whole board**, bottom left to top right | 10 (53069–53079) | 21 (53080–53100) | **8** (53101–53108) / **4.6 h** | Linear, 60 to 77 px per frame (60, 77, 60, 69, 70, 69, 68), last frame 34 | 0.42 to 0.65 h, deep overlap | ~16 (53109–53124), ease-out (by eye, ±8 px) | Same 8-frame strike as a 0.3 h attack. Target shattered at 53174 (65 fr). |
| A5 | Bros 2020. [?t=902](https://youtu.be/M11gKHV4whs?t=902), fr 53514–53555 | Plain attack, bottom card hits the card straight above | 11 (53514–53525) | 21 (53525–53545) | 7 (53546–53552) / 0.33 h | Linear, 4.5 to 5 px per frame | ~0.83 h, overlap ~0.27 h | n/m | |
| A6 | Sevel, 23 Nov 2026, 60 fps. [youtu.be/X3cr8nyi_-s?t=785](https://youtu.be/X3cr8nyi_-s?t=785), fr 47152–47189 | Attack, top card hits the card below it, then after-attack triggers (see T1) | 10 (47152–47161) | 14 (47161–47174) | 5 (47175–47179) / 0.27 h | Linear, 5 to 8 px per frame | 0.93 h, overlap ~0.2 h | **9** (47181–47189), ease-out: 14, 5, 6, 2.5, 2, 1.8, 0.6 px | Scale 1.28 at contact |
| A7 | Sevel 2026. [?t=782](https://youtu.be/X3cr8nyi_-s?t=782), fr 46954–46985 | Plain attack, top card hits the card below | 10 (46954–46964) | 16 (46964–46979) | 6 (46979–46984) / 0.30 h | Linear, 5 to 6 px per frame | ~0.92 h, overlaps | n/m (flash occludes it) | |
| A8 | ItzElegy, Sep 2025, 60 fps upload (every 3rd frame repeated, so ~40 fps captured). [youtu.be/HxC68n9hcUU?t=226](https://youtu.be/HxC68n9hcUU?t=226), fr 13562–13617 | Attack, top card hits down, both cards die (see T5) | 11 (13562–13573) | 21 (13573–13593) | 7 (13594–13600) / 0.3 h | Roughly linear (repeated frames give 4, 5, 0, 9, 4, 0, 10) | ~1.0 h, overlap ~0.15 h | n/m | Scale 1.34 at contact |
| A9 | Sevel 2026. [?t=466](https://youtu.be/X3cr8nyi_-s?t=466), fr 28016–28261 | Attack whose wind-up started while a death and a deathrattle were still playing | 15 (28016–28031, while sliding into a dead card's gap) | **220** (28031–28251) | 7 (28252–28258) / 0.75 h | Linear, 7 to 18 px per frame | ~0.6 h | n/m | The hold absorbs the queue (T2) |
| A11 | Sevel 2026. [?t=127](https://youtu.be/X3cr8nyi_-s?t=127), fr 7636–7668 | Plain attack, **far diagonal** (2.4 h) | n/m (already lifted at 7636) | ≥18 (7642–7659) | 7 (7660–7666) / 2.4 h | Linear, 34 to 60 px per frame (60, 38, 34, 38, 40, 36) | ~0.37 h | n/m | |
| A12 | Shadybunny, Jun 2026, 60 fps. [youtu.be/cRVjjXEnd0I?t=1888](https://youtu.be/cRVjjXEnd0I?t=1888), fr 113335–113355 | Plain attack **late in a long, sped-up fight** | **6** (113335–113341) | **9** (113341–113350) | **4 to 5** (113351–113355) / ~1.9 h | Linear, ~40 to 59 px per frame | n/m | n/m | Sped up. A second attack in the same fight, [?t=1874](https://youtu.be/cRVjjXEnd0I?t=1874) fr 112488–112512: lift 6, hold 12, strike ~5. |
| R1 | Sevel 2026. [?t=778](https://youtu.be/X3cr8nyi_-s?t=778), fr 46680–46686 | Board reflow: a card slides sideways into a dead card's gap | – | – | 7 / 1.0 card width | Linear, 13 to 20 px per frame | – | – | Not an attack. Recorded for reference. |

n/m = not measured: the white flash or effects occlude the card, or the tracker lost it.

## Measurement table: triggers, deaths, chains

| ID | Source, link, frames | What happens | Timing against the attacker's motion | Together or in sequence |
|---|---|---|---|---|
| T1 | Sevel 2026. [youtu.be/X3cr8nyi_-s?t=786](https://youtu.be/X3cr8nyi_-s?t=786), fr 47180–47252 | Attack A6, then a buff star on an allied card, a projectile, a red glow across the board, then the target dies | Contact 47180. Return done 47189. Buff star 47206 (**+26 fr**). Projectile 47214–47220. Target shatters 47219–47224 (**+40 fr**). Red glow 47224–47250. Next attacker's red ring 47226, its contact 47252. | No pause in the strike or return. The triggers start after the attacker is home, one after another. The **next attacker's wind-up overlaps** the last effect (the red glow). |
| T2 | Sevel 2026. [?t=466](https://youtu.be/X3cr8nyi_-s?t=466), fr 27984–28261 | A big unit (150) dies, then its deathrattle (a green burst on the board) | Hit about 27984. Next attacker lifts 28016–28031 **while** the dead card's star is still showing. Green deathrattle effect 28088–28180 (~90 fr). Next attacker holds raised until 28251, launches 28252. | Death, then deathrattle, in sequence. The next attacker's lift overlaps them, and its hold stretches to 220 fr until they finish. |
| T3 | Shadybunny 2026, "Start of Combat: trigger all Deathrattles 6x". [youtu.be/cRVjjXEnd0I?t=1570](https://youtu.be/cRVjjXEnd0I?t=1570), fr 94318–96631 | About 32 cycles of deathrattles. Each cycle damages 4 cards at once (red burst plus a -1 star on each), and their stat numbers update ~40 to 45 fr later. | Cycle starts (onset of the yellow stars): 94318, 94388, 94459 (period **71**), mid-chain 55 to 63, end of chain (96180 onward) **31 to 40**. Pauses of 132 to 328 fr between groups of cycles. Total **2313 fr (38.5 s)**. | **Grouped:** one effect plays on all its cards together. Cycles run in sequence. Clear **acceleration (~2×)** over the chain. No counter or skip shown. |
| T4 | Shadybunny 2026. [?t=1886](https://youtu.be/cRVjjXEnd0I?t=1886), fr 113190–113393 | Late attacks in a long fight | Flash onsets 113226, 113280, 113355 → periods of **37 to 54 fr**. Within each attack: lift 6, hold 9, strike 5 (A12). | The whole fight runs at about twice the normal speed. |
| T5 | ItzElegy 2025. [youtu.be/HxC68n9hcUU?t=226](https://youtu.be/HxC68n9hcUU?t=226), fr 13601–13740 | Attack A8, both cards hit, damage stars | Contact 13601. Stars at 13606 (+5 fr). Next attacker's red ring at 13643 (+42 fr), its strike about 13676–13682. Another attacker's ring at 13718. | In sequence. |
| T6 | Savjz 2022. [youtu.be/sOiaEv25Fgc?t=41](https://youtu.be/sOiaEv25Fgc?t=41), fr 2440–2620 | Start of Combat trigger | The source card is shown **enlarged beside the board** from 2480 to 2600 (120 fr). The effect's projectile flies 2496–2512 (16 fr) while the card is shown. | The enlarged card and the effect play **together**. The same pattern shows in FJyKGdqRj4Q at ~t=1418 (fr 85106–85412). |
| D1 | Savjz 2022. [?t=34](https://youtu.be/sOiaEv25Fgc?t=34), fr 2051–2128 | Death of attacker A1 | Star at +4. Card goes slightly translucent ~2068. Shatters **2119–2128 (+68 to 77)**. | Meanwhile the next attacker's red ring appears at 2092 (+41), and it strikes at 2134. **Its wind-up overlaps the death.** |
| D2 | Bros 2020. [youtu.be/M11gKHV4whs?t=895](https://youtu.be/M11gKHV4whs?t=895), fr 53109–53196 | Death of A4's target | Star +2. Glow throughout. Shatters **53174–53178 (+65)**. Dust to ~53196. | |
| D3 | Sevel 2026. [?t=786](https://youtu.be/X3cr8nyi_-s?t=786), fr 47180–47245 | Death of A6's target | Shatters **47219–47224 (+40)**. Dust to ~47245. | Overlaps the red-glow trigger in T1 |

**Cycle times between impact flashes** (automatic detection of the white impact flash over the whole of each video; a run of plain attacks gives a steady gap):

| Video | Plain attack-to-attack gap (fr at 60 fps) | With a death or trigger |
|---|---|---|
| M11gKHV4whs (2020) | 79 to 83 (for example 80, 79, 80, 79 at t≈1267 s) | 158 to 163, 200 to 480 |
| sOiaEv25Fgc (2022) | 77 to 81 (78, 80, 80 at t≈752 s) | 111 to 161, up to 513 |
| HxC68n9hcUU (2025) | 75 to 79 (78, 79, 77, 69, 72, 81, 81, 76, 77 at t≈958 s) | 141 to 289 |
| X3cr8nyi_-s (Nov 2026) | 73 to 77 | 100 to 550 |
| cRVjjXEnd0I (Jun 2026), long fights | **34 to 50** late in a fight (34, 38, 38, 39 …). The first attacks of the same fights run at 67 to 75. | |

## Method

- **Sources**, all downloaded with `yt-dlp` as video only at 720p into `/data/fight-anim-ref/bg/`:
  - [M11gKHV4whs](https://youtu.be/M11gKHV4whs) (Jul 2020, 59.33 fps)
  - [sOiaEv25Fgc](https://youtu.be/sOiaEv25Fgc) (Savjz, Jan 2022, 60)
  - [HxC68n9hcUU](https://youtu.be/HxC68n9hcUU) (Sep 2025, 60 fps upload of a ~40 fps capture: every third frame is repeated)
  - [cRVjjXEnd0I](https://youtu.be/cRVjjXEnd0I) (Shadybunny, Jun 2026, 60)
  - [X3cr8nyi_-s](https://youtu.be/X3cr8nyi_-s) (Sevel, 23 Nov 2026, 60)
  - [FJyKGdqRj4Q](https://youtu.be/FJyKGdqRj4Q) (Aug 2026, 60). Only looked at: its big chain is hidden under full-screen effects and a facecam.

  No download was refused. The 2026 videos with a 60 fps stream play at 60 distinct frames (checked with a frame-difference test).
- **Finding fights:** thumbnail sheets every 6 to 10 s, then labelled contact sheets every 2 to 6 frames, then single-frame strips.
- **Positions:** OpenCV normalised cross-correlation, run in a venv under `/data/fight-anim-ref/venv`. The template was the upper middle of the attacker's portrait, searched over scale 0.8 to 1.6 and rotation ±30°, giving the card's centre and scale per frame. Every track was checked against gridded crops (10 px grid). Where the tracker lost the card (match score below ~0.6, usually in the flash at contact), positions come from the centre of the damage star that sits on the returning card, or were read by eye from the grid (±8 px). The CSV's note column says which.
- **Card height:** the resting oval portrait height in px at that board position (100 to 115 px).
- **Timings:** the source's frame numbers. The 59.33 fps source differs from 60 by 1%, too little to matter. The impact flash and the yellow damage-star counts were detected by pixel-colour thresholds and checked on contact sheets.
- **Per-frame positions:** `battlegrounds_positions.csv`, next to this file. Columns: clip_id, frame, x_norm, y_norm, note. x and y are offsets from the rest position in card heights (y grows downward on screen). Only frames up to contact are tracked, plus the return where it could be traced. A9's long hold is kept in full.

## Doubts

- **Contact frame ±1.** The flash covers the card for 1 to 3 frames, so the stop point and "0 frames held" have ±1 frame of uncertainty. The attacker is clearly moving back 1 to 2 frames after the flash starts in A2, A4 and A6.
- **Stop distance ±0.1 h.** The board is drawn in perspective, the attacker is scaled up ~15% while it moves, and the target's centre was read by eye from the grid. "Overlaps the target's edge" is certain in every measured clip. The exact centre gap is not.
- **Target reaction is not fully measured.** I saw the white impact streak (3 to 6 frames), the damage star (+3 to 4 frames) and the Health number turning red (+3). I did not measure whether the target shakes or recoils, because the flash covers it.
- **Deaths: 40 frames in 2026 against 65 to 68 in 2020 and 2022** is three samples (one each). It may be a real change or may depend on the case.
- **What causes the speed-up** (queue length, fight length, attack count, a hero or an anomaly) can't be told from this footage. It shows only in the Shadybunny 2026 fights, which are long. Within those fights the first attacks run at normal speed (67 to 75 frames) and later ones at 34 to 50.
- **The return** is the least sampled phase: traced cleanly in A2 and A6, roughly in A1 and A4. The flash and damage stars hide it in the others.
- **Commentary videos.** Facecams sit in a corner and never covered a measured card. Unit names weren't needed, so I didn't identify cards.
- **Common belief this disagrees with:** a "lunge" is usually pictured as a pull-back and an eased strike. Battlegrounds does neither: it lifts the card toward the camera and holds it, then strikes in a straight line at constant speed. The weight comes from the hold and the abrupt stop with the scale pop, not from easing.
