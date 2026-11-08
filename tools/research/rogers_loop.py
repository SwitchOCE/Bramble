"""Why Infinite Pirates was infinite in Battlegrounds, and whether it would be in Bramble.

Evidence for the owner's Sky Admiral Rogers example (docs/design/owner-notes/2026-11-08b-taste-answers.md
section 4.2). Standard library only. Run:  python -I tools/research/rogers_loop.py

THE MODEL IN ONE PARAGRAPH
Rogers counts every gold spent (refreshes and buys alike) and pays it back as Bounties. Call the gold
returned per gold spent r. A refresh at price p then costs p * (1 - r). Buying a unit for 3 and
selling it straight back for s costs 3 - s but returns 3 * r, so each buy nets 3r - 3 + s. A turn
is unbounded when one shop, on average, gives back at least what it costs:

    -p * (1 - r) + sum over the units you buy of (3r - 3 + s)  >=  0

With r below 1 and no buys, the turn always ends: total gold spent is G / (1 - r) for a bank of G.
Buying is what can tip it over. An ordinary unit (s = 1) is worth buying once r > 2/3. A unit that
sells for its price, like Freedealing Gambler (s = 3), is worth buying at any r > 0.

CARD TEXT (docs/research/battlegrounds/data/)
  Sky Admiral Rogers, golden: "After you spend 9 Gold, get two random Bounties."
  Proud Privateer, golden: "Your Bounties cast three times."
  Bounties (random, 1 in 5 each; uniform pick is a judgement): Wealthy "Gain 2 Gold";
    Friendly "Get a random minion of your most common type" (a Pirate here, sold for gold);
    Healthy, Hostile, Selfish give stats only.
  Freedealing Gambler (tier 2): "This minion sells for 3 Gold."
  Bounties from Rogers go to hand and are free to cast; only shop Bounties cost 2.

RULE DIFFERENCES THAT MATTER
  Battlegrounds: every unit sells for 1, refresh always costs 1.
  Bramble: Created units (Friendly Bounty's Pirate) sell for 0 (rulebook 4.3.3). Bought units sell
    as normal. Paid refreshes 1-15 cost 1, 16-20 cost 2, 21-25 cost 3, and so on (rulebook 4.4.3).

LIMITS
  Ignores hand and board space, the turn timer, and stats. Assumes the player buys a unit only when
  that buy is profitable, sells it at once, and refreshes until broke. Gambler frequency is the
  pool-share figure from economy-engines.md (one named tier-2 card about once per 19 shops at tier 6).
"""
import random

CAP = 2000          # shops in one turn; reaching it counts as unbounded
SLOTS = 6           # unit slots in a tier-6 shop
UNIT_PRICE = 3
GAMBLER_PER_SLOT = 1 / (19 * SLOTS)


def spend_return(golden_rogers, casts, friendly_sell):
    """Gold returned per gold spent (r). Each golden Rogers gives 2 Bounties per 9 gold."""
    bounties_per_9 = 2 * golden_rogers
    gold_per_cast = (2 + friendly_sell) / 5          # Wealthy 2 gold, Friendly sells for friendly_sell
    return bounties_per_9 * casts * gold_per_cast / 9


def price(rule, paid):
    """Price of the next paid refresh, given paid refreshes already made this turn."""
    if rule == 'BG':
        return 1
    return 1 if paid < 15 else 2 + (paid - 15) // 5   # Bramble, rulebook 4.4.3


def net_per_buy(r, sell):
    return UNIT_PRICE * r - UNIT_PRICE + sell


def turn(rule, bank, r, rng):
    """Shops seen and gold spent in one turn, buying every unit whose buy is profitable."""
    gold, paid, shops, spent = float(bank), 0, 0, 0.0
    buy_ordinary = net_per_buy(r, 1) > 0
    while shops < CAP:
        p = price(rule, paid)
        if gold < p:
            break
        gold += p * r - p
        spent += p
        paid += 1
        shops += 1
        for _ in range(SLOTS):
            gambler = rng.random() < GAMBLER_PER_SLOT
            if gold >= UNIT_PRICE and (gambler or buy_ordinary):
                gold += net_per_buy(r, 3 if gambler else 1)
                spent += UNIT_PRICE
    return shops, spent


def main():
    lines = [
        # name, golden Rogers, Privateer casts, Friendly's Pirate sells for (BG), same in Bramble
        ('Golden Rogers + golden Privateer', 1, 3, 1, 0),
        ('Two golden Rogers + golden Privateer', 2, 3, 1, 0),
        ("Same, owner's estimate (Pirates sell ~4/3 each)", 2, 3, 4 / 3, 0),
    ]
    rng = random.Random(7)
    print('r = gold back per gold spent. Ordinary buys pay once r > 0.667.\n')
    print('%-48s %6s %8s | %-26s | %-26s' % ('Board', 'rule', 'r', 'median shops (bank 10/30/60)',
                                              'median gold spent (10/30/60)'))
    # 'B-ref' isolates Bramble's refresh prices with Battlegrounds sell values, to show which rule does the work.
    for name, n, casts, sell_bg, sell_bramble in lines:
        for label, rule, sell in (('BG', 'BG', sell_bg), ('B-ref', 'Bramble', sell_bg),
                                  ('Bramble', 'Bramble', sell_bramble)):
            r = spend_return(n, casts, sell)
            shops, spent = [], []
            for bank in (10, 30, 60):
                runs = sorted(turn(rule, bank, r, rng) for _ in range(400))
                s, g = runs[200]
                shops.append('>=2000' if s >= CAP else str(s))
                spent.append('-' if s >= CAP else '%d' % g)
            print('%-48s %6s %8.2f | %-26s | %-26s' % (name, label, r, ' / '.join(shops), ' / '.join(spent)))
    print("\nBG = Battlegrounds rules. B-ref = Bramble's refresh prices but Battlegrounds sell values."
          "\nBramble = Bramble's refresh prices and Created units selling for 0.")
    print('\nPer-shop balance at a 1-gold refresh, buying all 6 ordinary units when profitable:')
    for r in (0.53, 0.80, 0.89):
        buys = SLOTS * max(0.0, net_per_buy(r, 1))
        print('  r = %.2f: refresh %+.2f, buys %+.2f, net %+.2f per shop' % (r, -(1 - r), buys, buys - (1 - r)))


if __name__ == '__main__':
    main()
