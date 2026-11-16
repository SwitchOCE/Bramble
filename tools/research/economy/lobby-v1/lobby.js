// Bramble fudge sim: economy + power numbers + fights + damage, 8-player lobby.
// Every number here is a judgement call; all of them live in CFG.
'use strict';
let seed = 7;
const R = () => { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; };
const gauss = () => Math.sqrt(-2 * Math.log(R() || 1e-9)) * Math.cos(2 * Math.PI * R());

const CFG = {
  // economy (rulebook proposals)
  incStart: 5, incStep: 2, incKnee: 15, incLate: 1,
  extra: 0, extraFrom: 4,                  // stand-in for economy units: +gold a turn from a turn
  tierBase: [8, 14, 22, 30, 38], disc: [1, 2, 3, 4, 5],
  rollCheap: 10, rollEvery: 5,
  odds: [null, [100], [60, 40], [35, 40, 25], [20, 30, 32, 18], [12, 20, 28, 27, 13], [7, 13, 22, 27, 21, 10]],
  shopSize: 5, boardSize: 7, unitsPerTier: [0, 14, 14, 14, 12, 12, 10],
  // power numbers (fudge)
  p1: 10, growth: 1.5,          // tier N unit = 10 x 1.5^(N-1): 10, 15, 22, 34, 51, 76
  goldenMult: 2,                // a triple is twice one copy
  scaleFlat: 1, scalePct: 0.05, // each unit grows every turn it stays on the board
  spellCost: 3, spellPct: 0.36, spellsPerShop: 2, // a spell buffs a unit by 36% of a unit of your tier
  // fights and damage
  sigma: 0.082,   // 90 vs 60: ~never; 90 vs 85: ~68%
  drawBand: 0.02, bigRatio: 0.65, hp: 40, players: 8,
};

const P = t => CFG.p1 * CFG.growth ** (t - 1);
const income = t => { let g = CFG.incStart; for (let k = 2; k <= t; k++) g += g >= CFG.incKnee ? CFG.incLate : CFG.incStep; return g + (t >= CFG.extraFrom ? CFG.extra : 0); };
const cum = w => { let s = 0; for (let i = 0; i < w; i++) s += CFG.disc[Math.min(i, CFG.disc.length - 1)]; return s; };
const tierPrice = (tier, waited) => Math.max(0, CFG.tierBase[tier - 1] - cum(waited));
const rollPrice = n => n < CFG.rollCheap ? 1 : 2 + Math.floor((n - CFG.rollCheap) / CFG.rollEvery);
const pow = u => P(u.tier) * (u.golden ? CFG.goldenMult : 1) + u.buff;
const boardPow = b => b.reduce((s, u) => s + pow(u), 0);
const sellOf = u => Math.ceil(u.tier / 2) * u.paid;   // per bought copy; tokens 0

function drawUnit(shopTier) {
  const o = CFG.odds[shopTier]; let x = R() * 100, t = o.length;
  for (let i = 0, s = 0; i < o.length; i++) { s += o[i]; if (x < s) { t = i + 1; break; } }
  return { tier: t, id: Math.floor(R() * CFG.unitsPerTier[t]) };
}

// Apply buying unit u to a copy of the board. Returns {board, refund}.
function withBuy(board, u, shopTier) {
  let b = board.map(x => ({ ...x })), refund = 0;
  const same = b.filter(x => !x.golden && x.tier === u.tier && x.id === u.id);
  if (same.length >= 2) {
    const [a, c] = same; b = b.filter(x => x !== a && x !== c);
    b.push({ tier: u.tier, id: u.id, golden: true, buff: a.buff + c.buff, paid: a.paid + c.paid + 1 });
    b.push({ tier: Math.min(6, shopTier + 1), id: -1, golden: false, buff: 0, paid: 0 }); // triple reward, a token
  } else b.push({ tier: u.tier, id: u.id, golden: false, buff: 0, paid: 1 });
  while (b.length > CFG.boardSize) { b.sort((x, y) => pow(x) - pow(y)); refund += sellOf(b.shift()); }
  return { board: b, refund };
}

const STRATS = [
  { name: 'Hyper-rush (any time)', plan: [2, 3, 4, 5, 6], panicHP: 0, rollCap: 0, spells: false },
  { name: 'Burst (4,4,10,10,10)', plan: [4, 4, 10, 10, 10], panicHP: 0, rollCap: 2, spells: false },
  { name: 'Fast (2,4,6,8,10)', plan: [2, 4, 6, 8, 10], panicHP: 12, rollCap: 3, spells: true },
  { name: 'Standard (3,5,7,9,11)', plan: [3, 5, 7, 9, 11], panicHP: 12, rollCap: 5, spells: true },
  { name: 'Slow (3,6,9,11,13)', plan: [3, 6, 9, 11, 13], panicHP: 12, rollCap: 8, spells: true },
  { name: 'Stay low (4,8,11,14,16)', plan: [4, 8, 11, 14, 16], panicHP: 12, rollCap: 15, spells: true },
];

function playerTurn(p, t) {
  if (t > 1 && p.tier < 6) p.waited++;
  p.gold += income(t);
  const panic = p.hp <= p.s.panicHP;
  const due = () => p.tier < 6 && t >= p.s.plan[p.tier - 1];
  // tier-ups (a free one is always taken)
  while (p.tier < 6 && ((due() && !panic) || tierPrice(p.tier, p.waited) === 0) && p.gold >= tierPrice(p.tier, p.waited)) {
    const c = tierPrice(p.tier, p.waited);
    p.gold -= c; p.tierSpend += c; p.tier++; p.waited = 0; p.tierTurn[p.tier] = t;
  }
  // reserve for the next planned tier-up (saves up to 3 turns ahead)
  let reserve = 0;
  if (p.tier < 6 && !panic) {
    const T2 = Math.max(p.s.plan[p.tier - 1], t + 1);
    if (T2 - t <= 3) {
      let incSum = 0; for (let u = t + 1; u <= T2; u++) incSum += income(u);
      reserve = Math.max(0, tierPrice(p.tier, p.waited + (T2 - t)) - incSum);
    }
  }
  // shop
  let rolls = 0;
  const fill = () => { const s = []; for (let i = 0; i < CFG.shopSize; i++) s.push(drawUnit(p.tier)); return s; };
  let shop = fill(), spells = p.s.spells ? CFG.spellsPerShop : 0;
  for (let guard = 0; guard < 200; guard++) {
    const spare = p.gold - reserve, before = boardPow(p.board);
    let best = null;
    shop.forEach((u, i) => {
      const cost = u.tier + 1; if (cost > spare) return;
      const r = withBuy(p.board, u, p.tier);
      let gain = boardPow(r.board) - before;
      if (p.board.some(x => !x.golden && x.tier === u.tier && x.id === u.id)) gain += 0.25 * P(u.tier); // pair hope
      if (gain > 0 && (!best || gain / cost > best.score)) best = { kind: 'unit', i, r, cost, score: gain / cost };
    });
    if (spells > 0 && CFG.spellCost <= spare && p.board.length) {
      const gain = CFG.spellPct * P(p.tier);
      if (!best || gain / CFG.spellCost > best.score) best = { kind: 'spell', cost: CFG.spellCost, score: gain / CFG.spellCost };
    }
    if (best) {
      p.gold -= best.cost; p.unitSpend += best.cost;
      if (best.kind === 'unit') { p.board = best.r.board; p.gold += best.r.refund; shop.splice(best.i, 1); }
      else { spells--; p.board.sort((a, b) => pow(b) - pow(a)); p.board[0].buff += CFG.spellPct * P(p.tier); }
      continue;
    }
    const rp = rollPrice(rolls);
    if (rolls < p.s.rollCap + (panic ? 6 : 0) && spare >= rp + 2) { p.gold -= rp; p.rollSpend += rp; rolls++; shop = fill(); spells = p.s.spells ? CFG.spellsPerShop : 0; continue; }
    break;
  }
}

function playGame(seats) {
  const ps = seats.map(s => ({ s, hp: CFG.hp, alive: true, gold: 0, tier: 1, waited: 0, board: [], tierTurn: {}, unitSpend: 0, tierSpend: 0, rollSpend: 0, out: 0, last: null, snap: {} }));
  let ghostPow = 0.1, order = [], t = 0;
  while (ps.filter(p => p.alive).length > 1 && t < 40) {
    t++;
    const alive = ps.filter(p => p.alive);
    alive.forEach(p => playerTurn(p, t));
    const a = alive.slice().sort(() => R() - 0.5);
    for (let i = 0; i + 1 < a.length; i += 2) if (a[i].last === a[i + 1] && i + 2 < a.length) [a[i + 1], a[i + 2]] = [a[i + 2], a[i + 1]];
    const fights = [];
    for (let i = 0; i + 1 < a.length; i += 2) fights.push([a[i], a[i + 1]]);
    if (a.length % 2) fights.push([a[a.length - 1], null]);
    const dmg = Math.min(10, t + 1);
    for (const [x, y] of fights) {
      const px = boardPow(x.board) + 0.1, py = y ? boardPow(y.board) + 0.1 : ghostPow;
      const d = Math.log(px) + CFG.sigma * gauss() - Math.log(py) - CFG.sigma * gauss();
      if (y) { x.last = y; y.last = x; }
      if (Math.abs(d) < CFG.drawBand) continue;
      const loser = d > 0 ? y : x;
      if (!loser) continue; // the ghost lost
      loser.hp -= dmg + (Math.exp(-Math.abs(d)) < CFG.bigRatio ? 3 : 0);
    }
    const dead = alive.filter(p => p.hp <= 0).sort((x, y) => x.hp - y.hp);
    for (const p of dead) { p.alive = false; p.out = t; order.push(p); ghostPow = boardPow(p.board) + 0.1; }
    for (const p of ps) if ([6, 8, 10, 12].includes(t)) p.snap[t] = p.alive ? { tier: p.tier, hp: p.hp, pw: boardPow(p.board) } : null;
    for (const p of ps.filter(p => p.alive)) for (const u of p.board) u.buff += CFG.scaleFlat + CFG.scalePct * P(u.tier) * (u.golden ? 2 : 1);
  }
  ps.filter(p => p.alive).forEach(p => { p.out = t + 1; order.push(p); });
  order.reverse().forEach((p, i) => p.place = i + 1);
  return { ps, length: t };
}

function run(n, label) {
  const acc = {}; const lens = [], firstOut = [];
  for (let g = 0; g < n; g++) {
    const seats = STRATS.slice(); while (seats.length < CFG.players) seats.push(STRATS[2 + Math.floor(R() * 4)]);
    const { ps, length } = playGame(seats);
    lens.push(length); firstOut.push(Math.min(...ps.map(p => p.out)));
    for (const p of ps) {
      const a = acc[p.s.name] = acc[p.s.name] || { n: 0, place: 0, win: 0, top4: 0, t6: 0, t6turn: [], out: 0, unit: 0, tierG: 0 };
      a.n++; a.place += p.place; a.win += p.place === 1; a.top4 += p.place <= 4;
      if (p.tierTurn[6]) { a.t6++; a.t6turn.push(p.tierTurn[6]); }
      a.out += p.out; a.unit += p.unitSpend; a.tierG += p.tierSpend;
      for (const k of [6, 8, 10, 12]) { const z = p.snap[k]; a['s' + k] = a['s' + k] || { n: 0, tier: 0, hp: 0, pw: 0 }; if (z) { const q = a['s' + k]; q.n++; q.tier += z.tier; q.hp += z.hp; q.pw += z.pw; } }
    }
  }
  const pct = (arr, q) => { const s = arr.slice().sort((x, y) => x - y); return s[Math.floor(q * (s.length - 1))]; };
  console.log(`\n== ${label}   fights per game ${pct(lens, .1)}/${pct(lens, .5)}/${pct(lens, .9)}  first out ${pct(firstOut, .5)}`);
  console.log('  strategy                   place  win%  top4%  reach T6%  T6 turn  out turn');
  for (const s of STRATS) {
    const a = acc[s.name];
    console.log('  ' + s.name.padEnd(25) + (a.place / a.n).toFixed(2).padStart(6) + (100 * a.win / a.n).toFixed(0).padStart(6) + (100 * a.top4 / a.n).toFixed(0).padStart(7)
      + (100 * a.t6 / a.n).toFixed(0).padStart(10) + String(a.t6turn.length ? pct(a.t6turn, .5) : '-').padStart(9) + (a.out / a.n).toFixed(1).padStart(10)
      + '   ' + [6, 8, 10, 12].map(k => { const q = a['s' + k]; return q.n ? `t${k}: tier ${(q.tier / q.n).toFixed(1)} hp ${(q.hp / q.n).toFixed(0)} pow ${(q.pw / q.n).toFixed(0)}` : `t${k}: -`; }).join(' | '));
  }
}
module.exports = { CFG, STRATS, run };
if (require.main === module) {
  const over = process.argv[2] ? JSON.parse(process.argv[2]) : {};
  Object.assign(CFG, over);
  run(+process.argv[3] || 2000, process.argv[4] || JSON.stringify(over));
}
