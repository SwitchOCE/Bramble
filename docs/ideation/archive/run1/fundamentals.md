# Fundamentals: what the audit found, and the assumptions behind our work (9 Nov 2026)

Written by the orchestrator after the owner's step-back request (owner notes 2026-11-09a–d). The evidence is a fundamentals audit: eight independent readers and two critics, in `evidence/fundamentals-audit/` (`audit-all.json` holds every map and both critiques). The numbers come from 400 bot lobbies on the pass 2 build, a plain combat model checked against our rules, the card files, and Battlegrounds data from Firestone's public per-turn board averages (288,790 games in the current patch, archived snapshots back to September 2025) plus 129 parsed replays.

## 1. What we found

**The game is flat by construction.** Board stats grow in a straight line, about +13 a round. Battlegrounds is level with us until turn 7. From turn 8 it grows about ×1.9 a turn.

| Turn | 4 | 6 | 8 | 10 | 12 | 14 |
|---|---|---|---|---|---|---|
| Battlegrounds median board, Nov 2026 | 24 | 62 | 149 | 714 | 2,598 | 7,980 |
| Bramble bots' median board | 30 | 52 | 80 | 107 | 133 | 155 |

In September 2025, a tamer era, Battlegrounds' turn-12 mean was 759 stats (about 54/54 a unit).

1. **Battlegrounds' curve comes from text, not income.** Our income already matches Battlegrounds: 3 to 10 gold, 3-gold units, 1-gold refresh. What differs is what gold buys. Battlegrounds turns a gold into about 2.8 stats at turn 8 and 71 at turn 14. We stay at 1.4, falling to 1.05. About 25% of Battlegrounds' pool says "this game", "improve" or "extra". In our pool, one card does.
2. **Our method made the game flat.**
   - The costing method prices growth to break even with a plain unit by turn 12, and caps it at 0.8–3.8 stat points a turn per card.
   - The method has no test for "too small". Seven of the ten pass 2 costing cuts were for growth over those caps.
   - 22% of our units now carry a cap or limiter. By our own taxonomy, Battlegrounds is at about 5%.
   - From 7 to 9 November, at least 19 decisions added a cap, a limiter or a dearer climb after something dominated.
3. **New tiers don't feel like progress.**
   - A tier 4–6 body arrives at 0.60–0.74 of the median unit already on the board.
   - Board growth as a share of the board falls from 40% a turn at round 5 to 7% at round 16. Battlegrounds grows 55–95% a turn from turn 8. Our late game gives the smallest rewards when the stakes are highest.
   - Ten Battlegrounds tier 4–6 payoffs give a median of about 32 stats a turn. Ten of ours give about 3.
4. **There is no tail.**
   - **Battlegrounds:** from turn 8, 13–23% of ordinary boards are at least twice the median. The top tenth of its best 0.4% of games reach 7–18 times.
   - **Bramble:** in 400 lobbies no board ever reached twice the median. The biggest board in a lobby is 1.2 times the median at every round.
5. **Absolute size matters less than growth, spread and breakpoints.**
   - **Ratios decide.** Our fights are counts of exchanges. Each side attacks once a turn, overkill is wasted, and a unit lasts ceil(Health ÷ enemy Attack) hits. Multiplying every stat by k changes almost nothing.
   - **Breakpoints decide too.** Crossing the enemy's Attack and Health thresholds is what wins. The same total wins 0% to 100% depending on how it is split. At our small numbers, one point sits on a breakpoint for a third of unit pairs, which is why fixed boards swing 22–68 points on +1/+1. Scaling stats ×4 cuts that swing from about 30 points to 9.
   - **What bigger numbers do buy:** finer steps, and flat effects that bite less.
6. **Concentration: the owner is right, with one correction under our rules.**
   - Three 10/11s beat five 10/10s every time: 5,600 fights over every layout gave one outcome.
   - At equal totals, fewer and evenly bigger bodies always win.
   - One carry among small units does not. It wins 0–15% against an even board of the same total. A carry holding 30% or more of the board loses 9–20 points, because overkill is wasted and every body soaks a whole exchange.
   - Units that hold their stats make concentration strong: in the model, taking 2 less damage adds 24.5 points, a shield 13 and cleave 11. Our pool has almost none of these keywords.
7. **Most payoffs are invisible and temporary.**
   - Payoffs that last one fight only: 9 of 13 in Bog, 10 of 13 in Hunters, 6 of 11 in Birds, 4 of 13 in Hedgerow.
   - They don't show in the shop and they reset, so the player can neither see nor plan that power.
   - Only Hedgerow lets a player pick a carry, protect it and grow it from gold (Acorns, Pass, Dozey).
8. **Hedgerow's lead is mostly one card.** Squire Lollop, a tier 6 full-board aura, was on 70 of Hedgerow's 71 wins. 422 of the 568 final boards holding him belonged to other tribes. Dozey's round 9 win is a Health breakpoint: six plain 5/6s win as often.
9. **The bots can't measure any of this.**
   - **Valuation:** they value card text at 1.5 × tier.
   - **Climbing:** every seat climbs on one hand-set curve. In tiers 2–4, bots could afford the next climb in 99–100% of the rounds where they didn't take it.
   - **Saving:** they almost never save (5+ gold left in under 10% of turns).
   - **Answers:** they never buy answers. Changeling and Ichneumon Wasp were on 0 of 3,200 final boards.
   - **Fairies:** picked by 0.9% of seats, yet they won 31% of the games where a seat took them.
10. **Feedback loops have almost nothing to run on.** Gold is flat: everyone spends about 10 a round, nothing raises income, and the median most anyone banks in a game is 3. Late damage is mostly the round base, so a blowout costs the loser little more than a narrow win, and a runaway can't end games faster.
11. **Combat is nearly deterministic.** 59 of 66 plain test pairs fall outside 10–90%. A board 1.5 times the median wins 94%. If we add compounding without adding variance, a one-round lead decides every later fight. That is the common snowball the owner doesn't want.
12. **Ghosts are near-byes.** They lose 93.5% of fights. They are scouted exactly and never change. 817 ghost fights come with three players left.
13. **There is no recruit timer.** The target game is async (rulebook 2.1.4, 3.1.2). Any patient player can run a many-action line that bots never attempt, so the human skill tail may be fatter than Battlegrounds'.

## 2. My assumptions, stated, and what the audit says about each

### Balance
| I assumed | The audit says | Now |
|---|---|---|
| Stats add up: a board's strength is its total, and so is a card's cost. | Wrong under our rules. Breakpoints and distribution decide fights. | Score boards by win rate against a sampled field of boards, never by stat sums. |
| A card that dominates is too strong: cap it. | Wrong. Every cap flattened the curve and removed the tail the owner wants. | Caps only as loop guards. Where sims show a common snowball, add a rate limit or an answer, not a size cap. |
| Growth should break even with a plain unit by turn 12. | Wrong. It makes investing pointless by construction. | An engine should be behind at once, level after 2–3 turns, and clearly ahead after that. |
| Tier power is about printed bodies. | Incomplete. Battlegrounds' bodies and buffs are small too; its scale comes from second-order text. | Payoff growth and compounding text, not just bigger bodies. |
| Tribe parity in bot lobbies is the balance bar. | Wrong. It measures the bot. | Constructed-field sims decide. Lobbies are a sanity check (owner, 9d). |
| Fixed round 9 boards measure card strength. | Mostly breakpoints. One author, one round, equal spend, no tier 6. | Boards built from seeded shops by scripted strong lines, plus a search for the best reachable board, at rounds 6, 9, 12 and 15. |

### Design
| I assumed | The audit says | Now |
|---|---|---|
| Designers briefed without the budget stay creative. | They also had no target curve, so everything was designed small. | Briefs carry the target curve shape and the condition/payoff/enabler frame, but no price table. |
| Combat-only payoffs are a fair main reward. | They are invisible in the shop and never build up. | Every tribe's main payoffs are permanent and visible. The shop shows combat-start stats. |
| Answers aimed at "the enemy across" are real answers. | They land by layout luck, and the carry's owner places after scouting. Bots never bought them, so nobody has met one. | Add answers that target the biggest enemy or ignore rows, and test them in a carry-against-answer sim. |
| A full-board aura belongs to its tribe. | Lollop is a neutral in practice. | Tribe-only payoffs carry the tribe word, so others can't splash them. |

### Delegation and process
| I assumed | The audit says | Now |
|---|---|---|
| One fresh reviewer per step keeps the game on course. | Every check was relative: card against plain unit, tribe against tribe, bot against bot. Nothing compared the game with a reference game or a feel target. | Absolute bars: the curve-shape sim against the target. Plus a whole-game critic each pass that reads every new cap and the curve. |
| The costing reviewer's hand math can veto. | It won every split and cut 10 of 10, with no sims. | Costing becomes advice backed by sims, with a "too small" check. Rare highrolls don't fail work (owner, 9d). |
| Bots stand in for human opponents in playtests. | Bots pin carries, never buy answers and never greed. After the rework a human will snowball against them, and that would look like the problem the owner fears. | A "strong field" mode: each round's opponent comes from that round's constructed field. Snowball reports count only when a sim reproduces them. |

## 3. Calls I'm making now (logged in DECISIONS.md)

- **The scale target is a shape, not a unit size.** It is set as:
  - growth per round after round 8;
  - spread: p90/p50, and the share of boards at twice the median or more;
  - the top 1%;
  - the biggest unit's share of the board;
  - stats per gold by round;
  - game length.

  First target: Battlegrounds' September 2025 shape. That means roughly ×1.5 a round from round 8, 13–23% of boards at twice the median from round 10, the top 1% up to 10 times, and winners done by rounds 14–16. Variants are tested on either side, including the current patch's steeper curve.
- **Growth rate and game length are one decision.** At ×1.5 a round, a 20-round game ends 90 times above round 8. So the damage table and Health are re-set together with the curve.
- **There is a variance budget alongside compounding.** It includes:
  - answers that ignore rows (a few);
  - stat-holding keywords;
  - summons.

  The bar: the smaller board wins a set share of rounds 10–14 fights. Battlegrounds' figure is 14–26% of fights won by the side with fewer stats.
- **Every tribe gets a compounding, permanent, visible engine and a route to a carry.** Some tribes also get a strong non-carry route (my current lean: Bog as the answer tribe, Oozes wide through Bellies). Neutrals get a few answers. On the ideation branch these are designers' calls (owner, 9c: "be creative").
- **The balance bar becomes "same order of magnitude", measured on sims.** Each tribe's best line scores within a set band of field win rates, read as distributions. Bot lobbies only check sanity.

## 4. Questions for the owner

Each has my default. Answer only the ones you want to.

1. **Which Battlegrounds era had the curve you'd want us to feel like?** Options: launch era (carries 30–60 late), September 2025 (about 54/54 a unit at turn 12), or now (median unit 117/117 at turn 12).
   - Default: September 2025's shape. Sims test the others too.
2. **May answers reach a carry hidden in the back row?**
   - Default: rarely. Two or three cards in the whole pool target "the biggest enemy" in any row, while most answers still aim across. This keeps the back row meaningful and stops carries being untouchable.
3. **The playtest build has no recruit timer, so patient players can run many-action lines.**
   - Default: keep no timer. The rising refresh price stays the brake until sims show many-action lines dominate.
4. **Would you spend ten minutes judging about eight constructed boards (rounds 9, 12 and 15) as "what a strong player would have here"?**
   - Default: no. A search for the best reachable board sets the upper bound, and scripted lines set typical play. Your eye would calibrate both, so it's worth it if you have the time.
