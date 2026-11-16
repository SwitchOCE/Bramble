# Ideation track 2: hand-over

For a session that picks this track up if the orchestrator stops. The plan is `docs/workstreams/ideation-track-2.md` on `main`; this file only says where the work stands. Keep it short and current.

Last updated: 16 Nov 2026, evening (Optiplex).

## Where things are

- **Integration branch:** `ideation/track-2`. Workers branch from it as `ideation/<something>`; PRs target it, never `main`.
- **Step 1, look tool:** merged (PR 74). `tools/look/README.md` says how to use it.
- **Step 1, mock-up pieces into Godot:** merged (PR 75). `assets/glass/`, `src/glass/`, `tools/glass/`. Owner, 16 Nov: "I want the mock-up stuff brought into Godot as part of this."
- **Step 2, mechanics:** done. Page source in `docs/ideation-track-2/mechanics/`; the owner's picks and notes are in that page's database (collection `picks`) and copied below.
- **Step 4, rules core:** PR 76, branch `ideation/core`. Gate passed; scope-review changes being made, then merge. A second pass (the hooks the five tribes need) follows as its own PR.
- **Step 3, cards:** five tribe designers working from `docs/ideation-track-2/tribes/DESIGN-FRAME.md`; each tribe gets a folder there with its units, plans and log.
- **Step 5, screens:** recruit screen in progress on `ideation/recruit-screen`. Fight screen not started.
- **Step 6, builds:** not started.

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

- **Cloudflare account ID in a closed PR.** PR 77 (Windows build) committed `.wrangler/cache/wrangler-account.json` by mistake: the owner's Cloudflare account ID and email, on a public repo. The file never reached `ideation/track-2` (the work was redone as one clean commit, PR 78; `.wrangler/` is now gitignored; PR 77 is closed and its branch deleted). GitHub still serves a closed PR's commits through the PR, and only GitHub support can purge them. The ID is an identifier, not a credential. Whether to ask GitHub to purge it is the owner's call.
