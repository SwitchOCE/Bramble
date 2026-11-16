// Bramble fudge sim v2: adaptive evolved bots, economy units, strata/free evolution.
'use strict';
let rs = 7;
const R = () => { rs = (rs * 1664525 + 1013904223) >>> 0; return rs / 4294967296; };
const gauss = () => Math.sqrt(-2 * Math.log(R() || 1e-9)) * Math.cos(2 * Math.PI * R());

const CFG = {
  seed: 7,
  incStart: 5, incStep: 2, incKnee: 15, incLate: 1,
  extra: 0, extraFrom: 4,
  tierBase: [8, 14, 22, 30, 38], disc: [1, 2, 3, 4, 5],
  rollCheap: 10, rollEvery: 5,
  odds: [null, [100], [60, 40], [35, 40, 25], [20, 30, 32, 18], [12, 20, 28, 27, 13], [7, 13, 22, 27, 21, 10]],
  shopSize: 5, boardSize: 7, unitsPerTier: [0, 14, 14, 14, 12, 12, 10],
  p1: 10, growth: 1.5, goldenMult: 2,
  scaleFlat: 1, scalePct: 0.05,
  spellCost: 3, spellPct: 0.36, spellsPerShop: 2,
  sigma: 0.082, drawBand: 0.02, bigRatio: 0.65, hp: 40, players: 8,
  dmgCap: 10, bigBonus: 3,
  // economy units
  econShare: 0.14, econPow: 0.5, econGold: [0, 1, 1, 2, 2, 3, 3],
  // evolution
  popSize: 24, gens: 12, lobbiesPerGen: 500, evalLobbies: 4000, rushLobbies: 2000,
};

// gene ranges (cap is separate)
const GENES = { greedEarly: [0.3, 1], greedLate: [0.3, 1], L: [0, 4], relMin: [0, 1.3], save: [0, 1], rollCap: [0, 12], econW: [0, 2] };
const GK = Object.keys(GENES);
const RUSHER = { cap: 6, greedEarly: 1, greedLate: 1, L: 0, relMin: 0, save: 1, rollCap: 0, econW: 0 };

const P = t => CFG.p1 * CFG.growth ** (t - 1);
const income = t => { let g = CFG.incStart; for (let k = 2; k <= t; k++) g += g >= CFG.incKnee ? CFG.incLate : CFG.incStep; return g + (t >= CFG.extraFrom ? CFG.extra : 0); };
const cum = w => { let s = 0; for (let i = 0; i < w; i++) s += CFG.disc[Math.min(i, CFG.disc.length - 1)]; return s; };
const tierPrice = (tier, waited) => Math.max(0, CFG.tierBase[tier - 1] - cum(waited));
const rollPrice = n => n < CFG.rollCheap ? 1 : 2 + Math.floor((n - CFG.rollCheap) / CFG.rollEvery);
const pow = u => P(u.tier) * (u.golden ? CFG.goldenMult : 1) * (u.econ ? CFG.econPow : 1) + u.buff;
const boardPow = b => b.reduce((s, u) => s + pow(u), 0);
const pay = u => u.econ ? (CFG.econGold[u.tier] || 0) * (u.golden ? 2 : 1) : 0;
const boardPay = b => b.reduce((s, u) => s + pay(u), 0);
const sellOf = u => Math.ceil(u.tier / 2) * u.paid;

function drawUnit(shopTier) {
  const o = CFG.odds[shopTier]; let x = R() * 100, t = o.length;
  for (let i = 0, s = 0; i < o.length; i++) { s += o[i]; if (x < s) { t = i + 1; break; } }
  const id = Math.floor(R() * CFG.unitsPerTier[t]);
  if (CFG.econShare > 0 && R() < CFG.econShare) return { tier: t, id: 1000 + id, econ: true };
  return { tier: t, id };
}

function withBuy(board, u, shopTier, val) {
  let b = board.map(x => ({ ...x })), refund = 0;
  const same = b.filter(x => !x.golden && x.tier === u.tier && x.id === u.id);
  if (same.length >= 2) {
    const [a, c] = same; b = b.filter(x => x !== a && x !== c);
    b.push({ tier: u.tier, id: u.id, econ: !!u.econ, golden: true, buff: a.buff + c.buff, paid: a.paid + c.paid + 1 });
    b.push({ tier: Math.min(6, shopTier + 1), id: -1, econ: false, golden: false, buff: 0, paid: 0 });
  } else b.push({ tier: u.tier, id: u.id, econ: !!u.econ, golden: false, buff: 0, paid: 1 });
  while (b.length > CFG.boardSize) { b.sort((x, y) => val(x) - val(y)); refund += sellOf(b.shift()); }
  return { board: b, refund };
}

function playerTurn(p, t, medPow) {
  const s = p.s;
  if (t > 1 && p.tier < 6) p.waited++;
  const ep = boardPay(p.board); p.gold += income(t) + ep; p.econGold += ep;
  const danger = p.hp <= s.L * (Math.min(CFG.dmgCap, t + 1) + CFG.bigBonus);
  const econW = danger ? 0 : s.econW;
  const val = u => pow(u) + (econW ? econW * pay(u) * 3 * P(p.tier) / (p.tier + 1) : 0);
  const boardVal = b => b.reduce((a, u) => a + val(u), 0);
  const relOK = () => t === 1 || !(medPow > 0) || boardPow(p.board) / medPow >= s.relMin;
  let tiered = false;
  for (;;) {
    if (p.tier >= 6) break;
    const c = tierPrice(p.tier, p.waited);
    if (c > p.gold) break;
    const greed = p.tier + 1 <= 3 ? s.greedEarly : s.greedLate;
    if (c === 0 || (p.tier < s.cap && !danger && relOK() && c <= greed * p.gold)) {
      p.gold -= c; p.tierSpend += c; p.tier++; p.waited = 0; p.tierTurn[p.tier] = t; tiered = true;
    } else break;
  }
  let reserve = 0;
  if (!danger && p.tier < s.cap && !tiered) reserve = s.save * Math.max(0, tierPrice(p.tier, p.waited + 1) - (income(t + 1) + boardPay(p.board)));
  let rolls = 0;
  const rc = Math.round(s.rollCap) + (danger ? 6 : 0);
  const fill = () => { const a = []; for (let i = 0; i < CFG.shopSize; i++) a.push(drawUnit(p.tier)); return a; };
  let shop = fill(), spells = CFG.spellsPerShop;
  for (let guard = 0; guard < 200; guard++) {
    const spare = p.gold - reserve, before = boardVal(p.board);
    let best = null;
    shop.forEach((u, i) => {
      const cost = u.tier + 1; if (cost > spare) return;
      const r = withBuy(p.board, u, p.tier, val);
      let gain = boardVal(r.board) - before;
      if (p.board.some(x => !x.golden && x.tier === u.tier && x.id === u.id)) gain += 0.25 * P(u.tier);
      if (gain > 0 && (!best || gain / cost > best.score)) best = { kind: 'unit', i, r, cost, score: gain / cost };
    });
    if (spells > 0 && CFG.spellCost <= spare && p.board.length) {
      const gain = CFG.spellPct * P(p.tier);
      if (!best || gain / CFG.spellCost > best.score) best = { kind: 'spell', cost: CFG.spellCost, score: gain / CFG.spellCost };
    }
    if (best) {
      p.gold -= best.cost;
      if (best.kind === 'unit') { p.board = best.r.board; p.gold += best.r.refund; shop.splice(best.i, 1); }
      else { spells--; p.board.sort((a, b) => pow(b) - pow(a)); p.board[0].buff += CFG.spellPct * P(p.tier); }
      continue;
    }
    const rp = rollPrice(rolls);
    if (rolls < rc && spare >= rp + 2) { p.gold -= rp; rolls++; shop = fill(); spells = CFG.spellsPerShop; continue; }
    break;
  }
}

const median = a => { if (!a.length) return NaN; const s = a.slice().sort((x, y) => x - y); const m = s.length >> 1; return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2; };

function playGame(seats) {
  const ps = seats.map(s => ({ s, hp: CFG.hp, alive: true, gold: 0, tier: 1, waited: 0, board: [], tierTurn: { 1: 1 }, tierSpend: 0, econGold: 0, out: 0, last: null, lastPow: undefined }));
  let ghostPow = 0.1; const order = []; let t = 0;
  while (ps.filter(p => p.alive).length > 1 && t < 40) {
    t++;
    const alive = ps.filter(p => p.alive);
    for (const p of alive) {
      const others = alive.filter(q => q !== p && q.lastPow !== undefined).map(q => q.lastPow);
      playerTurn(p, t, others.length ? median(others) : 0);
    }
    const a = alive.slice().sort(() => R() - 0.5);
    for (let i = 0; i + 1 < a.length; i += 2) if (a[i].last === a[i + 1] && i + 2 < a.length) [a[i + 1], a[i + 2]] = [a[i + 2], a[i + 1]];
    const fights = [];
    for (let i = 0; i + 1 < a.length; i += 2) fights.push([a[i], a[i + 1]]);
    if (a.length % 2) fights.push([a[a.length - 1], null]);
    const dmg = Math.min(CFG.dmgCap, t + 1);
    for (const [x, y] of fights) {
      const bx = boardPow(x.board), by = y ? boardPow(y.board) : 0;
      x.lastPow = bx; if (y) y.lastPow = by;
      const px = bx + 0.1, py = y ? by + 0.1 : ghostPow;
      const d = Math.log(px) + CFG.sigma * gauss() - Math.log(py) - CFG.sigma * gauss();
      if (y) { x.last = y; y.last = x; }
      if (Math.abs(d) < CFG.drawBand) continue;
      const loser = d > 0 ? y : x;
      if (!loser) continue;
      loser.hp -= dmg + (Math.exp(-Math.abs(d)) < CFG.bigRatio ? CFG.bigBonus : 0);
    }
    const dead = alive.filter(p => p.hp <= 0).sort((x, y) => x.hp - y.hp);
    for (const p of dead) { p.alive = false; p.out = t; order.push(p); ghostPow = boardPow(p.board) + 0.1; }
    for (const p of ps.filter(p => p.alive)) for (const u of p.board) u.buff += (CFG.scaleFlat + CFG.scalePct * P(u.tier) * (u.golden ? 2 : 1)) * (u.econ ? CFG.econPow : 1);
  }
  ps.filter(p => p.alive).sort((x, y) => x.hp - y.hp).forEach(p => { p.out = t + 1; order.push(p); });
  order.reverse().forEach((p, i) => p.place = i + 1);
  return { ps, length: t };
}

// ---------- bots / evolution ----------
const rnd = (lo, hi) => lo + (hi - lo) * R();
const clamp = (x, lo, hi) => Math.min(hi, Math.max(lo, x));
const newBot = cap => { const b = { cap: cap || [4, 5, 6][Math.floor(R() * 3)] }; for (const k of GK) b[k] = rnd(...GENES[k]); return b; };
function mutate(b, fixedCap) {
  const c = { ...b };
  for (const k of GK) { const [lo, hi] = GENES[k]; c[k] = clamp(c[k] + gauss() * 0.12 * (hi - lo), lo, hi); }
  if (!fixedCap && R() < 0.15) { const o = [4, 5, 6].filter(x => x !== b.cap); c.cap = o[Math.floor(R() * 2)]; }
  return c;
}
function draw8(pop, n) {
  const idx = pop.map((_, i) => i);
  for (let i = 0; i < n; i++) { const j = i + Math.floor(R() * (idx.length - i)); [idx[i], idx[j]] = [idx[j], idx[i]]; }
  return idx.slice(0, n).map(i => pop[i]);
}
function fitnessGen(pop) {
  const sum = new Map(), cnt = new Map(); pop.forEach(b => { sum.set(b, 0); cnt.set(b, 0); });
  for (let g = 0; g < CFG.lobbiesPerGen; g++) {
    const { ps } = playGame(draw8(pop, CFG.players));
    for (const p of ps) { sum.set(p.s, sum.get(p.s) + p.place); cnt.set(p.s, cnt.get(p.s) + 1); }
  }
  pop.forEach(b => { b.fit = cnt.get(b) ? sum.get(b) / cnt.get(b) : 4.5; });
}
function evolve(mode) {
  let pop;
  if (mode === 'free') pop = Array.from({ length: CFG.popSize }, () => newBot());
  else pop = Array.from({ length: CFG.popSize }, (_, i) => newBot([4, 5, 6][Math.floor(i / 8)]));
  for (let gen = 0; gen < CFG.gens; gen++) {
    fitnessGen(pop);
    if (mode === 'free') {
      pop.sort((a, b) => a.fit - b.fit);
      const keep = pop.slice(0, 12);
      pop = keep.concat(keep.map(b => mutate(b, false)));
    } else {
      const next = [];
      for (const cap of [4, 5, 6]) {
        const sub = pop.filter(b => b.cap === cap).sort((a, b) => a.fit - b.fit);
        const keep = sub.slice(0, 4);
        next.push(...keep, ...keep.map(b => mutate(b, true)));
      }
      pop = next;
    }
  }
  fitnessGen(pop); // final ranking
  if (mode === 'free') { pop.sort((a, b) => a.fit - b.fit); return pop.slice(0, 12); }
  const out = [];
  for (const cap of [4, 5, 6]) out.push(...pop.filter(b => b.cap === cap).sort((a, b) => a.fit - b.fit).slice(0, 4));
  return out;
}

const pct = (arr, q) => { if (!arr.length) return NaN; const s = arr.slice().sort((x, y) => x - y); return s[Math.floor(q * (s.length - 1))]; };
const mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : NaN;

function evalFree(surv) {
  const all = [], lens = [], firstOut = [], out45 = [], t6pl = [];
  for (let g = 0; g < CFG.evalLobbies; g++) {
    const { ps, length } = playGame(draw8(surv, CFG.players));
    lens.push(length); firstOut.push(Math.min(...ps.map(p => p.out)));
    t6pl.push(ps.filter(p => p.tier === 6).length);
    for (const p of ps) { all.push(p); if (p.place === 4 || p.place === 5) out45.push(p.out); }
  }
  const n = all.length, ge = k => all.filter(p => p.tier >= k);
  const tt = k => median(all.filter(p => p.tierTurn[k]).map(p => p.tierTurn[k]));
  const by = f => mean(all.filter(f).map(p => p.place));
  const top = all.filter(p => p.place <= 4), bot = all.filter(p => p.place > 4);
  const capDist = { 4: 0, 5: 0, 6: 0 }; surv.forEach(b => capDist[b.cap]++);
  const genes = {}; for (const k of GK) genes[k] = mean(surv.map(b => b[k]));
  return {
    pT4: 100 * ge(4).length / n, pT5: 100 * ge(5).length / n, pT6: 100 * ge(6).length / n,
    tT4: tt(4), tT5: tt(5), tT6: tt(6),
    placeBy: [by(p => p.tier <= 3), by(p => p.tier === 4), by(p => p.tier === 5), by(p => p.tier === 6)],
    t6Top4: 100 * top.filter(p => p.tier === 6).length / top.length, t6Bot4: 100 * bot.filter(p => p.tier === 6).length / bot.length,
    t6PerLobby: mean(t6pl),
    len: [pct(lens, .1), pct(lens, .5), pct(lens, .9)], firstOut: median(firstOut), out45: median(out45),
    econGold: mean(all.map(p => p.econGold)), capDist, genes,
  };
}
function evalStrata(surv) {
  const acc = { 4: [], 5: [], 6: [] };
  for (let g = 0; g < CFG.evalLobbies; g++) {
    const { ps } = playGame(draw8(surv, CFG.players));
    for (const p of ps) acc[p.s.cap].push(p);
  }
  const out = {};
  for (const c of [4, 5, 6]) {
    const a = acc[c], n = a.length, m = mean(a.map(p => p.place));
    out[c] = { place: m, sd: Math.sqrt(mean(a.map(p => (p.place - m) ** 2))), win: 100 * a.filter(p => p.place === 1).length / n, top4: 100 * a.filter(p => p.place <= 4).length / n, b78: 100 * a.filter(p => p.place >= 7).length / n, reach: 100 * a.filter(p => p.tier >= c).length / n };
  }
  const genes = {}; for (const c of [4, 5, 6]) { genes[c] = {}; for (const k of GK) genes[c][k] = mean(surv.filter(b => b.cap === c).map(b => b[k])); }
  return { byCap: out, genes };
}
function rushCheck(surv) {
  const r = [];
  for (let g = 0; g < CFG.rushLobbies; g++) {
    const seats = draw8(surv, 7); seats.push(RUSHER);
    const { ps } = playGame(seats);
    r.push(ps[7].place);
  }
  return mean(r);
}

function runAll() {
  rs = CFG.seed >>> 0;
  const free = evolve('free');
  const F = evalFree(free);
  F.rusher = rushCheck(free);
  const strat = evolve('strata');
  const S = evalStrata(strat);
  return { free: F, strata: S };
}

function selfCheck() {
  rs = CFG.seed >>> 0;
  for (let g = 0; g < 300; g++) {
    const { ps, length } = playGame(Array.from({ length: 8 }, () => newBot()));
    if (length >= 40) throw new Error('game did not end');
    if (ps.map(p => p.place).sort((a, b) => a - b).join() !== '1,2,3,4,5,6,7,8') throw new Error('bad placings');
  }
  return true;
}

function fmt(r) {
  const F = r.free, f1 = x => x.toFixed(1), f2 = x => x.toFixed(2);
  const L = [];
  L.push(`FREE: >=T4 ${f1(F.pT4)}%  >=T5 ${f1(F.pT5)}%  T6 ${f1(F.pT6)}%  T6/lobby ${f2(F.t6PerLobby)}  turns T4/T5/T6 ${F.tT4}/${F.tT5}/${F.tT6}`);
  L.push(`  place by peak (<=3/4/5/6): ${F.placeBy.map(f2).join(' / ')}   T6 share top4/bottom4: ${f1(F.t6Top4)}% / ${f1(F.t6Bot4)}%`);
  L.push(`  game len p10/50/90 ${F.len.join('/')}  first out ${F.firstOut}  out-turn of 4th-5th ${F.out45}  econ gold/player ${f1(F.econGold)}`);
  L.push(`  survivors caps ${JSON.stringify(F.capDist)}  genes ${GK.map(k => k + ' ' + f2(F.genes[k])).join(', ')}`);
  L.push(`  rusher place ${f2(F.rusher)}`);
  L.push('STRATA: cap  place  sd  win%  top4%  7-8%  reachCap%');
  for (const c of [4, 5, 6]) { const s = r.strata.byCap[c]; L.push(`  cap${c}  ${f2(s.place)}  ${f2(s.sd)}  ${f1(s.win)}  ${f1(s.top4)}  ${f1(s.b78)}  ${f1(s.reach)}   genes ${GK.map(k => k + ' ' + f2(r.strata.genes[c][k])).join(', ')}`);
  }
  return L.join('\n');
}

module.exports = { CFG, runAll, selfCheck, fmt, playGame };
if (require.main === module) {
  const over = process.argv[2] ? JSON.parse(process.argv[2]) : {};
  Object.assign(CFG, over);
  const label = process.argv[3] || JSON.stringify(over);
  const t0 = Date.now();
  const r = runAll();
  console.log(`== ${label}  (${((Date.now() - t0) / 1000).toFixed(0)}s)`);
  console.log(fmt(r));
  console.log('RESULT_JSON:' + JSON.stringify({ label, cfg: over, r }));
}
