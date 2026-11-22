# Wording the mechanics: pilot plan (22 Nov 2026, draft for the owner)

## The owner's words (22 Nov, dictated)

> "What we can do now is we could potentially start a phase of work on tooltip cleanup and wording. I think we really need to look at how Magic of the Gathering and Hearthstone word their mechanics kind of thing. And think about every mechanic and how we could phrase it in a few different ways. And like, what's going to be simplest to somebody? That's probably, I would say the most the most important to me"

> "Yeah, I think we also want to just capture the process that produces good names and a kind of instruction set for it. So I'm more worried about it being repeatable in future because we're going to be designing lots of mechanics and doing lots of wording. We just want to think about things in terms of most intuitive and simple way of wording something Can you start that process of the exploration under an orchestrator on the Optiplex and see how we go"

Two products: better wording for the mechanics, and, more important to the owner, a written process that gives the same quality again.

## Pilot: six mechanics of different kinds

| Mechanic | Kind | Live keyword text today |
|---|---|---|
| Divine Shield | plain borrowed keyword | "The first damage this takes is prevented." |
| Fury N (Badger) | tribe keyword with a number that scales off another term | "Whenever this attacks or is attacked, gain +N Attack, and +N more for each unit you're outnumbered by." |
| Pile on N (Mouse) | depends on position (neighbours) | "The first N times a neighbour attacks each fight, this hits the target first." |
| Renown (Pigeon) | carries across turns, sits on a slot not a unit | no keyword text at all |
| Root N (Briar) | has a cost | "The first time this dies each fight, spend N Compost to return it." |
| Charge N | the name may be the problem: in both reference games "Charge" means "can attack at once" | "Works this many times, then stops. Refills each fight." |

Charge is the owner's own pick (rulebook 11.7.3); a rename goes on the page as a proposal, separate from wording.

## Steps

1. **Facts.** For each of the six: the live keyword text, how cards print it, the rulebook rule, and what the code does. A disagreement goes to the owner only when it changes the wording; wording doesn't settle a rule.
2. **References.** The closest Magic and Hearthstone mechanic for each, quoted with source, plus how they handle trigger words, "this unit", numbers, reminder text, and where they changed a wording and why.
3. **Instruction set v0.** A first draft of the process, from the references, before any wording is written, so the pilot tests it.
4. **Wordings, by following v0.** Three per mechanic, each with a short form (a few words, for a possible cue line under the card) and the hover line, covering the existing `reminder` / `reminder_general` pair where there is one. Rename candidates listed apart. A length check against the hover box.
5. **Reader test.** Fresh readers that have never seen the game get only what a player would see (card text plus hover line) and a concrete board, and say what happens. Readers from three providers (Opus, GPT Sol, Gemini Neon). Reported as "misread by N of M readers". Agents aren't new players; the owner's read is the real test.
6. **The page.** One house-style artifact: per mechanic, the recommended wording first, then the options, the references and the test result. The owner picks. Nothing changes in the game before that.
7. **Instruction set v1.** Revised from what the pilot showed, each instruction tied to a pilot case; drop any that can't point to one. Into the `ux-copy` skill (add, don't rewrite) by a PR into `dev` that waits for the owner.
8. **The rest of the mechanics.** A fresh worker given only v1 words the remaining keywords (about 40). The owner checks a sample against the pilot: the test of whether the process repeats.
9. **Into the game.** The picked text goes into `display.json` by a PR into `dev` that waits for the owner.

Checkpoints with the owner: after 6, after 8, before 9.

## Not in the pilot

No change to `src/` before step 9. The cue line under the card waits for the owner's UI pick; its short forms are written, not built. Card text (as opposed to keyword text) is a second pass. Nothing to `main`.
