// Fix round 20 Nov: the recruit screen as the build draws it today (positions from the build's code, audit
// interaction.md section 8), with real cards from cards.js (make_cards.py, from src/content). Each page adds its
// proposal on top. Needs: kit/data.js (CARD_DATA), card.js, stage.js, kit/kit.js (coins, keyword marks), cards.js.
// Agent-drawn proposals for the owner; nothing here is decided.

const CH = 250, CW = CH * 0.56;
// the build's stage: recruit_shop.gd geometry(), recruit_screen.gd, glass_screen.gd
const GB = {
  H: CH, W: CW, g: 12, handTop: 980, sill: 966, boardTop: 486.5, T0: 456.5, T1: 472.5, shopTop: 138.5, shopBot: 388.5,
  shopL: 586, shopW: 5 * CW + 4 * 12, sideW: 214, cL: 16 + 214 + 24, cR: 1904 - 214 - 24, ys: 168.5,
  SW: CW, SH: 167, SS: 0.17 * CH / 167,
};
const SLOT_XY = [[662, 486.5], [814, 486.5], [966, 486.5], [1118, 486.5], [738, 702], [890, 702], [1042, 702]];

const SPELLS = {
  sharpen: { id: "sp_sharpen", name: "Sharpen", tier: 1, cost: 1, art: "assets/art/spell-2.jpg", text: "Give a friendly unit +2/+2.", spell: true },
  seek: { id: "sp_seek", name: "Seek", tier: 2, cost: 3, art: "assets/art/spell-1.jpg", text: "Discover a unit.", spell: true },
  forage: { id: "sp_forage", name: "Forage", tier: 3, cost: 5, art: "assets/art/spell-2.jpg", text: "Discover two units.", spell: true },
  reward: { id: "triple_reward", name: "Triple Reward", tier: 1, cost: 0, art: "assets/art/spell-1.jpg", text: "Discover a unit from the tier above yours.", spell: true },
};

// a card object from the build's content
function U(id, extra = {}) {
  const c = BR_CARDS[id];
  if (!c) throw new Error("no card " + id);
  return { ...c, art: `units/${c.tribe}/${id}.jpg`, pills: pillsFromText(c.text), price: c.tier + 1, sell: Math.ceil(c.tier / 2), ...extra };
}
function golden(id, extra = {}) { const c = U(id); return { ...c, golden: true, attack: c.attack * 2, health: c.health * 2, ...extra }; }
const typeLineOf = c => (c.types || []).join(" ");

// ---- a card in the build's look ----
const SVGNS = "http://www.w3.org/2000/svg";
function statSettings(el, c) {
  const t = CARD_DATA.roundels["tier" + c.tier];
  const shape = (d, shield) => {
    const [cx, cy] = d.centre_units, r = d.radius_units * 1.04;
    const pts = (shield ? [[-.88, -.9], [.88, -.9], [.88, .3], [0, 1.05], [-.88, .3]] : [[0, -1.12], [1.12, 0], [0, 1.12], [-1.12, 0]])
      .map(([x, y]) => `${(cx + x * r).toFixed(1)},${(cy + y * r).toFixed(1)}`).join(" ");
    return `<circle cx="${cx}" cy="${cy}" r="${d.radius_units}" fill="#201a18"/>
<polygon points="${pts}" fill="${shield ? "#542d34" : "#50391f"}" stroke="#18130f" stroke-width="${(r * .16).toFixed(1)}" stroke-linejoin="round"/>
<polygon points="${pts}" fill="none" stroke="#d5c6a5" stroke-width="${(r * .06).toFixed(1)}" stroke-linejoin="round"/>`;
  };
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("viewBox", "0 0 560 1000"); svg.setAttribute("preserveAspectRatio", "none"); svg.setAttribute("class", "stat");
  svg.innerHTML = shape(t.attack, false) + shape(t.health, true);
  el.insertBefore(svg, el.querySelector(".num"));
}
function goldRim(el) {
  const svg = document.createElementNS(SVGNS, "svg");
  svg.setAttribute("viewBox", "0 0 560 1000"); svg.setAttribute("preserveAspectRatio", "none"); svg.setAttribute("class", "grim");
  svg.innerHTML = `<polygon points="280,0 560,170 560,830 280,1000 0,830 0,170" fill="none" stroke="rgba(255,199,64,.95)" stroke-width="17" stroke-linejoin="round"/>`;
  el.insertBefore(svg, el.querySelector(".num"));
}
// the type line (item 8). where: "stats" (a strip just above Attack and Health) or "crest" (under the top point)
function typeLine(el, c, h, where = "stats") {
  const words = typeLineOf(c); if (!words) return;
  const hh = 0.078, top = where === "crest" ? 0.17 : 0.615;
  const band = document.createElement("div");
  band.className = "tline";
  band.style.cssText = `top:${(top * h).toFixed(1)}px;height:${(hh * h).toFixed(1)}px;border-width:${Math.max(2, h * 0.009).toFixed(1)}px;clip-path:${Cards.outlineClip}`;
  band.innerHTML = `<span style="font-size:${(h * 0.06).toFixed(1)}px">${words}</span>`;
  el.append(band);
  // shrunk to fit inside the frame's side borders by fitTypeLines(), once the card is on the page
  band.firstChild.dataset.room = (h * 0.56 * 0.88).toFixed(1); band.firstChild.dataset.min = (h * 0.03).toFixed(1);
}
function fitTypeLines() {
  document.querySelectorAll(".tline span").forEach(sp => {
    let fs = parseFloat(sp.style.fontSize);
    while (sp.offsetWidth > +sp.dataset.room && fs > +sp.dataset.min) { fs -= 0.25; sp.style.fontSize = fs + "px"; }
  });
}
// o: {h, marks (default true), type: "stats"|"crest"|null, hurt, up:[atk,hp] bools}
function drawCard(c, o = {}) {
  const h = o.h || CH;
  if (c.spell) {
    const el = Cards.make({ ...c, spell: "hex", h: h * GB.SH / CH, aspect: GB.SW / GB.SH, shoulder: GB.SS, cost: null });
    el.classList.add("bc");
    return el;
  }
  const el = Cards.make({ ...c, h });
  el.classList.add("bc");
  statSettings(el, c);
  if (c.golden) goldRim(el);
  if (o.up) el.querySelectorAll(".num").forEach((n, i) => o.up[i] && n.classList.add("up"));
  if (o.type) typeLine(el, c, h, o.type);
  if (o.marks !== false) cardMarks(el, c.pills, h, "border");
  if (o.foil) { const f = document.createElement("div"); f.className = "foil"; f.style.clipPath = Cards.outlineClip; el.append(f); }
  return el;
}

// a spell's price coin on its top-left shoulder, a unit's price coin on a string from its point (the build's tags)
function priceTag(st, cx, tipY, price, gold) {
  st.append(place(html(`<svg class="a" width="4" height="14" style="z-index:3;overflow:visible"><path d="M2,0 V14" stroke="#16120e" stroke-width="3"/><circle cx="2" cy="1" r="3" fill="#16120e"/></svg>`), cx - 2, tipY - 1));
  st.append(place(html(`<div class="hang">${coinN(price, price > gold)}</div>`), cx - 22, tipY + 10));
}
function spellCoin(st, x, y, cost, gold) { st.append(place(html(`<div class="hang">${coinN(cost, cost > gold)}</div>`), x - 18, y + 28)); }

const TIER_IC = '<svg viewBox="0 0 24 24" class="ti"><path d="M5 20h14M7 16h10M12 4l5 8H7z"/></svg>';
const COG = '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3.2"/><path d="M12 2.8v2.6M12 18.6v2.6M2.8 12h2.6M18.6 12h2.6M5.5 5.5l1.8 1.8M16.7 16.7l1.8 1.8M5.5 18.5l1.8-1.8M16.7 7.3l1.8-1.8"/><circle cx="12" cy="12" r="6.3"/></svg>';

// ---- the shop's controls, by layout ("built" is today's) ----
// s: {gold, tier, upCost, drop, income, refresh, left}
function controls(st, layout, s) {
  const ic = p => p.replace("<svg ", '<svg class="ic" ');
  const goldEl = (extra = "") => html(`<div class="btn sb goldm">${COIN}<b>${s.gold}</b>${extra}</div>`);
  const tierEl = () => html(`<div class="btn sb"><div class="tt">${TIER_IC.replace('class="ti"', "")}<span>${s.tier}→${s.tier + 1}</span></div>${coinN(s.upCost, s.upCost > s.gold)}</div>`);
  const refEl = () => html(`<div class="btn sb">${ic(ICON.refresh)}${coinN(s.refresh, s.refresh > s.gold)}</div>`);
  const frzEl = () => html(`<div class="btn sb freeze">${ic(ICON.freeze)}</div>`);
  const income = (x, y) => st.append(place(html(`<div class="rd"><span>Next turn</span><b>+${s.income}</b>${COIN}</div>`), x, y));
  const dropRd = (x, y) => st.append(place(html(`<div class="rd">${TIER_IC}<b class="neg">−${s.drop}</b>${COIN}</div>`), x, y));
  const left = (x, y, w = 176) => st.append(place(html(`<div class="sbsub" style="width:${w}px">${s.left} left at this price</div>`), x, y));
  // a readout fixed to a button's edge: a small cream plate overlapping the button's lower right
  const tab = (inner, x, y) => { const el = html(`<div class="rd" style="height:34px;padding:0 6px 0 10px">${inner}</div>`); st.append(el); place(el, x, y); return el; };
  const at = (el, x, y) => { st.append(place(el, x, y)); return el; };

  if (layout === "built") {
    at(goldEl(), 390, 185.5); at(tierEl(), 390, 269.5); at(refEl(), 1354, 185.5); at(frzEl(), 1354, 269.5);
    left(1354, 155.5); income(196, 962);
    const d = html(`<div class="rd">${TIER_IC}<b class="neg">−${s.drop}</b>${COIN}</div>`); st.append(d); place(d, 1700 - d.offsetWidth, 962);
    return;
  }
  if (layout === "A") {
    // two wings: left = your gold and your tier, each with its own "next turn"; right = the shop's own controls
    const g = at(goldEl(), 390, 160);
    st.append(place(html(`<div class="sbsub" style="width:176px;font-size:18px">+${s.income} next turn</div>`), 390, 234));
    at(tierEl(), 390, 282);
    st.append(place(html(`<div class="sbsub" style="width:176px;font-size:18px">−${s.drop} next turn</div>`), 390, 356));
    left(1354, 155.5); at(refEl(), 1354, 185.5); at(frzEl(), 1354, 269.5);
    return;
  }
  if (layout === "A2") {
    // A as the owner changed it (21 Nov): the buttons keep today's places and gaps on both sides,
    // nothing under the gold; the next turn's gold moves to a badge on the next opponent's portrait
    at(goldEl(), 390, 185.5); at(tierEl(), 390, 269.5);
    st.append(place(html(`<div class="sbsub" style="width:176px;font-size:18px">−${s.drop} next turn</div>`), 390, 343.5));
    left(1354, 155.5); at(refEl(), 1354, 185.5); at(frzEl(), 1354, 269.5);
    return;
  }
  if (layout === "B") {
    // one purse: all four controls in a block left of the shop, the gold top-left; each readout under what it explains
    const w = 150, x1 = 264, x2 = 422;
    const sz = el => { el.style.width = w + "px"; return el; };
    const sub = (t, x, y) => st.append(place(html(`<div class="sbsub" style="width:${w}px;font-size:17px">${t}</div>`), x, y));
    at(sz(goldEl()), x1, 158); sub(`+${s.income} next turn`, x1, 231);
    at(sz(refEl()), x2, 158); sub(`${s.left} left at this price`, x2, 231);
    at(sz(tierEl()), x1, 270); sub(`−${s.drop} next turn`, x1, 343);
    at(sz(frzEl()), x2, 270);
    return;
  }
  if (layout === "C") {
    // gold in the middle of the arch, between the two spells; tier-up left, shop controls right
    at(goldEl(), 872, 34);
    st.append(place(html(`<div class="sbsub" style="width:176px;font-size:18px">+${s.income} next turn</div>`), 872, 106));
    at(tierEl(), 390, 200);
    st.append(place(html(`<div class="sbsub" style="width:176px;font-size:18px">−${s.drop} next turn</div>`), 390, 274));
    left(1354, 155.5); at(refEl(), 1354, 185.5); at(frzEl(), 1354, 269.5);
    return;
  }
}

// ---- the whole recruit screen ----
// o: {turn, shop:[card|null x5], spells:[spell|null x2], board:[card|null x7], hand:[card...], ctl:{...}, layout,
//     cardOpts(c, where) -> drawCard options, skipBoard:[i] (slots left for the page to draw), hero, opp}
function recruitScreen(st, o) {
  const G = GB, ctl = o.ctl;
  st.innerHTML = `<div id="field"></div><div id="light"></div>` + stone(G);
  const els = { shop: [], spells: [], board: [], hand: [] }, cards = [];
  const opt = (c, where) => (o.cardOpts ? o.cardOpts(c, where) : {}) || {};
  // shop units, with the price coin under each; an empty shop place shows its pane
  (o.shop || []).forEach((c, i) => {
    const x = G.shopL + i * (G.W + G.g), y = G.shopTop;
    if (!c) { st.append(place(slotEl(G, false), x, y)); els.shop.push(null); return; }
    const el = drawCard(c, opt(c, "shop")); st.append(place(el, x, y)); els.shop.push(el); cards.push([el, c]);
    priceTag(st, x + G.W / 2, y + G.H, c.price, ctl.gold);
  });
  // shop spells hang in the arch between the cards (the C layout moves them outward to make room for the gold)
  (o.spells || []).forEach((c, k) => {
    if (!c) return;
    const cx = o.layout === "C" ? [G.shopL + (G.W + G.g) - G.g / 2, G.shopL + 4 * (G.W + G.g) - G.g / 2][k] : 884 + 152 * k;
    const x = cx - G.SW / 2, y = 6;
    const el = drawCard(c, opt(c, "spell")); st.append(place(el, x, y)); els.spells.push(el); cards.push([el, c]);
    spellCoin(st, x, y, c.cost, ctl.gold);
  });
  controls(st, o.layout || "built", ctl);
  // the board, 4 in front and 3 behind; slots the page draws itself are left empty
  (o.board || []).forEach((c, i) => {
    const [x, y] = SLOT_XY[i];
    if (o.skipBoard && o.skipBoard.includes(i)) { els.board.push(null); return; }
    if (!c) { st.append(place(slotEl(G, false), x, y)); els.board.push(null); return; }
    const el = drawCard(c, opt(c, "board")); st.append(place(el, x, y)); els.board.push(el); cards.push([el, c]);
  });
  // the hand fan
  const hand = o.hand || [], N = o.handN ?? hand.length;
  hand.forEach((c, i) => {
    if (!c) { els.hand.push(null); return; }
    const p = handXY(i, N);
    const el = drawCard(c, opt(c, "hand"));
    el.style.transform = `rotate(${p.rot}deg)`; el.style.transformOrigin = "50% 100%";
    st.append(place(el, p.x, p.y)); els.hand.push(el); cards.push([el, c]);
    if (c.spell && c.cost) spellCoin(st, p.x, p.y, c.cost, 99);
  });
  const fanW = 103.6 * (Math.max(N, 1) - 1) + G.W;
  st.append(place(html(`<div class="lbl" style="font-size:22px;color:#cfd8de">Hand ${o.handLabel ?? N}/7</div>`), 960 - fanW / 2 - 150, 1020));
  // left light: cog, turn, hero; right light: Cards, End turn
  st.append(place(html(`<div class="cog">${COG}</div>`), 94, 72));
  st.append(place(html(`<div class="lbl">Turn ${o.turn || 4}</div>`), 54, 150));
  st.append(place(html(`<div class="lbl" style="font-size:22px">Dame Farthing</div>`), 40, 892));
  st.append(place(html(`<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/dame_farthing.jpg)"></div>`), 40, 930));
  st.append(place(html(`<div class="hp">${o.hp || 34}</div>`), 118, 1014));
  st.append(place(html(`<div class="cardsbtn"><div class="btn">${CARDS_ICON}</div><div class="lbl">Cards</div></div>`), 1763 - 2, 64));
  st.append(place(html(`<div class="lbl endlbl" style="font-size:22px">End turn</div>`), 1728, 892));
  st.append(place(html(`<div class="port endturn" style="width:128px;height:128px;background-image:url(assets/portraits/old_mother_mousewife.jpg)"></div>`), 1734, 930));
  st.append(place(html(`<div class="hp">40</div>`), 1722, 1014));
  if (o.layout === "A2") {
    // the next turn's gold, on the top-right of the next opponent's portrait
    st.append(place(html(`<div class="rd incbadge" style="height:34px;padding:0 6px 0 10px"><b>+${ctl.income}</b>${COIN}</div>`), 1804, 918));
  }
  return { G, els, cards };
}
function handXY(i, N) {
  const k = i - (N - 1) / 2;
  return { x: 960 - CW / 2 + k * 103.6, y: GB.handTop + k * k * 4, rot: +(k * 2.5).toFixed(2), k };
}
const CARDS_ICON = '<svg viewBox="0 0 24 24"><path d="M3.5 8 10 5.5l3.4 12.6-6.5 2.4z"/><path d="M12 4.5h6.5v13.5"/><path d="M15.5 7.5l5 1.6-3 10"/></svg>';
function vignette(st) { st.append(html(`<div id="vig"></div>`)); }

// a lit slot (drop target)
function litSlot(st, i, swap = false) {
  const [x, y] = SLOT_XY[i];
  const w = html(`<div class="litwrap${swap ? " swap" : ""}" style="width:${CW}px;height:${CH}px"></div>`);
  w.append(slotEl(GB, false)); st.append(place(w, x, y)); return w;
}
function pointer(st, x, y) { const p = html(POINTER); st.append(place(p, x, y)); p.style.zIndex = 30; return p; }

// ---- the page frame: switches, scaling, ?state= in the address ----
function startAfter(S, render) {
  const q = new URLSearchParams(location.search);
  Object.keys(S).forEach(k => { if (q.has(k)) S[k] = q.get(k); });
  if (q.has("shot")) document.documentElement.classList.add("shot");
  const mark = () => document.querySelectorAll(".ctl button").forEach(b => { const on = S[b.dataset.k] === b.dataset.v; b.classList.toggle("on", on); b.setAttribute("aria-pressed", on); });
  const fit = () => { const k = document.getElementById("box").clientWidth / 1920; document.getElementById("stage").style.transform = `scale(${k})`; };
  const go = () => { render(); fitTypeLines(); mark(); fit(); };
  document.querySelectorAll(".ctl button").forEach(b => b.addEventListener("click", () => {
    S[b.dataset.k] = b.dataset.v; history.replaceState(null, "", "?" + new URLSearchParams(S)); go();
  }));
  addEventListener("resize", fit);
  Cards.load().then(() => document.fonts.ready).then(go);
}
