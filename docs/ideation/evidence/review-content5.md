# Review: content5 (`c11e55d..cb7a1cc`)

**Counts: cut 1, ask 2, simplify 2.** Reviewer: fresh cloud session, 8 Nov 2026. Scope: design5 §0 revised texts (pitches 1, 2, 3, 8), plus the owner's 8 Nov rule: "Do not revise, rescale or cut anything already in your library."

**Does it move the problems?** In part, and the evidence is thin. Horseshoe is a direct answer to Ring piles, but the bench doesn't log spell buys, so whether bots cast it is shown only by unit tests. Birds: a 60-lobby spread gave Summer/Winter 5.24 average place (n=29, prior 6.11), Passage 6.14 and Highway 4.06. The samples are too small to separate. On final boards, Barn Owl appeared 30 times and Redwing 17. Positioning: both units are positional, and the bots place them by lane. Economy: Stall is bounded at 2 and costed from health.

## Items

- **cut** `src/core/game_session.gd:805`: a ghost's slot snapshot is taken before `after_fights` clears Horseshoe. A player eliminated after casting it leaves a ghost that halves Rings permanently, which contradicts "Next fight". I found this by reading the code; I didn't probe it. Fix: strip Horseshoe from `_ghost_slots`.
- **ask** `src/core/recruit_rules.gd:76-79`: the 7-unit ceiling applies to every player, not only to Stall slots. Probed: Pipkin at tier 6 with no Stall shows 8 units on `c11e55d` and 7 on `cb7a1cc`. Hunter Poach overflow is also deferred now (`hunter_recruit.gd:18`). Design5 assumed Pipkin was "already at 7". That conflicts with the "do not revise" rule. Owner call: cap only Stall additions, or accept the rulebook ceiling.
- **ask** `src/core/combat/combat_reactions.gd:48`: Owl immunity covers the whole attack, so Death text it triggers inside that attack (for example Mrs Posset's 3) can't hurt it either. That's a defensible reading of "when attacking", but it's broader than the pitch's counterplay list assumes.
- **simplify** `assets/portraits/redwing.jpg`: painterly fine feathers and gradients, off the flat house style that Jack Daw, Barn Owl and Horseshoe follow. `market_stall.jpg` is textured too. Re-roll both flatter.
- **simplify** `src/core/mechanics/redwing.gd:22-44`, `player_state.gd:255-288`: about 70 lines of `redwing_eggs` public-scout plumbing. Snapshotting the supported Egg as a plain spec would do the same job.

## Checked, keep

- Texts, tiers, costs and bodies match the revised pitches exactly. No existing unit, spell or hero file changed: `content/` differs only by 4 new files, bot priorities and the glossary.
- Pitch interactions have tests: Wisp, Monarch and Hex with Horseshoe; Reel-Mistress's dance; Bristle and Bitter, Mire, decoys and the Brock/Laird quarry refusal for the Owl; Dunnock, Stork, Goose, Whistlers and theft for Redwing; Pipkin, Hungry Gap, the held-Stall limit and Stone Soup for the Stall.
- Mutation probes. The Owl immunity mutation failed 8 tests and the `no_quarry` mutation failed 3. The Horseshoe-expiry mutation failed 7 tests in the selected batch, but I didn't check which ones.
- Bots wait for a scouted Ring before buying Horseshoe, skip a dead second Stall and avoid Owl Mire traps. Sensible.
- `./scripts/check.sh` passed, all ten steps.
- Four games with `tools/play/play.sh`, driven by a crude script: all placed 8th by round 10, and none was offered or bought a new card. That's a driver weakness, not evidence about the cards.
- The variation notes copy §3 and change no originals. That's in scope.
