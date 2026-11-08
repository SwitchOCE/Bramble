# Review: content5 (`c11e55d..cb7a1cc`)

**Counts: cut 1, ask 2, simplify 2.** Scope: design5 §0 revised pitches 1, 2, 3, 8, plus the owner's 8 Nov rule "do not revise… anything already in your library".

**Does it move the problems?** Partly, on thin evidence.
- **Ring piles:** Horseshoe answers them directly, but the bench doesn't log spell buys, so only tests show bots casting it.
- **Birds:** a 60-lobby spread gave Summer/Winter 5.24 average place (n=29, prior 6.11), Passage 6.14 and Highway 4.06. The samples are too small to tell apart.
- **Positioning:** Owl and Redwing are both lane-placed by the bots.
- **Economy:** Market Stall is bounded at two.

## Items

- **cut** `src/core/game_session.gd:805`: the ghost's slot snapshot is taken before `after_fights` clears Horseshoe. A player eliminated after casting it leaves a ghost that halves a Ring every fight, against "Next fight". Found by reading, not probed. Fix: strip Horseshoe from `_ghost_slots`.
- **ask** `src/core/recruit_rules.gd:76-79`: the 7-unit ceiling applies to every player. Probed: Pipkin at tier 6 with no Stall shows 8 units on `c11e55d` and 7 now. Poach overflow is also deferred (`hunter_recruit.gd:18`). This changes an existing hero. The options are to cap only the Stall additions, or to accept the rulebook ceiling.
- **ask** `src/core/combat/combat_reactions.gd:48`: Owl immunity spans its whole attack, so Death text it triggers there (e.g. Mrs Posset's 3) can't hurt it either. Defensible but broad.
- **simplify** `assets/portraits/redwing.jpg`: painterly feathers and gradients, off the flat house style. `market_stall.jpg` is textured too. Re-roll both.
- **simplify** `src/core/mechanics/redwing.gd:22-44` and `player_state.gd:255-288`: about 70 lines of `redwing_eggs` scout plumbing. A plain Egg spec in the snapshot would do the same job.

## Checked, keep

- Texts, tiers, costs and bodies match the revised pitches. No existing unit, spell or hero file changed.
- Every interaction the pitches list has a test.
- Mutation probes: the Owl immunity mutation failed 8 tests, `no_quarry` failed 3 and Horseshoe expiry failed 7.
- Bot logic is sensible: Horseshoe waits for a scouted Ring, a dead second Stall is skipped and Mire traps are avoided. In the bench, Barn Owl appeared on 30 final boards and Redwing on 17.
- `./scripts/check.sh` passed all ten steps.
- Four play.sh games, scripted crudely: all placed 8th by round 10, and none reached a new card. Driver failure, not card evidence.
- The variation notes copy §3 and leave the originals alone.
