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

const NUMBERED = /^(\d+)[.)]\s+(.*)$/;
const BOLD_ID = /^[-*]\s+\*\*([A-Z]{1,3}\d+)[.:)]\s*(.*)$/;
const HEADING = /^#{1,6}\s/;
const ANSWERED = /\*\*Answer|\bAnswered\b|\bAnswer:|^~~/;

function parseQuestions(text) {
  if (typeof text !== 'string') return { count: null, reason: 'The questions file could not be read.', items: [] };
  const lines = text.replace(/\r\n?/g, '\n').split('\n');
  const items = [];
  let cur = null;
  let inFence = false;
  for (const line of lines) {
    if (/^\s*(```|~~~)/.test(line)) inFence = !inFence;
    if (inFence) continue;
    let m;
    if ((m = NUMBERED.exec(line))) {
      cur = { id: m[1], text: m[2] };
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
  if (!items.length) {
    return { count: null, reason: 'No numbered or ID-tagged questions found in the file.', items };
  }
  const open = items.filter((i) => !i.answered);
  return { count: open.length, answered: items.length - open.length, items };
}

function titleOf(text) {
  const first = text.split('\n')[0];
  const bold = /^\*\*(.+?)\*\*/.exec(first);
  const t = (bold ? bold[1] : first).replace(/[*`]/g, '').trim();
  return t.length > 90 ? t.slice(0, 89) + '…' : t;
}

module.exports = { parseQuestions };
