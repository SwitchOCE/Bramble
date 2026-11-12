// Folk Print: shared builders (cards, board slots, icons, papercut ornament, stage fit).
// Data comes from data.js (a copy of ../../fixture.json). Everything is namespaced fp-.
(function () {
  const F = window.FIX;
  const ART = '../../../folio/art/web/trials/ink-b-';
  // Only six Ink B portraits exist, so units borrow the nearest one, cropped differently.
  const PORTRAIT = {
    'Belladonna Sprite': ['fairy-hollowdeep', '50% 28%'], 'Hornet Scout': ['fairy-hollowdeep', '62% 18%'],
    'Hornetling': ['fairy-hollowdeep', '44% 14%'],
    'Drumming Woodpecker': ['squirrel-mosswood', '50% 30%'], 'Lesser Spotted Woodpecker': ['squirrel-mosswood', '38% 24%'],
    'Robin Redbreast': ['squirrel-mosswood', '58% 36%'],
    'Hedge Doctor': ['dormouse-beechhold', '50% 30%'], 'Sett Warden': ['dormouse-beechhold', '42% 40%'],
    'Feeder Vole': ['dormouse-beechhold', '55% 22%'],
    'Mudwallow Toad': ['otter-reedmouth', '50% 34%'], 'Garden Snail': ['ooze-moorbog', '50% 42%'],
    'Bear Cub': ['marmot-highcrown', '50% 30%'], 'Tusker Boar': ['marmot-highcrown', '48% 40%']
  };
  // Tribe = one papercut colour + one carved motif (colour alone never separates tribes).
  const TRIBE = {
    'Fairies': ['plum', 'moth'], 'Birds': ['blue', 'bird'], 'Hedgerow folk': ['green', 'leaf'],
    'Bog folk': ['moss', 'drop'], 'Great beasts': ['red', 'paw'], 'Hunters': ['ink', 'arrow'],
    'Hive': ['ochre', 'hex'], 'Neutral': ['kraft', 'sun']
  };
  const CHIP = {
    'Drumming Woodpecker': 'Peck 2', 'Lesser Spotted Woodpecker': 'Peck 2', 'Mudwallow Toad': 'Mire',
    'Bear Cub': 'Shoulder', 'Sett Warden': 'Hunker', 'Robin Redbreast': 'Rival', 'Belladonna Sprite': 'Start of Combat'
  };

  // Phone shop cards show chips, not clipped text: red = the unit's own keywords, outlined = what triggers the rest.
  const CHIPS = {
    'Belladonna Sprite': [['k', 'Start of Combat'], ['ns', 'Nightshade']], 'Drumming Woodpecker': [['k', 'Peck 2'], ['t', 'On attack']],
    'Hedge Doctor': [['t', 'On Curl prick']], 'Mudwallow Toad': [['k', 'Mire']], 'Garden Snail': [['k', 'Shell 4']],
    'Robin Redbreast': [['k', 'Rival'], ['t', 'On kill']], 'Sett Warden': [['k', 'Hunker'], ['t', 'On survive']]
  };
  // Keyword reminders for the inspect slip: the mechanics library's one-line summaries.
  const REMIND = {
    'Nightshade': 'each time this unit is attacked, it first loses half its current Health, rounded down. Lasts this combat.',
    'Peck': 'strikes its target 2 or 3 times in one attack, splitting its Attack between the strikes.',
    'Curl': 'doesn\'t attack while another friendly unit can, takes half damage, and anything that hits it gets pricked for 1.',
    'Mire': 'an enemy this damages gets stuck in the mud and skips its next attack.',
    'Shell': 'the first hit on this each combat deals at most N damage, then the shell breaks.',
    'Rival': 'the enemy across from this becomes its Rival; it fights only that unit, and both deal double damage.',
    'Hunker': 'when an enemy attacks this, it takes only half the damage.',
    'Shoulder': 'once per enemy cycle, this steps in and takes an attack aimed at a unit beside it.'
  };
  const REG = {};
  const BEHIND = { B1: 'F1 · F2', B2: 'F2 · F3', B3: 'F3 · F4' };

  function star(n, ro, ri, cx, cy) {
    const p = [];
    for (let i = 0; i < n * 2; i++) {
      const r = i % 2 ? ri : ro, a = Math.PI * i / n - Math.PI / 2;
      p.push((cx + r * Math.cos(a)).toFixed(2) + ',' + (cy + r * Math.sin(a)).toFixed(2));
    }
    return p.join(' ');
  }
  const petals = (n, cx, cy, d, rx, ry, fill) => Array.from({ length: n }, (_, i) =>
    `<ellipse cx="${cx}" cy="${cy - d}" rx="${rx}" ry="${ry}" fill="${fill}" transform="rotate(${i * 360 / n} ${cx} ${cy})"/>`).join('');

  const I = {
    heart: '<svg viewBox="0 0 32 32"><path d="M16 30C5.5 22.5 1.6 16.4 1.6 10.6 1.6 5.6 5.2 2.4 9.2 2.4c3 0 5.4 1.8 6.8 4.6 1.4-2.8 3.8-4.6 6.8-4.6 4 0 7.6 3.2 7.6 8.2 0 5.8-3.9 11.9-14.4 19.4z" fill="var(--fp-red)" stroke="var(--fp-ink)" stroke-width="2.2" stroke-linejoin="round"/><path d="M6 10.4c0-2.6 1.6-4.4 3.6-4.6" fill="none" stroke="var(--fp-paper)" stroke-width="1.5" stroke-linecap="round" opacity=".8"/></svg>',
    shield: '<svg viewBox="0 0 32 32"><path d="M16 1.8l13 4.4-.8 11.4C27.6 24 22.4 28 16 30.4 9.6 28 4.4 24 3.8 17.6L3 6.2z" fill="var(--fp-ink)" stroke="var(--fp-ink)" stroke-width="1.6" stroke-linejoin="round"/><path d="M16 4.6l10.2 3.4-.6 9.2c-.6 5-4.6 8.2-9.6 10.2-5-2-9-5.2-9.6-10.2l-.6-9.2z" fill="none" stroke="var(--fp-paper)" stroke-width="1" opacity=".55"/></svg>',
    tier: `<svg viewBox="0 0 32 32"><polygon points="${star(8, 15.4, 10.6, 16, 16)}" fill="var(--fp-ochre)" stroke="var(--fp-ink)" stroke-width="1.8" stroke-linejoin="round"/></svg>`,
    coin: `<svg viewBox="0 0 32 32"><circle cx="16" cy="16" r="14.4" fill="var(--fp-ochre)" stroke="var(--fp-ink)" stroke-width="2"/><circle cx="16" cy="16" r="11" fill="none" stroke="var(--fp-ink)" stroke-width="1" stroke-dasharray="1.6 1.6"/>${petals(6, 16, 16, 4.4, 2.1, 4.4, 'var(--fp-ink)')}<circle cx="16" cy="16" r="1.8" fill="var(--fp-ochre)"/></svg>`,
    refresh: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M26 13A10.4 10.4 0 0 0 7.4 9.6"/><path d="M6 19a10.4 10.4 0 0 0 18.6 3.4"/><path d="M26.6 5.6V13h-7.4"/><path d="M5.4 26.4V19h7.4"/></svg>',
    freeze: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"><g><path d="M16 3v26"/><path d="M12 6.4l4 3.4 4-3.4M12 25.6l4-3.4 4 3.4"/></g><g transform="rotate(60 16 16)"><path d="M16 3v26"/><path d="M12 6.4l4 3.4 4-3.4M12 25.6l4-3.4 4 3.4"/></g><g transform="rotate(120 16 16)"><path d="M16 3v26"/><path d="M12 6.4l4 3.4 4-3.4M12 25.6l4-3.4 4 3.4"/></g><circle cx="16" cy="16" r="3" fill="currentColor"/></svg>',
    berry: '<svg viewBox="0 0 32 32"><path d="M16 3c3 2 7 2.6 11 1.6-1.6 3.6-5.4 5.6-9.6 5" fill="var(--fp-green)" stroke="var(--fp-ink)" stroke-width="1.4" stroke-linejoin="round"/><path d="M16 3c-.4 4 .4 7 1.6 9.6M17 10l-6 5M17.4 11l5.6 5" stroke="var(--fp-ink)" stroke-width="1.6" fill="none" stroke-linecap="round"/><circle cx="10" cy="19.6" r="5.6" fill="var(--fp-plum)" stroke="var(--fp-ink)" stroke-width="1.6"/><circle cx="22.6" cy="20.4" r="5.6" fill="var(--fp-plum)" stroke="var(--fp-ink)" stroke-width="1.6"/><circle cx="16.4" cy="25.2" r="5.6" fill="var(--fp-plum)" stroke="var(--fp-ink)" stroke-width="1.6"/><circle cx="8.6" cy="18" r="1.4" fill="var(--fp-paper)"/><circle cx="21.2" cy="18.8" r="1.4" fill="var(--fp-paper)"/><circle cx="15" cy="23.6" r="1.4" fill="var(--fp-paper)"/></svg>',
    crown: '<svg viewBox="0 0 48 20"><path d="M3 18L6 4l9 8 9-10 9 10 9-8 3 14z" fill="var(--fp-ochre)" stroke="var(--fp-ink)" stroke-width="2" stroke-linejoin="round"/><circle cx="24" cy="12" r="2.4" fill="var(--fp-red)" stroke="var(--fp-ink)" stroke-width="1.2"/></svg>',
    swords: '<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"><path d="M5 5l17 17M27 5L10 22M19 25l6-6M13 25l-6-6M24 24l4 4M8 24l-4 4"/></svg>',
    skip: '<svg viewBox="0 0 32 32" fill="currentColor"><path d="M5 6l12 10-12 10zM16 6l12 10-12 10z"/><rect x="27" y="6" width="3" height="20" rx="1"/></svg>'
  };
  const MOTIF = {
    moth: '<svg viewBox="0 0 24 24"><ellipse cx="7.4" cy="9" rx="5.6" ry="6" fill="currentColor"/><ellipse cx="16.6" cy="9" rx="5.6" ry="6" fill="currentColor"/><ellipse cx="8.4" cy="17.4" rx="3.8" ry="4" fill="currentColor"/><ellipse cx="15.6" cy="17.4" rx="3.8" ry="4" fill="currentColor"/><circle cx="7.4" cy="9" r="1.8" fill="var(--fp-mc)"/><circle cx="16.6" cy="9" r="1.8" fill="var(--fp-mc)"/><rect x="11" y="4" width="2" height="17" rx="1" fill="var(--fp-mc)"/></svg>',
    bird: '<svg viewBox="0 0 24 24"><path d="M3 9.6c1.6-3.8 6-4.4 8-1.4l2 3.6 9-4.4-4.2 7.8C16 19 9.6 20 6.4 16.6 4.6 14.6 7.6 12.6 6 11.2z" fill="currentColor"/><circle cx="6.4" cy="9.2" r="1.1" fill="var(--fp-mc)"/><path d="M2.6 9.6L0.4 10.6l2.6.6" fill="currentColor"/></svg>',
    leaf: '<svg viewBox="0 0 24 24"><path d="M12 1.6c6 4.6 7.6 11.6 0 20.8-7.6-9.2-6-16.2 0-20.8z" fill="currentColor"/><path d="M12 5v16M12 10l-3-2.6M12 10l3-2.6M12 14.6l-3.4-2.6M12 14.6l3.4-2.6" stroke="var(--fp-mc)" stroke-width="1.3" fill="none" stroke-linecap="round"/></svg>',
    drop: '<svg viewBox="0 0 24 24"><path d="M12 2c4.6 6.4 7.4 10.4 7.4 14A7.4 7.4 0 0 1 4.6 16C4.6 12.4 7.4 8.4 12 2z" fill="currentColor"/><path d="M8.4 15.6a3.6 3.6 0 0 0 3 3.4" stroke="var(--fp-mc)" stroke-width="1.6" fill="none" stroke-linecap="round"/></svg>',
    paw: '<svg viewBox="0 0 24 24" fill="currentColor"><ellipse cx="12" cy="16" rx="6" ry="5.2"/><ellipse cx="4.6" cy="9.6" rx="2.4" ry="3"/><ellipse cx="9.2" cy="5.4" rx="2.4" ry="3"/><ellipse cx="14.8" cy="5.4" rx="2.4" ry="3"/><ellipse cx="19.4" cy="9.6" rx="2.4" ry="3"/></svg>',
    arrow: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 1l5 7h-3.4v9.6h-3.2V8H7z"/><path d="M10.4 17.6L7 22.6h3.4l1.6-2.2 1.6 2.2H17l-3.4-5z"/></svg>',
    hex: '<svg viewBox="0 0 24 24"><polygon points="22.4,12.0 17.2,21.0 6.8,21.0 1.6,12.0 6.8,3.0 17.2,3.0" fill="currentColor"/><polygon points="16.6,12.0 14.3,16.0 9.7,16.0 7.4,12.0 9.7,8.0 14.3,8.0" fill="var(--fp-mc)"/></svg>',
    sun: `<svg viewBox="0 0 24 24"><polygon points="${star(12, 11.6, 8, 12, 12)}" fill="currentColor"/><circle cx="12" cy="12" r="4.4" fill="var(--fp-mc)"/></svg>`
  };

  function kw(text) {
    return text.replace(/(Start of Combat|Nightshade|Peck \d|Curl|Mire|Shell \d+|Shoulder|Hunker|Rival)/g,
      m => `<b class="fp-kw${m === 'Nightshade' ? ' fp-kw-ns' : ''}">${m}</b>`);
  }
  function chip(u) {
    if (CHIP[u.name]) return CHIP[u.name];
    const m = /^(Shell \d+)/.exec(u.text || '');
    return m ? m[1] : '';
  }
  function tribeOf(u) { const t = TRIBE[u.tribe] || TRIBE.Neutral; return { ink: t[0], motif: MOTIF[t[1]] }; }

  // size: full | shop | board | combat. opts: frozen, hp (override), status[], id, cls, oldHp
  function card(u, size, o = {}) {
    REG[u.name] = u;
    const t = tribeOf(u);
    const [pf, pos] = PORTRAIT[u.name] || ['ooze-moorbog', '50% 40%'];
    const cls = ['fp-card', 'fp-s-' + size, 'fp-ink-' + t.ink];
    if (u.golden) cls.push('fp-golden');
    if (o.frozen || u.frozen) cls.push('fp-frozen');
    if (u.token) cls.push('fp-token');
    if (o.cls) cls.push(o.cls);
    const hp = o.hp != null ? o.hp : (u.current_health != null ? u.current_health : u.health);
    const text = size === 'full' || size === 'shop';
    const c = chip(u);
    const status = (o.status || u.status || []);
    return `<div class="${cls.join(' ')}"${o.id ? ` id="${o.id}"` : ''} data-name="${u.name}">
      ${u.golden ? `<div class="fp-crown">${I.crown}</div>` : ''}
      <div class="fp-body"><div class="fp-inner">
        <div class="fp-arch"><img src="${ART + pf}.jpg" style="object-position:${pos}" alt=""></div>
        <div class="fp-name"><span class="fp-fit">${u.name}</span></div>
        ${text ? `<div class="fp-tribe"><i class="fp-motif">${t.motif}</i><span>${u.type_line ? u.type_line + ' · ' : ''}${u.tribe}</span></div>
        <div class="fp-text"><p>${kw(u.text || '')}</p>${size === 'full' && u.keyword_reminder ? `<p class="fp-remind">${kw(u.keyword_reminder)}</p>` : ''}</div>` : ''}
        ${size === 'shop' ? `<div class="fp-chips">${(CHIPS[u.name] || []).map(([k, l]) => `<span class="fp-ch fp-ch-${k}">${l}</span>`).join('')}</div>` : ''}
      </div></div>
      ${size === 'shop' ? `<span class="fp-read" title="Tap to read">i</span>` : ''}
      ${u.tier ? `<div class="fp-tier">${I.tier}<b>${u.tier}</b></div>` : ''}
      ${!text && c ? `<div class="fp-chip"><span class="fp-fit" data-min="8">${c}</span></div>` : ''}
      ${!text ? `<i class="fp-motif fp-motif-pin">${t.motif}</i>` : ''}
      <div class="fp-atk">${I.shield}<b>${u.attack}</b></div>
      <div class="fp-hp">${I.heart}<b>${hp}</b>${o.oldHp != null ? `<s class="fp-oldhp">${o.oldHp}</s>` : ''}</div>
      ${o.frozen || u.frozen ? `<div class="fp-frost"><span class="fp-frost-flake">${I.freeze}</span><em>Frozen</em></div>` : ''}
      ${status.includes('Nightshade') ? `<div class="fp-ns-tag">${I.berry}<span>Nightshade</span></div>` : ''}
      ${u.token ? `<div class="fp-token-tag">Token</div>` : ''}
    </div>`;
  }
  function empty(slot, size) {
    const note = BEHIND[slot] ? `behind ${BEHIND[slot]}` : 'front row';
    return `<div class="fp-empty fp-s-${size}"><b>${slot}</b><span>Empty</span><small>${note}</small></div>`;
  }
  // 4–3 brick board. rows: {front:[...4], back:[...3]} entries are units or {slot, empty}.
  function board(rows, size, o = {}) {
    const one = (u) => `<div class="fp-slot" data-slot="${u.slot}">${u.empty ? empty(u.slot, size) : card(u, size, (o.opts && o.opts[u.slot]) || {})}<span class="fp-slotlab">${u.slot}</span></div>`;
    const fr = `<div class="fp-row fp-row-front"><div class="fp-rowlab">Front</div>${rows.front.map(one).join('')}</div>`;
    const bk = `<div class="fp-row fp-row-back"><div class="fp-rowlab">Back</div>${rows.back.map(one).join('')}</div>`;
    return `<div class="fp-board fp-board-${size}${o.enemy ? ' fp-board-enemy' : ''}">${o.enemy ? bk + fr : fr + bk}</div>`;
  }

  // Stitch each back slot to the two front slots in front of it (works for either board orientation).
  function stitch(b, color = 'var(--fp-red)') {
    const o = rect(b), sl = s => rect(b.querySelector(`[data-slot="${s}"]`));
    const enemy = b.classList.contains('fp-board-enemy');
    let d = '';
    [['B1', 'F1', 'F2'], ['B2', 'F2', 'F3'], ['B3', 'F3', 'F4']].forEach(([bk, f1, f2]) => {
      const r = sl(bk), x0 = r.x - o.x + r.w / 2, y0 = enemy ? r.y - o.y + r.h : r.y - o.y;
      [sl(f1), sl(f2)].forEach(f => {
        const x1 = f.x - o.x + f.w / 2, y1 = enemy ? f.y - o.y : f.y - o.y + f.h;
        d += `M${x0} ${y0 + (enemy ? -2 : 2)} L${(x0 + x1) / 2} ${(y0 + y1) / 2 + (enemy ? -1 : 1)}`;
      });
    });
    b.insertAdjacentHTML('afterbegin', `<svg class="fp-stitch"><path d="${d}" stroke="${color}" stroke-width="4.5" stroke-linecap="round" stroke-dasharray="1 8" fill="none"/></svg>`);
  }

  // Inspect slip: the full rules text, opened by tapping a card (phone shop cards show only chips).
  function slip(u) {
    const t = tribeOf(u);
    const own = Object.keys(REMIND).filter(k => new RegExp('\\b' + k + '\\b').test(u.text || ''));
    return `<div class="fp-slip fp-ink-${t.ink}" role="dialog" aria-label="${u.name}">
      <div class="fp-slip-top"></div>
      <button class="fp-slip-x" aria-label="Close">${'\u00d7'}</button>
      <div class="fp-slip-head">${u.tier ? `<span class="fp-slip-tier">${I.tier}<b>${u.tier}</b></span>` : ''}<span class="fp-slip-name">${u.name}</span></div>
      <div class="fp-slip-line"><span class="fp-slip-stat">${I.shield}<b>${u.attack}</b></span><span class="fp-slip-stat">${I.heart}<b>${u.current_health != null ? u.current_health : u.health}</b></span>
        <span class="fp-slip-tribe"><i class="fp-motif">${t.motif}</i>${u.type_line ? u.type_line + ' · ' : ''}${u.tribe}</span></div>
      <p class="fp-slip-rules">${kw(u.text || '')}</p>
      ${own.map(k => `<p class="fp-slip-rem"><b class="fp-kw${k === 'Nightshade' ? ' fp-kw-ns' : ''}">${k}</b>: ${REMIND[k]}</p>`).join('')}
    </div>`;
  }
  // Tap any card to open its slip; tap the cross or the scrim to close.
  function inspect(stageSel = '.fp-stage') {
    const st = document.querySelector(stageSel);
    st.addEventListener('click', e => {
      if (e.target.closest('.fp-slip-x') || e.target.classList.contains('fp-insp')) { st.querySelector('.fp-insp')?.remove(); return; }
      const c = e.target.closest('.fp-card[data-name]');
      if (!c || e.target.closest('.fp-insp')) return;
      st.querySelector('.fp-insp')?.remove();
      st.insertAdjacentHTML('beforeend', `<div class="fp-insp">${slip(REG[c.dataset.name])}</div>`);
    });
  }

  // Łowicz-style layered papercut "tree of life": draw half, mirror it.
  function tree(w = 400, h = 520) {
    const cx = w / 2;
    const half = `
      <path d="M${cx} 470 C ${cx - 4} 380, ${cx - 2} 260, ${cx} 150" stroke="var(--fp-green)" stroke-width="12" fill="none"/>
      <path d="M${cx - 6} 400 C ${cx - 70} 380, ${cx - 120} 330, ${cx - 128} 280 C ${cx - 80} 290, ${cx - 30} 330, ${cx - 6} 380z" fill="var(--fp-green)"/>
      <path d="M${cx - 6} 300 C ${cx - 60} 290, ${cx - 96} 250, ${cx - 100} 210 C ${cx - 60} 220, ${cx - 26} 250, ${cx - 6} 282z" fill="var(--fp-green)"/>
      <path d="M${cx - 6} 340 C ${cx - 50} 320, ${cx - 70} 300, ${cx - 72} 290" stroke="var(--fp-ink)" stroke-width="2" fill="none"/>
      <g transform="translate(${cx - 128} 262)">
        <path d="M0 -40 C -22 -36, -26 -6, 0 10 C 26 -6, 22 -36, 0 -40z" fill="var(--fp-red)"/>
        <path d="M-18 -46 C -24 -20, -12 -4, 0 0 C -6 -18, -8 -32, -18 -46z M18 -46 C 24 -20, 12 -4, 0 0 C 6 -18, 8 -32, 18 -46z" fill="var(--fp-red)"/>
        <path d="M0 -26 C -9 -22, -10 -8, 0 0 C 10 -8, 9 -22, 0 -26z" fill="var(--fp-ochre)"/>
        <circle cx="0" cy="-12" r="3.4" fill="var(--fp-blue)"/>
      </g>
      <g transform="translate(${cx - 100} 196)">
        <circle r="22" fill="var(--fp-blue)"/>${petals(10, 0, 0, 22, 6, 9, 'var(--fp-blue)')}
        <circle r="15" fill="var(--fp-rose)"/><circle r="8" fill="var(--fp-ochre)"/><circle r="3" fill="var(--fp-ink)"/>
      </g>
      <g transform="translate(${cx - 120} 440)">
        <path d="M-40 -10 C -40 -40, -8 -52, 14 -36 C 26 -46, 40 -44, 44 -34 C 34 -34, 28 -28, 26 -20 C 30 0, 14 14, -6 14 C -26 14, -40 4, -40 -10z" fill="var(--fp-ink)"/>
        <path d="M-40 -12 C -62 -40, -70 -64, -60 -84 C -50 -60, -40 -46, -30 -36z M-38 -8 C -70 -24, -84 -44, -84 -62 C -66 -44, -52 -34, -34 -26z M-36 -2 C -70 -2, -88 -12, -96 -28 C -76 -18, -56 -14, -36 -12z" fill="var(--fp-red)"/>
        <circle cx="26" cy="-34" r="3" fill="var(--fp-paper)"/>
        <path d="M14 -40 C 14 -52, 22 -56, 28 -50 C 30 -58, 38 -56, 36 -46" fill="var(--fp-red)"/>
        <path d="M-24 -10 C -14 -22, 4 -22, 12 -10 C 2 -2, -14 -2, -24 -10z" fill="var(--fp-ochre)"/>
        <path d="M-6 14 L -10 30 M 6 12 L 8 30" stroke="var(--fp-ink)" stroke-width="3"/>
      </g>`;
    const center = `
      <path d="M${cx - 70} 470 C ${cx - 70} 520, ${cx + 70} 520, ${cx + 70} 470 L ${cx + 50} 452 L ${cx - 50} 452z" fill="var(--fp-red)"/>
      <path d="M${cx - 48} 476 L ${cx + 48} 476" stroke="var(--fp-ochre)" stroke-width="6" stroke-dasharray="8 6"/>
      <g transform="translate(${cx} 120)">
        ${petals(16, 0, 0, 52, 9, 16, 'var(--fp-red)')}<circle r="50" fill="var(--fp-ink)"/>
        ${petals(12, 0, 0, 36, 7, 12, 'var(--fp-ochre)')}<circle r="32" fill="var(--fp-green)"/>
        ${petals(8, 0, 0, 20, 6, 9, 'var(--fp-rose)')}<circle r="14" fill="var(--fp-blue)"/><circle r="6" fill="var(--fp-paper)"/>
      </g>
      <g transform="translate(${cx} 300)"><circle r="16" fill="var(--fp-ochre)"/>${petals(8, 0, 0, 16, 4, 7, 'var(--fp-ochre)')}<circle r="8" fill="var(--fp-red)"/></g>`;
    return `<svg class="fp-tree" viewBox="0 0 ${w} ${h}">${half}<g transform="translate(${w} 0) scale(-1 1)">${half}</g>${center}</svg>`;
  }
  function rosette(r = 40, ring = 'var(--fp-red)', mid = 'var(--fp-ochre)', core = 'var(--fp-ink)') {
    return `<svg viewBox="-50 -50 100 100" width="${r * 2}" height="${r * 2}">${petals(12, 0, 0, 36, 8, 13, ring)}<circle r="34" fill="${ring}"/>${petals(8, 0, 0, 22, 7, 11, mid)}<circle r="20" fill="${core}"/><circle r="8" fill="var(--fp-paper)"/></svg>`;
  }

  // Textures: paper grain, and linocut gouge marks for the black plates.
  function textures() {
    const grain = `<svg xmlns='http://www.w3.org/2000/svg' width='180' height='180'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.8' numOctaves='2' seed='4' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 .11 0 0 0 0 .1 0 0 0 0 .11 3.2 0 0 0 -1.9'/></filter><rect width='180' height='180' filter='url(#n)'/></svg>`;
    let g = '';
    const rnd = (s => () => (s = (s * 16807) % 2147483647) / 2147483647)(7);
    for (let i = 0; i < 26; i++) {
      const x = rnd() * 120, y = rnd() * 120, l = 6 + rnd() * 12, a = (rnd() * 40 - 20) | 0, b = (rnd() * 4 - 2).toFixed(1);
      g += `<path d='M${x.toFixed(1)} ${y.toFixed(1)} q${(l / 2).toFixed(1)} ${b} ${l.toFixed(1)} 0' transform='rotate(${a} ${x.toFixed(0)} ${y.toFixed(0)})'/>`;
    }
    const gouge = `<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><g stroke='%23F3EAD6' stroke-opacity='.13' stroke-width='1.6' stroke-linecap='round' fill='none'>${g}</g></svg>`;
    const gougeInk = gouge.replace("%23F3EAD6' stroke-opacity='.13'", "%231D1A1E' stroke-opacity='.16'");
    const r = document.documentElement.style;
    r.setProperty('--fp-gouge-ink', `url("data:image/svg+xml,${gougeInk.replace(/</g, '%3C').replace(/>/g, '%3E').replace(/"/g, "'")}")`);
    r.setProperty('--fp-grain', `url("data:image/svg+xml,${encodeURIComponent(grain)}")`);
    r.setProperty('--fp-gouge', `url("data:image/svg+xml,${gouge.replace(/</g, '%3C').replace(/>/g, '%3E').replace(/"/g, "'")}")`);
  }

  function fit() {
    const H = 720, s = innerHeight / H;
    const st = document.querySelector('.fp-stage');
    document.body.classList.toggle('fp-phone', innerHeight < 560);
    st.style.width = (innerWidth / s) + 'px';
    st.style.height = H + 'px';
    st.style.transform = `scale(${s})`;
    return s;
  }
  // Shrink text that overflows its box (names on small cards).
  function fitText(root = document) {
    root.querySelectorAll('.fp-fit').forEach(el => {
      const box = el.parentElement, cs = getComputedStyle(box);
      const room = () => box.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
      let fs = parseFloat(getComputedStyle(el).fontSize), n = 0;
      let min = parseFloat(el.dataset.min || 10);
      if (box.classList.contains('fp-name')) min = Math.max(min, fs * .88); // big names: wrap to two lines instead of shrinking
      while (el.offsetWidth > room() + 0.5 && fs > min && n++ < 40) {
        fs -= 0.5; el.style.fontSize = fs + 'px';
      }
      if (el.offsetWidth > room() + 0.5) { // still too long: wrap onto two lines
        el.style.whiteSpace = 'normal'; el.style.width = room() + 'px'; el.style.textAlign = 'center'; el.style.lineHeight = '1';
        box.style.height = 'auto'; box.style.paddingTop = box.style.paddingBottom = '3px';
        while (el.offsetHeight > fs * 2.2 && fs > 9 && n++ < 60) { fs -= 0.5; el.style.fontSize = fs + 'px'; } // at most two lines
      }
    });
  }
  // Shrink rules text that doesn't fit its card (desktop; the phone clamps lines instead).
  function fitRules(root = document) {
    if (document.body.classList.contains('fp-phone')) return;
    root.querySelectorAll('.fp-text').forEach(el => {
      let fs = parseFloat(getComputedStyle(el).fontSize), n = 0;
      while (el.scrollHeight > el.clientHeight + 1 && fs > 10 && n++ < 30) { fs -= 0.5; el.style.fontSize = fs + 'px'; }
    });
  }
  // Position of an element in stage coordinates.
  function rect(el) {
    const st = document.querySelector('.fp-stage').getBoundingClientRect();
    const s = st.height / 720, r = el.getBoundingClientRect();
    return { x: (r.left - st.left) / s, y: (r.top - st.top) / s, w: r.width / s, h: r.height / s };
  }
  function boot(build) {
    textures();
    const go = () => { fit(); build(); fitText(); fitRules(); if (window.fpAfter) window.fpAfter(); };
    const fonts = ['16px "Alfa Slab One"', '800 16px "Alegreya Sans SC"', '700 16px "Alegreya Sans SC"', '500 16px Alegreya', 'italic 500 16px Alegreya', '800 16px Alegreya'];
    Promise.all(fonts.map(f => document.fonts.load(f))).then(() => document.fonts.ready).then(go, go);
    addEventListener('resize', () => { fit(); });
  }

  window.FP = { F, I, MOTIF, REG, card, slip, inspect, empty, board, tree, rosette, kw, boot, rect, fitText, star, petals, stitch };
})();
