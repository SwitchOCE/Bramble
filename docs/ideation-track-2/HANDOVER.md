# Ideation track 2: hand-over

For a session that picks this track up if the orchestrator stops. The plan is `docs/workstreams/ideation-track-2.md` on `main`; this file only says where the work stands. Keep it short and current.

Last updated: 17 Nov 2026, 06:10 (Optiplex).

## Where things are

- **Integration branch:** `ideation/track-2`. Workers branch from it as `ideation/<something>`; PRs target it, never `main`.
- **Step 1, look tool:** merged (PR 74). `tools/look/README.md` says how to use it.
- **Step 1, mock-up pieces into Godot:** merged (PR 75). `assets/glass/`, `src/glass/`, `tools/glass/`. Owner, 16 Nov: "I want the mock-up stuff brought into Godot as part of this."
- **Step 2, mechanics:** done. Page source in `docs/ideation-track-2/mechanics/`; the owner's picks and notes are in that page's database (collection `picks`) and copied below.
- **Step 4, rules core:** merged (PRs 76, 80, 84, 93). Tribes are added as files only: `docs/ideation-track-2/ADDING-A-TRIBE.md`.
- **Tribe coding:** all five tribes merged (PRs 87 to 91), each as `src/content/<tribe>/` with tests. The game flow reads them (PR 92). A 100-game soak of the five shipped tribes together: 4,465 fights, 0 violations.
- **Tribe follow-ups:** merged (PRs 94 to 98). Every card that was a "closest version" now plays as designed on the core's fourth pass, with reminder, keyword and golden text for the hover.
- **Polish from the first play-test:** merged (PR 99).
- **Reviews (17 Nov):** every merged step has now had a scope review; none had a cut item left open. Findings became: the core clean-up with 43 fights between two tribes' real cards, all matching `tribes/SHARED-RULES.md` (PRs 101, 102), and the second screens pass (PR 103: real tribe cards through the real screen in tests, one data shape, the Compost's contents on hover, fights showing blocked hits, given effects and returns). PR 103's review (done 03:40) had one cut and two simplify items, sent to the `ideation/screens-3` worker, and three questions for the owner (below).
- **Second play-test (agent, 17 Nov 03:00, on build `five-tribes-2`):** all five tribes play from start to knockout with no errors. Its list (fights hard to follow, skipping inconsistent, a Compost plate without briars) was worked through in PR 104.
- **Builds:** `five-tribes-4` (commit a03d270b, 17 Nov 05:56) is in R2 and is the one to play: all five tribes as designed, recipe art on every card, four screens passes (PRs 99, 103, 104, 105). On this commit: `scripts/check.sh` passed, a 100-game soak of the five tribes had 4,495 fights and 0 violations, and a reviewer played nine turns with real key presses with no error. It booted under wine; it has not run on real Windows. The owner's line (PowerShell): `npx.cmd -y wrangler@4.160.1 r2 object get bramble-assets/sha256/d9/d936411196b83d3eeb57143b748e90d22e1be24d19206aee9ba74eecd76b0910.zip --remote --file "$HOME\Downloads\Bramble-windows-a03d270be-1117-0556-five-tribes-4.zip"; Expand-Archive "$HOME\Downloads\Bramble-windows-a03d270be-1117-0556-five-tribes-4.zip" "$HOME\Downloads" -Force; ii "$HOME\Downloads\Bramble-windows-a03d270be-1117-0556-five-tribes-4"`. Three older builds (`five-tribes-1`, `-2`, `-3`, about 390 MB together) are still listed in `tools/assets/manifest.tsv`; once the owner has played the new one, remove their lines and run `python tools/assets/assets.py prune --delete`. Nothing is running; no worker branch or worktree is left.
- **Step 3, cards:** all five tribes designed and committed under `docs/ideation-track-2/tribes/`, with `SHARED-RULES.md` (one glossary, 46 cross-tribe rulings) and `CROSS-TRIBE.md` (for the owner). Art: locusts and pigeons merged (PR 83, `assets/units/`); briars, mice and badgers merged (PR 81; three pictures remade once). All 99 cards have a picture. The art PRs' review had nothing to cut; its fix (mipmaps on the older 40 pictures, one test over the shipped cards) is PR 100. Not done: the masters and prompts are only on the Optiplex under `/data/bramble-art/track-2/` (about 175 MB), not in R2. Masters are under `/data/bramble-art/track-2/`.
- **Step 5, screens:** recruit and fight screens (PR 82) and play: spells in hand, target picking, the Discover picker, tweens (PR 86).
- **Game flow:** merged (PRs 85, 92). The main scene plays a whole game against bots with the five tribes.
- **Step 6, builds:** `scripts/build_windows.sh [--push] <label>` (PR 78). First playable build: `five-tribes-1`.
- **First play-test (agent, 17 Nov 01:30):** the rules work and match the cards; the screen did not explain them. Fixed in PR 99.

## The owner's picks (16 Nov 2026, from the page's database, as written)

- **Badger:** Battle fury. No note.
- **Mouse:** Pile on. Note: "If we're going to have this where mice attack and kind of they're sticky in a way, right, the idea is they're like piling on, they're going to need a way of scaling attack. So, but I don't want them to scale HP, so they are weak, but it'd be good for the Mice as a tribe to have a lot of attack scaling in some ways. They Cloudflare *[probably "could have"]* some slot attack scaling too. They Cloudflare *[probably "could have"]* a bit of a fuse *[probably "a few"]* units that summon stuff. Like, we, I think, like, you're looking at the core mechanics as too simple, and the tribes will fall apart. They need to have a mix of units to provide different things and different strategies, right? If you were to look at a tribe like beasts Battlegrounds, there's like four or five different sub-strategies you can run. There's attack scaling beasts where you try and scale the attack with a five-drop and banana slammer. There's Lobster Beast, where you try and trigger lobster Deathrattle repeatedly. There's like rally beasts, where they use them to get money and use the money to try and trigger more rallies that trigger Deathrattle. You can either use Goldrin or something else. There's like Beetle Scaling Beasts. There's like, you know, all the cards kind of tie together and form a bunch of different options and strategies. And none of these tribes are really pitched as one-dimensional. They should have like three or four effects that kind of work together and kind of can either mesh together or serve as pieces for, you know, other tribes as well, and a bit flexible. It needs to be a bunch of overlapping, like horizontal design as well as vertical design. If mice only care about being near other mice, they're not interesting options for any player who doesn't have a mouse on their board. That doesn't mean that all units should not care about other mice. Some should, some shouldn't. There needs to be a mix. Think about the tribe as having to have multiple different sub-strategies"
- **Wood pigeon:** Medals. Note: "I think we should have a mix of trail *[probably "Drill"]* and medals, and I think maybe Pigeon should buff the slots rather than teach other pigeons and stuff. We're going to need some slot buffs stuff. We may need additional spice as well. I feel like this is a bit bland as is"
- **Locusts:** none of the three. Note: "I don't think any of these really fit locusts very well. Kind of the way I see them is they kind of like swarm and, you know, leave devastation in their wake and breed more locusts. So I thought of them more of like a summoning tribe, more similar Battlegrounds Undead"
- **Briars and thorns:** Compost. Note: "Compost wasn't optional. That's what we're doing. Find a way of making it work"

## The owner on designing the tribes (16 Nov 2026, in chat)

"I think there's some weak designs there that might have been caught when you tried to flesh them into full tribes. If a tribe's not looking good and, it, you know, comparing it to like, the, you know, finding like 4 or 5 different sub-setups that all kind of seem like similarly interesting and competitive with one another, you know, and reasons you might want to run them and ways the units could be used with other tribes so that not just, you know, some of the units in the tribes are flexible and, you know, etc. You may have to go back to the beginning and try again with stuff. You have my permission to iterate multiple times and log what worked and what didn't, and I'll check it when we look at the build."

## The owner's answers for the overnight run (16 Nov 2026, late evening)

- **Who is in charge, and merging:** "I don't mind whether you merge as long as nothing goes back on domain *[main]*. You can merge everything you want. You know, I would prefer clean work trees and clean branches, unless there's a pressing reason ... Like you're the PM, you're in charge of this stuff. But yeah, you can't merge on domain *[main]*. But yeah, within ideation, it's yours. You're the owner." And: "you're in charge of ideation, right? I'm just here to advise on ideation, and I pick and choose the stuff that I like from here."
- **Locusts:** design them from the note, no second options page. "Locusts. Yeah, you do that."
- **Dictation:** "Cloudflare" in the picks notes means "could have". "trail" in the pigeon note is read as "Drill" (not confirmed).
- **Tribe quality:** no owner note, but: "you need to keep that in mind, right? Like, that's going to be a big struggle you're going to have with quality, is that these things come through and aren't cohesive. I mean, I'll iterate them, but I'd like to do as little iteration as possible because you guys get it as right as you can first try."
- **Models:** "You can use what models you want. If you want to use Fable for specific really high-skilled tasks and you're having struggle with the designs, go for it. No, never use the max effort setting. If you really need to, you can go to XI *[xhigh]*. I doubt you'll need it though."
- **Pictures:** "Yeah, you can generate some pictures. Just make sure you throw away anything you don't like ... it doesn't meet your quality standards, just delete, because don't go crazy, don't be wasteful, right? Like, it's concept art at the end of the day. This is all going to be redrawn by a human artist at the end. It needs to feel right and be of a decent quality. Like, concept art needs to evoke the right feeling, but it doesn't need to be perfect."
- **The mock-up pieces:** "I want the mock-up stuff brought into Godot as part of this."
- The orchestrator runs on the Optiplex and keeps running when the owner's PC is off. The quality advisor session is on the owner's PC.

## Calls the orchestrator made (not decided for the real game)

- **Look tool (PR 74):** reused the first run's tool; `godot-mcp-runtime` not tried (owner: "if that's working for you, then go for it"). Four look games at once, 3 GB each; the gate's own check has its own lock.
- **Glass pieces (PR 75):** the hand count is not pulled from the mock-up (it shows 10; the rule is 7). The screen numbers under `stage.*` are a partial pull the screens step completes. The rest of the mock-up's assets come in with each screen.
- **Screens:** the Godot project is drawn at the mock-up's 1920x1080.
- **Rules core (PR 76):** the scope review found it follows the rulebook where built, but its mechanic interface fits only two of the five picked mechanics in their plainest form. A second pass builds what the tribes need before any tribe's units are coded. Battlegrounds-style keywords stay available to tribe cards; shop odds are flat for this build (rulebook 6.1.7 is open); the screens read the player view and the fight log.
- **Tribe designers run on Fable,** critics and engineering on Opus.

## For the owner to decide

- **Badger Fury differs from the option picked.** The option read "+8/+8 ... while the enemy has more units than you ... As the enemy thins out, the fury stops by itself". As designed and built, Fury gives Attack only, and the outnumbered count is fixed at the start of the fight, so it never fades. The designers' reasons are in `tribes/badger/LOG.md`.
- **Pigeon Medals reward surviving on one card only** (Old Campaigner). The Adjutant and Flying Ace give Medals alive or dead.
- **Three shop spells nobody designed** (Sharpen, Seek, Forage) are in the game as stand-ins, because the plan says "Spells: in, a small set" and no tribe has a spell.
- **Counters by the portrait differ from the owner's mock-up.** The mock-up shows emblem chips (an emblem and a number). The build shows named plates ("Compost 4", "Tide 3"), because a play-tester could not tell what an unnamed chip was and no emblems exist for the tribes' counters. The recruit and fight compares now run against copies of the owner's pages under `docs/ideation-track-2/mockups/` that draw the plates. Chips or plates is the owner's call; if plates, the owner's own pages should change.
- **`recruit-tribes.html` is drawn from the build's own data,** so it checks layout with real cards and art, and cannot catch a wrong pill. It is not a mock-up.
- **A seed line on the pause panel** (for bug reports from play-tests) was added by the orchestrator, not asked for.
- **Fights are long.** Over 173 fights the middle one ran 19 s and the longest 49 s. Space or a click skips to the result. Faster pacing is the owner's call.
- **The result screen leaves by itself after 2.5 s;** a "You" label sits under the player's portrait on the start screen. Both small, both the owner's call.
- **In a fight, a hover does not always say why a number is green or red** (an opponent's saved board, units that arrive mid-fight). On the recruit board every changed number names its source.
- **"Space or click to skip" stays on screen through every fight.** It is the one static line left; without it nothing tells a player a fight can be skipped.
- **Counter emblems are not drawn.** Plates for the Compost, the Tide, Medals and the rest name an emblem that has no picture yet.
- **Gold piles up** (a play-tester had 56 by turn 7). That is rulebook 4.1.1 and 4.1.2 as the owner set them on 12 Nov; it is left alone.
- **Mock-up match numbers are run by hand.** The gate does not re-run the screenshot compares.

- **Cloudflare account ID in a closed PR.** PR 77 (Windows build) committed `.wrangler/cache/wrangler-account.json` by mistake: the owner's Cloudflare account ID and email, on a public repo. The file never reached `ideation/track-2` (the work was redone as one clean commit, PR 78; `.wrangler/` is now gitignored; PR 77 is closed and its branch deleted). GitHub still serves a closed PR's commits through the PR, and only GitHub support can purge them. The ID is an identifier, not a credential. Whether to ask GitHub to purge it is the owner's call.
- **Recruit screen (PR 79, closed; continues on `ideation/fight-screen` as one PR for both screens):** buying is by drag only; the leaderboard is hidden until Tab or a click on the player's corner; the frozen look and the golden look are stand-ins (the mock-up has neither); the two chips by the player's corner show player counters such as the Compost count; the mock-up's Ring slot look is used for an empty slot that holds a slot buff. The Discover picker gets an HTML mock-up first, as the plan says.

## Small things left undone (17 Nov, 06:10)

- `tests/screens/fixtures/fight_moments.json` still has a `"waiting"` block nothing reads, and a button in `mockups/stand-ins.html` still says "outnumbered, waiting, used up".
- The whole-game test compares shop and fight numbers in the five single-tribe games but not in the all-tribes game (the core's test cards are loaded into it). A reviewer ran six mixed games of only the shipped tribes with numbers compared: all passed. A mixed game of only shipped tribes should be added to the test.
- Enter skips a fight; only a unit test covers it.
- The core's `effect` fight event carries no `totals`, so a keyword given twice in one fight shows a summed number until the next unit view.
- Stand-in cards (`src/game/data/stand_in_units.json`) and the Battlegrounds keywords only they use are still in the core.
- This checkout's Godot cache goes stale after merges: a soak run here failed with "Nonexistent function 'create'" until `godot --headless --editor --import --quit` was run. Workers' fresh worktrees and the build (a clean copy) are not affected.
