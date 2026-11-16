// The card template: art, tier frame, and Attack and Health drawn on that tier's own discs.
// Every card on every mock-up page is made here, at any size. Nothing is placed by hand.
//
//   await Cards.load();                       // reads window.CARD_DATA from assets/card-data.js
//   Cards.make({tier, art, attack, health, h}) // returns a positioned-ready <div class="card">
//   hurt: true draws Health in red, for a unit damaged in a fight (a stand-in, as in Battlegrounds)
//
// Card space is 560 x 1000 units (0.56 wide to 1 tall). Disc centres and radii come from
// frame-lab/final/roundels.json, per tier, so the small differences between tiers are kept.
(function () {
  const U = { w: 560, h: 1000 };
  const C = { roundels: null, artClip: null };
  const pct = (x, y) => `${(x / U.w * 100).toFixed(3)}% ${(y / U.h * 100).toFixed(3)}%`;
  // the card's outer outline (frame-lab/art-space.md)
  const OUTLINE = [[280, 0], [560, 170], [560, 830], [280, 1000], [0, 830], [0, 170]];
  // a hex with its shoulders at s (a fraction of its height) from the top and bottom; s = 0.25 is a regular hexagon
  const hexClip = s => `polygon(50% 0%,100% ${100 * s}%,100% ${100 - 100 * s}%,50% 100%,0% ${100 - 100 * s}%,0% ${100 * s}%)`;

  async function load() {
    const d = window.CARD_DATA; // assets/card-data.js, made by tools/art/mockups/prep_assets.py
    C.roundels = d.roundels;
    C.artClip = `polygon(${d.art.map(([x, y]) => pct(x, y)).join(",")})`;
    C.outlineClip = `polygon(${OUTLINE.map(([x, y]) => pct(x, y)).join(",")})`;
  }

  // Numbers sit on the gold disc. Size follows the disc: one digit at 1.2 x radius, two at 0.95 x.
  function num(value, disc, h, cls) {
    const k = h / U.h; // px per card unit
    const [cx, cy] = disc.centre_units, r = disc.radius_units;
    const s = String(value);
    const fs = r * (s.length > 1 ? 0.95 : 1.2) * k;
    const el = document.createElement("span");
    el.className = "num " + cls;
    el.textContent = s;
    el.style.cssText = `left:${(cx / U.w * 100).toFixed(3)}%;top:${(cy / U.h * 100).toFixed(3)}%;font-size:${fs.toFixed(2)}px;width:${(2 * r * k).toFixed(1)}px;height:${(2 * r * k).toFixed(1)}px`;
    return el;
  }

  // spell: true (the unit's tall 0.56 hex) or "hex": a regular hexagon, width = height x sqrt(3)/2 (owner, 15 Nov:
  // "inherit the width from the normal cards, but the height of a regular hexagon"). Pass h = unit width / (sqrt(3)/2).
  // aspect and shoulder bend it to match the cards' roofs until the frames are fixed (owner, 16 Nov; see recruit.html).
  function make({ tier, art, attack, health, h, spell = false, cost = null, id = "", hurt = false,
                  aspect = Math.sqrt(3) / 2, shoulder = 0.25 }) {
    const w = spell === "hex" ? h * aspect : h * U.w / U.h;
    const el = document.createElement("div");
    el.className = "card" + (spell ? " spell" + (spell === "hex" ? " hexsp" : "") : "");
    el.dataset.tier = tier;
    if (id) el.dataset.id = id;
    el.style.width = w + "px";
    el.style.height = h + "px";
    const img = document.createElement("div");
    img.className = "art";
    img.style.backgroundImage = `url(${art})`;
    img.style.clipPath = spell === "hex" ? hexClip(shoulder) : spell ? C.outlineClip : C.artClip;
    el.append(img);
    if (spell) {
      // STAND-IN: there is no spell frame yet. A plain lead outline and a cost disc.
      const lead = document.createElement("div");
      lead.className = "spell-lead";
      if (spell === "hex") lead.style.clipPath = hexClip(shoulder);
      el.append(lead);
      if (cost !== null) {
        const c = document.createElement("span");
        c.className = "cost";
        c.textContent = cost;
        c.style.fontSize = (h * (spell === "hex" ? 0.11 : 0.075)).toFixed(1) + "px";
        el.append(c);
      }
      return el;
    }
    const fr = document.createElement("img");
    fr.className = "frame";
    fr.src = `assets/frames/tier${tier}.webp`;
    fr.alt = "";
    el.append(fr);
    const t = C.roundels["tier" + tier];
    el.append(num(attack, t.attack, h, "n-atk"), num(health, t.health, h, "n-hp" + (hurt ? " hurt" : "")));
    return el;
  }

  window.Cards = { load, make, outline: OUTLINE, get outlineClip() { return C.outlineClip; } };
})();
