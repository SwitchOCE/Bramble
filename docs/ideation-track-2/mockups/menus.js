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
function begin(render) {
  if (new URLSearchParams(location.search).has("shot")) document.documentElement.classList.add("shot");
  const fitStage = () => {
    const k = document.getElementById("box").clientWidth / 1920;
    document.getElementById("stage").style.transform = `scale(${k})`;
  };
  addEventListener("resize", fitStage);
  document.fonts.ready.then(() => { render(document.getElementById("stage")); fitStage(); });
}
