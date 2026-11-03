'use strict';
// Server-rendered pages. Every value from git or disk goes through esc() or
// the Markdown renderer, which escapes too.

const { renderMarkdown, inline, escapeHtml: esc } = require('./markdown');
const { stripStatusBlock } = require('./status');

let assetVersion = '0';
function setAssetVersion(v) {
  assetVersion = v;
}

// ---------- small helpers ----------

const STATUS = {
  active: { label: 'Active', cls: 'active', icon: 'active' },
  'waiting on you': { label: 'Waiting on you', cls: 'waiting', icon: 'waiting' },
  paused: { label: 'Paused', cls: 'paused', icon: 'paused' },
  done: { label: 'Done', cls: 'done', icon: 'done' },
};

const ICONS = {
  active: '<circle cx="12" cy="12" r="5" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="9"/>',
  waiting: '<circle cx="12" cy="12" r="9"/><path d="M12 7v6"/><circle cx="12" cy="16.5" r="1.2" fill="currentColor" stroke="none"/>',
  paused: '<circle cx="12" cy="12" r="9"/><path d="M10 8.5v7M14 8.5v7"/>',
  done: '<circle cx="12" cy="12" r="9"/><path d="m8 12.5 2.8 2.8L16.5 9.5"/>',
  unknown: '<circle cx="12" cy="12" r="9" stroke-dasharray="3 3"/><path d="M9.6 9.6a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.6"/><circle cx="12" cy="16.6" r="1.1" fill="currentColor" stroke="none"/>',
  leaf: '<path d="M5 19c0-8 5-13 14-14-1 9-6 14-14 14Z"/><path d="M5 19 13 11"/>',
  phone: '<rect x="7" y="2.5" width="10" height="19" rx="2.2"/><path d="M11 18.5h2"/>',
  windows: '<path d="M3.5 5.5 10.5 4.5v7h-7zM12.5 4.2 20.5 3v8.5h-8zM3.5 12.5h7v7l-7-1zM12.5 12.5h8V21l-8-1.2z"/>',
  download: '<path d="M12 4v11M7 10.5l5 5 5-5M5 20h14"/>',
  arrow: '<path d="M9 5.5 15.5 12 9 18.5"/>',
  back: '<path d="M15 5.5 8.5 12l6.5 6.5"/>',
  question: '<circle cx="12" cy="12" r="9"/><path d="M9.6 9.6a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.6"/><circle cx="12" cy="16.6" r="1.1" fill="currentColor" stroke="none"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  branch: '<circle cx="7" cy="5.5" r="2"/><circle cx="7" cy="18.5" r="2"/><circle cx="17" cy="8" r="2"/><path d="M7 7.5v9M17 10c0 4-4 4.5-9.2 7"/>',
  book: '<path d="M4 5.5C4 4.7 4.7 4 5.5 4H11v16H5.5c-.8 0-1.5-.7-1.5-1.5zM20 5.5c0-.8-.7-1.5-1.5-1.5H13v16h5.5c.8 0 1.5-.7 1.5-1.5z"/>',
  alert: '<path d="M12 3.5 21.5 20h-19z"/><path d="M12 10v4.5"/><circle cx="12" cy="17.3" r="1.1" fill="currentColor" stroke="none"/>',
};

function icon(name, cls = '') {
  return `<svg class="icon ${cls}" viewBox="0 0 24 24" aria-hidden="true" focusable="false" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICONS[name] || ''}</svg>`;
}

function statusMeta(st) {
  if (st && st.status && STATUS[st.status]) return STATUS[st.status];
  if (st && st.state === 'missing') return { label: 'No status', cls: 'unknown', icon: 'unknown' };
  return { label: 'Status unreadable', cls: 'unknown', icon: 'unknown' };
}

function pill(st, size = '') {
  const m = statusMeta(st);
  return `<span class="pill pill-${m.cls} ${size}">${icon(m.icon)}<span>${esc(m.label)}</span></span>`;
}

const dayFmt = new Intl.DateTimeFormat('en-AU', { day: 'numeric', month: 'short' });
const dayYearFmt = new Intl.DateTimeFormat('en-AU', { day: 'numeric', month: 'short', year: 'numeric' });
const timeFmt = new Intl.DateTimeFormat('en-AU', { hour: '2-digit', minute: '2-digit', hour12: false });

function fmtDay(d, withYear = false) {
  return (withYear ? dayYearFmt : dayFmt).format(d);
}
function fmtDateTime(d) {
  return `${fmtDay(d, true)}, ${timeFmt.format(d)}`;
}
function relative(d, now = new Date()) {
  const s = Math.round((now - d) / 1000);
  if (s < 90) return 'just now';
  const m = Math.round(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.round(m / 60);
  if (h < 24) return `${h} h ago`;
  const days = Math.round(h / 24);
  if (days === 1) return 'yesterday';
  if (days < 14) return `${days} days ago`;
  return fmtDay(d, true);
}
function timeTag(d, { rel = true } = {}) {
  const date = new Date(d);
  const abs = fmtDateTime(date);
  return `<time datetime="${esc(date.toISOString())}" title="${esc(abs)}">${esc(rel ? relative(date) : abs)}</time>`;
}

function mb(bytes) {
  return bytes >= 1e6 ? `${(bytes / 1e6).toFixed(bytes >= 1e8 ? 0 : 1)} MB` : `${Math.max(1, Math.round(bytes / 1e3))} kB`;
}

function short(sha) {
  return sha ? String(sha).slice(0, 7) : '';
}

function plural(n, one, many) {
  return `${n} ${n === 1 ? one : many}`;
}

// ---------- layout ----------

function layout({ title, active, body, index, crumbs }) {
  const nav = [
    ['home', '/', 'Home'],
    ['builds', '/builds', 'Builds'],
  ]
    .map(([k, href, label]) => `<a href="${href}"${active === k ? ' aria-current="page"' : ''}>${label}</a>`)
    .join('');
  const stale = index && index.stale ? `<div class="banner banner-warn" role="status">${icon('alert')}<span>Couldn't re-read git just now, so this may be out of date: ${esc(index.stale)}</span></div>` : '';
  const regErr = index && index.registryError ? `<div class="banner banner-warn" role="status">${icon('alert')}<span>The workstream list couldn't be read: ${esc(index.registryError)}</span></div>` : '';
  const crumb = crumbs
    ? `<nav class="crumbs" aria-label="Breadcrumb">${crumbs.map(([href, label]) => (href ? `<a href="${href}">${icon('back')}<span>${esc(label)}</span></a>` : '')).join('')}</nav>`
    : '';
  const foot = index
    ? `<footer class="site-foot"><p>Read from git and <code>/data/bramble-builds</code>. Indexed ${timeTag(index.builtAt)}; checked ${timeTag(index.checkedAt || index.builtAt)}. Read-only: this site never changes the project.</p></footer>`
    : '';
  return `<!doctype html>
<html lang="en-AU">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#f4f1e8" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#121a16" media="(prefers-color-scheme: dark)">
<title>${esc(title)}${title === 'Bramble' ? '' : ' · Bramble'}</title>
<link rel="icon" href="/static/icon.svg?v=${assetVersion}" type="image/svg+xml">
<link rel="stylesheet" href="/static/portal.css?v=${assetVersion}">
</head>
<body>
<a class="skip" href="#main">Skip to content</a>
<header class="site-head">
  <div class="wrap head-row">
    <a class="brand" href="/">${icon('leaf', 'brand-mark')}<span>Bramble</span></a>
    <nav class="site-nav" aria-label="Main">${nav}</nav>
  </div>
</header>
<main id="main" class="wrap">
${stale}${regErr}${crumb}
${body}
</main>
<div class="wrap">${foot}</div>
</body>
</html>`;
}

// ---------- home ----------

function homePage(index) {
  const ws = index.workstreams;
  const counts = {};
  for (const w of ws) {
    const k = statusMeta(w.status).cls;
    counts[k] = (counts[k] || 0) + 1;
  }
  const waitingN = counts.waiting || 0;
  const headline = !ws.length
    ? 'No workstreams to show'
    : waitingN > 0
      ? `${plural(waitingN, 'workstream is', 'workstreams are')} waiting on you`
      : counts.active
        ? 'Nothing is waiting on you'
        : 'All quiet';
  const chips = [
    ['waiting', 'waiting on you'],
    ['active', 'active'],
    ['paused', 'paused'],
    ['done', 'done'],
    ['unknown', 'unreadable'],
  ]
    .filter(([k]) => counts[k])
    .map(([k, label]) => `<li class="chip chip-${k}">${icon(STATUS_ICON[k])}<span><b>${counts[k]}</b> ${label}</span></li>`)
    .join('');

  const cards = ws.map(card).join('\n');
  const body = `
<section class="hero" aria-labelledby="h-home">
  <p class="eyebrow">Project status</p>
  <h1 id="h-home">${esc(headline)}</h1>
  <ul class="chips" aria-label="Workstreams by status">${chips}</ul>
  ${latestStrip(index.builds)}
</section>

<section aria-labelledby="h-ws">
  <h2 id="h-ws" class="section-title">Workstreams</h2>
  <ul class="cards" role="list">
${cards}
  </ul>
</section>

<div class="lower">
${latestBuildCard(index.builds)}
${waitingList(index.waiting)}
</div>`;
  return layout({ title: 'Bramble', active: 'home', body, index });
}

const STATUS_ICON = { active: 'active', waiting: 'waiting', paused: 'paused', done: 'done', unknown: 'unknown' };

function card(w) {
  const st = w.status || { state: 'missing', fields: {}, problems: [] };
  const m = statusMeta(st);
  const f = st.fields || {};
  const rows = [];
  if (st.state !== 'ok') {
    const what = st.state === 'missing' ? 'Missing status block' : 'Malformed status block';
    rows.push(
      `<div class="card-problem" role="note">${icon('alert')}<div><strong>${what}</strong><span>${st.problems.map(esc).join(' ')}</span></div></div>`,
    );
  }
  if (f.next) rows.push(`<div class="fact fact-next"><dt>Next</dt><dd>${inline(f.next)}</dd></div>`);
  if (f.lastDone) rows.push(`<div class="fact"><dt>Last done</dt><dd>${inline(f.lastDone)}</dd></div>`);

  const q = w.questions;
  let qHtml;
  if (!q) qHtml = '';
  else if (q.count === null) qHtml = `<a class="meta-link q-none" href="/w/${esc(w.id)}/questions">${icon('question')}<span>Questions: no count</span></a>`;
  else
    qHtml = `<a class="meta-link ${q.count ? 'q-open' : ''}" href="/w/${esc(w.id)}/questions">${icon('question')}<span>${q.count ? plural(q.count, 'open question', 'open questions') : 'No open questions'}</span></a>`;
  const act = w.activity ? `<span class="meta">${icon('clock')}<span><span class="wide-only">Last commit </span><span class="vh-narrow">Last commit </span>${timeTag(w.activity.date)}</span></span>` : `<span class="meta">${icon('clock')}<span>No commits found</span></span>`;

  return `<li class="card ws-card s-${m.cls}" data-ws="${esc(w.id)}">
  <div class="card-head">
    <h3 class="card-title"><a class="stretch" href="/w/${esc(w.id)}">${esc(w.title)}</a></h3>
    ${pill(st)}
  </div>
  <dl class="facts">${rows.join('')}</dl>
  <div class="card-foot">${qHtml}${act}<span class="go" aria-hidden="true">${icon('arrow')}</span></div>
</li>`;
}

function downloadButtons(b, { big = false, quiet = false } = {}) {
  if (!b.files.length) return `<p class="muted">This build has no phone or Windows download.</p>`;
  return `<div class="dl-row${big ? ' dl-big' : ''}">${b.files
    .map(
      (f) =>
        `<a class="btn btn-dl ${f.key === 'apk' && !quiet ? 'btn-primary' : 'btn-secondary'}" href="/builds/${encodeURIComponent(b.name)}/${encodeURIComponent(f.file)}" data-kind="${f.key}" download>${icon(f.key === 'apk' ? 'phone' : 'windows')}<span class="btn-text"><span class="btn-label">${esc(f.label)}</span><span class="btn-sub">${esc(mb(f.size))}</span></span>${icon('download', 'btn-end')}</a>`,
    )
    .join('')}</div>`;
}

function newsList(b, { limit = 0 } = {}) {
  if (b.news && b.news.length) {
    const groups = limit ? b.news.slice(0, limit) : b.news;
    return groups
      .map(
        (g) =>
          `<div class="news"><p class="news-head">${esc(g.heading)}</p><ul>${g.items.map((i) => `<li>${esc(i)}</li>`).join('')}</ul></div>`,
      )
      .join('');
  }
  if (b.summary) return `<div class="news"><p class="news-head">In this build</p><ul><li>${esc(b.summary)}</li></ul></div>`;
  return '';
}

function sourceLine(b) {
  if (!b.source) return '';
  if (b.source.commit)
    return `<span class="meta">${icon('branch')}<span><code>${esc(b.source.branch)}</code> at <code>${esc(short(b.source.commit))}</code></span></span>`;
  return `<span class="meta">${icon('branch')}<span>${esc(b.source.text)}</span></span>`;
}

// Phone and tablet only: the latest build's APK right under the headline,
// so it isn't below every workstream card. Desktop shows the full card.
function latestStrip(builds) {
  const b = builds.latest || builds.builds[0];
  if (!b) return '';
  const apk = b.files.find((f) => f.key === 'apk');
  return `<section class="build-strip" aria-label="Latest build">
  <div class="strip-text"><span class="eyebrow">Latest build</span><span class="strip-name">${esc(b.label)} <span class="muted">· ${esc(fmtDateTime(new Date(b.date)))}</span></span></div>
  ${apk ? `<a class="btn btn-primary btn-dl" href="/builds/${encodeURIComponent(b.name)}/${encodeURIComponent(apk.file)}" data-kind="apk" download>${icon('phone')}<span class="btn-text"><span class="btn-label">${esc(apk.label)}</span><span class="btn-sub">${esc(mb(apk.size))}</span></span>${icon('download', 'btn-end')}</a>` : ''}
  <a class="text-link" href="/builds">Install help and Windows${icon('arrow')}</a>
</section>`;
}

function latestBuildCard(builds) {
  const b = builds.latest || builds.builds[0];
  if (!b) {
    return `<section class="panel build-panel" aria-labelledby="h-latest"><h2 id="h-latest" class="panel-title">Latest build</h2><p class="muted">${esc(builds.error || 'No builds yet.')}</p></section>`;
  }
  return `<section class="panel build-panel" aria-labelledby="h-latest">
  <div class="panel-head">
    <h2 id="h-latest" class="panel-title">Latest build</h2>
    <a class="text-link" href="/builds">All builds and install help${icon('arrow')}</a>
  </div>
  <p class="build-name">${esc(b.label)}${b.isLatest ? '' : ' <span class="tag">newest</span>'}</p>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(b.date, { rel: false })}</span></span>${sourceLine(b)}</div>
  ${newsList(b, { limit: 1 })}
  ${downloadButtons(b, { big: true })}
</section>`;
}

function waitingList(items) {
  const body = items.length
    ? `<ul class="waiting-list" role="list">${items
        .map(
          (i) =>
            `<li><a href="/w/${esc(i.id)}"><span class="w-title">${esc(i.title)}</span><span class="w-text">${inline(i.text)}</span></a></li>`,
        )
        .join('')}</ul>`
    : `<p class="muted">Nothing is waiting on you.</p>`;
  return `<section class="panel" aria-labelledby="h-waiting">
  <h2 id="h-waiting" class="panel-title">Waiting on you</h2>
  ${body}
</section>`;
}

// ---------- workstream (plan) page ----------

function workstreamPage(index, w) {
  const st = w.status;
  const f = st.fields || {};
  const facts = [];
  if (st.state !== 'ok') {
    facts.push(
      `<div class="card-problem wide" role="note">${icon('alert')}<div><strong>${st.state === 'missing' ? 'Missing status block' : 'Malformed status block'}</strong><span>${st.problems.map(esc).join(' ')}</span></div></div>`,
    );
  }
  const fact = (label, html, cls = '') => `<div class="fact ${cls}"><dt>${label}</dt><dd>${html}</dd></div>`;
  if (f.next) facts.push(fact('Next step', inline(f.next), 'fact-next'));
  if (f.lastDone) facts.push(fact('Last step done', inline(f.lastDone)));
  if (f.waiting) facts.push(fact('Waiting on you', inline(f.waiting), 'fact-waiting'));
  if (w.questions) {
    const q = w.questions;
    facts.push(
      fact(
        'Open questions',
        q.count === null
          ? `<a class="fact-link" href="/w/${esc(w.id)}/questions">No reliable count</a>`
          : `<a class="fact-link" href="/w/${esc(w.id)}/questions">${q.count ? plural(q.count, 'open question', 'open questions') : 'None open'}</a>`,
      ),
    );
  }
  if (w.activity) {
    facts.push(
      fact(
        'Last activity',
        `${timeTag(w.activity.date)} <span class="muted">· ${esc(fmtDateTime(new Date(w.activity.date)))}</span><br><span class="commit">${esc(w.activity.subject)}</span> <code>${esc(short(w.activity.sha))}</code>${w.activity.branches.length ? ` <span class="muted">on ${w.activity.branches.map((b) => `<code>${esc(b)}</code>`).join(', ')}</span>` : ''}`,
      ),
    );
  }

  let doc = '';
  if (w.planText) {
    doc = `<article class="doc" aria-labelledby="h-plan">
  <div class="doc-source">${icon('book')}<span id="h-plan">Plan: <code>${esc(w.planPath)}</code> on <code>${esc(w.branch.name)}</code>${w.branch.from === 'origin' ? ' (from origin, ahead of the local branch)' : ''} at <code>${esc(short(w.branch.sha))}</code></span></div>
  <div class="prose">${renderMarkdown(stripStatusBlock(w.planText), { headingOffset: 1 })}</div>
</article>`;
  } else {
    doc = `<p class="muted">No plan file to show: <code>${esc(w.planPath)}</code> wasn't found on ${w.branchesTried.map((b) => `<code>${esc(b)}</code>`).join(' or ')}.</p>`;
  }

  const body = `
<section class="hero hero-ws" aria-labelledby="h-ws-title">
  <div class="hero-row"><h1 id="h-ws-title">${esc(w.title)}</h1>${pill(st, 'pill-lg')}</div>
  ${w.blurb ? `<p class="lede">${esc(w.blurb)}</p>` : ''}
</section>
<dl class="panel facts facts-grid">${facts.join('')}</dl>
${doc}`;
  return layout({ title: w.title, active: 'home', body, index, crumbs: [['/', 'Home']] });
}

function questionsPage(index, w) {
  const q = w.questions;
  let summary;
  if (q.count === null) {
    summary = `<p class="lede">No reliable count: ${esc(q.reason || '')}</p>`;
  } else {
    const open = q.items.filter((i) => !i.answered);
    summary = `<p class="lede">${q.count ? plural(q.count, 'open question', 'open questions') : 'No open questions'}${q.answered ? `, ${q.answered} answered` : ''}.</p>
<ol class="q-index" role="list">${open
      .map((i) => `<li><span class="q-id">${esc(i.id)}</span><span>${inline(i.title)}</span></li>`)
      .join('')}</ol>
<p class="fine">Counted as: each numbered item, or bullet starting with a bold ID like <b>B1.</b>, that has no answer marker (“Answer:”, “Answered” or a struck-through start). Plain bullets are summaries, not questions.</p>`;
  }
  const doc = q.text
    ? `<article class="doc"><div class="doc-source">${icon('book')}<span><code>${esc(q.path)}</code> on <code>${esc(q.branch.name)}</code> at <code>${esc(short(q.branch.sha))}</code></span></div><div class="prose">${renderMarkdown(q.text, { headingOffset: 1 })}</div></article>`
    : '';
  const body = `
<section class="hero" aria-labelledby="h-q"><p class="eyebrow">${esc(w.title)}</p><h1 id="h-q">Open questions</h1>${summary}</section>
${doc}`;
  return layout({ title: `${w.title}: questions`, active: 'home', body, index, crumbs: [[`/w/${encodeURIComponent(w.id)}`, w.title]] });
}

// ---------- builds ----------

function section(md, heading) {
  if (!md) return null;
  const lines = md.replace(/\r\n?/g, '\n').split('\n');
  const start = lines.findIndex((l) => new RegExp(`^##\\s+${heading}\\s*$`, 'i').test(l));
  if (start === -1) return null;
  let end = lines.findIndex((l, k) => k > start && /^##?\s/.test(l));
  if (end === -1) end = lines.length;
  return lines.slice(start + 1, end).join('\n');
}

function buildsPage(index) {
  const { builds, error } = index.builds;
  const latest = index.builds.latest || builds[0];
  const older = builds.filter((b) => b !== latest);
  const pt = index.playtest;
  const tryMd = pt && pt.text ? section(pt.text, 'What to try') : null;

  const hero = latest
    ? `<section class="panel build-hero${latest.isLatest ? ' is-latest' : ''}" aria-labelledby="h-b-latest">
  <p class="eyebrow">${latest.isLatest ? 'Latest build' : 'Newest build (the <code>latest</code> link points elsewhere)'}</p>
  <h2 id="h-b-latest" class="build-name big">${esc(latest.label)}</h2>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(latest.date, { rel: false })}</span></span>${sourceLine(latest)}</div>
  ${downloadButtons(latest, { big: true })}
  <p class="fine install-hint">Phone: the APK is debug-signed, so Android asks you to allow installs from your browser. <a href="#install">Step-by-step install</a></p>
  ${newsList(latest, { limit: 1 })}
  ${readmeDetails(latest)}
</section>`
    : `<section class="panel"><p class="muted">${esc(error || 'No builds yet.')}</p></section>`;

  const install = `<section aria-labelledby="h-install" id="install">
  <h2 id="h-install" class="section-title">How to install</h2>
  <div class="install-grid">
    <div class="panel install">
      <h3>${icon('phone')}<span>Phone (Android)</span></h3>
      <ol class="steps">
        <li>On your phone, open this page and tap <b>APK for phone</b>.</li>
        <li>When the download finishes, tap it in the notification, or open it from <b>Files › Downloads</b>.</li>
        <li>If Android says your browser isn't allowed to install apps, tap <b>Settings</b>, turn on <b>Allow from this source</b>, and go back.</li>
        <li>Tap <b>Install</b>. The build is debug-signed, so Play Protect may warn you: tap <b>More details › Install anyway</b>.</li>
        <li>If Android won't install over an older build, uninstall the old Bramble first, then install again.</li>
      </ol>
    </div>
    <div class="panel install">
      <h3>${icon('windows')}<span>Windows</span></h3>
      <ol class="steps">
        <li>On your PC, click <b>Windows zip</b>.</li>
        <li>In Downloads, right-click the zip and choose <b>Extract All</b>. Don't run it from inside the zip.</li>
        <li>Open the extracted <code>windows</code> folder and run <code>bramble.exe</code>. Keep <code>bramble.pck</code> next to it: the game needs it to start.</li>
        <li>If SmartScreen says “Windows protected your PC”, click <b>More info › Run anyway</b>. The build isn't code-signed.</li>
      </ol>
    </div>
  </div>
  ${latest && latest.hasLinux ? `<p class="fine">Linux: on the Optiplex itself, run <code>linux/bramble.x86_64</code> in <code>/data/bramble-builds/${esc(latest.name)}/</code>.</p>` : ''}
</section>`;

  const tryIt = `<section aria-labelledby="h-try" class="panel">
  <div class="panel-head"><h2 id="h-try" class="panel-title">What to try</h2>${pt && pt.text ? `<a class="text-link" href="/playtest">Full playtest guide${icon('arrow')}</a>` : ''}</div>
  ${tryMd ? `<div class="prose">${renderMarkdown(tryMd)}</div><p class="fine">From <code>${esc(pt.path)}</code> on <code>${esc(pt.branchName)}</code>.</p>` : `<p class="muted">The playtest guide (<code>${esc(pt ? pt.path : 'PLAYTEST.md')}</code>) couldn't be read.</p>`}
</section>`;

  const list = older.length
    ? `<section aria-labelledby="h-older"><h2 id="h-older" class="section-title">Earlier builds</h2><ul class="build-list" role="list">${older.map(buildItem).join('')}</ul></section>`
    : '';

  const body = `
<section class="hero" aria-labelledby="h-builds">
  <p class="eyebrow">Builds</p>
  <h1 id="h-builds">${builds.length ? `${plural(builds.length, 'build', 'builds')}, newest first` : 'No builds yet'}</h1>
</section>
<div class="builds-top">${hero}${tryIt}</div>
${install}
${list}`;
  return layout({ title: 'Builds', active: 'builds', body, index });
}

function readmeDetails(b) {
  return `<details class="readme"><summary>README.txt and file sizes</summary>
  <pre>${esc(b.readme)}</pre>
  <ul class="files">${b.files.map((f) => `<li><code>${esc(f.file)}</code><span>${esc(mb(f.size))}</span></li>`).join('')}</ul>
</details>`;
}

function buildItem(b) {
  return `<li class="panel build" data-build="${esc(b.name)}">
  <div class="build-head"><h3 class="build-name">${esc(b.label)}</h3>${b.isLatest ? '<span class="tag tag-latest">latest</span>' : ''}</div>
  <div class="meta-row"><span class="meta">${icon('clock')}<span>${timeTag(b.date, { rel: false })}</span></span>${sourceLine(b)}</div>
  ${newsList(b)}
  ${downloadButtons(b, { quiet: true })}
  ${readmeDetails(b)}
</li>`;
}

function playtestPage(index) {
  const pt = index.playtest;
  const body =
    pt && pt.text
      ? `<p class="callout">${icon('download')}<span>Downloads are on the <a href="/builds">Builds page</a>; you don't need <code>scp</code>.</span></p>
<article class="doc"><div class="doc-source">${icon('book')}<span><code>${esc(pt.path)}</code> on <code>${esc(pt.branch.name)}</code> at <code>${esc(short(pt.branch.sha))}</code></span></div><div class="prose">${renderMarkdown(pt.text)}</div></article>`
      : `<p class="muted">The playtest guide couldn't be read from git.</p>`;
  return layout({ title: 'Playtest guide', active: 'builds', body, index, crumbs: [['/builds', 'Builds']] });
}

function errorPage(status, message, index) {
  const titles = { 400: 'Bad request', 403: 'Not allowed', 404: 'Not found', 500: 'Something went wrong' };
  const body = `<section class="hero"><p class="eyebrow">${status}</p><h1>${esc(titles[status] || 'Error')}</h1><p class="lede">${esc(message)}</p><p><a class="btn btn-secondary" href="/">${icon('back')}<span>Back to home</span></a></p></section>`;
  return layout({ title: titles[status] || 'Error', body, index });
}

// Refused clients can't load /static, so the 403 page carries its own small
// stylesheet, allowed by hash in that response's CSP (FORBIDDEN_CSP).
const FORBIDDEN_CSS = 'body{font:16px/1.5 system-ui,sans-serif;max-width:36rem;margin:3rem auto;padding:0 16px;color:#1c2a21;background:#f4f1e8}code{font-family:ui-monospace,monospace;overflow-wrap:anywhere}@media (prefers-color-scheme:dark){body{color:#e6eee8;background:#111915}}';
const FORBIDDEN_CSP = `default-src 'none'; style-src 'sha256-${require('node:crypto').createHash('sha256').update(FORBIDDEN_CSS).digest('base64')}'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`;

function forbiddenPage(addr) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="light dark"><title>Not allowed</title><style>${FORBIDDEN_CSS}</style></head><body><h1>Not allowed</h1><p>The Bramble portal only answers devices on the home network or Tailscale. This request came from <code>${esc(addr || 'an unknown address')}</code>.</p><p>On the home network, use the machine's IPv4 address (for example <code>http://192.168.x.x:8780</code>).</p></body></html>`;
}

module.exports = { FORBIDDEN_CSP, homePage, workstreamPage, questionsPage, buildsPage, playtestPage, errorPage, forbiddenPage, setAssetVersion, relative, mb };
