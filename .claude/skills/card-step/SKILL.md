---
name: card-step
description: Run Bramble's card step - measure card power on a played match, follow up every card the report marks, and get each mark explained or in front of the owner the same day. Use when told to run the card step or the card report, after a bot version is kept, after any card or keyword changes in dev, when the owner names a card as too strong or too weak, or when the ledger of marks has rows nobody has acted on. Also says who makes a card change once the owner picks, and whom to tell first.
---

# The card step

The owner, 26 Nov 2026: "if we don't have agents being able to catch stuff and change it, then we haven't yet succeeded." This skill is the brief for the agent that acts. The measures and their limits are in `docs/workstreams/card-power/definitions.md`; the process is in `docs/workstreams/balance/plan.md` ("The card step", "Who acts on a mark"). Read both. This page holds no numbers of its own.

## What you own

**Whoever runs the card report owns every mark it makes that the ledger does not hold,** until each one is explained in a line or in front of the owner. There is no hand-over. You are not done, and you do not end or hand over, while a mark has no row in the ledger.

The ledger is `docs/workstreams/balance/marks.csv`: one row per marked card or keyword. `python3 tools/league/analysis/marks.py <report folder>` lists the marks it does not hold. **The ledger that counts is the one on `dev`:** add or change rows on a branch and merge them by pull request the same day (a row records what happened; it is not a process change). The morning check reads `dev`.

## The steps

1. **The card report.** `tools/league/card_report.sh <match dir> --field <the field it was played on>`, on a match with records, before its records are deleted. It ends by listing marks that are not in the ledger. No match to hand, or the rules have changed since the last one: `docs/workstreams/bot-league/bot-versions.md`, "Playing a card-step match from nothing", has the commands.
2. **A ledger row for each new mark,** state `new`, holder you, and `source` saying which match marked it and where its tables are. A card already in the ledger that is marked again by the same measure stays as it is. A card whose row says `changed` and that is marked on the new build goes back to the owner.
3. **Left out of the shop** for each new mark, the same day: `tools/league/analysis/card_without_run.py <the match> <out folder> --field <field> --seeds <the match's seeds file> <card ids>` plays one match per card, then `card_without.py <the match> <out folder>/*/ --control <a second run of the match with nothing left out>` gives places worse without each card. The control run shows how far the bots' own noise moves the number; read every card against it. Skip this step for a card no bot buys: leaving that out measures nothing, and its route is the edge cases in `definitions.md`. If the row's `source` names tables that already hold the card's left-out number, use it.
4. **Read each mark** with the card's text in front of you, and choose one:
   - **Explained.** One line in the row's note saying why the card is fine or why the mark is the bot's habit and not the card. State `explained`.
   - **To the owner.** Anything over the line on left out of the shop, anything you cannot explain, and anything the owner named. State `with the owner`, with today's date.
5. **Tell the owner the same day,** in your thread with them: one page, built as the `bramble-design` skill says ("Balancing existing cards": the card as in game, a defence of the card, the four kinds of change weighed, a recommendation), with the numbers that marked it. At most three decisions on a page. Put the page's link in the row's `page`. If you have no thread with the owner, hand the page to the session that started you and say so in the row.

A mark means look, not change. The measures are hints from imperfect bots; say what each number cannot see.

## Ledger states

`new` → `explained` (closed), or `with the owner` → `change picked` (quote the owner) → `changed` (the pull request) → `measured again` (closed, or back to `with the owner` if the card is still marked).

A scheduled check each morning tells the owner about any row that has sat: `new` for a day, or `with the owner`, `change picked` or `changed` for three (`marks.py --stale`).

## When the owner picks a change

The session that sent the page makes the change, or starts the session that does, and gives it the ledger rows and the owner's words.

1. **Before merging, tell two sessions**, because a card change moves the rules hash and every recorded field stops matching: the T3 thread "Ghost Build Orchestrator" (the Rust engine's copy of the card, its proof, refilling the fields) and the T3 thread "Merge coordinator: UI and fight animation" (those builds carry a field inside them). Send each a message in its thread. If you cannot message threads, or one does not answer, tell the owner before you merge. The quality gate stops a rules change until `./scripts/rules_hash.sh --update` is run on purpose, and says this too.
2. Design and build the change as the `bramble-design` skill says. Designs go to the owner first.
3. **After it merges, measure again:** play a match on the new build (bot-versions.md, "Playing a card-step match from nothing") and run this card step on it. Close the row as `measured again`, or send it back to the owner if the card is still marked.

Never change a card whose row says the owner starts the batch until the owner says so.
