'use strict';
// A small Markdown renderer for the project's docs. Everything from the file
// is HTML-escaped; raw HTML in the source is shown as text, and HTML comments
// are dropped. Covers what the docs use: headings, paragraphs, nested lists,
// blockquotes, fenced code, tables, rules, emphasis, code spans and links.

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

const LIST_ITEM = /^( {0,3})([-*+]|\d{1,9}[.)])(\s+|$)(.*)$/;
const FENCE = /^ {0,3}(```+|~~~+)\s*([\w+-]*)\s*$/;
const HEADING = /^ {0,3}(#{1,6})(?:\s+(.*?))?\s*#*\s*$/;
const HR = /^ {0,3}([-*_])(?:\s*\1){2,}\s*$/;
const TABLE_SEP = /^\s*\|?\s*:?-{1,}:?\s*(\|\s*:?-{1,}:?\s*)*\|?\s*$/;

function renderMarkdown(src, opts = {}) {
  const text = String(src)
    .replace(/\r\n?/g, '\n')
    .replace(/\u0000/g, '')
    .replace(/<!--[\s\S]*?-->/g, '');
  const ctx = { slugs: new Map(), resolveLink: opts.resolveLink || null, headingOffset: opts.headingOffset || 0 };
  return blocks(text.split('\n'), ctx, false);
}

function blocks(lines, ctx, tight) {
  const out = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (!line.trim()) { i++; continue; }

    let m;
    if ((m = FENCE.exec(line))) {
      const marker = m[1];
      const body = [];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith(marker)) body.push(lines[i++]);
      i++;
      out.push(`<pre><code>${escapeHtml(body.join('\n'))}</code></pre>`);
      continue;
    }
    if ((m = HEADING.exec(line))) {
      const level = Math.min(6, m[1].length + ctx.headingOffset);
      const content = m[2] || '';
      const id = slug(content, ctx);
      out.push(`<h${level} id="${id}">${inline(content, ctx)}</h${level}>`);
      i++;
      continue;
    }
    if (HR.test(line)) { out.push('<hr>'); i++; continue; }
    if (/^ {0,3}>/.test(line)) {
      const body = [];
      while (i < lines.length && lines[i].trim() && /^ {0,3}>/.test(lines[i])) {
        body.push(lines[i].replace(/^ {0,3}> ?/, ''));
        i++;
      }
      out.push(`<blockquote>${blocks(body, ctx, false)}</blockquote>`);
      continue;
    }
    if (line.includes('|') && i + 1 < lines.length && TABLE_SEP.test(lines[i + 1]) && lines[i + 1].includes('-')) {
      const head = cells(line);
      const aligns = cells(lines[i + 1]).map((c) => (/^:-+:$/.test(c) ? 'center' : /-+:$/.test(c) ? 'right' : ''));
      i += 2;
      const rows = [];
      while (i < lines.length && lines[i].trim() && lines[i].includes('|')) rows.push(cells(lines[i++]));
      const th = head.map((c, k) => `<th${al(aligns[k])}>${inline(c, ctx)}</th>`).join('');
      const tb = rows
        .map((r) => '<tr>' + head.map((_, k) => `<td${al(aligns[k])}>${inline(r[k] || '', ctx)}</td>`).join('') + '</tr>')
        .join('');
      out.push(`<div class="table-wrap"><table><thead><tr>${th}</tr></thead><tbody>${tb}</tbody></table></div>`);
      continue;
    }
    if (LIST_ITEM.exec(line)) {
      const r = list(lines, i, ctx);
      out.push(r.html);
      i = r.next;
      continue;
    }
    // Paragraph.
    const para = [];
    while (i < lines.length && lines[i].trim() && !startsBlock(lines[i])) para.push(lines[i++]);
    if (!para.length) para.push(lines[i++]);
    const html = para
      .map((l, k) => inline(l.trim(), ctx) + (k < para.length - 1 && / {2,}$/.test(l) ? '<br>' : ''))
      .join('\n');
    out.push(tight ? html : `<p>${html}</p>`);
  }
  return out.join('\n');
}

function startsBlock(line) {
  return FENCE.test(line) || HEADING.test(line) || /^ {0,3}>/.test(line) || LIST_ITEM.test(line) || HR.test(line);
}

function list(lines, start, ctx) {
  const first = LIST_ITEM.exec(lines[start]);
  const ordered = /\d/.test(first[2]);
  const baseIndent = first[1].length;
  const items = [];
  let i = start;
  let loose = false;
  let sawBlank = false;
  while (i < lines.length) {
    const line = lines[i];
    const m = LIST_ITEM.exec(line);
    if (m && m[1].length === baseIndent && /\d/.test(m[2]) === ordered) {
      if (sawBlank && items.length) loose = true;
      sawBlank = false;
      const contentIndent = m[1].length + m[2].length + Math.max(1, Math.min(4, m[3].length || 1));
      items.push({ lines: [m[4]], indent: contentIndent, start: ordered ? parseInt(m[2], 10) : null });
      i++;
      continue;
    }
    if (!line.trim()) {
      // A blank line ends the list unless the next non-blank line continues it.
      let j = i + 1;
      while (j < lines.length && !lines[j].trim()) j++;
      if (j >= lines.length) break;
      const nm = LIST_ITEM.exec(lines[j]);
      const indent = lines[j].length - lines[j].trimStart().length;
      const cur = items[items.length - 1];
      if ((nm && nm[1].length === baseIndent && /\d/.test(nm[2]) === ordered) || indent >= cur.indent) {
        sawBlank = true;
        cur.lines.push('');
        i++;
        continue;
      }
      break;
    }
    const indent = line.length - line.trimStart().length;
    const cur = items[items.length - 1];
    if (indent > baseIndent || (!startsBlock(line) && !sawBlank)) {
      if (sawBlank && indent >= cur.indent) loose = true;
      cur.lines.push(indent >= cur.indent ? line.slice(cur.indent) : line.trimStart());
      sawBlank = false;
      i++;
      continue;
    }
    break;
  }
  const tag = ordered ? 'ol' : 'ul';
  const startAttr = ordered && items[0].start !== 1 ? ` start="${items[0].start}"` : '';
  const lis = items
    .map((it) => {
      while (it.lines.length && !it.lines[it.lines.length - 1].trim()) it.lines.pop();
      return `<li>${blocks(it.lines, ctx, !loose)}</li>`;
    })
    .join('\n');
  return { html: `<${tag}${startAttr}>\n${lis}\n</${tag}>`, next: i };
}

function cells(row) {
  let r = row.trim();
  if (r.startsWith('|')) r = r.slice(1);
  if (r.endsWith('|') && !r.endsWith('\\|')) r = r.slice(0, -1);
  const out = [];
  let cur = '';
  let inCode = false;
  for (let k = 0; k < r.length; k++) {
    const ch = r[k];
    if (ch === '`') inCode = !inCode;
    if (ch === '\\' && r[k + 1] === '|') { cur += '|'; k++; continue; }
    if (ch === '|' && !inCode) { out.push(cur.trim()); cur = ''; continue; }
    cur += ch;
  }
  out.push(cur.trim());
  return out;
}

function al(a) {
  return a ? ` class="align-${a}"` : '';
}

function slug(text, ctx) {
  let s = String(text)
    .toLowerCase()
    .replace(/[`*_~[\]()]/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '') || 'section';
  const n = ctx.slugs.get(s) || 0;
  ctx.slugs.set(s, n + 1);
  return n ? `${s}-${n}` : s;
}

// Inline formatting. Code spans and links are cut out first so their
// contents aren't touched by emphasis rules.
function inline(src, ctx = {}) {
  const tokens = [];
  const hold = (html) => `\u0000${tokens.push(html) - 1}\u0000`;
  let s = String(src).replace(/\u0000/g, '');

  s = s.replace(/(`+)([\s\S]*?[^`])\1(?!`)/g, (_, __, code) => hold(`<code>${escapeHtml(code.trim())}</code>`));
  s = s.replace(/\\([\\`*_{}[\]()#+\-.!|~<>])/g, (_, ch) => hold(escapeHtml(ch)));
  s = s.replace(/<(https?:\/\/[^\s<>]+)>/g, (_, url) => hold(link(url, escapeHtml(url), ctx)));
  s = s.replace(/\[([^\]]+)\]\(\s*<?([^)\s>]*)>?(?:\s+"[^"]*")?\s*\)/g, (_, label, href) =>
    hold(link(href, inlineNoLinks(label), ctx)),
  );

  s = escapeHtml(s);
  s = emphasis(s);
  return s.replace(/\u0000(\d+)\u0000/g, (_, n) => tokens[Number(n)]);
}

function inlineNoLinks(label) {
  const tokens = [];
  let s = label.replace(/(`+)([\s\S]*?[^`])\1(?!`)/g, (_, __, code) => `\u0000${tokens.push(`<code>${escapeHtml(code.trim())}</code>`) - 1}\u0000`);
  s = emphasis(escapeHtml(s));
  return s.replace(/\u0000(\d+)\u0000/g, (_, n) => tokens[Number(n)]);
}

function emphasis(s) {
  return s
    .replace(/\*\*(?=\S)([\s\S]*?\S)\*\*/g, '<strong>$1</strong>')
    .replace(/(^|[^\w])__(?=\S)([\s\S]*?\S)__(?=[^\w]|$)/g, '$1<strong>$2</strong>')
    .replace(/(^|[^*\w])\*(?=[^\s*])([\s\S]*?[^\s*])\*(?![*\w])/g, '$1<em>$2</em>')
    .replace(/(^|[^\w])_(?=\S)([\s\S]*?\S)_(?=[^\w]|$)/g, '$1<em>$2</em>')
    .replace(/~~(?=\S)([\s\S]*?\S)~~/g, '<del>$1</del>');
}

// External links open normally. Relative links in repo docs point at files
// the portal doesn't serve yet, so they become text unless a resolver maps them.
function link(href, labelHtml, ctx) {
  let url = null;
  if (/^https?:\/\//i.test(href) || /^mailto:/i.test(href)) url = href;
  else if (href.startsWith('#')) url = href;
  else if (ctx.resolveLink) url = ctx.resolveLink(href);
  if (!url) return `<span class="doc-ref" title="${escapeHtml(href)}">${labelHtml}</span>`;
  const ext = /^https?:/i.test(url) ? ' rel="noopener noreferrer"' : '';
  return `<a href="${escapeHtml(url)}"${ext}>${labelHtml}</a>`;
}

module.exports = { renderMarkdown, inline, escapeHtml };
