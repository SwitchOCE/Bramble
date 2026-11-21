// Fight animation prototypes (fix round, 20 Nov 2026, item 11). PROPOSAL, nothing here is decided.
// A small timeline engine on the Web Animations API: every motion is a paused animation with its own
// delay, and the page seeks them all to one time each frame. That makes loops, quarter speed and
// frozen key frames (?event=…&t=…) all the same code. The fight screen is fight.html's: card height
// 250, 4 front and 3 back slots staggered like bricks, the stone window, the heroes in the side lights.
// Needs (through <base>): card.js, stage.js, plates.js, ../../design/mockups/kit/{data,kit}.js.

const H = 250, W = H * 0.56, GAP = 12;
const BY = {}; ALL_CARDS.forEach(c => BY[c.id] = c);

function fightGeom() {
  const boardH = H + 0.83 * H + 8, oppTop = 50, oppBot = oppTop + boardH;
  const T0 = oppBot + 14, T1 = T0 + 16, boardTop = T1 + 14, boardBot = boardTop + boardH, sill = boardBot + 14;
  const sideW = 214, cL = 16 + sideW + 24, cR = 1904 - sideW - 24;
  return { H, W, g: GAP, ys: 90, oppTop, oppBot, T0, T1, boardTop, boardBot, sill, cL, cR, sideW };
}
// the recruit screen's geometry (recruit-tribes.html), for the move into the fight
function recruitGeom() {
  const g = GAP, roof = 0.17 * H, edge = Math.hypot(W / 2, roof), SH = 2 * roof + edge;
  let handShow = 0.7 * H;
  const top0 = 1080 - handShow - 14 - 14 - (1.83 * H + 8) - 14 - 16 - 14 - H + 0.17 * H - 8 - SH;
  if (top0 < 48) handShow = Math.max(0.4 * H, handShow - (48 - top0));
  const handTop = 1080 - handShow, sill = handTop - 14;
  const boardH = H + 0.83 * H + 8, boardBot = sill - 14, boardTop = boardBot - boardH;
  const T1 = boardTop - 14, T0 = T1 - 16, shopBot = T0 - 14, shopTop = shopBot - H;
  const shopW = 5 * W + 4 * g, shopL = 960 - shopW / 2;
  const sideW = 214, cL = 16 + sideW + 24, cR = 1904 - sideW - 24, ys = Math.max(shopTop + 30, 90);
  return { H, W, g, ys, handTop, sill, boardTop, boardBot, T0, T1, shopTop, shopBot, shopL, shopW, cL, cR, sideW };
}
const FG = fightGeom(), RG = recruitGeom();
const FX = 960 - (4 * W + 3 * GAP) / 2, ROWD = 0.83 * H + 8;
const slotX = i => i < 4 ? FX + i * (W + GAP) : FX + (W + GAP) / 2 + (i - 4) * (W + GAP);
const slotY = (side, i) => side === "you" ? (i < 4 ? FG.boardTop : FG.boardTop + ROWD) : (i < 4 ? FG.oppTop + ROWD : FG.oppTop);
const OPP_X = 1904 - FG.sideW / 2 - 64;           // the opponent's portrait, top of the right light
const HERO = { you: { x: 40, y: 1080 - 150, s: 128 }, opp: { x: OPP_X, y: 96, s: 128 } };

// filters: the same function list everywhere so they interpolate (fight.html .card.lunge is the glow)
const F_BASE = "brightness(1) drop-shadow(0px 0px 0px rgba(255,214,140,0)) drop-shadow(0px 6px 8px rgba(0,0,0,.6))";
const F_GLOW = "brightness(1.12) drop-shadow(0px 0px 14px rgba(255,214,140,.7)) drop-shadow(0px 10px 12px rgba(0,0,0,.7))";
const F_HIT = "brightness(1.6) drop-shadow(0px 0px 6px rgba(255,120,90,.6)) drop-shadow(0px 6px 8px rgba(0,0,0,.6))";
const F_BLOCK = "brightness(1.35) drop-shadow(0px 0px 14px rgba(150,200,255,.9)) drop-shadow(0px 6px 8px rgba(0,0,0,.6))";
const FAM = { strike: ["#c8442c", "#ffb7a4"], ward: ["#d9a633", "#ffe7a6"], growth: ["#4f9a3a", "#c8f2a6"], kin: ["#8457c4", "#e1ccff"],
  shop: ["#2f88a8", "#bfe9f7"], count: ["#7d8a99", "#e2e8ee"] };

// the current build's motion numbers (src/screens/fight/fight_motion.gd), in ms
const M = { windup: 67, travel: 133, hold: 33, back: 183, recoil: 50, contact: 0.62 * H, death: 250, burst: 543 };

let UID = 0;
function uniqueIds(s) { const u = "_" + (++UID); return s.replace(/id="(\w+)"/g, `id="$1${u}"`).replace(/url\(#(\w+)\)/g, `url(#$1${u})`); }
const v2 = (x, y) => ({ x, y });
const sub = (a, b) => v2(a.x - b.x, a.y - b.y), len = a => Math.hypot(a.x, a.y);
const norm = a => { const l = len(a) || 1; return v2(a.x / l, a.y / l); };
const px = (a) => `${a.x.toFixed(1)}px ${a.y.toFixed(1)}px`;

// a unit's marks from its card text (the build's rule: a keyword that starts a sentence), unless given.
// Cards are dev's (dev-cards.js). spec.renown: the Renown the unit carries in the fight, shown on its own pill;
// spec.pipsSpent: {charge: n} pips already used this fight.
function unitSpec(s) {
  if (typeof s === "string") s = { id: s };
  const c = BY[s.id];
  if (!c) throw new Error("no dev card " + s.id);
  const marks = s.marks || pillsFromText(fillText(c));
  return { ...s, c, tier: s.tier || c.tier, atk: s.atk ?? c.attack, hp: s.hp ?? c.health, max: s.max ?? s.hp ?? c.health, marks };
}

class Proto {
  constructor(stage) {
    this.st = stage; this.anims = []; this.end = 0; this.u = { you: [], opp: [] }; this.warp = null;
    this.svg = null;
  }
  // ---------------- drawing ----------------
  window(G = FG, field = true) {
    if (field) this.st.insertAdjacentHTML("beforeend", `<div id="field"></div><div id="light"></div>`);
    const d = html(`<div class="stonewrap" style="position:absolute;inset:0">${uniqueIds(stone(G))}</div>`);
    this.st.append(d); return d;
  }
  layer() { const l = html(`<div class="layer" style="position:absolute;inset:0;pointer-events:none"></div>`); this.st.append(l); return l; }
  card(spec, x, y, parent = this.st) {
    const s = unitSpec(spec);
    const el = Cards.make({ tier: s.tier, art: s.c.noArt ? "assets/ui/pane.jpg" : `units/${s.c.tribe}/${s.c.id}.jpg`, attack: s.atk, health: s.hp, hurt: s.hp < s.max, h: H });
    el.style.filter = F_BASE;
    cardMarks(el, s.marks, H, "border");
    cardPips(el, fillText(s.c), H, s.tier, s.pipsSpent || {});
    (s.spent || []).forEach(n => { const m = el.querySelector(`.kwc[title="${n}"]`); if (m) m.style.opacity = .4; });
    if (s.up) s.up.forEach(k => el.querySelector(k === "atk" ? ".n-atk" : ".n-hp").classList.add("up"));
    parent.append(place(el, x, y));
    if (s.renown) { const r = renownPill(s.renown, H); el.append(r); r.style.left = ((W - r.offsetWidth) / 2).toFixed(1) + "px"; r.style.top = "-4px"; }
    const U = { el, s, x, y, cx: x + W / 2, cy: y + H / 2, atk: s.atk, hp: s.hp, max: s.max,
      n: { atk: el.querySelector(".n-atk"), hp: el.querySelector(".n-hp") } };
    if (s.hidden) el.style.opacity = 0;
    return U;
  }
  board(side, list) {
    this.slots = this.slots || { you: [], opp: [] };
    list.forEach((s, i) => {
      const x = slotX(i), y = slotY(side, i);
      const sl = place(slotEl(FG, false), x, y); this.st.append(sl); this.slots[side][i] = sl;
      if (s) { const U = this.card(s, x, y); U.side = side; U.slot = i; this.u[side][i] = U; }
    });
  }
  // add a unit to a slot later (a summon, Reserve): hidden until animated in
  later(side, i, spec) {
    const U = this.card({ ...(typeof spec === "string" ? { id: spec } : spec), hidden: true }, slotX(i), slotY(side, i));
    U.side = side; U.slot = i; return U;
  }
  heroes(o = {}) {
    const st = this.st, you = o.you || {}, opp = o.opp || {};
    st.append(place(html(`<div class="lbl">${o.turn || "Turn 7"}</div>`), 54, 150));
    st.append(place(html(`<div class="lbl" style="font-size:22px">${you.name || "Dame Farthing"}</div>`), 40, 1080 - 188));
    this.youPort = place(html(`<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/${you.p || "dame_farthing"}.jpg)"></div>`), HERO.you.x, HERO.you.y);
    st.append(this.youPort);
    this.youHp = place(html(`<div class="hp">${you.hp ?? 34}</div>`), 118, 1080 - 66); st.append(this.youHp);
    this.plates = {};
    (you.plates || []).forEach(([icon, name, v], i) => {
      const el = html(`<div class="cnt${icon ? "" : " bare"}">${icon ? `<i style="background-image:url(assets/ui/tr-${icon}.png)"></i>` : ""}<span>${name}</span><b>${v}</b></div>`);
      st.append(place(el, 40, 1080 - 188 - 56 - i * 54)); this.plates[name] = { el, v, b: el.querySelector("b") };
    });
    if (opp.hidden) return;
    this.oppPort = place(html(`<div class="port opphero" style="width:128px;height:128px;background-image:url(assets/portraits/${opp.p || "brother_bracken"}.jpg)"></div>`), OPP_X, 96);
    st.append(this.oppPort);
    this.oppHp = place(html(`<div class="hp">${opp.hp ?? 36}</div>`), OPP_X + 78, 180); st.append(this.oppHp);
    this.oppName = place(html(`<div class="lbl oppname" style="font-size:22px">${opp.name || "Brother Bracken"}</div>`), OPP_X - 30, 238);
    st.append(this.oppName);
    (opp.plates || []).forEach(([icon, name, v], i) => {
      const el = html(`<div class="cnt${icon ? "" : " bare"}">${icon ? `<i style="background-image:url(assets/ui/tr-${icon}.png)"></i>` : ""}<span>${name}</span><b>${v}</b></div>`);
      st.append(place(el, 1904 - 200, 288 + i * 54)); this.plates["opp " + name] = { el, v, b: el.querySelector("b") };
    });
  }
  vignette() { this.st.append(html(`<div id="vig"></div>`)); }
  fx() { if (!this.fxl) { this.fxl = this.layer(); this.fxl.style.zIndex = 20; } return this.fxl; }
  svgLayer() {
    if (!this.svg) {
      this.svg = html(`<svg class="fxsvg" width="1920" height="1080" viewBox="0 0 1920 1080" style="position:absolute;left:0;top:0;z-index:19;overflow:visible;pointer-events:none"></svg>`);
      this.st.append(this.svg);
    }
    return this.svg;
  }

  // ---------------- timeline ----------------
  // one paused animation, starting at t ms; returns it. Later-made animations win on the same property.
  at(t, el, frames, dur, easing = "linear") {
    let delay = t, d = Math.max(1, dur);
    if (this.warp) { const a = this.warp(t), b = this.warp(t + dur); delay = a; d = Math.max(1, b - a); }
    const a = el.animate(frames, { duration: d, delay, fill: "forwards", easing });
    a.pause(); this.anims.push(a);
    this.end = Math.max(this.end, delay + d);
    return a;
  }
  seek(t) { for (const a of this.anims) a.currentTime = t; }

  // ---------------- motions ----------------
  glow(t, U, dur, lift = true) {
    const d = U.side === "opp" ? 14 : -14;
    this.at(t, U.el, [{ filter: F_BASE, zIndex: 5 }, { filter: F_GLOW, zIndex: 5, offset: 80 / dur }, { filter: F_GLOW, zIndex: 5, offset: Math.max(.5, 1 - 120 / dur) }, { filter: F_BASE, zIndex: 5 }], dur);
    if (lift) this.at(t, U.el, [{ translate: "0px 0px" }, { translate: `0px ${d}px`, offset: 100 / dur }, { translate: `0px ${d}px`, offset: Math.max(.5, 1 - 120 / dur) }, { translate: "0px 0px" }], dur, "ease-out");
  }
  // a keyword mark on the card flares: grows, lights in its family colour, settles
  flare(t, U, name, dur = 380) {
    const m = U.el.querySelector(`.kwc[title="${name}"]`); if (!m) return;
    const k = KW[name], light = FAM[k[0]][1];
    this.at(t, m, [{ scale: 1, filter: "drop-shadow(0 0 0 transparent)", zIndex: 3 },
      { scale: 2.1, filter: `drop-shadow(0 0 8px ${light})`, zIndex: 3, offset: .3 },
      { scale: 1.8, filter: `drop-shadow(0 0 6px ${light})`, zIndex: 3, offset: .6 },
      { scale: 1, filter: "drop-shadow(0 0 0 transparent)", zIndex: 3 }], dur, "ease-out");
  }
  spend(t, U, name) { const m = U.el.querySelector(`.kwc[title="${name}"]`); if (m) this.at(t, m, [{ opacity: 1 }, { opacity: .4 }], 200); }
  // a number on the card changes: the new one pops from 1.5x (card_keeper.gd POP_SCALE), old one goes
  num(t, U, which, value, cls) {
    const old = U.n[which], sp = old.cloneNode(true);
    sp.textContent = value;
    const ol = String(old.textContent).length, nl = String(value).length;
    if (ol !== nl) sp.style.fontSize = (parseFloat(old.style.fontSize) * (nl > 1 ? 0.95 / 1.2 : 1.2 / 0.95)).toFixed(2) + "px";
    sp.classList.remove("hurt", "up"); if (cls) sp.classList.add(cls);
    sp.style.opacity = 0; U.el.append(sp);
    this.at(t, old, [{ opacity: 1 }, { opacity: 0 }], 30);
    this.at(t, sp, [{ opacity: 1, transform: "translate(-50%,-50%) scale(1.5)" }, { opacity: 1, transform: "translate(-50%,-50%) scale(1)" }], 240, "ease-out");
    U.n[which] = sp; U[which] = value;
  }
  // count a number up or down through its values over dur (the land-and-hop _roll, card_keeper.gd)
  count(t, U, which, to, dur, cls) {
    const from = U[which], steps = Math.min(Math.abs(to - from), 8);
    for (let k = 1; k <= steps; k++) this.num(t + dur * (k - 1) / steps, U, which, Math.round(from + (to - from) * k / steps), cls);
  }
  // the eight-pointed burst (fight.html hit()), popping as fight_motion.gd burst() does
  burst(t, cx, cy, n, o = {}) {
    const r = o.r || 46;
    const pts = [...Array(16)].map((_, i) => { const a = Math.PI * i / 8 - Math.PI / 2, k = i % 2 ? 0.62 : 1;
      return `${(50 + 50 * k * Math.cos(a)).toFixed(1)}% ${(50 + 50 * k * Math.sin(a)).toFixed(1)}%`; }).join(",");
    const words = o.blocked ? `<b>0</b>` : o.text ? `<b>${o.text}</b>` : n > 0 ? `<b>-${n}</b>` : "";
    const el = html(`<div class="hit${o.blocked ? " blk" : ""}${o.cls ? " " + o.cls : ""}" style="left:0;top:0;width:${2 * r}px;height:${2 * r}px;opacity:0"><i style="clip-path:polygon(${pts})"></i><i style="clip-path:polygon(${pts})"></i>${words}</div>`);
    if (o.fs) el.querySelector("b").style.fontSize = o.fs + "px";
    // a holder, so the burst can follow its unit home while it pops and rises (fight_motion.gd burst())
    const wrap = html(`<div class="hitwrap" style="position:absolute;width:0;height:0;z-index:6"></div>`);
    wrap.append(el); this.fx().append(place(wrap, cx - r, cy - r));
    const read = o.read ?? 290, D = 50 + 83 + read + 120;
    this.at(t, el, [{ opacity: 1, scale: .55, translate: "0px 0px" }, { opacity: 1, scale: 1.18, offset: 50 / D }, { opacity: 1, scale: 1, offset: 133 / D },
      { opacity: 1, scale: 1, translate: "0px 0px", offset: (133 + read) / D }, { opacity: 0, scale: 1, translate: "0px -16px" }], D);
    return wrap;
  }
  // a unit attacks another: wind-up, travel to contact, hold, home (fight_motion.gd). Returns the contact time.
  attack(t, A, T, o = {}) {
    const a = v2(A.cx, A.cy), b = o.to || v2(T.cx, T.cy), dir = norm(sub(b, a)), dist = len(sub(b, a));
    const travel = Math.max(0, dist - M.contact), lean = 6 * (dir.y < 0 ? -1 : 1);
    const wind = o.windup || M.windup, trav = o.travel || M.travel, total = wind + trav + M.hold + (o.back || M.back);
    const end = v2(dir.x * travel, dir.y * travel), back = v2(-dir.x * 12, -dir.y * 12);
    const f0 = o.from || v2(0, 0);
    const fr = [{ translate: px(f0), rotate: "0deg", scale: 1, easing: "ease-out" },
      { translate: px(v2(f0.x + back.x, f0.y + back.y)), rotate: lean + "deg", scale: 1.04, offset: wind / total, easing: "ease-in" }];
    if (o.arc) {   // Sortie: up and over the front row, larger at the top as if flying nearer
      const mid = v2(end.x * .55, end.y * .55 + (A.side === "you" ? -o.arc : o.arc));
      fr.push({ translate: px(mid), rotate: (-lean) + "deg", scale: 1.16, offset: (wind + trav * .55) / total, easing: "ease-in" });
    }
    fr.push({ translate: px(end), rotate: (-lean / 2) + "deg", scale: 1.04, offset: (wind + trav) / total, easing: "linear" },
      { translate: px(end), rotate: (-lean / 2) + "deg", scale: 1.04, offset: (wind + trav + M.hold) / total, easing: "cubic-bezier(.22,.61,.36,1)" });
    if (o.stay) fr.push({ translate: px(v2(end.x * o.stay, end.y * o.stay)), rotate: "0deg", scale: 1 });
    else fr.push({ translate: "0px 0px", rotate: "0deg", scale: 1 });
    this.at(t, A.el, fr, total);
    this.at(t, A.el, [{ filter: F_BASE, zIndex: 6 }, { filter: F_GLOW, zIndex: 6, offset: .2 }, { filter: F_GLOW, zIndex: 6, offset: .8 }, { filter: F_BASE, zIndex: 6 }], total + 40);
    const c = t + wind + trav;
    A.contact = v2(A.cx + end.x, A.cy + end.y);
    if (T && !o.noRecoil) this.recoil(c, T, dir, o.blocked);
    if (T && o.dealt != null && !o.noBurst) this.burst(c, T.cx, T.y + H * .48, o.dealt, { blocked: o.blockedT });
    if (o.taken != null) {
      const bw = this.burst(c, A.contact.x, A.contact.y - H * .08, o.taken, { r: 40, blocked: o.takenBlocked });
      const home = o.stay ? v2(-end.x * (1 - o.stay), -end.y * (1 - o.stay)) : v2(-end.x, -end.y);
      this.at(c + M.hold, bw, [{ translate: "0px 0px" }, { translate: px(home) }], o.back || M.back, "cubic-bezier(.22,.61,.36,1)");
    }
    if (T && o.tHp != null) this.num(c, T, "hp", o.tHp, o.tHp < T.max ? "hurt" : "");
    if (o.aHp != null) this.num(c, A, "hp", o.aHp, o.aHp < A.max ? "hurt" : "");
    return c;
  }
  recoil(t, T, dir, blocked) {
    const sh = blocked ? .3 : 1, push = v2(dir.x * 16 * sh, dir.y * 16 * sh), turn = 4 * Math.sign(dir.y || 1) * sh;
    const D = M.recoil + M.back;
    this.at(t, T.el, [{ translate: "0px 0px", rotate: "0deg", easing: "ease-out" }, { translate: px(push), rotate: turn + "deg", offset: M.recoil / D, easing: "cubic-bezier(.22,.61,.36,1)" }, { translate: "0px 0px", rotate: "0deg" }], D);
    this.at(t, T.el, [{ filter: blocked ? F_BLOCK : F_HIT }, { filter: F_BASE }], D);
  }
  // death: drops 48 px away from the fight, turns 16 degrees, shrinks to 0.72 and fades (fight_motion.gd)
  die(t, U, o = {}) {
    const dir = o.dir || v2(0, U.side === "opp" ? -1 : 1), D = o.dur || M.death;
    const fr = [{ translate: "0px 0px", rotate: "0deg", scale: 1, opacity: 1 }];
    if (o.linger) fr.push({ translate: px(v2(dir.x * 10, dir.y * 10)), rotate: (4 * Math.sign(dir.y)) + "deg", scale: .9, opacity: 1, offset: o.linger / (D + o.linger) });
    fr.push({ translate: px(v2(dir.x * 18, dir.y * 18)), rotate: (8 * Math.sign(dir.y)) + "deg", scale: .86, opacity: 1, offset: (67 + (o.linger || 0)) / (D + (o.linger || 0)) });
    fr.push({ translate: px(v2(dir.x * 48, dir.y * 48)), rotate: (16 * Math.sign(dir.y)) + "deg", scale: .72, opacity: 0 });
    this.at(t, U.el, fr, D + (o.linger || 0), "ease-in");
    return t + D + (o.linger || 0);
  }
  // a unit fades and drops into its slot (a summon): from 24 px above, 1.1x, a ring in its family colour
  arrive(t, U, o = {}) {
    const up = U.side === "opp" ? 24 : -24, D = o.dur || 260;
    this.at(t, U.el, [{ opacity: 0, translate: `0px ${up}px`, scale: 1.12 }, { opacity: 1, translate: "0px 0px", scale: 1, offset: .7, easing: "ease-out" },
      { opacity: 1, translate: `0px ${-up * .15}px`, scale: 1, offset: .85 }, { opacity: 1, translate: "0px 0px", scale: 1 }], D, "ease-out");
    if (o.ring !== false) this.ring(t + D * .6, U.cx, U.cy, o.ring || FAM.kin[1], 60, 130, 320);
    return t + D;
  }
  ring(t, cx, cy, colour, r0, r1, dur, width = 6) {
    const el = html(`<div class="ring" style="width:${2 * r1}px;height:${2 * r1}px;border-width:${width}px;border-color:${colour};box-shadow:0 0 18px ${colour}, inset 0 0 12px ${colour};opacity:0"></div>`);
    this.fx().append(place(el, cx - r1, cy - r1));
    this.at(t, el, [{ opacity: .95, scale: r0 / r1 }, { opacity: 0, scale: 1 }], dur, "ease-out");
  }
  // words or numbers that pop and rise (the combo counter, +2/+2)
  float(t, x, y, text, o = {}) {
    const el = html(`<div class="flo ${o.cls || ""}" style="opacity:0">${text}</div>`);
    if (o.fs) el.style.fontSize = o.fs + "px";
    this.fx().append(el); place(el, x, y);
    el.style.translate = "-50% -50%";
    const D = o.dur || 700, rise = o.rise ?? 34, s = o.scale || 1;
    this.at(t, el, [{ opacity: 0, transform: `translateY(0px) scale(${.5 * s})` }, { opacity: 1, transform: `translateY(0px) scale(${1.25 * s})`, offset: .12 },
      { opacity: 1, transform: `translateY(${-rise * .4}px) scale(${s})`, offset: .3 }, { opacity: 1, transform: `translateY(${-rise * .8}px) scale(${s})`, offset: o.hold ?? .8 },
      { opacity: 0, transform: `translateY(${-rise}px) scale(${s})` }], D, "ease-out");
    return el;
  }
  // a glass shard flies from a to b along a curve (a Seed to the Compost, an effect's bolt, a strike at a hero)
  shard(t, a, b, dur, o = {}) {
    const sz = o.size || 26, col = o.colour || "#ffb7a4";
    const el = html(`<div class="shard ${o.cls || ""}" style="width:${sz}px;height:${sz}px;--c:${col};opacity:0"></div>`);
    this.fx().append(place(el, a.x - sz / 2, a.y - sz / 2));
    const d = sub(b, a), bend = o.bend ?? .25, nrm = v2(-d.y * bend, d.x * bend), fr = [];
    const ang = Math.atan2(d.y, d.x) * 180 / Math.PI + 45;
    for (let k = 0; k <= 10; k++) {
      const s = k / 10, q = 4 * s * (1 - s);
      fr.push({ translate: `${(d.x * s + nrm.x * q).toFixed(1)}px ${(d.y * s + nrm.y * q).toFixed(1)}px`, opacity: k === 10 ? .9 : 1,
        scale: (o.grow ? 1 + o.grow * s : 1) * (k === 0 ? .4 : 1), rotate: ang + "deg" });
    }
    this.at(t, el, fr, dur, o.easing || "ease-in");
    this.at(t + dur, el, [{ opacity: 1 }, { opacity: 0 }], 60);
    return t + dur;
  }
  // a lead line drawn from a to b with a lit core (effect damage), then fading
  line(t, a, b, o = {}) {
    const svg = this.svgLayer(), L = len(sub(b, a)), col = o.colour || "#ff8a6a", draw = o.draw || 130, hold = o.hold ?? 260;
    const g = document.createElementNS("http://www.w3.org/2000/svg", "g");
    g.innerHTML = `<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" stroke="#16120e" stroke-width="${o.w ? o.w + 6 : 12}" stroke-linecap="round" stroke-dasharray="${L} ${L}" stroke-dashoffset="${L}"/>
<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" stroke="${col}" stroke-width="${o.w || 6}" stroke-linecap="round" stroke-dasharray="${L} ${L}" stroke-dashoffset="${L}" style="filter:drop-shadow(0 0 6px ${col})"/>`;
    g.style.opacity = 0; svg.append(g);
    this.at(t, g, [{ opacity: 1 }, { opacity: 1 }], 1);
    g.querySelectorAll("line").forEach(l => this.at(t, l, [{ strokeDashoffset: L }, { strokeDashoffset: 0 }], draw, "ease-out"));
    this.at(t + draw + hold, g, [{ opacity: 1 }, { opacity: 0 }], 160);
    return t + draw;
  }
  // an SVG path (a Cleave's arc, thorns, roots, cracks) drawn on, then faded
  path(t, d, o = {}) {
    const svg = this.svgLayer(), col = o.colour || "#ff8a6a";
    const g = document.createElementNS("http://www.w3.org/2000/svg", "g");
    g.innerHTML = `<path d="${d}" fill="${o.fill || "none"}" stroke="#16120e" stroke-width="${(o.w || 6) + 6}" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1 1" stroke-dashoffset="1"/>
<path d="${d}" fill="none" stroke="${col}" stroke-width="${o.w || 6}" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1 1" stroke-dashoffset="1" style="filter:drop-shadow(0 0 6px ${col})"/>`;
    g.style.opacity = 0; svg.append(g);
    this.at(t, g, [{ opacity: 1 }, { opacity: 1 }], 1);
    g.querySelectorAll("path").forEach(p => this.at(t, p, [{ strokeDashoffset: 1 }, { strokeDashoffset: 0 }], o.draw || 120, "ease-out"));
    if (!o.keep) this.at(t + (o.draw || 120) + (o.hold ?? 200), g, [{ opacity: 1 }, { opacity: 0 }], o.fade || 160);
    return g;
  }
  // thorns: tapered glass spikes that shoot from base to tip
  spike(t, base, tip, o = {}) {
    const svg = this.svgLayer(), wdt = o.w || 16, d = norm(sub(tip, base)), n = v2(-d.y * wdt / 2, d.x * wdt / 2);
    const g = document.createElementNS("http://www.w3.org/2000/svg", "g");
    const pts = `${base.x + n.x},${base.y + n.y} ${tip.x},${tip.y} ${base.x - n.x},${base.y - n.y}`;
    g.innerHTML = `<polygon points="${pts}" fill="${o.colour || "#7fbf4a"}" stroke="#16120e" stroke-width="4" stroke-linejoin="round" style="filter:drop-shadow(0 0 5px #b6f07a)"/>`;
    g.style.opacity = 0; g.style.transformBox = "view-box"; g.style.transformOrigin = `${base.x}px ${base.y}px`;
    svg.append(g);
    const ang = Math.atan2(d.y, d.x) * 180 / Math.PI;
    this.at(t, g, [{ opacity: 1, transform: `rotate(${ang}deg) scale(0.05,1) rotate(${-ang}deg)` }, { opacity: 1, transform: `rotate(${ang}deg) scale(1,1) rotate(${-ang}deg)`, offset: .35 }, { opacity: 1, transform: `rotate(${ang}deg) scale(1,1) rotate(${-ang}deg)`, offset: .7 }, { opacity: 0, transform: `rotate(${ang}deg) scale(1,1) rotate(${-ang}deg)` }], o.dur || 260, "ease-out");
  }
  plate(t, name, value) {
    const P = this.plates[name]; if (!P) return;
    const nb = P.b.cloneNode(true); nb.textContent = value; nb.style.opacity = 0; nb.style.position = "absolute";
    nb.style.left = P.b.offsetLeft + "px"; nb.style.top = P.b.offsetTop + "px"; P.el.append(nb);
    this.at(t, P.b, [{ opacity: 1 }, { opacity: 0 }], 20);
    this.at(t, nb, [{ opacity: 1 }, { opacity: 1 }], 1);
    this.at(t, P.el, [{ scale: 1.25, filter: "brightness(1.3)" }, { scale: 1, filter: "brightness(1)" }], 350, "ease-out");
    P.b = nb; P.v = value;
  }
  plateXY(name) { const P = this.plates[name].el; return v2(parseFloat(P.style.left) + 60, parseFloat(P.style.top) + 22); }
  shake(t, el, amp = 6, dur = 260) {
    this.at(t, el, [0, 1, -1, .8, -.6, .3, 0].map(k => ({ translate: `${(k * amp).toFixed(1)}px 0px` })), dur);
  }
}

// ---------------- the page: one Proto per event, run while on screen ----------------
const Player = {
  list: [], rate: 1,
  add(box, ev, opts = {}) {
    const st = html(`<div class="pstage"></div>`); box.append(st);
    const p = new Proto(st);
    ev.build(p);
    p.vignette();
    const item = { box, st, p, ev, on: false, paused: false, t0: performance.now(), tFix: opts.t, gap: ev.gap ?? 900, bar: opts.bar, slow: 1 };
    this.list.push(item);
    const fit = () => { const k = box.clientWidth / 1920; st.style.transform = `scale(${k})`; };
    new ResizeObserver(fit).observe(box); fit();
    if (opts.t != null) { p.seek(opts.t); return item; }
    new IntersectionObserver(es => es.forEach(e => { item.on = e.isIntersecting; if (item.on) item.t0 = performance.now() - (item.tNow || 0) / item.slow; }), { threshold: .15 }).observe(box);
    return item;
  },
  tick(now) {
    for (const it of this.list) {
      if (it.tFix != null || !it.on || it.paused) continue;
      const L = it.p.end + it.gap;
      const t = ((now - it.t0) * it.slow) % L;
      it.tNow = t; it.p.seek(Math.min(t, it.p.end));
      if (it.bar) it.bar.style.width = (100 * Math.min(1, t / it.p.end)).toFixed(1) + "%";
    }
    requestAnimationFrame(n => this.tick(n));
  },
};
