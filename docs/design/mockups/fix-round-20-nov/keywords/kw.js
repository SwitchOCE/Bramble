// PROPOSAL (fix round, 20 Nov 2026; not decided): a look for each fight keyword on a card, in lead and glass.
//
//   KW.decorate(cardEl, [{ k: "Guard" }, { k: "Fury", n: 3 }, { k: "Molt", spent: true }], { h: 250, flip: false })
//
// Each look lives in its own place on the card, so two or three stack without covering each other:
//   behind the card   Guard (a leaded amber ward round the whole card), Reserve (a lancet arch over the top)
//   above the crest   Overrun (two chevrons), Sortie (an arrow arcing over)       flip: true turns these to face down
//   roof              Molt (a pale husk over the roof, split at the crest)
//   roof slopes       Attacks twice (two gusts of pale glass shards each side)
//   long sides        Thorns (thorny lead tracery), Cleave (a blade each side), Pile on (linked rings each side)
//   lower corners     Fury (glass flames; taller for a bigger Fury)
//   bottom point      Root (lead roots with green glass knots)
//   Health disc       Stiff Upper Lip (a gold ring round the Health)
// Molt, Root and Stiff Upper Lip take spent: true once used in a fight: grey, cracked and faded to the marks' 0.4.
// The round marks under the card are kept as the game draws them (up to 3, then "+N").
//
// Card space is 560 x 1000 units, as card.js. Everything here is drawn in those units and scaled with the card.
(function () {
  const INK = "#16120e";
  const OUT = [[280, 0], [560, 170], [560, 830], [280, 1000], [0, 830], [0, 170]];
  const P = 190;                       // margin round the card, in card units, that a look may use
  let uid = 0;

  // keywords.json's mark colours and icons (read once)
  let STYLE = null;
  function style() {
    if (!STYLE) {
      const r = new XMLHttpRequest(); r.open("GET", "assets/keywords.json", false); r.send(); STYLE = JSON.parse(r.responseText);
      // dev's entries (origin/dev 5d697e07 assets/glass/keywords.json), not in this branch's file yet
      Object.assign(STYLE.keywords, { "Hand-me-down": { family: "growth", icon: "handdown" }, "Renown": { family: "growth", icon: "star" } });
      Object.assign(STYLE.icons, {
        handdown: '<circle cx="5.5" cy="17" r="2.5"/><circle cx="18.5" cy="17" r="2.5"/><path d="M5.5 12c1.5-6 11.5-6 13 0"/><path d="M15 10.5l3.5 1.5 1-3.5"/>',
        star: '<path d="M12 3.5l2.5 5.2 5.6.7-4.1 3.9 1 5.6L12 16.2l-5 2.7 1-5.6-4.1-3.9 5.6-.7z"/>' });
    }
    return STYLE;
  }

  // ---- geometry helpers ----
  const f = v => (+v).toFixed(1);
  const pts = a => a.map(([x, y]) => f(x) + "," + f(y)).join(" ");
  // offset a convex clockwise polygon outward by d[i] on edge i (edge i runs from point i to i+1)
  function offset(poly, d) {
    const n = poly.length, lines = [];
    for (let i = 0; i < n; i++) {
      const [ax, ay] = poly[i], [bx, by] = poly[(i + 1) % n], len = Math.hypot(bx - ax, by - ay);
      const nx = (by - ay) / len, ny = -(bx - ax) / len, k = Array.isArray(d) ? d[i] : d;
      lines.push([ax + nx * k, ay + ny * k, bx + nx * k, by + ny * k]);
    }
    const out = [];
    for (let i = 0; i < n; i++) {
      const [x1, y1, x2, y2] = lines[(i + n - 1) % n], [x3, y3, x4, y4] = lines[i];
      const den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
      const t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / den;
      out.push([x1 + t * (x2 - x1), y1 + t * (y2 - y1)]);
    }
    return out;
  }
  const lerp = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];

  // a glass gradient: light at the top-left, colour, darker at the edge
  function grad(defs, stops, x1 = 0, y1 = 0, x2 = 0, y2 = 1) {
    const id = "g" + (++uid);
    defs.push(`<linearGradient id="${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}">${stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join("")}</linearGradient>`);
    return `url(#${id})`;
  }
  // a soft coloured halo behind a group (blurred copy of its shape, tinted)
  function halo(defs, colour, sd = 12, k = 0.85) {
    const id = "h" + (++uid);
    defs.push(`<filter id="${id}" x="-50%" y="-50%" width="200%" height="200%"><feMorphology in="SourceAlpha" operator="dilate" radius="4" result="d"/><feGaussianBlur in="d" stdDeviation="${sd}" result="b"/><feFlood flood-color="${colour}" flood-opacity="${k}"/><feComposite in2="b" operator="in" result="g"/><feMerge><feMergeNode in="g"/><feMergeNode in="SourceGraphic"/></feMerge></filter>`);
    return `url(#${id})`;
  }

  // ---- the looks. Each returns SVG for the back (behind the card) or front (over the frame). ----
  const LOOK = {};

  // Guard: a leaded amber ward round the whole card, thicker over the roof, like a shield's rim
  LOOK.Guard = (defs) => {
    const d = [44, 26, 34, 34, 26, 44];
    const outer = offset(OUT, d), inner = offset(OUT, -10);
    const fill = grad(defs, [[0, "#fff1c2"], [0.35, "#f0c04a"], [0.75, "#d9a633"], [1, "#9a6a14"]], 0, 0, 1, 1);
    // cross leads across the band, every ~110 units along each edge
    const leads = [];
    for (let i = 0; i < 6; i++) {
      const a = OUT[i], b = OUT[(i + 1) % 6], oa = outer[i], ob = outer[(i + 1) % 6];
      const len = Math.hypot(b[0] - a[0], b[1] - a[1]), n = Math.max(1, Math.round(len / 120));
      for (let k = 0; k <= n; k++) {
        const t = k / n, p = lerp(a, b, t), q = lerp(oa, ob, t);
        leads.push(`M${f(p[0])},${f(p[1])} L${f(q[0])},${f(q[1])}`);
      }
    }
    const studs = [outer[0], outer[1], outer[2], outer[3], outer[4], outer[5]].map(([x, y]) => [x * 0.93 + 280 * 0.07, y * 0.93 + 500 * 0.07]);
    return { back: `<g class="kw-guard" filter="${halo(defs, "#ffcf5a", 14, 0.75)}">
      <path d="M${pts(outer)}Z M${pts(inner)}Z" fill-rule="evenodd" fill="${fill}"/>
      <path d="M${pts(offset(OUT, d.map(v => v * 0.55)))}Z" fill="none" stroke="#fff6d8" stroke-opacity=".55" stroke-width="5"/>
      <path d="${leads.join(" ")}" stroke="${INK}" stroke-width="10" fill="none"/>
      <path d="M${pts(outer)}Z" fill="none" stroke="${INK}" stroke-width="13" stroke-linejoin="round"/>
      ${studs.map(([x, y]) => `<circle cx="${f(x)}" cy="${f(y)}" r="13" fill="#ffe7a6" stroke="${INK}" stroke-width="7"/>`).join("")}
    </g>` };
  };

  // Reserve: a lancet arch of pale blue glass behind the top of the card: a niche it waits in
  LOOK.Reserve = (defs) => {
    const o = 30, t = 30, y0 = 560;
    const arc = (dx, top) => `M${-dx},${y0} L${-dx},210 C${-dx},${top + 120} ${120 - dx},${top + 10} 280,${top} C${440 + dx},${top + 10} ${560 + dx},${top + 120} ${560 + dx},210 L${560 + dx},${y0}`;
    const fill = grad(defs, [[0, "#eef0ff"], [0.5, "#a9b4ea"], [1, "#5e66b8"]], 0, 0, 0, 1);
    const mid = arc(o + t / 2, -104);
    return { back: `<g class="kw-reserve" filter="${halo(defs, "#b8c2ff", 12, 0.7)}">
      <path d="${mid}" fill="none" stroke="${INK}" stroke-width="${t + 22}" stroke-linecap="butt"/>
      <path d="${mid}" fill="none" stroke="${fill}" stroke-width="${t}" stroke-linecap="butt"/>
      <path d="${mid}" fill="none" stroke="${INK}" stroke-width="${t + 2}" stroke-dasharray="7 95" stroke-linecap="butt"/>
      <path d="${mid}" fill="none" stroke="#ffffff" stroke-opacity=".5" stroke-width="5" transform="translate(-4,-4)"/>
      <path d="M${-o - t - 6},${y0} h${t + 12} M${554 + o},${y0} h${t + 12}" stroke="${INK}" stroke-width="16"/>
    </g>` };
  };

  // Overrun: two chevrons of red glass above the crest, pointing at the enemy
  LOOK.Overrun = (defs) => {
    const fill = grad(defs, [[0, "#ffe0b8"], [0.45, "#f0773a"], [1, "#a8301c"]], 0, 0, 0, 1);
    const chev = (cy, w, h, th) => `M${280 - w},${cy} L280,${cy - h} L${280 + w},${cy} L${280 + w},${cy + th * 0.2} L${280 + w - th * 0.9},${cy + th * 0.55} L280,${cy - h + th} L${280 - w + th * 0.9},${cy + th * 0.55} L${280 - w},${cy + th * 0.2}Z`;
    return { front: `<g class="kw-overrun dir" filter="${halo(defs, "#ff7a3a", 10, 0.7)}">
      <g class="kw-pulse"><path d="${chev(-2, 104, 66, 36)}" fill="${fill}" stroke="${INK}" stroke-width="11" stroke-linejoin="round"/>
      <path d="${chev(-56, 84, 54, 32)}" fill="${fill}" stroke="${INK}" stroke-width="11" stroke-linejoin="round"/></g>
    </g>` };
  };

  // Sortie: an arrow of sky glass arcing over the crest, from one shoulder over the top
  LOOK.Sortie = (defs) => {
    const path = "M500,150 C470,-40 330,-120 200,-95 C140,-82 95,-48 70,-10";
    const head = "M35,30 L52,-52 L104,-6 Z";
    const fill = grad(defs, [[0, "#f2fbff"], [0.5, "#8fd0ee"], [1, "#2f88a8"]], 0, 0, 1, 1);
    return { front: `<g class="kw-sortie dir" filter="${halo(defs, "#9fe0ff", 10, 0.7)}">
      <path d="${path}" fill="none" stroke="${INK}" stroke-width="34" stroke-linecap="round"/>
      <path class="kw-flow" d="${path}" fill="none" stroke="${fill}" stroke-width="18" stroke-linecap="round" stroke-dasharray="44 12"/>
      <path d="M486,186 l-20,-62 M528,170 l-36,-56" stroke="${INK}" stroke-width="24" stroke-linecap="round"/>
      <path d="M486,186 l-20,-62 M528,170 l-36,-56" stroke="#bfe9f7" stroke-width="10" stroke-linecap="round"/>
      <path d="${head}" fill="${fill}" stroke="${INK}" stroke-width="12" stroke-linejoin="round"/>
    </g>` };
  };

  // Molt: a pale husk hugging the top of the card, split down the crest and lifting away, as a skin about to be shed
  LOOK.Molt = (defs) => {
    const fill = grad(defs, [[0, "#ffffff", 0.9], [0.45, "#ece0ff", 0.72], [1, "#b49ae6", 0.75]], 0, 0, 1, 1);
    // the left half: outside the left edge from y 360 up over the shoulder to the crest, a jagged split, back inside the border
    const half = [[-20, 330], [-20, 164], [262, -26], [248, 8], [266, 38], [248, 70], [256, 92], [40, 206], [40, 330]];
    const seams = "M-20,262 L40,262 M60,110 L96,178 M150,50 L176,134";
    const shine = "M-6,310 L-6,174 L200,36";
    const one = `<path d="M${pts(half)}Z" fill="${fill}" stroke="${INK}" stroke-width="12" stroke-linejoin="round"/>
      <path d="${seams}" stroke="${INK}" stroke-width="8"/><path d="${shine}" fill="none" stroke="#fff" stroke-opacity=".85" stroke-width="5"/>`;
    return { front: `<g class="kw-molt" filter="${halo(defs, "#d9c2ff", 12, 0.8)}"><g class="kw-shimmer">
      <g transform="translate(-4,-8) rotate(-3 0 330)">${one}</g>
      <g transform="translate(564,-8) scale(-1,1) rotate(-3 0 330)">${one}</g></g></g>` };
  };

  // shards of glass along a path of cubic pieces: [x0,y0, x1,y1, x2,y2, x3,y3, ...]; widths taper along it
  function shards(c, n, w0, w1, w2, fill, gapK = 0.18) {
    const segs = (c.length - 2) / 6, P = [];
    for (let i = 0; i <= n; i++) {
      const u = i / n * segs, s = Math.min(segs - 1, Math.floor(u)), t = u - s, o = s * 6;
      const [x0, y0, x1, y1, x2, y2, x3, y3] = c.slice(o, o + 8), m = 1 - t;
      const x = m * m * m * x0 + 3 * m * m * t * x1 + 3 * m * t * t * x2 + t * t * t * x3;
      const y = m * m * m * y0 + 3 * m * m * t * y1 + 3 * m * t * t * y2 + t * t * t * y3;
      const dx = 3 * m * m * (x1 - x0) + 6 * m * t * (x2 - x1) + 3 * t * t * (x3 - x2), dy = 3 * m * m * (y1 - y0) + 6 * m * t * (y2 - y1) + 3 * t * t * (y3 - y2);
      const L = Math.hypot(dx, dy) || 1, q = i / n, w = q < 0.5 ? w0 + (w1 - w0) * q * 2 : w1 + (w2 - w1) * (q - 0.5) * 2;
      P.push([x, y, -dy / L * w / 2, dx / L * w / 2]);
    }
    let out = "";
    for (let i = 0; i < n; i++) {
      const a = P[i], b = P[i + 1], g = gapK / 2;
      const A = [a[0] + (b[0] - a[0]) * g, a[1] + (b[1] - a[1]) * g], B = [b[0] - (b[0] - a[0]) * g, b[1] - (b[1] - a[1]) * g];
      const poly = [[A[0] + a[2], A[1] + a[3]], [B[0] + b[2], B[1] + b[3]], [B[0] - b[2], B[1] - b[3]], [A[0] - a[2], A[1] - a[3]]];
      out += `<path d="M${pts(poly)}Z" fill="${fill}" stroke="${INK}" stroke-width="7" stroke-linejoin="round"/>`;
    }
    return out;
  }

  // shards along any list of points [x, y] (already sampled), widths w(q) for q in 0..1
  function shardsAt(P0, w, fill, gapK = 0.2, sw = 7) {
    const n = P0.length - 1, P = P0.map(([x, y], i) => {
      const a = P0[Math.max(0, i - 1)], b = P0[Math.min(n, i + 1)], dx = b[0] - a[0], dy = b[1] - a[1], L = Math.hypot(dx, dy) || 1, k = w(i / n) / 2;
      return [x, y, -dy / L * k, dx / L * k];
    });
    let out = "";
    for (let i = 0; i < n; i++) {
      const a = P[i], b = P[i + 1], g = gapK / 2;
      const A = [a[0] + (b[0] - a[0]) * g, a[1] + (b[1] - a[1]) * g], B = [b[0] - (b[0] - a[0]) * g, b[1] - (b[1] - a[1]) * g];
      out += `<path d="M${pts([[A[0] + a[2], A[1] + a[3]], [B[0] + b[2], B[1] + b[3]], [B[0] - b[2], B[1] - b[3]], [A[0] - a[2], A[1] - a[3]]])}Z" fill="${fill}" stroke="${INK}" stroke-width="${sw}" stroke-linejoin="round"/>`;
    }
    return out;
  }

  // Attacks twice: two whirls of pale glass shards round the card, like a gust wrapping it; the far side of each
  // whirl goes behind the card, the near side crosses in front
  LOOK["Attacks twice"] = (defs) => {
    const fill = grad(defs, [[0, "#ffffff", 0.95], [0.5, "#e8f7ff", 0.9], [1, "#b4dcf2", 0.9]], 0, 0, 0, 1);
    const whirl = (yc, rx, ry, a0, a1, wmax) => {
      // from angle a0 to a1 (degrees, 90 = nearest the viewer, below the centre); split into the near and far parts
      const n = 16, P = [];
      for (let i = 0; i <= n; i++) { const t = (a0 + (a1 - a0) * i / n) * Math.PI / 180; P.push([280 + rx * Math.cos(t), yc + ry * Math.sin(t), Math.sin(t)]); }
      const w = q => 4 + (wmax - 4) * Math.pow(Math.sin(Math.PI * Math.min(1, q * 1.08)), 0.7);
      const near = [], far = [];
      // keep the shard index so widths run along the whole whirl
      const pieces = [];
      let cur = null;
      P.forEach((p, i) => { const side = p[2] >= 0 ? "near" : "far"; if (!cur || cur.side !== side) { if (cur) cur.pts.push(p); cur = { side, pts: cur ? [cur.pts[cur.pts.length - 2] ? P[i - 1] : p, p] : [p], i0: Math.max(0, i - 1) }; pieces.push(cur); } else cur.pts.push(p); });
      pieces.forEach(pc => { const svg = shardsAt(pc.pts.map(([x, y]) => [x, y]), q => w((pc.i0 + q * (pc.pts.length - 1)) / n), fill, 0.1, 5); (pc.side === "near" ? near : far).push(svg); });
      return { near: near.join(""), far: far.join("") };
    };
    const A = whirl(410, 312, 52, 205, 515, 44), B = whirl(600, 304, 46, 165, 470, 36);
    const tilt = (y, d) => `rotate(${d} 280 ${y})`;
    return {
      back: `<g class="kw-twice" filter="${halo(defs, "#e2f6ff", 8, 0.8)}"><g transform="${tilt(410, -7)}"><g class="kw-drift">${A.far}</g></g><g transform="${tilt(600, 6)}"><g class="kw-drift d2">${B.far}</g></g></g>`,
      front: `<g class="kw-twice" filter="${halo(defs, "#e2f6ff", 8, 0.8)}"><g transform="${tilt(410, -7)}"><g class="kw-drift">${A.near}</g></g><g transform="${tilt(600, 6)}"><g class="kw-drift d2">${B.near}</g></g></g>`,
    };
  };

  // Thorns: a lead bramble stem down each long side with red-tipped thorns pointing out
  LOOK.Thorns = (defs) => {
    const fill = grad(defs, [[0, "#ffd0c2"], [0.4, "#e0503a"], [1, "#7c1a10"]], 1, 0, 0, 0);
    const thorn = (y, up) => `M18,${y - 26} L-34,${y + (up ? -24 : 14)} L18,${y + 22}Z`;
    const ys = [235, 345, 455, 565, 675, 785];
    const side = `<path d="M16,200 C30,260 4,320 16,380 S30,500 16,560 S4,680 16,740 S30,800 18,820" fill="none" stroke="${INK}" stroke-width="18"/>
      <path d="M16,200 C30,260 4,320 16,380 S30,500 16,560 S4,680 16,740 S30,800 18,820" fill="none" stroke="#5b7a2e" stroke-width="7"/>
      ${ys.map((y, i) => `<path d="${thorn(y, i % 2)}" fill="${fill}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>`).join("")}
      <path d="M118,98 L78,36 L148,80Z" fill="${fill}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>`;
    return { front: `<g class="kw-thorns" filter="${halo(defs, "#ff5a3a", 8, 0.6)}">${side}<g transform="translate(560,0) scale(-1,1)">${side}</g></g>` };
  };

  // Cleave: an axe blade on each long side, red glass with a bright edge: it also hits the units beside the target
  LOOK.Cleave = (defs) => {
    const blade = grad(defs, [[0, "#ffe2d6"], [0.35, "#ff7a52"], [1, "#9e2414"]], 1, 0, 0, 0);
    const side = `<path d="M30,320 L-4,350 C-62,400 -70,520 -4,580 L30,610 L30,540 L4,520 L4,410 L30,390Z" fill="${blade}" stroke="${INK}" stroke-width="12" stroke-linejoin="round"/>
      <path d="M-30,380 C-54,430 -54,500 -30,550" fill="none" stroke="#fff4e6" stroke-width="8" stroke-linecap="round"/>
      <path d="M4,410 L4,520" stroke="${INK}" stroke-width="10"/>`;
    return { front: `<g class="kw-cleave" filter="${halo(defs, "#ff7a52", 10, 0.7)}"><g class="kw-glint">${side}<g transform="translate(560,0) scale(-1,1)">${side}</g></g></g>` };
  };

  // Pile on: two linked rings on each long side: neighbours with Pile on look chained together
  LOOK["Pile on"] = (defs) => {
    const ring = "#ffbe8a", r = 34;
    const loop = (x, y) => `<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="${INK}" stroke-width="24"/><circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="${ring}" stroke-width="11"/>`;
    const side = `${loop(26, 650)}${loop(-8, 598)}
      <path d="M${26 - r},650 A${r},${r} 0 0 1 ${26 - r * 0.2},${650 - r * 0.98}" fill="none" stroke="${INK}" stroke-width="24"/>
      <path d="M${26 - r},650 A${r},${r} 0 0 1 ${26 - r * 0.2},${650 - r * 0.98}" fill="none" stroke="${ring}" stroke-width="11"/>
      <path d="M-36,590 A30,30 0 0 1 -14,568" fill="none" stroke="#fff" stroke-opacity=".8" stroke-width="4"/>`;
    return { front: `<g class="kw-pile" filter="${halo(defs, "#ff9a5a", 8, 0.65)}">${side}<g transform="translate(560,0) scale(-1,1)">${side}</g></g>` };
  };

  // Fury N: glass flames licking up both lower corners; taller for a bigger Fury
  LOOK.Fury = (defs, kw) => {
    const n = Math.max(1, kw.n || 1), s = Math.min(1.15, 0.85 + 0.1 * n);
    const outer = grad(defs, [[0, "#b8301c"], [0.5, "#f0642a"], [1, "#ffb43a"]], 0, 0, 0, 1);
    const core = grad(defs, [[0, "#ffd35a"], [1, "#fff6c8"]], 0, 0, 0, 1);
    // a tongue of flame: a round base, a bulging side and a hooked tip
    const tongue = (x, y, h, w, lean) => `M${x},${y} C${x - w},${y - h * .08} ${x - w * 1.05},${y - h * .45} ${x - w * .35 + lean * .5},${y - h * .68}`
      + ` C${x - w * .1 + lean * .8},${y - h * .82} ${x + lean * .85},${y - h * .9} ${x + lean},${y - h}`
      + ` C${x + w * .4 + lean * .5},${y - h * .78} ${x + w * .95},${y - h * .55} ${x + w * .8},${y - h * .3}`
      + ` C${x + w * .7},${y - h * .1} ${x + w * .35},${y} ${x},${y}Z`;
    const flame = (x, y, h, w, lean, cls) => `<g class="${cls}" style="transform-origin:${x}px ${y}px">
      <path d="${tongue(x, y, h, w, lean)}" fill="${outer}" stroke="${INK}" stroke-width="10" stroke-linejoin="round"/>
      <path d="${tongue(x + 2, y - 8, h * .5, w * .5, lean * .45)}" fill="${core}" stroke="${INK}" stroke-width="6" stroke-linejoin="round"/></g>`;
    // the flames stay outside the Attack and Health discs: they rise from the lower corner and lean out
    const side = `<g transform="translate(0,930) scale(${s}) translate(0,-930)">
      ${flame(-26, 850, 180, 44, -26, "kw-flick c")}${flame(36, 984, 160, 44, -26, "kw-flick b")}${flame(8, 930, 280, 62, -40, "kw-flick")}</g>`;
    return { front: `<g class="kw-fury" filter="${halo(defs, "#ff6a2a", 12, 0.75)}">${side}<g transform="translate(560,0) scale(-1,1)">${side}</g></g>` };
  };

  // Root N: lead roots with green glass knots, gripping the bottom point and running up the lower edges
  LOOK.Root = (defs) => {
    const knot = grad(defs, [[0, "#e6ffbf"], [0.5, "#7fc24a"], [1, "#2f6a1c"]], 0, 0, 1, 1);
    const wood = "#8a5a2e";
    const roots = [
      "M280,930 C276,980 262,1010 238,1056", "M280,930 C284,990 286,1030 280,1072", "M280,930 C290,980 304,1010 328,1052",
      "M280,950 C220,940 150,910 70,868 C40,852 20,846 -6,850", "M280,950 C340,940 410,910 490,868 C520,852 540,846 566,850",
      "M150,912 L132,962 M410,912 L428,962", "M70,868 L40,900 M490,868 L520,900", "M238,1056 L214,1072 M328,1052 L352,1066",
    ].join(" ");
    const knots = [[280, 940], [150, 912], [410, 912], [70, 868], [490, 868]];
    return { front: `<g class="kw-root" filter="${halo(defs, "#9ee05a", 8, 0.55)}">
      <path d="${roots}" fill="none" stroke="${INK}" stroke-width="26" stroke-linecap="round"/>
      <path d="${roots}" fill="none" stroke="${wood}" stroke-width="12" stroke-linecap="round"/>
      <path d="${roots}" fill="none" stroke="#d9a873" stroke-opacity=".6" stroke-width="3" stroke-linecap="round" transform="translate(-2,-3)"/>
      ${knots.map(([x, y], i) => `<circle cx="${x}" cy="${y}" r="${i ? 17 : 22}" fill="${knot}" stroke="${INK}" stroke-width="8"/>`).join("")}
    </g>` };
  };

  // Stiff Upper Lip: a ring of gold glass bound round the Health disc, with a clasp at the top
  LOOK["Stiff Upper Lip"] = (defs, kw, h) => {
    const t = (window.CARD_DATA.roundels["tier" + (kw.tier || 1)] || window.CARD_DATA.roundels.tier1).health;
    const [cx, cy] = t.centre_units, r0 = t.radius_units + 6, r1 = r0 + 26, rm = (r0 + r1) / 2;
    const fill = grad(defs, [[0, "#fff1c2"], [0.5, "#f0c04a"], [1, "#a8741a"]], 0, 0, 1, 1);
    const spokes = [...Array(8)].map((_, i) => { const a = Math.PI * 2 * i / 8 + Math.PI / 8;
      return `M${f(cx + r0 * Math.cos(a))},${f(cy + r0 * Math.sin(a))} L${f(cx + r1 * Math.cos(a))},${f(cy + r1 * Math.sin(a))}`; }).join(" ");
    return { front: `<g class="kw-lip" filter="${halo(defs, "#ffd36a", 10, 0.75)}">
      <circle cx="${cx}" cy="${cy}" r="${rm}" fill="none" stroke="${INK}" stroke-width="${r1 - r0 + 14}"/>
      <circle cx="${cx}" cy="${cy}" r="${rm}" fill="none" stroke="${fill}" stroke-width="${r1 - r0 - 2}"/>
      <path d="${spokes}" stroke="${INK}" stroke-width="7"/>
      <path d="M${cx - 22},${cy - r1 - 14} h44 v30 h-44Z" fill="#ffe7a6" stroke="${INK}" stroke-width="8"/>
    </g>` };
  };

  // Hand-me-down (dev): a ring of green glass tied round the Attack disc, its bow and ribbon tails trailing out of
  // the card: when this dies, its Attack is handed to the nearest Mouse. got: true is the receiver's look, this fight
  // only: the same green bow pinned over its Attack disc, no ring and no mark.
  LOOK["Hand-me-down"] = (defs, kw) => {
    const t = (window.CARD_DATA.roundels["tier" + (kw.tier || 1)] || window.CARD_DATA.roundels.tier1).attack;
    const [cx, cy] = t.centre_units, r0 = t.radius_units + 6, r1 = r0 + 22, rm = (r0 + r1) / 2;
    const fill = grad(defs, [[0, "#e6ffbf"], [0.5, "#7fc24a"], [1, "#2f6a1c"]], 0, 0, 1, 1);
    const ribbon = grad(defs, [[0, "#d8f7b0"], [1, "#4f9a3a"]], 0, 0, 0, 1);
    const bow = (x, y, k) => `<g transform="translate(${x},${y}) scale(${k})">
      <path d="M0,0 L-46,-30 L-50,22Z M0,0 L44,-34 L48,18Z" fill="${ribbon}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
      <path d="M-4,6 L-34,74 L-14,66 L-2,88 L8,10Z M6,6 L26,70" fill="${ribbon}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
      <circle r="14" fill="#c8f2a6" stroke="${INK}" stroke-width="8"/></g>`;
    if (kw.got) return { front: `<g class="kw-hmd-got" filter="${halo(defs, "#a6f07a", 10, 0.75)}">${bow(cx - 6, cy - r0 - 18, 0.9)}</g>` };
    const spokes = [...Array(7)].map((_, i) => { const a = Math.PI * 2 * i / 7 + 0.3;
      return `M${f(cx + r0 * Math.cos(a))},${f(cy + r0 * Math.sin(a))} L${f(cx + r1 * Math.cos(a))},${f(cy + r1 * Math.sin(a))}`; }).join(" ");
    return { front: `<g class="kw-hmd" filter="${halo(defs, "#a6f07a", 10, 0.75)}">
      <circle cx="${cx}" cy="${cy}" r="${rm}" fill="none" stroke="${INK}" stroke-width="${r1 - r0 + 14}"/>
      <circle cx="${cx}" cy="${cy}" r="${rm}" fill="none" stroke="${fill}" stroke-width="${r1 - r0 - 2}"/>
      <path d="${spokes}" stroke="${INK}" stroke-width="7"/>
      <g class="kw-sway" style="transform-origin:${f(cx - r1)}px ${cy + 30}px">
        <path d="M${f(cx - r1 + 6)},${cy + 26} C${f(cx - r1 - 40)},${cy + 70} ${f(cx - r1 - 60)},${cy + 100} ${f(cx - r1 - 86)},${cy + 150} L${f(cx - r1 - 56)},${cy + 136} L${f(cx - r1 - 52)},${cy + 168} C${f(cx - r1 - 30)},${cy + 110} ${f(cx - r1 - 10)},${cy + 70} ${f(cx - r1 + 22)},${cy + 40}Z" fill="${ribbon}" stroke="${INK}" stroke-width="9" stroke-linejoin="round"/>
        ${bow(f(cx - r1 + 8), cy + 22, 0.8)}</g>
    </g>` };
  };

  // a spent look: grey, cracked, faded (the marks' SPENT_ALPHA is 0.4)
  function spentWrap(svg, defs) {
    const id = "s" + (++uid);
    defs.push(`<filter id="${id}"><feColorMatrix type="saturate" values="0.05"/><feComponentTransfer><feFuncR type="linear" slope=".75"/><feFuncG type="linear" slope=".75"/><feFuncB type="linear" slope=".8"/></feComponentTransfer></filter>`);
    return `<g class="spent" filter="url(#${id})" opacity=".45">${svg}</g>`;
  }
  const CRACK = {
    Molt: `<path d="M120,60 L150,110 L130,150 M440,60 L410,108 L432,146 M-20,300 L20,320" fill="none" stroke="${INK}" stroke-width="9"/>`,
    Root: `<path d="M258,1000 l26,22 M140,912 l20,20 M420,906 l-20,22" stroke="${INK}" stroke-width="10"/>`,
    "Stiff Upper Lip": "",
  };

  // ---- the round marks, as the game draws them (keyword_mark.gd): up to 3, the 3rd says +N when there are more ----
  function marks(card, kws, h) {
    const S = style(), d = Math.max(21.1, 0.09 * h), gap = 3;
    const shown = kws.length > 3 ? [...kws.slice(0, 2), { more: kws.length - 2 }] : kws;
    const row = document.createElement("div");
    row.className = "kw-marks";
    row.style.cssText = `top:${(0.925 * h - d / 2).toFixed(1)}px;height:${d.toFixed(1)}px;gap:${gap}px`;
    shown.forEach(k => {
      const m = document.createElement("div");
      m.className = "kw-mark" + (k.spent ? " spent" : "");
      m.style.width = m.style.height = d.toFixed(1) + "px";
      if (k.more) {
        m.style.background = "#7d8a99";
        m.innerHTML = `<b style="font-size:${Math.max(14, d * 0.6).toFixed(0)}px;position:static">+${k.more}</b>`;
      } else {
        const def = S.keywords[k.k] || { family: "count", icon: "uses" }, fam = S.families[def.family];
        m.style.background = "#" + fam.colour;
        m.innerHTML = `<i style="width:${(d * 0.72).toFixed(1)}px;height:${(d * 0.72).toFixed(1)}px"></i>
          <svg viewBox="0 0 24 24" style="width:${(d * 0.62).toFixed(1)}px;height:${(d * 0.62).toFixed(1)}px;stroke:#${fam.light}">${S.icons[def.icon] || ""}</svg>`
          + (k.n ? `<b style="font-size:${Math.max(14, d * 0.6).toFixed(0)}px;left:${(d * 0.65).toFixed(1)}px;top:${(d * 0.45).toFixed(1)}px">${k.n}</b>` : "");
      }
      row.append(m);
    });
    card.append(row);
  }

  // Charge and Supply pips (dev, card_pips.gd): round pips for Charge, small square crates for Supply, centred just
  // over the stat discs, the count family's light glass in the marks' lead; a used one fades to 0.4. Drawn as dev does.
  function pipRow(card, pips, h, tier) {
    const t = (window.CARD_DATA.roundels["tier" + tier] || window.CARD_DATA.roundels.tier1).attack, k = h / 1000;
    const side = Math.max(8, Math.round(h * 0.05)), gap = 3, w = h * 0.56;
    let bottom = (t.centre_units[1] - t.radius_units * 1.12) * k - 3;
    pips.forEach(({ kind, total, left }) => {
      const width = total * side + (total - 1) * gap;
      for (let n = 0; n < total; n++) {
        const p = document.createElement("div");
        p.className = "kw-pip" + (n >= left ? " spent" : "");
        p.style.cssText = `left:${((w - width) / 2 + n * (side + gap)).toFixed(1)}px;top:${(bottom - side).toFixed(1)}px;width:${side}px;height:${side}px;border-radius:${kind === "charge" ? "50%" : (side * 0.2).toFixed(1) + "px"}`;
        card.append(p);
      }
      bottom -= side + 4;
    });
  }

  // Renown N on a slot (dev): a gold glass star medallion with the number at the slot's foot, and laurel sprays up its
  // lower edges, longer for more Renown. On the enemy's board (flip) it sits at the slot's top: the side away from you,
  // so it never meets Overrun or Sortie, which point at the enemy. It belongs to the slot, so it is the same with a unit on it or none, and is drawn
  // over the cards like dev's own Renown pill (which it replaces). Returns an element to place at the slot's top-left.
  function renown(n, h, flip = false) {
    const k = h / 1000, defs = [];
    const gold = grad(defs, [[0, "#fff1c2"], [0.5, "#f0c04a"], [1, "#a8741a"]], 0, 0, 1, 1);
    const leaf = grad(defs, [[0, "#f4f0a0"], [0.5, "#b8c24a"], [1, "#5e7a1c"]], 0, 0, 1, 1);
    const pairs = n >= 6 ? 4 : n >= 3 ? 3 : 2, cx = 280, cy = 1036;
    // leaves along the lower-left edge, from the medallion up towards the corner; mirrored for the right
    let side = "";
    for (let i = 0; i < pairs; i++) {
      const q = 0.18 + i * 0.2, x = cx - 280 * q - 34, y = cy - 40 - 176 * q;
      side += `<ellipse cx="${f(x - 18)}" cy="${f(y + 6)}" rx="30" ry="13" transform="rotate(${-58} ${f(x - 18)} ${f(y + 6)})" fill="${leaf}" stroke="${INK}" stroke-width="8"/>`
            + `<ellipse cx="${f(x + 14)}" cy="${f(y - 18)}" rx="30" ry="13" transform="rotate(${-12} ${f(x + 14)} ${f(y - 18)})" fill="${leaf}" stroke="${INK}" stroke-width="8"/>`;
    }
    const last = 0.18 + (pairs - 1) * 0.2;
    const stem = `M${cx - 40},${cy - 22} L${f(cx - 280 * last - 40)},${f(cy - 40 - 176 * last - 10)}`;
    const star = [...Array(16)].map((_, i) => { const a = Math.PI * i / 8 - Math.PI / 2, r = i % 2 ? 62 : 88; return `${f(cx + r * Math.cos(a))},${f(cy + r * Math.sin(a))}`; }).join(" ");
    const sprays = `<path d="${stem}" stroke="${INK}" stroke-width="16" stroke-linecap="round"/><path d="${stem}" stroke="#8a6a2e" stroke-width="7" stroke-linecap="round"/>${side}`;
    const hf = halo(defs, "#ffd36a", 10, 0.7);
    const el = document.createElement("div");
    el.className = "kw-renown";
    el.style.cssText = `position:absolute;pointer-events:none;width:${560 * k}px;height:${1000 * k}px;z-index:8`;
    el.innerHTML = `<svg class="kw-layer" style="left:${-P * k}px;top:${-P * k}px;width:${(560 + 2 * P) * k}px;height:${(1000 + 2 * P) * k}px" viewBox="${-P} ${-P} ${560 + 2 * P} ${1000 + 2 * P}" xmlns="http://www.w3.org/2000/svg"><defs>${defs.join("")}</defs>
      <g filter="${hf}" ${flip ? 'transform="translate(0,1000) scale(1,-1)"' : ""}>${sprays}<g transform="translate(560,0) scale(-1,1)">${sprays}</g>
      <polygon points="${star}" fill="${gold}" stroke="${INK}" stroke-width="11" stroke-linejoin="round"/>
      <circle cx="${cx}" cy="${cy}" r="52" fill="#fff3d6" stroke="${INK}" stroke-width="9"/></g>
      <text x="${cx}" y="${(flip ? 1000 - cy : cy) + 26}" text-anchor="middle" font-family="Alegreya,Georgia,serif" font-weight="900" font-size="${String(n).length > 1 ? 66 : 78}" fill="#150e08">${n}</text></svg>`;
    return el;
  }

  // order in which the looks are drawn, back to front
  const ORDER = ["Reserve", "Guard", "Root", "Fury", "Hand-me-down", "Thorns", "Cleave", "Pile on", "Attacks twice", "Molt", "Overrun", "Sortie", "Stiff Upper Lip"];

  function decorate(card, kws, { h, flip = false, looks = true, showMarks = true, tier = 1, pips = null } = {}) {
    const k = h / 1000, W = 560 + 2 * P, H = 1000 + 2 * P;
    if (looks) {
      const defs = [], back = [], front = [];
      ORDER.forEach(name => kws.filter(x => x.k === name).forEach(kw => {
        const r = LOOK[name](defs, { tier, ...kw }, h);
        let b = r.back || "", fr = r.front || "";
        if (flip && /class="[^"]*\bdir\b/.test(fr)) fr = `<g transform="translate(0,1000) scale(1,-1)">${fr}</g>`;
        if (kw.spent) { b = b && spentWrap(b + (CRACK[name] || ""), defs); fr = fr && spentWrap(fr + (CRACK[name] || ""), defs); }
        if (b) back.push(b); if (fr) front.push(fr);
      }));
      const svg = (layer, z) => `<svg class="kw-layer" style="left:${-P * k}px;top:${-P * k}px;width:${W * k}px;height:${H * k}px;z-index:${z}" viewBox="${-P} ${-P} ${W} ${H}" xmlns="http://www.w3.org/2000/svg"><defs>${defs.join("")}</defs>${layer.join("")}</svg>`;
      if (back.length) card.insertAdjacentHTML("afterbegin", svg(back, -1));
      if (front.length) card.insertAdjacentHTML("beforeend", svg(front, 3));
    }
    const marked = kws.filter(x => !x.got);
    if (showMarks && marked.length) marks(card, marked, h);
    if (pips) pipRow(card, pips, h, tier);
    return card;
  }

  window.KW = { decorate, renown, NAMES: ORDER };
})();
