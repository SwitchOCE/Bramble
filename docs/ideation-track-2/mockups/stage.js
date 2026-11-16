// Shared by the mock-up screens: the stone window, small DOM helpers, the hero on the left, the lobby and
// leaderboard, the hover detail that follows the cursor, and the switches bar. Each screen keeps its own layout.

const A = n => `assets/art/${n}.jpg`;
const LOBBY = [
  { p: "march_hare", hp: 40, t: 4 }, { p: "brother_bracken", hp: 36, t: 4, next: true }, { p: "dame_farthing", hp: 34, t: 4, you: true },
  { p: "pipkin", hp: 29, t: 3 }, { p: "dame_hoolet", hp: 22, t: 5 }, { p: "hob_mumblecrust", hp: 17, t: 3 },
  { p: "little_king_wren", hp: 9, t: 2 }, { p: "old_mother_mousewife", hp: 4, t: 3 },
];

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

// a board slot with no unit: the empty pane, or the Ring slot (the first mock-up's)
function slotEl(G, ring) {
  return ring
    ? html(`<div class="slot ring" style="width:${G.W}px;height:${G.H}px"><div class="rt" style="font-size:${(G.H * .12).toFixed(0)}px">+4/+4<small>Ring</small></div></div>`)
    : html(`<div class="slot" style="width:${G.W}px;height:${G.H}px"></div>`);
}

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

// the leaderboard: a slim strip of portraits in the right light, from y = top
function leaderboard(st, G, top, step) {
  const px = 1904 - G.sideW / 2;
  st.append(place(html(`<div id="lbpane" style="width:170px;height:${LOBBY.length * step + 40}px"></div>`), px - 85, top - 10));
  const lb = html(`<div class="lb"></div>`); st.append(lb);
  LOBBY.forEach((p, i) => {
    const y = top + 14 + i * step, cls = p.next ? "next" : p.you ? "you" : "";
    const row = html(`<div class="${cls}"></div>`);
    row.append(place(html(`<div class="port" style="width:72px;height:72px;background-image:url(assets/portraits/${p.p}.jpg)"></div>`), px - 36, y));
    row.append(place(html(`<div class="hp">${p.hp}</div>`), px + 22, y + 44));
    row.append(place(html(`<div class="pl">${i + 1}</div>`), px - 66, y + 22));
    lb.append(row);
  });
}

// hover: the card's detail next to the cursor (owner, 14 Nov); the text is a placeholder.
// bigOf(c, big) gives the enlarged card's {h, spell}.
function hoverDetail(st, cards, byId, G, pinned, bigOf) {
  const H = G.H, tip = html(`<div id="tip" hidden></div>`); st.append(tip);
  const show = (el, mx, my) => {
    const c = byId[el.dataset.id]; if (!c) return;
    const big = 1.6 * H, bigW = big * 0.56;
    tip.innerHTML = "";
    tip.append(Cards.make({ ...c, ...bigOf(c, big) }));
    tip.append(html(`<div class="txt"><div class="n">${c.name}</div><div class="m">${c.spell ? "Spell · costs " + c.cost : "Tier " + c.tier + " · unit"}</div><div class="r">Rules text goes here, in one or two short lines.</div></div>`));
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
