'use strict';
// Counts open questions in an owner-questions file.
//
// A question is an item with its own number or ID:
//   - a top-level numbered item:        "12. **Card text on phone.** ..."
//   - a bullet that starts with a bold ID: "- **B4. Growth cap per tier?** ..."
// Plain bullets (summaries of decisions already made) are not questions.
// An item counts as answered when its own text carries an answer marker:
// "**Answer", "Answered", "Answer:" or a struck-through ~~start~~.
//
// If the file has no such items at all, the count is unknown (null), so the
// portal shows nothing rather than a misleading 0.
//
// Decision cards point at one item with findQuestion(): "#16" (the first
// numbered item 16), "#9.1" (numbered item 1 under the "## 9." heading), or
// "#B8" (a bold-ID bullet, or else a heading "### B8. ..." at any level,
// whose block runs to the next heading of the same or a higher level).
// Heading items are only for lookup; they don't change the count.

const NUMBERED = /^(\d+)[.)]\s+(.*)$/;
const SECTION = /^##\s+(\d+)\.\s/;
const ID_HEADING = /^(#{1,6})\s+([A-Z]{1,3}\d+)[.:)]\s*(.*)$/;
const BOLD_ID = /^[-*]\s+\*\*([A-Z]{1,3}\d+)[.:)]\s*(.*)$/;
const HEADING = /^#{1,6}\s/;
const ANSWERED = /\*\*Answer|\bAnswered\b|\bAnswer:|^~~/;

function parseQuestions(text) {
  if (typeof text !== 'string') return { count: null, reason: 'The questions file could not be read.', items: [] };
  const lines = text.replace(/\r\n?/g, '\n').split('\n');
  const items = [];
  const headingItems = [];
  let cur = null;
  let block = null;
  let section = null;
  let inFence = false;
  for (const line of lines) {
    if (/^\s*(```|~~~)/.test(line)) inFence = !inFence;
    if (inFence) {
      if (block) block.text += '\n' + line;
      continue;
    }
    const h = /^(#{1,6})\s/.exec(line);
    if (h) {
      if (h[1].length <= 2) section = (SECTION.exec(line) || [])[1] || null;
      if (block && h[1].length <= block.level) block = null;
      const hm = ID_HEADING.exec(line);
      if (hm) {
        block = { id: hm[2], level: hm[1].length, heading: true, text: '**' + hm[3] + '**' };
        headingItems.push(block);
      }
    } else if (block) block.text += '\n' + line;
    let m;
    if ((m = NUMBERED.exec(line))) {
      cur = { id: m[1], section, text: m[2] };
      items.push(cur);
    } else if ((m = BOLD_ID.exec(line))) {
      cur = { id: m[1], text: '**' + m[2] };
      items.push(cur);
    } else if (HEADING.test(line) || /^[-*]\s/.test(line)) {
      cur = null;
    } else if (cur && line.trim()) {
      cur.text += '\n' + line.trim();
    }
  }
  for (const it of items) {
    it.answered = ANSWERED.test(it.text);
    it.title = titleOf(it.text);
  }
  for (const it of headingItems) {
    it.answered = /\*\*Answered/.test(it.text);
    it.title = titleOf(it.text);
  }
  if (!items.length) {
    return { count: null, reason: 'No numbered or ID-tagged questions found in the file.', items, headingItems };
  }
  const open = items.filter((i) => !i.answered);
  return { count: open.length, answered: items.length - open.length, items, headingItems };
}

// The item a card's source anchor points at, or null.
function findQuestion(parsed, ref) {
  if (!parsed || !ref) return null;
  const sec = /^(\d+)\.(\d+)$/.exec(ref);
  if (sec) return parsed.items.find((i) => i.section === sec[1] && i.id === sec[2]) || null;
  return parsed.items.find((i) => i.id === ref) || (parsed.headingItems || []).find((i) => i.id === ref) || null;
}

function titleOf(text) {
  const first = text.split('\n')[0];
  const bold = /^\*\*(.+?)\*\*/.exec(first);
  const t = (bold ? bold[1] : first).replace(/[*`]/g, '').trim();
  return t.length > 90 ? t.slice(0, 89) + '…' : t;
}

module.exports = { parseQuestions, findQuestion };
