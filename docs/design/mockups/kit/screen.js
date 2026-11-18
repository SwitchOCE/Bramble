// The recruit screen as the build's recruit-tribes.html draws it (real tribe cards from the build's own state),
// with the 17 Nov proposals switched on by options. Agent-drawn; nothing here is decided.
//   drawRecruit(stage, {prices: "none"|"tag"|"ped", refresh: "none"|"text"|"pips", dupes, gold, marks: "icons"|"words",
//                       holding, tipFor: card id, alt: keyword name or null, tipLive})
const H = 250, W = H * 0.56;
const BY_ID = {}; ALL_CARDS.forEach(c => BY_ID[c.id] = c);
const unitArt = id => { const c = BY_ID[id]; return `units/${c.tribe}/${id}.jpg`; };
const asCard = (u, extra = {}) => u && { id: u.id, name: u.name, tier: u.tier || 1, art: u.spell ? `assets/art/${u.art}.jpg` : unitArt(u.id),
  attack: u.attack, health: u.health, cost: u.cost, price: u.price, spell: !!u.spell, pills: u.pills || [], text: u.text, types: u.types || (BY_ID[u.id] || {}).types, tribe: (BY_ID[u.id] || {}).tribe, ...extra };

// the fixture: the build's own state, with a few swaps so every proposal shows at once
function fixture(o = {}) {
  const s = STATE;
  const shop = s.shop_units.map(u => asCard(u));
  const brock = s.board.find(u => u && u.id === "brock-cub");
  shop[3] = asCard({ ...brock, price: 2, pills: brock.pills });          // a third Brock Cub: completes a triple
  const board = s.board.map(u => asCard(u));
  const ace = BY_ID["flying-ace"];
  const slot = o.aceSlot ?? 3;
  if (slot !== 3) board[3] = board[slot];
  board[slot] = asCard({ id: "flying-ace", name: ace.name, tier: ace.tier, attack: ace.attack, health: ace.health, types: ace.types,
    text: fillText(ace), pills: ["Sortie", "Medal 2"] });
  const hand = s.hand.map(u => asCard(u));
  hand[2] = asCard({ ...brock });                                         // you own two Brock Cubs: board and hand
  const spells = [{ ...ALL_SPELLS[0] }, { ...ALL_SPELLS[1] }];
  return { shop, board, hand, spells };
}
const OWNED = { "hedge-knight": 1, "brock-cub": 2 };

function geom(pr, g = 12) {
  const roof = 0.17 * H, edge = Math.hypot(W / 2, roof);
  const SW = W, SH = 2 * roof + edge, SS = roof / SH;
  let handShow = 0.7 * H;
  const top0 = 1080 - handShow - 14 - 14 - (1.83 * H + 8) - 14 - 16 - 14 - pr - H + 0.17 * H - 8 - SH;
  if (top0 < 48) handShow = Math.max(0.4 * H, handShow - (48 - top0));
  const handTop = 1080 - handShow, sill = handTop - 14;
  const boardH = H + 0.83 * H + 8, boardBot = sill - 14, boardTop = boardBot - boardH;
  const T1 = boardTop - 14, T0 = T1 - 16, shopBot = T0 - 14 - pr, shopTop = shopBot - H;
  const shopW = 5 * W + 4 * g, shopL = 960 - shopW / 2;
  const sideW = 214, cL = 16 + sideW + 24, cR = 1904 - sideW - 24, ys = Math.max(shopTop + 30, 90);
  return { H, W, g, SH, SW, SS, ys, handTop, sill, boardTop, boardBot, T0, T1, shopTop, shopBot, shopL, shopW, cL, cR, sideW };
}

function drawRecruit(st, o) {
  const F = fixture(o), gold = o.gold ?? 8;
  const legacy = !!o.legacy;
  const pr = o.prices === "tag" ? 54 : o.prices === "ped" ? 52 : o.prices === "edge" ? 30 : 0;
  const G = geom(pr, o.prices === "edge" ? 30 : 12);
  st.innerHTML = `<div id="field"></div><div id="light"></div>` + stone(G);
  const cards = [];
  const marksOn = (c, x, y) => c.pills.forEach((words, k) => {
    const el = html(`<div class="a" style="font-size:${o.marks === "words" ? 15 : 17}px;z-index:2">${marksIn(words).replace('class="kw', o.marks === "words" ? 'class="kw' : 'class="kw ico')}</div>`);
    st.append(el); place(el, x + W / 2 - el.offsetWidth / 2, y + 0.2 * H + k * (o.marks === "words" ? 27 : 30));
  });
  const unit = (c, x, y, where) => {
    const el = Cards.make({ ...c, h: H }); el.dataset.id = c.id + "@" + where; st.append(place(el, x, y));
    cards.push([el, c]);
    if (legacy) marksOn(c, x, y); else cardMarks(el, c.pills, H, o.marks || "border");
    if (!legacy && o.dupes && c.id === "brock-cub") el.classList.add("glowtri");   // every copy that would go into the triple
    return el;
  };
  // the shop
  let x = G.shopL;
  F.shop.forEach(c => {
    if (o.prices === "ped") pedestal(st, x, G.shopTop, c.price, gold);
    const ue = unit(c, x, G.shopTop, "shop");
    if (o.dupes && OWNED[c.id]) dupe(st, ue, x, G.shopTop, OWNED[c.id]);
    if (o.prices === "tag") tag(st, x + W / 2, G.shopTop + H, c.price, gold);
    if (o.prices === "edge") edgePrice(st, x + 0.25 * W, G.shopTop + 0.085 * H, c.price, gold);
    x += W + G.g;
  });
  F.spells.forEach((c, k) => {
    const gx = G.shopL + (k + 2) * (W + G.g) - G.g / 2, bottom = G.shopTop + 0.17 * H - 8 - (o.prices === "edge" ? 34 : 0);
    const el = Cards.make({ ...c, spell: "hex", h: G.SH, aspect: G.SW / G.SH, shoulder: G.SS, cost: o.prices === "none" ? c.cost : null });
    el.dataset.id = c.id + "@spell" + k; st.append(place(el, gx - G.SW / 2, bottom - G.SH)); cards.push([el, c]);
    if (o.prices === "edge") edgePrice(st, gx - G.SW / 2 + 0.25 * G.SW, bottom - G.SH + 0.5 * G.SS * G.SH, c.cost, gold);
    else if (o.prices !== "none") spellPrice(st, gx - G.SW / 2, bottom - G.SH, G.SH, c.cost, gold);
  });
  // the shop's buttons: gold and tier-up on the left, refresh and freeze on the right
  const bw = 176, bxL = G.shopL - 20 - bw, bxR = G.shopL + G.shopW + 20, by1 = G.shopTop + H / 2 - 78, by2 = by1 + 84;
  if (legacy) {
    const bw = 150, bxL = G.shopL - 18 - bw, bxR = G.shopL + G.shopW + 18, by1 = G.shopTop + H / 2 - 66, by2 = by1 + 76;
    st.append(place(html(`<div class="btn gold" style="width:${bw}px">${ICON.gold}<b>${gold}</b></div>`), bxL, by1));
    st.append(place(html(`<div class="btn" style="width:${bw}px">${ICON.tier}3→4<span class="pip">7</span></div>`), bxL, by2));
    st.append(place(html(`<div class="btn" style="width:${bw}px">${ICON.refresh}<span class="pip">1</span></div>`), bxR, by1));
    st.append(place(html(`<div class="btn freeze" style="width:${bw}px">${ICON.freeze}</div>`), bxR, by2));
  } else {
    // gold you have: a coin and a number (a count, not a cost); every cost: a coin with its number inside
    const ic = p => p.replace("<svg ", '<svg class="ic" ');
    st.append(place(html(`<div class="btn gold sbtn" style="width:${bw}px"><span style="font-size:40px;display:flex">${COIN}</span><b style="font-size:34px">${gold}</b></div>`), bxL, by1));
    st.append(place(html(`<div class="btn sbtn" style="width:${bw}px"><div class="tl"><small>Tier up</small><span>3 → 4</span></div>${coinN(7, 7 > gold)}</div>`), bxL, by2));
    st.append(place(html(`<div class="btn sbtn" style="width:${bw}px">${ic(ICON.refresh)}${coinN(1, 1 > gold)}</div>`), bxR, by1));
    st.append(place(html(`<div class="btn freeze sbtn" style="width:${bw}px">${ICON.freeze}</div>`), bxR, by2));
    if (o.refresh === "text") st.append(place(html(`<div class="rleft" style="width:${bw}px">7 left at this price</div>`), bxR, by1 - 30));
    if (o.refresh === "pips") st.append(place(html(`<div class="rpips">${Array.from({ length: 10 }, (_, i) => `<i class="${i < 7 ? "on" : ""}"></i>`).join("")}</div>`), bxR + 21, by1 - 22));
  }
  // the board, 4 in front and 3 behind
  const fw = 4 * W + 3 * G.g, fx = 960 - fw / 2, by = G.boardTop, backY = by + 0.83 * H + 8;
  const slotXY = i => i < 4 ? [fx + i * (W + G.g), by] : [fx + (W + G.g) / 2 + (i - 4) * (W + G.g), backY];
  F.board.forEach((c, i) => { const [sx, sy] = slotXY(i); if (c) unit(c, sx, sy, "board" + i); else st.append(place(slotEl(G, false), sx, sy)); });
  // the hand
  const N = F.hand.length, step = W * 0.74, hx = 960 - W / 2, hw = step * (N - 1) + W;
  F.hand.forEach((c, i) => {
    const k = i - (N - 1) / 2;
    if (c.spell) { const el = Cards.make({ ...c, spell: "hex", h: G.SH, aspect: G.SW / G.SH, shoulder: G.SS, cost: c.cost }); st.append(place(el, hx + k * step, G.handTop + 20)); cards.push([el, c]); return; }
    const el = unit(c, hx + k * step, G.handTop + k * k * 4, "hand" + i);
    el.style.transform = `rotate(${(k * 2.5).toFixed(2)}deg)`; el.style.transformOrigin = "50% 100%";
  });
  st.append(place(html(`<div class="lbl" style="font-size:22px;color:#cfd8de">Hand ${N}/7</div>`), 960 - hw / 2 - 150, G.handTop + 40));
  // left light: turn, hero, Health; right light: End turn
  st.append(place(html(`<div class="lbl">Turn 6</div>`), 54, 150));
  st.append(place(html(`<div class="lbl" style="font-size:22px">Dame Farthing</div>`), 40, 1080 - 188));
  st.append(place(html(`<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/dame_farthing.jpg)"></div>`), 40, 1080 - 150));
  st.append(place(html(`<div class="hp">34</div>`), 118, 1080 - 66));
  const eX = 1904 - 16 - 128 - 26;
  st.append(place(html(`<div class="lbl endlbl" style="font-size:22px">End turn</div>`), eX - 6, 1080 - 188));
  st.append(place(html(`<div class="port endturn" style="width:128px;height:128px;background-image:url(assets/portraits/march_hare.jpg)"></div>`), eX, 1080 - 150));
  st.append(place(html(`<div class="hp">40</div>`), eX - 12, 1080 - 66));
  if (!legacy) st.append(place(html(`<div class="cardsbtn"><div class="btn">${CARDS_ICON}</div><div class="lbl">Cards</div></div>`), 1920 - 123 - 34, 64));
  if (o.holding) holding(st, G, F.board[1], fx + (W + G.g), by);
  st.append(html(`<div id="vig"></div>`));
  return { G, cards, F, slotXY };
}

const CARDS_ICON = '<svg viewBox="0 0 24 24"><path d="M3.5 8 10 5.5l3.4 12.6-6.5 2.4z"/><path d="M12 4.5h6.5v13.5"/><path d="M15.5 7.5l5 1.6-3 10"/></svg>';
// C: every price on the middle of the card's top-left edge, as the spells carry theirs
function edgePrice(st, cx, cy, price, gold) { st.append(place(html(`<div class="hang">${coinN(price, price > gold)}</div>`), cx - 22, cy - 22)); }
// A: a price tag hanging off the card's bottom point
function tag(st, cx, tipY, price, gold) {
  const poor = price > gold;
  st.append(place(html(`<svg class="a" width="4" height="14" style="z-index:3;overflow:visible"><path d="M2,0 V14" stroke="#16120e" stroke-width="3"/><circle cx="2" cy="1" r="3" fill="#16120e"/></svg>`), cx - 2, tipY - 1));
  st.append(place(html(`<div class="hang">${coinN(price, poor)}</div>`), cx - 22, tipY + 10));
}
// B: a pedestal under the shop slot: a glass dais the card stands on, the price set in its front
function pedestal(st, x, y, price, gold) {
  const poor = price > gold, pw = W + 10, top = y + H - 26, dh = 72;
  st.append(place(html(`<svg class="a" width="${pw}" height="${dh}" style="z-index:0;overflow:visible" viewBox="0 0 ${pw} ${dh}">
<defs><linearGradient id="pd${x | 0}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5a6670"/><stop offset="1" stop-color="#20262b"/></linearGradient></defs>
<path d="M6,20 L${pw - 6},20 L${pw - 1},${dh - 6} L1,${dh - 6} Z" fill="url(#pd${x | 0})" stroke="#16120e" stroke-width="4" stroke-linejoin="round"/>
<path d="M6,20 L${pw - 6},20 L${pw - 1},${dh - 6} L1,${dh - 6} Z" fill="url(#st)" opacity=".3"/>
<ellipse cx="${pw / 2}" cy="20" rx="${pw / 2 - 6}" ry="13" fill="#7f8f99" stroke="#16120e" stroke-width="4"/>
<ellipse cx="${pw / 2}" cy="18" rx="${pw / 2 - 18}" ry="7" fill="#c9dbe4" opacity=".35"/>
<path d="M2,${dh - 6} L${pw},${dh - 6}" stroke="#b9ab94" stroke-opacity=".25" stroke-width="2"/></svg>`), x - 5, top));
  st.append(place(html(`<div class="hang">${coinN(price, poor)}</div>`), x + W / 2 - 22, top + 22));
}
function spellPrice(st, x, y, h, cost, gold) {
  st.append(place(html(`<div class="hang">${coinN(cost, cost > gold)}</div>`), x - 16, y + h * 0.16));
}
// a duplicate of a unit you own: a rim light, and three pips for the triple (lit = owned, ringed = this one)
function dupe(st, el, x, y, owned) {
  const strong = owned >= 2;
  el.classList.add(strong ? "glowtri" : "dupe1");
}
// holding a board unit over the shop: the shop shows what it sells for
function holding(st, G, c, sx, sy) {
  st.append(place(html(`<div class="sellzone" style="width:${G.shopW + 40}px;height:${H + 30}px"><div>Sell for <span style="font-size:58px;display:flex">${coinN(1)}</span></div></div>`), G.shopL - 20, G.shopTop - 14));
  const el = Cards.make({ ...c, h: H * 1.08 }); el.style.zIndex = 12; el.style.transform = "rotate(-6deg)";
  st.append(place(el, 960 - W * 0.54 + 90, G.shopTop + 20));
  st.append(place(html(POINTER), 960 + 140, G.shopTop + 120)).style.zIndex = 13;
  st.append(place(slotEl(G, false), sx, sy));
}
