# Once Upon a Galaxy, Super Auto Pets and Legends of Runeterra, measured (R2, 24 Nov 2026)

Measured from public gameplay videos, frame by frame. Frames are 60 fps frames (1 frame = 16.7 ms) unless a row says otherwise. "H" = one card height (Galaxy: art top to the bottom of the stat badges, 130 px in the LSV video, 120 px in the Rowan Ribbit video; SAP: one pet sprite, 110 px; LoR: one lane card). Same columns as R1's and R3's tables. Footage stays in `/data/fight-anim-ref/` and is not in the repo.

**Why these games.** Galaxy because the owner named it. **Super Auto Pets** because it is the other big auto-battler whose fights people call easy to read, and it reads in a very different way from Battlegrounds: both front units hit at once, big numbers, a speed button. **Legends of Runeterra** because its combat is cards on a board striking one at a time, with a strong wind-up and a strict order. Hearthstone constructed was left out because, as far as I know (not checked on footage), its minion attack is the same animation as Battlegrounds', which R1 measures. Marvel Snap was dropped for time: it has no attacks, only reveal queues.

## What matters, in short

**Once Upon a Galaxy: a throw with a big wind-up, and one thing at a time.** Very consistent across 7 attacks in two videos:
- **Wind-up 13–14 frames (0.22 s):** the card pulls back 0.44–0.83 H (median 0.58 H) away from its target, grows to ×1.30–1.40 (it "lifts toward the camera"), and tilts 24–40° when the target is diagonal (0–8° when it is straight ahead).
- **Travel 16–17 frames (0.27 s), whatever the distance (1.6–2.4 H).** Pure ease-in: it covers about a quarter of the path in the first half of the time, and it is fastest on the very last frame, at contact. The card shrinks back from ×1.4 to ×1.0 on the way, so it seems to dive into the target.
- **It goes past the target's centre:** at contact the attacker's centre is 0.2–0.57 H *beyond* the target's centre. The cards overlap almost completely.
- **No hold at contact (0 frames):** the next frame it is already going home. **Return 12–28 frames** (median about 15), easing out.
- **Target is knocked back 0.35 H** in 4–8 frames, held about 6 frames, then slides home in a straight line over about 15 frames (about 0.5 s in all).
- **The damage the attacker takes shows first:** a white flash on the target at +2 frames, the attacker's Health digit at +2–3, then a large white star with the number at +3, full size by +12–16, staying about 0.9–1 s. **The defender's damage is sometimes shown late:** at contact in 2 attacks, but 49–51 frames (0.8 s) after contact in the 2 measured attacks where the attacker died. Not sure why (see doubts).
- **Triggers wait until the attacker is home,** then play one after another: an ally's buff (gold ring, about 0.6 s) about 0.7 s after contact, a card flipping over into a new card (0.27 s), a buff on the new card, and only then the next attack's wind-up. **Treasure and spell triggers get a full-size card pop-up** that grows out of the unit's slot (0.27–0.4 s) to about 2.5 times card size over the middle of the board, gets a light sweep across it, holds, and flies off: **about 1.2 s, and the fight waits for it.** The next wind-up starts as it leaves.
- **Deaths:** the card is flung off the board spinning, about 0.5 s, starting about 1 s after the killing contact (after the number star has had its time).
- **Attack to attack:** the attacker's own motion is about 44 frames (0.73 s); contact to the next contact was 1.8–2.6 s in these fights, because the triggers, stars and deaths play between attacks.

**Super Auto Pets (filmed in its Fast mode): both pets hit at once, numbers huge.** The two front pets dash at each other and meet in the middle of the gap in 2–3 frames (under an impact flash), stay pressed together 16–20 frames, and snap home in 4–6. The wind-up is a back-step of about 0.14 H over 3–4 frames, barely visible at this speed. Stats change on the contact frame; huge red numbers over both pets at +1–2 frames, on screen about 0.4 s. A fainted pet turns into a plaster icon at once. One clash every 1.1–1.2 s. Triggered abilities throw visible projectiles (a rock arcing from its source to its target in about 10 frames), so you see what caused the damage. Pause, Fast and Autoplay are on screen during the fight.

**Legends of Runeterra (sampled at 20 fps): lift, slam, one strike at a time, left to right.** Each attacker lifts back away from its target and glows orange (about 12 frames), then slams in about 6 frames: to the enemy Nexus when unblocked, or into its blocker, which moves out to meet it at the lane's midline with a bright horizontal flash line. Damage numbers at contact (within 3 frames), visible about 0.7 s. The next strike waits until the previous one is home and any death (a 0.3–0.5 s shatter) is mostly done: strikes landed 0.65 s and 1.25 s apart.

**What these games do that may help reading, beyond Battlegrounds** (whether Battlegrounds does it is R1's call):
- Galaxy: the **attacker grows ×1.4 during the wind-up**: a size change you can see from across the board, not only a movement. A **card-sized pop-up of the treasure or spell that fired**, coming out of the slot that owns it, so cause → effect is shown by the card itself. **Triggers queue strictly after the attacker is home.** A strong knock-back (0.35 H) on the target.
- SAP: **symmetric hits** (both units move, both numbers at once), **numbers far larger than the stats**, **projectiles that draw a line from cause to effect**, and a **speed button and pause on screen**.
- LoR: a **glow on the unit that is about to act**, **strict left-to-right order**, a **flash line where the two cards meet**, and the **blocker moving out to meet the attacker** halfway.
- None of the three shakes the camera or freezes on hit (no hit-stop) in this footage.

## The owner's four claims, per game

| Claim | Galaxy | Super Auto Pets (Fast) | Legends of Runeterra |
|---|---|---|---|
| (a) Travels all the way to the target | **Yes, and further:** stops 0.2–0.57 H past the target's centre, almost full overlap | **Half way:** both pets dash and meet in the middle of the gap | **Yes** for unblocked (to the Nexus); blocked ones meet the blocker half way |
| (b) Speed is not constant | **Yes:** eased wind-up, ease-in travel fastest at contact (about 25 % of the path at half time), eased return | **Can't tell:** the dash is 2–3 frames under a flash; it reads as a snap | **Yes:** slow lift, very fast slam |
| (c) No pause mid-motion for triggers; the triggered animation comes after | **Yes:** no pause seen in 7 attacks; triggers start about 0.7 s after contact, once the attacker is home. One exception: a start-of-fight spell card stayed on screen about 1.9 s while the next attack played underneath it | **Yes:** projectiles and faints play between clashes, not during the dash | **Yes:** a death after a strike plays once the attacker is home; the next strike waits |
| (d) Wind-up clearly visible | **Yes:** 13–14 frames, 0.58 H back, ×1.4 scale, tilt | **No** in Fast mode: about 0.14 H, 3–4 frames. Normal speed not measured | **Yes:** about 12 frames, lift plus an orange glow |

## Full measurements

### Once Upon a Galaxy, plain attacks

Sources: LSV, "Diving Back In To Once Upon A Galaxy" (17 May 2026), <https://youtu.be/4_uOk8CZu0Y>, 1280×720 at 60 fps; Rowan Ribbit, "Once Upon A Galaxy | August: Season Spider Queen | 3 Thing In The Ice" (3 Aug 2026), <https://youtu.be/KpKgQAe_Jsg>, 1280×720 at 60 fps. Source frame = seconds × 60. Positions tracked by template matching (method below); per-frame rows in `galaxy_and_others_positions.csv`.

| Clip | Link, source frames (wind-up start / contact / home) | Event | Distance, centre to centre | Wind-up | Travel | Stop point vs target | Speed profile (share of path per frame, peak → contact) | Hold at contact | Return |
|---|---|---|---|---|---|---|---|---|---|
| G-A1 | <https://youtu.be/4_uOk8CZu0Y?t=327> 19625 / 19655 / ~19669 | Will-o'-the-Wisp (enemy) hits Davy Jones, straight down; attacker dies | 1.80 H | 13.5 f; 0.62 H back (and 0.32 H sideways), ×1.40, tilt ≤8° | 16.5 f | 0.20 H past centre (0.40 H from it) | 0, .006, .018, .035, .059, .088, .119, .163, .221, .283, .352, .432, .532, .633, .736, .859, 1; fastest on last frame | 0 f | ~14 f (lost under the number star at the end) |
| G-A2 | <https://youtu.be/4_uOk8CZu0Y?t=328> 19733 / 19763 / ~19787 | Davy Jones hits Jack in the Box, diagonal; target dies | 1.92 H | 14 f; 0.54 H back, ×1.35, tilt 24° | 16 f | 0.28 H past | 0, .004, .013, .033, .056, .084, .125, .170, .226, .289, .358, .440, .529, .631, .742, .865, 1 | 0 f | ~24 f (low tracking quality) |
| G-A3 | <https://youtu.be/4_uOk8CZu0Y?t=331> 19873 / 19903 / ~19917 | Jack (enemy) hits Black Jack, straight down; attacker dies | 1.62 H | 13.5 f; 0.58 H back, ×1.40, tilt ≤4° | 16.5 f | 0.38 H past | 0, 0, .006, .015, .033, .060, .090, .129, .176, .229, .291, .363, .444, .532, .634, .744, .865, 1 | 0 f | ~14 f |
| G-A4 | <https://youtu.be/4_uOk8CZu0Y?t=334> 20026 / 20056 / ~20084 | Black Jack hits Stinky, diagonal; both survive | 1.81 H | 13.5 f (start estimated, under a pop-up); 0.44 H back, ×1.30, tilt 24° | 16.5 f | 0.46 H past | 0, .003, .007, .018, .034, .055, .086, .125, .173, .229, .290, .360, .438, .533, .636, .746, .868, 1 | 0 f | ~28 f |
| G-A5 | <https://youtu.be/4_uOk8CZu0Y?t=368> 22119 / 22149 / ~22166 | Despicable Sneak (enemy) hits Anthelica, diagonal | 1.70 H | 13.5 f; 0.56 H back, ×1.40, tilt 24° | 16.5 f | 0.57 H past | steps in pairs here (the video repeats frames in this stretch); same curve | 0 f | ~17 f |
| G-A6 | <https://youtu.be/4_uOk8CZu0Y?t=369> 22180 / 22210 / ~22225 | Anthelica hits Tin Man, diagonal | 2.21 H | ~13.5 f (start estimated); 0.68 H back, tilt ≥40° (search limit) | 16.5 f | 0.52 H past | 0, 0, .007, .018, .036, .091, .091, .127, .173, .225, .290, .361, .439, .532, .631, .754, .868, 1 | 0 f | not measured (lost) |
| G-A7 | <https://youtu.be/KpKgQAe_Jsg?t=39> 2382 / 2412 / – | Dragonling (enemy) hits Mysterious Egg, diagonal; second video, same game build family | 2.38 H | 13.5 f; 0.83 H back, ×1.40, tilt ≥40° | 16.5 f | 0.37 H past | 0, .002, .014, .030, .052, .085, .123, .169, .225, .288, .360, .441, .533, .636, .743, .864, 1 | 0 f | not measured |

Same attacks, what happens around the hit:

| Clip | Target reaction | Numbers and Health vs contact | Death | Total |
|---|---|---|---|---|
| G-A1 | Davy knocked 45 px = 0.35 H straight back over 8 f, held ~6 f, straight-line return ~15 f (frames 19663–19700) | Blue-white flash on Davy +2 f; Wisp Health 8→0 at +2 f; star "21" on the Wisp from +3 f, full size by +13 f, still there at +44 f. **Davy's Health 55→45 and its star "10" only at +49 f** (t≈328.4) | Wisp flung up-left, spinning, ≈328.67–329.13 s (~0.5 s), starting ~1.1 s after contact | Wind-up start → home ≈ 44 f; next wind-up starts 1.3 s after contact |
| G-A2 | Jack in the Box pushed back (15 fps sheet, 329.6–329.8) | Davy's Health 45→30 at contact; star "15" on Davy and "21" on Jack in the Box within +8 f | No death: the card flips over into "Jack" (see G-T2) | Next attack's wind-up 1.83 s after contact |
| G-A3 | Black Jack knocked 45 px = 0.35 H in 4–5 f, slight drift to 0.36 H by +12 f, held to +16 f, straight-line return 14 f; home at +30 f (track T3) | Jack's Health 10→0 at +3 f; star "15" on Jack +6 f, full +16 f, gone at +58 f (~1 s). **Black Jack's Health 40→31 at +51 f**, together with its Worn Shield pop-up | Jack flung up-left from +60 f to +88 f (~0.47 s) | – |
| G-A4 | Stinky pushed (15 fps sheet) | Black Jack's Health 32→19 at contact (±4 f); Stinky's 39→23 at +4–8 f; stars "16" and "13" from +4 f | none | – |
| G-A5/A6 | – | Anthelica's Health 56→40 and "16" star at contact +2–4 f; after G-A6, "35" on Tin Man and "5" on Anthelica within +4 f | Two enemy units (the Sneak and Scorn) flung **together** ≈369.8–370.05 s, after G-A5's attacker was home: deaths are batched | – |

### Once Upon a Galaxy, triggers

| Clip | Link, time | What fires | When it starts vs the attacker's motion | How it looks, how long | Simultaneous or in turn |
|---|---|---|---|---|---|
| G-T1 | <https://youtu.be/4_uOk8CZu0Y?t=332> 332.57–333.80 s | Worn Shield (treasure on Black Jack), after G-A3's hit | +0.85 s after contact; the attacker (Jack) has been home since +0.23 s | Pop-up grows out of Black Jack's slot over 0.27 s to ~2.5× card size over the middle of the board, holds, light sweep across it (~0.2 s, 332.85–333.10 s 15 fps), flies off left ~0.15 s. **≈1.23 s in all.** Two-Headed Dragon's stats 20/20→22/22 change during the hold | Black Jack's Health change shows in the same frame the pop-up starts. The next attack's wind-up starts as the pop-up leaves (333.78 s) |
| G-T2 | <https://youtu.be/4_uOk8CZu0Y?t=329> 329.4–331.3 s | Chain after G-A2: Stinky's buff → Jack in the Box turns into Jack → Jack's buff → Jack attacks | Stinky's buff at +0.73 s (330.13), attacker home since ~+0.4 s | Stinky: stats 11/37→12/38 and a gold ring of sparkles (~0.6 s). Jack in the Box tilts and flips over in place 330.33–330.6 (0.27 s) and is "Jack 2/2". Jack's stats 2/2→9/10 at 331.2 with purple sparkles. Jack's wind-up starts 331.22 | **In turn**, each step after the last, small overlaps at the joins (the buff sparkle runs into the next wind-up). Whole chain from contact to the next wind-up: 1.83 s |
| G-T3 | <https://youtu.be/4_uOk8CZu0Y?t=332> 332.43 s | Stinky's buff after G-A3 (Jack about to die) | +0.72 s after contact | Gold ring, ~0.6 s | Runs **at the same time** as the number star and, from 332.57, the Worn Shield pop-up |
| G-T4 | <https://youtu.be/4_uOk8CZu0Y?t=371> 371.28–372.95 s | Bounty Contract (treasure) after Black Jack kills Nameless One | Pop-up starts +0.42 s after the killing contact, while the victim is still being flung | Same pop-up: grow ~0.4 s (12 fps), light sweep ~0.5 s, fly off left. **≈1.25 s.** Black Jack's stats change during it | Black Jack's own next attack's wind-up starts as the pop-up leaves (372.95) |
| G-T5 | <https://youtu.be/4_uOk8CZu0Y?t=374> 374.95–~376.2 s | Twinshot (treasure) after White Whale dies on Black Jack | Starts +0.4 s after contact, during the death fling | Same pop-up, ≥1.0 s | Fight ends under it |
| G-T6 | <https://youtu.be/4_uOk8CZu0Y?t=367> 367.85–369.75 s | Lightning Bolt (a spell cast at the start of the fight, from Anthelica) | Before any attack | Anthelica glows; the spell card pops out of it (0.25 s) and **stays on screen over our front row ~1.9 s** with a light sweep. **The fight carries on underneath:** the enemy's buff (14/7→16/7) and its whole attack G-A5 play while the card is shown. Scorn's Health 6→0 at 368.8 s (number only); its star "20" and death only at 369.8 s, batched with G-A5's victim | The one case in this footage where a trigger's display and an attack overlap |

**Many triggers of the same kind:** not seen in the Galaxy footage I measured. Not answered for Galaxy.

### Super Auto Pets

Source: "How To Win Every Time | Super Auto Pets" (604 s), <https://youtu.be/e-o1eG1C_bU>, 1280×720 at 60 fps. **The Fast button is lit in every battle**, so these are Fast-mode numbers. The game appears to draw at 30 fps in this video (many frames come in identical pairs), so ±1 frame. H = one pet sprite, 110 px; the two front pets stand 1.5 H apart.

| Clip | Link, time | Event | Wind-up | Travel | Stop point | Hold at contact | Return | Numbers vs contact | Target, deaths | Total / cadence |
|---|---|---|---|---|---|---|---|---|---|---|
| S-A1 | <https://youtu.be/e-o1eG1C_bU?t=451> contact 451.93 s (source frame 27116) | Rhino and Buffalo clash | back-step ~0.14 H, 3–4 f (tracked) | 2–3 f, each pet covers about half the gap; under a white flash | Pets pressed together in the middle | ~16 f pressed together | 4–6 f snap | Health on both changes on the contact frame; red "8" and "13" over both at +1–2 f, on screen ~22 f (0.37 s) | Both move; no separate knock-back | Next clash 1.17 s later |
| S-A2 | <https://youtu.be/e-o1eG1C_bU?t=453> contact 453.10 s | Rhino vs Buffalo again; Buffalo faints | not visible | ≤3 f | middle | ~20 f | ~4 f | numbers at +2 f, ~27 f on screen | Buffalo becomes a plaster icon at +3 f and stays in place while the pets are pressed together; what replaces it was not clear at this size | Next clash ~1.1 s later |
| S-A3 | <https://youtu.be/e-o1eG1C_bU?t=454> contact ≈454.2 s (20 fps sheet) | Next front pair | not visible at 20 fps | ≤1 sample | middle | ~0.3 s | – | numbers "8" and "4" at contact sample | – | further clashes ≈454.9 and ≈455.5 s |
| S-T1 | <https://youtu.be/e-o1eG1C_bU?t=453> 453.45–453.62 s | A thrown rock (an ability) hits our Swan, between clashes | Starts 0.35 s after S-A2's contact, once the pets are apart | Grey rock arcs over the pets to the target in ~10 f; flash on impact; "3" over the Swan and Health 27→24 at impact | – | In turn: the next clash comes after it lands |
| S-T2 | <https://youtu.be/e-o1eG1C_bU?t=451> 451.1–451.9 s | Start-of-battle ability: green melon particles cover two pets | Before the first clash | Particles swarm the pets ~0.8 s, burst at the first clash | – | The first clash starts while they are still on screen |

### Legends of Runeterra

Source: "Cast To Kill | Legends of Runeterra | No Commentary", <https://youtu.be/FJCxXTedbTk>, 1280×720 at 60 fps. **Measured from a 20 fps sheet** (one sample = 3 frames), so every frame count is ±3 f. Strikes are vertical: attackers in the middle lane slam down at our blockers or the Nexus.

| Clip | Link, time | Event | Wind-up | Travel | Stop point | Hold | Return | Numbers vs contact | Deaths | Cadence |
|---|---|---|---|---|---|---|---|---|---|---|
| L-A1 | <https://youtu.be/FJCxXTedbTk?t=413> 413.9–414.25 s | Left attacker, unblocked, hits our Nexus | Lifts away from us and glows red-orange, ~12 f | ~6 f slam all the way to the Nexus | Nexus; white impact burst | ≤3 f | 6–9 f back up to its lane | "−4" on the Nexus +3–6 f | The attacker then flashes and dissolves in purple particles (414.3–414.65), after it is home. Probably a keyword that kills it after striking; not checked | – |
| L-A2 | <https://youtu.be/FJCxXTedbTk?t=414> contact ≈414.8 s | Middle attacker vs our blocker | Lift and glow, ~6–9 f (both cards glow) | ~6 f; **both cards move** and meet at the lane's midline | Midline, horizontal orange flash line | ≤3 f | ~3–6 f | Damage colours and "−4" on our blocker from +3 f, ~0.7 s | Our blocker shatters 415.6–415.85 s (blue spirit rises) | 0.65 s after L-A1 |
| L-A3 | <https://youtu.be/FJCxXTedbTk?t=415> contact ≈416.05 s | Right attacker vs our blocker | Lift and glow ~6–9 f, starting as L-A2's death ends | ~6 f, both move | Midline flash line | ≤3 f | ~3 f | "−1" on both +3 f | – | 1.25 s after L-A2 (waited for the death) |
| L-T1 | 414.3–414.65 s | Attacker dies after its strike (see L-A1) | After the attacker is home | Flash, then dissolve ~0.35 s | – | In turn, then L-A2's wind-up |
| L-T2 | <https://youtu.be/FJCxXTedbTk?t=158> 160–164 s and <https://youtu.be/FJCxXTedbTk?t=485> | Spells and skills on the stack | Outside combat | A line is drawn from the spell to its target; a caption says what it does ("Drain 2 from a unit", "Deal 3 to an enemy"); items resolve one at a time | Not timed (sheets at 3–5 fps only) | In turn |

## Method

- **Downloads:** `yt-dlp` 2026.10.26, 720p60 video only, into `/data/fight-anim-ref/<game>/`. No download was refused. yt-dlp warned it had no JavaScript runtime; the 60 fps formats came through anyway.
- **Finding fights:** contact sheets at 1 frame per 4–5 s, then 5–6 fps sheets per fight, then 15–30 fps sheets with frame numbers around each event, then 60 fps sheets at contact. All read by eye.
- **Positions (Galaxy, SAP):** OpenCV template matching (normalised correlation with a mask) on the grey 720p frames at the source rate. The template is the top 62 % of the card (art and name plate) cut from a frame where the card is at rest and clear; each frame is searched over scale ×0.85–1.55 and tilt ±40°, in a window around the last position. The tracked point is the centre of that art area; the target's rest point is measured the same way, so "past the centre" compares like with like. Frames with match quality below about 0.45 (under a number star or a flash) are marked in the CSV and not used. Wind-up start = first frame off rest; wind-up peak = furthest back; contact = the furthest frame toward the target (the next frame always moves back); home = within ~3 px of rest.
- **Speed profile:** the attacker's position projected on the line from its rest point to the target's, rescaled so the wind-up peak is 0 and contact is 1.
- **Card height:** measured by eye on gridded frames (LSV 130 px, Rowan Ribbit 120 px; the front rows are 1.62 and 1.68 H apart in the two videos, which agrees). ±5 %.
- **Timing of numbers and stars:** by eye on 15–60 fps sheets; ±1 sample of the sheet used.

## Doubts

- **Galaxy's late defender damage** (G-A1, G-A3: about 0.8 s after contact, both times where the attacker died) may be how the game orders its log (the attacker's death first?) rather than a deliberate display choice. Two cases only, and in G-A4 (no death) it showed at contact.
- **Galaxy speed:** the two videos agree to the frame on wind-up and travel (13.5 f and 16.5 f), so I believe neither was sped up. Part of the LSV video (368–370 s) repeats frames in pairs, so the game or the capture dropped to 30 fps there; numbers in that stretch are ±1 f.
- **Galaxy tilt** above 40° would not be found (search limit). The returns are less sure than the wind-ups: the number star often covers the card on its way home.
- **Galaxy game version:** the LSV video is from May 2026 and the other from Aug 2026; the attack timing is the same in both. Not checked against the current version.
- **Super Auto Pets was in Fast mode.** Normal speed would be slower; I did not find or measure normal-speed footage. The game's own frame rate in the video seems to be 30.
- **Legends of Runeterra** was sampled at 20 fps, not stepped at 60; its rows are ±3 f. Only one combat (3 strikes) measured; spells on the stack were not timed.
- **Many triggers of the same kind** (grouping, speed-up, counters): not found in any of the footage I measured, for any of the three games. That question is still open for R2's games.
- No game showed camera shake or hit-stop here, but small shakes (2–3 px) would be hard to see at 720p.

## Files and scratch

- `galaxy_and_others_positions.csv` (next to this file): Galaxy G-A1–G-A7 per frame (positions in card heights from the rest centre, +y down; notes say wind-up, travel, contact, return, scale and match quality), SAP S-A1 (rhino, with quality), LoR L-A2 by eye.
- Scratch, not committed: `/data/fight-anim-ref/galaxy/`, `sap/`, `lor/` (videos and `work/` with sheets and tracker output). Scripts in this session's scratch folder (`track.py`, `metrics.py`, `sheet.sh`, `grid.py`).
