// Field Journal: shared helpers. Card rendering, stage scaling, keyword marking.
(function () {
  const P = '../../../folio/art/web/trials/ink-b-';
  // Stand-in plates: only six Ink B portraits exist, so each unit borrows the nearest one.
  const PLATE = {
    'Belladonna Sprite': ['fairy-hollowdeep', '50% 30%'],
    'Hornet Scout': ['fairy-hollowdeep', '70% 25%'],
    'Hornetling': ['fairy-hollowdeep', '30% 20%'],
    'Drumming Woodpecker': ['squirrel-mosswood', '55% 30%'],
    'Lesser Spotted Woodpecker': ['squirrel-mosswood', '60% 22%'],
    'Robin Redbreast': ['squirrel-mosswood', '45% 35%'],
    'Hedge Doctor': ['dormouse-beechhold', '35% 40%'],
    'Feeder Vole': ['dormouse-beechhold', '30% 35%'],
    'Mudwallow Toad': ['ooze-moorbog', '50% 45%'],
    'Garden Snail': ['ooze-moorbog', '45% 60%'],
    'Bear Cub': ['marmot-highcrown', '40% 35%'],
    'Tusker Boar': ['marmot-highcrown', '45% 45%'],
    'Sett Warden': ['otter-reedmouth', '45% 35%']
  };
  // Flavour only: the naturalist's binomial on each specimen label.
  const LATIN = {
    'Belladonna Sprite': 'Atropa pixia', 'Drumming Woodpecker': 'Dryocopus tympanista',
    'Hedge Doctor': 'Erinaceus medicus', 'Mudwallow Toad': 'Bufo limivolvens',
    'Garden Snail': 'Cornu aspersum', 'Bear Cub': 'Ursus arctos catulus',
    'Sett Warden': 'Meles custos', 'Lesser Spotted Woodpecker': 'Dryobates minor',
    'Hornet Scout': 'Vespa crabro explorator', 'Hornetling': 'Vespa crabro minima',
    'Robin Redbreast': 'Erithacus rubecula', 'Tusker Boar': 'Sus scrofa dentatus',
    'Feeder Vole': 'Microtus pastor'
  };
  const TYPE = { 'Belladonna Sprite': 'Fairy' };
  const TRIBE_CLASS = {
    'Birds': 'birds', 'Hedgerow folk': 'hedgerow', 'Bog folk': 'bog', 'Neutral': 'neutral',
    'Great beasts': 'beasts', 'Hunters': 'hunters', 'Hive': 'hive', 'Fairies': 'fairies'
  };
  const KW = ['Start of Combat', 'Nightshade', 'Peck 2', 'Shell 4', 'Shell 8', 'Mire', 'Shoulder', 'Hunker', 'Rival', 'Curl'];
  const CHIP = { 'Peck': 1, 'Shell': 1, 'Mire': 1, 'Shoulder': 1, 'Hunker': 1, 'Rival': 1, 'Start of Combat': 1 };
  const REMIND = {
    'Peck 2': 'Peck 2: strikes twice, splitting its Attack.',
    'Shell 4': 'Shell 4: the first hit this combat deals at most 4.',
    'Shell 8': 'Shell 8: the first hit this combat deals at most 8.',
    'Mire': 'Mire: an enemy this damages skips its next attack.',
    'Shoulder': 'Shoulder: once per enemy cycle, takes an attack aimed at a neighbour.',
    'Hunker': 'Hunker: takes half damage when attacked.',
    'Rival': 'Rival: duels the enemy across from it; both deal double damage.',
    'Curl': 'Curl: sits out while others can attack, takes half damage, pricks attackers for 1.'
  };

  function esc(s) { return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;'); }
  function markKw(text) {
    let t = esc(text);
    KW.forEach(k => { t = t.split(k).join('<b class="fj-kw">' + k + '</b>'); });
    return t;
  }
  function chipOf(u) {
    if (!u.text) return '';
    const first = u.text.split('.')[0].split(':')[0].trim();
    const head = first.split(' ')[0];
    if (CHIP[first] || CHIP[head]) return first;
    return '';
  }
  function remindOf(u) {
    if (!u.text) return '';
    for (const k of Object.keys(REMIND)) if (u.text.indexOf(k) >= 0) return REMIND[k];
    return '';
  }
  // A tiny deterministic tilt so pinned cards don't look machine-placed.
  function tilt(name, slot) {
    let h = 0; const s = name + (slot || '');
    for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) % 997;
    return ((h % 7) - 3) * 0.35;
  }
  function plate(u) {
    const p = PLATE[u.name] || ['ooze-moorbog', '50% 50%'];
    return '<div class="fj-plate"><img src="' + P + p[0] + '.jpg" style="object-position:' + p[1] + '" alt=""></div>';
  }

  // size: 'full' | 'shop' | 'board' | 'mini'. opts: {slot, hp (current), status, frozen}
  function card(u, size, opts) {
    opts = opts || {};
    const tc = TRIBE_CLASS[u.tribe] || 'neutral';
    const cls = ['fj-card', 'fj-size-' + size, 'fj-t-' + tc];
    if (u.golden) cls.push('fj-golden');
    if (u.frozen || opts.frozen) cls.push('fj-frozen');
    if (opts.cls) cls.push(opts.cls);
    const rot = opts.noTilt ? 0 : tilt(u.name, opts.slot);
    const hp = opts.hp != null ? opts.hp : u.health;
    const typeLine = (TYPE[u.name] || u.tribe) + (u.token ? ' · token' : '');
    let h = '<div class="' + cls.join(' ') + '" style="--rot:' + rot + 'deg">';
    if (u.tribe) h += '<div class="fj-tape">' + esc(u.tribe) + '</div>';
    if (u.tier) h += '<div class="fj-tier"><small>tier</small>' + u.tier + '</div>';
    h += plate(u);
    h += '<div class="fj-label"><div class="fj-name">' + esc(u.name) + '</div>';
    if (size !== 'board' && size !== 'mini') h += '<div class="fj-latin">' + (LATIN[u.name] || '') + '</div>';
    h += '</div>';
    if (size === 'full' || size === 'shop') {
      h += '<div class="fj-type">' + esc(typeLine) + '</div>';
      h += '<div class="fj-text">' + markKw(u.text || '') + '</div>';
    } else {
      const c = opts.chip != null ? opts.chip : chipOf(u);
      if (c) h += '<div class="fj-chip">' + esc(c) + '</div>';
    }
    if (u.golden) h += '<div class="fj-goldstamp">★ golden</div>';
    if (u.frozen || opts.frozen) h += '<div class="fj-frosttape">FROZEN</div>';
    if (opts.extra) h += opts.extra;
    h += '<div class="fj-stat fj-atk"><span>' + u.attack + '</span></div>';
    h += '<div class="fj-stat fj-hp' + (opts.hpCls ? ' ' + opts.hpCls : '') + '"><span>' + hp + '</span></div>';
    h += '</div>';
    return h;
  }
  function emptySlot(slot) {
    return '<div class="fj-empty"><span class="fj-pin">+</span><span>empty</span></div>';
  }

  // Fixed-height stage scaled to the window (works for 1920x1080 and 844x390).
  function stage(height) {
    const st = document.querySelector('.fj-stage');
    function fit() {
      const s = window.innerHeight / height;
      st.style.height = height + 'px';
      st.style.width = (window.innerWidth / s) + 'px';
      st.style.transform = 'scale(' + s + ')';
      document.body.classList.toggle('fj-phone', window.innerWidth < 1000);
      window.FJ_SCALE = s;
    }
    fit();
    window.addEventListener('resize', fit);
  }

  window.FJ = { card, emptySlot, stage, markKw, remindOf, LATIN, REMIND, esc };
})();
