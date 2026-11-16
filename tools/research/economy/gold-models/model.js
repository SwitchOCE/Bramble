// Bramble shop & economy toy model. Single-player economy only (no fights).
// node model.js  -> prints tables.
'use strict';

// ---------- RNG ----------
let seed = 12345;
function R() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }

// ---------- odds tables: per-slot chance of each tier, by shop tier ----------
const ODDS = {
  // Battlegrounds today, from copies left in a fresh 5-tribe lobby (computed from minions.csv)
  bg: [null, [100], [40, 60], [25, 37, 39], [17, 25, 27, 31], [14, 20, 22, 25, 19], [13, 19, 20, 23, 18, 8]],
  // TFT-shaped: weighted toward the current tier, low tiers fade out
  tftlike: [null, [100], [60, 40], [35, 40, 25], [20, 30, 32, 18], [12, 20, 28, 27, 13], [7, 13, 22, 27, 21, 10]],
  // Steeper: your top two tiers are most of the shop
  steep: [null, [100], [50, 50], [25, 40, 35], [10, 25, 35, 30], [5, 15, 25, 33, 22], [3, 8, 17, 27, 28, 17]],
};

function income(p, t) {
  let g = p.start + p.step * (t - 1);
  if (p.accelFrom && t > p.accelFrom) g += (p.accelStep - p.step) * (t - p.accelFrom);
  if (p.cap) g = Math.min(g, p.cap);
  return Math.round(g * (1 + p.econPct / 100) + p.econFlat * (t >= 3 ? 1 : 0));
}
function rollPrice(n) { // n = paid refreshes already made this turn (rulebook 4.4.3)
  return n < 15 ? 1 : 2 + Math.floor((n - 15) / 5);
}
function drawTier(odds) {
  let x = R() * 100, s = 0;
  for (let i = 0; i < odds.length; i++) { s += odds[i]; if (x < s) return i + 1; }
  return odds.length;
}

// One game of one player. Unit: {tier, fit, paid}
function play(p) {
  let gold = 0, tier = 1, nextCost = p.tierCost[2], board = [], log = [];
  for (let t = 1; t <= p.turns; t++) {
    const inc = income(p, t); gold += inc;
    if (t > 1) nextCost = Math.max(0, nextCost - p.discount);
    let tierSpend = 0, buySpend = 0, sellBack = 0, rollSpend = 0, rolls = 0, buys = 0;
    // tier up per plan
    while (tier < 6 && t >= p.plan[tier + 1] && gold >= nextCost) {
      gold -= nextCost; tierSpend += nextCost; tier++;
      nextCost = tier < 6 ? p.tierCost[tier + 1] : Infinity;
    }
    const val = u => u.tier + (u.fit ? p.fitBonus : 0);
    const cost = u => u.tier + 1;
    const sellv = u => Math.max(0, u.paid - 1);
    // reserve gold for next turn's planned tier-up
    let reserve = 0;
    if (tier < 6 && t + 1 >= p.plan[tier + 1]) reserve = Math.max(0, nextCost - p.discount - income(p, t + 1));
    const wantFull = Math.min(7, p.boardByTurn(t));
    let shop = [];
    const refill = () => { shop = []; for (let i = 0; i < p.slots; i++) shop.push({ tier: drawTier(p.odds[tier]), fit: R() < p.fitShare }); };
    refill();
    for (let guard = 0; guard < 400; guard++) {
      // buy pass: best shop unit first
      shop.sort((a, b) => val(b) - val(a));
      let bought = true;
      while (bought) {
        bought = false;
        for (let i = 0; i < shop.length; i++) {
          const u = shop[i];
          if (board.length < wantFull) {
            if (gold - cost(u) >= 0) { gold -= cost(u); buySpend += cost(u); board.push({ ...u, paid: cost(u) }); shop.splice(i, 1); buys++; bought = true; break; }
          } else {
            board.sort((a, b) => val(a) - val(b));
            const w = board[0];
            if (val(u) > val(w) && gold + sellv(w) - cost(u) >= reserve) {
              gold += sellv(w); sellBack += sellv(w); gold -= cost(u); buySpend += cost(u);
              board[0] = { ...u, paid: cost(u) }; shop.splice(i, 1); buys++; bought = true; break;
            }
          }
        }
      }
      // roll decision: is the board "current"?  current = every unit is on-plan at shop tier - lag, or better
      board.sort((a, b) => val(a) - val(b));
      const worst = board.length ? val(board[0]) : 0;
      const target = tier - p.lag + p.fitBonus;
      const happy = board.length >= wantFull && worst >= target;
      const pr = rollPrice(rolls);
      if (happy) break;
      if (rolls >= p.maxRolls) break;
      // keep enough to buy something useful after rolling
      if (gold - pr < reserve + Math.min(tier + 1, 3)) break;
      gold -= pr; rollSpend += pr; rolls++; refill();
    }
    const stock = board.reduce((s, u) => s + sellv(u), 0);
    const avgT = board.reduce((s, u) => s + u.tier, 0) / Math.max(1, board.length);
    const fit = board.filter(u => u.fit).length;
    log.push({ t, inc, tier, units: board.length, avgT, fit, rolls, rollSpend, tierSpend, buySpend, sellBack, bank: gold, stock, buys });
  }
  return log;
}

function avgRuns(p, n = 2000) {
  const acc = [];
  for (let k = 0; k < n; k++) {
    const L = play(p);
    L.forEach((r, i) => { acc[i] = acc[i] || {}; for (const key in r) acc[i][key] = (acc[i][key] || 0) + r[key] / n; });
  }
  return acc;
}

const BASE = {
  start: 5, step: 3, accelFrom: 0, accelStep: 3, cap: 0, econPct: 0, econFlat: 0,
  tierCost: [0, 0, 5, 7, 8, 11, 11], discount: 1,
  plan: [0, 0, 2, 4, 6, 8, 10], // turn each tier is reached (standard BG-ish curve)
  odds: ODDS.tftlike, slots: 5, fitShare: 0.35, fitBonus: 1, lag: 0, maxRolls: 60,
  boardByTurn: t => t + 1, turns: 14,
};

function fmt(acc, cols) {
  const head = 'turn ' + cols.map(c => c.padStart(6)).join('');
  const lines = acc.map(r => String(r.t).padStart(4) + ' ' + cols.map(c => (Math.abs(r[c]) < 10 ? r[c].toFixed(1) : r[c].toFixed(0)).padStart(6)).join(''));
  return [head, ...lines].join('\n');
}
module.exports = { play, avgRuns, BASE, ODDS, income, rollPrice, fmt };

if (require.main === module) {
  const mode = process.argv[2] || 'all';
  const cols = ['inc', 'tier', 'units', 'avgT', 'fit', 'rolls', 'rollSpend', 'tierSpend', 'buySpend', 'sellBack', 'bank', 'stock'];
  const run = (name, over) => { const p = { ...BASE, ...over }; console.log('\n== ' + name); console.log(fmt(avgRuns(p), cols)); };
  if (mode === 'all' || mode === 'a') {
    run('+3, BG tier costs', {});
    run('+2, BG tier costs', { step: 2 });
    run('+3, tier costs x2', { tierCost: [0, 0, 10, 14, 16, 22, 22] });
    run('+2, tier costs x2', { step: 2, tierCost: [0, 0, 10, 14, 16, 22, 22] });
  }
}
