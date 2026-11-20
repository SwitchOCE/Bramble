// Every action outside the fight, one prototype each. PROPOSAL: agent-drawn, not decided.
// def: { id, grp, name, tag: "new"|"changed"|"keep", line, timing, scene(st) -> handles, run(T, h) }
// Times are ms from the start of the loop; each starts with a short still so the before-state shows.

const R = over => st => recruit(st, base(over));
const T0 = 450;
const FUR = "Fury";

// ---- shared beats ------------------------------------------------------------------------------
// the shop: old cards sink away, new ones drop in left to right, their tags swinging in after
function shopOut(T, h, t0, els = h.shop, tags = h.tags, spells = h.spells) {
  els.forEach((el, i) => { if (!el) return; const p = el._p; path(T, el, t0 + i * 25, [[0, p, 1], [150, { ...p, y: p.y + 24, s: .94 }, 0]], "in");
    if (tags[i]) T.a(tags[i], [{ opacity: 1 }, { opacity: 0 }], t0 + i * 25, 100, EASE.lin); });
  spells.forEach((el, k) => { const p = el._p; path(T, el, t0 + (5 + k) * 25, [[0, p, 1], [150, { ...p, y: p.y + 24, s: .94 }, 0]], "in"); });
  return t0 + 150 + 6 * 25;
}
function newShop(h, cards, spells = []) {
  const out = { shop: [], tags: [], spells: [] };
  cards.forEach((c, i) => {
    const [x, y] = shopXY(i), el = mk(c); h.st.append(put(el, x, y)); pose0(el, P(x, y)); el.style.opacity = 0; out.shop.push(el);
    const t = html(`<div class="a" style="z-index:3;width:44px;height:68px;transform-origin:22px 0"><svg class="a" width="4" height="14" style="left:20px;top:0;overflow:visible"><path d="M2,0 V14" stroke="#16120e" stroke-width="3"/><circle cx="2" cy="1" r="3" fill="#16120e"/></svg><div class="hang" style="left:0;top:11px">${coinN(c.price ?? 3, (c.price ?? 3) > h.s.gold)}</div></div>`);
    h.st.append(put(t, x + W / 2 - 22, y + H - 1)); t.style.opacity = 0; out.tags.push(t);
  });
  spells.forEach((c, k) => { const [x, y] = spellXY(k), el = mk(c); h.st.append(put(el, x, y)); pose0(el, P(x, y)); el.style.opacity = 0; out.spells.push(el); });
  return out;
}
function shopIn(T, n, t0) {
  n.shop.forEach((el, i) => { const p = el._p, t = t0 + i * 50;
    path(T, el, t, [[0, { ...p, y: p.y - 40, s: 1.04 }, 0], [90, { ...p, y: p.y + 4 }, 1], [220, p, 1]], "out");
    T.a(n.tags[i], [{ opacity: 0, transform: "rotate(-28deg)" }, { opacity: 1, transform: "rotate(10deg)", offset: .5 }, { opacity: 1, transform: "rotate(0deg)" }], t + 140, 260, EASE.out); });
  n.spells.forEach((el, k) => { const p = el._p, t = t0 + (2 + k) * 50 + 20; path(T, el, t, [[0, { ...p, y: p.y - 30 }, 0], [90, { ...p, y: p.y + 3 }, 1], [220, p, 1]], "out"); });
  return t0 + 4 * 50 + 400;
}
function goldTo(T, h, from, to, t0, dur = 260) {
  T.num(h.gold, from, to, t0, dur);
  const spend = to < from;
  T.a(h.goldBtn, spend
    ? [{ transform: "scale(1)" }, { transform: "scale(.94)", offset: .3 }, { transform: "scale(1)" }]
    : [{ transform: "scale(1)", filter: "brightness(1)" }, { transform: "scale(1.07)", filter: "brightness(1.5)", offset: .3 }, { transform: "scale(1)", filter: "brightness(1)" }], t0, 280, EASE.out);
}
function coinToGold(T, h, c0, n, t0, dur = 420) {
  const el = coinEl(h.st, n ? "+" + n : "", 50);
  gainFly(T, h.st, el, c0, GOLDC, t0, dur, { w: 50, h: 50, lift: 140, s0: .7, s1: 1, colour: "255,214,90", ringR: 44, ease: "arrive" });
  return t0 + dur;
}
function plateTo(T, h, plate, from, to, t0) {
  T.text(plate.querySelector("b"), String(to), t0);
  T.a(plate, [{ transform: "scale(1.25)" }, { transform: "scale(1)" }], t0, 350, EASE.out);   // glass_counters.gd PLATE_POP
}
function press(T, el, t0) { T.a(el, [{ transform: "scale(1)" }, { transform: "scale(.93)", filter: "brightness(1.25)", offset: .35 }, { transform: "scale(1)" }], t0, 200, EASE.out); }

// ---- start-of-turn effects: the source lights, the gain flies to the target ----------------------
function fxGrudge(T, h, idxs, t0, g = [2, 3]) {
  idxs.forEach((i, k) => {
    const el = h.board[i], t = t0 + k * 50; fire(T, el, t, 420);
    const pill = gainPill(h.st, `+${g[0]}/+${g[1]}`), p = el._p;
    const from = { x: p.x + W / 2, y: p.y + 0.93 * H - 14 }, mid = { x: p.x + W / 2, y: p.y + 0.42 * H - 14 };
    put(pill, mid.x - 50, mid.y - 22); pill.style.opacity = 0;
    path(T, pill, t + 110, [[0, P(from.x - 50, from.y - 22, 0, .5), 0], [90, P(from.x - 50, from.y - 32, 0, .9), 1], [330, P(mid.x - 50, mid.y - 22, 0, 1.1), 1], [430, P(mid.x - 50, mid.y + 40, 0, .5), 0]], "out");
    gain(T, el, g[0], g[1], t + 520);
  });
  return t0 + 520 + 260;
}
function fxRelic(T, h, i, t0, n = 2) { const el = h.board[i]; fire(T, el, t0); const t = coinToGold(T, h, centre(el, -14), n, t0 + 110); goldTo(T, h, h.s.gold, h.s.gold + n, t); return t + 260; }
// Old Campaigner (dev): "After each fight, give this slot 1 Renown, or 2 if this survived." A gold star carrying the
// Renown rises over it and drops onto its slot's Renown pill, which pops (1 to 3); its numbers rise with it.
function fxCampaigner(T, h, i, t0, n = 2) {
  const el = h.board[i], p = el._p; fire(T, el, t0, 380);
  const m = starEl(h.st, "+" + n);
  const top = { x: p.x + W / 2 - 30, y: p.y - 120 }, pill = { x: p.x + W / 2 - 30, y: p.y - 20 };
  put(m, pill.x, pill.y); m.style.opacity = 0;
  path(T, m, t0 + 110, [[0, P(top.x, top.y + 60, -30, .4), 0], [140, P(top.x, top.y, 0, 1.15), 1], [260, P(top.x, top.y, 0, 1), 1], [400, P(pill.x, pill.y, 0, .7), 1], [450, P(pill.x, pill.y, 0, .5), 0]], "lin");
  ring(T, h.st, p.x + W / 2, p.y + 10, t0 + 480, 40);
  addRenown(T, h, i, n, t0 + 500);
  return t0 + 800;
}
function fxHopper(T, h, i, t0, toWait = false) {
  const el = h.board[i]; fire(T, el, t0);
  const c = mk(C("hopper")), N = h.hand.length;
  const to = toWait ? waitPose(h.waiting.length) : handPose(N, N + 1);
  h.st.append(put(c, to.x, to.y)); c.style.opacity = 0; c.style.zIndex = 20;
  const ce = centre(el);
  T.a(c, [{ opacity: 0 }, { opacity: 1 }], t0 + 110, 80, EASE.lin);
  fly(T, c, P(ce.x - W / 2, ce.y - H / 2, 0, .3), to, t0 + 110, 430, { lift: 160, ease: "arrive", lean: 6 });
  hop(T, c, to, t0 + 540, toWait ? H * WS : H);
  T.at(t0 + 760, on => { c.style.zIndex = on ? 4 + N : 20; });
  if (!toWait) { refan(T, h.hand, N + 1, t0 + 300, 220); T.text(h.handN, String(N + 1), t0 + 540); }
  else { T.text(h.waitBadge, String(h.waiting.length + 1), t0 + 540); T.a(h.waitBadge, [{ opacity: 0, transform: "scale(1.8)" }, { opacity: 1, transform: "scale(1)" }], t0 + 540, 260, EASE.out); }
  return t0 + 760;
}

// ---- the list ------------------------------------------------------------------------------------
const GROUPS = [
  ["menus", "Start, menus and the game frame"],
  ["start", "Start of your turn"],
  ["shop", "The shop"],
  ["hand", "Hand and board"],
  ["end", "End of turn"],
  ["over", "Out of the game"],
];

const PROTOS = [
// ======================================================================= menus
{ id: "boot", grp: "menus", name: "Game opens to the start screen", tag: "changed",
  line: "The window lights up out of the dark, then the pane and its buttons settle in.",
  timing: "0.9 s, once per launch. Now: instant.",
  scene: st => { const h = startScreen(st); h.veil = add(st, `<div class="veil"></div>`, 0, 0); return h; },
  run(T, h) {
    T.a(h.veil, [{ opacity: 1 }, { opacity: 0 }], T0, 500, EASE.inout);
    T.a(h.pane, [{ opacity: 0, transform: "translateY(18px)" }, { opacity: 1, transform: "translateY(0)" }], T0 + 200, 380, EASE.out);
    const parts = [...h.parts, ...h.tribes.flatMap(t => [t.b, t.o]), h.play, h.quit];
    parts.forEach((el, i) => { el.style.opacity = 0; T.a(el, [{ opacity: 0, transform: "translateY(8px)" }, { opacity: 1, transform: "translateY(0)" }], T0 + 330 + i * 22, 220, EASE.out); });
    h.pane.style.opacity = 0;
  } },
{ id: "tribes", grp: "menus", name: "Toggle a tribe, or play only one", tag: "changed",
  line: "Turning a tribe on fills its amber ring and lifts the strike; \"Only\" turns the others off in a quick ripple.",
  timing: "0.15 s per toggle; the ripple 40 ms apart, 0.3 s in all. Now: instant redraw.",
  scene: st => startScreen(st),
  run(T, h) {
    const lo = h.tribes[3], at = { x: lo.b._b.x + 66, y: lo.b._b.y + 30 };
    ptrMove(T, h.ptr, { x: 1000, y: 820 }, at, T0, 420);
    ptrPress(T, h.ptr, at, T0 + 430);
    const on = (t, b, t0) => { T.a(b, [{ opacity: .4, boxShadow: "0 0 0 0 rgba(255,178,74,0)" }, { opacity: 1, boxShadow: "0 0 0 5px rgba(255,178,74,1)", offset: .5 }, { opacity: 1, boxShadow: "0 0 0 3px rgba(255,178,74,1)" }], t0, 220, EASE.out);
      T.a(b.querySelector(".strike"), [{ transform: "scaleX(1)" }, { transform: "scaleX(0)" }], t0, 150, EASE.in); };
    const off = (b, t0) => { T.a(b, [{ opacity: 1, boxShadow: "0 0 0 3px rgba(255,178,74,1)" }, { opacity: .4, boxShadow: "0 0 0 0 rgba(255,178,74,0)" }], t0, 160, EASE.out);
      T.a(b.querySelector(".strike"), [{ transform: "scaleX(0)" }, { transform: "scaleX(1)" }], t0, 160, EASE.out); };
    on(T, lo.b, T0 + 520);
    const ba = h.tribes[0], at2 = { x: ba.o.offsetLeft + ba.o.offsetWidth / 2, y: 598 };
    ptrMove(T, h.ptr, at, at2, T0 + 1300, 450);
    ptrPress(T, h.ptr, at2, T0 + 1760);
    T.a(ba.o, [{ color: "#efe6d2", transform: "scale(1)" }, { color: "#ffb24a", transform: "scale(1.15)", offset: .4 }, { color: "#efe6d2", transform: "scale(1)" }], T0 + 1800, 300, EASE.out);
    [1, 2, 3, 4].forEach((i, k) => off(h.tribes[i].b, T0 + 1880 + k * 40));
    ptrHide(T, h.ptr, T0 + 2800);
  } },
{ id: "play", grp: "menus", name: "Play: into the first recruit turn", tag: "new",
  line: "The start pane lifts away and the recruit window comes up under it; the first shop drops in card by card.",
  timing: "0.3 s out, shop lands over 0.5 s; about 1 s to playable. Now: instant swap.",
  scene: st => { const r = layer(st, 0), s = layer(st, 1); const hr = recruit(r, base({ turn: 1, gold: 5, tier: 1, up: 8, board: Array(7).fill(null), renown: [], hand: [], next: 7,
    shop: [C("brock-cub"), C("pip"), C("cousin"), C("sentry"), C("needle-page")], spells: [SPELLS.sharpen, SPELLS.sharpen] })); const hs = startScreen(s); return { r: hr, s: hs, sl: s, rl: r }; },
  run(T, h) {
    const at = { x: 960, y: 690 };
    ptrMove(T, h.s.ptr, { x: 1080, y: 860 }, at, T0, 380);
    ptrPress(T, h.s.ptr, at, T0 + 400);
    press(T, h.s.play, T0 + 400);
    T.a(h.sl, [{ opacity: 1, transform: "scale(1)" }, { opacity: 0, transform: "scale(1.04)" }], T0 + 560, 300, EASE.in);
    h.r.shop.concat(h.r.spells).forEach(el => el.style.opacity = 0); h.r.tags.forEach(t => t.style.opacity = 0);
    shopIn(T, { shop: h.r.shop, tags: h.r.tags, spells: h.r.spells }, T0 + 760);
    T.num(h.r.gold, 0, 5, T0 + 900, 300);
  } },
{ id: "browser", grp: "menus", name: "Open and close the card browser", tag: "changed",
  line: "The room dims, the browser's pane rises a little into place and its cards fill in, top left first.",
  timing: "Open 0.2 s, cards 20 ms apart (0.4 s); close 0.15 s. Now: instant.",
  scene: st => { const h = recruit(st, base()); const o = layer(st, 45); o.style.opacity = 0;
    add(o, `<div id="dim"></div>`, 0, 0); const pn = paneEl(o, 300, 110, 1320, 860); title(o, "Cards", 960, 140, 48);
    const ids = ["brock-cub", "hedge-knight", "pip", "cousin", "hopper", "private", "sentry", "needle-page", "bramble-runner", "green-recruit", "relic-seeker", "harvest-piper"];
    h.bcards = ids.map((id, i) => { const el = mk(C(id), 300); o.append(put(el, 380 + (i % 6) * 196, 220 + Math.floor(i / 6) * 330)); el.style.opacity = 0; return el; });
    h.o = o; h.pn = pn; return h; },
  run(T, h) {
    const at = { x: 1817, y: 95 };
    ptrMove(T, h.ptr, { x: 1600, y: 300 }, at, T0, 380);
    ptrPress(T, h.ptr, at, T0 + 400); press(T, h.cards.firstChild, T0 + 400);
    T.a(h.o, [{ opacity: 0 }, { opacity: 1 }], T0 + 520, 150, EASE.out);
    T.a(h.pn, [{ transform: "translateY(24px)" }, { transform: "translateY(0)" }], T0 + 520, 220, EASE.out);
    h.bcards.forEach((el, i) => T.a(el, [{ opacity: 0, transform: "translateY(14px)" }, { opacity: 1, transform: "translateY(0)" }], T0 + 620 + i * 20, 160, EASE.out));
    T.a(h.o, [{ opacity: 1 }, { opacity: 0 }], T0 + 2600, 150, EASE.in);
    ptrHide(T, h.ptr, T0 + 2600);
  } },
{ id: "pause", grp: "menus", name: "Pause and resume", tag: "changed",
  line: "Esc or the cog: the room dims and the pause pane settles from slightly small; Resume lets it go faster than it came.",
  timing: "Open 0.18 s, close 0.12 s. Now: instant.",
  scene: st => { const h = recruit(st, base()); const o = layer(st, 45); o.style.opacity = 0;
    add(o, `<div id="dim"></div>`, 0, 0); const p = layer(o, 1); paneEl(p, 740, 270, 440, 460); title(p, "Paused", 960, 305, 48);
    h.resume = button(p, "Resume", 810, 390, 300); button(p, "Quit to start", 810, 470, 300); button(p, "Quit", 810, 550, 300); title(p, "Seed 48213", 960, 650, 18, "#c9bda6");
    h.o = o; h.p = p; return h; },
  run(T, h) {
    const at = { x: 123, y: 101 };
    ptrMove(T, h.ptr, { x: 300, y: 300 }, at, T0, 360);
    ptrPress(T, h.ptr, at, T0 + 380); press(T, h.cog, T0 + 380);
    T.a(h.o, [{ opacity: 0 }, { opacity: 1 }], T0 + 500, 150, EASE.out);
    T.a(h.p, [{ transform: "scale(.96)" }, { transform: "scale(1)" }], T0 + 500, 180, EASE.out);
    h.p.style.transformOrigin = "960px 500px";
    const r = { x: 960, y: 420 };
    ptrMove(T, h.ptr, at, r, T0 + 1300, 420);
    ptrPress(T, h.ptr, r, T0 + 1740); press(T, h.resume, T0 + 1740);
    T.a(h.o, [{ opacity: 1 }, { opacity: 0 }], T0 + 1900, 120, EASE.in);
    ptrHide(T, h.ptr, T0 + 2300);
  } },
{ id: "hover", grp: "menus", name: "Hover a card", tag: "changed",
  line: "The card brightens and its detail grows in beside it; a hand card stands up first, as now.",
  timing: "Detail in 0.13 s, out 0.1 s; the hand card stands in 0.15 s. Now: the detail appears at once.",
  scene: st => { const h = recruit(st, base());
    const c = h.s.shop[1], tip = html(`<div class="kt" style="opacity:0"></div>`), big = mk(c, 400); big.style.position = "relative";
    tip.append(big); tip.insertAdjacentHTML("beforeend", `<div class="ktp"><div class="n">${c.name}</div><div class="m">Tier ${c.tier} · ${TRIBE_NAME[BY_ID[c.id].tribe]}</div><div class="r">${marksIn(fillText(BY_ID[c.id]))}</div></div>`);
    st.append(put(tip, shopXY(1)[0] + W + 18, 60)); h.tip = tip; tip.style.transformOrigin = "0 40%"; return h; },
  run(T, h) {
    const el = h.shop[1], at = { x: el._b.x + 80, y: el._b.y + 120 };
    ptrMove(T, h.ptr, { x: 700, y: 640 }, at, T0, 420);
    T.a(el, [{ filter: REST }, { filter: "brightness(1.1) drop-shadow(0 0 10px rgba(255,236,190,.55)) drop-shadow(0 8px 10px rgba(0,0,0,.6))" }], T0 + 420, 80, EASE.out);
    T.a(h.tip, [{ opacity: 0, transform: "scale(.94) translateX(-8px)" }, { opacity: 1, transform: "scale(1) translateX(0)" }], T0 + 440, 130, EASE.out);
    T.a(h.tip, [{ opacity: 1 }, { opacity: 0 }], T0 + 2000, 100, EASE.in);
    T.a(el, [{ filter: "brightness(1.1) drop-shadow(0 0 10px rgba(255,236,190,.55)) drop-shadow(0 8px 10px rgba(0,0,0,.6))" }, { filter: REST }], T0 + 2000, 100, EASE.in);
    const hc = h.hand[1], p = hc._p, up = P(p.x, 1080 - H - 24, 0, 1.06), at2 = { x: p.x + 80, y: 1050 };
    ptrMove(T, h.ptr, at, at2, T0 + 2000, 380);
    T.at(T0 + 2380, on => { hc.style.zIndex = on ? 30 : 5; });
    path(T, hc, T0 + 2380, [[0, p], [150, up]], "out");
    path(T, hc, T0 + 3400, [[0, up], [120, p]], "in");
    ptrMove(T, h.ptr, at2, { x: 1100, y: 800 }, T0 + 3400, 300);
  } },
{ id: "board", grp: "menus", name: "Open the leaderboard (Tab or your portrait)", tag: "changed",
  line: "The leaderboard's pane unrolls down the right window and the players drop in, first place first.",
  timing: "Pane 0.2 s, rows 25 ms apart; 0.4 s in all. Now: instant.",
  crop: [1100, 40, 820, 1000],
  scene: st => { const h = recruit(st, base()); const o = layer(st, 45); leaderboard(o, G, 150, 84); h.o = o; h.lpane = o.querySelector("#lbpane"); h.rows = [...o.querySelectorAll(".lb > div")]; o.style.opacity = 0; return h; },
  run(T, h) {
    T.a(h.o, [{ opacity: 0 }, { opacity: 1 }], T0, 60, EASE.lin);
    h.lpane.style.transformOrigin = "50% 0";
    T.a(h.lpane, [{ transform: "scaleY(.05)", opacity: .4 }, { transform: "scaleY(1)", opacity: 1 }], T0, 200, EASE.out);
    h.rows.forEach((r, i) => { r.style.opacity = 0; T.a(r, [{ opacity: 0, transform: "translateY(-14px)" }, { opacity: 1, transform: "translateY(0)" }], T0 + 120 + i * 25, 160, EASE.out); });
    T.a(h.o, [{ opacity: 1 }, { opacity: 0 }], T0 + 2400, 150, EASE.in);
  } },
{ id: "compost", grp: "menus", name: "Open the Compost (click its plate)", tag: "changed",
  line: "What's in your Compost flies out of the plate and spreads out; closing sends it back.",
  timing: "Cards 0.26 s each, 35 ms apart (0.45 s); close 0.2 s. Now: instant.",
  scene: st => { const h = recruit(st, base({ plates: [["bog", "Compost", 6]] })); const o = layer(st, 45); h.o = o; h.dim = add(o, `<div id="dim"></div>`, 0, 0); h.dim.style.opacity = 0;
    h.cc = ["pip", "pip", "bramble-runner", "crab-apple", "blackthorn-sapling", "nettle-sprout"].map(id => { const el = mk(C(id)); o.append(put(el, 0, 0)); el.style.opacity = 0; return el; }); return h; },
  run(T, h) {
    const pl = h.plates[0], at = { x: 110, y: 858 };
    ptrMove(T, h.ptr, { x: 400, y: 700 }, at, T0, 360);
    ptrPress(T, h.ptr, at, T0 + 380); press(T, pl, T0 + 380);
    T.a(h.dim, [{ opacity: 0 }, { opacity: 1 }], T0 + 500, 160, EASE.out);
    const c0 = { x: 110 - W / 2, y: 858 - H / 2 };
    h.cc.forEach((el, i) => { const to = P(960 - 3 * 170 + i * 170 + 15, 360, (i - 2.5) * 1.5, 1);
      put(el, to.x, to.y); T.a(el, [{ opacity: 0 }, { opacity: 1 }], T0 + 500 + i * 35, 80, EASE.lin);
      fly(T, el, P(c0.x, c0.y, 0, .18), to, T0 + 500 + i * 35, 260, { lift: 120, ease: "out" });
      fly(T, el, to, P(c0.x, c0.y, 0, .18), T0 + 2600 + i * 15, 200, { ease: "in", fade: [1, 0] }); });
    T.a(h.dim, [{ opacity: 1 }, { opacity: 0 }], T0 + 2650, 200, EASE.in);
    plateTo(T, h, pl, 6, 6, T0 + 2800);
  } },

// ======================================================================= start of turn
{ id: "income", grp: "start", name: "Turn starts: turn number and income", tag: "changed",
  line: "The turn number flips; coins pour from the Next turn plate into your gold, which counts up as they land.",
  timing: "0.8 s. Gold counts over 0.3 s from the first coin. Now: both redraw at once.",
  crop: [0, 0, 1100, 1080],
  scene: R({ gold: 1, turn: 5, next: 15 }),
  run(T, h) {
    const sp = h.turn.querySelector("span"); sp.style.display = "inline-block";
    T.a(sp, [{ transform: "rotateX(0)" }, { transform: "rotateX(90deg)" }], T0, 120, EASE.in);
    T.text(sp, "6", T0 + 120);
    T.a(sp, [{ transform: "rotateX(-90deg)", color: "#ffd77a" }, { transform: "rotateX(0)", color: "#efe6d2" }], T0 + 120, 220, EASE.out);
    const pc = { x: 360, y: 988 };
    for (let k = 0; k < 4; k++) coinToGold(T, h, pc, "", T0 + 200 + k * 70, 400);
    goldTo(T, h, 1, 16, T0 + 600, 320);
    const b = h.nextPl.querySelector("b");
    T.a(b, [{ opacity: 1 }, { opacity: 0 }], T0 + 200, 150, EASE.lin);
    T.text(b, "+16", T0 + 700);
    T.a(b, [{ opacity: 0 }, { opacity: 1 }], T0 + 700, 200, EASE.out);
  } },
{ id: "newshop", grp: "start", name: "Turn starts: a new shop", tag: "changed",
  line: "Last turn's shop sinks away; the new one drops in left to right, each price tag swinging in after its card.",
  timing: "Out 0.15 s, in 50 ms apart, 0.6 s in all. Now: a 0.18 s cross-fade.",
  crop: [300, 0, 1320, 540],
  scene: st => { const h = recruit(st, base()); h.n = newShop(h, [C("sett-shield-bearer"), C("harvest-piper"), C("prophet-of-the-dust"), C("old-campaigner"), C("needle-page")], [SPELLS.seek, SPELLS.sharpen]); return h; },
  run(T, h) { shopOut(T, h, T0); shopIn(T, h.n, T0 + 200); } },
{ id: "thaw", grp: "start", name: "Turn starts: a frozen shop thaws", tag: "new",
  line: "The ice flashes and falls away card by card; the cards you froze stay.",
  timing: "0.25 s per card, 40 ms apart; 0.5 s in all. Now: the ice is gone at once.",
  crop: [300, 0, 1320, 540],
  scene: R({ frozen: true }),
  run(T, h) {
    const ices = [...h.shop.map(e => e.querySelector(".ice-o")), ...h.spells.map(e => e.querySelector(".ice-o")), h.frzBtn.querySelector(".ice-o")];
    ices.forEach((el, i) => T.a(el, [{ opacity: 1, transform: "scale(1)", filter: "brightness(1)" }, { opacity: 1, transform: "scale(1.02)", filter: "brightness(2.2)", offset: .3 }, { opacity: 0, transform: "scale(1.08) translateY(10px)", filter: "brightness(1)" }], T0 + i * 40, 260, EASE.out));
  } },
{ id: "grudge", grp: "start", name: "Grudge pays, at the start of your turn", tag: "new",
  line: "Every unit with Grudge lights together; its gain rises from its Grudge mark and drops into its numbers. One beat however many there are.",
  timing: "0.8 s for any number of units (50 ms apart). Replaces the silent after-fight pay.",
  crop: [560, 380, 800, 700],
  scene: R({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1, fired: "Grudge" }), C("hedge-knight"), C("armsbearer", { fired: "Grudge" }), C("padre"),
    C("sett-shield-bearer", { fired: "Grudge" }), C("colour-sergeant"), C("relic-seeker")] }),
  run(T, h) { fxGrudge(T, h, [0, 2, 4], T0); } },
{ id: "relic", grp: "start", name: "Relic Seeker's gold, at the start of your turn", tag: "new",
  line: "Relic Seeker lights and a coin arcs from it to your gold, which counts up as it lands.",
  timing: "0.8 s. Replaces the after-fight gold the notice never counted.",
  crop: [300, 100, 1000, 800],
  scene: R({}),
  run(T, h) { fxRelic(T, h, 4, T0, 2); } },
{ id: "campaigner", grp: "start", name: "Old Campaigner gives its slot Renown", tag: "new",
  line: "Old Campaigner lights; a gold star marked +2 (it survived) rises over it and drops onto its slot's Renown pill, which pops from 1 to 3, and its numbers rise with it.",
  timing: "0.8 s. Now: the slot's Renown pill and the numbers just change next turn.",
  crop: [560, 300, 800, 780],
  scene: R({}),
  run(T, h) { fxCampaigner(T, h, 2, T0, 2); } },
{ id: "hopper", grp: "start", name: "Horde Runner gets a Hopper", tag: "changed",
  line: "Horde Runner lights; the Hopper leaps out of it, grows as it arcs into the hand, and the hand opens to take it.",
  timing: "0.75 s. Now: the Hopper fades in, with nothing to say where from.",
  crop: [400, 380, 1100, 700],
  scene: R({}),
  run(T, h) { fxHopper(T, h, 6, T0); } },
{ id: "cutpurse", grp: "start", name: "Gold from the last fight (Shrew Cutpurse)", tag: "changed",
  line: "The gold arrives from the unit that earned it, as Relic Seeker's does, so no notice is needed.",
  timing: "0.8 s. Now: static words on the transom (\"+1 gold from the last fight\").",
  crop: [300, 100, 1000, 800],
  scene: R({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("shrew-cutpurse"), C("relic-seeker"), null, C("horde-runner")] }),
  run(T, h) { fxRelic(T, h, 3, T0, 1); } },
{ id: "queue", grp: "start", name: "Start of turn, all together", tag: "new",
  line: "Income and the new shop first, then each effect in board order. Each starts sooner than the last, so a long queue speeds up instead of dragging. You can act at once; a press finishes the queue.",
  timing: "About 2.7 s here (gaps 0.42, 0.36, 0.31 s). One effect alone keeps its full beat.",
  scene: st => { const h = recruit(st, base({ gold: 1, turn: 5, next: 15, board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1, fired: "Grudge" }), C("hedge-knight"), C("old-campaigner"), C("padre"), C("relic-seeker"), C("colour-sergeant"), C("horde-runner")] }));
    h.n = newShop(h, [C("sett-shield-bearer"), C("harvest-piper"), C("prophet-of-the-dust"), C("old-campaigner"), C("needle-page")], [SPELLS.seek, SPELLS.sharpen]); return h; },
  run(T, h) {
    const sp = h.turn.querySelector("span"); sp.style.display = "inline-block";
    T.a(sp, [{ transform: "rotateX(0)" }, { transform: "rotateX(90deg)" }], T0, 120, EASE.in); T.text(sp, "6", T0 + 120);
    T.a(sp, [{ transform: "rotateX(-90deg)" }, { transform: "rotateX(0)" }], T0 + 120, 220, EASE.out);
    for (let k = 0; k < 4; k++) coinToGold(T, h, { x: 360, y: 988 }, "", T0 + 200 + k * 70, 400);
    T.num(h.gold, 1, 16, T0 + 600, 320);
    shopOut(T, h, T0 + 100); shopIn(T, h.n, T0 + 300);
    let t = T0 + 1000;
    fxGrudge(T, h, [0], t, [2, 3]); t += 420;
    fxCampaigner(T, h, 2, t, 2); t += 360;
    const t2 = t + 110 + 420; fire(T, h.board[4], t); coinToGold(T, h, centre(h.board[4], -14), 2, t + 110); T.num(h.gold, 16, 18, t2, 260); t += 310;
    fxHopper(T, h, 6, t);
  } },

// ======================================================================= shop
{ id: "buy", grp: "shop", name: "Buy a unit into your hand", tag: "changed",
  line: "Carried as now. Let go over the hand, it flies to its place and hops; the hand opens for it. Its price tag drops off when lifted, and your gold counts down instead of jumping.",
  timing: "Lift 0.15 s, flight 0.25 s, hop 0.2 s; gold counts in 0.26 s. Keep: carry, flight and hop. Changed: gold and tag.",
  scene: R({}),
  run(T, h) {
    const el = h.shop[1], from = el._p, rel = P(1000, 760), to = handPose(3, 4);
    const t = carry(T, h.st, el, from, rel, T0 + 400, 520, h.ptr);
    T.a(h.tags[1], [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(14px)" }], T0 + 400, 140, EASE.in);
    ptrHide(T, h.ptr, t + 200);
    fly(T, el, { ...rel, s: 1.2 }, to, t, 250, { ease: "arrive", lean: 4 });
    hop(T, el, to, t + 250); el._p = to;
    refan(T, h.hand, 4, t, 220);
    goldTo(T, h, 9, 5, t);
    T.text(h.handN, "4", t + 250);
    T.at(t + 450, on => { el.style.zIndex = on ? 7 : 30; });
  } },
{ id: "buyboard", grp: "shop", name: "Buy straight onto the board", tag: "new",
  line: "Carried from the shop, the empty slots light; let go over one, the unit drops in and hops. Works with a full hand.",
  timing: "Same as playing a unit: drop 4 to 6 frames, hop 0.2 s; gold counts in 0.26 s.",
  scene: R({ hand: [C("lance-corporal"), C("master-at-arms"), C("sett-shield-bearer"), C("cousin"), C("private"), C("pip"), C("hopper")] }),
  run(T, h) {
    const lit = litSlot(h.st, 5), el = h.shop[3], [sx, sy] = slotXY(5), to = P(sx, sy);
    T.a(lit, [{ opacity: 0 }, { opacity: 1 }], T0 + 400, 120, EASE.out);
    T.a(h.tags[3], [{ opacity: 1 }, { opacity: 0 }], T0 + 400, 140, EASE.in);
    const t = carry(T, h.st, el, el._p, to, T0 + 400, 560, h.ptr);
    drop(T, el, to, t);
    T.a(lit, [{ opacity: 1 }, { opacity: 0 }], t, 150, EASE.in);
    goldTo(T, h, 9, 7, t);
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "sell", grp: "shop", name: "Sell a unit", tag: "changed",
  line: "Over the shop it shows what it sells for; let go, it shrinks into the shop and a coin flies to your gold.",
  timing: "0.45 s from let-go to gold. Now: the card fades and the gold jumps.",
  scene: st => { const h = recruit(st, base()); h.sz = add(st, `<div class="sellzone" style="width:${G.shopW + 40}px;height:${H + 30}px"><div>Sell for <span style="font-size:58px;display:flex">${coinN(1)}</span></div></div>`, G.shopL - 20, G.shopTop - 14); h.sz.style.opacity = 0; return h; },
  run(T, h) {
    const el = h.board[3], rel = P(1000, 160);
    const t = carry(T, h.st, el, el._p, rel, T0 + 400, 520, h.ptr);
    T.a(h.sz, [{ opacity: 0 }, { opacity: 1 }], T0 + 700, 120, EASE.out);
    path(T, el, t, [[0, { ...rel, s: 1.2 }, 1], [200, { ...rel, y: rel.y + 20, s: .3 }, 0]], "in");
    T.a(h.sz, [{ opacity: 1 }, { opacity: 0 }], t + 60, 150, EASE.in);
    const tg = coinToGold(T, h, { x: rel.x + W / 2, y: rel.y + H / 2 }, 1, t + 80, 360);
    goldTo(T, h, 9, 10, tg);
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "eat", grp: "shop", name: "Sell to an eater (Gorger)", tag: "changed",
  line: "The sold unit flies shrinking into Gorger, as now; then Gorger lights and its numbers rise by what it ate.",
  timing: "Flight 0.3 s (keep), Gorger lights 0.35 s after. Now: numbers pop with no light.",
  scene: R({ tier: 4, up: 9, board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("gorger"), C("relic-seeker"), null, C("horde-runner")] }),
  run(T, h) {
    const el = h.board[1], g = h.board[3], rel = P(860, 160);
    const t = carry(T, h.st, el, el._p, rel, T0 + 400, 500, h.ptr);
    fly(T, el, { ...rel, s: 1.2 }, { ...g._p, s: .35 }, t, 300, { ease: "out", fade: [1, .2] });
    T.a(el, [{ opacity: .2 }, { opacity: 0 }], t + 300, 40, EASE.lin);
    fire(T, g, t + 300, 300);
    gain(T, g, 2, 8, t + 420);
    goldTo(T, h, 9, 10, coinToGold(T, h, { x: rel.x + W / 2, y: rel.y + H / 2 }, 1, t + 40, 360));
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "compostsell", grp: "shop", name: "Sell a Seed into the Compost", tag: "keep",
  line: "A unit with Seed flies shrinking to the Compost plate, which pops; the coin goes to your gold as for any sale.",
  timing: "Flight 0.3 s, plate pop 0.35 s (both as now); the coin is new.",
  scene: R({ plates: [["bog", "Compost", 4]], board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("pip"), C("relic-seeker"), null, C("horde-runner")] }),
  run(T, h) {
    const el = h.board[3], rel = P(1000, 160);
    const t = carry(T, h.st, el, el._p, rel, T0 + 400, 500, h.ptr);
    fly(T, el, { ...rel, s: 1.2 }, P(110 - W / 2, 858 - H / 2, 0, .15), t, 300, { ease: "out", lift: 80, fade: [1, .3] });
    T.a(el, [{ opacity: .3 }, { opacity: 0 }], t + 300, 40, EASE.lin);
    plateTo(T, h, h.plates[0], 4, 5, t + 300);
    goldTo(T, h, 9, 10, coinToGold(T, h, { x: rel.x + W / 2, y: rel.y + H / 2 }, 1, t + 40, 360));
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "bury", grp: "shop", name: "Bury a shop unit (Hedge-layer)", tag: "changed",
  line: "Click Bury, then a shop unit: it flies shrinking into the Compost plate as now; then Hedge-layer lights and sends its gold.",
  timing: "Flight 0.3 s (keep); the effect 0.6 s after. Now: the gold just changes.",
  scene: st => { const h = recruit(st, base({ plates: [["bog", "Compost", 4]], board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-layer"), C("old-campaigner"), C("padre"), C("relic-seeker"), null, C("horde-runner")] }));
    const [x, y] = slotXY(1); h.bury = add(st, `<div class="btn abil">Bury</div>`, 0, 0); put(h.bury, x + (W - h.bury.offsetWidth) / 2, y + H * .62);
    h.lits = [0, 1, 2, 3, 4].map(i => { const [sx, sy] = shopXY(i), p = hexPts(W, H, .17).map(q => q.join(",")).join(" "); const e = add(st, `<svg class="lit" width="${W}" height="${H}" style="z-index:3"><polygon points="${p}"/><polygon class="glow" points="${p}"/><polygon class="edge" points="${p}"/></svg>`, sx, sy); e.style.opacity = 0; return e; });
    return h; },
  run(T, h) {
    const b = { x: h.bury._b.x + h.bury.offsetWidth / 2, y: h.bury._b.y + 16 };
    ptrMove(T, h.ptr, { x: 1000, y: 900 }, b, T0, 380); ptrPress(T, h.ptr, b, T0 + 400); press(T, h.bury, T0 + 400);
    h.lits.forEach((e, i) => T.a(e, [{ opacity: 0 }, { opacity: 1 }], T0 + 520 + i * 20, 120, EASE.out));
    message(T, h, "Choose a shop unit", T0 + 520, 700);
    const el = h.shop[2], at = { x: el._b.x + 70, y: el._b.y + 120 };
    ptrMove(T, h.ptr, b, at, T0 + 900, 400); ptrPress(T, h.ptr, at, T0 + 1310);
    h.lits.forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], T0 + 1400, 120, EASE.in));
    T.a(h.tags[2], [{ opacity: 1 }, { opacity: 0 }], T0 + 1400, 100, EASE.lin);
    fly(T, el, el._p, P(110 - W / 2, 858 - H / 2, 0, .15), T0 + 1400, 300, { ease: "out", lift: 60, fade: [1, .3] });
    T.a(el, [{ opacity: .3 }, { opacity: 0 }], T0 + 1700, 40, EASE.lin);
    plateTo(T, h, h.plates[0], 4, 5, T0 + 1700);
    T.a(h.bury, [{ opacity: 1 }, { opacity: .45 }], T0 + 1450, 200, EASE.lin);
    fire(T, h.board[1], T0 + 1850);
    goldTo(T, h, 9, 10, coinToGold(T, h, centre(h.board[1], -14), 1, T0 + 1960, 420));
    ptrHide(T, h.ptr, T0 + 2400);
  } },
{ id: "refresh", grp: "shop", name: "Refresh the shop", tag: "changed",
  line: "The button dips; the shop sinks and the new one drops in; the count above the button ticks down.",
  timing: "0.5 s from the click to a full shop. Now: a 0.18 s cross-fade; a place that rolls the same card doesn't change.",
  crop: [300, 0, 1320, 540],
  scene: st => { const h = recruit(st, base()); h.n = newShop(h, [C("cousin"), C("brock-cub"), C("sentry"), C("green-recruit"), C("hedge-knight")], [SPELLS.sharpen, SPELLS.seek]); return h; },
  run(T, h) {
    const at = { x: BXR + 70, y: BY1 + 34 };
    ptrMove(T, h.ptr, { x: 1500, y: 500 }, at, T0, 360); ptrPress(T, h.ptr, at, T0 + 380); press(T, h.refBtn, T0 + 380);
    T.text(h.left, "6 left at this price", T0 + 420);
    T.a(h.left, [{ transform: "scale(1.15)", color: "#ffe08a" }, { transform: "scale(1)", color: "#d9cfbb" }], T0 + 420, 300, EASE.out);
    goldTo(T, h, 9, 8, T0 + 420);
    shopOut(T, h, T0 + 420); shopIn(T, h.n, T0 + 560);
    ptrHide(T, h.ptr, T0 + 1500);
  } },
{ id: "freeze", grp: "shop", name: "Freeze and unfreeze", tag: "changed",
  line: "Ice spreads over the shop from the Freeze button's side, card by card, with a white glint; unfreezing melts it all at once.",
  timing: "Freeze 0.18 s per card, 35 ms apart (0.4 s); unfreeze 0.15 s. Now: instant.",
  crop: [300, 0, 1320, 540],
  scene: st => { const h = recruit(st, base()); h.ices = [...h.shop.map(e => e.appendChild(ice())), ...h.spells.map(e => e.appendChild(ice(true)))]; h.bice = h.frzBtn.appendChild(ice(false, true)); [...h.ices, h.bice].forEach(e => e.style.opacity = 0); return h; },
  run(T, h) {
    const at = { x: BXR + 88, y: BY2 + 34 };
    ptrMove(T, h.ptr, { x: 1500, y: 500 }, at, T0, 360); ptrPress(T, h.ptr, at, T0 + 380); press(T, h.frzBtn, T0 + 380);
    T.a(h.bice, [{ opacity: 0 }, { opacity: 1 }], T0 + 420, 150, EASE.out);
    const order = [4, 3, 2, 1, 0, 6, 5];
    order.forEach((i, k) => T.a(h.ices[i], [{ opacity: 0, transform: "scale(1.08)", filter: "brightness(2.4)" }, { opacity: 1, transform: "scale(1)", filter: "brightness(1)" }], T0 + 460 + k * 35, 180, EASE.out));
    ptrPress(T, h.ptr, at, T0 + 2000); press(T, h.frzBtn, T0 + 2000);
    [...h.ices, h.bice].forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], T0 + 2050, 150, EASE.in));
    ptrHide(T, h.ptr, T0 + 2600);
  } },
{ id: "tierup", grp: "shop", name: "Tier up", tag: "changed",
  line: "The button flashes and its tiers roll over; your gold counts down; a band of light sweeps across the shop.",
  timing: "0.45 s. Now: instant redraw.",
  crop: [300, 0, 1320, 540],
  scene: st => { const h = recruit(st, base()); h.sweep = add(st, `<div class="sweep" style="width:260px;height:${H + 60}px"></div>`, G.shopL - 300, G.shopTop - 30); h.sweep.style.opacity = 0; return h; },
  run(T, h) {
    const at = { x: BXL + 70, y: BY2 + 34 };
    ptrMove(T, h.ptr, { x: 600, y: 600 }, at, T0, 360); ptrPress(T, h.ptr, at, T0 + 380);
    T.a(h.tierBtn, [{ filter: "brightness(1)", transform: "scale(1)" }, { filter: "brightness(1.7) drop-shadow(0 0 16px rgba(255,190,90,.9))", transform: "scale(1.06)", offset: .3 }, { filter: "brightness(1)", transform: "scale(1)" }], T0 + 380, 420, EASE.out);
    const sp = h.tierBtn.querySelector(".tl span"); sp.style.display = "inline-block";
    T.a(sp, [{ transform: "rotateX(0)" }, { transform: "rotateX(90deg)" }], T0 + 400, 110, EASE.in); T.text(sp, "4 → 5", T0 + 510);
    T.a(sp, [{ transform: "rotateX(-90deg)" }, { transform: "rotateX(0)" }], T0 + 510, 180, EASE.out);
    const cn = h.tierBtn.querySelector("svg.coinn"); T.html(cn, coinN(9).replace(/^<svg[^>]*>/, "").replace(/<\/svg>$/, ""), T0 + 510);
    goldTo(T, h, 9, 2, T0 + 420);
    T.a(h.sweep, [{ opacity: 0, transform: "translateX(0)" }, { opacity: 1, offset: .2 }, { opacity: 1, offset: .8 }, { opacity: 0, transform: `translateX(${G.shopW + 340}px)` }], T0 + 460, 480, EASE.inout);
    ptrHide(T, h.ptr, T0 + 1400);
  } },
{ id: "poor", grp: "shop", name: "Not enough gold", tag: "changed",
  line: "Let go over the hand, the card flies home; the gold shakes and flashes red, and the reason shows on the transom.",
  timing: "Flight home 0.25 s (keep); shake 0.24 s; words hold 1.5 s. Now: words only.",
  scene: R({ gold: 1 }),
  run(T, h) {
    const el = h.shop[2], home = el._p, rel = P(980, 760);
    const t = carry(T, h.st, el, home, rel, T0 + 400, 480, h.ptr);
    fly(T, el, { ...rel, s: 1.2 }, home, t, 250, { ease: "arrive", lean: -5 }); hop(T, el, home, t + 250);
    T.at(t + 450, on => { el.style.zIndex = on ? 2 : 30; });
    T.a(h.goldBtn, [0, -7, 7, -6, 6, -3, 0].map(x => ({ transform: `translateX(${x}px)` })), t, 240, EASE.lin);
    T.a(h.gold, [{ color: "#f2cf73" }, { color: "#ff6a4a", offset: .2 }, { color: "#ff6a4a", offset: .6 }, { color: "#f2cf73" }], t, 500, EASE.lin);
    message(T, h, "Not enough gold.", t, 1500);
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "dupes", grp: "shop", name: "Duplicate and triple light, as the hand and board change", tag: "changed",
  line: "A shop copy of a unit you own has a soft glow. When one more buy would make a triple, all three copies flare to the strong glow and breathe; when that stops being true it fades back.",
  timing: "Flare 0.15 s, fade 0.25 s; the triple breath 1.4 s, as now. Now: marks snap on each redraw.",
  scene: st => { const h = recruit(st, base({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("padre"), C("relic-seeker"), null, C("horde-runner")] }));
    h.n = newShop(h, [C("cousin"), C("sentry"), C("brock-cub"), C("green-recruit"), C("pip")]); return h; },
  run(T, h) {
    const MATCH = "drop-shadow(0 0 4px #fff3c4) drop-shadow(0 0 12px rgba(255,226,150,.85)) drop-shadow(0 6px 8px rgba(0,0,0,.6))";
    const TRI = "drop-shadow(0 0 4px #fff6c8) drop-shadow(0 0 12px #ffc23a) drop-shadow(0 0 26px rgba(255,150,20,.95))";
    const TRI_LO = "drop-shadow(0 0 3px #fff6c8) drop-shadow(0 0 8px rgba(255,194,58,.6)) drop-shadow(0 0 14px rgba(255,150,20,.45))";
    const FLARE = "brightness(1.5) drop-shadow(0 0 10px #fffbe6) drop-shadow(0 0 24px #ffc23a) drop-shadow(0 0 40px rgba(255,150,20,1))";
    const NONE = REST;
    const shopCub = h.shop[0], boardCub = h.board[0];
    T.a(shopCub, [{ filter: MATCH }, { filter: MATCH }], 0, 1, EASE.lin);
    // 1: buy the shop cub into the hand: two owned, none in the shop, so no light
    const rel = P(1000, 760), to = handPose(3, 4);
    T.a(shopCub, [{ filter: MATCH }, { filter: NONE }], T0 + 400, 150, EASE.lin);
    const t = carry(T, h.st, shopCub, shopCub._p, rel, T0 + 400, 480, h.ptr);
    T.a(h.tags[0], [{ opacity: 1 }, { opacity: 0 }], T0 + 400, 140, EASE.in);
    fly(T, shopCub, { ...rel, s: 1.2 }, to, t, 250, { ease: "arrive" }); hop(T, shopCub, to, t + 250); shopCub._p = to;
    refan(T, h.hand, 4, t, 220); goldTo(T, h, 9, 7, t); T.text(h.handN, "4", t + 250);
    T.at(t + 450, on => { shopCub.style.zIndex = on ? 7 : 30; });
    ptrHide(T, h.ptr, t + 200);
    // 2: refresh brings the third: all three flare, then breathe
    const t2 = t + 900;
    press(T, h.refBtn, t2); const rest = h.shop.filter((e, i) => i > 0);
    shopOut(T, h, t2, [null, ...rest], [null, ...h.tags.slice(1)], []); shopIn(T, h.n, t2 + 150);
    const t3 = t2 + 150 + 2 * 50 + 240, tri = [h.n.shop[2], boardCub, shopCub];
    tri.forEach(e => { T.a(e, [{ filter: NONE }, { filter: FLARE, offset: .4 }, { filter: TRI }], t3, 250, EASE.out);
      T.a(e, [{ filter: TRI }, { filter: TRI_LO }, { filter: TRI }, { filter: TRI_LO }, { filter: TRI }], t3 + 250, 2800, EASE.inout); });
    // 3: sell the board cub: one owned, so the shop copy steps down to the soft glow and the hand copy goes dark
    const t4 = t3 + 3100, srel = P(1000, 160);
    const t5 = carry(T, h.st, boardCub, boardCub._p, srel, t4, 480, h.ptr);
    path(T, boardCub, t5, [[0, { ...srel, s: 1.2 }, 1], [200, { ...srel, y: srel.y + 20, s: .3 }, 0]], "in");
    goldTo(T, h, 7, 8, coinToGold(T, h, { x: srel.x + 70, y: srel.y + 125 }, 1, t5 + 80, 360));
    T.a(h.n.shop[2], [{ filter: TRI }, { filter: MATCH }], t5 + 60, 250, EASE.out);
    T.a(shopCub, [{ filter: TRI }, { filter: NONE }], t5 + 60, 250, EASE.out);
    ptrHide(T, h.ptr, t5 + 200);
  } },
{ id: "triple", grp: "shop", name: "A triple forms, and its Triple Reward", tag: "keep",
  line: "As built: the three copies lift, gather, charge and flash; the golden unit is revealed, lands in the hand, and the Triple Reward comes out under it and follows.",
  timing: "2.25 s (the build's beats: lift 14, gather 22, charge 14, flash 8, reveal 20, land 20, reward 27, tail 10 frames). A press finishes it. Re-created here roughly.",
  scene: st => { const h = recruit(st, base({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), null, C("relic-seeker"), null, C("horde-runner")],
      hand: [C("lance-corporal"), C("brock-cub"), C("sett-shield-bearer")] }));
    h.halo = add(st, `<div class="halo"></div>`, 960 - 205, 570 - 205); h.rays = add(st, `<div class="rays"></div>`, 960 - 260, 570 - 260); h.flash = add(st, `<div class="flash"></div>`, 960 - 170, 570 - 170);
    [h.halo, h.rays, h.flash].forEach(e => e.style.opacity = 0);
    h.gold1 = mk(C("brock-cub", { golden: true, attack: 4, health: 12, pills: ["Fury 2", "Grudge"] })); st.append(put(h.gold1, 960 - W / 2, 570 - H / 2)); h.gold1.style.opacity = 0; h.gold1.style.zIndex = 31;
    h.reward = mk(SPELLS.reward); st.append(put(h.reward, 960 - W / 2, 570)); h.reward.style.opacity = 0; h.reward.style.zIndex = 30;
    return h; },
  run(T, h) {
    const f = n => n * 1000 / 60;
    const el = h.shop[0], [sx, sy] = slotXY(3), to = P(sx, sy);
    T.a(h.tags[0], [{ opacity: 1 }, { opacity: 0 }], T0 + 400, 140, EASE.in);
    let t = carry(T, h.st, el, el._p, to, T0 + 400, 520, h.ptr); drop(T, el, to, t); ptrHide(T, h.ptr, t + 200);
    t += 200;
    const three = [h.board[0], el, h.hand[1]], hub = { x: 960 - W / 2, y: 570 - H / 2 };
    three.forEach((e, k) => { const p = e._p, up = { ...p, y: p.y - 28, r: 0, s: 1.05 }, sp = P(hub.x + (k - 1) * 110, hub.y, (k - 1) * 6, 1);
      const z0 = e.style.zIndex; T.at(t, on => { e.style.zIndex = on ? 29 : z0; });
      path(T, e, t, [[0, p], [f(14), up]], "out");
      fly(T, e, up, sp, t + f(14), f(22), { ease: "inout" });
      path(T, e, t + f(36), [[0, sp, 1], [f(14), { ...sp, x: hub.x + (k - 1) * 30, s: .9 }, 1], [f(22), { ...hub, s: .6 }, 0]], "in"); });
    const tf0 = t + f(50);
    T.a(h.halo, [{ opacity: 0, transform: "scale(.4)" }, { opacity: 1, transform: "scale(1)" }], t + f(36), f(14), EASE.out);
    T.a(h.flash, [{ opacity: 0, transform: "scale(.3)" }, { opacity: 1, transform: "scale(1)", offset: .4 }, { opacity: 0, transform: "scale(1.4)" }], tf0, f(8) + 120, EASE.out);
    T.a(h.rays, [{ opacity: 0, transform: "rotate(0deg) scale(.6)" }, { opacity: 1, transform: "rotate(25deg) scale(1)", offset: .3 }, { opacity: 0, transform: "rotate(60deg) scale(1.1)" }], tf0, f(48), EASE.out);
    const rv = P(hub.x, hub.y, 0, 1.22), dest = handPose(1, 4);
    T.a(h.gold1, [{ opacity: 0 }, { opacity: 1 }], tf0 + f(4), f(6), EASE.lin);
    path(T, h.gold1, tf0 + f(4), [[0, { ...rv, s: .8 }], [f(16), rv]], "back");
    fly(T, h.gold1, rv, dest, tf0 + f(28), f(20), { lift: 90, ease: "arrive" }); hop(T, h.gold1, dest, tf0 + f(48));
    T.a(h.halo, [{ opacity: 1 }, { opacity: 0 }], tf0 + f(28), f(20), EASE.in);
    T.at(tf0 + f(60), on => { h.gold1.style.zIndex = on ? 5 : 31; });
    const r0 = P(hub.x + 120, hub.y + 100, 0, .5), rd = handPose(3, 4);
    T.a(h.reward, [{ opacity: 0 }, { opacity: 1 }], tf0 + f(40), f(6), EASE.lin);
    path(T, h.reward, tf0 + f(40), [[0, { ...r0, s: .3 }], [f(10), { ...r0, s: 1 }]], "back");
    fly(T, h.reward, { ...r0, s: 1 }, rd, tf0 + f(52), 250, { lift: 60, ease: "arrive" }); hop(T, h.reward, rd, tf0 + f(52) + 250);
    T.at(tf0 + f(52) + 450, on => { h.reward.style.zIndex = on ? 7 : 30; });
    T.text(h.handN, "4", tf0 + f(52) + 250);
    [h.hand[0], h.hand[2]].forEach((e, k) => { const p2 = handPose(k === 0 ? 0 : 2, 4); fly(T, e, e._p, p2, tf0 + f(30), 220, { ease: "out", n: 6 }); });
  } },
{ id: "rewardwait", grp: "shop", name: "Triple Reward with a full hand", tag: "new",
  line: "The golden unit fills the hand's last place, so the Triple Reward goes to the waiting stack instead of being lost.",
  timing: "As the triple's reward beat (0.45 s), into the stack instead of the hand.",
  scene: st => { const h = recruit(st, base({ hand: [C("lance-corporal"), C("master-at-arms"), C("sett-shield-bearer"), C("cousin"), C("private"), C("pip"), C("brock-cub", { golden: true, attack: 4, health: 12, pills: ["Fury 2", "Grudge"] })] }));
    h.reward = mk(SPELLS.reward); st.append(put(h.reward, WAIT.x, WAIT.y)); h.reward.style.opacity = 0; h.reward.style.zIndex = 30; return h; },
  run(T, h) {
    const r0 = P(960 - W / 2 + 120, 570 - H / 2 + 100, 0, 1), to = waitPose(0);
    T.a(h.reward, [{ opacity: 0 }, { opacity: 1 }], T0, 100, EASE.lin);
    path(T, h.reward, T0, [[0, { ...r0, s: .3 }], [170, r0]], "back");
    fly(T, h.reward, r0, to, T0 + 450, 320, { lift: 80, ease: "arrive", lean: 5 }); hop(T, h.reward, to, T0 + 770, H * WS);
    T.text(h.waitBadge, "1", T0 + 770);
    T.a(h.waitBadge, [{ opacity: 0, transform: "scale(1.8)" }, { opacity: 1, transform: "scale(1)" }], T0 + 770, 260, EASE.out);
    T.a(h.handLbl, [{ transform: "translateX(0)" }, { transform: "translateX(-5px)" }, { transform: "translateX(5px)" }, { transform: "translateX(0)" }], T0 + 450, 200, EASE.lin);
  } },

// ======================================================================= hand and board
{ id: "carry", grp: "hand", name: "Pick up and carry a card", tag: "keep",
  line: "As built: lifts 1.2x and rises in 9 frames, then hangs from the pointer, leaning into its travel; every slot it can go to lights.",
  timing: "Lift 0.15 s; lean follows a spring. Re-created roughly; the build's own feel is the reference.",
  scene: st => { const h = recruit(st, base()); h.lit = litSlot(st, 5); return h; },
  run(T, h) {
    const el = h.hand[1], home = el._p;
    T.a(h.lit, [{ opacity: 0 }, { opacity: 1 }], T0 + 400, 120, EASE.out);
    const t = carry(T, h.st, el, home, P(520, 560), T0 + 400, 600, h.ptr);
    fly(T, el, P(520, 560, 0, 1.2), P(1240, 520, 0, 1.2), t, 700, { lean: 9 });
    ptrMove(T, h.ptr, { x: 520 + 66, y: 560 + 112 }, { x: 1240 + 66, y: 520 + 112 }, t, 700);
    fly(T, el, P(1240, 520, 0, 1.2), { ...home, s: 1.2 }, t + 750, 600, { lean: -7 });
    ptrMove(T, h.ptr, { x: 1240 + 66, y: 520 + 112 }, { x: home.x + 66, y: home.y + 112 }, t + 750, 600);
    drop(T, el, home, t + 1350); T.at(t + 1640, on => { el.style.zIndex = on ? 5 : 30; });
    T.a(h.lit, [{ opacity: 1 }, { opacity: 0 }], t + 1350, 150, EASE.in);
    ptrHide(T, h.ptr, t + 1500);
  } },
{ id: "playunit", grp: "hand", name: "Play a unit from the hand", tag: "keep",
  line: "As built: let go over a lit slot, it drops in and hops; the hand closes the gap.",
  timing: "Drop 4 to 6 frames, hop 0.2 s, hand closes in 0.2 s.",
  scene: st => { const h = recruit(st, base()); h.lit = litSlot(st, 5); return h; },
  run(T, h) {
    const el = h.hand[0], [sx, sy] = slotXY(5), to = P(sx, sy);
    T.a(h.lit, [{ opacity: 0 }, { opacity: 1 }], T0 + 400, 120, EASE.out);
    const t = carry(T, h.st, el, el._p, to, T0 + 400, 520, h.ptr);
    drop(T, el, to, t); T.a(h.lit, [{ opacity: 1 }, { opacity: 0 }], t, 150, EASE.in);
    refan(T, [h.hand[1], h.hand[2]], 2, t, 200); T.text(h.handN, "2", t);
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "whenplayed", grp: "hand", name: "A Recruit effect (Harvest Piper)", tag: "new",
  line: "Bought, it lands in the hand as any buy does, then lights; its gain flies to every unit it gives to at once, and their numbers rise.",
  timing: "0.6 s after it lands, however many targets. Now: the targets' numbers just pop.",
  scene: st => recruit(st, base({ shop: [C("brock-cub"), C("harvest-piper"), C("needle-page"), C("pip"), C("hedge-knight")],
    board: [C("needle-page"), C("shrew-cutpurse"), C("old-campaigner"), C("padre"), C("cousin"), null, C("horde-runner")], hand: [C("lance-corporal"), C("sett-shield-bearer")] })),
  run(T, h) {
    const el = h.shop[1], rel = P(1000, 760), to = handPose(2, 3);
    let t = carry(T, h.st, el, el._p, rel, T0 + 400, 520, h.ptr);
    T.a(h.tags[1], [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(14px)" }], T0 + 400, 140, EASE.in);
    ptrHide(T, h.ptr, t + 200);
    fly(T, el, { ...rel, s: 1.2 }, to, t, 250, { ease: "arrive", lean: 4 }); hop(T, el, to, t + 250); el._p = to;
    refan(T, h.hand, 3, t, 220); goldTo(T, h, 9, 6, t); T.text(h.handN, "3", t + 250);
    T.at(t + 450, on => { el.style.zIndex = on ? 6 : 30; });
    // it stands up out of the fan to fire, as a hovered hand card does, then settles back
    const up = P(to.x, 1080 - H - 24, 0, 1.06);
    t += 470; path(T, el, t - 150, [[0, to], [150, up]], "out"); el._p = up; fire(T, el, t, 300, up);
    path(T, el, t + 900, [[0, up], [120, to]], "in");
    // "Recruit: Give your other Mice +5 Attack." Its Mice: Needle Page, Shrew Cutpurse, Cousin
    [0, 1, 4].forEach((i, k) => { const u = h.board[i], p = gainPill(h.st, "+5"); p.classList.add("atk");
      const a = { x: u._p.x + 0.198 * W, y: u._p.y + 0.778 * H };
      gainFly(T, h.st, p, centre(el, -14), a, t + 110 + k * 30, 340, { w: 64, h: 44, lift: 70, ringR: 34 });
      gain(T, u, 5, 0, t + 450 + k * 30); });
  } },
{ id: "aim", grp: "hand", name: "Choose a target (Master-at-Arms)", tag: "changed",
  line: "Bought, it lands in the hand; the units it can give to breathe while you choose. Pick one and Master-at-Arms lights, its gift flies there and stamps onto the mark.",
  timing: "Rims breathe 1.4 s; the effect 0.55 s after the click. Now: still rims, then numbers pop.",
  scene: st => { const h = recruit(st, base({ shop: [C("brock-cub"), C("famine-caller"), C("master-at-arms"), C("pip"), C("hedge-knight")], hand: [C("lance-corporal"), C("sett-shield-bearer")] }));
    h.tl = [0, 1, 2, 3, 4, 6].map(i => litSlot(st, i, 3)); return h; },
  run(T, h) {
    const el = h.shop[2], rel = P(1000, 760), to = handPose(2, 3);
    let t = carry(T, h.st, el, el._p, rel, T0 + 400, 520, h.ptr);
    T.a(h.tags[2], [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(14px)" }], T0 + 400, 140, EASE.in);
    fly(T, el, { ...rel, s: 1.2 }, to, t, 250, { ease: "arrive", lean: 4 }); hop(T, el, to, t + 250); el._p = to;
    refan(T, h.hand, 3, t, 220); goldTo(T, h, 9, 5, t); T.text(h.handN, "3", t + 250);
    T.at(t + 450, on => { el.style.zIndex = on ? 6 : 30; });
    t += 450;
    message(T, h, "Choose a unit", t + 200, 900);
    h.tl.forEach(e => T.a(e, [{ opacity: 0 }, { opacity: 1, offset: .15 }, { opacity: .35, offset: .55 }, { opacity: 1, offset: .9 }, { opacity: 1 }], t + 200, 1400, EASE.inout));
    // its target can be a unit in the hand too (dev: a friendly unit, hand or board)
    const HG = "drop-shadow(0 0 6px #ffe7a6) drop-shadow(0 0 16px rgba(255,190,90,.9)) drop-shadow(0 6px 8px rgba(0,0,0,.6))";
    [h.hand[0], h.hand[1]].forEach(e => T.a(e, [{ filter: REST }, { filter: HG, offset: .15 }, { filter: REST, offset: .55 }, { filter: HG, offset: .9 }, { filter: REST }], t + 200, 1300, EASE.inout));
    const tgt = h.board[0], at = { x: tgt._p.x + 70, y: tgt._p.y + 110 };
    ptrMove(T, h.ptr, h.ptr._last, at, t + 500, 500); ptrPress(T, h.ptr, at, t + 1020);
    h.tl.forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], t + 1100, 150, EASE.in));
    const t2 = t + 1100, up = P(to.x, 1080 - H - 24, 0, 1.06);
    path(T, el, t2 - 150, [[0, to], [150, up]], "out"); el._p = up; fire(T, el, t2, 260, up);
    path(T, el, t2 + 800, [[0, up], [120, to]], "in");
    const mark = html(`<span class="kwc f-strike fxmark" style="width:44px;height:44px"><svg viewBox="0 0 24 24">${IC.flame}</svg><em style="font-size:20px">+1</em></span>`);
    h.st.append(mark); mark.style.position = "absolute";
    const m1 = { x: tgt._p.x + W / 2 - 22 - 12, y: tgt._p.y + 0.925 * H - 22 };
    gainFly(T, h.st, mark, { x: centre(el).x, y: centre(el).y - 30 }, { x: m1.x + 22, y: m1.y + 22 }, t2 + 110, 380, { w: 44, h: 44, lift: 100, s0: .7, s1: 1.2, ringR: 40, colour: "255,140,90" });
    marks(T, tgt, ["Fury 2", "Grudge"], t2 + 500);
    T.at(t2 + 501, on => { const e = tgt.querySelector('.kwc[title="Fury"]'); if (on && e) e.animate([{ transform: "scale(1.8)" }, { transform: "scale(1)" }], { duration: 300, easing: EASE.out }); });
    ptrHide(T, h.ptr, t2 + 300);
  } },
{ id: "spell", grp: "hand", name: "Cast a spell on a unit (Sharpen)", tag: "changed",
  line: "Let go over its target, the spell flashes and breaks into glass that flies into the unit; the unit lights and its numbers rise.",
  timing: "0.55 s from let-go. Now: the spell fades and the numbers pop.",
  scene: st => { const h = recruit(st, base({ hand: [C("lance-corporal"), SPELLS.sharpen, C("sett-shield-bearer")] })); h.tl = [0, 1, 2, 3, 4, 6].map(i => litSlot(st, i, 3));
    h.shards = Array.from({ length: 7 }, (_, i) => { const e = add(st, `<div class="shard" style="background-image:url(assets/art/spell-1.jpg);background-position:${i * 15}% ${i * 11}%"></div>`, 0, 0); e.style.opacity = 0; return e; }); return h; },
  run(T, h) {
    const el = h.hand[1], tgt = h.board[1], over = P(tgt._p.x, tgt._p.y - 70);
    h.tl.forEach(e => T.a(e, [{ opacity: 0 }, { opacity: 1 }], T0 + 400, 120, EASE.out));
    const t = carry(T, h.st, el, el._p, over, T0 + 400, 520, h.ptr);
    h.tl.forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], t, 150, EASE.in));
    T.a(el, [{ filter: REST, opacity: 1 }, { filter: "brightness(2.2) drop-shadow(0 0 20px #fff2c0)", opacity: 1, offset: .6 }, { filter: "brightness(3)", opacity: 0 }], t, 160, EASE.out);
    refan(T, [h.hand[0], h.hand[2]], 2, t + 100, 200); T.text(h.handN, "2", t + 100);
    const c0 = { x: over.x + W / 2, y: over.y + H / 2 - 20 }, c1 = centre(tgt);
    h.shards.forEach((s, k) => { const a = k / 7 * Math.PI * 2, burst = { x: c0.x + Math.cos(a) * 110 - 28, y: c0.y + Math.sin(a) * 110 - 28 };
      put(s, c1.x - 28, c1.y - 28);
      T.a(s, [{ opacity: 0 }, { opacity: 1 }], t + 120, 40, EASE.lin);
      path(T, s, t + 120 + k * 12, [[0, P(c0.x - 28, c0.y - 28, 0, .6)], [130, P(burst.x, burst.y, k * 50, 1)], [340, P(c1.x - 28, c1.y - 28, k * 90, .4)]], "inout");
      T.a(s, [{ opacity: 1 }, { opacity: 0 }], t + 440 + k * 12, 40, EASE.lin); });
    ring(T, h.st, c1.x, c1.y, t + 430, 80, "190,230,255");
    fire(T, tgt, t + 430, 200);
    gain(T, tgt, 2, 2, t + 500);
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "order", grp: "hand", name: "Use an Active (Lance Corporal)", tag: "changed",
  line: "Click its coin: it dips and pays, the unit lights, and a star of Renown flies to each slot in front; each slot's Renown pill pops and the unit there gains it in its numbers.",
  timing: "0.65 s from the click. Now: the Renown pills redraw and numbers pop.",
  scene: st => { const h = recruit(st, base({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("padre"), C("relic-seeker"), C("lance-corporal"), C("horde-runner")] }));
    // dev's Active: a round button with no name, holding its cost as a coin
    const [x, y] = slotXY(5); h.ob = add(st, `<div class="btn abil act">${coinN(1)}</div>`, 0, 0); put(h.ob, x + (W - h.ob.offsetWidth) / 2, y + H * .62); return h; },
  run(T, h) {
    const b = { x: h.ob._b.x + h.ob.offsetWidth / 2, y: h.ob._b.y + 22 };
    ptrMove(T, h.ptr, { x: 1000, y: 950 }, b, T0, 380); ptrPress(T, h.ptr, b, T0 + 400); press(T, h.ob, T0 + 400);
    goldTo(T, h, 9, 8, T0 + 420);
    T.a(h.ob, [{ opacity: 1 }, { opacity: .45 }], T0 + 600, 200, EASE.lin);
    const el = h.board[5]; fire(T, el, T0 + 450, 300);
    // "1: Give the slots in front of this 2 Renown."
    [1, 2].forEach(i => { const [sx, sy] = slotXY(i), m = starEl(h.st, "+2");
      gainFly(T, h.st, m, centre(el, -30), { x: sx + W / 2, y: sy + 10 }, T0 + 560, 340, { w: 60, h: 60, lift: 90, s0: .5, s1: .8, ringR: 40 });
      addRenown(T, h, i, 2, T0 + 900); });
    ptrHide(T, h.ptr, T0 + 1300);
  } },
{ id: "reorder", grp: "hand", name: "Rearrange the board", tag: "keep",
  line: "As built: let go on another unit, they swap; the other slides over.",
  timing: "Drop 4 to 6 frames and hop; the other slides in 0.2 s.",
  scene: R({}),
  run(T, h) {
    const a = h.board[0], b = h.board[1], pa = a._p, pb = b._p;
    const t = carry(T, h.st, a, pa, pb, T0 + 400, 520, h.ptr);
    drop(T, a, pb, t); fly(T, b, pb, pa, t, 200, { ease: "out", n: 6 }); b._p = pa;
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "tohand", grp: "hand", name: "Take a board unit back into the hand", tag: "keep",
  line: "As built: let go over the hand, it flies into the fan and hops; the hand opens for it.",
  timing: "Flight 0.25 s, hop 0.2 s.",
  scene: R({}),
  run(T, h) {
    const el = h.board[3], rel = P(1040, 780), to = handPose(3, 4);
    const t = carry(T, h.st, el, el._p, rel, T0 + 400, 520, h.ptr);
    fly(T, el, { ...rel, s: 1.2 }, to, t, 250, { ease: "arrive" }); hop(T, el, to, t + 250);
    refan(T, h.hand, 4, t, 220); T.text(h.handN, "4", t + 250);
    T.at(t + 450, on => { el.style.zIndex = on ? 7 : 30; });
    ptrHide(T, h.ptr, t + 200);
  } },
{ id: "swap", grp: "hand", name: "Swap a hand card with a board unit", tag: "new",
  line: "Carry a hand card over an occupied slot: that unit lifts a little to show it will move. Let go: the new unit drops in and the old one arcs into the hand where the new one was.",
  timing: "The two cross in 0.28 s, then each hops. Now: refused with \"choose an empty slot\".",
  scene: st => { const h = recruit(st, base({ board: [C("brock-cub", { attack: 3, health: 8, upA: 1, upH: 1 }), C("hedge-knight"), C("old-campaigner"), C("padre"), C("relic-seeker"), C("colour-sergeant"), C("horde-runner")] })); h.lit = litSlot(st, 3, 3); return h; },
  run(T, h) {
    const el = h.hand[1], home = el._p, b = h.board[3], pb = b._p;
    const t = carry(T, h.st, el, home, pb, T0 + 400, 560, h.ptr);
    T.a(h.lit, [{ opacity: 0 }, { opacity: 1 }], t - 200, 120, EASE.out);
    path(T, b, t - 200, [[0, pb], [140, { ...pb, y: pb.y - 12, s: .94 }]], "out");
    T.a(b, [{ filter: REST }, { filter: "brightness(.85) drop-shadow(0 6px 8px rgba(0,0,0,.6))" }], t - 200, 140, EASE.out);
    drop(T, el, pb, t);
    T.a(h.lit, [{ opacity: 1 }, { opacity: 0 }], t, 150, EASE.in);
    T.at(t, on => { b.style.zIndex = on ? 28 : 2; });
    fly(T, b, { ...pb, y: pb.y - 12, s: .94 }, home, t, 280, { lift: 120, ease: "arrive", lean: -6 });
    T.a(b, [{ filter: "brightness(.85) drop-shadow(0 6px 8px rgba(0,0,0,.6))" }, { filter: REST }], t, 200, EASE.out);
    hop(T, b, home, t + 280);
    T.at(t + 480, on => { b.style.zIndex = on ? 5 : 28; });
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "towait", grp: "hand", name: "A card arrives with a full hand: it waits", tag: "new",
  line: "Instead of being lost, the card flies to a small waiting stack beside the hand and the stack's count pops.",
  timing: "Same flight as into the hand (0.43 s) and a small hop. Now: the card is lost and nothing says so.",
  crop: [400, 380, 1300, 700],
  scene: R({ hand: [C("lance-corporal"), C("master-at-arms"), C("sett-shield-bearer"), C("cousin"), C("private"), C("pip"), C("needle-page")] }),
  run(T, h) { fxHopper(T, h, 6, T0, true); } },
{ id: "fromwait", grp: "hand", name: "Room frees: the waiting card slides into the hand", tag: "new",
  line: "Play a card out of a full hand and the waiting card slides from its stack into the hand at once; the stack's count goes.",
  timing: "Starts as the played card lands; slide 0.32 s and hop. The hand count dips and comes back.",
  scene: st => { const h = recruit(st, base({ hand: [C("lance-corporal"), C("master-at-arms"), C("sett-shield-bearer"), C("cousin"), C("private"), C("pip"), C("needle-page")], waiting: [C("hopper")] })); h.lit = litSlot(st, 5); return h; },
  run(T, h) {
    const el = h.hand[3], [sx, sy] = slotXY(5), to = P(sx, sy);
    T.a(h.lit, [{ opacity: 0 }, { opacity: 1 }], T0 + 400, 120, EASE.out);
    const t = carry(T, h.st, el, el._p, to, T0 + 400, 520, h.ptr);
    drop(T, el, to, t); T.a(h.lit, [{ opacity: 1 }, { opacity: 0 }], t, 150, EASE.in);
    const rest = h.hand.filter((e, i) => i !== 3);
    refan(T, rest, 6, t, 200); T.text(h.handN, "6", t);
    const w = h.waiting[0], dest = handPose(6, 7);
    T.at(t + 120, on => { w.style.zIndex = on ? 12 : 3; });
    fly(T, w, w._p, dest, t + 120, 320, { ease: "inout", lift: 40 });
    T.a(h.waitBadge, [{ opacity: 1, transform: "scale(1)" }, { opacity: 0, transform: "scale(.4)" }], t + 120, 160, EASE.in);
    refan(T, rest, 7, t + 200, 220); T.text(h.handN, "7", t + 440);
    hop(T, w, dest, t + 440);
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "discover", grp: "hand", name: "Discover opens (Seek)", tag: "changed",
  line: "Cast the spell: the room dims and the options rise out of where the spell was, spreading into a row.",
  timing: "Veil 0.18 s; options 0.28 s each, 60 ms apart. Now: veil and options appear at once.",
  scene: st => { const h = recruit(st, base({ hand: [C("lance-corporal"), SPELLS.seek, C("sett-shield-bearer")] })); h.veil = add(st, `<div id="dim" style="z-index:20"></div>`, 0, 0); h.veil.style.opacity = 0;
    h.prompt = title(st, "Discover a unit", 960, 150, 40); h.prompt.style.zIndex = 22; h.prompt.style.opacity = 0;
    h.opts = ["sett-shield-bearer", "harvest-piper", "old-campaigner"].map(id => { const e = mk(C(id)); st.append(put(e, 0, 0)); e.style.zIndex = 21; e.style.opacity = 0; return e; }); return h; },
  run(T, h) {
    const el = h.hand[1], rel = P(890, 520);
    const t = carry(T, h.st, el, el._p, rel, T0 + 400, 520, h.ptr);
    T.a(el, [{ opacity: 1, filter: REST }, { opacity: 0, filter: "brightness(2.4)" }], t, 180, EASE.out);
    T.a(h.veil, [{ opacity: 0 }, { opacity: 1 }], t, 180, EASE.out);
    refan(T, [h.hand[0], h.hand[2]], 2, t, 200); T.text(h.handN, "2", t);
    const c0 = { x: rel.x + W / 2, y: rel.y + H / 2 };
    h.opts.forEach((e, k) => { const to = P(960 + (k - 1) * 270 - W / 2, 470 - H / 2, 0, 1.4); put(e, to.x, to.y);
      T.a(e, [{ opacity: 0 }, { opacity: 1 }], t + 120 + k * 60, 80, EASE.lin);
      fly(T, e, P(c0.x - W / 2, c0.y - H / 2, 0, .4), to, t + 120 + k * 60, 280, { ease: "out", lift: 40 }); });
    T.a(h.prompt, [{ opacity: 0, transform: "translateY(8px)" }, { opacity: 1, transform: "translateY(0)" }], t + 250, 200, EASE.out);
    ptrHide(T, h.ptr, t + 300);
  } },
{ id: "pick", grp: "hand", name: "Discover: pick one", tag: "changed",
  line: "The one you pick flies into the hand and hops; the others sink away and the room brightens. Now the picked card fades into the hand.",
  timing: "0.32 s flight, others out in 0.15 s, veil off in 0.15 s.",
  scene: st => { const h = recruit(st, base({ hand: [C("lance-corporal"), C("sett-shield-bearer")] })); h.veil = add(st, `<div id="dim" style="z-index:20"></div>`, 0, 0);
    h.prompt = title(st, "Discover a unit", 960, 150, 40); h.prompt.style.zIndex = 22;
    h.opts = ["sett-shield-bearer", "harvest-piper", "old-campaigner"].map((id, k) => { const e = mk(C(id)); const to = P(960 + (k - 1) * 270 - W / 2, 470 - H / 2, 0, 1.4); st.append(put(e, to.x, to.y)); pose0(e, to); e.style.zIndex = 21; return e; }); return h; },
  run(T, h) {
    const e = h.opts[1], p = e._p, at = { x: 960, y: 480 };
    ptrMove(T, h.ptr, { x: 1300, y: 800 }, at, T0, 420); ptrPress(T, h.ptr, at, T0 + 440);
    const t = T0 + 540, dest = handPose(2, 3);
    path(T, e, t - 80, [[0, p], [80, { ...p, s: 1.48 }]], "out");
    fly(T, e, { ...p, s: 1.48 }, dest, t, 320, { ease: "arrive", lean: 4 }); hop(T, e, dest, t + 320);
    refan(T, h.hand, 3, t + 60, 220); T.text(h.handN, "3", t + 320);
    [0, 2].forEach(k => { const o = h.opts[k]; path(T, o, t, [[0, o._p, 1], [150, { ...o._p, y: o._p.y + 30, s: 1.3 }, 0]], "in"); });
    T.a(h.veil, [{ opacity: 1 }, { opacity: 0 }], t + 80, 150, EASE.in); T.a(h.prompt, [{ opacity: 1 }, { opacity: 0 }], t, 120, EASE.in);
    T.at(t + 520, on => { e.style.zIndex = on ? 6 : 21; });
    ptrHide(T, h.ptr, t + 200);
  } },

// ======================================================================= end of turn
{ id: "endfx", grp: "end", name: "End-of-turn effects, grouped", tag: "new",
  line: "Press End turn and your end-of-turn effects play on the board first, in board order, each sooner than the last. Sentry spends a Supply crate on its slot's Renown; Colour Sergeant gives its whole row Renown in one wave with a rising ×N, not four separate beats; Prophet of the Dust raises the Tide.",
  timing: "About 2 s here (gaps 0.38, 0.5 s; the wave 35 ms a slot). Now: they happen unseen before the fight.",
  scene: st => { const h = recruit(st, base({ plates: [[null, "Tide", 2]], renown: [],
    board: [C("sentry"), C("lance-corporal"), C("colour-sergeant"), C("padre"), C("prophet-of-the-dust"), C("recruiting-sergeant"), C("horde-runner")] }));
    h.combo = add(st, `<div class="combo">×<b>1</b></div>`, 0, 0); h.combo.style.opacity = 0; return h; },
  run(T, h) {
    const at = { x: 1734 + 64, y: 930 + 64 };
    ptrMove(T, h.ptr, { x: 1500, y: 800 }, at, T0, 360); ptrPress(T, h.ptr, at, T0 + 380); press(T, h.end, T0 + 380);
    T.a(h.end, [{ boxShadow: "0 0 0 4px #ffb24a,0 0 0 7px #16120e,0 0 30px 8px rgba(255,170,70,.45)" }, { boxShadow: "0 0 0 4px #6b5a44,0 0 0 7px #16120e,0 0 0 0 rgba(255,170,70,0)" }], T0 + 500, 200, EASE.lin);
    ptrHide(T, h.ptr, T0 + 700);
    const toSlot = (src, i, words, t, o = {}) => { const [sx, sy] = slotXY(i), m = starEl(h.st, words);
      gainFly(T, h.st, m, centre(src, -30), { x: sx + W / 2, y: sy + 10 }, t, o.dur || 300, { w: 60, h: 60, lift: o.lift ?? 50, s0: .5, s1: .8, ringR: 36 }); };
    let t = T0 + 800;
    // Sentry, "Supply 6: At the end of your turn, give this slot 1 Renown.": a crate empties for good
    const sen = h.board[0]; fire(T, sen, t); spendPip(T, sen, "supply", t + 60);
    toSlot(sen, 0, "+1", t + 110, { lift: 110 }); addRenown(T, h, 0, 1, t + 420); t += 380;
    // Colour Sergeant: its row is full of Pigeons, so each slot in it gets 2 Renown, as one wave
    const cs = h.board[2]; fire(T, cs, t, 520);
    const c = centre(cs); put(h.combo, c.x - 40, c.y - 190);
    T.a(h.combo, [{ opacity: 0, transform: "translateY(20px) scale(.6)" }, { opacity: 1, transform: "translateY(0) scale(1)" }], t + 100, 160, EASE.back);
    const cb = h.combo.querySelector("b");
    for (let i = 0; i < 4; i++) {
      const ti = t + 120 + i * 35;
      toSlot(cs, i, "+2", ti, { dur: 260, lift: 40 });
      addRenown(T, h, i, 2, ti + 260);
      T.text(cb, String(i + 1), ti + 260);
      T.a(h.combo, [{ transform: "scale(1.25)" }, { transform: "scale(1)" }], ti + 260, 120 - i * 8, EASE.out);
    }
    T.a(h.combo, [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(-30px)" }], t + 120 + 4 * 35 + 600, 250, EASE.in);
    t += 500;
    // Prophet of the Dust: Tide +1
    fire(T, h.board[4], t); const tide = gainPill(h.st, "Tide +1"); gainFly(T, h.st, tide, centre(h.board[4], -14), { x: 120, y: 858 }, t + 110, 380, { w: 120, h: 44, lift: 120, ringR: 44 });
    plateTo(T, h, h.plates[0], 2, 3, t + 490);
  } },
{ id: "tofight", grp: "end", name: "End turn: into the fight", tag: "new",
  line: "The shop lifts away and the hand drops out of sight; your board slides to its fight place while the opponent's board drops in above. The fight half takes over from here.",
  timing: "0.6 s. Now: an instant swap to the fight screen.",
  scene: st => { const f = layer(st, 0); backdropU(f);
    const fl = layer(st, 1), opp = ["gorger", "hopper", "hopper", "swarm-lord", "prophet-of-the-dust", "brood-mother", "green-recruit"].map((id, i) => {
      const x = i < 4 ? FX + i * (W + G.g) : FX + (W + G.g) / 2 + (i - 4) * (W + G.g), y = i < 4 ? 265.5 : 50; const e = mk(C(id)); fl.append(put(e, x, y)); pose0(e, P(x, y)); e.style.opacity = 0; return e; });
    const ohero = add(fl, `<div class="port opphero" style="width:128px;height:128px;background-image:url(assets/portraits/march_hare.jpg);border:6px solid #16120e;box-shadow:0 0 0 3px #b0574d,0 0 0 6px #16120e"></div>`, 1733, 96); ohero.style.opacity = 0;
    const r = layer(st, 2); const h = recruit(r, base()); h.f = f; h.opp = opp; h.ohero = ohero; h.bg = [...r.children].slice(0, 3); return h; },
  run(T, h) {
    const at = { x: 1798, y: 994 };
    ptrMove(T, h.ptr, { x: 1500, y: 800 }, at, T0, 360); ptrPress(T, h.ptr, at, T0 + 380); press(T, h.end, T0 + 380);
    ptrHide(T, h.ptr, T0 + 520);
    const t = T0 + 520;
    const up = [...h.shop, ...h.spells].filter(Boolean);
    up.forEach((e, i) => path(T, e, t + i * 15, [[0, e._p, 1], [300, { ...e._p, y: e._p.y - 340 }, 0]], "in"));
    [...h.tags, h.goldBtn, h.tierBtn, h.refBtn, h.left, h.frzBtn].filter(Boolean).forEach(e => T.a(e, [{ opacity: 1, transform: "translateY(0)" }, { opacity: 0, transform: "translateY(-120px)" }], t, 260, EASE.in));
    h.hand.forEach(e => path(T, e, t, [[0, e._p, 1], [250, { ...e._p, y: e._p.y + 160 }, 1]], "in"));
    [h.handLbl, h.nextPl].forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], t, 200, EASE.lin));
    h.bg.forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], t + 100, 300, EASE.inout));
    h.slots.forEach(e => T.a(e, [{ opacity: 1 }, { opacity: 0 }], t, 200, EASE.lin));
    h.board.forEach(e => { if (!e) return; path(T, e, t + 80, [[0, e._p], [300, { ...e._p, y: e._p.y + 73 }]], "inout"); });
    h.opp.forEach((e, i) => { const p = e._p; T.a(e, [{ opacity: 0 }, { opacity: 1 }], t + 200 + i * 30, 80, EASE.lin); path(T, e, t + 200 + i * 30, [[0, { ...p, y: p.y - 260 }], [280, p]], "out"); });
    T.a(h.end, [{ opacity: 1 }, { opacity: 0 }], t, 200, EASE.lin);
    T.a(h.ohero, [{ opacity: 0, transform: "translateY(-30px)" }, { opacity: 1, transform: "translateY(0)" }], t + 300, 250, EASE.out);
  } },

// ======================================================================= out of the game
{ id: "elim", grp: "over", name: "A player is knocked out", tag: "new",
  line: "On the leaderboard, their Health runs down to 0 with a shake, their portrait greys and cracks, and they slide to the bottom as the others close up.",
  timing: "0.9 s. Now: the next redraw shows a dimmed \"out\" portrait.",
  crop: [1240, 100, 680, 820],
  scene: st => { backdropU(st); const o = layer(st, 1); const h = { st }; const LB = [["march_hare", 40], ["brother_bracken", 36], ["dame_farthing", 34, "you"], ["pipkin", 29], ["dame_hoolet", 22], ["hob_mumblecrust", 12], ["little_king_wren", 9], ["old_mother_mousewife", 4]];
    const px = 1904 - 214 / 2; paneEl(o, px - 85, 140, 170, 8 * 84 + 40);
    h.rows = LB.map(([p, v, you], i) => { const y = 164 + i * 84, row = html(`<div class="lb" style="left:0;top:0"><div class="${you || ""}"></div></div>`); o.append(row);
      const d = row.firstChild; d.append(place(html(`<div class="port" style="width:72px;height:72px;background-image:url(assets/portraits/${p}.jpg)"></div>`), px - 36, y));
      d.append(place(html(`<div class="hp">${v}</div>`), px + 22, y + 44)); d.append(place(html(`<div class="pl">${i + 1}</div>`), px - 66, y + 22));
      d.append(place(html(`<svg class="crack" width="72" height="72" viewBox="0 0 72 72" style="opacity:0"><path d="M36 4 L30 26 L40 34 L28 52 L34 70 M30 26 L12 30 M40 34 L62 40"/></svg>`), px - 36, y));
      row._y = y; return row; });
    return h; },
  run(T, h) {
    const r = h.rows[5], d = r.firstChild, hpEl = d.querySelector(".hp"), port = d.querySelector(".port"), cr = d.querySelector(".crack");
    T.num(hpEl, 12, 0, T0, 220);
    T.a(hpEl, [0, -6, 6, -5, 5, 0].map(x => ({ transform: `translateX(${x}px)` })), T0, 240, EASE.lin);
    T.a(port, [{ filter: "grayscale(0) brightness(1)" }, { filter: "grayscale(1) brightness(.55)" }], T0 + 220, 300, EASE.out);
    T.a(cr, [{ opacity: 0, strokeDashoffset: 120 }, { opacity: 1, strokeDashoffset: 0 }], T0 + 260, 220, EASE.out);
    T.a(r, [{ transform: "translateY(0)" }, { transform: "translateY(168px)" }], T0 + 620, 300, EASE.inout);
    [6, 7].forEach(i => T.a(h.rows[i], [{ transform: "translateY(0)" }, { transform: "translateY(-84px)" }], T0 + 620, 300, EASE.inout));
    const pls = h.rows.map(x => x.querySelector(".pl"));
    T.text(pls[5], "8", T0 + 770); T.text(pls[6], "6", T0 + 770); T.text(pls[7], "7", T0 + 770);
  } },
{ id: "gameover", grp: "over", name: "Game over: the result", tag: "new",
  line: "The game fades through dark; your place stamps in, the standings fill in from first place down, and your row lights.",
  timing: "1.4 s to the buttons. Now: an instant swap. When you're out early, the same plays after the others finish.",
  scene: st => { const h = resultScreen(st, 3); h.veil = add(st, `<div class="veil"></div>`, 0, 0); return h; },
  run(T, h) {
    T.a(h.veil, [{ opacity: 1 }, { opacity: 0 }], T0, 400, EASE.inout);
    h.title.style.opacity = 0; h.sub.style.opacity = 0;
    T.a(h.title, [{ opacity: 0, transform: "scale(1.4)" }, { opacity: 1, transform: "scale(1)" }], T0 + 300, 260, EASE.back);
    T.a(h.sub, [{ opacity: 0 }, { opacity: 1 }], T0 + 500, 200, EASE.lin);
    h.rows.forEach((r, i) => { r.row.style.opacity = 0; T.a(r.row, [{ opacity: 0, transform: "translateY(-10px)" }, { opacity: 1, transform: "translateY(0)" }], T0 + 600 + i * 60, 200, EASE.out);
      if (r.you) T.a(r.row, [{ filter: "brightness(1)" }, { filter: "brightness(1.35) drop-shadow(0 0 12px rgba(255,178,74,.8))" }, { filter: "brightness(1.1) drop-shadow(0 0 6px rgba(255,178,74,.5))" }], T0 + 1300, 500, EASE.out); });
    h.btns.forEach((b, i) => { b.style.opacity = 0; T.a(b, [{ opacity: 0 }, { opacity: 1 }], T0 + 1400 + i * 50, 200, EASE.out); });
  } },
];
