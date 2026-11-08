# Review: ideation/feedback5 (round-five clarity)

Fresh cloud reviewer. Target `origin/ideation/feedback5` at `8c20e3c` against its merge-base with `ideation/main` (43 files). Scope: the owner's "Clear and concise wording... If it's implied, let it be implied" and plan step 5: clarity only.

**Counts: 14 items. Fine 8, ask 5, cut 1. Moves the problem: yes.**

- **Cut:** the Pass reminder rewrite drops "or keeps it", which the engine still does, and "recruiting waits until End of Turn" reads as if the recruit phase waits.
- **Ask:** Changeling golden "it gains +4/+4" is ambiguous; Mousewife now toasts on every failed summon; Frumenty's borrowed text comes from splitting card sentences; the sale preview copies Rainbow's payout math; Brother Wolf's text re-explains Pack.

## What I ran

- Full GUT suite on the branch (Godot 4.7.2 headless): **1,418/1,418 passing, 19,737 asserts, strict hook ok**. Matches the worker's claim. Not run: lint/format, soak.
- Probe: I removed the Rainbow term from `_sale_payout`. `test_feedback5_sales.gd` failed in all 8 cases, so that test has teeth.
- Read every `content/` and `src/core/` hunk.

## (2) Did any effect, number or rule change? No, as far as I found.

- `content/units/*.json`: only `text`, `golden_text` and `details` changed (Queen's `details` is new). `mechanics` and stats are identical. `effects.json`: only the Pass reminder string changed.
- Core: every new `emit_event` goes through `_emit`, which returns when `log_events` is false and only appends to `events`. The aura provenance bookkeeping (`combat_auras.gd`) runs only when logging. The `bonus` sum is unchanged. `wobbly.gd` splits the old `or` into two early returns; behaviour is the same. `recruit_rules`/`recruit_context` add `log_event` calls; Spill still fires on the same branch. `no_target` and `cause` are display-only.
- The worker's logged-vs-quiet drift test (random streams, rewards, trigger counts) exists and passes.

## (3) Card text, before and after, checked against the engine

| Card | Before | After | Verdict |
|---|---|---|---|
| Queen of Elfland | "Your other Fairies split their stats." | "Other Fairies share the destroyed units' stats." | **Fine.** `teind.gd` pools base + permanent stats of the destroyed units and splits them among other Fairies. The new Details ("counts End of Turns since this was played and resets after 3... spare points go in board order") matches `on_end_of_turn` and `_split`. |
| Brother Wolf | "Pack, with each unit beside this. It lets them attack first." | "Pack: this joins attacks by units beside it, once each a cycle. Those units lead the attacks." | **Fine, with an ask.** It matches `combat_hunt.gd`: `repeat` joins once per leader per cycle, and `can_lead` makes Wolf wait while a neighbour can attack. The Details matches `can_lead`. Ask: the first clause restates the Pack reminder, against guide rule 3; "Pack. Units beside this attack first; this joins each once a cycle." is shorter. |
| Changeling | "trade places with the enemy across. It fights for you until it attacks." | "swap sides with the enemy across. Swap back after that enemy attacks once." | **Fine:** it says who returns and when. **Ask** for golden: "...across; it gains +4/+4." `borrow_across` gives the bonus to the borrowed enemy, but "it" can read as the Changeling. Write "that enemy gains +4/+4". |
| Young Brock | "units beside this get +1 Attack and the enemy across from this as quarry." | "units beside this gain +1 Attack. They mark the enemy across from this as quarry." | **Fine.** The old line read as giving out the enemy. Details still has the exception for a unit that already has a quarry. |
| Pass (reminder) | "Gives the bonus to the last touching unit to its right, or keeps it. While recruiting, at End of Turn." | "Gives the bonus to the last touching unit rightward; recruiting waits until End of Turn." | **Cut.** `BoardGeometry.pass_landing` returns the source's own slot when nothing touches it on the right, so a rightmost Mr Crumb keeps the bonus. The new text implies nothing happens. Not a marginal case. "recruiting waits" makes the recruit phase the subject. A fix within 16 words: "The last touching unit to the right gains it, or this does. Recruiting: at End of Turn." |

## (1) Other changes: do they move the round-5 complaints?

- **Stat causes** (`-3 Attack (Bitter)`, "Cluricaun (F1)'s aura lost"): **fine.**
- **No-room and no-target notices** (Wobbly, Posset, empty Rings, birds, Belly "lost for this fight" vs "stays inside", recruit "No room for Mouse."): **fine.**
- **Mousewife dedupe removed:** **ask.** The toast now fires on every failed attempt, so a full board can stack identical toasts. Option: the log keeps every line, the toast once per fight.
- **Ring braces → `[Slot: Ring +1/+1]`:** **fine.**
- **Same-name units** (F1/F3) and **Pack log** ("Z joins the attack"): **fine.**
- **Rainbow Chaser sell tag:** **fine** as a fix. **Ask:** `game_session._sale_payout` copies Rainbow's payout formula instead of asking the sale rule. Tested, but it can drift; prefer one shared rule function.
- **Frumenty borrowed rules:** **fine** for clarity. **Ask:** `RecruitUnit._borrowed_rules` builds the display by splitting card text on ". " and dropping sentences that start with "when played" etc. Rewording breaks it quietly; derive it from the mechanics `_can_lend` filters.
- **Vocabulary** (Mire/Mired, Wasp, Start of Combat) and the **enemy keywords in the play-tool glossary:** **fine.**

## (4) Out of scope

Nothing found. No rules, balance or new content.
