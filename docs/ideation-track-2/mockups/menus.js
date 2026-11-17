// The game flow's plain screens and panels: start, result, pause, and the fight's skip hint.
// Built from the glass mock-ups' own pieces only (stage.css and stage.js, copied verbatim from
// design/glass-mockups at 8279442b): the stone window at the fight screen's geometry, the
// leaderboard's pane, .btn, .lbl, .port, .hp. Every place and size here is mirrored in
// src/game/ui/glass_ui.gd and the screens in src/game/ui/; change both together. Nothing here is decided.

const FIGHT_G = { ys: 90, T0: 529.5, T1: 545.5, sill: 1039, cL: 254, cR: 1666, sideW: 214 };
const PLAYERS = [
  ["dame_farthing", "Dame Farthing"], ["brother_bracken", "Brother Bracken"], ["march_hare", "March Hare"],
  ["pipkin", "Pipkin"], ["dame_hoolet", "Dame Hoolet"], ["hob_mumblecrust", "Hob Mumblecrust"],
  ["little_king_wren", "Little King Wren"], ["old_mother_mousewife", "Old Mother Mousewife"],
];

function backdrop(st) {
  st.innerHTML = `<div id="field"></div><div id="light"></div>` + stone(FIGHT_G);
}
function pane(st, x, y, w, h) {
  st.append(place(html(`<div id="lbpane" style="width:${w}px;height:${h}px"></div>`), x, y));
}
// a .lbl centred on cx
function title(st, words, cx, y, px, colour) {
  const el = html(`<div class="lbl" style="font-size:${px}px${colour ? ";color:" + colour : ""}">${words}</div>`);
  st.append(el);
  place(el, Math.round(cx - el.offsetWidth / 2), y);
  return el;
}
function button(st, words, x, y, w, dim) {
  const el = html(`<div class="btn" style="width:${w}px${dim ? ";opacity:.45" : ""}">${words}</div>`);
  st.append(place(el, x, y));
  return el;
}
function port(st, p, x, y, side, you) {
  const row = html(`<div class="lb"><div class="${you ? "you" : ""}"></div></div>`);
  row.firstChild.append(place(html(`<div class="port" style="width:${side}px;height:${side}px;background-image:url(assets/portraits/${p}.jpg)"></div>`), x, y));
  st.append(row);
}
// STAND-IN (settings cog, 17 Nov): the cog that opens the pause panel, a round .btn in the left light's
// arch, in the same place on the recruit and fight screens; its icon drawn as stage.js's ICON are (24 box, stroked)
const COG_ICON = '<svg viewBox="0 0 24 24"><path d="M10.43 5.59 L10.81 2.88 L13.19 2.88 L13.57 5.59 L15.42 6.36 L17.61 4.71 L19.29 6.39 L17.64 8.58 L18.41 10.43 L21.12 10.81 L21.12 13.19 L18.41 13.57 L17.64 15.42 L19.29 17.61 L17.61 19.29 L15.42 17.64 L13.57 18.41 L13.19 21.12 L10.81 21.12 L10.43 18.41 L8.58 17.64 L6.39 19.29 L4.71 17.61 L6.36 15.42 L5.59 13.57 L2.88 13.19 L2.88 10.81 L5.59 10.43 L6.36 8.58 L4.71 6.39 L6.39 4.71 L8.58 6.36Z"/><circle cx="12" cy="12" r="2.8"/></svg>';
const COG = { x: 94, y: 72, side: 58 };
function cog(st) {
  st.append(place(html(`<div class="btn" style="width:${COG.side}px;z-index:9">${COG_ICON}</div>`), COG.x, COG.y));
}
// STAND-IN: one of a choice of two; the one that is on has recruit-play.html's lit rim round its pill
function choice(st, words, x, y, w, on) {
  button(st, words, x, y, w);
  if (!on) return;
  const h = 58, r = h / 2, pts = [];
  for (let i = 0; i <= 12; i++) { const a = -Math.PI / 2 + Math.PI * i / 12; pts.push([w - r + r * Math.cos(a), r + r * Math.sin(a)]); }
  for (let i = 0; i <= 12; i++) { const a = Math.PI / 2 + Math.PI * i / 12; pts.push([r + r * Math.cos(a), r + r * Math.sin(a)]); }
  const p = pts.map(q => q.map(v => v.toFixed(2)).join(",")).join(" ");
  st.append(place(html(`<svg class="lit" width="${w}" height="${h}"><polygon points="${p}"/><polygon class="glow" points="${p}"/><polygon class="edge" points="${p}"/></svg>`), x, y));
}
function begin(render) {
  if (new URLSearchParams(location.search).has("shot")) document.documentElement.classList.add("shot");
  const fitStage = () => {
    const k = document.getElementById("box").clientWidth / 1920;
    document.getElementById("stage").style.transform = `scale(${k})`;
  };
  addEventListener("resize", fitStage);
  document.fonts.ready.then(() => { render(document.getElementById("stage")); fitStage(); });
}
