# Owner direction: invent new effects; designers don't see the budget

Said by the owner in chat on 2 November 2026, answering Claude's questions on the rulebook rewrite.

## Answers on the rulebook rewrite

- **The revised plan** (Battlegrounds is the default for systems only; chapter 11 becomes examples; keyword sentences rewritten with rule numbers kept; a short slot-effects section; deltas and the review doc updated): "Approve the revised plan."
- **The 27 October Taunt ruling:** "Mark it a proposal." It applies only if Bramble designs a must-be-attacked mechanic.
- **Worked two-row versions of example mechanics:** "Keep the worked versions."

## New effects

On whether to relabel Battlegrounds keywords in the other docs as examples:

Do something even more thorough than that. I want explicit attempts to create different effects than just what exists in Hearthstone Battlegrounds. I know there is stuff out there that can be done. You could have something that takes 50% less damage when it's attacking (either it rounds up or down, I don't know), or 50% less damage when it's defending. You could have all sorts of effects:

- Something that skips its attack, and every time it skips its attack in combat, it gains additional stats or something. Things that don't attack, but get rewarded every time they skip.
- Something that gets rewarded every time something else is attacked instead of itself, when it's a legal target, or maybe when it's not a legal target, I don't know. Maybe just whenever anything else is attacked.
- Something that deals damage back to the attacker whenever it's dealt damage. Maybe the hedgehogs do that: the thorn effect.

We can come up with new types of effects. Think about all the game triggers that might be interesting, and that we could assign some sort of flavour to that would match a woodland creature or something of the sort. We can try to create balanced, interesting keywords that we could potentially use. We don't have to copy all of Battlegrounds' stuff, and it doesn't need to follow the system's rules. The good mechanics break the system rules. They change them. The example of Battlegrounds is that you can see the system rules being broken by the mechanics, and that's why our code needs to be flexible and separated into layers.

## Budgets and taxonomy are guidelines

I guess the output of this is that we can't power budget everything exhaustively yet, and we can't see our taxonomy as exhaustive yet either. These are just guidelines for content generation, and they will be added to. Any agent that wants to add an effect, or thinks an effect could be good that isn't in the taxonomy or power budget, can add it. They do not need to adhere to the power budgets perfectly. The power budgets are just guidelines to help design.

Maybe design agents should be given cards to design without any concept of power budgets. They're not even informed; they're goldfish. They don't know that power budgets even exist. Then review agents can look at them against the power budgets, and if they're significantly outside them, flag it, and maybe propose some changes that keep the core of the creative card.

*[Editor notes:*
- *"Goldfish" is read as: design agents are briefed without the power budget or price tables, so their ideas aren't shaped by them; a separate review step costs the designs.*
- *Saving this as a working rule for agents needs the owner's OK on exact wording (owner, 2 Nov: rules are proposed first and saved only in the wording the owner agrees).]*

## Answers on the wording

- **Sample rule rewrites** (the intro line, 9.5.2, 9.5.4, 9.7.2, and new slot effects 8.5.1–8.5.3): "Yes, do the rest this way."
- **The working rule for budgets:** "Yes, add it." It is in CLAUDE.md under Working rules, in the wording Claude proposed: "Budgets and taxonomy are guidelines. The power budget and the effect taxonomy are not exhaustive, and any agent may add an effect that isn't in them. Agents that design cards or mechanics are briefed without the power budget. A separate review agent then costs the designs, flags any that are well outside the budget, and proposes changes that keep the card's creative core. Purpose: costing too early narrows designs to what Battlegrounds already does."
