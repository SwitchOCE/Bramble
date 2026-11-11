// Slot shapes: a small lab experiment. The same 4-3 board, drawn with different
// unit shapes, in both layouts (bottom-up and left-right), in the same zone sizes
// the Arena and Nouveau use. Shapes that point toward the next row let the back
// row tuck in, so the board gets shorter and every unit can be drawn bigger.
(function () {
  const stage = document.getElementById('stage');
  const P = J.params;
  const S = { shape: P.get('shape') || 'honey', lay: P.get('lay') || 'bu', view: P.get('view') || 'one' };
  const G = J.state(4);
  const GAP = 16;

  // Each shape is drawn in a unit frame: x runs along the row, y runs across it,
  // and y = 0 is the edge that faces the enemy. f = front row, b = back row.
  // t: how far (as a share of the unit's depth) the back row can tuck into the front.
  const hex = (t) => [[.5, 0], [1, t], [1, 1 - t], [.5, 1], [0, 1 - t], [0, t]];
  const SHAPES = [
    { id: 'card', name: 'Card', tag: 'today', a: { bu: .75, lr: .75 }, t: 0, round: true,
      line: 'The plain rounded card every look uses now. The baseline for size.',
      good: ['The whole picture shows; nothing is cropped.', 'Familiar: reads as a card at once.'],
      bad: ['Rows sit apart, so the board reads as two lines, not one block.', 'No tucking: the board needs the most height.'],
      vary: ['Square corners for a harder edge.', 'A slight tilt per slot (as in Storybook) for a hand-placed feel.'] },
    { id: 'chamfer', name: 'Cut corners', a: { bu: .75, lr: .75 }, t: 0, chamfer: .16,
      line: 'A card with its four corners cut off: angular, but still a card.',
      good: ['Crisp and angular for almost no art lost.', 'Where four slots meet, the gaps form small diamonds, a hint of weave.'],
      bad: ['Doesn\'t tuck: same height as the plain card.', 'On its own, it reads as a style choice more than a shape.'],
      vary: ['Cut only the corners that face the next row.', 'Cut the corners deeper, until it is nearly an octagon.'] },
    { id: 'longhex', name: 'Tall hex', pick: true, a: { bu: .75, lr: .75 }, t: .17,
      line: 'A card with a point at each end. The points lock into the next row.',
      good: ['Keeps a card\'s tall shape and most of the art.', 'The back row tucks in a little: at the same unit width, the board is about a tenth shallower.', 'Rows read as one locked block.'],
      bad: ['The tip of each point crops the art (ears and hats).', 'Numbers sit on the slanted corners, slightly tighter.'],
      vary: ['Point only toward the enemy (a spearhead).', 'A sharper point, partway to the near-diamond.'] },
    { id: 'midhex', name: 'Mid hex', pick: true, a: { bu: .81, lr: .81 }, t: .21,
      line: 'Between the two: taller than a regular hexagon, squatter than the tall hex.',
      good: ['Keeps a portrait shape while tucking in almost as far as the honeycomb.', 'Stays taller than wide in both layouts, so it never turns on its side.', 'Faces sit in a wider middle band than in the tall hex.'],
      bad: ['Not a true tessellation of the regular kind, so it reads less instantly as "honeycomb".', 'Still crops ears and hats in the top corners.'],
      vary: ['Round the six corners slightly.', 'The same proportions with a flat top on the front row (toward the enemy).'] },
    { id: 'honey', name: 'Honeycomb', pick: true, a: { bu: .866, lr: 1.155 }, t: .25,
      line: 'Regular hexagons. A 4-3 board is a piece of honeycomb: it tessellates exactly.',
      good: ['The offset rows stop looking like a compromise; they are what a honeycomb is.', 'The back row tucks in by a quarter: at the same unit width, the board is about a quarter shorter.', 'Fits a woodland theme (bees, cells, combs).'],
      bad: ['Each hex is wider than a card, so in a wide zone it runs out of width first and the units come out smaller. It pays off in a zone that is narrower and shorter.', 'In the left-right layout the hexes turn on their side, so the units are wider than tall.'],
      vary: ['Rounded hex corners for a softer look.', 'Honeycomb for the board only, plain cards in the market and hand.'] },
    { id: 'lozenge', name: 'Near-diamond', a: { bu: .78, lr: .78 }, t: .36,
      line: 'A deep point at each end, short straight sides: nearly a diamond.',
      good: ['Tucks deep: the board becomes a lattice, about a fifth shorter.', 'Very distinctive silhouette for the whole board.'],
      bad: ['Crops the most art, top and bottom.', 'Least room for numbers; tier and stats crowd the slants.'],
      vary: ['A true diamond for the empty slots only, as a board pattern.', 'Deep points toward the enemy, shallow toward the back.'] },
    { id: 'shield', name: 'Shield wall', a: { bu: .75, lr: .75 }, t: .18, split: true,
      line: 'Front row: shields, flat toward the enemy and pointed behind. Back row: pointed forward into the gaps.',
      good: ['Front and back rows look different, so you can tell which row is which at a glance.', 'Flat faces meet flat faces in a fight: a wall against a wall.', 'The back row tucks in like the tall hex.'],
      bad: ['Two shapes to draw and frame for every unit.', 'A unit changes shape when it moves between rows.'],
      vary: ['Only the front row changes shape; the back row stays plain.', 'Use the shield for a "guard" keyword instead of for the row.'] },
    { id: 'weave', name: 'Woven', a: { bu: .75, lr: .75 }, t: 0, weave: .14,
      line: 'Slanted cards: the front row leans one way, the back row the other, like a basket weave.',
      good: ['A lively, woven look; the chevrons pull the eye along the board.', 'Rows read as distinct without changing size.'],
      bad: ['Leaning pictures can feel unstable.', 'Doesn\'t tuck: same height as the plain card.'],
      vary: ['Lean only the empty slots, as a woven mat under upright cards.', 'A gentler slant, enough to suggest the weave.'] },
  ];
  // The owner's picks lead (11 Nov): honeycomb, the in-between hex, the tall hex.
  const ORDER = ['honey', 'midhex', 'longhex', 'card', 'chamfer', 'lozenge', 'shield', 'weave'];
  SHAPES.sort((x, y) => ORDER.indexOf(x.id) - ORDER.indexOf(y.id));
  const byId = Object.fromEntries(SHAPES.map((s) => [s.id, s]));

  // Placing the picture. Portraits are square and the face sits about 30% down.
  // Scale to cover the whole unit (never stretched), zoom in a touch on hexes, then
  // pan so the face lands in the hex's wide middle band, clear of the top point.
  // The bottom crops first: that is the body, where the numbers sit anyway.
  const FACE = 0.30;
  function art(sh, lay, W, H) {
    // A unit wider than tall (the honeycomb on its side) already crops top and
    // bottom: no zoom, and keep the top edge so heads and hats stay whole.
    const wide = W > H, pointy = sh.t && lay === 'bu';
    const zoom = sh.round || wide ? 1 : pointy ? 1.1 : 1.04;
    const side = Math.max(W, H) * zoom;
    const target = pointy ? Math.max(0.36, sh.t + 0.14) : 0.34;
    const y = wide ? 0 : Math.min(0, Math.max(H - side, target * H - FACE * side));
    return { x: (W - side) / 2, y, side };
  }

  function poly(sh, row) {
    if (sh.weave) { const s = sh.weave; return row === 'f' ? [[s, 0], [1, 0], [1 - s, 1], [0, 1]] : [[0, 0], [1 - s, 0], [1, 1], [s, 1]]; }
    if (sh.split) { const t = sh.t; return row === 'f' ? [[0, 0], [1, 0], [1, 1 - t], [.5, 1], [0, 1 - t]] : [[.5, 0], [1, t], [1, 1], [0, 1], [0, t]]; }
    if (sh.t) return hex(sh.t);
    return null; // card and cut corners are drawn in screen space
  }
  // Unit frame -> screen box. lay: bu or lr. foe flips the side that faces the enemy.
  function toScreen(pts, W, H, lay, foe) {
    return pts.map(([x, y]) => lay === 'bu' ? [x * W, (foe ? 1 - y : y) * H] : [(foe ? y : 1 - y) * W, x * H]);
  }
  function screenPoly(sh, row, W, H, lay, foe) {
    if (sh.chamfer) { const c = sh.chamfer * Math.min(W, H); return [[c, 0], [W - c, 0], [W, c], [W, H - c], [W - c, H], [c, H], [0, H - c], [0, c]]; }
    const p = poly(sh, row);
    return p ? toScreen(p, W, H, lay, foe) : null;
  }
  const area = (pts) => Math.abs(pts.reduce((s, [x, y], i) => { const [x2, y2] = pts[(i + 1) % pts.length]; return s + x * y2 - x2 * y; }, 0) / 2);
  const pathD = (pts) => 'M' + pts.map((p) => p.map((v) => v.toFixed(1)).join(' ')).join(' L') + ' Z';
  const roundD = (W, H, r) => `M${r} 0 H${W - r} A${r} ${r} 0 0 1 ${W} ${r} V${H - r} A${r} ${r} 0 0 1 ${W - r} ${H} H${r} A${r} ${r} 0 0 1 0 ${H - r} V${r} A${r} ${r} 0 0 1 ${r} 0 Z`;
  // Where a horizontal line at height y crosses the shape: [left, right].
  function span(pts, W, y) {
    if (!pts) return [0, W];
    const xs = [];
    pts.forEach(([x1, y1], i) => { const [x2, y2] = pts[(i + 1) % pts.length]; if ((y1 - y) * (y2 - y) <= 0 && y1 !== y2) xs.push(x1 + (x2 - x1) * (y - y1) / (y2 - y1)); });
    return xs.length ? [Math.min(...xs), Math.max(...xs)] : [0, W];
  }

  // Fit the brick into a zone: the biggest unit size whose 4-3 board fits.
  function fit(sh, lay, Zw, Zh) {
    const a = sh.a[lay], q = lay === 'bu' ? 1 / a : a; // across / along
    const alongMax = lay === 'bu' ? Zw : Zh, acrossMax = lay === 'bu' ? Zh : Zw;
    let d = GAP;
    if (sh.t) { const th = Math.atan(2 * sh.t * q); d = (GAP - (GAP / 2) * Math.sin(th)) / Math.cos(th); }
    const along = Math.min((alongMax - 3 * GAP) / 4, (acrossMax - d) / ((2 - sh.t) * q));
    const across = along * q;
    const step = across * (1 - sh.t) + d;
    const W = lay === 'bu' ? along : across, H = lay === 'bu' ? across : along;
    return { along, across, step, W, H, a0: (alongMax - (4 * along + 3 * GAP)) / 2, c0: (acrossMax - (across + step)) / 2 };
  }
  function unitArea(sh, lay, f) {
    if (sh.round) return f.W * f.H - (4 - Math.PI) * Math.pow(Math.min(f.W, f.H) * .09, 2);
    return area(screenPoly(sh, 'f', f.W, f.H, lay, false));
  }

  let clipN = 0;
  function unit(u, sh, row, lay, foe, f, x, y) {
    const { W, H } = f;
    const pts = sh.round ? null : screenPoly(sh, row, W, H, lay, foe);
    const d = sh.round ? roundD(W, H, Math.min(W, H) * .09) : pathD(pts);
    const id = 'c' + clipN++;
    const pos = `left:${x.toFixed(1)}px;top:${y.toFixed(1)}px;width:${W.toFixed(1)}px;height:${H.toFixed(1)}px`;
    if (!u) return `<div class="u empty" style="${pos}"><svg viewBox="0 0 ${W} ${H}"><path d="${d}" class="dash"/></svg></div>`;
    const b = Math.max(30, Math.min(54, Math.min(W, H) * .3));
    const im = art(sh, lay, W, H);
    const yl = H * .84, [l, r] = span(pts, W, yl), [tl] = span(pts, W, H * .14);
    return `<div class="u ${u.golden ? 'golden' : ''}" style="${pos};--b:${b.toFixed(0)}px">
      <svg viewBox="0 0 ${W} ${H}"><defs><clipPath id="${id}"><path d="${d}"/></clipPath></defs>
        <image href="${J.por(u.id)}" x="${im.x.toFixed(1)}" y="${im.y.toFixed(1)}" width="${im.side.toFixed(1)}" height="${im.side.toFixed(1)}" preserveAspectRatio="none" clip-path="url(#${id})"/>
        <path d="${d}" class="edge"/></svg>
      <span class="tier" style="left:${(tl + b * .42).toFixed(0)}px;top:${(H * .14).toFixed(0)}px">${u.tier}</span>
      <span class="atk" style="left:${(l + b * .3).toFixed(0)}px;top:${yl.toFixed(0)}px">${u.atk}</span>
      <span class="hp" style="left:${(r - b * .3).toFixed(0)}px;top:${yl.toFixed(0)}px">${u.hp}</span>
    </div>`;
  }
  // One board in a zone. Front row faces the enemy: up (bu, yours), down (bu, foe),
  // right (lr, yours) or left (lr, foe).
  function board(slots, sh, lay, foe, Zw, Zh) {
    const f = fit(sh, lay, Zw, Zh);
    const cells = [];
    const place = (k, along, across, row) => {
      let x, y;
      if (lay === 'bu') { x = along; y = foe ? Zh - across - f.across : across; } else { y = along; x = foe ? across : Zw - across - f.across; }
      cells.push(unit(slots[k], sh, row, lay, foe, f, x, y));
    };
    for (let k = 0; k < 4; k++) place(k, f.a0 + k * (f.along + GAP), f.c0, 'f');
    for (let k = 0; k < 3; k++) place(4 + k, f.a0 + (f.along + GAP) / 2 + k * (f.along + GAP), f.c0 + f.step, 'b');
    return cells.join('');
  }

  const ZONE = { bu: [830, 492], lr: [430, 1000] };
  const PAD = 24;
  function zone(slots, sh, lay, foe, x, y) {
    const [w, h] = ZONE[lay];
    return `<section class="zone ${foe ? 'foe' : 'me'}" style="left:${x}px;top:${y}px;width:${w}px;height:${h}px">
      <div class="inner" style="left:${PAD}px;top:${PAD}px;width:${w - 2 * PAD}px;height:${h - 2 * PAD}px">${board(slots, sh, lay, foe, w - 2 * PAD, h - 2 * PAD)}</div>
      <b class="ztag">${foe ? 'OPPONENT' : 'YOUR BAND'}</b></section>`;
  }
  // How deep the two rows are (height in bottom-up, width in left-right) when the
  // units are as wide as today's cards: the space a shape saves where space is short.
  function depth(sh, lay, along) {
    const a = sh.a[lay], q = lay === 'bu' ? 1 / a : a, across = along * q;
    let d = GAP;
    if (sh.t) { const th = Math.atan(2 * sh.t * q); d = (GAP - (GAP / 2) * Math.sin(th)) / Math.cos(th); }
    return across * (2 - sh.t) + d;
  }
  function size(sh, lay) {
    const [w, h] = ZONE[lay];
    const f = fit(sh, lay, w - 2 * PAD, h - 2 * PAD), base = fit(byId.card, lay, w - 2 * PAD, h - 2 * PAD);
    return { pct: Math.round(100 * unitArea(sh, lay, f) / unitArea(byId.card, lay, base)), keep: Math.round(100 * unitArea(sh, lay, f) / (f.W * f.H)),
      deep: Math.round(100 * depth(sh, lay, base.along) / depth(byId.card, lay, base.along)), W: Math.round(f.W), H: Math.round(f.H) };
  }

  function controls() {
    const seg = (key, opts) => `<div class="seg">${opts.map(([v, t]) => `<button data-${key}="${v}" class="${S[key] === v ? 'on' : ''}">${t}</button>`).join('')}</div>`;
    return `<header class="top"><a class="back" href="../index.html">Lab ↩</a><h1>Slot shapes</h1><span class="sub">Same 4-3 board, same zone size, different unit shapes</span>
      ${seg('lay', [['bu', 'Bottom-up'], ['lr', 'Left-right']])}${seg('view', [['one', 'One shape, in a fight'], ['all', 'All shapes']])}</header>`;
  }
  function list() {
    return `<nav class="list">${SHAPES.map((s, i) => { const z = size(s, S.lay); return `${i === 0 ? '<h4>Your picks</h4>' : s.id === 'card' ? '<h4>Others</h4>' : ''}<button data-shape="${s.id}" class="${S.shape === s.id ? 'on' : ''}"><b>${s.name}${s.tag ? ` <i>${s.tag}</i>` : ''}${s.pick ? ' <i>pick</i>' : ''}</b><span>Units ${z.pct}% size · board ${z.deep}% ${S.lay === 'bu' ? 'height' : 'width'}</span></button>`; }).join('')}</nav>`;
  }
  function notes(sh) {
    const z = size(sh, S.lay);
    return `<aside class="notes"><h2>${sh.name}</h2><p class="line">${sh.line}</p>
      <div class="stats"><div><b>${z.pct}%</b><span>unit size vs today's card, in the same zone</span></div><div><b>${z.deep}%</b><span>board ${S.lay === 'bu' ? 'height' : 'width'} vs today's, with units as ${S.lay === 'bu' ? 'wide' : 'tall'} as today's cards</span></div><div><b>${z.keep}%</b><span>of the picture's box still shows</span></div></div>
      <h3>Good</h3><ul>${sh.good.map((x) => `<li>${x}</li>`).join('')}</ul>
      <h3>Watch for</h3><ul>${sh.bad.map((x) => `<li>${x}</li>`).join('')}</ul>
      <h3>Variations</h3><ul>${sh.vary.map((x) => `<li>${x}</li>`).join('')}</ul></aside>`;
  }

  function render() {
    clipN = 0;
    const sh = byId[S.shape];
    let body = '';
    if (S.view === 'one') {
      if (S.lay === 'bu') body = zone(G.enemy, sh, 'bu', true, 380, 64) + zone(G.board, sh, 'bu', false, 380, 64 + 492 + 16);
      else body = zone(G.board, sh, 'lr', false, 380, 64) + zone(G.enemy, sh, 'lr', true, 380 + 430 + 16, 64);
      body = list() + body + notes(sh);
    } else {
      const k = S.lay === 'bu' ? .5 : .42, [w, h] = ZONE[S.lay];
      body = `<div class="grid ${S.lay}">${SHAPES.map((s) => { const z = size(s, S.lay); return `<button class="cell ${S.shape === s.id ? 'on' : ''}" data-shape="${s.id}" data-goto="one" style="width:${w * k}px">
        <div style="width:${w * k}px;height:${h * k}px;overflow:hidden"><div class="mini" style="width:${w}px;height:${h}px;transform:scale(${k})">${zone(G.board, s, S.lay, false, 0, 0)}</div></div>
        <b>${s.name}</b><span>${z.pct}% size · ${z.deep}% board ${S.lay === 'bu' ? 'height' : 'width'} · ${z.keep}% of picture</span></button>`; }).join('')}</div>`;
    }
    document.documentElement.dataset.lay = S.lay;
    stage.innerHTML = controls() + body;
    history.replaceState(null, '', `?shape=${S.shape}&lay=${S.lay}&view=${S.view}${J.static ? '&static' : ''}`);
  }

  stage.addEventListener('click', (e) => {
    const b = e.target.closest('button'); if (!b) return;
    ['shape', 'lay', 'view'].forEach((k) => { if (b.dataset[k]) S[k] = b.dataset[k]; });
    if (b.dataset.goto) S.view = b.dataset.goto;
    render();
  });

  J.mountWorld({ ferns: false });
  J.fit(stage);
  J.setArea(1, 'instant');
  render();
})();
