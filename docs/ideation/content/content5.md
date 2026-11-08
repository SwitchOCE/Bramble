# Round 5 additions

Implemented from the revised openings of pitches 1, 2, 3 and 8 and section 0 in `origin/ideation/c-design5:docs/ideation/evidence/design5.md`, with its critics. Existing printed card designs remain unchanged (owner, 8 November 2026). The alternatives for existing designs are recorded separately in [variation-notes.md](../variation-notes.md).

| Card | Offering / body | Exact text |
|---|---|---|
| Horseshoe | Spell, from tier 2, costs 1 | Next fight: halve the Ring across from a slot. |
| Barn Owl | Birds, tier 4, 3/4; golden 6/8 | Swoop. Takes no damage while attacking the back row. |
| Redwing | Birds, tier 2, 2/2 | Fly South. Eggs beside this have their Bird's full stats. |
| Golden Redwing | 4/4 | Fly South. Eggs beside this have their Bird's full stats, +2/+2. |
| Market Stall | Spell, from tier 4, costs 4 | Your shop permanently shows 1 more unit of your tier. |

The card wording now follows `wording-guide.md`; effects and numbers are unchanged. Quarry refusal, rounding, caps and other rulings live in each card’s `details` layer.

## Interaction rulings and simplest readings

- **Horseshoe** can choose an empty own slot. It marks the opposing Ring before Start of Combat, rounds Attack and Health down independently after adding Monarch's contribution, and expires after that fight, including ghost fights. Eliminated-player ghost snapshots discard spent Horseshoe markers. Repeated Horseshoes on one slot do not stack. A Ring reduced to zero is still a Ring, including for Wisp summons. Its investment stays intact for recruit, including Queen's tithe. Hex and other slot effects are separate. A dancing Ring carries its weakening, including any golden Reel-Mistress growth; when Rings meet, their weakening remains attached to the affected contribution. Monarch remains one addition per slot and is halved if that slot holds a weakened Ring. Whirligig swaps units, so the spell still targets the chosen Ring slot; the draft Farrier's moving source does not exist here. Mag Pye cannot steal a spell's slot marker.
- **Barn Owl** refuses both its own and lent quarry. Mire still outranks Swoop. A declared back-row attack prevents all damage during that attack, including declaration damage, retaliation and Bristle. Prevented hits do not consume Shell or fire damage hooks. Bitter and other changes that are not damage still work. Immunity ends before queued replies; defending and attacking a front-row Mire maker remain vulnerable. Swoop still randomly chooses among back-row decoys, including Eggs and Shell carriers. Hoolet changes attack order normally. Stolen Owl text confers these rules.
- **Redwing** affects immediate neighbours in the same row, the existing meaning of beside. The strongest adjacent Redwing applies: full Bird body once, with at most one golden +2/+2. It is a temporary aura; moving, flying, dying or losing its text removes support. An Egg retains its damage when the aura changes, using existing aura Health rules. The full body includes the away Bird's permanent and tribe bonuses, not the Ring it left behind; the Egg's current Ring is added separately. Even Mother Goose's normally 0/2 Egg receives her full body beside Redwing. Nests covered by recruits produce no Egg. Trips, Dunnock/Stork/Tern timing, Bird play effects, Whistlers, Supper and ghost-fight timing keep their existing rules; there is no new homecoming growth.
- **Market Stall** takes effect on subsequent refills, without refreshing existing offers. Newly filled extra unit slots use the player's current tier; no lower-tier fallback if that tier's pool is empty. Existing frozen offers retain their identities. The two-Stall limit counts upgrades plus copies already in hand, preventing dead shop and Discover offers. Normal tier 6 can legally buy a redundant second Stall. Only Stall additions are capped by seven normal unit offers. Existing hero shop sizes and Poach bonus offers retain their c11e55d behavior: tier-6 Pipkin without a Stall still shows eight units. Pipkin converts blocked Stall additions into spell slots. Hungry Gap retains its existing one-fewer behavior and does not create extra conversion. Stone Soup reaches extra units normally; frozen offers and Poach admission/expiry remain unchanged.

## Bot and portrait support

The strongest bot values Horseshoe from its actual scout, chooses the biggest unweakened opposing Ring, avoids unsupported casts, values Owl against back-row targets and Mire, arranges Redwing beside empty Nests, accounts for support lost when flying, and buys Stall as an investment when survival and usable shop space justify it. All three Birds bench strategies include the new Birds with route-appropriate weights.

Codex's built-in image tool generated four separate portraits from [the prompt file](../../../tools/art/prompts/content5.txt), using the header and format from `tribes56-bog.txt`. Final 512-square JPEGs: `assets/portraits/horseshoe.jpg`, `barn_owl.jpg`, `redwing.jpg`, `market_stall.jpg`. PNG masters are outside the repository and are not committed.

Review follow-up: Redwing and Market Stall were re-rolled in the flat house style with Codex's built-in image tool; final JPEG destinations are unchanged. Prompts: [content5-flat-review.txt](../../../tools/art/prompts/content5-flat-review.txt).
