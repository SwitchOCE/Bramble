// Shared by the mock-up screens: the stone window, small DOM helpers, the hero on the left, the lobby and
// leaderboard, the hover detail that follows the cursor, and the switches bar. Each screen keeps its own layout.

const A = n => `assets/art/${n}.jpg`;
// the lobby, by placing. t: shop tier; tribes: its tribe icons (only two emblems exist, both stand-ins); last: your last
// fight with them (W/L and the damage), if any; out: eliminated, with the turn. Names and numbers are placeholders.
const LOBBY = [
  { p: "march_hare", name: "March Hare", hp: 40, t: 4, tribes: ["fairies", "bog"], last: { r: "L", n: 7, turn: 4 } },
  { p: "brother_bracken", name: "Brother Bracken", hp: 36, t: 4, tribes: ["bog"], next: true, last: { r: "W", n: 5, turn: 5 } },
  { p: "dame_farthing", name: "Dame Farthing", hp: 34, t: 4, tribes: ["fairies"], you: true },
  { p: "pipkin", name: "Pipkin", hp: 29, t: 3, tribes: ["bog", "fairies"], last: { r: "W", n: 4, turn: 6 } },
  { p: "dame_hoolet", name: "Dame Hoolet", hp: 22, t: 5, tribes: ["fairies"], last: { r: "L", n: 9, turn: 3 } },
  { p: "hob_mumblecrust", name: "Hob Mumblecrust", hp: 17, t: 3, tribes: ["bog"] },
  { p: "little_king_wren", name: "Little King Wren", hp: 9, t: 2, tribes: ["fairies", "bog"], last: { r: "W", n: 8, turn: 2 } },
  { p: "old_mother_mousewife", name: "Old Mother Mousewife", hp: 0, t: 3, tribes: ["bog"], out: 6 },
];
// the board you last saw each opponent with (placeholder: built from the test art, F1-F4 then B1-B3)
const SUBJ = ["stag", "badger", "otter", "hare", "ooze", "stoat", "fairy", "hedgehog", "boar", "mouse", "owl"];
function lastBoard(i) {
  return [...Array(7)].map((_, k) => (k === (i + 5) % 7 && i % 2) ? null : {
    tier: 1 + (i * 3 + k * 2) % 6, art: A(`${SUBJ[(i * 4 + k * 3) % SUBJ.length]}-${1 + (i + k) % 2}`),
    attack: 2 + (i * 5 + k * 7) % 11, health: 3 + (i * 3 + k * 5) % 12 });
}

function place(el, x, y) { el.style.left = x + "px"; el.style.top = y + "px"; return el; }
function html(s) { const d = document.createElement("div"); d.innerHTML = s.trim(); return d.firstChild; }

// the stone window: three lights, each an arch over a transom, and a sill (after tools/gen_stone.py).
// G gives ys (where the centre arch starts to curve), T0 and T1 (the transom), sill, cL, cR and sideW.
function arch(x0, x1, ys, ya, yb) {
  const w = x1 - x0, xm = (x0 + x1) / 2, h = ys - ya, f = v => v.toFixed(1);
  return `M${x0},${yb} L${x0},${ys} C${x0},${f(ys - .62 * h)} ${f(xm - .13 * w)},${f(ya + .12 * h)} ${xm},${ya} C${f(xm + .13 * w)},${f(ya + .12 * h)} ${x1},${f(ys - .62 * h)} ${x1},${ys} L${x1},${yb} Z`;
}
function stone(G) {
  const rect = (x0, y0, x1, y1) => `M${x0},${y0} H${x1} V${y1} H${x0} Z`;
  const ysSide = 150;
  const L = [[16, 16 + G.sideW, ysSide, 50], [G.cL, G.cR, G.ys, 12], [1904 - G.sideW, 1904, ysSide, 50]];
  const holes = L.map(([x0, x1, s, a]) => arch(x0, x1, s, a, G.T0) + " " + rect(x0, G.T1, x1, G.sill)).join(" ");
  const all = `M0,0 H1920 V1080 H0 Z ${holes}`;
  return `<svg class="a" style="left:0;top:0" width="1920" height="1080" viewBox="0 0 1920 1080" xmlns="http://www.w3.org/2000/svg">
<defs><pattern id="st" patternUnits="userSpaceOnUse" width="384" height="384"><image href="assets/ui/stone.jpg" width="384" height="384"/></pattern>
<linearGradient id="sillg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a8172" stop-opacity=".35"/><stop offset=".05" stop-color="#000" stop-opacity="0"/><stop offset=".06" stop-color="#000" stop-opacity=".25"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></linearGradient>
<clipPath id="op"><path d="${holes}"/></clipPath></defs>
<path d="${all}" fill-rule="evenodd" fill="url(#st)"/>
<path d="${all}" fill-rule="evenodd" fill="#0b0907" fill-opacity=".62"/>
<g clip-path="url(#op)" fill="none">
 <path d="${holes}" stroke="#14100c" stroke-width="30"/><path d="${holes}" stroke="#3b2a26" stroke-width="24"/>
 <path d="${holes}" stroke="#3a3324" stroke-width="24" stroke-dasharray="34 34"/><path d="${holes}" stroke="#14100c" stroke-width="24" stroke-dasharray="3 31"/>
</g>
<path d="${holes}" fill="none" stroke="#0a0806" stroke-width="7"/>
<path d="${holes}" fill="none" stroke="#b9ab94" stroke-opacity=".13" stroke-width="2" transform="translate(-3,-3)"/>
<rect x="0" y="${G.sill}" width="1920" height="${1080 - G.sill}" fill="url(#sillg)"/></svg>`;
}

const ICON = {
  gold: '<svg viewBox="0 0 24 24"><path d="M12 2.5v2.2"/><path d="M4.5 10.2c0-3 3.4-5.5 7.5-5.5s7.5 2.5 7.5 5.5z"/><path d="M6 10.2v1.3c0 4.2 2.7 8.3 6 10 3.3-1.7 6-5.8 6-10v-1.3"/></svg>',
  tier: '<svg viewBox="0 0 24 24"><path d="M5 20h14M7 16h10M12 4l5 8H7z"/></svg>',
  refresh: '<svg viewBox="0 0 24 24"><path d="M19 12a7 7 0 1 1-2.05-4.95"/><path d="M19 4v4h-4"/></svg>',
  freeze: '<svg viewBox="0 0 24 24"><path d="M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9M9.5 4.5 12 7l2.5-2.5M9.5 19.5 12 17l2.5 2.5"/></svg>',
};

// a board slot with no unit: the empty pane. A slot buff shows its values where a unit's Attack and Health would sit
// (owner, 16 Nov), on that tier-1 frame's disc positions, in green glass. It has no name ("Ring" was ideation).
function slotEl(G, buff, id) {
  const el = html(`<div class="slot" style="width:${G.W}px;height:${G.H}px"></div>`);
  if (id) el.dataset.id = id;
  if (!buff) return el;
  el.classList.add("buffed");
  const d = window.CARD_DATA.roundels.tier1, k = G.H / 1000;
  [[d.attack, buff.attack], [d.health, buff.health]].forEach(([disc, v]) => {
    const [cx, cy] = disc.centre_units, r = disc.radius_units * k * 1.1;
    const b = html(`<span class="sbv">+${v}</span>`);
    b.style.cssText = `left:${(cx / 560 * 100).toFixed(2)}%;top:${(cy / 1000 * 100).toFixed(2)}%;width:${(2 * r).toFixed(1)}px;height:${(2 * r).toFixed(1)}px;font-size:${(r * 1.05).toFixed(1)}px`;
    el.append(b);
  });
  return el;
}

// the line the hover detail adds for a slot buff
const slotBuffText = b => `Slot buff: +${b.attack}/+${b.health} to the unit here`;

// left light: Turn at the top, your hero on the sill with its two chips
function leftLight(st, turnLabel) {
  st.append(place(html(`<div class="lbl">${turnLabel}</div>`), 54, 150));
  st.append(place(html(`<div class="lbl" style="font-size:22px">Dame Farthing</div>`), 40, 1080 - 188));
  st.append(place(html(`<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/dame_farthing.jpg)"></div>`), 40, 1080 - 150));
  st.append(place(html(`<div class="hp">34</div>`), 118, 1080 - 66));
  [["bog", "0"], ["fairies", "×4"]].forEach(([t, v], i) => {
    st.append(place(html(`<div class="chip" style="background-image:url(assets/ui/tr-${t}.png)"></div>`), 186, 1080 - 136 + i * 60));
    st.append(place(html(`<div class="chipv">${v}</div>`), 218, 1080 - 112 + i * 60));
  });
}

// the leaderboard: a slim strip of portraits in the right light, from y = top.
// hover: a player's index to show as hovered; detail: the second, fuller hover (owner, 16 Nov: "Tavern tier and their
// HP and the icons as for the normal hover state, and then maybe you can get that extra detail ... on a more detailed hover").
function leaderboard(st, G, top, step, hover = null, detail = false) {
  const px = 1904 - G.sideW / 2;
  st.append(place(html(`<div id="lbpane" style="width:170px;height:${LOBBY.length * step + 40}px"></div>`), px - 85, top - 10));
  const lb = html(`<div class="lb"></div>`); st.append(lb);
  LOBBY.forEach((p, i) => {
    const y = top + 14 + i * step, cls = [p.next ? "next" : p.you ? "you" : p.out ? "out" : "", hover === i ? "hot" : ""].join(" ");
    const row = html(`<div class="${cls}"></div>`);
    row.append(place(html(`<div class="port" style="width:72px;height:72px;background-image:url(assets/portraits/${p.p}.jpg)"></div>`), px - 36, y));
    if (!p.out) row.append(place(html(`<div class="hp">${p.hp}</div>`), px + 22, y + 44));
    row.append(place(html(`<div class="pl">${i + 1}</div>`), px - 66, y + 22));
    lb.append(row);
  });
  if (hover !== null) playerTip(st, LOBBY[hover], hover, px - 85 - 12, top + 14 + hover * step + 36, detail);
}

// the hover card for a player, to the left of the strip, centred on the row at y. The name, and under it the shop tier,
// health and tribe icons. The detailed hover adds your last fight with them and the board you last saw, side by side
// so it stays short.
function playerTip(st, p, i, right, y, detail) {
  const icons = `<div class="pt-icons"><span class="tier">${p.t}</span>${p.out ? `<span class="outt">Out on turn ${p.out}</span>` : `<span class="hp">${p.hp}</span>`}` +
    p.tribes.map(t => `<span class="chip" style="background-image:url(assets/ui/tr-${t}.png)"></span>`).join("") + `</div>`;
  const sub = p.you ? "You" : p.next ? "Your next opponent" : "";
  let body = `<div class="pt-name">${p.name}</div>${sub ? `<div class="pt-sub${p.next ? " go" : ""}">${sub}</div>` : ""}${icons}`;
  if (detail && !p.you) body += `<div class="pt-last">${p.last ? `Last fight: <b class="${p.last.r === "W" ? "w" : "l"}">${p.last.r === "W" ? "won" : "lost"} ${p.last.n}</b>, turn ${p.last.turn}` : "Not fought yet"}</div>`;
  const h = 84, w = h * 0.56, g = 5, showBoard = detail && p.last, bw = showBoard ? 4 * w + 3 * g + 16 : 0;
  const tw = 250 + bw, th = showBoard ? Math.max(150, h * 1.83 + 4 + 28) : (detail ? 150 : 122);
  const el = html(`<div class="ptip" style="width:${tw}px;height:${th}px"><div class="pt-txt">${body}</div></div>`);
  place(el, right - tw, Math.max(12, Math.min(1068 - th, y - th / 2)));
  st.append(el);
  if (showBoard) {
    const bx = right - bw - 6, by = parseFloat(el.style.top) + (th - (h * 1.83 + 4)) / 2;
    lastBoard(i).forEach((c, k) => {
      const cx = bx + (k < 4 ? k * (w + g) : (w + g) / 2 + (k - 4) * (w + g)), cy = by + (k < 4 ? 0 : 0.83 * h + 4);
      const card = c ? Cards.make({ ...c, h }) : slotEl({ H: h, W: w });
      card.classList.add("ptb"); st.append(place(card, cx, cy));
    });
  }
}

// hover: the card's detail next to the cursor (owner, 14 Nov); the text is a placeholder.
// bigOf(c, big) gives the enlarged card's {h, spell}.
function hoverDetail(st, cards, byId, G, pinned, bigOf) {
  const H = G.H, tip = html(`<div id="tip" hidden></div>`); st.append(tip);
  const show = (el, mx, my) => {
    const c = byId[el.dataset.id]; if (!c) return;
    const big = 1.6 * H, bigW = big * 0.56;
    tip.innerHTML = "";
    if (c.slot) { const s = slotEl({ H: big, W: bigW }, c.slot); s.style.position = "relative"; tip.append(s); }
    else tip.append(Cards.make({ ...c, ...bigOf(c, big) }));
    if (c.slot) tip.append(html(`<div class="txt"><div class="n">Slot buff</div><div class="m">Stays on this slot</div><div class="r">+${c.slot.attack}/+${c.slot.health} to the unit here.</div></div>`));
    else tip.append(html(`<div class="txt"><div class="n">${c.name}</div><div class="m">${c.spell ? "Spell · costs " + c.cost : "Tier " + c.tier + " · unit"}</div><div class="r">Rules text goes here, in one or two short lines.</div>${c.slotBuff ? `<div class="sb">${slotBuffText(c.slotBuff)}</div>` : ""}</div>`));
    let tx = mx + 28, ty = my - big / 2;
    if (tx + bigW + 320 > 1900) tx = mx - 28 - bigW - 316;
    ty = Math.max(10, Math.min(1070 - big, ty));
    place(tip, tx, ty); tip.hidden = false;
    cards.forEach(k => k.classList.toggle("hot", k === el));
  };
  cards.forEach(el => {
    el.addEventListener("mousemove", e => { const r = st.getBoundingClientRect(), k = r.width / 1920; show(el, (e.clientX - r.left) / k, (e.clientY - r.top) / k); });
    el.addEventListener("mouseleave", () => { tip.hidden = true; el.classList.remove("hot"); });
  });
  if (pinned) {
    const el = cards.find(k => k.dataset.id === pinned);
    if (el) show(el, parseFloat(el.style.left) + G.W * 0.7, parseFloat(el.style.top) + H * 0.45);
  }
}

// the switches bar above the stage, and scaling the 1920 x 1080 stage to the page
function fit() {
  const box = document.getElementById("box"), k = box.clientWidth / 1920;
  document.getElementById("stage").style.transform = `scale(${k})`;
}
function startPage(S, render) {
  if (new URLSearchParams(location.search).has("shot")) document.documentElement.classList.add("shot");
  const mark = () => document.querySelectorAll(".bar button").forEach(b => b.classList.toggle("on", S[b.dataset.k] === b.dataset.v));
  document.querySelectorAll(".bar button").forEach(b => b.addEventListener("click", () => {
    S[b.dataset.k] = b.dataset.v;
    history.replaceState(null, "", "?" + new URLSearchParams(S));
    render(); mark(); fit();
  }));
  addEventListener("resize", fit);
  Cards.load().then(() => document.fonts.ready).then(() => { render(); mark(); fit(); });
}
