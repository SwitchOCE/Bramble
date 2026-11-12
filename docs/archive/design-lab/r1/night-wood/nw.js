// Night Wood shared helpers: icon sprite, portrait map, card and board builders.
(function () {
  const ART = '../../../folio/art/web/trials/ink-b-';
  // Six Ink B trial portraits stand in for ten units; species don't match.
  const PORTRAIT = {
    'Belladonna Sprite': 'fairy-hollowdeep', 'Bear Cub': 'marmot-highcrown', 'Tusker Boar': 'marmot-highcrown',
    'Sett Warden': 'squirrel-mosswood', 'Robin Redbreast': 'squirrel-mosswood',
    'Lesser Spotted Woodpecker': 'otter-reedmouth', 'Drumming Woodpecker': 'otter-reedmouth',
    'Mudwallow Toad': 'ooze-moorbog', 'Garden Snail': 'ooze-moorbog',
    'Hedge Doctor': 'dormouse-beechhold', 'Hornet Scout': 'dormouse-beechhold', 'Hornetling': 'dormouse-beechhold', 'Feeder Vole': 'dormouse-beechhold'
  };
  // Short label for board-size cards: words taken from each unit's own text.
  const KEY = {
    'Drumming Woodpecker': 'Peck 2', 'Lesser Spotted Woodpecker': 'Peck 2', 'Hedge Doctor': 'Whenever…', 'Mudwallow Toad': 'Mire',
    'Bear Cub': 'Shoulder', 'Sett Warden': 'Hunker', 'Hornet Scout': 'Nightshade', 'Hornetling': 'Nightshade',
    'Robin Redbreast': 'Rival', 'Belladonna Sprite': 'Start of Combat'
  };
  const TRIBE = { 'Fairies': 'nightshade', 'Birds': 'hoarfrost', 'Hedgerow folk': 'lichen', 'Bog folk': 'lichen', 'Great beasts': 'ember', 'Hunters': 'mist', 'Hive': 'firefly', 'Neutral': 'mist' };
  const KEYWORDS = ['Peck 2', 'Shell 4', 'Shell 8', 'Mire', 'Shoulder', 'Hunker', 'Rival', 'Nightshade', 'Curl', 'Start of Combat'];

  const SPRITE = `<svg xmlns="http://www.w3.org/2000/svg" style="display:none">
  <symbol id="i-gold" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="#FFCB57"/><circle cx="12" cy="12" r="7.2" fill="none" stroke="#0B1618" stroke-width="1.4" opacity=".55"/><path d="M8.6 11.4c0-2 1.6-3.3 3.4-3.3s3.4 1.3 3.4 3.3z" fill="#0B1618" opacity=".7"/><path d="M9.4 11.4c.2 2.6 1.3 4.6 2.6 4.6s2.4-2 2.6-4.6z" fill="#0B1618" opacity=".45"/></symbol>
  <symbol id="i-tier" viewBox="0 0 24 24"><path d="M15.5 3.2A9 9 0 1 0 20.8 15 7 7 0 0 1 15.5 3.2z" fill="currentColor"/></symbol>
  <symbol id="i-atk" viewBox="0 0 24 24"><path d="M12 2.2 L21.8 12 L12 21.8 L2.2 12 Z" fill="currentColor" stroke="currentColor" stroke-width="2.4" stroke-linejoin="round"/><path d="M12 2.2 L14.2 6.4 M21.8 12 L17.6 14.2" stroke="#0B1618" stroke-width="1.2" opacity=".35" stroke-linecap="round"/></symbol>
  <symbol id="i-hp" viewBox="0 0 24 24"><path d="M12 21s-8.5-5.2-8.5-11A4.8 4.8 0 0 1 12 7a4.8 4.8 0 0 1 8.5 3c0 5.8-8.5 11-8.5 11z" fill="currentColor"/></symbol>
  <symbol id="i-refresh" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M19.5 9.5A8 8 0 0 0 5.2 7.6"/><path d="M4.5 14.5a8 8 0 0 0 14.3 1.9"/><path d="M5 3.5v4.4h4.4"/><path d="M19 20.5v-4.4h-4.4"/></g></symbol>
  <symbol id="i-freeze" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M12 2.5v19M3.8 7.2l16.4 9.6M3.8 16.8l16.4-9.6"/><path d="M9.3 4.2 12 6.6l2.7-2.4M9.3 19.8 12 17.4l2.7 2.4M3.6 10.6l3.4-.9-1-3.4M20.4 13.4l-3.4.9 1 3.4M6 17.1l1-3.4-3.4-.9M18 6.9l-1 3.4 3.4.9"/></g></symbol>
  <symbol id="i-night" viewBox="0 0 24 24"><circle cx="12" cy="14" r="7" fill="currentColor"/><path d="M12 4.2l1.4 3 3.2-.6-2 2.5 2.2 2.3-3.2-.2L12 14l-1.6-2.8-3.2.2 2.2-2.3-2-2.5 3.2.6z" fill="#0B1618" opacity=".55"/><circle cx="9.6" cy="12.6" r="1.4" fill="#fff" opacity=".55"/></symbol>
  <symbol id="i-end" viewBox="0 0 24 24"><path d="M5 4.5v15l12-7.5z" fill="currentColor"/><rect x="17.5" y="4.5" width="2.6" height="15" rx="1.3" fill="currentColor"/></symbol>
  <symbol id="i-play" viewBox="0 0 24 24"><path d="M7 4.5v15l12-7.5z" fill="currentColor"/></symbol>
  <symbol id="i-pause" viewBox="0 0 24 24"><rect x="6" y="4.5" width="4" height="15" rx="1.4" fill="currentColor"/><rect x="14" y="4.5" width="4" height="15" rx="1.4" fill="currentColor"/></symbol>
  <symbol id="i-skip" viewBox="0 0 24 24"><path d="M3.5 5v14l8-7zM11.5 5v14l8-7z" fill="currentColor"/><rect x="19.5" y="5" width="2" height="14" rx="1" fill="currentColor"/></symbol>
  <symbol id="i-gear" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3.3"/><path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3M5.5 5.5l2.1 2.1M16.4 16.4l2.1 2.1M5.5 18.5l2.1-2.1M16.4 7.6l2.1-2.1" stroke-linecap="round"/></g></symbol>
  <symbol id="i-star" viewBox="0 0 24 24"><path d="M12 2.5l2.6 6.6 7 .5-5.4 4.5 1.7 6.9L12 17.2 6.1 21l1.7-6.9L2.4 9.6l7-.5z" fill="currentColor"/></symbol>
  <symbol id="i-cap" viewBox="0 0 24 24"><path d="M2.5 12.5C3.5 6.8 7.4 4 12 4s8.5 2.8 9.5 8.5z" fill="currentColor"/><rect x="10" y="12" width="4" height="8.5" rx="2" fill="currentColor" opacity=".7"/><circle cx="8" cy="9" r="1.2" fill="#0B1618" opacity=".35"/><circle cx="14.5" cy="7.6" r="1" fill="#0B1618" opacity=".35"/></symbol>
  <symbol id="i-lantern" viewBox="0 0 24 24"><path d="M9 3.5h6M10 3.5v2M14 3.5v2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" fill="none"/><path d="M7 7.5c0-1.1.9-2 2-2h6a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2z" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="12" cy="12.5" r="2.6" fill="currentColor"/></symbol>
</svg>`;
  function ico(id, cls) { return `<svg class="ico ${cls || ''}"><use href="#i-${id}"/></svg>`; }

  function rulesHTML(text) {
    let t = text;
    KEYWORDS.forEach(k => { t = t.split(k).join(`<b class="kwd">${k}</b>`); });
    return t;
  }

  // size: 'shop' (text), 'board' (no text, keyword tag), 'hero' (big, text + reminder)
  function card(u, size, extra) {
    extra = extra || {};
    const cls = ['card', size, u.golden ? 'golden' : '', u.frozen ? 'frozen' : '', (u.status || []).includes('Nightshade') || extra.nightshade ? 'shaded' : '', extra.cls || ''].join(' ');
    const tribe = TRIBE[u.tribe] || 'mist';
    const hp = extra.hp !== undefined ? extra.hp : (u.current_health !== undefined ? u.current_health : u.health);
    const key = KEY[u.name] || (u.text && u.text.length < 12 ? u.text.replace(/\.$/, '') : '');
    const art = PORTRAIT[u.name] ? `<img src="${ART}${PORTRAIT[u.name]}.jpg" alt="">` : '';
    return `<div class="${cls}" style="--tribe:var(--${tribe})" data-name="${u.name}">
  <div class="art">${art}</div>
  ${u.tier ? `<div class="tier" title="Tier ${u.tier}">${ico('tier')}<b>${u.tier}</b></div>` : ''}
  ${u.frozen ? `<div class="flag frost">${ico('freeze')}<span>Frozen</span></div>` : ''}
  ${(u.status || []).includes('Nightshade') || extra.nightshade ? `<div class="flag shade">${ico('night')}<span>Nightshade</span></div>` : ''}
  ${u.golden ? `<div class="flag gilt">${ico('star')}<span>Golden</span></div>` : ''}
  ${(size === 'board' || size === 'shop') && key ? `<div class="key${key === 'Nightshade' ? ' ns' : ''}">${key}</div>` : ''}
  <div class="plate">
    <div class="name">${u.name}</div>
    <div class="type"><i></i>${u.type_line && u.type_line !== u.tribe ? u.type_line + ' · ' : ''}${u.tribe || ''}</div>
    ${size !== 'board' && u.text ? `<div class="txt">${rulesHTML(u.text)}</div>` : ''}
    ${size === 'hero' && u.keyword_reminder ? `<div class="remind">${rulesHTML(u.keyword_reminder)}</div>` : ''}
  </div>
  <div class="stat atk">${ico('atk')}<b>${u.attack}</b></div>
  <div class="stat hp">${ico('hp')}<b>${hp}</b></div>
</div>`;
  }

  function emptySlot(slot) { return `<div class="slot-empty"><span>${slot}</span><small>empty</small></div>`; }

  // rows: {front:[4], back:[3]} with unit objects or {empty:true, slot}. orient 'up' = front row on top (yours), 'down' = enemy (back on top)
  function board(rows, orient, extra) {
    extra = extra || {};
    const cell = (u) => `<div class="slot" data-slot="${u.slot}">${u.empty ? emptySlot(u.slot) : card(u, 'board', (extra.per || {})[u.slot])}<span class="slot-id">${u.slot}</span></div>`;
    const front = `<div class="row front">${rows.front.map(cell).join('')}<span class="row-tag">Front</span></div>`;
    const back = `<div class="row back">${rows.back.map(cell).join('')}<span class="row-tag">Back</span></div>`;
    // root lines: each back slot links to the two front slots in front of it
    const W = 10, G = 'var(--bgap)';
    return `<div class="brick ${orient}">${orient === 'up' ? front + back : back + front}<svg class="roots" viewBox="0 0 100 100" preserveAspectRatio="none">${[0, 1, 2].map(j => {
      const bx = 12.5 + 25 * (j + 0.5) - 0; // back slot centre in % of width (front slots at 12.5 + 25i)
      const fy = orient === 'up' ? 25 : 75, by = orient === 'up' ? 75 : 25;
      return `<line x1="${bx}" y1="${by}" x2="${12.5 + 25 * j}" y2="${fy}"/><line x1="${bx}" y1="${by}" x2="${12.5 + 25 * (j + 1)}" y2="${fy}"/>`;
    }).join('')}</svg></div>`;
  }

  window.NW = { card, board, ico, rulesHTML, SPRITE, PORTRAIT, ART };
  document.addEventListener('DOMContentLoaded', () => document.body.insertAdjacentHTML('afterbegin', SPRITE));
})();
