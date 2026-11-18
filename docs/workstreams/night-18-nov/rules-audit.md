# Rulebook v0.9 vs the build: audit, 18 Nov 2026

Read-only audit by a Codex worker at dev `960625f7`. File links point to a worktree that may be gone; the file:line references still hold for that commit.

Audited **193 numbered rules** in chapters 1–10 at `960625f7`: **140 MATCH, 24 DIFFERS, 14 MISSING, 15 N/A**.

The economy tables, pool copy-count tables, Bought/Created sell values, and mixed-origin triple sell accounting match. **C15 remains incomplete:** hand sales and board-to-hand moves are absent; recruit effects and Triple Rewards retain the earlier timing.

S/M/L estimates include implementation and verification. Proposed defaults are **not bugs**. Rows marked **wording conflict** need rulebook clarification before changing gameplay. File links point to the audited worktree.

| Rule | Tag | Result | What the build does | File:line | Size |
|---|---|---|---|---|---|
| 1.1.3 | [BG] | MISSING | Placements work; rating and the top-four rating-win classification are absent. | [player_state.gd:49](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/player_state.gd:49) | M |
| 1.2.3 | [PROPOSED] | DIFFERS | Combat setup effects run before main effects, overriding unconditional reading order. | [combat.gd:233](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:233) | M |
| 1.2.4 | [PROPOSED] | DIFFERS | Integer stats, attack floor and billion-point cap work; numbers above four digits are printed in full. | [glass_card.gd:251](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/glass/glass_card.gd:251) | S |
| 2.1.2 | [BG] | DIFFERS | Elimination ghosts work, but there is no mid-phase concession action or corresponding ghost replacement. | [recruit.gd:105](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:105) | M |
| 2.1.4 | [BRAMBLE] | DIFFERS | Uses current boards in a local eight-player bot lobby, without a timer; no asynchronous recorded-opponent matchmaking. | [game_flow.gd:49](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/game/game_flow.gd:49), [game_session.gd:229](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:229) | L |
| 2.2.1 | [BG] | MISSING | No hero offers or selection; seats receive fixed stand-in identities. | [game_flow.gd:16](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/game/game_flow.gd:16) | L |
| 2.2.2 | [BG] | MISSING | No two-hero offer or 70-second selection timer. | [game_session.gd:6](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:6) | M |
| 2.2.4 | [BG] | MISSING | No tribe-dependent hero eligibility filtering. | [game_session.gd:6](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:6) | S¹ |
| 2.2.6 | [BG] | DIFFERS | Armor absorbs damage correctly, but starting armor is one global setting, default zero, rather than a per-hero value. | [game_config.gd:10](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/rules/game_config.gd:10) | S¹ |
| 2.2.7 | [BG] | MISSING | Unit abilities exist; hero powers do not. | [recruit.gd:105](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:105) | L |
| 3.1.1 | [BRAMBLE] | DIFFERS | Recruit precedes combat, but human End Turn drives all bots and fights together, rather than independent asynchronous turns. | [game_flow.gd:80](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/game/game_flow.gd:80) | L |
| 3.2.1 | [PROPOSED] | DIFFERS | **Wording conflict:** build applies accelerating upgrade discounts, correctly following 4.6.3; this rule still says a flat drop of one. | [rules.gd:127](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/rules/rules.gd:127) | S, docs |
| 3.3.1 | [BG] | DIFFERS | Listed recruit actions are supported except board-to-hand movement and hero powers. | [recruit.gd:105](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:105) | M + hero system |
| 3.5.1 | [BG] | DIFFERS | Applies damage after each individual fight, rather than after all fights. Eliminations correctly wait. No current cross-fight consequence established. | [game_session.gd:189](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:189), [game_session.gd:255](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:255) | S |
| 4.3.5 | [BRAMBLE] | MISSING | Only triples merge units; no non-triple merge operation implements Bought-origin inheritance. | [recruit.gd:608](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:608) | M |
| 4.3.6 | [PROPOSED] | MISSING | Hand-to-board placement preserves the object and origin. Transformation and non-triple golden conversion, with origin retention, are unimplemented. | [recruit.gd:220](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:220), [recruit_context.gd:249](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit_context.gd:249) | M |
| **4.3.7** | [BRAMBLE] | DIFFERS | **Sells board units only.** Neither engine nor UI accepts hand sales. | [recruit.gd:180](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:180), [recruit_input.gd:303](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/screens/recruit/recruit_input.gd:303) | M |
| 4.4.6 | [PROPOSED] | MISSING | Zero-cost player refreshes correctly avoid the paid counter; there is no effect-driven refresh operation in the mechanic context. | [recruit.gd:388](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:388), [recruit_context.gd:94](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit_context.gd:94) | S |
| 5.2.4 | [BG] | DIFFERS | Lobby tribes are supplied by the player/configuration, defaulting to all; no random rotation subset is chosen. | [game_flow.gd:48](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/game/game_flow.gd:48) | M |
| 5.2.6 | [BG] | MISSING | Filters pool membership by tribe, but has no tribe-pair exclusions, unit bans or hero exclusions. | [card_pool.gd:31](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/units/card_pool.gd:31) | M |
| 5.3.5 | [PROPOSED] | DIFFERS | **Wording conflict:** golden sales return every constituent pool copy, including Created Discover picks. This follows its first sentence and 4.3.2, but contradicts “Created copies return nothing.” | [recruit.gd:615](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:615), [recruit.gd:188](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:188) | S, docs |
| 5.3.6 | [BG] | DIFFERS | **Wording conflict:** Created Discover picks come from and return to the pool, as explicitly required by 4.3.2. Generated copies correctly use no pool copies. | [recruit.gd:436](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:436), [recruit_context.gd:254](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit_context.gd:254) | S, docs |
| 5.3.7 | [PROPOSED] | MISSING | Existing shop consumption and spell casting return pool copies; general recruit-board destruction, consumption and transformation removal are unimplemented. | [recruit_context.gd:289](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit_context.gd:289), [recruit.gd:254](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:254) | M |
| **7.2.3** | [BRAMBLE] | DIFFERS | **Unit effects fire after placement from hand.** Buying only adds the unit and settles triples. | [recruit.gd:173](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:173), [recruit.gd:229](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:229) | M |
| **7.2.4** | [BRAMBLE] | MISSING | No board-to-hand action. Board dragging only moves, swaps or sells. | [recruit.gd:105](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:105), [recruit_input.gd:310](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/screens/recruit/recruit_input.gd:310) | M |
| **7.2.5** | [BRAMBLE] | MISSING | No return operation, full-hand return check or return-state preservation path. Existing hand-to-board play preserves the unit. | [legal_actions.gd:95](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/legal_actions.gd:95), [recruit.gd:220](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:220) | M |
| **7.2.6** | [BRAMBLE] | DIFFERS | Discover picks and generated hand cards gain no recruit trigger; their effects wait for play. | [recruit.gd:439](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:439), [recruit.gd:530](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:530) | M |
| 7.3.4 | [BG] | DIFFERS | Combines permanent and turn modifiers separately, clamps only permanent negatives, and can produce golden stats below golden base. | [recruit.gd:631](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:631) | S |
| 7.3.5 | [BRAMBLE] | DIFFERS | Default parameters double, but authored goldens include ×2→×3 multipliers rather than universal doubling. Their explicit card text invokes 1.2.1; this is a policy choice, not automatically a bug. | [mechanic_params.gd:78](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/mechanics/mechanic_params.gd:78), [thorn/units.json:468](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/thorn/units.json:468) | M |
| **7.3.6** | [BRAMBLE] | DIFFERS | **Normally grants the reward when the golden is played.** Only the full-hand/all-board fallback grants it immediately—and loses it to the full hand. Reward tier is evaluated when cast. | [recruit.gd:231](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:231), [recruit.gd:639](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:639) | M |
| 8.2.6 | [PROPOSED] | DIFFERS | Lieutenant redirects a vacant “across” target to another enemy, potentially in another row. Geometry itself maps corresponding slots correctly. | [lieutenant.gd:34](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/pigeon/mechanics/lieutenant.gd:34) | S |
| 8.3.5 | [PROPOSED] | MISSING | Player movement exists; effect movement and its occupied-slot refusal/swap rules do not. | [recruit.gd:370](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:370), [combat.gd:762](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:762) | M |
| 8.4.2 | [BRAMBLE] | DIFFERS | Immediate summons use nearest-source placement. Waiting summons ignore their saved source and land in reading order. | [fight_arrivals.gd:102](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/fight_arrivals.gd:102) | M |
| 9.3.2 | [BG] | DIFFERS | Resolves both players’ setup effects before either player’s main effects, rather than all effects for one player and then the other. Priority is absent from visible card text. | [combat.gd:233](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:233) | M |
| 9.4.9 | [PROPOSED] | MISSING | No combat movement operation implements preservation or adjustment of attack flags. Placement calculates flags for arrivals only. | [combat.gd:762](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:762) | M |
| 9.5.3 | [PROPOSED] | DIFFERS | If all candidates are hidden, targeting ignores protection for that selection; it does not remove protection. Hidden units can become protected again after a visible arrival. | [combat.gd:346](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:346) | S |
| 9.6.3 | [BG] | DIFFERS | Deaths resolve after the enclosing effect/attack, rather than after every damage event. **Wording conflict:** 9.6.1 itself puts deaths after “after this attacks.” | [combat.gd:547](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:547), [combat.gd:383](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/combat.gd:383) | L |
| 9.8.2 | [BG] | DIFFERS | Ordinary returns are fresh; Root restores recruit-board buffs, counters and granted effects. Its visible reminder does not state that exception. | [fight_deaths.gd:121](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/fight_deaths.gd:121), [root.gd:39](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/thorn/mechanics/root.gd:39) | S |

¹ Incremental estimate once hero infrastructure exists. Related rows overlap; estimates should not be added together.

The other **[PROPOSED] defaults currently used** include round-50 health-plus-armor placement; end-turn expiry before combat; income modifiers and the five-point waiting-discount ceiling; type matching; copy-weighted draws and empty-pool behavior; the full-hand golden fallback; slot-based relations, movement and summons; persistent slot effects; attack flags and row-local forced targeting; ordered deaths and returns; the 200-attack, 10,000-combat-trigger, 1,000-action-trigger and five-return limits; starting-unit loss accounting and simultaneous-elimination placement.

The **15 N/A classifications** are:

- **[OPEN] 2.1.5:** local eight-player bot rounds, elimination ghosts and a round-50 ending.
- **[OPEN] 2.2.3:** no hero offers, rerolls or paid choices.
- **[OPEN] 5.1.4:** shared copy-count pool.
- **[OPEN] 5.2.2:** separate `types` and `tribes` fields determine matching and lobby eligibility.
- **[OPEN] 5.2.5:** five shipped tribes; all or a player-selected subset.
- **[OPEN] 5.2.8:** no additional trait system.
- **[OPEN] 6.1.6:** no separate shop-slot upgrade.
- **[OPEN] 6.1.7:** flat draws proportional to eligible copies remaining.
- **[OPEN] 7.3.8:** one triple-to-golden level.
- **[OPEN] 8.3.2:** no minimum front row; an empty front is legal.
- **[BRAMBLE] 1.2.5, 5.2.1, 8.2.5:** content-level stat scale, type-line and wording constraints.
- **[BG] 9.3.3, 9.3.4:** no hero-power phase to order or snapshot.

Separately, these bugs emerged from the audit. They are source-backed findings; no runtime reproduction was performed.

| Bug | Evidence |
|---|---|
| **Master-at-Arms can be impossible to play onto an empty board through the UI.** The core offers itself as a target, but the targeting UI only recognizes board cards; the held card remains a hand target. | [recruit.gd:294](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:294), [recruit_input.gd:435](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/screens/recruit/recruit_input.gd:435), [recruit_screen.gd:405](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/screens/recruit/recruit_screen.gd:405) |
| **Ghost Reserve units lose prior permanent stats/counters when Root returns them.** The saved ghost hand still exists, but original-unit lookup searches the eliminated player’s cleared hand and falls back to a plain copy. | [game_session.gd:371](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:371), [game_session.gd:401](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/session/game_session.gd:401), [fight_side.gd:64](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/fight_side.gd:64), [fight_deaths.gd:129](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/combat/fight_deaths.gd:129) |
| **Lieutenant’s text omits fallback targeting.** “The enemy across from it” can actually mean a different slot or row. | [pigeon/units.json:262](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/pigeon/units.json:262), [lieutenant.gd:34](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/pigeon/mechanics/lieutenant.gd:34) |
| **Golden debuff handling can give wrong stats.** For example, three base-2 Attack copies each carrying −1 temporary Attack yield a golden with 1 Attack, below its golden base of 4. | [recruit.gd:632](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:632), [stat_block.gd:37](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/units/stat_block.gd:37) |

Questions for the owner:

- Keep the local bot lobby for now, or replace it with asynchronous snapshot opponents under 2.1.4/2.1.5?
- Keep the accepted setup-before-main combat passes, or enforce 9.3.2’s single pass per player?
- Keep waiting summons landing in reading order, or apply 8.4.2’s source-relative placement?
- Keep authored golden exceptions such as ×2→×3 under 1.2.1, or enforce universal doubling under 7.3.5?
- Should Root explicitly preserve recruit-board stats as an exception to 9.8.2?
- Should Lieutenant miss across an empty slot, or should its fallback be stated in its text?
- Should death checkpoints follow each damage event, each complete effect, or 9.6.1’s attack sequence?
- Should 3.2.1’s flat discount wording be corrected to the accelerating discount already decided in 4.6.3?
- Should 5.3.5–5.3.6 explicitly exempt Created pool copies, as required by 4.3.2?
- Is a Triple Reward’s tier fixed when the triple forms, or evaluated when the spell is cast?
- Under C15, may a newly recruited unit target itself while in hand, or only units already on the board?

Files changed: none. Commits: none. Checks: static source and existing-test inspection; runtime tests not run. Denied actions: none.

## Units with play effects (follow-up)

Found **2 units, 0 spells, and 0 “after you play” listeners in `src/content`**. I checked all 99 unit definitions, including tokens, their mechanic bindings and inherited hooks.

The results below assume the recruit trigger is wired into successful acquisition; neither unit currently fires on buy or non-buy gain.

| ID · tribe · tier | On-play effect today | What it needs | On buy, while still in hand | On gain without buying |
|---|---|---|---|---|
| `harvest-piper` · Mouse · **2** | Permanently give your other board Mice **+2 Attack**, or **+4** when golden. | **Board contents only.** No chosen target, own slot or neighbours. | **Works unchanged mechanically.** It buffs the Mice currently on the board; the source is naturally excluded because it is in hand. You lose the ability to delay the effect until after playing more Mice—that is the intended timing change. | **Works the same as on buy.** Discover picks and generated copies can execute the same effect body. Other hand Mice remain unaffected. |
| `master-at-arms` · Badger · **4** | Permanently give a chosen friendly unit **+1 Fury**, or **+2** when golden. Today it can target itself after placement. | **A target.** Current choices are friendly board units plus itself. No own-slot or neighbour dependency. | **Works with a targeting decision.** Existing board targets still work, and giving Fury to itself in hand also works technically. Decide whether that self-target remains legal and whether other hand units become eligible. Calling the effect with no target silently buffs itself. | **Same targeting issue.** Discover/generated acquisition must support a target choice if choice is retained. A simple call with `null` automatically self-buffs; it does not wait for the player. |

Effect implementations: [piper.gd:9](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/mouse/mechanics/piper.gd:9), [arms_master.gd:13](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/content/badger/mechanics/arms_master.gd:13). Current target eligibility is at [recruit.gd:287](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:287); granting Fury does not require the recipient to occupy a slot ([unit.gd:102](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/units/unit.gd:102)).

**There are no listeners to migrate or retain on play.** Neither content text nor implemented hooks contain an “after you play another unit” effect. For such a listener, 7.2.3’s “triggers nothing by itself” supports moving it to **after you recruit**; keeping it on play would require an explicit exception.

One implementation distinction matters for spells: `on_played` also handles **spell casting** ([recruit.gd:252](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/recruit/recruit.gd:252)). The shop spells live outside `src/content`, and Triple Reward is defined in the core. Their cast effects should remain on cast. **7.3.6 moves when the Triple Reward spell is granted, not when its Discover executes** ([triple_reward.gd:6](/home/alex/code/Bramble/.claude/worktrees/night-18-nov-93aa9a/src/core/mechanics/effects/triple_reward.gd:6)).

Counts for the **2 affected units**:

- **1 works unchanged mechanically after retiming:** Harvest Piper.
- **1 needs a rule decision:** Master-at-Arms.
- **2 need text updated:** both currently say “When played.”
- **0 currently require an effect redesign.** Master-at-Arms might need one depending on the targeting decision.

The wording count overlaps the mechanical counts. The decision groups are:

- **Target eligibility — Master-at-Arms:** board units only, board units plus itself in hand, or any friendly unit including other hand cards?
- **Target resolution — Master-at-Arms:** retain player choice for both buys and automatic gains, or explicitly adopt automatic self-buffing; define what happens when no eligible target exists.

Read-only inspection at `d7781d8a`. Files changed: none. Commits: none. Runtime tests: not run. Denied actions: none.
