# Plan: the second ideation track

<!-- status -->
- **In short:** A playable Godot build with five tribes in the glass look. Agents design the tribes and cards; you pick each tribe's mechanic.
- **Status:** active
- **Last step done:** You approved this plan (16 Nov 2026).
- **Next step:** The session on the Optiplex (started 16 Nov 2026) gets agents seeing the running game, starts the rules core, and writes the page of mechanic options.
- **Waiting on you:** Nothing yet. Next: picking a mechanic for each tribe, once the options page is ready.
<!-- /status -->

Status: approved by the owner, 16 Nov 2026: "I approve the plan. I think that plan's good."

This is an ideation track. It lives on `ideation/*` branches, and nothing from it enters `main` without the owner's say-so (`CLAUDE.md`, "Main and its archive"). Choices agents make in it are not decided for the real game.

## What the owner asked for (16 Nov 2026)

"I basically wanted to get a build with the new glass art in. I wanted to have 5 tribes. I want agents to run with the design of the tribes and the cards for those tribes, but I want to pick their mechanics, and I want to have a playable build with it built in Godot."

Earlier the same day: "I'd like to resume ideation builds at some point. ... now they've got more rigor in place, I want to see what we can do."

On the first run: "ideation served its purpose. It showed me that I couldn't be that hands-off with agents and get what I wanted."

## Done means

The owner plays a whole game against bots, on their own PC, with five tribes whose mechanics they picked, shown in the glass frames and recipe art.

## The owner's decisions for this track (16 Nov 2026)

- **Engine: Godot.** "I think we stick with the Godot as well. ... HTML should be used for mockups, and we can then hopefully just copy HTML layouts and get them pixel accurate."
- **No hero powers.** "I think no hero powers. I think that's a good idea."
- **No growth checks on designs.** "I agree with removing those."
- **Hand limit 7,** now rulebook 7.1.1.
- **It runs on the Optiplex.** "I want to do this on the SSH, on the Optiplex. Optiplex is for long, unsupervised runs because it can run overnight." The owner still plays each build on their own PC.
- **The five tribes** are the ones the owner rated "First pass" on the species seeds page, https://claude.ai/artifact/L7QD6ka8LzD22mnGsgA4SY (read from the page's saved ratings on 16 Nov 2026):

| Tribe | Seed name | The owner's words on the page |
|---|---|---|
| Badger | The Iron Setts | "They can be our tall faction, right? Where you have these big payoff units ... this should be our tall tribe. That's settled" |
| Mouse | The Thimble Guard | "It's got to be this en-masse kind of summoning tribe ... A volume tribe: multiple bodies, but fewer stats." |
| Wood pigeon | The Regiment | "The pigeons is one of our medium tribes for sure. ... World War I and earlier British Army" |
| Locusts | The Locust Tide | "I think that could be a really good summoning tribe, maybe." |
| Briars and thorns | The Hedge Wardens | No note yet. |

## Steps

Steps 1, 2 and 4 start at once. Each step ends at something the owner looks at or plays.

1. **Give agents eyes and hands in Godot, on the Optiplex.** Godot 4.7.2, `xvfb-run` and `xdotool` are installed there, and the first run's `tools/look/` (tag `archive/branches/ideation/main`) let an agent run the game, take screenshots, click and read errors on that machine. Reuse it, or try `godot-mcp-runtime` (https://github.com/Erodenn/godot-mcp-runtime; found by the 16 Nov web search, MIT licence, read its code before installing it). Give Godot the mock-up's own pieces: the six frame files, the card data and the layout numbers.
2. **Mechanics.** One page for the owner: for each of the five tribes, three mechanic options, each with an example unit, made with the `bramble-design` skill and starting from the owner's notes above. The owner picks.
3. **Cards.** Agents design each tribe's 19 units (2/3/4/4/3/3 by tier, the owner's shape from the tribe run) around the picked mechanic, costed against the [tier guide](../design/tier-guide.md). Designs reach the owner as one page per tribe with no review round. Card art is made by the [card art recipe](../design/art-direction/card-art-recipe.md) as designs land.
4. **Rules core, in Godot.** A fresh, headless core that follows the [rulebook](../design/rulebook.md), with no hero powers, plus tests and simple bots. It starts from the generic parts of the first run's engine (session, pool, recruit loop, board, combat, fight log; tag `archive/branches/ideation/main`) and takes none of its tribe code.
5. **Screens, copied from the HTML mock-ups.** The recruit and fight screens are rebuilt in Godot to match the chosen mock-ups on the `design/glass-mockups` branch, and each is compared with its mock-up by screenshot. A screen with no mock-up gets an HTML mock-up first.
6. **First playable, then the rest.** As soon as one tribe has cards and art, the owner gets a build to play. The other four land one at a time, each as a new build.

## Calls made by the planning session, not the owner

The owner saw these with the plan and can change any of them.

- **Spells:** in, a small set, because the rulebook's shop has two spell slots and the mock-up shows them. No spell frame exists yet; a stand-in is used.
- **Screenshot comparison stays.** It tests the build against the mock-up, which is what "pixel accurate" needs. It is not a review of designs.
- **Out of the first build:** phone layout, sound, tutorial, balance sims beyond a soak that proves the rules never break.
- **Who runs it:** a fresh orchestrator session, with Opus workers and Codex for art. The assurance session stays outside, on the owner's PC, and checks at each step.

## Not known yet

- Whether `godot-mcp-runtime` works as its README says. It has not been tried here.
- The fight screen's animation is not designed: the mock-up's lunge and damage splashes are stand-ins.
- Mice and locusts both lean towards summoning in the owner's notes. The mechanic options should make them play differently; the owner picks.
- The mock-ups on `design/glass-mockups` still show a hand of 10.
- How long steps 3 to 6 take. The first run reached a playable rules core overnight and a full build in about a week, with far less supervision.

## How this plan was made

A fresh agent checked the first draft against the owner's words (16 Nov 2026). It found that a two-way engine test was the planning session's own addition, and that tribe choice, hand limit, hero powers and two added checks were the owner's calls. The owner then answered each one; this plan follows those answers. It has not had a second independent check.

On the engine question: the first run's Godot rules engine was its strongest part (2,180 core tests), and its Godot screens were what the owner disliked. The look the owner approved was built as web pages. A web search on 16 Nov found tools that let an agent see and click a running Godot game. Models know Godot's language less well than web code. The search found no measured comparison of web against Godot for agent-built work.
