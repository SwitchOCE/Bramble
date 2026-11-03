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
    coin: '<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13" fill="var(--gilt)" stroke="var(--ink)" stroke-width="2.6"/><circle cx="16" cy="16" r="8.6" fill="none" stroke="var(--ink)" stroke-width="1.6"/><path d="M11.8 14.2h8.4c0-2.6-1.9-4.2-4.2-4.2s-4.2 1.6-4.2 4.2zM12.6 14.2c0 4 1.6 7 3.4 8 1.8-1 3.4-4 3.4-8" fill="var(--peat)" stroke="var(--ink)" stroke-width="1.4" stroke-linejoin="round"/></svg>',
    heart: '<svg viewBox="0 0 32 32"><path d="M16 28.5C6.5 21.6 3 16 3 11.2 3 7 6.1 4 9.8 4c2.8 0 4.8 1.6 6.2 3.8C17.4 5.6 19.4 4 22.2 4 25.9 4 29 7 29 11.2c0 4.8-3.5 10.4-13 17.3z" fill="var(--berry)"/><path class="cel" d="M26.6 6.8C28.3 9.6 28 13.4 25.5 17.6 23 21.6 19.8 24.8 16 27.6 21 22 24.6 15.6 26.6 6.8z" fill="#86261F"/><path d="M16 28.5C6.5 21.6 3 16 3 11.2 3 7 6.1 4 9.8 4c2.8 0 4.8 1.6 6.2 3.8C17.4 5.6 19.4 4 22.2 4 25.9 4 29 7 29 11.2c0 4.8-3.5 10.4-13 17.3z" fill="none" stroke="var(--ink)" stroke-width="2.6" stroke-linejoin="round"/></svg>',
    atkbadge: '<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="13.6" fill="var(--mustard)"/><path d="M27.4 10.6A13.6 13.6 0 0 1 8 27.2 12 12 0 0 0 27.4 10.6z" fill="#B9821A"/><circle cx="16" cy="16" r="13.6" fill="none" stroke="var(--ink)" stroke-width="2.6"/></svg>',
    attack: '<svg viewBox="0 0 32 32"><path d="M16 2.5l5.6 13.2L16 29.5l-5.6-13.8z" fill="var(--mustard)" stroke="var(--ink)" stroke-width="2.6" stroke-linejoin="round"/><path d="M16 6v19" stroke="var(--ink)" stroke-width="1.4"/></svg>',
    tier: '<svg viewBox="0 0 32 32"><path d="M16 2.8l3.9 8.2 8.9 1.1-6.6 6.1 1.8 8.9L16 22.7l-7.9 4.4 1.8-8.9-6.6-6.1 8.9-1.1z" fill="var(--gilt)" stroke="var(--ink)" stroke-width="2.4" stroke-linejoin="round"/></svg>',
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
    const chipHtml = chips(u.text || '').map(c => `<span class="chip">${c}</span>`).join('');
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
  function empty(slot) { return `<div class="slot empty"><span class="sl">${slot}</span><span class="e">empty</span></div>`; }
  function slot(u, size, o) { return u.empty ? empty(u.slot) : `<div class="slot"><span class="sl">${u.slot}</span>${card(u, size, o && o[u.slot])}</div>`; }
  // b = {front:[4], back:[3]} with slot ids. order: 'front-first' (front on top) or 'back-first' (enemy: back on top)
  function board(b, size, o = {}) {
    const front = `<div class="row front"><div class="rowtag">Front</div>${b.front.map(u => slot(u, size, o.per)).join('')}</div>`;
    const back = `<div class="row back"><div class="rowtag">Back</div>${b.back.map(u => slot(u, size, o.per)).join('')}</div>`;
    return `<div class="board ${o.cls || ''}">${o.order === 'back-first' ? back + front : front + back}</div>`;
  }
  function lobby(list, o = {}) {
    return list.map((p, i) => `<li class="${p.name === 'You' ? 'you' : ''} ${p.next_opponent ? 'next' : ''} ${p.eliminated ? 'out' : ''}">
      <span class="rk">${p.eliminated ? '' : i + 1}</span>
      <span class="nm">${p.name}${p.next_opponent ? '<em class="nx">' + ICON.swords + 'Next</em>' : ''}</span>
      <span class="tr" title="Tier">${ICON.tier}<b>${p.tier}</b></span>
      <span class="hp">${ICON.heart}<b>${p.health}</b></span>
      ${o.last ? `<span class="last ${p.last}">${p.eliminated ? 'out' : p.last}</span>` : ''}
    </li>`).join('');
  }
  window.INK = { ICON, card, board, empty, lobby, text, PORTRAIT, ART };
})();
