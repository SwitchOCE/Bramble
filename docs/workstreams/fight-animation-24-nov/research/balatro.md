# How Balatro animates scoring, late in a run (25 Nov 2026)

Findings only. Nothing here is a proposal to build. The owner, 25 Nov: "investigate Balatro animations … from probably towards the later part of the game … it also does sound and animation pairing really, really well, which I know is beyond our scope. But just some findings … don't act on the findings yet."

**How to read it.**
- Every time is in frames at 60 fps (1 f = 16.7 ms). All five measured sources are 60 fps uploads at 1280 × 720.
- Each claim is marked **M** (measured on frames), **E** (seen by eye on frame strips) or **S** (from a source, linked).
- "Trigger" means one scoring event: one popup such as "+10", "X1.5 Mult", "Again!" or "$2", with its counter change.
- The footage stays in `/data/fight-anim-ref/balatro/`. No frame or crop of it is in the repo. The onset times behind the tables are in `balatro_trigger_onsets.csv`, next to this file.
- **The game-speed setting of each video is unknown.** Balatro has a speed option (§6), and the videos don't show it. The ratios inside one hand (how much faster the 100th trigger is than the 1st) don't depend on it; the absolute frame counts do. Two sources (dP8 and HZ) have the same curve, frame for frame, so they very likely ran at the same setting. 1Q6's first gaps are about twice theirs, so it may have run at half their speed.

## 1. The short version

1. **One thing at a time, never two.** A hand of 2,000 triggers still plays them one by one. Each popup replaces the last instead of stacking. **M**
2. **Each trigger gets shorter as the hand goes on.** It falls from about 15 f to a floor of about 6 f, a 2.5× speed-up, reached after about 100 triggers. It's a smooth curve, not a step. **M** LocalThunk says this is on purpose: by then "you're not actually really reading everything that's happening on the screen … so now here's the fireworks and you get the final number." **S**
3. **One trigger is three things on the same frames, all at its source.** The source card pops on a spring (about ×1.27, then ×0.85, then ×1.08, still by +15 f). A popup with the amount appears over the source. The counter slams its new digits in, white and shaking, for about 7 f. **M** Nothing travels from the card to the counter: timing alone links them. **E**
4. **Counters slam; they don't roll.** Only the final transfer, from the hand total into the round score, counts up, and it takes about 8 f. **M**
5. **Late on, the spectacle wins over the number.** Flames on the counters grow with the score. At the extreme, white shards cover the counters on most frames. Large numbers turn into scientific notation ("1.920e78") in a shrinking font. **E** The end of a hand is a big total and a burst, then the total drops into the round score. **M/E**
6. **Juice is everywhere and constant:** idle sway, a swirling background, a CRT filter, a hand-written "physics engine" for card motion. One "Reduced Motion" toggle removes "the swirly background, gyrating card motion, much of the 'juice' in the game". **S**

## 2. Scoring cascades late in a run

### 2.1 The trigger rhythm across a hand (the main measurement)

Each row is one hand. The gap is the median of 9 consecutive popup-to-popup gaps around that trigger.

| Chain | Source | What triggers | Triggers in the hand | Gap at the 1st | 10th | 20th | 30th | 50th | 100th | 200th and on | Hand, from play to total |
|---|---|---|---|---|---|---|---|---|---|---|---|
| HZ5: ante 5 Four of a Kind | HZ, [t=12:39](https://youtu.be/_Hz7Qbn2g6Y?t=759) | 4 scoring cards, a gold seal, 2 jokers | ~12 | 16 | 13 | – | – | – | – | – | **~215 f (3.6 s)** |
| 1Q6: ante 24 Flush Five | [1q6ehsbF5Kg?t=15](https://youtu.be/1q6ehsbF5Kg?t=15) | 5 red-seal glass kings, retriggers, ×mult jokers | ~205 | 28 | 22 | 14 | 9 | 9 | 10 | 8 | **~2,235 f (37 s)** |
| XA: ante 16 Flush Five | [XazjkqTRAfY?t=26](https://youtu.be/XazjkqTRAfY?t=26) | Same kind of build | ~93 | 13 to 20 | ~20 | 7 | 6 | 7 | – | – | ~1,100 f (18 s) |
| dP8: naneinf, 61 held kings | [dp8RgqcENXs?t=192](https://youtu.be/dp8RgqcENXs?t=192) | Baron ×1.5 per held king, Mime retriggers | ~890 | 15 | 12 | 11 | 9 | 8 | 7 | **6 to 7** | **~6,420 f (107 s)** |
| HZ: ante 15, held kings | [_Hz7Qbn2g6Y?t=3757](https://youtu.be/_Hz7Qbn2g6Y?t=3757) | The same build | ~2,300 (2,025 counted in the first 13,000 f) | 16 | 13 | 11 | 9 | 7 | 6 | **6** | **~14,900 f (4 min 8 s)** |

What this shows:
- **The gap shrinks with the trigger count, not with time or with the kind of trigger.** **M** dP8 and HZ, different runs and different players, give the same curve: 15–16, 12–13, 11, 9, 7–8, 6. The same ×1.5 trigger runs at 15 f early in the hand and 6 f later.
- **The speed-up is gradual.** It is about 1.4× by the 20th trigger, 1.7× by the 30th, 2× by the 50th, and 2.5× at the floor (6 f) from about the 100th. **M**
- **The floor holds.** In HZ the gap stays at 6 f for 1,900 triggers in a row. **M**
- **1Q6 starts at 28 f and falls to 8 to 10 f by the 30th trigger**, a 3× drop over a shorter span. Its cycle mixes chips, "Again!" retriggers and four ×mult popups per card. The cycle for the same card shrank from 113 to 100, 93, then 77 to 70, 65 to 60, 59 to 55, and finally 53 to 50 f. **M**
- **A small late hand never gets fast.** The ante 5 hand has about 12 triggers at 13 to 16 f. The speed-up only matters in big hands. **M**
- The order (E, from the strips): played cards score left to right, each with its own effects and the jokers that react to it. Held-in-hand effects come next, then the jokers left to right, then the deck effect (Plasma's "Balanced").

### 2.2 One trigger, frame by frame

The slow phase is measured on 1Q6's ×1.5 trigger at frame 1020 (gap 30 f). The normal phase is measured on HZ5's +10 chip trigger at frame 45623 (gap 15 f).

| Piece | 1Q6, slow phase | HZ5, normal hand | Mark |
|---|---|---|---|
| **Counter** | At f 0 (frame 1020) the new value (140 → 210) is drawn larger than the box, white with a coloured outline, each digit jittering. It is back to normal size by +4 to +5 f. | f 0 = frame 45621. 320 → 330: white, enlarged and jittered digits for 7 f (45621–45628), then plain. | M |
| **Source card pop** (half-height from the card's bottom edge; rest = 1.00) | 0.93 at f 0, **1.27 at +2**, **0.84 at +5**, **1.08 at +9**, 0.97 at +12, rest by +15. It also tilts a few degrees at the peak. | **1.28 at +2 to +3**, **0.88 at +6**, **1.08 at +9 to +10**, 0.97 at +12 to +14, rest by +15. | M (tilt E) |
| **Popup** | Appears at +3 above the source card, small, then grows. Its text writes on letter by letter ("X1.5 M", "X1.5 Mu", "X1.5 Mult") over ~7 f, then holds until the next popup replaces it at +30. | "+10" (blue) appears at +3 (45624) above the card, grows over ~15 f, and is gone at +20, just before the next popup. | M |
| **Popup look** | The amount plus the operation, on a blob coloured by stat: blue for chips, red for mult, orange "Again!" for a retrigger, gold for money, grey for ×1.5 on glass. | Plain "+10" in blue. | E |
| **At the floor** (dP8, 6 f per trigger) | The counter changes every 6 f. Each popup takes 2 f to grow, holds 2 f with its full text, and fades over 2 f. | – | M (the 2/2/2 split is ±1 f) |

- **The counter, the card pop and the popup all start within 3 f of each other,** in the same order in both clips: counter at 0, card pop at +1 to +2, popup at +3. **M** That is the only link between cause and number. Nothing flies to the counter. **E**
- **A joker's trigger is drawn at the joker,** in the top row, with the joker wobbling. **E** For example, "+10 Mult", "+5" and "+50" at 1Q6 frames 3089–3104.
- **The pop keeps its shape whatever the gap.** It lasts about 15 f in both the 30 f phase and the 15 f phase. **M** At the 6 f floor it must be cut short or overlap the next one. I didn't measure which.

### 2.3 Before and after the triggers (normal hand, HZ5)

| Beat | Frames | Mark |
|---|---|---|
| Cards rise from the hand into the play area | ~45540 → first popup at 45580: **~40 f** (1Q6: 72 f; dP8: ~30 to 60 f) | M |
| The hand total appears, replacing the hand name ("Four of a Kind" → "18,330"). It is big, white and shaking, and both counters reset to 0 × 0 with the same slam. | **10 f** shaking (45736–45746), 2 f still | M |
| The total transfers. The hand total counts down while the round score counts up: 23,595 → 26,675 → 32,838 → 39,049 → 41,925. The steps are small, large, large, then small, so it eases in and out. | **~8 f** (45749–45756) | M |
| The played cards fly off to the right. A text line ("4 Remaining") writes on letter by letter. | 12 to 15 f; ~20 f | M/E |

## 3. Counters and huge numbers

| Behaviour | Detail | Mark |
|---|---|---|
| Each change is a slam, not a roll | The new value appears whole on one frame, enlarged and jittering, then settles in 5 to 7 f. No roll-up between the old and new values. | M |
| The only roll | The final transfer into the round score, ~8 f, eased | M |
| Number format | Up to about 10⁶ with commas ("41,925"). Beyond that, scientific notation in the counter ("1.251e64", "4.743e78"), in a smaller font that fits the box. Past the float limit, the game shows "naneinf". | E |
| Flames | Flames rise from the chips (blue) and mult (red) boxes once the hand is set to beat the blind, and stay on the 0 × 0 boxes after the total, changing colour. In 1Q6 they burn for more than 100 f after the total. Players read them as "you can already start celebrating" ([Kotaku](https://kotaku.com/best-video-game-moment-2024-astro-bot-marvel-dragon-age-1851733392/15)). LocalThunk calls the flame his most productive night's work and one of the features he is proudest of ([GamesRadar](https://www.gamesradar.com/games/roguelike/after-winning-big-at-the-game-awards-and-taking-hours-of-our-time-in-2024-balatro-creator-reveals-their-most-productive-night-resulted-in-one-of-the-games-most-satisfying-features)). | E, S |
| At the extreme | Deep in HZ's long chain (frame ~232,200), large white angular shards burst from the mult box and cover the side panel on most frames. The mult value is unreadable for long stretches. At the end of 1Q6, white shards cover the counters for ~10 f (3122–3131) as the total lands. | E |
| Shake | Measured on fixed HUD areas by phase correlation. 1Q6: the whole screen shifts by up to **2 to 3 px at 720p** on ~6% of frames during the hand. dP8 and HZ: **0 px**, even in their 2,000-trigger chains. Screen shake is a setting (§6), so those two players may have turned it off. | M |

## 4. Readability: what you can follow and what blurs

| Phase | Gap | What a player can read | Mark |
|---|---|---|---|
| A normal hand | 13 to 16 f | Every popup with its full text, which card or joker fired, and each counter step. | M (timings), E (readability) |
| Mid-chain | 8 to 10 f | The popup's colour and number. "Mult" is half-written when the next popup arrives. The counter changes too often to read each value. | M/E |
| The floor | 6 f | The full text shows for 2 f only. What's left is a rhythm of colours (red, red, red, orange "Again!", blue), the counter's exponent creeping up, and the flames growing. Single values blur. | M/E |
| The finish | – | The one number that matters (the total) is shown big, alone, for 10+ f, then drops into the round score. | M |

- **The blur is on purpose.** LocalThunk, on the late game, in an auto-generated, unpunctuated transcript: "at the end game and there's all this crap going on on the screen … it accelerates the speed at which the um all the animations take place … because I know that you're not actually really reading everything that's happening on the screen … you've already done all the work … so now here's the fireworks and you get the final number". Elsewhere: "it's just fun numbers and fire and and colors at that point it's just kind of like a victory lap" ([Game Maker's Notebook, 9 Dec 2024](https://gamemakersnotebook.libsyn.com/balatro-creator-localthunk-talks-inspirations-and-jokers), [transcript](https://sozai.app/transcript/balatro-creator-localthunk-inspirations-jokers/) ~107:13 and 108:10–108:39). **S**
- **What keeps it followable:** a fixed counter position, one popup at a time, the popup always at its source, a colour per stat, and a fixed order (cards left to right, then held cards, then jokers). **E**
- **The cost:** a 2,000-trigger hand takes 4 minutes, and players ask for more speed and a skip ([Steam, speed](https://steamcommunity.com/app/2379780/discussions/0/6426156954538745672), [Steam, skip request](https://steamcommunity.com/app/2379780/discussions/0/4346606879508270539)). AV Club: "By the end of particularly massive payouts, it's all passing in a blur" ([AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up)). **S**

## 5. Juice

| Element | What it does | Mark |
|---|---|---|
| Idle sway | A joker in the top row tilts by up to ~2° and back over about 2 s. Its drawn height breathes ±1.5%, like a slight 3D tilt (HZ frames 45770–45900). Cards in the shop "gently sway as if suspended" ([AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up)). | M (rough), S |
| Hover and select | A hovered card shows its tooltip. A selected card rises and tilts a few degrees. The hand fans up from below when drawn. | E |
| Hand-made card physics | LocalThunk: "I made like my own physics engine for the game". He spent "an absurd amount of time just like changing a formula a little tiny bit … mousing my cursor over a card moving it around seeing how it feels", and wants "to just make the card jiggle good again" ([transcript](https://sozai.app/transcript/balatro-creator-localthunk-inspirations-jokers/)). The host: "It Feels So Punchy when these cards are like slamming down or you know shaking". | S |
| Spring pop on every trigger | See §2.2: overshoot, undershoot, overshoot, settled by +15 f. Uniform scale plus a small tilt; the card never bends. | M |
| Text that writes on | Popups, the hand total, "Balanced" and "4 Remaining" appear letter by letter. "Balanced" takes ~12 f (1Q6 3107–3119). | M/E |
| Background and filter | A swirling shader background, a CRT barrel distortion and scan lines. LocalThunk: "I just really love writing shaders … The swirly background and the kind of gyrating cards, and I just felt like it was all cohesive" ([Game Informer](https://gameinformer.com/interview/2024/03/21/balatro-was-almost-called-joker-poker-and-other-details-from-its-creator)). | S |
| Particles | White shards from the counters on big scores. Flames on the counters. | E |

## 6. Settings

| Setting | What it does | Mark |
|---|---|---|
| Game speed | Players name ×1, ×2 and ×4; some want ×3, or ×8 and up. One says ×1 "felt positively glacial", another that the step from 2 to 4 "is WAY too fast" ([Steam](https://steamcommunity.com/app/2379780/discussions/0/6426156954538745672)). A 0.5× option and the default value could not be confirmed. LocalThunk tested every new feature by raising the speed "even when you ramp the game up to 4X speed … how far can I push this thing before it really starts to like show its cracks … make sure it looks good along every step of the way" ([transcript](https://sozai.app/transcript/balatro-creator-localthunk-inspirations-jokers/)). | S |
| How speed changes the above | Not measured: no source shows the same hand at two settings. The automatic speed-up in §2.1 works on top of whatever setting the player chose. dP8 and HZ, probably at the same setting, share one curve. | M (curve), unknown (setting) |
| Reduced Motion | Added in 1.0.1: "removing the swirly background, gyrating card motion, much of the 'juice' in the game" ([patch notes via MP1st](https://mp1st.com/news/balatro-update-1-07-shuffles-out-this-may-16), [Nintendo Everything](https://nintendoeverything.com/balatro-update-announced-version-1-0-1-patch-notes/)). | S |
| Screen shake, CRT | Separate settings, per players ([Steam thread](https://steamcommunity.com/app/2379780/discussions/0/4346606879522655969)). | S (weak) |

## 7. Sound pairing (beyond our scope; brief)

- **Not measured.** The owner's footage rule allows video only, so there was no audio to line up with frames. Measuring sound against motion to the frame would need audio from the same videos. That's the owner's call.
- **What sources say.** "Base chips are added with a satisfying click, followed by an ascending ring for the multipliers, with each consecutive effect added by a Joker slightly increasing the pitch and speed of the process", building "into a breakneck, euphoric crescendo"; "your final chip tally clinks as if you won a jackpot" ([AV Club, 1 Mar 2024](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up)). **S**
- **What the pictures suggest.** Every trigger is a single onset frame (counter, pop and popup within 3 f), which gives a sound one clear frame to land on. The rising pitch the AV Club describes runs alongside the shrinking gaps measured in §2.1: pitch and tempo climb together. **E** (inference)
- An earlier note in this workstream (`../buff-look/DESIGN.md` §1) gives "+1.6% pitch per trigger" from a reverse-engineered copy of the game's code. I did not re-check it, because this study does not use the game's files.
- The soundtrack is by LouisF ([Wikipedia](https://en.wikipedia.org/wiki/Balatro)). No interview about the scoring sounds was found.

## 8. Method

- **Sources.** All were downloaded with `yt-dlp`, video only, 720p60 (format 298), into `/data/fight-anim-ref/balatro/`. All are 60 fps; a frame-difference check shows distinct frames, with a duplicate frame every few hundred.

| ID | Video | Used for |
|---|---|---|
| HZ | [_Hz7Qbn2g6Y](https://youtu.be/_Hz7Qbn2g6Y), Roffle Lite, "I Scored naneinf on Gold Stake (Unseeded and Unmodded)", 87 min | The normal hand (HZ5), the 2,000-trigger chain, idle sway, shake, hover |
| 1Q6 | [1q6ehsbF5Kg](https://youtu.be/1q6ehsbF5Kg), "An Average Turn In Lategame Balatro", 66 s, ante 24 | The single-trigger frame study, the end-of-hand sequence, shake |
| dP8 | [dp8RgqcENXs](https://youtu.be/dp8RgqcENXs), Evil Pancake, seeded naneinf speedrun, 5 min | The 890-trigger chain, popup at the floor, shake |
| XA | [XazjkqTRAfY](https://youtu.be/XazjkqTRAfY), ante 16, 52 s | A fourth trigger curve (noisy: the red board and red seals add false onsets) |
| – | [ywRtrJktO5M](https://youtu.be/ywRtrJktO5M), [RCPy9qEZnfs](https://youtu.be/RCPy9qEZnfs), [6e8-QeANHJU](https://youtu.be/6e8-QeANHJU), [MQyaOLqfmJs](https://youtu.be/MQyaOLqfmJs), [EFEauLTZZJ0](https://youtu.be/EFEauLTZZJ0), [S3kUbN_zaLw](https://youtu.be/S3kUbN_zaLw) (30 fps) | Looked at on thumbnail sheets only. They are edited, time-lapsed, modded ("128x Speed") or slides, so they weren't measured. |

- **Finding hands:** thumbnail sheets every 5 to 60 s, then sheets every 1 to 4 frames.
- **Trigger onsets:** per frame, the count of saturated red, blue and orange pixels in a band over the source cards. An onset is a popup appearing from nothing, the dominant colour changing, or the area collapsing to under half (the next popup replacing the last). Checked against single-frame strips: in dP8 frames 13000–13035 the detected onsets fall within 1 to 2 f of the mult counter's changes, which come every 6 f. Grey popups (glass ×1.5) are missed, so 1Q6's gaps are slightly overstated where they occur.
- **Card pop:** the bottom and left edges of the light card face per frame, in a fixed column band. Scale is the half-height measured from the bottom edge to the resting centre. The top edge is unreliable, because the popup overlaps it.
- **Shake:** phase correlation of fixed HUD regions (the Hands/Discards/money panel, the deck) against the first frame of the hand.
- **Idle:** the minimum-area rectangle of a white joker card's face.
- **Not used:** the game's own files or any decompiled copy of them (the owner's rule), and the Blake Crosley "Balatro" design guide, whose timings are the author's CSS examples, not measurements ([blakecrosley.com](https://blakecrosley.com/guides/design/balatro)).

## 9. Doubts

- **The game-speed setting is unknown for every source.** Absolute frames could all be ×2 or ×4 off from the default. The ratios and the curve shape hold.
- **Whether the speed-up follows the number of triggers or the time since the hand began** can't be told apart, because both grow together. LocalThunk's words point to the late-game state, not to a timer.
- **Popup onsets are ±1 to 2 f,** and the detector misses grey popups and merges two popups less than 3 f apart.
- **The card-pop numbers come from two triggers.** The shape matched closely, but it's a small sample. The tilt was seen, not measured.
- **The white shards** were seen in one video (HZ) at extreme values and briefly in 1Q6. I can't say what makes them appear.
- **Shake ≤ 3 px** in 1Q6 might be the stream's encoding drifting, not game shake. Two of three sources show none.

## What Bramble could learn

Findings, not proposals. Each names what in our plan (`../PLAN-implement.md`, `../practice/GUIDELINES.md`) it bears on.

1. **A smooth speed-up tied to the count, not a step.** Balatro shortens every trigger a little: about 1.4× faster by the 20th, 2× by the 50th, 2.5× from the 100th, then a floor. Our late-fight speed-up is a step: ×1.5 from the 5th attack. A Bramble fight has tens of attacks, not hundreds, so Balatro's curve at our lengths (1.2× to 1.7×) is close to ×1.5 in size but smooth in shape. *Bears on:* the speed-ups from the 5th attack (CB16 FAST), T8.
2. **Speed comes from shorter beats, never from playing things at once.** Even 2,000 triggers play one by one, each popup replacing the last. *Bears on:* up to 3 triggers at once (CB16 GROUP) and T7. Balatro shows a single-file chain can stay followable, but a fight with many triggers would be slower than with GROUP. Balatro accepts 4-minute hands; "fights clear and not slow" doesn't.
3. **Cause, popup and number land within 3 f, and nothing flies.** The source pops, the amount appears over the source, and the counter slams, all together. Balatro's counter sits in one fixed place, so timing alone ties cause to number. *Bears on:* +N gains flying in (CB14 c) and V2/V4. Our stats sit on moving cards, so a flight may still be needed where Balatro needs none. Timing could carry part of the link and let the flight be short.
4. **The pop is a spring: overshoot, undershoot, overshoot.** ×1.27 at +2 f, ×0.84–0.88 at +5 to +6, ×1.08 at +9, still by +15. It scales and tilts, and never bends. *Bears on:* `pop.contact` (≤ ×1.25, back within 5 f, no undershoot) and E5. A rigid pane that scales and tilts fits lead and glass. A rubbery wobble would not.
5. **Numbers slam; only the final transfer rolls.** Each change shows the new value at once, enlarged and jittering, for 5–7 f. Only the hand total rolls into the round score, over ~8 f with easing. *Bears on:* number readability, V4 ("count over 8 f"), and the player's Health counting down (CB12 b). Balatro's split (slam each step, roll the final sum) is an option to film against counting every step.
6. **Balatro's combo has no ×N count.** The running number is the count, with a popup per hit at its source and pace rising. *Bears on:* the combo count (A1, slanted on a backing) and V5. It suggests the cumulative number can carry the chain on its own, while a ×N count adds what Balatro leaves out: how many hits there were.
7. **Late on, Balatro lets spectacle hide the number on purpose.** Flames grow, shards cover the counters, and single values blur at 6 f per trigger. LocalThunk: the player has "already done all the work … here's the fireworks and you get the final number". *Bears on:* number readability, E6 ("spectacle never hides the number"), and "fights clear and not slow". This clashes with both, and with the art direction: pixel fire, white shards and a CRT swirl are not lead and stained glass. What carries over is the structure, not the look: escalation, then one big final number shown alone.
8. **Deaths falling one after another use the same shrinking-gap idea, but much gentler in Balatro.** Its gap falls from about 15 to 11 f over 20 triggers. Our CB8 c stagger falls 10/7/5/4/4 f over 5 deaths. *Bears on:* deaths falling one after another (CB8 c). Balatro's floor (6 f) is higher than our late death gaps (4 f) and still reads only as a rhythm. At 4 f, deaths may read as "several at once" more than one by one, which the owner judges on film.
