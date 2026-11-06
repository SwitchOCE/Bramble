// Woodland Nouveau: shared helpers (stage scaling, icons, card renderer).
(function () {
  const STAGE_H = 660;
  const NV = (window.NV = {});

  // Fixed-height stage scaled to the window: desktop 1920x1080 -> ~1173 wide, phone 844x390 -> ~1427 wide.
  NV.fit = function () {
    const st = document.querySelector('.nv-stage');
    if (!st) return;
    const s = window.innerHeight / STAGE_H;
    st.style.width = window.innerWidth / s + 'px';
    st.style.height = STAGE_H + 'px';
    st.style.setProperty('--sw', window.innerWidth / s + 'px');
    st.style.transform = 'scale(' + s + ')';
  };
  window.addEventListener('resize', () => { NV.fit(); if (NV.afterLayout) NV.afterLayout(); });

  NV.roman = n => ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'][n] || String(n);
  NV.slug = s => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  NV.art = name => 'assets/p-' + NV.slug(name) + '.jpg';

  // Keywords from the fixture's rules text, shown in small caps.
  const KEYS = ['Start of Combat', 'Nightshade', 'Peck', 'Curl', 'Mire', 'Shell', 'Shoulder', 'Hunker', 'Rival'];
  NV.rules = t => KEYS.reduce((s, k) => s.replace(new RegExp('\\b' + k + '\\b', 'g'), '<b class="nv-key nv-key-' + NV.slug(k) + '">' + k + '</b>'), t || '');
  // Board cards show only the leading keyword phrase when the text starts with one (e.g. "Shell 8"), never new text.
  NV.lead = t => { const m = (t || '').match(/^(Peck \d+|Shell \d+|Mire|Shoulder|Hunker|Rival)\b/); return m ? m[1] : ''; };

  // Icons: inline SVG, drawn for this direction.
  const I = (NV.icon = {});
  I.gold = '<svg viewBox="0 0 48 48" class="nv-ic"><defs><radialGradient id="nvg-coin" cx=".35" cy=".3" r=".8"><stop offset="0" stop-color="#fbe9a8"/><stop offset=".5" stop-color="#d4a542"/><stop offset="1" stop-color="#7a5418"/></radialGradient></defs><circle cx="24" cy="24" r="21" fill="url(#nvg-coin)" stroke="#4a3210" stroke-width="2"/><circle cx="24" cy="24" r="16.5" fill="none" stroke="#5c3e12" stroke-width="1.2" stroke-dasharray="2 2"/><path d="M24 14c-6 0-9 3-9 6h18c0-3-3-6-9-6z" fill="#5c3e12"/><path d="M16 21h16c0 7-4 12-8 13-4-1-8-6-8-13z" fill="#8a5a1c" stroke="#4a3210" stroke-width="1.4"/><path d="M24 14c0-2 1-4 3-5" stroke="#4a3210" stroke-width="1.6" fill="none" stroke-linecap="round"/></svg>';
  I.tier = '<svg viewBox="0 0 48 48" class="nv-ic"><g fill="#c9821a" stroke="#3a2510" stroke-width="1.4">' +
    [0, 60, 120, 180, 240, 300].map(a => '<ellipse cx="24" cy="11" rx="5.5" ry="10" transform="rotate(' + a + ' 24 24)"/>').join('') +
    '</g><circle cx="24" cy="24" r="7" fill="#f0d58a" stroke="#3a2510" stroke-width="1.4"/></svg>';
  I.health = '<svg viewBox="0 0 48 48" class="nv-ic"><path d="M24 42C10 32 5 24 5 16.5 5 10 10 6 15.5 6c4 0 7 2.5 8.5 5.5C25.5 8.5 28.5 6 32.5 6 38 6 43 10 43 16.5 43 24 38 32 24 42z" fill="#9a1f35" stroke="#3a0d16" stroke-width="2"/><path d="M12 15c1-4 4-5 7-4" stroke="#f2b4bf" stroke-width="2.4" fill="none" stroke-linecap="round"/></svg>';
  I.attack = '<svg viewBox="0 0 48 48" class="nv-ic"><path d="M24 3 40 24 24 45 8 24z" fill="#26449a" stroke="#0c1a40" stroke-width="2"/><path d="M24 3 24 45M8 24h32" stroke="#6f8ee0" stroke-width="1.2"/><path d="M15 18l6-8" stroke="#c9d6ff" stroke-width="2.4" stroke-linecap="round"/></svg>';
  I.refresh = '<svg viewBox="0 0 48 48" class="nv-ic" fill="none" stroke="#24180f" stroke-width="3.2" stroke-linecap="round"><path d="M38 20C35 11 25 7 17 11 9 15 7 25 11 32"/><path d="M38 9v11H27"/><path d="M10 28c3 9 13 13 21 9 6-3 8-8 8-13" stroke-width="2.2"/><circle cx="31" cy="37" r="2.4" fill="#24180f"/><path d="M16 34c-3-1-4 2-2 3" stroke-width="2"/></svg>';
  I.freeze = '<svg viewBox="0 0 48 48" class="nv-ic" fill="none" stroke="#0f3f4a" stroke-width="2.6" stroke-linecap="round">' +
    [0, 60, 120].map(a => '<g transform="rotate(' + a + ' 24 24)"><path d="M24 4v40"/><path d="M24 11c-3-3-6-2-6 1M24 11c3-3 6-2 6 1M24 37c-3 3-6 2-6-1M24 37c3 3 6 2 6-1"/></g>').join('') +
    '<circle cx="24" cy="24" r="4" fill="#bfe6ee"/></svg>';
  I.nightshade = '<svg viewBox="0 0 48 48" class="nv-ic"><path d="M24 6c6 2 12 6 13 12-6 1-11-2-13-7-2 5-7 8-13 7 1-6 7-10 13-12z" fill="#5e7f2c" stroke="#1d2a0c" stroke-width="1.4"/><circle cx="24" cy="30" r="12" fill="#2a0f3a" stroke="#b08adb" stroke-width="2"/><circle cx="19.5" cy="25.5" r="3.4" fill="#d9c2f2" opacity=".85"/></svg>';
  I.star = '<svg viewBox="0 0 48 48" class="nv-ic"><path d="M24 2c2 12 10 20 22 22-12 2-20 10-22 22-2-12-10-20-22-22C14 22 22 14 24 2z" fill="#f0d58a" stroke="#6a4a14" stroke-width="1.5"/></svg>';
  I.token = '<svg viewBox="0 0 48 48" class="nv-ic"><circle cx="24" cy="24" r="18" fill="none" stroke="#f0d58a" stroke-width="3" stroke-dasharray="4 4"/></svg>';

  // Whiplash ornament (a single curve with a curl) used for corners and dividers.
  NV.whip = (cls = '') => '<svg class="nv-whip ' + cls + '" viewBox="0 0 120 60" fill="none" stroke-linecap="round"><path d="M2 58C20 56 26 40 40 34 58 26 70 44 84 36 98 28 92 10 104 6c8-3 14 3 10 9-3 5-10 3-9-2" stroke="currentColor" stroke-width="2.6"/><path d="M40 34c-4-9 2-16 9-15M84 36c6 6 14 5 17-1" stroke="currentColor" stroke-width="1.6"/><path d="M58 30c3-6 9-7 12-4-4 3-8 4-12 4z" fill="currentColor"/></svg>';

  // Card renderer. size: 'shop' | 'board' | 'full'. opts: {golden, frozen, nightshade, token, cur, tag}
  NV.card = function (u, size, opts = {}) {
    const golden = opts.golden || u.golden;
    const tribe = NV.slug(u.tribe || 'neutral');
    const cls = ['nv-card', 'nv-' + size, 'nv-tr-' + tribe, golden ? 'nv-golden' : '', opts.frozen || u.frozen ? 'nv-frozen' : '',
      opts.nightshade ? 'nv-shaded' : '', u.name.length > 15 ? 'nv-long' : '', opts.cls || ''].join(' ');
    const lead = NV.lead(u.text);
    const hp = opts.cur != null ? opts.cur : u.health;
    let body = '';
    if (size === 'board') {
      body = '<div class="nv-name">' + u.name + '</div>' + (lead ? '<div class="nv-lead">' + lead + '</div>' : '<div class="nv-lead nv-lead-tribe">' + (u.tribe || '') + '</div>');
    } else {
      body = '<div class="nv-name">' + u.name + '</div>' +
        '<div class="nv-type">' + (u.type_line ? u.type_line + ' <span>·</span> ' : '') + '<i class="nv-enamel"></i>' + (u.tribe || 'Neutral') + '</div>' +
        '<div class="nv-text"><span>' + NV.rules(u.text) + '</span>' + (size === 'full' && opts.reminder ? '<div class="nv-remind">' + NV.rules(opts.reminder) + '</div>' : '') + '</div>';
    }
    return '<div class="' + cls + '"' + (opts.id ? ' id="' + opts.id + '"' : '') + '>' +
      '<div class="nv-frame"><div class="nv-inner">' +
      '<div class="nv-art"><img src="' + NV.art(u.name) + '" alt=""></div>' + body +
      '</div></div>' +
      (u.tier ? '<div class="nv-tier" title="Tier ' + u.tier + '">' + NV.roman(u.tier) + '</div>' : '') +
      (golden ? '<div class="nv-gstar">' + I.star + '</div>' : '') +
      (opts.token || u.token ? '<div class="nv-tokenmark">token</div>' : '') +
      (opts.nightshade ? '<div class="nv-nsbadge">' + I.nightshade + '</div>' : '') +
      '<div class="nv-gem nv-atk"><span>' + u.attack + '</span></div>' +
      '<div class="nv-gem nv-hp' + (opts.cur != null && opts.cur < u.health ? ' nv-hurt' : '') + '"><span>' + hp + '</span></div>' +
      (opts.frozen || u.frozen ? '<div class="nv-frost"><div class="nv-frost-tag">' + I.freeze + 'Frozen</div></div>' : '') +
      '</div>';
  };

  NV.empty = (slot, size = 'board') => '<div class="nv-card nv-' + size + ' nv-empty"><div class="nv-well"><span>' + slot + '</span>' + NV.whip('nv-wellwhip') + '</div></div>';

  // Board: front row of 4, back row of 3 offset by half a slot. rows: {front:[...], back:[...]}, cardFn(u) -> html
  NV.board = function (rows, cardFn, opts = {}) {
    const row = (list, name) => '<div class="nv-row nv-row-' + name + '">' + list.map(u => '<div class="nv-slot" data-slot="' + u.slot + '">' + (u.empty ? NV.empty(u.slot) : cardFn(u)) + '</div>').join('') + '</div>';
    const order = opts.enemy ? [['back', rows.back], ['front', rows.front]] : [['front', rows.front], ['back', rows.back]];
    return '<div class="nv-brick' + (opts.enemy ? ' nv-enemy' : '') + '">' + order.map(([n, l]) =>
      '<div class="nv-rowwrap nv-rw-' + n + '"><div class="nv-plaque">' + (n === 'front' ? 'Front' : 'Back') + '</div>' + row(l, n) + '</div>').join('') + '</div>';
  };

  NV.ready = function (fn) {
    const go = () => { NV.fit(); fn && fn(); document.fonts.ready.then(() => { NV.fit(); if (NV.afterLayout) NV.afterLayout(); document.body.classList.add('nv-ready'); }); };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', go); else go();
  };
})();
