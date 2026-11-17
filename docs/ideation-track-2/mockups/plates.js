// STAND-IN (polish.html .cnt): the player's counters by the portrait as named plates, in place of
// stage.js's two emblem chips. Loaded after stage.js, it replaces leftLight() on every page here
// that draws the left light, so the mock-ups show what the game draws. Ideation track 2; not
// decided. The plates are polish.html's: Compost 4 with the bog emblem, Tide 3 with none.
(function () {
  const css = `.cnt{position:absolute;display:flex;align-items:center;gap:8px;height:44px;padding:0 14px 0 6px;border-radius:22px;white-space:nowrap;
  border:3px solid var(--lead);background:url(assets/ui/rd-cream.png) center/150% auto,#e8dcc0;box-shadow:0 3px 6px rgba(0,0,0,.6);color:var(--ink)}
.cnt.bare{padding-left:14px}
.cnt i{width:32px;height:32px;border-radius:50%;border:2px solid var(--lead);background-size:cover}
.cnt span{font:800 20px var(--display)}
.cnt b{font:900 26px var(--display)}`;
  const style = document.createElement("style");
  style.textContent = css;
  document.head.append(style);
})();

const PLATES = [["bog", "Compost", 4], [null, "Tide", 3]];

// the counters: named plates above your name, the first lowest
function plates(st) {
  PLATES.forEach(([icon, name, v], i) => {
    const el = html(`<div class="cnt${icon ? "" : " bare"}">${icon ? `<i style="background-image:url(assets/ui/tr-${icon}.png)"></i>` : ""}<span>${name}</span><b>${v}</b></div>`);
    st.append(place(el, 40, 1080 - 188 - 56 - i * 54));
  });
}

// stage.js leftLight() with the plates for the chips
function leftLight(st, turnLabel) {
  st.append(place(html(`<div class="lbl">${turnLabel}</div>`), 54, 150));
  st.append(place(html(`<div class="lbl" style="font-size:22px">Dame Farthing</div>`), 40, 1080 - 188));
  st.append(place(html(`<div class="port hero" style="width:128px;height:128px;background-image:url(assets/portraits/dame_farthing.jpg)"></div>`), 40, 1080 - 150));
  st.append(place(html(`<div class="hp">34</div>`), 118, 1080 - 66));
  plates(st);
}
