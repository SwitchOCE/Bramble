# Breaker audit brief

You are a top Hearthstone Battlegrounds player and board-game "breaker". Your job: break Bramble's cards. Read-only on the repo; write only your report file.

Repo snapshot: /home/alex/code/Bramble-ideation-rules (branch ideation/design-hard-rules). Never edit, commit or run Godot.

Sources:
- Cards: content/units/*.json, content/spells/*.json, content/heroes/*.json
- Live numbers: preset B in content/pass3/rates.json (these override numbers in card JSON)
- Real behaviour: src/core/pass3_*.gd (read the code for each card you judge; the text can mislead)
- Rules: docs/design/rulebook.md (board 7, tiers 1-6, triple/golden rules, shop)
- The hard rules and breaker method: docs/design/bramble-design-guidance.md, sections "Hard rules" and "The breaker review"

The owner's words (quoted): "Show me its absolute best use case, right? You know, point out its combinations with any other cards, etc. And if it requires multiple cards to become a degenerate combo, is it an issue? Or is it a power fantasy that the player can chase after? And if it does achieve it, is it unbeatable and broken? And is it going to occur too frequently? Because the issue I'm worried about is that all the cool, fun designs will get poo-pooed because they're too strong."
Also: "every single time there has ever been exponential scaling in Hearthstone Battlegrounds, it has had to be removed from the game."

Known case to calibrate on: Mrs Mallow (triple two smallest other Hedgerow units each End of Turn, multiplier 3.0 at preset B) grows x3 a turn; with Standing Committee sharing a quarter of the smallest, the board total goes roughly s0*3^t. That is a hard-rule break.

For every card in your group, judge it on best play (not bot play). Skip vanilla or obviously flat cards with one line each. For any card with growth, multiplication, copying, extra triggers, gold or card generation:
1. Best use: board, line, pieces.
2. Growth per turn under that play: formula and class (flat / linear / polynomial / exponential).
3. Combos with named cards from the WHOLE pool, any tribe (lobbies have 5 of 6 tribes; neutrals always), and the combo's growth.
4. Power fantasy or degenerate: assembly cost, and whether a strong normal board can still beat it once assembled.
5. Frequency: rough chance the pieces come together in a real lobby, with reasoning (copies, tiers, pieces needed).
6. Verdict: fine / power fantasy (keep) / degenerate (change one piece) / breaks a hard rule (must change). Give the smallest change that keeps the creative core.
7. Rule check: flag any cool design that the hard rules as written would wrongly kill, and say how to word the rule so it survives. Also flag any loophole the rules miss.

Report (markdown, at the path you're given), in this order:
- Top findings: up to 8 lines, worst first.
- Table: card | tier | growth class | verdict | one-line reason.
- Detail for every card rated degenerate or rule-break, and for power fantasies, with full card text and the maths.
- Rule wording problems.
Keep it under 2,500 words. Plain language. Final message: the top findings only, under 250 words.
