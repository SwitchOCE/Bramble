// Clean Arena components. Data comes from data.js (window.FX, a copy of fixture.json).
(function () {
  const P = {
    // currency: a coin with an acorn cut in ink
    gold: '<circle cx="12" cy="12" r="11" fill="#FFCC33"/><path d="M11.2 4.2h1.6v2.4h-1.6z" fill="#0B0E10"/><path d="M5.6 10.6Q12 4.6 18.4 10.6z" fill="#0B0E10"/><path d="M7.4 11.6h9.2v1q0 5.6-4.6 7.6-4.6-2-4.6-7.6z" fill="#0B0E10"/>',
    tier: '<path d="M12 1.5 21.5 7v10L12 22.5 2.5 17V7z" fill="currentColor"/>',
    // attack: a bramble thorn
    attack: '<path d="M3 21.5 8.5 13C11.5 8.6 15.6 5.4 21.5 2.5 19 8.4 15.7 12.5 11.3 15.6z" fill="currentColor"/><path d="M8.7 16.5 4.5 13.8 3 15.6z" fill="currentColor"/>',
    // health: a heart-shaped leaf with a midrib
    health: '<path d="M12 21.5C5 15.8 2 12 2 8.3a5 5 0 0 1 10-1.6 5 5 0 0 1 10 1.6c0 3.7-3 7.5-10 13.2z" fill="currentColor"/><path d="M12 7.5v13" stroke="#F3F4EF" stroke-width="1.4" opacity=".55"/>',
    refresh: '<path d="M19.5 12.5a7.5 7.5 0 1 1-2.4-6" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round"/><path d="M13.5 2.5 21 4.2 19.4 11.6z" fill="currentColor"/>',
    freeze: '<g stroke="currentColor" stroke-width="2.3" stroke-linecap="round" fill="none"><path d="M12 2v20M3.3 7l17.4 10M3.3 17 20.7 7"/><path d="M9 3.6l3 2.4 3-2.4M9 20.4l3-2.4 3 2.4M3.6 10.5l3.6-1.2-.6-3.8M20.4 13.5l-3.6 1.2.6 3.8M3.6 13.5l3.6 1.2-.6 3.8M20.4 10.5l-3.6-1.2.6-3.8"/></g>',
    up: '<path d="M12 3 21 13h-5.5v8h-7v-8H3z" fill="currentColor"/>',
    play: '<path d="M6 3.5 20 12 6 20.5z" fill="currentColor"/>',
    ff: '<path d="M2.5 4.5 12 12l-9.5 7.5zM12 4.5 21.5 12 12 19.5z" fill="currentColor"/>',
    skip: '<path d="M3 4.5 14 12 3 19.5zM16 4.5h3.5v15H16z" fill="currentColor"/>',
    gear: '<path d="M12 8.2a3.8 3.8 0 1 0 0 7.6 3.8 3.8 0 0 0 0-7.6zm8.6 5.2-.1-2.8 2-1.7-2-3.4-2.5.8-2.4-1.4L15 2h-4l-.6 2.5-2.4 1.4-2.5-.8-2 3.4 2 1.7v2.8l-2 1.7 2 3.4 2.5-.8 2.4 1.4L11 22h4l.6-2.5 2.4-1.4 2.5.8 2-3.4z" fill="currentColor" fill-rule="evenodd"/>',
    sword: '<path d="M14 3h7v7L10 21l-7-7z" fill="currentColor"/>',
    trophy: '<path d="M6 2h12v6a6 6 0 0 1-12 0zM3 4h3v4H3zM18 4h3v4h-3zM10.5 14h3v4h3v3.5h-9V18h3z" fill="currentColor"/>',
    // tribes
    Birds: '<path d="M20.5 2.5C11 3.3 5.2 9.8 4 20.5h2.2c.9-4.6 3-8.2 6.8-10.6-3 3.2-4.8 6.6-5.4 10.4 7.4-1.4 12.3-8.6 12.9-17.8z" fill="currentColor"/>',
    'Hedgerow folk': '<path d="M12 2l1.8 3.4 3.6-1.2-.4 3.8 3.8.6-1.8 3.4 2.8 2.6-3.6 1.4.6 3.8-3.8-.6L12 22l-1.6-3.4-3.8.6.6-3.8-3.6-1.4 2.8-2.6L4.6 8l3.8-.6L8 3.6l3.6 1.2z" fill="currentColor"/>',
    'Bog folk': '<path d="M12 2.5a9.5 9.5 0 1 0 9.5 9.5H12z" fill="currentColor"/>',
    'Great beasts': '<ellipse cx="6" cy="9" rx="2.2" ry="2.8" fill="currentColor"/><ellipse cx="10" cy="5.6" rx="2.2" ry="2.8" fill="currentColor"/><ellipse cx="14.6" cy="5.6" rx="2.2" ry="2.8" fill="currentColor"/><ellipse cx="18.6" cy="9" rx="2.2" ry="2.8" fill="currentColor"/><path d="M12.3 11c3.4 0 6.2 4 6.2 6.8 0 2.6-2.6 3.4-6.2 3.4S6 20.4 6 17.8C6 15 8.9 11 12.3 11z" fill="currentColor"/>',
    Hunters: '<path d="M12 1.5 18 9.5h-4v12h-4v-12H6z" fill="currentColor"/>',
    Hive: '<path d="M7.5 2.8l4 2.3v4.6l-4 2.3-4-2.3V5.1zM16.5 2.8l4 2.3v4.6l-4 2.3-4-2.3V5.1zM12 10.6l4 2.3v4.6l-4 2.3-4-2.3v-4.6z" fill="currentColor"/>',
    Fairies: '<path d="M12 1.5c1 6.4 4 9.5 10.5 10.5C16 13 13 16 12 22.5 11 16 8 13 1.5 12 8 11 11 7.9 12 1.5z" fill="currentColor"/>',
    berry: '<circle cx="12" cy="14.5" r="7.5" fill="currentColor"/><path d="M12 7.5C11 4.5 8 3 5 3.5c1 3 3.6 4.4 7 4zM12 7.5c1-3 4-4.5 7-4-1 3-3.6 4.4-7 4z" fill="currentColor"/>',
    Neutral: '<path d="M12 3a9 9 0 1 0 9 9" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/><path d="M12 8a4 4 0 1 0 4 4" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>'
  };
  const icon = (n, cls = '') => `<svg class="i ${cls}" viewBox="0 0 24 24" aria-hidden="true">${P[n] || P.Neutral}</svg>`;
  const TRIBE = { 'Great beasts': 'bark', Hunters: 'bark', 'Hedgerow folk': 'bark', 'Bog folk': 'bark', Birds: 'bloom', Fairies: 'bloom', Hive: 'bloom', Neutral: 'mist' };
  const tribeVar = t => `--tribe: var(--${TRIBE[t] || 'mist'})`;
  const PORTRAIT = { 'Belladonna Sprite': 'assets/belladonna-sprite.jpg', 'Tusker Boar': 'assets/tusker-boar.jpg', 'Hornet Scout': 'assets/hornet.jpg', 'Hornetling': 'assets/hornet.jpg' };
  // A leading one-word keyword ("Shoulder.", "Peck 2.") becomes a tag; other text is shown as a clipped line.
  const keyword = text => {
    if (!text) return null;
    const m = text.match(/^([A-Z][a-z]+(?: \d+)?)\.(\s|$)/);
    return m ? m[1] : null;
  };
  const art = u => {
    const src = PORTRAIT[u.name];
    return `<div class="art">${src ? `<img src="${src}" alt="">` : icon(u.tribe || 'Neutral')}</div>`;
  };
  const stats = (a, h, hpCls = '') => `<div class="stats"><div class="stat atk">${icon('attack')}<span class="n">${a}</span></div><div class="stat hp ${hpCls}">${icon('health')}<span class="n">${h}</span></div></div>`;

  function token(u, o = {}) {
    const kw = keyword(u.text);
    const mid = o.status ? o.status : kw ? `<span class="kw">${kw}</span>` : (u.text ? `<span class="kw txt">${u.text}</span>` : '');
    const cls = ['tok', u.golden ? 'golden' : '', o.cls || ''].join(' ');
    const hp = o.hp != null ? o.hp : (u.current_health != null ? u.current_health : u.health);
    return `<div class="tokwrap"><div class="${cls}" style="${tribeVar(u.tribe)}" data-slot="${o.slot || u.slot || ''}">
      <div class="tok-top">${u.tier ? `<span class="hex">${u.tier}</span>` : ''}<span class="tok-name">${u.name}</span>${u.golden ? '<span class="gstar">★</span>' : ''}<span class="tok-slot">${o.slot || u.slot || ''}</span></div>
      <div class="tok-mid">${art(u)}${mid}</div>
      ${stats(u.attack, hp, o.hpCls)}
      
    </div></div>`;
  }
  const empty = slot => `<div class="slot-empty" data-slot="${slot}"><b>${slot}</b><span>empty</span></div>`;
  function shopCard(u) {
    const kw = keyword(u.text);
    const rest = kw ? u.text.slice(kw.length + 1).trim() : u.text;
    const mid = kw ? `<div><div class="kw">${kw}</div>${rest ? `<div class="kw txt">${rest}</div>` : ''}</div>` : `<span class="kw txt">${u.text}</span>`;
    return `<div class="card ${u.frozen ? 'frozen' : ''} ${u.golden ? 'golden' : ''}" style="${tribeVar(u.tribe)}">
      <div class="tok-top"><span class="hex">${u.tier}</span><span class="tok-name">${u.name}</span></div>
      <span class="price">${icon('gold')}3</span>
      <div class="tok-mid">${art(u)}${mid}</div>
      ${u.frozen ? `<div class="frozen-tag"><span>${icon('freeze')}FROZEN</span></div>` : ''}
      ${stats(u.attack, u.health)}
    </div>`;
  }
  // rows: {front:[...4], back:[...3]} items are units (with slot) or {slot, empty}
  function board(rows, o = {}) {
    const cell = x => x.empty ? empty(x.slot) : token(x, (o.per && o.per[x.slot]) || {});
    const front = `<div class="rowlab">Front <i>·</i> attacks first</div><div class="row front">${rows.front.map(cell).join('')}</div>`;
    const back = `<div class="rowlab">Back</div><div class="row back">${rows.back.map(cell).join('')}</div>`;
    return `<div class="board ${o.cls || ''}">${o.flip ? back + front : front + back}<svg class="ties"></svg></div>`;
  }
  // Draw the brick ties: each back slot to the two front slots it sits behind.
  function drawTies(root = document) {
    root.querySelectorAll('.board').forEach(b => {
      const svg = b.querySelector('.ties'); const br = b.getBoundingClientRect();
      const f = [...b.querySelectorAll('.row.front > *')], k = [...b.querySelectorAll('.row.back > *')];
      const flip = b.querySelector('.row.back').getBoundingClientRect().top < b.querySelector('.row.front').getBoundingClientRect().top;
      let s = '';
      k.forEach((el, i) => {
        const r = el.getBoundingClientRect();
        [f[i], f[i + 1]].forEach(fe => {
          if (!fe) return; const q = fe.getBoundingClientRect();
          const y1 = flip ? r.bottom : r.top, y2 = flip ? q.top : q.bottom;
          const x1 = r.left + r.width / 2 + (q.left < r.left ? -r.width * .18 : r.width * .18), x2 = q.left + q.width / 2;
          s += `<line x1="${x1 - br.left}" y1="${y1 - br.top}" x2="${x2 - br.left}" y2="${y2 - br.top}"/>`;
        });
      });
      svg.setAttribute('width', br.width); svg.setAttribute('height', br.height); svg.innerHTML = s;
    });
  }
  function lobby(players) {
    return `<div class="lobby">${players.map(p => `<div class="pill ${p.name === 'You' ? 'you' : ''} ${p.next_opponent ? 'next' : ''} ${p.eliminated ? 'out' : ''}">
      ${p.next_opponent ? '<span class="flag">NEXT</span>' : ''}
      <span class="hp">${p.health}</span><span><span class="nm" style="display:block">${p.name}</span><span class="tr">T${p.tier}</span></span>
      ${p.eliminated ? '' : `<span class="res ${p.last}"></span>`}</div>`).join('')}</div>`;
  }
  window.CA = { icon, token, empty, shopCard, board, drawTies, lobby, keyword, tribeVar, PORTRAIT, TRIBE };
})();
