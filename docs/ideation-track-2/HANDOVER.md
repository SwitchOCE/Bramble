# Ideation track 2: hand-over

For a session that picks this track up if the orchestrator stops. The plan is `docs/workstreams/ideation-track-2.md` on `main`; this file only says where the work stands. Keep it short and current.

Last updated: 16 Nov 2026, evening (Optiplex).

## Where things are

- **Integration branch:** `ideation/track-2`. Workers branch from it as `ideation/<something>`; PRs target it, never `main`.
- **Step 1, look tool:** PR 74, branch `ideation/look`. Scope review done; the owner agreed the cuts and limits (16 Nov: "I follow your recommendation. Yeah, you manage the machine. Make sure you don't crash it."). Merge once `scripts/check.sh` passes on its head.
- **Step 1, mock-up pieces into Godot:** branch `ideation/glass-pieces`, stacked on `ideation/look`. In progress. Owner, 16 Nov: "I want the mock-up stuff brought into Godot as part of this."
- **Step 2, mechanics:** done. Page source in `docs/ideation-track-2/mechanics/`; the owner's picks and notes are in that page's database (collection `picks`) and copied below.
- **Step 4, rules core:** branch `ideation/core`. In progress.
- **Steps 3, 5, 6:** not started.

## The owner's picks (16 Nov 2026, from the page's database, as written)

- **Badger:** Battle fury. No note.
- **Mouse:** Pile on. Note: "If we're going to have this where mice attack and kind of they're sticky in a way, right, the idea is they're like piling on, they're going to need a way of scaling attack. So, but I don't want them to scale HP, so they are weak, but it'd be good for the Mice as a tribe to have a lot of attack scaling in some ways. They Cloudflare *[probably "could have"]* some slot attack scaling too. They Cloudflare *[probably "could have"]* a bit of a fuse *[probably "a few"]* units that summon stuff. Like, we, I think, like, you're looking at the core mechanics as too simple, and the tribes will fall apart. They need to have a mix of units to provide different things and different strategies, right? If you were to look at a tribe like beasts Battlegrounds, there's like four or five different sub-strategies you can run. There's attack scaling beasts where you try and scale the attack with a five-drop and banana slammer. There's Lobster Beast, where you try and trigger lobster Deathrattle repeatedly. There's like rally beasts, where they use them to get money and use the money to try and trigger more rallies that trigger Deathrattle. You can either use Goldrin or something else. There's like Beetle Scaling Beasts. There's like, you know, all the cards kind of tie together and form a bunch of different options and strategies. And none of these tribes are really pitched as one-dimensional. They should have like three or four effects that kind of work together and kind of can either mesh together or serve as pieces for, you know, other tribes as well, and a bit flexible. It needs to be a bunch of overlapping, like horizontal design as well as vertical design. If mice only care about being near other mice, they're not interesting options for any player who doesn't have a mouse on their board. That doesn't mean that all units should not care about other mice. Some should, some shouldn't. There needs to be a mix. Think about the tribe as having to have multiple different sub-strategies"
- **Wood pigeon:** Medals. Note: "I think we should have a mix of trail *[probably "Drill"]* and medals, and I think maybe Pigeon should buff the slots rather than teach other pigeons and stuff. We're going to need some slot buffs stuff. We may need additional spice as well. I feel like this is a bit bland as is"
- **Locusts:** none of the three. Note: "I don't think any of these really fit locusts very well. Kind of the way I see them is they kind of like swarm and, you know, leave devastation in their wake and breed more locusts. So I thought of them more of like a summoning tribe, more similar Battlegrounds Undead"
- **Briars and thorns:** Compost. Note: "Compost wasn't optional. That's what we're doing. Find a way of making it work"

## The owner on designing the tribes (16 Nov 2026, in chat)

"I think there's some weak designs there that might have been caught when you tried to flesh them into full tribes. If a tribe's not looking good and, it, you know, comparing it to like, the, you know, finding like 4 or 5 different sub-setups that all kind of seem like similarly interesting and competitive with one another, you know, and reasons you might want to run them and ways the units could be used with other tribes so that not just, you know, some of the units in the tribes are flexible and, you know, etc. You may have to go back to the beginning and try again with stuff. You have my permission to iterate multiple times and log what worked and what didn't, and I'll check it when we look at the build."

## Asked, not yet answered (16 Nov, evening)

Whether the orchestrator may merge overnight after applying scope-review cuts itself; whether to design locusts from the note without a second options page; the two dictation guesses above; whether to record the design instruction as an owner note; Fable for tribe designers; Codex usage for about 95 card pictures. Until answered: no merge with open cut or ask items, Opus designers, the owner's words quoted in briefs.
