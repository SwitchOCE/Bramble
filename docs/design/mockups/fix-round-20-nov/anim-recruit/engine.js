// Animation prototypes, fix round 20 Nov, item 11 (outside the fight). PROPOSAL, nothing here is decided.
// The engine: a timeline driven by one clock (so every prototype can loop, slow down, or be frozen at any
// millisecond for a screenshot), the recruit screen drawn from the approved shop mock-up's pieces
// (kit/screen.js geometry, price tags, the coin, keyword marks), and the menu screens from menus.js.
// Loaded after kit/data.js, card.js, stage.js, plates.js, menus.js, kit/kit.js and kit/screen.js.

// ---------------------------------------------------------------- the clock and the timeline
const EASE = {
  out: "cubic-bezier(.2,.8,.2,1)", inout: "cubic-bezier(.45,0,.25,1)", in: "cubic-bezier(.55,0,.9,.45)",
  back: "cubic-bezier(.3,1.55,.5,1)", lin: "linear",
};
const ez = {
  out: u => 1 - Math.pow(1 - u, 3),
  inout: u => u < .5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2,
  in: u => u * u * u,
  // sets off gently and arrives at speed, as the build's let-go flight (card_keeper.gd)
  arrive: u => u * u * (1.6 - .6 * u),
  lin: u => u,
};
const lerp = (a, b, u) => a + (b - a) * u;

class TL {
  constructor() { this.anims = []; this.loops = []; this.calls = []; this.nums = []; this.end = 0; this.state = null; }
  // a Web Animation that starts at t0 (ms) and lasts dur; it holds its last frame after
  a(el, kf, t0, dur, ease = EASE.out, iter = 1) {
    if (!el) return null;
    const an = el.animate(kf, { delay: t0, duration: dur, fill: "forwards", easing: ease, iterations: iter });
    an.pause(); this.anims.push(an); this.end = Math.max(this.end, t0 + dur * iter); return an;
  }
  // an endless ambient loop (a breathing glow); not counted in the length
  loop(el, kf, period, ease = EASE.inout) {
    const an = el.animate(kf, { duration: period, iterations: Infinity, easing: ease, direction: "alternate" });
    an.pause(); this.loops.push(an); return an;
  }
  // a state change at t: fn(true) to apply, fn(false) to undo
  at(t, fn) { this.calls.push({ t, fn }); this.end = Math.max(this.end, t); }
  text(el, value, t) { const old = el.textContent; this.at(t, on => { el.textContent = on ? value : old; }); }
  html(el, value, t) { const old = el.innerHTML; this.at(t, on => { el.innerHTML = on ? value : old; }); }
  cls(el, c, t, add = true) { this.at(t, on => el.classList.toggle(c, add ? on : !on)); }
  // a number that counts from one value to another
  num(el, from, to, t0, dur, fmt = v => String(v)) { this.nums.push({ el, from, to, t0, dur, fmt }); this.end = Math.max(this.end, t0 + dur); }
  seek(t) {
    for (const an of this.anims) an.currentTime = t;
    for (const an of this.loops) an.currentTime = t;
    const st = this.calls.map(c => t >= c.t).join("");
    if (st !== this.state) {
      this.state = st;
      for (let i = this.calls.length - 1; i >= 0; i--) this.calls[i].fn(false);
      for (const c of this.calls) if (t >= c.t) c.fn(true);
    }
    // per element, the latest count that has started (or the first, before any has)
    const by = new Map();
    for (const n of [...this.nums].sort((a, b) => a.t0 - b.t0)) { if (!by.has(n.el) || t >= n.t0) by.set(n.el, n); }
    for (const n of by.values()) {
      const u = Math.max(0, Math.min(1, (t - n.t0) / n.dur));
      n.el.textContent = n.fmt(Math.round(lerp(n.from, n.to, ez.out(u))));
    }
  }
}

// ---------------------------------------------------------------- poses: every moving thing is placed once (its base)
// and moved by transform, so a pose is the place it would be put at {x, y} (top-left), turned r degrees, scaled s.
function put(el, x, y) { el.style.left = x + "px"; el.style.top = y + "px"; el._b = { x, y }; return el; }
function tf(el, p) {
  const b = el._b || { x: 0, y: 0 };
  return `translate(${(p.x - b.x).toFixed(1)}px,${(p.y - b.y).toFixed(1)}px) rotate(${(p.r || 0).toFixed(2)}deg) scale(${(p.s ?? 1).toFixed(3)})`;
}
const P = (x, y, r = 0, s = 1) => ({ x, y, r, s });
function pose0(el, p) { el.style.transform = tf(el, p); el.style.transformOrigin = "50% 50%"; el._p = p; }

// move along a path: a straight or arced flight from one pose to another, sampled so any easing and arc work
function fly(T, el, from, to, t0, dur, o = {}) {
  const n = o.n || 14, e = ez[o.ease || "inout"], kf = [];
  for (let i = 0; i <= n; i++) {
    const u = i / n, k = e(u), arc = (o.lift || 0) * 4 * k * (1 - k);
    const p = { x: lerp(from.x, to.x, k), y: lerp(from.y, to.y, k) - arc, r: lerp(from.r || 0, to.r || 0, k) + (o.lean || 0) * Math.sin(Math.PI * k),
      s: lerp(from.s ?? 1, to.s ?? 1, k) };
    const f = { transform: tf(el, p), offset: u };
    if (o.fade) f.opacity = lerp(o.fade[0], o.fade[1], k);
    kf.push(f);
  }
  return T.a(el, kf, t0, dur, EASE.lin);
}
// keyframes in poses: steps [[ms from t0, pose, opacity?], ...]
function path(T, el, t0, steps, ease = "inout") {
  const dur = steps[steps.length - 1][0], kf = steps.map(([ms, p, o]) => { const f = { transform: tf(el, p), offset: dur ? ms / dur : 0 }; if (o != null) f.opacity = o; return f; });
  return T.a(el, kf, t0, Math.max(dur, 1), EASE[ease]);
}
// the build's hop after a card lands: up 6.4% of its height, swell 1.06, 12 frames (card_keeper.gd)
function hop(T, el, p, t0, h = H) {
  const up = { ...p, y: p.y - 0.064 * h, s: (p.s ?? 1) * 1.06 };
  return T.a(el, [{ transform: tf(el, p) }, { transform: tf(el, up), offset: .45 }, { transform: tf(el, p) }], t0, 200, EASE.inout);
}
// a source lighting up: lifted 14 px with a warm glow (the fight's trigger look, fight_screen.gd), then down
const GLOW = "brightness(1.18) drop-shadow(0 0 6px rgba(255,236,190,.95)) drop-shadow(0 0 22px rgba(255,190,90,.9)) drop-shadow(0 10px 12px rgba(0,0,0,.7))";
const REST = "brightness(1) drop-shadow(0 0 0 rgba(255,236,190,0)) drop-shadow(0 0 0 rgba(255,190,90,0)) drop-shadow(0 6px 8px rgba(0,0,0,.6))";
function fire(T, el, t0, hold = 260, p = el._p || { ...el._b }) {
  const up = { ...p, y: p.y - 14 };
  T.a(el, [{ transform: tf(el, p) }, { transform: tf(el, up), offset: 100 / (hold + 250) }, { transform: tf(el, up), offset: (100 + hold) / (hold + 250) }, { transform: tf(el, p) }], t0, hold + 250, EASE.lin);
  T.a(el, [{ filter: REST }, { filter: GLOW, offset: .2 }, { filter: GLOW, offset: .7 }, { filter: REST }], t0, hold + 250, EASE.lin);
  const z0 = el.style.zIndex; T.at(t0, on => { el.style.zIndex = on ? 8 : z0; });
  const mark = el.querySelector(".kwc.fired");
  if (mark) T.a(mark, [{ transform: "scale(1)" }, { transform: "scale(1.6)", filter: "brightness(1.6)", offset: .3 }, { transform: "scale(1)" }], t0 + 40, 380, EASE.out);
  return t0 + 110;
}
// a number that changes: it pops from 1.5x (card_keeper.gd POP) and turns green when it is above the card's own
function bump(T, numEl, value, t0, up = true) {
  T.text(numEl, String(value), t0);
  if (up) T.cls(numEl, "up", t0);
  T.a(numEl, [{ transform: "translate(-50%,-50%) scale(1.6)" }, { transform: "translate(-50%,-50%) scale(1)" }], t0, 260, EASE.out);
}
const atk = el => el.querySelector(".n-atk"), hp = el => el.querySelector(".n-hp");
// a card's numbers and marks as the timeline has left them, so effects in a row add up
function model(el) { if (!el._m) el._m = { a: +atk(el).textContent, h: +hp(el).textContent, pills: [...(el._pills || [])] }; return el._m; }
function gain(T, el, da, dh, t) { const m = model(el); if (da) { m.a += da; bump(T, atk(el), m.a, t); } if (dh) { m.h += dh; bump(T, hp(el), m.h, t); } }
function marks(T, el, pills, t) {
  const m = model(el), before = m.pills; m.pills = pills;
  T.at(t, on => cardMarks(el, on ? pills : before, H, "border"));
}
// a slot gains Renown: its pill pops to the new number (appearing if the slot had none), and the unit standing
// there shows it in its numbers, +1/+1 a point, as dev's recruit board does (rulebook 11.7.7)
function addRenown(T, h, i, n, t) {
  const now = (h.rn[i] || 0) + n; h.rn[i] = now;
  let el = h.renown[i];
  if (!el) { el = renownEl(h.st, i, now); el.style.opacity = 0; h.renown[i] = el; T.a(el, [{ opacity: 0 }, { opacity: 1 }], t, 60, EASE.lin); }
  T.text(el.querySelector("b"), String(now), t);
  T.a(el, [{ transform: "scale(1.7)", filter: "brightness(1.5)" }, { transform: "scale(1)", filter: "brightness(1)" }], t, 320, EASE.out);
  if (h.board[i]) gain(T, h.board[i], n, n, t + 20);
}
// a Charge or Supply pip is used: it flashes, then dims (card_pips.gd: a spent pip at 40%)
function spendPip(T, el, kind, t) {
  const left = [...el.querySelectorAll(".pip." + kind + ":not(.spent)")], p = left[left.length - 1]; if (!p) return;
  p.classList.add("spent");
  T.a(p, [{ opacity: 1, transform: "scale(1)", filter: "brightness(1)" }, { opacity: 1, transform: "scale(1.8)", filter: "brightness(1.6)", offset: .3 }, { opacity: .4, transform: "scale(1)", filter: "brightness(1)" }], t, 360, EASE.out);
}
// a ring of light where something lands
function ring(T, st, cx, cy, t0, r = 60, colour = "255,214,120") {
  const el = add(st, `<div class="fxring" style="opacity:0;width:${2 * r}px;height:${2 * r}px;border-color:rgba(${colour},.95);box-shadow:0 0 18px rgba(${colour},.8),inset 0 0 14px rgba(${colour},.6)"></div>`, cx - r, cy - r);
  T.a(el, [{ transform: "scale(.3)", opacity: 0 }, { transform: "scale(.6)", opacity: 1, offset: .25 }, { transform: "scale(1.3)", opacity: 0 }], t0, 380, EASE.out);
  return el;
}
function add(st, s, x, y) { const el = html(s); st.append(el); return put(el, x, y); }
function show(T, el, t0, dur = 120, from = 0, to = 1) { T.a(el, [{ opacity: from }, { opacity: to }], t0, dur, EASE.out); }

// ---------------------------------------------------------------- flying gains
// a gain in coloured glass: green for stats, amber for gold; the words are its amount
function gainPill(st, words, kind = "stat") { return add(st, `<div class="gain ${kind}">${words}</div>`, -999, -999); }
function coinEl(st, n, size = 54) {
  return add(st, `<div class="fxcoin" style="width:${size}px;height:${size}px">${COIN.replace('class="coin"', 'class="coin" style="width:100%;height:100%"')}${n ? `<b>${n}</b>` : ""}</div>`, -999, -999);
}
// a gold star with the Renown it carries (+2), flying to a slot's Renown pill
function starEl(st, words) {
  return add(st, `<div class="fxstar"><i><svg viewBox="0 0 24 24">${IC.star}</svg></i>${words ? `<em>${words}</em>` : ""}</div>`, -999, -999);
}
// a gain that flies from (x0, y0) to (x1, y1) (centres), then bursts there
function gainFly(T, st, el, c0, c1, t0, dur = 380, o = {}) {
  const w = el.offsetWidth || o.w || 0, hh = el.offsetHeight || o.h || 0;
  put(el, c1.x - w / 2, c1.y - hh / 2);
  el.style.opacity = 0;
  T.a(el, [{ opacity: 0 }, { opacity: 1 }], t0, 60, EASE.lin);
  fly(T, el, P(c0.x - w / 2, c0.y - hh / 2, 0, o.s0 ?? .6), P(c1.x - w / 2, c1.y - hh / 2, 0, o.s1 ?? 1), t0, dur, { lift: o.lift ?? 60, ease: o.ease || "inout" });
  if (!o.keep) T.a(el, [{ opacity: 1 }, { opacity: 0 }], t0 + dur + (o.linger || 60), 140, EASE.lin);
  if (o.ring !== false) ring(T, st, c1.x, c1.y, t0 + dur - 30, o.ringR || 54, o.colour);
  return t0 + dur;
}
const centre = (el, dy = 0) => { const p = el._p || el._b; return { x: p.x + el.offsetWidth / 2, y: p.y + el.offsetHeight / 2 + dy }; };
const statsAt = el => { const p = el._p || el._b; return { x: p.x + W / 2, y: p.y + 0.778 * H }; };

// ---------------------------------------------------------------- the pointer
function pointer(st) { const el = add(st, POINTER, 0, 0); el.style.opacity = 0; el.style.zIndex = 40; return el; }
function ptrMove(T, el, a, b, t0, dur, ease = "inout") {
  if (!el._shown) { el._shown = true; T.a(el, [{ opacity: 0 }, { opacity: 1 }], Math.max(0, t0 - 120), 120, EASE.lin); }
  fly(T, el, P(a.x, a.y), P(b.x, b.y), t0, dur, { ease });
  el._last = b; return t0 + dur;
}
function ptrPress(T, el, at, t0) {
  T.a(el, [{ transform: tf(el, P(at.x, at.y, 0, 1)) }, { transform: tf(el, P(at.x, at.y + 3, 0, .82)), offset: .4 }, { transform: tf(el, P(at.x, at.y, 0, 1)) }], t0, 180, EASE.inout);
  return t0 + 180;
}
function ptrHide(T, el, t0) { T.a(el, [{ opacity: 1 }, { opacity: 0 }], t0, 160, EASE.lin); el._shown = false; el._last = null; }

// carry: pressed, the card lifts 1.2x in 9 frames and rises 35 px (card_carry.gd), then follows the pointer, leaning
// toward its travel; returns the time it is let go. The pointer grips it at its middle.
function carry(T, st, el, from, to, t0, dur = 520, ptr) {
  const lift = { ...from, y: from.y - 35, s: 1.2, r: 0 }, end = { ...to, s: 1.2, r: 0 };
  const lean = Math.max(-9, Math.min(9, (to.x - from.x) / 60));
  const z0 = el.style.zIndex; T.at(t0, on => { el.style.zIndex = on ? 30 : z0; });
  path(T, el, t0, [[0, from], [150, lift]], "out");
  fly(T, el, lift, end, t0 + 150, dur, { lean, ease: "inout" });
  T.a(el, [{ filter: REST }, { filter: "brightness(1.06) drop-shadow(0 0 14px rgba(255,236,190,.5)) drop-shadow(0 22px 18px rgba(0,0,0,.55))" }], t0, 150, EASE.out);
  if (ptr) {
    const g = { x: W / 2 - 4, y: H * 0.45 };
    const a = { x: from.x + g.x, y: from.y + g.y };
    ptrMove(T, ptr, ptr._shown && ptr._last ? ptr._last : { x: a.x + 120, y: Math.min(a.y + 90, 1040) }, a, t0 - 360, 340);
    ptrPress(T, ptr, a, t0 - 10);
    ptrMove(T, ptr, a, { x: lift.x + g.x, y: lift.y + g.y }, t0, 150, "out");
    ptrMove(T, ptr, { x: lift.x + g.x, y: lift.y + g.y }, { x: end.x + g.x, y: end.y + g.y }, t0 + 150, dur);
  }
  return t0 + 150 + dur;
}
// let go over its place: drops in (shrinks back, straightens) in 4-6 frames, then hops (card_keeper.gd)
function drop(T, el, to, t0) {
  path(T, el, t0, [[0, { ...to, s: 1.2 }], [90, to]], "in");
  T.a(el, [{ filter: "brightness(1.06) drop-shadow(0 0 14px rgba(255,236,190,.5)) drop-shadow(0 22px 18px rgba(0,0,0,.55))" }, { filter: REST }], t0, 90, EASE.in);
  hop(T, el, to, t0 + 90);
  T.at(t0 + 290, on => { el.style.zIndex = on ? 2 : 30; });
  el._p = to;
  return t0 + 290;
}

// ---------------------------------------------------------------- cards
const SPELLS = {
  sharpen: { id: "sp_sharpen", name: "Sharpen", tier: 1, cost: 1, art: "assets/art/spell-1.jpg", spell: true },
  seek: { id: "sp_seek", name: "Seek", tier: 2, cost: 3, art: "assets/art/spell-2.jpg", spell: true },
  // dev draws the Triple Reward with the stand-in spell art spell-1 (game_content.gd)
  reward: { id: "triple_reward", name: "Triple Reward", tier: 1, cost: 0, art: "assets/art/spell-1.jpg", spell: true },
};
// a unit by its id, from dev's card data (dev-cards.js), with its keyword marks; x overrides any field.
// It costs its tier + 1 (dev). A dev card with no art yet shows a plain glass panel, as the build's stand-in does.
function C(id, x = {}) {
  const c = BY_ID[id];
  if (!c) throw new Error("no dev card " + id);
  return { id, name: c.name, tier: c.tier, art: c.noArt ? "assets/ui/pane.jpg" : unitArt(id), attack: c.attack, health: c.health,
    pills: pillsFromText(fillText(c)), text: fillText(c), price: c.tier + 1, ...x };
}
function mk(c, h = H) {
  let el;
  if (c.spell) {
    el = Cards.make({ ...c, spell: "hex", h: G.SH * h / H, aspect: G.SW / G.SH, shoulder: G.SS, cost: null });
    const k = html(`<div class="hang" style="left:-14px;top:${(G.SH * h / H * 0.16).toFixed(1)}px">${coinN(c.cost)}</div>`);
    k.querySelector("svg").style.cssText = `width:${44 * h / H}px;height:${44 * h / H}px`;
    el.append(k);
  } else {
    el = Cards.make({ ...c, h });
    cardMarks(el, c.pills, h, "border"); el._pills = c.pills || [];
    cardPips(el, c.text, h, c.tier, c.spent || {});
    if (c.fired) el.querySelectorAll(".kwc").forEach(m => { if (m.title === c.fired) m.classList.add("fired"); });
    if (c.golden) el.append(html(`<svg class="gold-rim" viewBox="0 0 560 1000" preserveAspectRatio="none"><polygon points="280,8 552,174 552,826 280,992 8,826 8,174"/></svg>`));
    if (c.upA) atk(el).classList.add("up");
    if (c.upH) hp(el).classList.add("up");
  }
  el.style.zIndex = 2;
  return el;
}

// ---------------------------------------------------------------- the recruit screen (geometry: kit/screen.js geom with hanging tags, as the build)
const G = geom(54);
const FW = 4 * W + 3 * G.g, FX = 960 - FW / 2, BACK = G.boardTop + 0.83 * H + 8;
const slotXY = i => i < 4 ? [FX + i * (W + G.g), G.boardTop] : [FX + (W + G.g) / 2 + (i - 4) * (W + G.g), BACK];
const shopXY = i => [G.shopL + i * (W + G.g), G.shopTop];
const spellXY = k => [G.shopL + (k + 2) * (W + G.g) - G.g / 2 - G.SW / 2, G.shopTop + 0.17 * H - 8 - G.SH];
const handPose = (i, N) => { const k = i - (N - 1) / 2; return P(960 - W / 2 + k * W * 0.74, G.handTop + k * k * 4, k * 2.5); };
const BW = 176, BXL = G.shopL - 20 - BW, BXR = G.shopL + G.shopW + 20, BY1 = G.shopTop + H / 2 - 78, BY2 = BY1 + 84;
const GOLDC = { x: BXL + 46, y: BY1 + 34 };            // the gold coin on the gold button
const WAIT = { x: 1400, y: G.handTop - 50 };          // PROPOSED: the waiting stack, right of the hand (its top-left as drawn, 0.7x)
const WS = .7, waitPose = n => P(WAIT.x - W * (1 - WS) / 2 + n * 10, WAIT.y - H * (1 - WS) / 2 - n * 6, 8, WS);
let UID = 0;
function stoneU(g) { const u = "s" + (++UID); return stone(g).replace(/id="(st|sillg|op)"/g, `id="$1${u}"`).replace(/url\(#(st|sillg|op)\)/g, `url(#$1${u})`); }

function base(over = {}) {
  return {
    turn: 6, gold: 9, tier: 3, up: 7, refresh: 1, left: 7, next: 16, hp: 34, frozen: false, limit: 7,
    shop: [C("brock-cub"), C("famine-caller"), C("needle-page"), C("pip"), C("hedge-knight")],
    spells: [SPELLS.sharpen, SPELLS.seek],
    board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"),
      C("padre"), C("relic-seeker"), null, C("horde-runner")],
    // Renown on each slot (dev): Old Campaigner's slot has 1 from an earlier fight
    renown: [0, 0, 1, 0, 0, 0, 0],
    hand: [C("lance-corporal"), C("master-at-arms"), C("sett-shield-bearer")],
    waiting: [], plates: [], opp: "march_hare", oppHp: 40, cutL: 0,
    ...over,
  };
}

// draws the recruit screen into a layer; returns handles to everything a prototype moves
function recruit(st, s) {
  st.insertAdjacentHTML("beforeend", `<div id="field"></div><div id="light"></div>` + stoneU(G));
  const h = { st, s, shop: [], spells: [], board: [], slots: [], hand: [], tags: [], waiting: [] };
  s.shop.forEach((c, i) => {
    const [x, y] = shopXY(i);
    if (!c) { h.shop.push(null); h.tags.push(null); return; }
    const el = mk(c); st.append(put(el, x, y)); pose0(el, P(x, y)); h.shop.push(el);
    const t = html(`<div class="a" style="z-index:3;width:44px;height:68px"><svg class="a" width="4" height="14" style="left:20px;top:0;overflow:visible"><path d="M2,0 V14" stroke="#16120e" stroke-width="3"/><circle cx="2" cy="1" r="3" fill="#16120e"/></svg><div class="hang" style="left:0;top:11px">${coinN(c.price ?? 3, (c.price ?? 3) > s.gold)}</div></div>`);
    st.append(put(t, x + W / 2 - 22, y + H - 1)); h.tags.push(t);
    if (s.frozen) el.append(ice());
    if (c.dupe) el.classList.add(c.dupe === 2 ? "glowtri" : "dupe1");
  });
  s.spells.forEach((c, k) => { const [x, y] = spellXY(k); const el = mk(c); st.append(put(el, x, y)); pose0(el, P(x, y)); h.spells.push(el); if (s.frozen) el.append(ice(true)); });
  // the shop's buttons, as the approved shop mock-up and the build draw them
  const ic = p => p.replace("<svg ", '<svg class="ic" ');
  h.goldBtn = add(st, `<div class="btn gold sbtn" style="width:${BW}px"><span style="font-size:40px;display:flex">${COIN}</span><b style="font-size:34px">${s.gold}</b></div>`, BXL, BY1);
  h.gold = h.goldBtn.querySelector("b");
  h.tierBtn = add(st, `<div class="btn sbtn" style="width:${BW}px"><div class="tl"><small>Tier up</small><span>${s.tier} → ${s.tier + 1}</span></div>${coinN(s.up, s.up > s.gold)}</div>`, BXL, BY2);
  h.refBtn = add(st, `<div class="btn sbtn" style="width:${BW}px">${ic(ICON.refresh)}${coinN(s.refresh, s.refresh > s.gold)}</div>`, BXR, BY1);
  h.left = add(st, `<div class="rleft" style="width:${BW}px">${s.left} left at this price</div>`, BXR, BY1 - 30);
  h.frzBtn = add(st, `<div class="btn freeze sbtn" style="width:${BW}px">${ICON.freeze}</div>`, BXR, BY2);
  if (s.frozen) h.frzBtn.append(ice(false, true));
  // the board: every slot's pane, then its unit (showing its slot's Renown in its numbers), then the Renown pill
  h.rn = [...(s.renown || [])]; h.renown = [];
  for (let i = 0; i < 7; i++) {
    const [x, y] = slotXY(i), rn = h.rn[i] || 0;
    h.slots.push(add(st, `<div class="slot" style="width:${W}px;height:${H}px"></div>`, x, y));
    if (rn) h.renown[i] = renownEl(st, i, rn);
    const c = s.board[i];
    if (!c) { h.board.push(null); continue; }
    const el = mk(rn ? { ...c, attack: c.attack + rn, health: c.health + rn, upA: 1, upH: 1 } : c); st.append(put(el, x, y)); pose0(el, P(x, y)); h.board.push(el);
    if (c.dupe) el.classList.add(c.dupe === 2 ? "glowtri" : "dupe1");
  }
  // the hand: a fan whose tops show above the sill
  const N = s.hand.length;
  s.hand.forEach((c, i) => {
    const p = handPose(i, N), el = mk(c);
    st.append(put(el, p.x, p.y)); pose0(el, p); el.style.zIndex = 4 + i; h.hand.push(el);
    if (c.dupe) el.classList.add(c.dupe === 2 ? "glowtri" : "dupe1");
  });
  h.handLbl = add(st, `<div class="lbl" style="font-size:22px;color:#cfd8de">Hand <span>${N}</span>/${s.limit}</div>`, 960 - (W * .74 * Math.max(N - 1, 0) + W) / 2 - 150, G.handTop + 40);
  h.handN = h.handLbl.querySelector("span");
  // PROPOSED: cards that don't fit wait in a small stack right of the hand
  h.waitBadge = add(st, `<div class="waitn">${s.waiting.length}</div>`, WAIT.x + W * WS - 4, WAIT.y - 10);
  if (!s.waiting.length) h.waitBadge.style.opacity = 0;
  s.waiting.forEach((c, i) => { const p = waitPose(i), el = mk(c); st.append(put(el, p.x, p.y)); pose0(el, p); el.style.zIndex = 3; h.waiting.push(el); });
  // left light: cog, turn, plates, hero; right light: Cards, End turn
  h.cog = add(st, `<div class="btn" style="width:${COG.side}px;z-index:9">${COG_ICON}</div>`, COG.x, COG.y);
  h.turn = add(st, `<div class="lbl">Turn <span>${s.turn}</span></div>`, 54, 150);
  s.plates.forEach(([icon, name, v], i) => {
    const el = add(st, `<div class="cnt${icon ? "" : " bare"}">${icon ? `<i style="background-image:url(assets/ui/tr-${icon}.png)"></i>` : ""}<span>${name}</span><b>${v}</b></div>`, 40, 1080 - 188 - 56 - i * 54);
    (h.plates = h.plates || []).push(el);
  });
  add(st, `<div class="lbl" style="font-size:22px">Dame Farthing</div>`, 40, 1080 - 188);
  h.hero = add(st, `<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/dame_farthing.jpg)"></div>`, 40, 1080 - 150);
  h.hp = add(st, `<div class="hp">${s.hp}</div>`, 118, 1080 - 66);
  h.nextPl = add(st, `<div class="cnt bare nextpl"><span>Next turn</span><b>+${s.next}</b>${COIN}</div>`, 200, 966);
  h.cards = add(st, `<div class="cardsbtn"><div class="btn">${CARDS_ICON}</div><div class="lbl">Cards</div></div>`, 1920 - 123 - 34, 64);
  const eX = 1904 - 16 - 128 - 26;
  add(st, `<div class="lbl endlbl" style="font-size:22px">End turn</div>`, eX - 6, 1080 - 188);
  h.end = add(st, `<div class="port endturn" style="width:128px;height:128px;background-image:url(assets/portraits/${s.opp}.jpg)"></div>`, eX, 1080 - 150);
  add(st, `<div class="hp">${s.oppHp}</div>`, eX - 12, 1080 - 66);
  h.msg = add(st, `<div class="lbl msg" style="opacity:0"></div>`, 0, 0);
  st.append(html(`<div id="vig"></div>`));
  h.ptr = pointer(st);
  return h;
}
// a slot's Renown pill, centred on the top of the slot, over the unit there (dev: recruit_board.gd _add_renown)
function renownEl(st, i, n) {
  const [x, y] = slotXY(i), el = renownPill(n, H); st.append(el);
  return put(el, x + (W - el.offsetWidth) / 2, y - 4);
}
// a word line on the transom, centred
function message(T, h, words, t0, hold = 1500) {
  h.msg.textContent = words;
  put(h.msg, 960 - h.msg.offsetWidth / 2, (G.T0 + G.T1) / 2 - h.msg.offsetHeight / 2);
  T.a(h.msg, [{ opacity: 0, transform: "translateY(6px)" }, { opacity: 1, transform: "translateY(0)" }], t0, 160, EASE.out);
  T.a(h.msg, [{ opacity: 1 }, { opacity: 0 }], t0 + 160 + hold, 300, EASE.lin);
}
// frozen ice on a card or button (stand-ins.html's look)
function ice(spell = false, pill = false) {
  if (pill) return html(`<svg class="ice-o" viewBox="0 0 176 68" preserveAspectRatio="none" style="inset:-4px"><rect x="2" y="2" width="172" height="64" rx="32"/></svg>`);
  const pts = spell ? `280,0 560,${1000 * G.SS} 560,${1000 - 1000 * G.SS} 280,1000 0,${1000 - 1000 * G.SS} 0,${1000 * G.SS}` : "280,0 560,170 560,830 280,1000 0,830 0,170";
  return html(`<svg class="ice-o" viewBox="0 0 560 1000" preserveAspectRatio="none"><polygon points="${pts}"/><path d="M120,300 L230,420 L200,560 M380,240 L330,420 L430,600 M240,700 L330,780" class="crack"/></svg>`);
}
// lit slot rim (recruit-play.html's lit look), above the slot, below cards
function litSlot(st, i, z = 1) {
  const [x, y] = slotXY(i), p = hexPts(W, H, .17).map(q => q.join(",")).join(" ");
  const el = add(st, `<svg class="lit" width="${W}" height="${H}" style="z-index:${z}"><polygon points="${p}"/><polygon class="glow" points="${p}"/><polygon class="edge" points="${p}"/></svg>`, x, y);
  el.style.opacity = 0; return el;
}
const hexPts = (w, h, s) => [[w / 2, 0], [w, s * h], [w, h - s * h], [w / 2, h], [0, h - s * h], [0, s * h]];
// the hand fan re-spacing: each card to its place in a hand of N
function refan(T, els, N, t0, dur = 200, skip = -1) {
  els.forEach((el, i) => { if (!el || i === skip) return; const to = handPose(i, N); fly(T, el, el._p, to, t0, dur, { ease: "out", n: 6 }); el._p = to; });
}

// ---------------------------------------------------------------- the menu screens (menus.js and start.html, result.html, pause.html)
function backdropU(st) { st.insertAdjacentHTML("beforeend", `<div id="field"></div><div id="light"></div>` + stoneU(FIGHT_G)); }
function paneEl(st, x, y, w, hh) { return add(st, `<div id="lbpane" style="width:${w}px;height:${hh}px"></div>`, x, y); }
function startScreen(st) {
  backdropU(st);
  const h = { st, parts: [] };
  h.pane = paneEl(st, 580, 200, 760, 720);
  h.parts.push(title(st, "Bramble", 960, 228, 84), title(st, "A game against seven bots", 960, 338, 24, "#c9bda6"));
  const row = html(`<div class="a" style="left:0;top:0"></div>`); st.append(row);
  PLAYERS.forEach(([p], i) => port(row, p, 701 + i * 66, 392, 56, i === 0));
  h.parts.push(row, title(st, "You", 729, 450, 16, "#c9bda6"), title(st, "Tribes in the lobby", 960, 480, 22, "#c9bda6"));
  h.tribes = [["Badgers", true], ["Mice", true], ["Pigeons", true], ["Locusts", false], ["Briars", true]].map(([t, on], i) => {
    const b = button(st, t, 614 + i * 140, 516, 132); b.classList.add("tribe"); b._b = { x: 614 + i * 140, y: 516 };
    b.append(html(`<i class="strike"></i>`)); if (!on) b.classList.add("off");
    const o = title(st, "Only", 614 + i * 140 + 66, 584, 18); o.classList.add("only");
    return { b, o, on };
  });
  h.play = button(st, "Play", 810, 660, 300); h.quit = button(st, "Quit", 810, 740, 300);
  st.append(html(`<div id="vig"></div>`));
  h.ptr = pointer(st);
  return h;
}
function resultScreen(st, rank = 3) {
  backdropU(st);
  const h = { st, rows: [] };
  h.pane = paneEl(st, 560, 90, 800, 900);
  h.title = title(st, `You placed ${rank}${["st", "nd", "rd"][rank - 1] || "th"}`, 960, 125, 56);
  h.sub = title(st, "Round 14", 960, 200, 22, "#c9bda6");
  const ORDER = [2, 4, 0, 1, 3, 5, 6, 7], HPS = [12, 0, 0, 0, 0, 0, 0, 0];
  ORDER.forEach((who, i) => {
    const y = 250 + i * 74, you = who === 0;
    const row = html(`<div class="a" style="left:0;top:0;width:1920px;height:1080px;pointer-events:none"></div>`); st.append(row);
    const pl = html(`<div class="lb"><div class="pl">${i + 1}</div></div>`); row.append(pl); place(pl.firstChild, 636, y + 20);
    port(row, PLAYERS[who][0], 680, y, 60, you);
    row.append(place(html(`<div class="lbl" style="font-size:28px${you ? ";color:var(--go)" : ""}">${PLAYERS[who][1]}</div>`), 764, y + 12));
    const hpEl = html(`<div class="lb"><div class="hp">${HPS[i]}</div></div>`); row.append(hpEl); place(hpEl.firstChild, 1240, y + 14);
    h.rows.push({ row, you, y });
  });
  h.btns = [button(st, "Play again", 600, 880, 240), button(st, "Start screen", 840, 880, 240), button(st, "Quit", 1080, 880, 240)];
  st.append(html(`<div id="vig"></div>`));
  return h;
}
function layer(st, z = 0) { const el = html(`<div class="layer" style="z-index:${z}"></div>`); st.append(el); return el; }
