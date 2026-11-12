# Owner design philosophy — working notes (interview, 2026-11-10)

## 1. Two axes of route
- Altitude: top-down (system/concept → parts) vs bottom-up (specific thing → system).
- Origin: flavor-first (world, lore, representation) vs mechanical-first (maths, logic).
- Examples: Migratory Birds = top-down flavor; resource-exchange effect list = top-down mechanical; beer = bottom-up flavor; leftovers/efficiency puzzle = bottom-up mechanical.
- Routes CAN converge but in practice produce different games:
  - Mechanical bottom-up → tight tension, disjointed flavor unless a later top-down pass.
  - Flavor top-down → evocative, but balance/system problems, over-designed mechanics.
- Birds: nests/eggs/migration forced in, clunky, too complex, not "simple but deep". Evokes birds. Maybe a great mechanic for a different ruleset, wrong fit for the auto-battler's tight bounds.
- Iteration can redeem a poor start; a non-obvious fit can end up more artistic than the obvious one. Owner is letting Birds play out despite intuition — part of the art.
- Switch routes when: it isn't working, or the "topology" has a gap to fill. Otherwise taste + goal.
- Observed: agents mostly do top-down flavor-first.
- Idea: design "modes" — ask agents to design through each route, measure which the owner likes.

## 2. New content in an existing game
- Tribe level tends top-down. Battlegrounds Aberrations (replaced Naga/Spellcraft): theme sacrifice → discard → discard too costly for the genre → many cards that get stronger when discarded.
- Piece level tends bottom-up / role-first: "need a capstone: top tier, big payoff for discards, wanted late on top of a working board" → mechanic → then name and flavor.
- Surgical / middle-out: look at the whole archetype — distribution of economy, enablers, payoffs, stat holders; their frequency; their tier in the progression curve — and place one piece where the gap is. Top-down alone risks wrong distribution (too much economy, too few payoffs).

## 3. Systems vs mechanics vs content
- System = a rule of the game (lose at 0 HP; gold each turn; the shop).
- A system has a concept + particulars. In a mature game the concept rarely changes (else it's a different game); particulars get tuned; content may break the rules.
- Mechanics (or subsystems/attributes — label unsettled) belong to a system: shop price, slot count, tiers.
- Much can be done with mechanics + content alone. The system's job: set the right incentives.

## 4. Entanglement / choosing the level to fix at
- Async with no timer: any infinite breaks the game (auto-clicker for 20 h). A Battlegrounds copy in async fails on pirates.
- Content fix: restrict every card → long text that won't fit, many concepts to learn, less fun.
- System fix (escalating reroll cost): bounds positive feedback, sigmoid not exponential, so content can be generous economy.
- Genre core tension: strong now vs strong in N turns. Economy effects are the best vehicle, so you want many → so a system must bound them.
- Telling content vs mechanic vs system problems apart is intuition; agents will struggle. Persistent, uncertain issues → owner steps in. Want a framework for agents to try options at each level and see how they play out.

## 5. Player types
- MTG Timmy / Johnny / Spike. Some players want to win whatever the strategy; some have strong strategic preferences and will lose rather than play what they dislike.
- Know the game's player profiles; give secondary audiences something without hurting the primary.

## 6. Judgment over rules
- "There are no hard rules when it comes to design." Agents pick the route and level by judgment.
- Obvious route → take it. Highly uncertain decision → try each option and compare.
- Spotting a system or mechanic problem: the same problem keeps coming up regardless of what is being designed (not only on cards).

## 7. Bramble's audience
- Primary player: wants something more skill-rewarding than Battlegrounds.
- Johnny first, Spike second (kept happy through balance), Timmy not the focus.
- Johnny needs interwoven, overlapping synergies and cards used outside their intended purpose.
- Risk: pure top-down archetype building yields tribe-locked cards ("a Quilboar card that only works with Quilboar") with no cross-synergy. You need bridge pieces: "good with this, great with that", linking things that otherwise wouldn't link.

# Contrast: owner vs agent process (from the Ideation 1/2 review)
| Owner | Agents (observed) |
|---|---|
| Chooses the route on purpose; switches when stuck or when the topology has a gap | Default route: top-down, flavor-first (owner's observation). Route never stated as a choice |
| Surgical mode is key for an existing game: role and tier distribution of the archetype | Checks worked on a single card or the whole game; the tribe-as-buying-sequence level was missing (Birds case study) |
| A recurring problem → suspect the system; fix it once at system level so content can stay generous | Patched at content level: ≥19 caps added after something dominated; 7/10 pass-2 cuts were caps |
| No hard rules; judgment; try options when uncertain | Each correction became a new rule or bar → the "too many criteria" risk |
| Johnny: cross-tribe interwoven synergies | Design docs centred on in-tribe "2–3 builds that win" and named combos (interpretation: in-tribe focus) |
| Weak ideas get to iterate; reactions drive iteration, not decisions | Options chosen by adversarial critique, not play; taste docs once said "do not revise", which locked in failing cards |
| Fun over balance; be generous, then dial back | Linear costing → small numbers, flat game; scale gap still open |

# Skill seeds (proposals, not agreed)
1. Route selection: name the altitude × origin (or surgical) route before designing; run several routes when uncertain.
2. Level diagnosis: is it content, mechanic or system? Recurrence across unlike things → system.
3. Archetype role map: economy / enabler / payoff / stat holder by tier; place pieces surgically.
4. Johnny check: what each piece does outside its tribe; bridge pieces.

# Experiment 1: one Quilboar card per route (n=1 each, 2026-11-10)
| File | Route | Owner verdict |
|---|---|---|
| A Reliquary Razorback | surgical | Great archetype enabler; simple yet consequential. Pure payoff, needs many gems. Far too strong at T3 (deathrattle multipliers) → T4–5 |
| B Razorfen Gemcutter | bottom-up mechanical | Cool, new, negative feedback loop, use-then-discard. Maybe underpowered. Wording clunky ("…then increase the amount required by 1") |
| C Bramblewound Seer | top-down flavor | Least interesting; fine role player; a T2 effect, not T4. "You need cards like that" |
| D Truffle Snuffler | bottom-up flavor | Most creative, least ready. "Ripen" unexplained; freezing is an uninteresting play; payoff too weak. Needs iterations |
| E Gemspinner Mystic | top-down mechanical | Best by far, near-ready. Natural limit; early piece or late role player; bridges Tavern-spell and gem builds, enables pivots. ~T4.5 |
Owner caution: tiny sample; don't overread the route → quality link.
Owner judges along separate axes: innovation, readiness, power/tier fit, wording, role (enabler/payoff/role player).

# Decision after experiment 1 (owner, 2026-11-10)
- Owner's own default is top-down mechanical: look at what the thing needs and its distribution of effects, sketch many loose concepts, then work out what each design needs. Role players come naturally this way.
- Make top-down mechanical (E) the default process for agents, and for choosing between options. Watch that it doesn't "overcook".
- Keep an idea library of the wilder designs from the other routes (flavor top-down, flavor bottom-up, etc.). The default process mines it: "can I rework these into role players?"
- If E struggles to produce interesting, varied ideas, tell agents to use another mode.
- A (surgical) may also be good; sample too small. Other routes may do better at tribe scale → experiment 2.
- Owner's aside: different card counts and tier distributions per tribe make no sense to a top-down mechanical designer.

# Experiment 2: one 24-minion Ogre tribe per route (n=1 each)
| Blind | Route | Core | Owner verdict (holistic) | Tokens / time |
|---|---|---|---|---|
| 1 | top-down flavor | Chieftain, Tribute, Usurp, Two-Headed | Most creative, eclectic; wild balance swings (T2 Glutton, Butcher); not cohesive. Best as an idea generator from a blank slate | 86.6k / 6m35s |
| 2 | bottom-up flavor | Chieftain, Usurp, Bicker, Grog | More cohesive than 1; mechanics synergise (Bicker ↔ Usurp), depth while simpler; balance unpolished (Phemos & Pol T4 → T6–7) | 98.8k / 9m00s |
| 3 | surgical | Tribute = sell the adjacent minion; empty spaces | Best unit-to-tier power; most ready to playtest; less creative; empty-spaces subtheme weak | 85.9k / 6m35s |
| 4 | top-down mechanical | Chieftain, Tribute, Usurp, Crowned | Same concept as 1 and 2 but better balance (Kromcrush at T5), closer to ready; less interesting, weak payoffs. Owner: polish 1 and 2's ideas inside 4's balance frame | 83.5k / 6m04s |
| 5 | bottom-up mechanical | Devour (eat a smaller friendly minion) | Owner's favourite: different feel for BG, ambitious, near-tunable, second closest to ready; some rules errors (Avenge + Taunt) | 96.8k / 20m09s |
Observations:
- 3 of 5 converged on the crown, driven by the brief's lore ("might makes right", challenges for the crown). The two that escaped (3 and 5) started from the game, not the race.
- Confound: T's brief (like B's in exp 1) carried the owner's leftover/efficiency example; Devour is that tension (sell for 1 Gold vs eat).
- Every crown design capped Usurp to once per turn or combat: a keyword-level bound against crown ping-pong loops.
- Common gaps: power-to-tier calibration, rules knowledge (Avenge only in combat; damage doesn't heal).
