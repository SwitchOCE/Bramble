// Hedgerow Woodcraft: shared helpers (icons, tiles, the brick tray, stage fit).
(function () {
  const W = (window.WC = {});
  const INK = '#2B1A0F';
  const ART = '../../../folio/art/web/trials/ink-b-';
  // Only six Ink B portraits exist: each unit borrows the nearest one.
  const P = {
    fairy: 'fairy-hollowdeep', squirrel: 'squirrel-mosswood', dormouse: 'dormouse-beechhold',
    marmot: 'marmot-highcrown', otter: 'otter-reedmouth', ooze: 'ooze-moorbog'
  };
  const MAP = {
    'Belladonna Sprite': 'fairy', 'Hornet Scout': 'fairy', 'Hornetling': 'fairy',
    'Drumming Woodpecker': 'squirrel', 'Lesser Spotted Woodpecker': 'squirrel', 'Robin Redbreast': 'squirrel',
    'Hedge Doctor': 'dormouse', 'Feeder Vole': 'dormouse',
    'Mudwallow Toad': 'ooze', 'Garden Snail': 'ooze',
    'Bear Cub': 'marmot', 'Tusker Boar': 'marmot', 'Sett Warden': 'otter'
  };
  W.art = (name) => ART + P[MAP[name] || 'squirrel'] + '.jpg';
  // Short keyword chip for small sizes (taken from each unit's own text).
  const KW = {
    'Drumming Woodpecker': 'Peck 2', 'Lesser Spotted Woodpecker': 'Peck 2', 'Hedge Doctor': 'Curl',
    'Mudwallow Toad': 'Mire', 'Bear Cub': 'Shoulder', 'Sett Warden': 'Hunker', 'Robin Redbreast': 'Rival',
    'Hornet Scout': '→ Nightshade', 'Hornetling': '→ Nightshade', 'Belladonna Sprite': 'Nightshade'
  };
  W.kw = (u) => KW[u.name] || (u.text && u.text.length < 12 ? u.text.replace('.', '') : '');

  W.icon = {
    acorn: `<svg viewBox="0 0 40 40"><path d="M20 4v6" stroke="${INK}" stroke-width="3.5" stroke-linecap="round"/><path d="M11 21h18c0 9-4 13-9 16-5-3-9-7-9-16z" fill="#D9A441" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/><path d="M21 22c0 6-1 9-3 12" stroke="#A8761E" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M7 21c0-10 26-10 26 0z" fill="#7A4A22" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/><path d="M12 17h4M19 15h3M25 17h3" stroke="${INK}" stroke-width="2" stroke-linecap="round"/></svg>`,
    attack: `<svg viewBox="0 0 40 40"><path d="M20 3l15 8.5v17L20 37 5 28.5v-17z" fill="#E0812A" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/><path d="M13 27l14-14M15 13l3 3M24 24l3 3" stroke="${INK}" stroke-width="3" stroke-linecap="round"/></svg>`,
    health: `<svg viewBox="0 0 40 40"><circle cx="20" cy="23" r="13" fill="#B8322A" stroke="${INK}" stroke-width="3"/><path d="M13 9l4 5M27 9l-4 5M20 7v6" stroke="${INK}" stroke-width="3" stroke-linecap="round"/><path d="M12 22a8 8 0 0 1 6-7" stroke="#F7ECD4" stroke-width="3" fill="none" stroke-linecap="round"/></svg>`,
    tier: `<svg viewBox="0 0 40 40"><path d="M4 34h32v-8H4z M10 26h20v-8H10z M16 18h8v-8h-8z" fill="#C08A52" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/></svg>`,
    refresh: `<svg viewBox="0 0 40 40"><g fill="none" stroke="${INK}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"><path d="M32 17A13 13 0 0 0 9 12"/><path d="M8 5v8h8"/><path d="M8 23a13 13 0 0 0 23 5"/><path d="M32 35v-8h-8"/></g></svg>`,
    freeze: `<svg viewBox="0 0 40 40"><g stroke="${INK}" stroke-width="3.5" stroke-linecap="round"><path d="M20 3v34M5 11.5l30 17M5 28.5l30-17"/><path d="M15 6l5 4 5-4M15 34l5-4 5 4M6 17l6-1-2-6M34 23l-6 1 2 6M6 23l6 1-2 6M34 17l-6-1 2-6"/></g></svg>`,
    sword: `<svg viewBox="0 0 40 40"><path d="M8 32L30 10M27 7l6 6M10 24l6 6M6 34l4-4" stroke="${INK}" stroke-width="4" stroke-linecap="round"/></svg>`,
    berry: `<svg viewBox="0 0 40 40"><path d="M20 4c-2 6 2 8 0 12M20 9c4-4 9-3 11-1-3 3-7 3-11 1z" stroke="${INK}" stroke-width="2.5" fill="#41662C" stroke-linejoin="round"/><circle cx="20" cy="26" r="11" fill="#5E3A86" stroke="${INK}" stroke-width="3"/><path d="M14 24a6 6 0 0 1 4-5" stroke="#F7ECD4" stroke-width="2.5" fill="none" stroke-linecap="round"/></svg>`
  };
  W.shape = {
    atk: `<svg viewBox="0 0 40 40"><path d="M20 2.5l15.5 8.8v17.4L20 37.5 4.5 28.7V11.3z" fill="#E0812A" stroke="${INK}" stroke-width="3" stroke-linejoin="round"/></svg>`,
    hp: `<svg viewBox="0 0 40 40"><path d="M15 2.5l5 5 5-5" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><circle cx="20" cy="22" r="15" fill="#B8322A" stroke="${INK}" stroke-width="3"/></svg>`
  };
  W.stat = (kind, v, extra = '') => `<div class="wc-stat wc-${kind} ${extra}">${W.shape[kind]}<b>${v}</b></div>`;
  // leaf-shaped button with an inline SVG leaf (keeps an even ink stroke at any size)
  W.leaf = (inner, cls = '', attrs = '') => `<button class="wc-leaf ${cls}" ${attrs}><svg class="wc-leaf-bg" viewBox="0 0 300 100" preserveAspectRatio="none"><path class="sh" d="M10 54 C 70 8, 200 4, 292 50 C 200 100, 70 100, 10 54 Z" transform="translate(0 8)"/><path class="lf" d="M10 50 C 70 4, 200 0, 292 46 C 200 96, 70 96, 10 50 Z" vector-effect="non-scaling-stroke"/><path class="vn" d="M2 52 L 40 50" vector-effect="non-scaling-stroke"/></svg><span class="wc-leaf-in">${inner}</span></button>`;

  // size: 'board' | 'shop' | 'hero'
  W.tile = function (u, size, o = {}) {
    const cls = ['wc-tile', 'wc-tile--' + size, u.golden ? 'wc-gold' : '', u.token ? 'wc-token' : '', o.cls || ''].join(' ');
    const kw = W.kw(u);
    const shade = kw === 'Nightshade' ? ' wc-kw-shade' : '';
    let h = `<div class="${cls}" ${o.attrs || ''}>`;
    h += `<div class="wc-art" style="background-image:url('${W.art(u.name)}')"></div>`;
    if (u.tier) h += `<div class="wc-tier">${u.tier}</div>`;
    if (size === 'board' && kw) h += `<div class="wc-kw${shade}${kw.length > 9 ? ' wc-kw-long' : ''}">${kw}</div>`;
    if (size === 'shop') {
      if (kw) h += `<div class="wc-kw${shade}">${kw}</div>`;
      h += `<div class="wc-name">${u.name}</div><div class="wc-tribe">${u.tribe || ''}</div>`;
    }
    if (size === 'hero') {
      h += `<div class="wc-name">${u.name}</div><div class="wc-type">${u.type_line || u.tribe}${u.golden ? ' · Golden' : ''}</div>`;
      h += `<div class="wc-text"><p>${o.text || u.text}</p>${o.rem ? `<p><em>${o.rem}</em></p>` : ''}</div><div class="wc-tribe">${u.tribe}</div>`;
    }
    h += W.stat('atk', u.attack) + W.stat('hp', o.hp != null ? o.hp : u.health, o.hpCls || '');
    if (o.frozen || u.frozen) h += `<div class="wc-frost"><span>${W.icon.freeze}Frozen</span></div>`;
    if (o.after) h += o.after;
    return h + '</div>';
  };

  const slotHTML = (s, o) => {
    if (!s || s.empty) return `<div class="wc-slot" data-slot="${s.slot}"><div class="wc-pocket wc-is-empty"><div class="wc-empty">${s.slot}<small>empty</small></div></div>${o.labels ? `<div class="wc-label">&nbsp;</div>` : ''}</div>`;
    const extra = (o.extra && o.extra[s.slot]) || {};
    return `<div class="wc-slot" data-slot="${s.slot}"><div class="wc-pocket">${W.tile(s, 'board', extra)}</div>${o.labels ? `<div class="wc-label"><i>${s.slot}</i>${s.name}</div>` : ''}</div>`;
  };
  // rows: {front:[4 slots], back:[3 slots]}; o.enemy flips row order; o.links draws "behind" chevrons
  W.board = function (rows, o = {}) {
    const front = `<div class="wc-row wc-row--front">${rows.front.map((s) => slotHTML(s, o)).join('')}</div>`;
    const back = `<div class="wc-row wc-row--back">${rows.back.map((s) => slotHTML(s, o)).join('')}</div>`;
    return `<div class="wc-board ${o.enemy ? 'wc-board--enemy' : ''}">${o.enemy ? back + front : front + back}</div>`;
  };

  W.fill = (rows, n) => {
    const out = [];
    for (let i = 1; i <= n; i++) out.push(rows.find((s) => s.slot.endsWith(String(i))) || { slot: rows[0].slot[0] + i, empty: true });
    return out;
  };

  W.fit = function () {
    const st = document.querySelector('.wc-stage');
    const s = innerHeight / 640;
    st.style.width = innerWidth / s + 'px';
    st.style.transform = `scale(${s})`;
    document.documentElement.dataset.wide = innerWidth / s > 1300 ? '1' : '0';
  };
  W.start = function (fn) {
    W.fit();
    addEventListener('resize', W.fit);
    fn && fn();
  };
})();
