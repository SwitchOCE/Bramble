'use strict';
// v2 rules: income 5,+2 to 15 then +1; refresh 1 for first 10 then +1 per 5; sell = ceil(tier/2) per copy;
// tier discount per turn waited: 2,3,4,5 (then stays 5 unless discCont); units cost tier+1.
let seed = 777; const R = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const ODDS = [null, [100], [60, 40], [35, 40, 25], [20, 30, 32, 18], [12, 20, 28, 27, 13], [7, 13, 22, 27, 21, 10]];
const income = (p, t) => { let g = p.start, s = p.step; for (let k = 2; k <= t; k++) g += g >= p.knee ? p.late : s; return g; };
const rollPrice = (p, n) => n < p.free1 ? 1 : 2 + Math.floor((n - p.free1) / 5);
const discAt = (p, k) => k <= 0 ? 0 : Math.min(p.discStart + k - 1, p.discMax); // discount on k-th turn waited
const drawTier = o => { let x = R() * 100, s = 0; for (let i = 0; i < o.length; i++) { s += o[i]; if (x < s) return i + 1; } return o.length; };
function play(p) {
  let gold = 0, tier = 1, cost = p.tierCost[2], waited = 0, board = [], log = [], lastUp = -9;
  for (let t = 1; t <= p.turns; t++) {
    const inc = income(p, t); gold += inc;
    if (t > 1 && tier < 6) { waited++; cost = Math.max(0, cost - discAt(p, waited)); }
    let tierSpend = 0, rolls = 0, rollSpend = 0, net = 0, b2b = false;
    const wantTier = p.policy(t, tier, cost, gold, lastUp);
    if (tier < 6 && wantTier && gold >= cost) { gold -= cost; tierSpend = cost; tier++; b2b = (t - lastUp === 1); lastUp = t; waited = 0; cost = tier < 6 ? p.tierCost[tier + 1] : Infinity; }
    const val = u => u.tier + (u.fit ? 1 : 0), buyC = u => u.tier + 1, sellV = u => u.sell;
    // reserve for next turn's tier-up if the policy wants it
    let reserve = 0;
    if (tier < 6 && p.policy(t + 1, tier, Math.max(0, cost - discAt(p, waited + 1)), 99, lastUp)) reserve = Math.max(0, cost - discAt(p, waited + 1) - income(p, t + 1));
    const want = Math.min(7, p.boardByTurn(t));
    let shop = []; const refill = () => { shop = []; for (let i = 0; i < 5; i++) shop.push({ tier: drawTier(p.odds[tier]), fit: R() < p.fitShare }); };
    refill();
    for (let g = 0; g < 300; g++) {
      shop.sort((a, b) => val(b) - val(a));
      let bought = true;
      while (bought) { bought = false;
        for (let i = 0; i < shop.length; i++) { const u = shop[i];
          if (board.length < want) { if (gold - buyC(u) >= reserve || (board.length < 2)) { if (gold < buyC(u)) continue; gold -= buyC(u); net += buyC(u); board.push({ ...u, sell: Math.ceil(u.tier / 2) }); shop.splice(i, 1); bought = true; break; } }
          else { board.sort((a, b) => val(a) - val(b)); const w = board[0];
            if (val(u) > val(w) && gold + sellV(w) - buyC(u) >= reserve) { gold += sellV(w) - buyC(u); net += buyC(u) - sellV(w); board[0] = { ...u, sell: Math.ceil(u.tier / 2) }; shop.splice(i, 1); bought = true; break; } } } }
      board.sort((a, b) => val(a) - val(b));
      const happy = board.length >= want && board.length && val(board[0]) >= tier + 1 - p.lag;
      const pr = rollPrice(p, rolls);
      if (happy || rolls >= p.maxRolls || gold - pr < reserve + Math.min(tier + 1, 4)) break;
      gold -= pr; rollSpend += pr; rolls++; refill();
    }
    const avgT = board.reduce((s, u) => s + u.tier, 0) / Math.max(1, board.length);
    log.push({ t, inc, tier, units: board.length, avgT, fit: board.filter(u => u.fit).length, rolls, rollSpend, tierSpend, unitNet: net, bank: gold, b2b: b2b ? 1 : 0 });
  }
  return log;
}
function avg(p, n = 1500) { const a = []; for (let k = 0; k < n; k++) play(p).forEach((r, i) => { a[i] = a[i] || {}; for (const c in r) a[i][c] = (a[i][c] || 0) + r[c] / n; }); return a; }
const curve = plan => (t, tier) => tier < 6 && t >= plan[tier + 1];
const BASE = { start: 5, step: 2, knee: 15, late: 1, free1: 10, discStart: 2, discMax: 5, tierCost: [0, 0, 8, 12, 16, 19, 21],
  odds: ODDS, fitShare: 0.35, lag: 0, maxRolls: 60, boardByTurn: t => t + 1, turns: 14, policy: curve([0, 0, 2, 4, 6, 8, 10]) };
module.exports = { play, avg, BASE, income, rollPrice, discAt, curve };
