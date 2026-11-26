# What makes game animation feel good (study 2, 24 Nov 2026)

Step 1, second study of `../PLAN-animation-practice.md`. The owner asked (24 Nov): "think about rules for good animations, and maybe even do research about what makes animations feel good in games, examples of what people love in animations and what's done well, guidance."

This is research, not a rule that binds anyone. Which rules become Bramble's practice is the owner's call (step 2).

**How to read it.** All times are in frames at 60 fps (1 frame = 16.7 ms). A claim with a link is sourced. **[unsourced]** marks a claim I could not find a source for, usually common practice or my own reading. **[weak]** marks a source that is a fan wiki, forum post or secondary summary rather than the developer, a measurement or a paper. Our own frame-by-frame measurements of Battlegrounds and of our build are in `../research/battlegrounds.md` (R1) and `../research/our-attack-measured.md` (R3). No video was downloaded for this study.

## Contents

1. [The short version](#1-the-short-version)
2. [The craft](#2-the-craft)
3. [Card games and auto-battlers](#3-card-games-and-auto-battlers)
4. [Moments players love, and why](#4-moments-players-love-and-why)
5. [Accessibility limits](#5-accessibility-limits)
6. [What makes motion feel bad, and how to spot it](#6-what-makes-motion-feel-bad-and-how-to-spot-it)
7. [Rules an agent or a person can check](#7-rules-an-agent-or-a-person-can-check)
8. [Sources](#8-sources)

## 1. The short version

- **Two kinds of motion need opposite things.** When the player acts (drag, buy, sell, refresh), the game must answer within about 100 ms and anticipation must not delay the answer ([Swink via England](https://lizengland.com/blog/review-game-feel-by-steve-swink/), [NN/g](https://www.nngroup.com/articles/animation-duration/)). When the player watches (the fight), nothing waits on input, and anticipation is how the eye knows where to look. Battlegrounds spends 24 to 33 frames on each wind-up (R1). Cooper's tension between "designers want short wind-ups, animators want long ones" ([Cooper](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games)) applies to the shop. It does not apply to the fight.
- **Cause and effect must touch in time.** A hit reads as causing the reaction only if the reaction starts within about 50 ms (3 frames) of contact. Michotte's launching studies found the impression constant up to 50 ms and only occasional at 100 ms ([White 2025 replication](https://orca.cardiff.ac.uk/id/eprint/178603/1/white-2025-michotte-s-research-on-perceptual-impressions-of-causality-a-registered-replication-study.pdf)). Our hit shows 3 frames after contact (R3), right at that edge.
- **Juice has an optimum, not a maximum.** In a controlled study with 3,018 players, medium and high juice beat both none and extreme on experience, motivation, play time and performance ([Kao 2020](https://doi.org/10.1016/j.entcom.2020.100359), as summarised in [Pichlmair & Johansen](https://arxiv.org/abs/2011.09201)).
- **Emphasis comes from contrast.** Hit-stop, shake and slow motion work because most events don't get them. Devil May Cry 5 stops only on heavy hits, and Bayonetta freezes only above a damage threshold ([de Heras](https://threadreaderapp.com/thread/1385104062157254660)). Sakurai's first design lesson is to "stop for big moments" ([Kotaku AU](https://www.kotaku.com.au/2022/08/masahiro-sakurais-new-youtube-channel-is-a-masterclass-in-making-video-games/)).
- **Card games lean toward speed.** Hearthstone cut each minion trigger from 0.8 s to 0.2 s ([outof.games](https://outof.games/hearthstone/758-hearthstone-gameplay-is-going-to-be-faster-minion-trigger-speeds-increasing-by-300-in-an-upcoming-patch)). Battlegrounds made long combats speed up and then slow for the finish ([patch 31.6](https://hearthstone.blizzard.com/en-us/news/24179332/31-6-patch-notes)). Legends of Runeterra sped up its animations after players called them slow ([Inven Global](https://www.invenglobal.com/articles/10550/patch-091-speeds-up-animations-introduces-jinx-and-garen-themed-boards-to-legends-of-runeterra)). Players' most common complaint about card-game animation is length, not looks.

## 2. The craft

### 2.1 The twelve principles in games and UI

Disney's twelve principles ([Thomas & Johnston, summarised](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)) still frame the craft. Jonathan Cooper (lead animator on Assassin's Creed and Mass Effect) restates each one for games in *Game Anim* ([excerpt](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games)). These are the parts that matter for Bramble:

| Principle | What Cooper says for games | What it means for a card on a board |
|---|---|---|
| Squash and stretch | Stretch fast motion, squash on impact, keep the volume | Cards are rigid panes of lead and glass. A uniform scale pop does the job (Battlegrounds: ×1.24 to 1.28 at contact for 1 to 2 frames, R1). Bending a glass card is an art-direction question for the owner. |
| Anticipation | Designers want few frames, animators want many. Telegraphs the player must read get longer ones, and bigger attacks get longer wind-ups. | In the fight, the wind-up says "this card is next". In the shop, no anticipation before the response. |
| Staging | Steer attention with layout and light | One focal action at a time (2.10) |
| Follow-through and overlap | Parts settle at different rates. Let follow-through finish before control returns. | A card's glow, number or debris can finish after the card has stopped |
| Slow in and slow out | Speed follows weight. A sword's weight comes from a slow follow-through, not a slow start. | Strikes fast in, returns slow out (2.5) |
| Arcs | Perfect arcs look floaty, so snaps add realism | A strike can be a straight line. Returns and flights can arc. [unsourced] |
| Timing | Speed is distance over time. A punch over 2 frames reads faster than over 5. Pauses let actions register. | Holds are part of timing (Battlegrounds' 21-frame raised hold) |
| Exaggeration | Hyper-real, poses held longer. The lead keeps exaggeration consistent across the project. | One studio-wide exaggeration level (rule 26) |
| Appeal, solid drawing | Readable silhouettes | Lead lines give strong silhouettes already [unsourced] |

Mariel Cartwright, lead animator on Skullgirls (GDC 2014), adds frame-tight tips ([80.lv summary](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations), [GDC Vault](https://gdcvault.com/play/1020575/Animation-Bootcamp-Fluid-and-Powerful)). Even one frame of anticipation improves readability. With few frames, pick the key moments and push them. One overshoot frame that pulls back adds power. Readability beats perfect in-betweens.

### 2.2 Timing in frames

- **Speed comes from duration, not from easing.** In Battlegrounds the strike takes a fixed 5 to 8 frames whatever the distance, at near-constant speed (R1). A cross-board strike moves 60 to 77 px a frame and a short one 5 px a frame, and both read as one move.
- **Holds carry information.** Battlegrounds holds the raised attacker still for 14 to 22 frames before launch (R1), and that hold is what makes "who attacks next" clear. Cooper: "pauses between moves let actions register" ([Cooper](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games)). The craft has no agreed minimum hold. Animators commonly cite 6 to 8 frames as the shortest hold that reads [weak: [Animation Mentor](https://animationmentor.com/blog/why-all-animators-need-to-master-the-moving-hold)].
- **Fighting games' frame data are the best published timings.** Street Fighter V's jab hits on frame 2 (0.03 s). Its hit-stop is 8, 12 and 15 frames for light, medium and heavy hits ([de Heras](https://threadreaderapp.com/thread/1385104062157254660), [weak]). Capcom's own column uses 8/12/16 as an illustration ([Capcom SF Seminar](https://game.capcom.com/cfn/sfv/column/131545?lang=en)).

### 2.3 Hit-stop (hit-pause, hitlag, "sleep")

A few frames where the hitter and the hit freeze at contact, so the eye registers the impact.

- **Smash Bros.** Hitlag scales with damage. In Ultimate it is ⌊(damage × 0.65 + 6) × modifiers⌋: about 7 frames for a 2 % jab and 15 for a 15 % hit, capped at 30. Electric hits ×1.5. **Only the objects in the hit freeze: particles and the rest of the world keep moving**, and the victim shakes during the freeze ([SSBWiki](https://www.ssbwiki.com/Hitlag), [weak but formula-level]).
- **Sakurai** calls the freeze on a boss kill "boss stop" and teaches that stops highlight important moments ([Kotaku AU](https://www.kotaku.com.au/2022/08/masahiro-sakurais-new-youtube-channel-is-a-masterclass-in-making-video-games/), [GamesRadar](https://gamesradar.com/smash-bros-masahiro-sakurai-has-started-a-fascinating-youtube-game-design-series)). His later video covers eight hit-stop techniques used in Smash Ultimate ([GoNintendo](https://www.gonintendo.com/contents/13581-sakurai-s-latest-game-dev-video-features-8-hit-stop-techniques)).
- **Celeste** freezes the whole game for 0.05 s (3 frames) when a dash starts, and for 0.1 s (6 frames) on some bigger events. The source is the game's published `Player.cs`: `Celeste.Freeze(.05f)` in `DashBegin`, `Celeste.Freeze(.1f)` elsewhere ([NoelFB/Celeste](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs)).
- **Nijman** lists "Sleep (pause game on hit)" as one of his screenshake-talk steps ([talk](https://www.youtube.com/watch?v=AJdEqssNZ-U), list from [Bayreuth course slides](https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf)).
- **Where it is used.** God of War stops on every Kratos hit, Devil May Cry 5 only on heavy ones, and Hollow Knight on every hit taken ([de Heras](https://threadreaderapp.com/thread/1385104062157254660)).
- **Battlegrounds holds 0 frames at contact.** It reverses the next frame and sells the hit with the scale jump and a 3 to 6 frame white flash instead (R1). Hit-stop is not required for a good hit in a watched card fight. It is a tool for the hits that matter.

### 2.4 Screen shake and its limits

- **Nijman's talk** ("The art of screenshake", 2013) builds a dull shooter into a lively one in about 30 steps. In order: bigger bullets, muzzle flash ("first frame is a circle"), impact effect, hit animation, enemy knockback, permanence (corpses), camera lerp, **screen shake**, player knockback, **sleep**, camera kick opposite the shot, more permanence, more bass, slow motion and others ([talk](https://www.youtube.com/watch?v=AJdEqssNZ-U), [slides list](https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf)). Shake is one layer in a stack, not the effect on its own.
- **Eiserloh's "trauma" model** (GDC 2016, [Vault](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing)): events add to a trauma value from 0 to 1, which decays over time. Shake strength is trauma² (or ³), so small knocks barely shake and big ones dominate. Offsets come from smooth noise, not white random. The [Bevy example](https://bevy.org/examples/camera/2d-screen-shake/) built on the talk uses trauma², a decay of 0.5 per second, at most 20 px of offset and at most 10° of roll. The talk's advice to prefer rotation in 2D is from memory of the talk and not re-checked here [unsourced].
- **Celeste** uses short directional shakes: `DirectionalShake(dashDir, 0.2s)` on a dash ([Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs)). The shake goes along the action, not randomly.
- **Hearthstone** shakes the board when a high-Attack minion strikes, harder for higher Attack [weak: [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/HearthstoneHeroesOfWarcraft/TropesSToZ)].
- **Limits.** Shake causes motion sickness for some players, and the Xbox guidelines say to avoid it or let players turn it off. Halo Infinite has 0 to 100 % sliders ([XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)). Constant shake numbs: shake the camera once for the event that matters, not once per event [unsourced, follows from 2.11].

### 2.5 Easing: which curve, when

| Motion | Curve | Source |
|---|---|---|
| Enters the screen | Ease-out (decelerate): arrive fast, settle | [Material](https://m1.material.io/motion/duration-easing.html) `cubic-bezier(0,0,0.2,1)`. NN/g: "the most common choice… feels responsive". |
| Leaves the screen | Ease-in (accelerate): leave at speed | Material `cubic-bezier(0.4,0,1,1)`. NN/g warns that a slow start can feel unresponsive. |
| Moves on screen, from rest to rest | Standard: fast start, long settle | Material `cubic-bezier(0.4,0,0.2,1)` |
| Strike into a target | Near-linear and fast. No slow-down before contact, so it arrives at speed. | Battlegrounds measured (R1) |
| Return home after a strike | Ease-out, fast first | Battlegrounds: 30, 23, 19, 16 … 2, 1 px a frame (R1) |
| Pop or settle (number, burst, card landing) | Overshoot and back (one overshoot frame) | Cartwright ([80.lv](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations)) |
| UI motion in general | Not linear | NN/g: linear looks unnatural |

Our strike today is quad ease-in, accelerating into contact (R3). That is closer to "arrive at speed" than an ease-out, but the last frame covers 24 % of the path, so the motion is mostly a blur on one frame.

### 2.6 Responsiveness vs weight

- Swink defines real-time control as a feedback loop under about 100 ms ([England's review of *Game Feel*](https://lizengland.com/blog/review-game-feel-by-steve-swink/)). The book's three time thresholds are motion impression, perceived instant response and continuity of response ([Pichlmair & Johansen](https://arxiv.org/abs/2011.09201)). The commonly cited values of about 10 frames a second, 100 ms and 240 ms come from the book via secondary sources and were not re-checked here [weak].
- UI: about 100 ms for simple feedback, 200 to 300 ms for bigger changes, and over about 500 ms "feels like a drag" ([NN/g](https://www.nngroup.com/articles/animation-duration/)). Material: about 300 ms on mobile, 150 to 200 ms on desktop, and exits shorter than entries (195 vs 225 ms) ([Material](https://m1.material.io/motion/duration-easing.html)). IBM Carbon's tokens run 70, 110, 150, 240, 400 and 700 ms ([@carbon/motion](https://cdn.jsdelivr.net/npm/@carbon/motion@11.45.0/index.scss)).
- **Weight without lag.** Answer at once, then let the weight live in the follow-through. Cooper's sword example puts the weight in the slow follow-through, not a slow start. For a buy, the card should move on the first frame after the click and can take its time settling. [Rule derived from Cooper, NN/g and Swink.]

### 2.7 Juice

- **"Juice it or lose it"** (Jonasson & Purho, GDC Europe 2012): wobble, squirt, bounce and little noises. "Maximum output for minimum input" ([Game Developer](https://gamedeveloper.com/design/video-is-your-game-juicy-enough-), [GDC Vault](https://gdcvault.com/play/1016487/Juice-It-or-Lose), [video](https://www.youtube.com/watch?v=Fy0aCDmgnxg), source code at [grapefrukt/juicy-breakout](https://github.com/grapefrukt/juicy-breakout)).
- **Mark Brown, "Secrets of Game Feel and Juice"** (GMTK, 2015): juice should amplify the core of the game, not decorate it ([video](https://www.youtube.com/watch?v=216_5nu4aVQ)).
- **The counterpoint.** Folmer Kelly's "Don't Juice It or Lose It" (GDC Europe 2014) argues that juice without context costs immersion ([GDC Vault](https://gdcvault.com/play/1020861/Don-t-Juice-It-or)).
- **Research.** Kao (2020, N = 3,018) tested four levels of juice in one action RPG. None and extreme were both worse than medium and high ([DOI](https://doi.org/10.1016/j.entcom.2020.100359), summary in [Pichlmair & Johansen](https://arxiv.org/abs/2011.09201)). Hicks et al. surveyed developers and found good juice is coherent, communicates game state without getting in the way, and gives direct feedback ([DiGRA 2018](https://dl.digra.org/index.php/dl/article/view/936)). Pichlmair & Johansen warn that heavy juice makes it hard to tell what matters mechanically, and that feedback suggesting the wrong rule confuses learning.

### 2.8 Squash and stretch, by the numbers

Celeste's source ([Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs)) sets the sprite to 0.6 × 1.4 on a jump, 1.4 × 0.6 or 1.5 × 0.5 on landings and wall hits, and 0.8 × 1.2 on a turn. Each snaps on in one frame and eases back toward 1 at 1.75 a second, so 0.6 × 1.4 recovers in about 0.23 s (14 frames). The area is not kept exactly (0.6 × 1.4 = 0.84). The pattern is to snap into the deformation and recover over 10 to 15 frames. For rigid cards, Battlegrounds uses a uniform scale jump at contact instead (R1).

### 2.9 Staggering and sequencing

- **Group what is one event.** Battlegrounds plays one trigger on all its targets in the same frame, four cards sharing one burst (R1, T3). We already group bursts within one exchange (R3).
- **Sequence what is separate, and overlap the seams.** Battlegrounds starts the next attacker's wind-up while the previous death or glow is still playing (R1, D1, T1), so there are no dead frames.
- **Never stop the actor.** Battlegrounds lets a strike and return run unbroken and plays triggers after. The wait lands in the next attacker's raised hold, which stretched to 220 frames in one case (R1, T2). We freeze our attacker at contact for each trigger step: 23 and 41 frames measured (R3).
- **Speed up long chains, then slow for the end.** Battlegrounds' plain attacks run every 76 to 83 frames normally and every 34 to 38 late in long 2026 fights. A repeated deathrattle chain shortened from 71 to 32 to 35 frames a cycle (R1). The 31.6 patch notes: "Combat animations will now accelerate as the battle rages on and then slow down towards the end, for a dramatic finish" ([31.6](https://hearthstone.blizzard.com/en-us/news/24179332/31-6-patch-notes)).
- **Rising pitch and speed in a tally.** Balatro adds chips with a click and mult with a rising ring, "each consecutive effect… slightly increasing the pitch and speed" ([AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up)). The sequence accelerates while the stakes climb.
- **UI stagger.** List items commonly enter 30 to 50 ms apart [unsourced].

### 2.10 Readability when many things happen at once

- Riot's League of Legends VFX style guide ranks gameplay clarity first and minimising clutter second ([Riot, Clarity in League](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/), [VFX style guide PDF](https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf), not opened, summarised from search).
- Teamfight Tactics slowed combat in patch 12.5 because "understandable combat is easier to control" ([TFT 12.5](https://teamfighttactics.leagueoflegends.com/en-us/news/game-updates/teamfight-tactics-patch-12-5-notes/)).
- Hearthstone's golden-card artists keep motion from becoming the focal point, and avoid motion that looks like a mechanic: smoke can read as Stealth, a red glow as Enrage ([Hearthstone wiki, Art](https://hearthstone.wiki.gg/wiki/Art), citing a 2015 Hearthside Chat, [weak]). Their Boomsday VFX notes say effects exist to help "read the board", and chose "a lighter approach so players could focus on playing out their combos" ([Hearthstone blog](https://hearthstone.blizzard.com/en-us/blog/22552047)).
- Inscryption dropped text from its cards, apart from the name, and used sigils because the physical look hurt legibility ([Game Developer](https://gamedeveloper.com/design/inscryption---daniel-mullins-games)).
- In Smash, the hit-stop freezes only the two fighters and particles keep moving ([SSBWiki](https://www.ssbwiki.com/Hitlag)). A local freeze keeps the rest of the board readable.

### 2.11 Frequency and emphasis

"The more frequent the animation, the more subtle and shorter you'll want it to be" ([NN/g](https://www.nngroup.com/articles/animation-duration/)). In card games, the per-attack and per-trigger animations are the frequent ones. Hearthstone's 0.8 s to 0.2 s trigger cut is this rule applied ([outof.games](https://outof.games/hearthstone/758-hearthstone-gameplay-is-going-to-be-faster-minion-trigger-speeds-increasing-by-300-in-an-upcoming-patch)). Rare moments (a triple, a legendary, a kill) earn length and spectacle.

## 3. Card games and auto-battlers

| Game | What is known about its animation | Source |
|---|---|---|
| **Hearthstone** | The UI was designed as a physical game box in a tavern, and production director Jason Chayes said the cards "feel like they have weight". Its sound is "rhythmic", built on fixed beats: "the cast, the hit". Some golden animations were first made about 400 % too fast and slowed. Triggers were cut to 0.2 s, and "Victory!" is announced while defeat is not (little victories). | [Sakamoto GDC 2015](https://gdcvault.com/play/1022036/Hearthstone-How-to-Create-an); Chayes via [search summary of the Hearthstone wiki](https://hearthstone.wiki.gg/wiki/Bad_cards) [weak]; [sound team](https://hearthstone.blizzard.com/en-us/blog/23964694/); [wiki](https://hearthstone.wiki.gg/wiki/Art) [weak]; [outof.games](https://outof.games/hearthstone/758-hearthstone-gameplay-is-going-to-be-faster-minion-trigger-speeds-increasing-by-300-in-an-upcoming-patch); [80.lv on Dodds GDC 2014](https://80.lv/articles/hearthstone-10-rules-of-great-design), [GamesBeat](https://gamesbeat.com/the-best-tricks-that-blizzards-game-designers-used-to-make-hearthstone-a-megahit/2/) |
| **Battlegrounds** | Fixed durations, the same from 2020 to 2026. A long lift-and-hold wind-up, a 5 to 8 frame linear strike, a scale jump and white flash at contact with no hold, an ease-out return. Deaths 40 to 68 frames after the hit, triggers after the attacker is home, speed-up in long fights. | R1, [31.6](https://hearthstone.blizzard.com/en-us/news/24179332/31-6-patch-notes) |
| **Marvel Snap** | Turns are simultaneous, then cards reveal one at a time, the player who is ahead first. Every reveal is its own beat. Retreat is presented as an escape rather than a loss, after Hearthstone's "little victories". VFX were thin at the PC launch and added later. | [GINX](https://www.ginx.tv/en/marvel-snap/reveal-first) [weak], [GDC 2023](https://www.gdcvault.com/play/1029024/Designing-MARVEL-SNAP), [mobilegamer.biz](https://mobilegamer.biz/second-dinners-ben-brode-reveals-marvel-snaps-recipe-for-success-literally/), [Dot Esports](https://dotesports.com/?p=942448) |
| **Balatro** | The score tally plays card by card, with click, ring and rising pitch and speed. LocalThunk's own favourite is the flame that appears when a hand beats the blind. A game-speed option exists. | [AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up), [GamesRadar](https://gamesradar.com/games/roguelike/after-winning-big-at-the-game-awards-and-taking-hours-of-our-time-in-2024-balatro-creator-reveals-their-most-productive-night-resulted-in-one-of-the-games-most-satisfying-features), [Steam forum](https://steamcommunity.com/app/2379780/discussions/0/6426156954538745672) [weak] |
| **Slay the Spire** | Ships a Fast Mode that many players use once they know the cards. Fan mods go further and let players switch off hit pauses separately. | [Steam discussion](https://steamcommunity.com/app/646570/discussions/0/2549465882935485677) [weak], [SpeedX mod](https://www.nexusmods.com/slaythespire2/mods/56) [weak] |
| **Legends of Runeterra** | Patches 0.9.1 and 0.9.2 sped up summons, draws, casts and the initiative token, and removed "effect buffers" and lock-outs, after feedback that the pace was "on the low end". Animations hook onto game events without engineers knowing their length, and the loot ceremony is an artist-editable state machine. | [Inven Global](https://www.invenglobal.com/articles/10550/patch-091-speeds-up-animations-introduces-jinx-and-garen-themed-boards-to-legends-of-runeterra), [Riot tech blog](https://www.riotgames.com/en/news/bringing-features-life-legends-runeterra) |
| **Teamfight Tactics** | Slowed combat for clarity (12.5). | [TFT 12.5](https://teamfighttactics.leagueoflegends.com/en-us/news/game-updates/teamfight-tactics-patch-12-5-notes/) |
| **Inscryption** | A tactile, skeuomorphic table, with legibility kept through sigils and little text. | [Game Developer](https://gamedeveloper.com/design/inscryption---daniel-mullins-games), [DiGRA](https://dl.digra.org/index.php/dl/article/download/2474/2467/2503) |
| **Super Auto Pets** | Automatic right-to-left battles. A player notes the information goes by fast but the damage is shown "in big red numbers". Speed options exist [unsourced]. | [SAP wiki](https://superautopets.wiki.gg/wiki/The_Basics), [itch.io post](https://itch.io/post/1715298) [weak] |

## 4. Moments players love, and why

| Game, moment | What the animation does | Numbers | Source |
|---|---|---|---|
| **Balatro, scoring a hand** | Each scored card pops in turn. Chips click, mult rings, and each extra effect is a little higher in pitch and a little faster, so sound and tempo climb with the number. When the hand beats the blind, the score catches fire. | Pitch and tempo rise per effect. No frame measurements published. | [AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up), [GamesRadar](https://gamesradar.com/games/roguelike/after-winning-big-at-the-game-awards-and-taking-hours-of-our-time-in-2024-balatro-creator-reveals-their-most-productive-night-resulted-in-one-of-the-games-most-satisfying-features) |
| **Marvel Snap, the reveal** | Simultaneous play, then a one-by-one reveal in a fixed order: suspense, then a payoff for each card. | Not measured | [GINX](https://www.ginx.tv/en/marvel-snap/reveal-first) [weak]. Why it is loved: [unsourced]. |
| **Hearthstone, a legendary dropping** | Legendaries get "a lot more wiggle room" for character, plus a unique stinger from Warcraft music. The board shake that players associate with big minions scales with Attack. | Not measured | [Hearthstone blog](https://hearthstone.blizzard.com/en-us/blog/22552047), [sound team](https://hearthstone.blizzard.com/en-us/blog/23964694/), [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/HearthstoneHeroesOfWarcraft/TropesSToZ) [weak]. The specifics of the entrance (dust, slam, camera) are [unsourced]. |
| **Hades, landing hits** | Widely praised. No developer source on its hit timing was found. A claimed "10 frames on every attack" comes from an unsourced blog. | [unsourced] | Search turned up nothing primary (see the end of §8) |
| **Celeste, the dash** | The game freezes for 3 frames, a directional shake runs for 0.2 s along the dash, the sprite deforms, the screen distorts and the controller rumbles strongly. The dash itself lasts 0.15 s. | Freeze 0.05 s, shake 0.2 s, dash 0.15 s, squash 0.6 × 1.4 recovering in about 14 frames | [Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) |
| **Vampire Survivors, opening a chest** | Coins pour out, items flicker past like a slot machine, the screen brightens and music plays. It is grander for rarer chests, and skippable with Escape after the first couple. | Not measured | [Josh Comeau](https://www.joshwcomeau.com/email/009), [Boger](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors) |
| **Fighting games, the hit and the combo** | Hit-stop scaled to the hit. The health bar shakes and the lost "chunk" stays visible about 1 s (Tekken 7). Combo counters and announcers are fan favourites, but no design source on why was found. | SFV 8/12/15 frames; Smash 7 to 30; Tekken chunk about 1 s | [de Heras](https://threadreaderapp.com/thread/1385104062157254660), [SSBWiki](https://www.ssbwiki.com/Hitlag). Why counters delight: [unsourced]. |
| **Bramble, the triple** | The owner's favourite in our own game ("Triples are great"). | See the inventory study | `../PLAN-animation-practice.md` |

What the loved moments share: (1) they are **rare or earned**, (2) they **escalate**, with pitch, speed or scale rising as stakes rise, (3) they are **legible**, the number or card is never hidden by the spectacle, and (4) the long ones are **skippable once seen** [synthesis].

## 5. Accessibility limits

| Limit | Number | Source |
|---|---|---|
| General and red flashes | No more than 3 in any 1 s (Level A), unless the flashing area is small. A flash is an opposing pair of relative-luminance changes of ≥ 10 % where the darker state is < 0.80. A red flash is any opposing pair involving saturated red, R/(R+G+B) ≥ 0.8. | [WCAG 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html) |
| Small-area exception | Combined flashing area ≤ 0.006 sr within any 10° field (25 % of it). WCAG's reference is 341 × 256 px at 1024 × 768. Scaled to 1920 × 1080 that is about 640 × 480 px [my scaling, assumes the same viewing geometry]. | WCAG 2.3.1 |
| Stricter level | No more than 3 flashes in any 1 s, whatever the area (AAA) | [WCAG 2.3.2](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes.html) |
| Motion from interactions | Players can turn off non-essential motion triggered by interaction (AAA) | [WCAG 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html) |
| Xbox photosensitivity | Test every game for seizure triggers, even with no flashing intended, with the Harding FPA test as a tool. Lower the contrast, frequency and size of flashes. | [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118) |
| Xbox motion | Avoid or allow turning off camera shake, bobbing and motion blur (Halo Infinite: 0 to 100 % sliders). Let players pause, hide or turn off moving and blinking UI content, such as an animated menu background. | [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) |
| Vestibular triggers | Spinning, spiralling, parallax, multi-speed movement and large movements. Colour changes, fades and small movements are not on the trigger list. "Reduce ≠ remove": keep a calm version. | [WebKit](https://webkit.org/blog/7551/responsive-design-for-motion/), [Val Head, Smashing](https://www.smashingmagazine.com/2020/09/design-reduced-motion-sensitivities), [Val Head slides](https://noti.st/valhead/xICaMq/slides) |
| Flicker | Avoid flickering images and repetitive patterns (basic level) | [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/) |
| Godot hook | `DisplayServer.accessibility_should_reduce_animation()` reads the OS reduce-motion preference. It is listed in the 4.6 class reference. Platform support and behaviour on 4.7.2 not checked. Headless runs return dummy values. | [Godot docs](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html) |

Our white impact flash and any full-screen glow count as "flashes" if they cross the luminance thresholds. A chain of triggers that each flash brightly can pass 3 a second: Battlegrounds' sped-up chain cycles every 32 to 35 frames, under 2 a second (R1).

## 6. What makes motion feel bad, and how to spot it

Each fault comes with how an agent could spot it from the per-frame log (`ours_positions.csv`-style: per frame, each object's position, scale, turn, opacity and markers) or the film, without watching at speed.

| Fault | What it looks like | Why it's bad | How to spot it in data |
|---|---|---|---|
| **Too long** | You wait for the game | NN/g: over about 500 ms "feels like a drag", and animations are more often too long than too short. Every card game in §3 cut its timings. | Duration per event type × times per game (from a soak log) = seconds per game. Flag the biggest. |
| **Input lag** | A click does nothing for a moment | Breaks real-time control (about 100 ms, Swink) | `.events` press frame → first frame the pressed object changes. More than 6 frames fails. |
| **Disconnected hit** | The target reacts late, so the hit looks like it missed | Causality breaks after about 50 to 100 ms (Michotte) | Contact marker → first frame the target changes position, scale or light. More than 3 frames fails. |
| **Frozen actor** | A card stops mid-move and waits | The motion "stalls" and reads as a bug. Battlegrounds never does it (R1). | Attacker speed 0 for more than N frames between `windup_start` and `home`, outside planned holds |
| **Floaty** | Everything eases in and out the same way, with no impact | No contrast between fast and slow phases [unsourced, Cooper on "floaty" arcs] | Peak speed ÷ mean speed per motion is near 1.5 for every motion. No phase has a clear speed change. |
| **Metronome** | Every motion has the same length | Distance and importance aren't expressed [unsourced] | Histogram of durations per event type shows one spike |
| **Everything at once** | No single focal point | Staging. Clutter hurts clarity (Riot). | Frames where 2 or more *different* event types are in their main motion at once |
| **Pops and jitter** | A jump in a value, or a shiver | Two tweens fighting over one property, or a missing in-between | Second difference of position or scale spikes, or velocity changes sign, outside marked impact frames |
| **Dead air** | Nothing moves for a beat between steps | The pace drags. Battlegrounds overlaps the seams (R1). | Frames where no object moves above 0.5 px a frame and no number changes, between two events |
| **Juice everywhere** | Shake and flash on every event | Kao: extreme juice is as bad as none. Emphasis lost. | Share of events with shake, flash or hit-stop. More than about 1 in 5 is a warning [unsourced threshold]. |
| **Misleading motion** | A decorative effect looks like a mechanic | Hearthstone's smoke-reads-as-Stealth problem | Owner only, or a rules-aware review |
| **Unskippable repetition** | A celebration you've seen 50 times | Vampire Survivors lets you skip after a couple of views | Skip input → end of animation in frames |
| **Sound off the hit** | The thud comes before or after the impact | Viewers detect sound leading by more than 45 ms or lagging by more than 125 ms ([ITU-R BT.1359](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!PDF-E.pdf)) | Frame of the sound-play call vs contact marker. Our film is silent and our sound delays follow the wall clock (R3), so this needs a game-time sound log. |
| **Frame-rate dependent motion** | Timing changes on a slow PC | Motion must use game time | Film at fixed 60 fps vs a real-time run on the owner's PC. Owner only on real hardware (`docs/AGENT-BLIND-SPOTS.md`). |

## 7. Rules an agent or a person can check

Proposed for step 2. Numbers are at 60 fps. "Log" means the per-frame engine log from a `tools/feel` film (positions, scale, turn, opacity, markers). "Events" means `tools/feel`'s `.events` file. Where a number is a proposal and not research, the source column says so.

### Responding to the player (the shop)

| # | Rule | Number | Source | How an agent checks it |
|---|---|---|---|---|
| 1 | Answer every player action on screen at once. No anticipation before the response. | First visible change ≤ 6 frames (100 ms) after the input. Aim for the next frame. | Swink via [England](https://lizengland.com/blog/review-game-feel-by-steve-swink/); [NN/g](https://www.nngroup.com/articles/animation-duration/) | Events press frame → first log frame where the target's position, scale or modulate changes |
| 2 | Keep UI motion short. Exits shorter than entries. | Feedback about 6 frames (100 ms). Panels 12 to 18 (200 to 300 ms). Nothing in the UI over 24 to 30 (400 to 500 ms) unless it is a celebration. Exit about 85 % of entry. | [NN/g](https://www.nngroup.com/articles/animation-duration/); [Material](https://m1.material.io/motion/duration-easing.html) (195 vs 225 ms) | Start and end markers in the log per UI tween |
| 3 | Ease by role: entries ease out, exits ease in, rest-to-rest moves use the standard curve. Never linear for UI. | Ease-out: ≥ 60 % of the distance covered in the first 40 % of the time [my operationalisation] | [Material](https://m1.material.io/motion/duration-easing.html); [NN/g](https://www.nngroup.com/articles/animation-duration/) | Fraction of the path covered at 40 % of the duration, from the log |
| 4 | Put weight in the settle, not the start. A dropped or bought card moves at once and may overshoot and settle. | One overshoot of ≤ 10 % of the travel, settled within 12 frames [proposal] | [Cooper](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games); [Cartwright](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations) | Log: peak past the target position, frames to within 0.5 px |

### The fight (watched motion)

| # | Rule | Number | Source | How an agent checks it |
|---|---|---|---|---|
| 5 | Show clearly who acts next. The wind-up is a visible change, then a still hold. | Normal speed: lift 9 to 11 frames, hold 14 to 22. Never under lift 6 and hold 9, even sped up. | R1 (Battlegrounds measured, normal and sped-up) | Log: scale or offset plateau start and end before the first forward frame |
| 6 | Strike in a fixed, short time, whatever the distance. Arrive at speed with no slow-down before contact. | 5 to 8 frames. Speed on the last frame before contact ≥ the mean strike speed. | R1; [Cooper](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games) (2 vs 5 frame punch) | Log: frames from first forward motion to contact, per-frame speed profile |
| 7 | The target reacts within the causality window | Flash, recoil or number starts 0 to 3 frames after contact. Battlegrounds: flash at contact, star at +3 to 4. | Michotte via [White 2025](https://orca.cardiff.ac.uk/id/eprint/178603/1/white-2025-michotte-s-research-on-perceptual-impressions-of-causality-a-registered-replication-study.pdf); R1 | Log: contact marker → first change on the target |
| 8 | Mark the contact frame itself | A scale pop on the attacker (up to about ×1.25) for 1 to 2 frames, back to 1.0 within 5. A white flash of 3 to 6 frames. | R1 | Log: scale at contact ± 2 frames. Film: luminance of the target area at contact. |
| 9 | Return eases out, fast first | 9 to 16 frames. The first frame of the return is the fastest. | R1 | Log: per-frame return speeds decrease monotonically (±1 px) |
| 10 | Never freeze the actor mid-motion for a trigger. Let the strike and return finish, then play triggers. Absorb waits in the next actor's held wind-up. | 0 frames of unplanned stop between `windup_start` and `home` | R1 (T1, T2) | Log: attacker speed < 0.5 px a frame for more than 2 frames outside the planned hold and contact frames |
| 11 | Hit-stop only where it means something, and freeze only the participants | Ordinary hit 0 to 2 frames. Big hit 4 to 8. A once-a-fight moment up to 12 to 20. The rest of the board and particles keep moving. | [SSBWiki](https://www.ssbwiki.com/Hitlag) (local freeze, 7 to 30 frames); [Celeste](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) (3 and 6 frames); [de Heras](https://threadreaderapp.com/thread/1385104062157254660) (DMC5 heavy only); R1 (Battlegrounds 0). Bands are a proposal. | Log: frames with zero speed on attacker and target at contact, while other moving objects keep their speed |
| 12 | A death reads after the hit has registered, breaks fast and leaves a short trace | Starts 30 to 68 frames after the hit. The break takes 5 to 10 frames, debris about 20 more. | R1 (40 frames in 2026, 65 to 68 in 2020 and 2022) | Log: hit marker → death start. Death motion length. |
| 13 | Damage numbers appear with the hit and stay long enough to read | Appear ≤ 4 frames after contact. Readable ≥ 30 frames (Battlegrounds about 60, Tekken's lost chunk about 1 s). | R1; [de Heras](https://threadreaderapp.com/thread/1385104062157254660) | Log: burst object appear and fade frames vs contact |
| 14 | One focal action at a time. One trigger on many targets plays as one beat on all of them. | 0 frames where two different event types are in their main motion at once, except a planned overlap (rule 15) | R1 (T3 grouping); [Riot clarity](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/); Disney staging | Log: count of distinct event types moving above 1 px a frame, per frame |
| 15 | Overlap the seams. The next actor's wind-up may start in the previous effect's tail, and no dead air in normal flow. | Gaps with nothing moving ≤ 6 frames [proposal]. Battlegrounds overlaps by tens of frames. | R1 (D1, T1) | Log: runs of frames with no motion and no number change, between events |
| 16 | Speed up long fights and long chains. Slow down for the finish. | Late attack cycle about half the early one (Battlegrounds 76 to 83 → 34 to 38 frames). Chains about 2× faster by the end. The last attack at normal speed. | R1; [31.6](https://hearthstone.blizzard.com/en-us/news/24179332/31-6-patch-notes) | Log: attack-to-attack period across a long fixture fight. The slope is negative, and the last period is ≥ the first. |
| 17 | Frequent animations are short. Rare ones may be long and loud. | Per-trigger beat ≤ 12 frames (Hearthstone 0.2 s). Total animation seconds per game from frequent events are tracked and kept below a budget the owner sets. | [outof.games](https://outof.games/hearthstone/758-hearthstone-gameplay-is-going-to-be-faster-minion-trigger-speeds-increasing-by-300-in-an-upcoming-patch); [NN/g](https://www.nngroup.com/articles/animation-duration/) | Bot soak log: event counts × measured durations |
| 18 | Chains escalate. Each repeat in a chain is a little faster and higher in pitch. | Each cycle ≤ the previous one. Pitch steps upward. | [AV Club on Balatro](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up); R1 (T3) | Log: cycle periods. Sound-event log: pitch parameter per play. |
| 19 | Impact sound lands on the impact frame | Sound start from 2 frames before to 7 frames after contact (BT.1359 detectability +45 / −125 ms). Aim for 0 to 1 frame. | [ITU-R BT.1359](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!PDF-E.pdf); [Hearthstone sound team](https://hearthstone.blizzard.com/en-us/blog/23964694/) ("the cast, the hit") | Needs a game-time sound log (the film is silent). Until then, owner only. |

### Emphasis, shake and juice

| # | Rule | Number | Source | How an agent checks it |
|---|---|---|---|---|
| 20 | Keep an emphasis budget. Shake, long hit-stop, full-screen flash and slow motion go only to the top tier of events. | At most about 1 event in 5 in a typical fight gets any of them [proposal] | [Kao 2020](https://doi.org/10.1016/j.entcom.2020.100359); [de Heras](https://threadreaderapp.com/thread/1385104062157254660); Sakurai ([Kotaku AU](https://www.kotaku.com.au/2022/08/masahiro-sakurais-new-youtube-channel-is-a-masterclass-in-making-video-games/)) | Log: share of events with a camera offset, flash or freeze |
| 21 | Shake scales with the event, along its direction, from smooth noise, and dies fast | Strength = trauma². Gone within 12 to 30 frames (Celeste 0.2 s). Offset ≤ 20 px at 1080p at full trauma [Bevy's value, a proposal for us]. | [Eiserloh](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing); [Bevy](https://bevy.org/examples/camera/2d-screen-shake/); [Celeste](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs) | Log: camera offset per frame. Amplitude vs event size, decay length, frame-to-frame smoothness (no offset jump over half the amplitude). |
| 22 | Rigid cards pop, they don't bend. Squash and stretch, if used, snaps in and recovers quickly. | Uniform scale pop ≤ ×1.3, 1 to 2 frames at the peak. If non-uniform: area within ±20 % and recovered within about 14 frames. | R1; [Celeste](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs). Whether glass may bend: owner (art direction). | Log: scale x and y per frame |
| 23 | Long celebrations can be skipped once seen | Skip ends it within 6 frames. Skippable from the third time a player sees it [proposal]. | [Josh Comeau on Vampire Survivors](https://www.joshwcomeau.com/email/009) | Scripted skip in a `tools/feel` scenario, then the frames to the end state |

### Safety, consistency and the owner's eye

| # | Rule | Number | Source | How an agent checks it |
|---|---|---|---|---|
| 24 | No harmful flashing | No more than 3 general or red flashes in any 1 s, unless the combined flashing area is under about 640 × 480 px at 1080p | [WCAG 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html); [XAG 118](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118) | From the film: per-frame relative luminance per region, count opposing ≥ 10 % transitions in a sliding 60-frame window, red per WCAG. This can be checked fully automatically. |
| 25 | Respect reduced motion, and give shake and flash their own sliders | With reduce-motion on, camera offset is 0, travel and scale changes are replaced by fades or short cuts, and every timing still lands (reduce, don't remove). Shake and flash sliders run 0 to 100 %. | [WCAG 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html); [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117); [Val Head](https://www.smashingmagazine.com/2020/09/design-reduced-motion-sensitivities); [Godot](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html) | Film the same fixture with the setting on. Camera offset is 0 on every frame, peak travel shrinks, event markers fall on the same frames ±2. |
| 26 | No spin, big zoom or parallax on decoration | Decorative rotation ≤ 15°, no continuous spin, no layers moving at different speeds outside gameplay [threshold is a proposal] | [WebKit](https://webkit.org/blog/7551/responsive-design-for-motion/); [Val Head slides](https://noti.st/valhead/xICaMq/slides) | Log: turn and scale ranges of non-gameplay nodes |
| 27 | No pops, no jitter | Speed changes by no more than 3× from one frame to the next, and velocity never reverses, except on marked impact, launch and stop frames | [unsourced; standard animation polish] | Log: first and second differences of position, scale and turn per object |
| 28 | One studio-wide timing table. The same action class has the same duration and curve everywhere, and every motion is specified in frames before it is built. | Film matches the spec within ±1 frame | [Cooper](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games) (consistent exaggeration); [Riot tech blog](https://www.riotgames.com/en/news/bringing-features-life-legends-runeterra) (consistency) | Spec file vs log markers. Code constants grouped per action class. |
| 29 | Whether it feels good: weight, satisfaction, charm, "does it feel right", and whether it fits lead and glass | None | `docs/AGENT-BLIND-SPOTS.md`; Kao (the optimum is found by people, not formulas) | **Owner only.** Agents bring a film, a frame strip, the speed chart and the rule results above. The owner judges at real speed on real hardware. |

### Which rules the data already tests

From R3, today's build against these rules: rule 5 fails (4-frame wind-up, no hold), rule 6 passes on duration (8 frames) but the speed profile is ease-in, rule 7 is at the edge (+3 frames), rule 10 fails (23 and 41 frame freezes), rule 12 passes (37 frames), rule 15 is close (4 empty frames after a death), rule 16 fails (nothing speeds up), and rule 17 is unknown (no soak timing yet). This is a reading of the existing measurement, not a new test.

## 8. Sources

Game feel and juice
- Jonasson & Purho, "Juice It or Lose It", GDC Europe 2012: [GDC Vault](https://gdcvault.com/play/1016487/Juice-It-or-Lose), [YouTube](https://www.youtube.com/watch?v=Fy0aCDmgnxg), [Game Developer](https://gamedeveloper.com/design/video-is-your-game-juicy-enough-), [juicy-breakout source](https://github.com/grapefrukt/juicy-breakout)
- Jan Willem Nijman, "The Art of Screenshake", INDIGO 2013: [YouTube](https://www.youtube.com/watch?v=AJdEqssNZ-U); technique list from [Univ. Bayreuth course slides](https://medienwissenschaft.uni-bayreuth.de/wp-content/uploads/GxD-10-Game-Feel.pdf); [Game Developer](https://gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)
- Folmer Kelly, "Don't Juice It or Lose It", GDC Europe 2014: [GDC Vault](https://gdcvault.com/play/1020861/Don-t-Juice-It-or)
- Mark Brown, "Secrets of Game Feel and Juice", GMTK 2015: [YouTube](https://www.youtube.com/watch?v=216_5nu4aVQ)
- Steve Swink, *Game Feel* (2008), via [Liz England's review](https://lizengland.com/blog/review-game-feel-by-steve-swink/)
- Squirrel Eiserloh, "Juicing Your Cameras With Math", GDC 2016: [GDC Vault](https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing); [Bevy example built on it](https://bevy.org/examples/camera/2d-screen-shake/)
- Pichlmair & Johansen, "Designing Game Feel: A Survey" (IEEE ToG): [arXiv](https://arxiv.org/abs/2011.09201)
- Kao, "The effects of juiciness in an action RPG", *Entertainment Computing* 2020: [DOI](https://doi.org/10.1016/j.entcom.2020.100359)
- Hicks et al., "Good Game Feel: An Empirically Grounded Framework for Juicy Design", DiGRA 2018: [DiGRA](https://dl.digra.org/index.php/dl/article/view/936)

Animation craft
- Jonathan Cooper, *Game Anim*, 12 principles chapter: [Game Developer excerpt](https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games)
- Twelve basic principles (Thomas & Johnston): [Wikipedia](https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation)
- Mariel Cartwright, "Fluid and Powerful Animation within Frame Restrictions", GDC 2014: [GDC Vault](https://gdcvault.com/play/1020575/Animation-Bootcamp-Fluid-and-Powerful), [80.lv summary](https://80.lv/articles/tips-on-making-fluid-and-powerful-animations)
- Jason de Heras, game-feel thread, part 2 (hit pause, freeze, camera, HUD): [Thread Reader](https://threadreaderapp.com/thread/1385104062157254660)
- Moving holds: [Animation Mentor](https://animationmentor.com/blog/why-all-animators-need-to-master-the-moving-hold) [weak]

Hit-stop
- Smash hitlag formula: [SSBWiki](https://www.ssbwiki.com/Hitlag)
- Sakurai on hit-stop: [Kotaku AU](https://www.kotaku.com.au/2022/08/masahiro-sakurais-new-youtube-channel-is-a-masterclass-in-making-video-games/), [GamesRadar](https://gamesradar.com/smash-bros-masahiro-sakurai-has-started-a-fascinating-youtube-game-design-series), [GoNintendo on the 8 techniques](https://www.gonintendo.com/contents/13581-sakurai-s-latest-game-dev-video-features-8-hit-stop-techniques), [Source Gaming translation of his Famitsu column](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)
- Capcom SF Seminar on hit stop: [Capcom](https://game.capcom.com/cfn/sfv/column/131545?lang=en) (403 to automated fetch; content from search summary)
- Celeste's player code: [NoelFB/Celeste Player.cs](https://github.com/NoelFB/Celeste/blob/master/Source/Player/Player.cs)
- Godot hit-stop mechanics (time scale, timers and tweens that ignore it, 4.4+): [uhiyama-lab](https://uhiyama-lab.com/en/notes/godot/hit-feedback-hitstop/), [Godot forum](https://forum.godotengine.org/t/tutorial-hit-stop-and-screen-shake-in-godot-4-autoload-trauma-camera-mit/145240) [weak; check against the 4.7 docs before use]

UI motion
- NN/g, animation duration: [nngroup.com](https://www.nngroup.com/articles/animation-duration/)
- Material Design, duration and easing: [m1.material.io](https://m1.material.io/motion/duration-easing.html)
- IBM Carbon motion tokens: [@carbon/motion source](https://cdn.jsdelivr.net/npm/@carbon/motion@11.45.0/index.scss), [Carbon docs](https://carbondesignsystem.com/elements/motion/overview/)

Perception
- Michotte's launching effect, delay thresholds and replication: [White 2025](https://orca.cardiff.ac.uk/id/eprint/178603/1/white-2025-michotte-s-research-on-perceptual-impressions-of-causality-a-registered-replication-study.pdf)
- Audio-video sync: [ITU-R BT.1359-1](https://www.itu.int/dms_pubrec/itu-r/rec/bt/R-REC-BT.1359-1-199811-I!!PDF-E.pdf)

Card games
- Hearthstone: [Sakamoto, GDC 2015](https://gdcvault.com/play/1022036/Hearthstone-How-to-Create-an); [Dodds' 10 rules, GDC 2014, via 80.lv](https://80.lv/articles/hearthstone-10-rules-of-great-design); [little victories, GamesBeat](https://gamesbeat.com/the-best-tricks-that-blizzards-game-designers-used-to-make-hearthstone-a-megahit/2/); [Boomsday VFX](https://hearthstone.blizzard.com/en-us/blog/22552047); [sound team](https://hearthstone.blizzard.com/en-us/blog/23964694/); [trigger 0.8 → 0.2 s](https://outof.games/hearthstone/758-hearthstone-gameplay-is-going-to-be-faster-minion-trigger-speeds-increasing-by-300-in-an-upcoming-patch); [Battlegrounds 31.6 combat speed-up](https://hearthstone.blizzard.com/en-us/news/24179332/31-6-patch-notes); [wiki, Art](https://hearthstone.wiki.gg/wiki/Art) [weak]; [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/HearthstoneHeroesOfWarcraft/TropesSToZ) [weak]; player complaints about slow BG animations: [Blizzard forum](https://us.forums.blizzard.com/en/hearthstone/t/can-we-fix-the-slow-battlegrounds-animations-already/138417)
- Marvel Snap: [Brode, GDC 2023](https://www.gdcvault.com/play/1029024/Designing-MARVEL-SNAP); [mobilegamer.biz](https://mobilegamer.biz/second-dinners-ben-brode-reveals-marvel-snaps-recipe-for-success-literally/); [reveal order, GINX](https://www.ginx.tv/en/marvel-snap/reveal-first) [weak]; [VFX at PC launch, Dot Esports](https://dotesports.com/?p=942448)
- Balatro: [AV Club](https://www.avclub.com/balatro-hones-the-art-of-making-numbers-go-up); [GamesRadar](https://gamesradar.com/games/roguelike/after-winning-big-at-the-game-awards-and-taking-hours-of-our-time-in-2024-balatro-creator-reveals-their-most-productive-night-resulted-in-one-of-the-games-most-satisfying-features); [Steam forum on game speed](https://steamcommunity.com/app/2379780/discussions/0/6426156954538745672) [weak]. Not used: a "Balatro-style" design guide whose timings are the author's own reconstruction, not measurements (blakecrosley.com).
- Slay the Spire: [Steam discussion on Fast Mode](https://steamcommunity.com/app/646570/discussions/0/2549465882935485677) [weak]
- Legends of Runeterra: [0.9.1 speed-ups, Inven Global](https://www.invenglobal.com/articles/10550/patch-091-speeds-up-animations-introduces-jinx-and-garen-themed-boards-to-legends-of-runeterra); [Riot, Bringing Features to Life](https://www.riotgames.com/en/news/bringing-features-life-legends-runeterra)
- Teamfight Tactics: [patch 12.5](https://teamfighttactics.leagueoflegends.com/en-us/news/game-updates/teamfight-tactics-patch-12-5-notes/); League clarity: [Riot](https://www.leagueoflegends.com/en-us/news/dev/clarity-in-league/), [VFX style guide](https://nexus.leagueoflegends.com/wp-content/uploads/2017/10/VFX_Styleguide_final_public_hidpjqwx7lqyx0pjj3ss.pdf)
- Inscryption: [Game Developer](https://gamedeveloper.com/design/inscryption---daniel-mullins-games); [DiGRA paper](https://dl.digra.org/index.php/dl/article/download/2474/2467/2503)
- Super Auto Pets: [wiki](https://superautopets.wiki.gg/wiki/The_Basics)
- Vampire Survivors: [Josh Comeau](https://www.joshwcomeau.com/email/009); [Boger](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors)

Accessibility
- [WCAG 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html), [2.3.2](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes.html), [2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)
- [Xbox XAG 117, motion](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117); [XAG 118, photosensitivity](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/118)
- [Game Accessibility Guidelines, flicker](https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/)
- [WebKit, Responsive Design for Motion](https://webkit.org/blog/7551/responsive-design-for-motion/); [Val Head, Smashing 2020](https://www.smashingmagazine.com/2020/09/design-reduced-motion-sensitivities); [Val Head, Making Motion Inclusive](https://noti.st/valhead/xICaMq/slides)
- [Godot DisplayServer (4.6)](https://docs.godotengine.org/en/4.6/classes/class_displayserver.html)

Searched for and not found: a developer source on Hades' hit timing, on Marvel Snap's reveal timing or why it reveals one card at a time, on Hearthstone's legendary entrance timing, on Balatro's event delays (since measured from footage in `../research/balatro.md`), and on why combo counters delight. Hearthstone's GDC talks (Sakamoto 2015, Dodds 2014) are on the Vault but only summaries were readable. Watching them, or measuring footage as R1 did, is the way to fill these gaps.
