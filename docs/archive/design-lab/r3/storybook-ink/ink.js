// Storybook Ink: shared builders for cards, boards, icons. Data comes from data.js (a copy of ../../fixture.json).
(function () {
  const ART = '../../../folio/art/web/trials/ink-b-';
  // Stand-in portraits: only six Ink B trials exist, so units borrow the nearest one.
  const PORTRAIT = {
    'Belladonna Sprite': 'fairy-hollowdeep', 'Hornet Scout': 'fairy-hollowdeep', 'Hornetling': 'fairy-hollowdeep',
    'Drumming Woodpecker': 'squirrel-mosswood', 'Lesser Spotted Woodpecker': 'squirrel-mosswood', 'Robin Redbreast': 'squirrel-mosswood',
    'Hedge Doctor': 'dormouse-beechhold', 'Feeder Vole': 'dormouse-beechhold',
    'Mudwallow Toad': 'otter-reedmouth', 'Garden Snail': 'ooze-moorbog',
    'Bear Cub': 'marmot-highcrown', 'Tusker Boar': 'marmot-highcrown', 'Sett Warden': 'otter-reedmouth'
  };
  const TRIBE = {
    'Fairies': 'heather', 'Birds': 'sky', 'Hedgerow folk': 'moss', 'Bog folk': 'peat', 'Great beasts': 'rust',
    'Hunters': 'pine', 'Hive': 'mustard', 'Neutral': 'stone'
  };
  const NOCHIP = ['Start of Combat', 'Nightshade'];
  const KW = ['Start of Combat', 'Nightshade', 'Peck', 'Curl', 'Mire', 'Shell', 'Shoulder', 'Hunker', 'Rival'];

  const ICON = {
    coin: '<svg viewBox="0 0 32 32"><path d="M16.00 1.40L17.62 2.70L19.49 1.82L20.75 3.47L22.78 3.07L23.61 4.97L25.68 5.07L26.03 7.11L28.02 7.71L27.87 9.77L29.65 10.82L29.01 12.79L30.49 14.24L29.40 16.00L30.49 17.76L29.01 19.21L29.65 21.18L27.87 22.23L28.02 24.29L26.03 24.89L25.68 26.93L23.61 27.03L22.78 28.93L20.75 28.53L19.49 30.18L17.62 29.30L16.00 30.60L14.38 29.30L12.51 30.18L11.25 28.53L9.22 28.93L8.39 27.03L6.32 26.93L5.97 24.89L3.98 24.29L4.13 22.23L2.35 21.18L2.99 19.21L1.51 17.76L2.60 16.00L1.51 14.24L2.99 12.79L2.35 10.82L4.13 9.77L3.98 7.71L5.97 7.11L6.32 5.07L8.39 4.97L9.22 3.07L11.25 3.47L12.51 1.82L14.38 2.70Z" fill="var(--gilt)" stroke="var(--ink)" stroke-width="2" stroke-linejoin="round"/><path d="M26.2 9.8A11.4 11.4 0 0 1 9.6 26.6 10.6 10.6 0 0 0 26.2 9.8z" fill="var(--gilt-cel)"/><circle cx="16" cy="16" r="10.2" fill="none" stroke="var(--ink)" stroke-width="1.6"/></svg>',
    heart: '<svg viewBox="0 0 32 32"><path d="M16 28.5C6.5 21.6 3 16 3 11.2 3 7 6.1 4 9.8 4c2.8 0 4.8 1.6 6.2 3.8C17.4 5.6 19.4 4 22.2 4 25.9 4 29 7 29 11.2c0 4.8-3.5 10.4-13 17.3z" fill="var(--berry)"/><path class="cel" d="M26.6 6.8C28.3 9.6 28 13.4 25.5 17.6 23 21.6 19.8 24.8 16 27.6 21 22 24.6 15.6 26.6 6.8z" fill="#86261F"/><path d="M16 28.5C6.5 21.6 3 16 3 11.2 3 7 6.1 4 9.8 4c2.8 0 4.8 1.6 6.2 3.8C17.4 5.6 19.4 4 22.2 4 25.9 4 29 7 29 11.2c0 4.8-3.5 10.4-13 17.3z" fill="none" stroke="var(--ink)" stroke-width="2.6" stroke-linejoin="round"/></svg>',
    atkbadge: '<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13.6" fill="var(--mustard)"/><path d="M27.4 10.6A13.6 13.6 0 0 1 8 27.2 12 12 0 0 0 27.4 10.6z" fill="#A9731A"/><circle cx="16" cy="16" r="13.6" fill="none" stroke="var(--ink)" stroke-width="2.6"/></svg>',
    attack: '<svg viewBox="0 0 32 32"><path d="M16 2.5l5.6 13.2L16 29.5l-5.6-13.8z" fill="var(--mustard)" stroke="var(--ink)" stroke-width="2.6" stroke-linejoin="round"/><path d="M16 6v19" stroke="var(--ink)" stroke-width="1.4"/></svg>',
    tier: '<svg viewBox="0 0 32 32"><path d="M16 1.8l4.2 8.6 9.4 1.2-6.9 6.5 1.8 9.3L16 22.8l-8.5 4.6 1.8-9.3-6.9-6.5 9.4-1.2z" fill="var(--ink)" stroke="var(--ink)" stroke-width="2.2" stroke-linejoin="round"/><path d="M16 6.2l2.9 6 6.5.8-4.8 4.5 1.3 6.4L16 20.7" fill="none" stroke="var(--inksoft)" stroke-width="1.2" stroke-linejoin="round"/></svg>',
    refresh: '<svg viewBox="0 0 32 32"><path d="M25.5 12.5A10 10 0 0 0 7.2 10.8M6.5 19.5a10 10 0 0 0 18.3 1.7" fill="none" stroke="var(--ink)" stroke-width="3" stroke-linecap="round"/><path d="M5 5.5l1.8 6.3 6.3-1.7M27 26.5l-1.8-6.3-6.3 1.7" fill="none" stroke="var(--ink)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    freeze: '<svg viewBox="0 0 32 32"><g stroke="var(--ink)" stroke-width="2.8" stroke-linecap="round" fill="none"><path d="M16 3v26M4.7 9.5l22.6 13M4.7 22.5l22.6-13"/><path d="M12.5 5.5L16 8.5l3.5-3M12.5 26.5L16 23.5l3.5 3M5 14l4.2-.8-1-4.4M27 18l-4.2.8 1 4.4M8.2 23.4l1-4.4L5 18M23.8 8.6l-1 4.4 4.2.8"/></g></svg>',
    swords: '<svg viewBox="0 0 32 32"><g stroke="var(--ink)" stroke-width="2.8" stroke-linecap="round"><path d="M6 6l17 17M26 6L9 23"/><path d="M20 26l6-6M6 20l6 6"/></g></svg>',
    lock: '<svg viewBox="0 0 32 32"><rect x="7" y="14" width="18" height="14" rx="3" fill="var(--sky)" stroke="var(--ink)" stroke-width="2.6"/><path d="M11 14v-3.5a5 5 0 0 1 10 0V14" fill="none" stroke="var(--ink)" stroke-width="2.6"/></svg>',
    berry: '<svg viewBox="0 0 32 32"><path d="M16 4c-1 3-3 4.5-6 5 3 .8 5 .5 6-1 1 1.5 3 1.8 6 1-3-.5-5-2-6-5z" fill="var(--moss)" stroke="var(--ink)" stroke-width="2" stroke-linejoin="round"/><circle cx="16" cy="19" r="9" fill="var(--heather)" stroke="var(--ink)" stroke-width="2.6"/><circle cx="13" cy="16.5" r="2" fill="var(--card)"/></svg>',
    hand: '<svg viewBox="0 0 32 32"><rect x="5" y="7" width="13" height="19" rx="2.5" transform="rotate(-12 11 16)" fill="var(--card)" stroke="var(--ink)" stroke-width="2.4"/><rect x="14" y="6" width="13" height="19" rx="2.5" transform="rotate(8 20 15)" fill="var(--card)" stroke="var(--ink)" stroke-width="2.4"/></svg>'
  };

  function text(t) {
    let s = t.replace(/&/g, '&amp;').replace(/</g, '&lt;');
    for (const k of KW) s = s.replace(new RegExp('\\b' + k + '\\b', 'g'), m => `<b class="kw${k === 'Nightshade' ? ' ns' : ''}">${m}</b>`);
    return s;
  }
  // Keyword chips for small cards: the keyword words that appear in the unit's own text.
  function chips(t) {
    const found = [];
    for (const k of KW) { if (NOCHIP.includes(k)) continue; const m = t.match(new RegExp('\\b' + k + '(?: \\d+)?\\b')); if (m) found.push(m[0]); }
    return found.slice(0, 2);
  }
  function stat(kind, v, extra = '') {
    return `<div class="stat ${kind} ${extra}">${kind === 'atk' ? ICON.atkbadge : ICON.heart}<span>${v}</span></div>`;
  }
  // size: full | shop | board
  function card(u, size, o = {}) {
    const tribe = TRIBE[u.tribe] || 'stone';
    const cls = ['card', 's-' + size, 't-' + tribe, u.golden ? 'golden' : '', u.frozen ? 'frozen' : '', o.cls || ''].join(' ');
    const img = PORTRAIT[u.name] ? `<img src="${ART + PORTRAIT[u.name]}.jpg" alt="">` : '';
    const hp = o.hp !== undefined ? o.hp : u.health;
    const statuses = (u.status || []).map(s => `<span class="status ${s === 'Nightshade' ? 'ns' : ''}">${s === 'Nightshade' ? ICON.berry : ''}${s}</span>`).join('');
    const chipHtml = (o.chips || chips(u.text || '')).map(c => `<span class="chip${c === 'Nightshade' ? ' ns' : ''}${c === o.open ? ' open' : ''}">${c}</span>`).join('');
    const tierB = u.tier ? `<div class="c-tier">${ICON.tier}<span>${u.tier}</span></div>` : '';
    let body = '';
    if (size === 'full') {
      body = `<div class="c-type"><span>${u.type_line || ''}</span><span class="tribe">${u.tribe}</span></div>
        <div class="c-text"><p>${text(u.text)}</p>${u.keyword_reminder ? `<p class="remind">${text(u.keyword_reminder)}</p>` : ''}</div>`;
    } else if (size === 'shop') {
      body = `<div class="c-text"><p class="long">${text(u.text || '')}</p><p class="short">${chipHtml}</p></div><div class="c-tribe">${u.tribe}</div>`;
    } else {
      body = `<div class="c-chips">${chipHtml}</div>`;
    }
    return `<div class="${cls}" ${o.id ? `id="${o.id}"` : ''}>
      ${u.frozen ? `<div class="frost"></div><div class="frost-tag">${ICON.freeze}Frozen</div>` : ''}
      ${u.golden ? '<div class="gold-tag">Golden</div>' : ''}
      <div class="c-art">${img}${statuses ? `<div class="c-status">${statuses}</div>` : ''}</div>
      ${tierB}
      <div class="c-name"><span>${u.name}</span></div>
      ${body}
      ${stat('atk', u.attack)}${stat('hp', hp, o.hpcls || '')}
    </div>`;
  }
  // Which front slots each back slot sits behind (the 4-3 brick).
  const BEHIND = { B1: 'F1 & F2', B2: 'F2 & F3', B3: 'F3 & F4' };
  function empty(slot) { return `<div class="slot empty"><span class="sl">${slot}</span><span class="e">empty</span>${BEHIND[slot] ? `<span class="bh">behind <span style="white-space:nowrap">${BEHIND[slot]}</span></span>` : ''}</div>`; }
  function slot(u, size, o) {
    if (u.empty) return empty(u.slot);
    const lab = BEHIND[u.slot] ? `${u.slot} <i>behind ${BEHIND[u.slot]}</i>` : u.slot;
    return `<div class="slot"><span class="sl">${lab}</span>${card(u, size, o && o[u.slot])}</div>`;
  }
  // b = {front:[4], back:[3]} with slot ids. order: 'front-first' (front on top) or 'back-first' (enemy: back on top)
  function board(b, size, o = {}) {
    const front = `<div class="row front"><div class="rowtag">Front<small>faces the fight</small></div>${b.front.map(u => slot(u, size, o.per)).join('')}</div>`;
    const back = `<div class="row back"><div class="rowtag">Back<small>each behind two</small></div>${b.back.map(u => slot(u, size, o.per)).join('')}</div>`;
    return `<div class="board ${o.cls || ''}"><svg class="tray"></svg>${o.order === 'back-first' ? back + front : front + back}</div>`;
  }

  // ---- the signature: one tray cut to the brick, ringed by an inked bramble stem ----
  const NS = 'http://www.w3.org/2000/svg';
  function el(tag, attrs, parent) { const e = document.createElementNS(NS, tag); for (const k in attrs) e.setAttribute(k, attrs[k]); if (parent) parent.appendChild(e); return e; }
  // Rounded path through a closed polygon (handles inner corners too).
  function rounded(pts, r) {
    let d = '';
    for (let i = 0; i < pts.length; i++) {
      const p0 = pts[(i - 1 + pts.length) % pts.length], p1 = pts[i], p2 = pts[(i + 1) % pts.length];
      const l1 = Math.hypot(p1[0] - p0[0], p1[1] - p0[1]), l2 = Math.hypot(p2[0] - p1[0], p2[1] - p1[1]);
      const rr = Math.min(r, l1 / 2, l2 / 2);
      const a = [p1[0] + (p0[0] - p1[0]) * rr / l1, p1[1] + (p0[1] - p1[1]) * rr / l1];
      const c = [p1[0] + (p2[0] - p1[0]) * rr / l2, p1[1] + (p2[1] - p1[1]) * rr / l2];
      d += (i ? 'L' : 'M') + a[0].toFixed(1) + ' ' + a[1].toFixed(1) + 'Q' + p1[0] + ' ' + p1[1] + ' ' + c[0].toFixed(1) + ' ' + c[1].toFixed(1);
    }
    return d + 'Z';
  }
  function brick(F, K, d) {
    // F: front row box, K: back row box (front on top). Grow outward by d.
    const mid = F.b + (K.t - F.b) / 2;
    return [[F.l - d, F.t - d], [F.r + d, F.t - d], [F.r + d, mid + d], [K.r + d, mid + d], [K.r + d, K.b + d], [K.l - d, K.b + d], [K.l - d, mid + d], [F.l - d, mid + d]];
  }
  const LEAF = 'M0 0C3-4.5 9-5.5 13-3.6 15.5-2.2 17-.8 18 0 17 .8 15.5 2.2 13 3.6 9 5.5 3 4.5 0 0Z';
  function leaf(g, x, y, ang, k) {
    const t = el('g', { transform: `translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${ang.toFixed(0)}) scale(${k})` }, g);
    el('path', { d: 'M0 0L6 0', stroke: 'var(--ink)', 'stroke-width': 1.8, 'stroke-linecap': 'round' }, t);
    for (const [a, s] of [[-38, .72], [0, 1], [38, .72]]) {
      const lf = el('g', { transform: `translate(6 0) rotate(${a}) scale(${s})` }, t);
      el('path', { d: LEAF, fill: 'var(--moss)', stroke: 'var(--ink)', 'stroke-width': 1.7 / s, 'stroke-linejoin': 'round' }, lf);
      el('path', { d: 'M2 0L14 0', stroke: 'var(--ink)', 'stroke-width': 1.1 / s, 'stroke-linecap': 'round' }, lf);
    }
  }
  function berries(g, x, y, k, ripe) {
    const t = el('g', { transform: `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${k})` }, g);
    const dots = [[0, 0], [5, -1], [2.5, 4], [-2.5, 4], [-4.5, -1], [0, -4.5], [5, 4.6]];
    for (const [i, [dx, dy]] of dots.entries()) el('circle', { cx: dx, cy: dy, r: 3.1, fill: ripe ? 'var(--bramble)' : 'var(--berry)', stroke: 'var(--ink)', 'stroke-width': 1.3 }, t);
    el('circle', { cx: -1, cy: -1.2, r: .9, fill: 'var(--card)' }, t);
  }
  function flower(g, x, y, k) {
    const t = el('g', { transform: `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${k})` }, g);
    for (let i = 0; i < 5; i++) el('ellipse', { cx: 0, cy: -4.6, rx: 3.4, ry: 4.4, transform: `rotate(${i * 72})`, fill: 'var(--card)', stroke: 'var(--ink)', 'stroke-width': 1.3 }, t);
    el('circle', { cx: 0, cy: 0, r: 2.3, fill: 'var(--gilt)', stroke: 'var(--ink)', 'stroke-width': 1.1 }, t);
  }
  // Draw an inked bramble along any closed or open path. k scales the props (1 = desktop).
  function vine(svg, d, k = 1, o = {}) {
    const g = el('g', { class: 'vine' }, svg);
    const guide = el('path', { d, fill: 'none', stroke: 'none' }, g);
    const L = guide.getTotalLength(), step = 3, lam = 100 * k, amp = 3.6 * k;
    const P = [];
    for (let s = 0; s <= L; s += step) {
      const p = guide.getPointAtLength(s), q = guide.getPointAtLength(Math.min(L, s + 1));
      let tx = q.x - p.x, ty = q.y - p.y; const tl = Math.hypot(tx, ty) || 1; tx /= tl; ty /= tl;
      const nx = ty, ny = -tx, w = Math.sin(s / lam * Math.PI * 2) * amp;
      P.push({ x: p.x + nx * w, y: p.y + ny * w, nx, ny, tx, ty, s });
    }
    el('path', { d: 'M' + P.map(p => p.x.toFixed(1) + ' ' + p.y.toFixed(1)).join('L'), fill: 'none', stroke: 'var(--ink)', 'stroke-width': 2.8 * k, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, g);
    // thorns: little hooked triangles, alternating sides
    const thorns = el('g', { fill: 'var(--ink)' }, g);
    P.forEach((p, i) => { if (i % Math.round(9 * k + 4) !== 3) return; const side = (i / Math.round(9 * k + 4)) % 2 ? 1 : -1;
      const bx = p.x, by = p.y, h = 5.2 * k, b = 2.2 * k;
      el('path', { d: `M${bx - p.tx * b} ${by - p.ty * b}L${bx + p.nx * h * side + p.tx * h * .6} ${by + p.ny * h * side + p.ty * h * .6}L${bx + p.tx * b} ${by + p.ty * b}Z` }, thorns); });
    // leaves, berries and a few flowers at the wave's outer peaks
    const props = el('g', {}, g);
    let n = 0;
    P.forEach((p, i) => {
      const ph = (p.s / lam) % 1, tol = step / lam / 2 + 1e-6;
      const peak = Math.abs(ph - .25) <= tol, trough = Math.abs(ph - .75) <= tol;
      if (!peak && !trough) return;
      if (o.skip && o.skip(p)) return;
      if (trough) { leaf(props, p.x, p.y, Math.atan2(p.ny, p.nx) * 180 / Math.PI + (n % 2 ? 55 : -55), k * .7); return; }
      n++;
      const ang = Math.atan2(p.ny, p.nx) * 180 / Math.PI + (n % 2 ? -30 : 30);
      if (n % 5 === 2) berries(props, p.x + p.nx * 7 * k, p.y + p.ny * 7 * k, k, n % 10 !== 2);
      else if (n % 7 === 4) flower(props, p.x + p.nx * 6 * k, p.y + p.ny * 6 * k, k);
      else leaf(props, p.x, p.y, ang, k);
    });
    return g;
  }
  function rectOf(e, B) { const r = e.getBoundingClientRect(); return { l: r.left - B.left, t: r.top - B.top, r: r.right - B.left, b: r.bottom - B.top }; }
  function drawTray(b) {
    const svg = b.querySelector('svg.tray'); if (!svg) return;
    svg.innerHTML = '';
    const B = b.getBoundingClientRect();
    svg.setAttribute('width', B.width); svg.setAttribute('height', B.height);
    const cs = getComputedStyle(b), k = parseFloat(cs.getPropertyValue('--vk')) || 1, rad = parseFloat(cs.getPropertyValue('--tr')) || 26;
    let F = rectOf(b.querySelector('.row.front'), B), K = rectOf(b.querySelector('.row.back'), B);
    const flip = F.t > K.t; // enemy boards: back on top
    if (flip) { const m = (F.t + K.b) ; [F, K] = [{ l: F.l, r: F.r, t: m - F.b, b: m - F.t }, { l: K.l, r: K.r, t: m - K.b, b: m - K.t }]; }
    const tr = flip ? `matrix(1 0 0 -1 0 ${F.t + K.b})` : '';
    const g = el('g', tr ? { transform: tr } : {}, svg);
    const shape = rounded(brick(F, K, 0), rad);
    el('path', { d: shape, fill: 'var(--ink)', transform: `translate(0 ${6 * k})` }, g);
    el('path', { d: shape, fill: 'var(--tray, var(--shade))', stroke: 'var(--ink)', 'stroke-width': 3 * Math.max(k, .8), 'stroke-linejoin': 'round' }, g);
    // the back step: one shade darker so the half-slot offset reads at a glance
    const mid = F.b + (K.t - F.b) / 2;
    el('path', { d: rounded([[K.l, mid], [K.r, mid], [K.r, K.b], [K.l, K.b]], rad - 4), fill: 'var(--tray-step, #D3BC92)' }, g);
    el('path', { d: `M${K.l + 14} ${mid}H${K.r - 14}`, stroke: 'var(--ink)', 'stroke-width': 2 * k, 'stroke-dasharray': `${2 * k} ${7 * k}`, 'stroke-linecap': 'round' }, g);
    el('path', { d: rounded(brick(F, K, 0), rad), fill: 'none', stroke: 'var(--ink)', 'stroke-width': 3 * Math.max(k, .8), 'stroke-linejoin': 'round' }, g);
    vine(g, rounded(brick(F, K, 6 * k), rad + 5 * k), k, { skip: p => p.nx < -.5 });
  }
  // Round 3: redraw on resize, and tell the page when the trays are drawn (combat draws its arrow then).
  function drawTrays() { document.querySelectorAll('.board').forEach(drawTray); document.dispatchEvent(new Event('ink:trays')); }
  window.addEventListener('load', drawTrays);
  window.addEventListener('resize', drawTrays);
  if (document.fonts) document.fonts.ready.then(drawTrays);

  function lobby(list, o = {}) {
    return list.map((p, i) => `<li class="${p.name === 'You' ? 'you' : ''} ${p.next_opponent ? 'next' : ''} ${p.eliminated ? 'out' : ''}">
      <span class="rk">${p.eliminated ? '' : i + 1}</span>
      <span class="nm">${p.name}${p.next_opponent ? '<em class="nx">' + ICON.swords + '</em>' : ''}</span>
      <span class="tr" title="Tier">${ICON.tier}<b>${p.tier}</b></span>
      <span class="hp">${ICON.heart}<b>${p.health}</b></span>
      ${o.last ? `<span class="last ${p.last}">${p.eliminated ? 'out' : p.last}</span>` : ''}
    </li>`).join('');
  }
  window.INK = { ICON, card, board, empty, lobby, text, PORTRAIT, ART, vine, rounded, drawTrays, el };
})();
