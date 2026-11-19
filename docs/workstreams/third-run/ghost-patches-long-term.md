# Recorded runs across patches, in the live game

Status: **research and a proposal, not decided.** This is the long-term problem the rulebook leaves open at 2.1.9. It changes nothing in development, where 2.1.8 holds: the field is refilled from bots after a rules change.

## The problem, in the owner's words

The owner, 19 Nov 2026, approving the ghost plan:

> "The old ghost stuff that'll be harder, I think, for when the games are really live, we won't have any ghosts if we make an update in the future. Like that rule can only hold in dev, and I don't want to populate ranked games in the future with bots. So we may have to allow the architecture for a player to play against a different patch. And I'm not sure how that would work with utility effects and stuff. And we'd hope to age the old ghosts out very quickly. It's a thorny subject, essentially. I like the idea of repopulating with bots for all of development, but we need to document that we need a solution long term and look at how other games have done it long term in terms of when we're a live game, how do we handle that exact same problem"

Put simply: in the live game, every patch makes the recorded runs out of date. If they are thrown away, ranked has no opponents. If they are filled with bots, that breaks the owner's rule. If they are kept, someone has to decide which rules a fight between an old board and a new board uses.

## What other games do

Research done 19 Nov 2026. Claims from players rather than developers are marked.

| Game | What happens at a patch | Source |
|---|---|---|
| Once Upon a Galaxy | Stores each run's decisions and replays them turn by turn. Old boards stayed in the pool until it filtered them. Twice it purged: all old-patch boards after cards left the game ("No more Santa, Mop, etc. on opponents boards", 8 Oct 2025), then only boards from before one card's nerf ("Old pre-Scrubfowl nerf boards are now flushed from the pool", 29 Oct 2025). New players fight bots until 5 wins or 10 games. | [guide](https://guide.galaxy.fun/asynchronous-gameplay/), [Oct notes](https://galaxy.fun/articles/patch-mid-october-2025/), [Nov notes](https://galaxy.fun/articles/patch-early-november-2025/) |
| Backpack Battles | Matches "builds of players that played recently and in the same version". So each version has its own pool. | [developer FAQ](https://steamcommunity.com/app/2427700/discussions/0/4363502241742993489/) |
| Super Auto Pets | Opponents come from teams made on the same turn and the same pack. AI teams fill in when no player team exists for that turn. No stated rule for patches. | [wiki](https://superautopets.wiki.gg/wiki/The_Basics) |
| The Bazaar | Ghosts are matched by day, and since Sep 2025 by rank too. *Players report* a full wipe at each patch, with "fake" ghosts until the pools fill again. | [announcement](https://bazaar-builds.net/announcement-future-updates-for-the-bazaar-september-10th-patch/), [Steam thread](https://steamcommunity.com/app/1617400/discussions/0/803467095729848476/) |
| Clash of Clans | *Inferred:* a base is saved as a layout and building levels, so old bases fight with today's numbers. Old replays stop working after a gameplay change. | [clash.ninja](https://clash.ninja/guides/why-cant-i-view-previous-replays) |
| Trackmania, other racing games | *Players report* that physics updates break old ghosts and leaderboards reset. | [forum](https://tm.mania-exchange.com/threads/4357?page=6) |
| Worms Armageddon | Every client in a match runs the oldest client's rules. One ruleset for the whole match; the only case found of keeping old rules in one build. | search snippet only; the page refused the fetch |

Battlegrounds, TFT, Underlords and Storybook Brawl have no cross-patch problem: their games are live lobbies.

What they have in common:
- No game found runs old card code against a live player's cards.
- The usual tool is a purge triggered by a changed card (Galaxy). Separate pools per version is the same idea built in (Backpack Battles, Super Auto Pets).
- Bots fill short gaps only: new players, the hours after a patch.
- No source says how long old ghosts are kept.

## The options

**(a) Fight an old board under its old rules.** Every card and engine rule would be kept per version. The owner's worry about effects is the real blocker: when an old aura buffs a new card, or an old summon makes today's token, every pair of versions needs a ruling, and the tests multiply with each patch. Players also lose to cards they can no longer buy, which is the complaint Galaxy's filter answered. **Never in ranked.** At most for watching old replays.

**(b) Move old boards onto the new numbers.** Swapping stats in place breaks on stored buffs: a unit that gained +2 a turn from a card now nerfed to +1 keeps a total the new rules can't make. Replaying the run's decision log under the new patch is honest, and the plan already records decisions. A decision that becomes illegal or changes its result drops the run. The shop rolls differ, so the rebuilt run isn't what was really played. **A gap-filler, not the main tool.**

**(c) Drop only the runs that hold a changed card.** Each card carries a fingerprint of its rules. After a patch, drop any run whose fingerprints or rules version don't match. A normal balance patch keeps most of the field. The changed set must include cards a held card can make (tokens, summons, Discover) and cards whose auras reach it. A change to the economy or core rules (gold, tier costs, combat order) changes every board without touching a card, so it drops everything.

**(d) Batch balance changes into scheduled patches.** Hotfixes between them only for crashes and exploits. Costs nothing to build, and makes (c) drop fewer runs.

**(e) Refill before release.** Internal and tester play is too little to cover every turn and rank. An unranked window after each patch is honest but holds back ranked. A **test realm** that runs the exact release content for a few days makes runs with the right fingerprints, valid in ranked from release. Widening matchmaking (more ranks, neighbouring turns) comes before any other fallback.

**(f) Smaller tools.** Prefer recent runs, so old ones fade without a hard purge (the owner's "age the old ghosts out very quickly"). Bots outside ranked only, marked as bots.

## Proposal

1. Ranked only matches runs from the same rules version with the same card fingerprints. No fights under mixed rules.
2. At each patch, drop runs by changed card (c), counting created and linked cards. Any economy or core change drops all of them.
3. Batch balance changes into scheduled patches (d).
4. Fill each patch from a test realm with identical content (e). If it runs short, in order: wider matchmaking; runs rebuilt from their decision logs (b) for numbers-only patches; then a delay to ranked, or bots in unranked only.
5. Old card rules are kept only for watching old replays, if that is ever wanted.

This is for the owner to decide before the game goes live. Nothing in the third run depends on it.

## What the ghost format records from day one

So that none of the options is ruled out later, the ghost system built in step 3 records:

**Per run:** rules version (engine hash and content hash); patch id; source (player, internal, tester, test realm or bot), so ranked can leave some out and the field's mix can be measured; player id and rating at the time; a timestamp, for preferring recent runs; hero and any run modifiers.

**Per turn:** the whole board; the decisions made; the seeds for that turn's shop and fight; gold, tier and health.

**Per unit:** card id and its rules fingerprint (stats, effect version, keywords); base stats at that version; a buff ledger, where each stat change has its source card, the source's fingerprint, and whether it lasts; golden state and slot.

**Per patch, kept apart from the runs:** the list of changed card fingerprints, counting created and linked cards, so dropping runs by card is one query.

In development (rulebook 2.1.8) only the rules version, the source and the per-turn record are used. The rest is recorded, not acted on.
