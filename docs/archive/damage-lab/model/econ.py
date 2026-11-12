# Rough per-turn accounting: a player follows a BG-like tier curve and keeps a full board
# at their tier as fast as gold allows. Reports units on board, avg board tier, and gold left for rolls.
upg_base={2:5,3:7,4:8,5:11,6:11}
tier_turn={2:2,3:4,4:6,5:8,6:10}   # turn each upgrade is bought (BG-ish curve)
def run(name,income,cost,sell,turns=14,buys_cap=99):
    gold=0; tier=1; board=[]; disc=0; up_cost=upg_base[2]; out=[]
    for t in range(1,turns+1):
        if t>1: up_cost=max(0,up_cost-1)
        gold+=income(t)
        if tier<6 and tier_turn[tier+1]==t and gold>=up_cost:
            gold-=up_cost; tier+=1; up_cost=upg_base.get(tier+1,0)
        buys=0
        # buy best-tier units: fill board, then replace lowest-tier units while it's an upgrade
        while buys<buys_cap:
            c=cost(tier)
            if len(board)<7:
                if gold<c: break
                gold-=c; board.append(tier); buys+=1; continue
            low=min(board)
            if low>=tier: break
            if gold+sell(low)<c: break
            board.remove(low); gold+=sell(low)-c; board.append(tier); buys+=1
        out.append((t,income(t),tier,len(board),round(sum(board)/max(1,len(board)),1),buys,gold))
        gold_for_rolls=gold; gold=0 if name.startswith('BG') else gold  # BG loses unspent; Bramble carries (we spend rest on rolls)
        out[-1]=out[-1]+(gold_for_rolls,)
        gold=0  # assume leftover is spent on rolls
    print(name); print(' turn inc tier units avgT buys rolls')
    for r in out: print(' %4d %3d %4d %5d %4.1f %4d %5d'%(r[0],r[1],r[2],r[3],r[4],r[5],r[7]))
bg_inc=lambda t:min(10,2+t)
run('BG: income 3..10, buy 3, sell 1',bg_inc,lambda T:3,lambda T:1)
run('Proposal, BG income: buy tier+1, sell tier',bg_inc,lambda T:T+1,lambda T:T)
run('Proposal, income 5,6,7.. no cap',lambda t:4+t,lambda T:T+1,lambda T:T)
run('Proposal, income 5..10 then +1 per 2 turns',lambda t:min(4+t,10)+max(0,(t-6)//2),lambda T:T+1,lambda T:T)
